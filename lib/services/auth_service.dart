import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserProfile(
      uid: credential.user!.uid,
      email: credential.user!.email ?? email,
      displayName: displayName ?? credential.user!.displayName ?? '',
      role: 'user',
    );
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_cancelled',
        message: 'Google sign-in was cancelled by user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await _ensureUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        role: 'user',
      );
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> createDemoUsers() async {
    if (!kDebugMode) {
      throw StateError('Demo users can only be created in debug mode.');
    }

    const demoUsers = [
      (
        email: 'admin@test.com',
        password: '123456',
        role: 'admin',
      ),
      (
        email: 'user@test.com',
        password: '123456',
        role: 'user',
      ),
    ];

    const demoAppName = 'demo-user-seeder';
    FirebaseApp demoApp;

    try {
      demoApp = Firebase.app(demoAppName);
    } on FirebaseException {
      demoApp = await Firebase.initializeApp(
        name: demoAppName,
        options: Firebase.app().options,
      );
    }

    final demoAuth = FirebaseAuth.instanceFor(app: demoApp);
    final demoFirestore = FirebaseFirestore.instanceFor(app: demoApp);
    var failureCount = 0;

    try {
      for (final demoUser in demoUsers) {
        try {
          UserCredential credential;

          try {
            credential = await demoAuth.createUserWithEmailAndPassword(
              email: demoUser.email,
              password: demoUser.password,
            );
            debugPrint('Created demo auth user: ${demoUser.email}');
          } on FirebaseAuthException catch (e) {
            if (e.code != 'email-already-in-use') {
              rethrow;
            }

            credential = await demoAuth.signInWithEmailAndPassword(
              email: demoUser.email,
              password: demoUser.password,
            );
            debugPrint('Demo auth user already exists: ${demoUser.email}');
          }

          final user = credential.user;
          if (user == null) {
            throw StateError('FirebaseAuth did not return a user.');
          }

          await _ensureDemoUserProfile(
            firestore: demoFirestore,
            uid: user.uid,
            email: user.email ?? demoUser.email,
            role: demoUser.role,
          );
          debugPrint(
            'Demo Firestore user ready: ${demoUser.email} (${demoUser.role})',
          );
        } catch (e) {
          failureCount++;
          debugPrint('Failed to create demo user ${demoUser.email}: $e');
        }
      }

      if (failureCount > 0) {
        throw StateError(
          '$failureCount demo user(s) failed. Check debug logs for details.',
        );
      }
    } finally {
      await demoAuth.signOut();
      await demoApp.delete();
    }
  }

  Future<void> _ensureDemoUserProfile({
    required FirebaseFirestore firestore,
    required String uid,
    required String email,
    required String role,
  }) async {
    final userRef = firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    await userRef.set(
      {
        'uid': uid,
        'email': email,
        'role': role,
        if (!snapshot.exists || data?['createdAt'] == null)
          'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _ensureUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
