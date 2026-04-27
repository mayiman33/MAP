import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../data/attractions_data.dart';
import '../models/attraction.dart';
import 'firebase_bootstrap.dart';

class PlaceLoadResult {
  final List<Attraction> attractions;
  final bool fromFallback;
  final String? error;

  const PlaceLoadResult({
    required this.attractions,
    required this.fromFallback,
    this.error,
  });
}

class PlaceServiceException implements Exception {
  final String message;
  const PlaceServiceException(this.message);

  @override
  String toString() => 'PlaceServiceException: $message';
}

class FirebasePlaceService {
  FirebasePlaceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<PlaceLoadResult> getPlacesWithFallback() async {
    try {
      if (!FirebaseBootstrap.isInitialized) {
        return PlaceLoadResult(
          attractions: List<Attraction>.from(allAttractions),
          fromFallback: true,
          error: FirebaseBootstrap.lastError ?? 'Firebase is not initialized.',
        );
      }

      final query = await _firestore.collection('places').get();
      final places = query.docs.map(_fromFirestoreDoc).toList();

      if (places.isEmpty) {
        return PlaceLoadResult(
          attractions: List<Attraction>.from(allAttractions),
          fromFallback: true,
          error: 'No places found in Firestore. Using local data fallback.',
        );
      }

      return PlaceLoadResult(attractions: places, fromFallback: false);
    } catch (e) {
      if (allAttractions.isEmpty) {
        throw PlaceServiceException(
          'Unable to load Firestore places and local fallback is empty: $e',
        );
      }

      return PlaceLoadResult(
        attractions: List<Attraction>.from(allAttractions),
        fromFallback: true,
        error: 'Firestore unavailable. Using local fallback. Error: $e',
      );
    }
  }

  Attraction _fromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw PlaceServiceException(
        'Place document ${doc.id} is missing latitude/longitude.',
      );
    }

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    return Attraction(
      id: (data['id'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? 'Unknown place',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'Historical',
      city: (data['city'] as String?) ?? '',
      state: (data['state'] as String?) ?? '',
      priceRange: (data['priceRange'] as String?) ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: (data['imageUrl'] as String?) ?? '',
      coordinates: LatLng(latitude, longitude),
      iconEmoji: _emojiForCategory((data['category'] as String?) ?? ''),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String _emojiForCategory(String category) {
    switch (category) {
      case 'Food':
        return '🍜';
      case 'Nature':
        return '🌿';
      case 'Historical':
        return '🏛️';
      default:
        return '📍';
    }
  }

  Future<void> seedSamplePlaces() async {
    if (!FirebaseBootstrap.isInitialized) {
      throw const PlaceServiceException(
        'Firebase is not initialized. Run FlutterFire configure first.',
      );
    }

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    final places = _firestore.collection('places');

    final docs = <Map<String, dynamic>>[
      {
        'id': 'nasi_kandar_line_clear',
        'name': 'Nasi Kandar Line Clear',
        'description':
            'Famous Penang nasi kandar spot known for rich curries and late-night dining.',
        'category': 'Food',
        'city': 'George Town',
        'state': 'Penang',
        'priceRange': 'RM10-RM40',
        'rating': 4.6,
        'latitude': 5.4145,
        'longitude': 100.3292,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'batu_caves_kl',
        'name': 'Batu Caves',
        'description':
            'Limestone cave temple complex and major cultural landmark near Kuala Lumpur.',
        'category': 'Historical',
        'city': 'Gombak',
        'state': 'Selangor',
        'priceRange': 'Free-RM20',
        'rating': 4.5,
        'latitude': 3.2379,
        'longitude': 101.6840,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'cameron_highlands_nature',
        'name': 'Cameron Highlands',
        'description':
            'Cool highland region with tea plantations, trails, and scenic viewpoints.',
        'category': 'Nature',
        'city': 'Tanah Rata',
        'state': 'Pahang',
        'priceRange': 'RM20-RM150',
        'rating': 4.7,
        'latitude': 4.4933,
        'longitude': 101.3763,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (final doc in docs) {
      final ref = places.doc(doc['id'] as String);
      batch.set(ref, doc, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
