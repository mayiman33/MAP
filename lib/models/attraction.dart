import 'package:latlong2/latlong.dart';

class Attraction {
  final String name;
  final String description;
  final LatLng coordinates;
  final String category; // "Nature", "Historical", "Food"
  final String iconEmoji;

  Attraction({
    required this.name,
    required this.description,
    required this.coordinates,
    required this.category,
    this.iconEmoji = '📍',
  });
}