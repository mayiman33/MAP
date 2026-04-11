import 'package:latlong2/latlong.dart';
import '../models/attraction.dart';

final List<Attraction> allAttractions = [
  Attraction(
    name: "Petronas Twin Towers",
    description: "Iconic twin skyscrapers in Kuala Lumpur, offering stunning city views from the skybridge.",
    coordinates: LatLng(3.1578, 101.7117),
    category: "Historical",
    iconEmoji: "🏙️",
  ),
  Attraction(
    name: "George Town, Penang",
    description: "Famous for its street art, colonial architecture, and delicious street food.",
    coordinates: LatLng(5.4141, 100.3288),
    category: "Historical",
    iconEmoji: "🎨",
  ),
  Attraction(
    name: "Langkawi Sky Bridge",
    description: "A curved pedestrian bridge offering breathtaking views of the Andaman Sea.",
    coordinates: LatLng(6.3772, 99.6728),
    category: "Nature",
    iconEmoji: "🌉",
  ),
  Attraction(
    name: "Mount Kinabalu",
    description: "The highest mountain in Borneo, a UNESCO World Heritage site with diverse flora and fauna.",
    coordinates: LatLng(6.0750, 116.5588),
    category: "Nature",
    iconEmoji: "⛰️",
  ),
  Attraction(
    name: "Jonker Street, Malacca",
    description: "Vibrant night market street known for antiques, local crafts, and Nyonya cuisine.",
    coordinates: LatLng(2.1952, 102.2477),
    category: "Food",
    iconEmoji: "🍜",
  ),
  Attraction(
    name: "Batu Caves",
    description: "Limestone hill with a series of caves and Hindu temples, guarded by a giant golden statue.",
    coordinates: LatLng(3.2374, 101.6839),
    category: "Historical",
    iconEmoji: "🕉️",
  ),
  Attraction(
    name: "Cameron Highlands",
    description: "Cool hill station famous for tea plantations, strawberry farms, and scenic trails.",
    coordinates: LatLng(4.4925, 101.3805),
    category: "Nature",
    iconEmoji: "🍃",
  ),
  Attraction(
    name: "Penang Street Food (Gurney Drive)",
    description: "Hawker centre offering a wide variety of authentic Malaysian dishes like Char Koay Teow.",
    coordinates: LatLng(5.4392, 100.3090),
    category: "Food",
    iconEmoji: "🍲",
  ),
];