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

  Future<int> seedSamplePlaces() async {
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
            'Classic Penang nasi kandar spot known for flavorful curries and late-night crowds.',
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
        'id': 'jalan_alor_food_street',
        'name': 'Jalan Alor Food Street',
        'description':
            'Bustling street food lane in Bukit Bintang with satay, seafood, and local desserts.',
        'category': 'Food',
        'city': 'Kuala Lumpur',
        'state': 'Kuala Lumpur',
        'priceRange': 'RM15-RM70',
        'rating': 4.5,
        'latitude': 3.1458,
        'longitude': 101.7090,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'gurney_drive_hawker_centre',
        'name': 'Gurney Drive Hawker Centre',
        'description':
            'Popular seafront hawker destination with char koay teow, asam laksa, and cendol.',
        'category': 'Food',
        'city': 'George Town',
        'state': 'Penang',
        'priceRange': 'RM10-RM50',
        'rating': 4.7,
        'latitude': 5.4392,
        'longitude': 100.3090,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'jonker_street_food_area',
        'name': 'Jonker Street Food Area',
        'description':
            'Melaka night market area famous for chicken rice balls, nyonya snacks, and desserts.',
        'category': 'Food',
        'city': 'Melaka City',
        'state': 'Melaka',
        'priceRange': 'RM10-RM60',
        'rating': 4.4,
        'latitude': 2.1952,
        'longitude': 102.2477,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'satay_kajang_haji_samuri',
        'name': 'Satay Kajang Haji Samuri',
        'description':
            'Well-known Kajang satay chain serving grilled skewers with rich peanut sauce.',
        'category': 'Food',
        'city': 'Kajang',
        'state': 'Selangor',
        'priceRange': 'RM20-RM80',
        'rating': 4.3,
        'latitude': 2.9935,
        'longitude': 101.7874,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'cameron_highlands',
        'name': 'Cameron Highlands',
        'description':
            'Cool highland retreat with tea plantations, strawberry farms, and walking trails.',
        'category': 'Nature',
        'city': 'Tanah Rata',
        'state': 'Pahang',
        'priceRange': 'RM20-RM150',
        'rating': 4.6,
        'latitude': 4.4925,
        'longitude': 101.3805,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'taman_negara_kuala_tahan',
        'name': 'Taman Negara Kuala Tahan',
        'description':
            'Ancient rainforest park offering canopy walks, river cruises, and jungle trekking.',
        'category': 'Nature',
        'city': 'Kuala Tahan',
        'state': 'Pahang',
        'priceRange': 'RM20-RM200',
        'rating': 4.6,
        'latitude': 4.3864,
        'longitude': 102.3940,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'penang_hill',
        'name': 'Penang Hill',
        'description':
            'Hilltop nature and heritage attraction with panoramic views reached by funicular train.',
        'category': 'Nature',
        'city': 'Air Itam',
        'state': 'Penang',
        'priceRange': 'RM12-RM50',
        'rating': 4.5,
        'latitude': 5.4214,
        'longitude': 100.2732,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'langkawi_sky_bridge',
        'name': 'Langkawi Sky Bridge',
        'description':
            'Curved pedestrian bridge with dramatic island and Andaman Sea views.',
        'category': 'Nature',
        'city': 'Langkawi',
        'state': 'Kedah',
        'priceRange': 'RM20-RM85',
        'rating': 4.5,
        'latitude': 6.3772,
        'longitude': 99.6728,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'tunku_abdul_rahman_marine_park',
        'name': 'Tunku Abdul Rahman Marine Park',
        'description':
            'Cluster of tropical islands near Kota Kinabalu for snorkeling and beach hopping.',
        'category': 'Nature',
        'city': 'Kota Kinabalu',
        'state': 'Sabah',
        'priceRange': 'RM30-RM250',
        'rating': 4.7,
        'latitude': 5.9724,
        'longitude': 116.0010,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'batu_caves',
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
        'id': 'a_famosa_melaka',
        'name': 'A Famosa',
        'description':
            'Historic Portuguese fortress remains in Melaka, one of Malaysia''s oldest colonial landmarks.',
        'category': 'Historical',
        'city': 'Melaka City',
        'state': 'Melaka',
        'priceRange': 'Free-RM20',
        'rating': 4.3,
        'latitude': 2.188303,
        'longitude': 102.250183,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'petronas_twin_towers',
        'name': 'Petronas Twin Towers',
        'description':
            'Iconic twin skyscrapers in Kuala Lumpur with city views from the skybridge.',
        'category': 'Historical',
        'city': 'Kuala Lumpur',
        'state': 'Kuala Lumpur',
        'priceRange': 'RM30-RM100',
        'rating': 4.7,
        'latitude': 3.157764,
        'longitude': 101.711861,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'sultan_abdul_samad_building',
        'name': 'Sultan Abdul Samad Building',
        'description':
            'Moorish-style heritage building at Dataran Merdeka, symbolic to Malaysia''s history.',
        'category': 'Historical',
        'city': 'Kuala Lumpur',
        'state': 'Kuala Lumpur',
        'priceRange': 'Free-RM10',
        'rating': 4.4,
        'latitude': 3.1488,
        'longitude': 101.6939,
        'imageUrl': '',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'kellies_castle',
        'name': 'Kellie''s Castle',
        'description':
            'Unfinished 20th-century mansion with unique architecture and local historical stories.',
        'category': 'Historical',
        'city': 'Batu Gajah',
        'state': 'Perak',
        'priceRange': 'RM10-RM30',
        'rating': 4.2,
        'latitude': 4.5599,
        'longitude': 101.0247,
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
    return docs.length;
  }
}
