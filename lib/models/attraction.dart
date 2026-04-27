import 'package:latlong2/latlong.dart';

class Attraction {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final String category; // "Nature", "Historical", "Food"
  final String iconEmoji;
  final String city;
  final String state;
  final String priceRange;
  final double rating;
  final String imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.category,
    this.iconEmoji = '📍',
    this.city = '',
    this.state = '',
    this.priceRange = '',
    this.rating = 0,
    this.imageUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  Attraction copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? coordinates,
    String? category,
    String? iconEmoji,
    String? city,
    String? state,
    String? priceRange,
    double? rating,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attraction(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coordinates: coordinates ?? this.coordinates,
      category: category ?? this.category,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      city: city ?? this.city,
      state: state ?? this.state,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}