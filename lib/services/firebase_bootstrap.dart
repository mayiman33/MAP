import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static String? _lastError;

  static bool get isInitialized => _initialized;
  static String? get lastError => _lastError;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      _lastError = null;
    } catch (e) {
      _initialized = false;
      _lastError = e.toString();
    }
  }
}
