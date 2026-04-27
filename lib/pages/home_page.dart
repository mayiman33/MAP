import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/attraction.dart';
import '../services/auth_service.dart';
import '../services/firebase_place_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebasePlaceService _placeService = FirebasePlaceService();
  String selectedCategory = "All";
  Attraction? selectedAttraction;
  List<Attraction> _allAttractions = [];
  List<Attraction> filteredAttractions = [];
  bool _isLoading = true;
  bool _isSeeding = false;
  bool _isCreatingDemoUsers = false;
  String? _friendlyError;
  String? _fallbackMessage;
  String _dataSourceLabel = 'Local fallback';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterAttractions);
    _loadAttractions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttractions() async {
    setState(() {
      _isLoading = true;
      _friendlyError = null;
      _fallbackMessage = null;
    });

    try {
      final result = await _placeService.getPlacesWithFallback();
      setState(() {
        _allAttractions = result.attractions;
        _fallbackMessage = result.fromFallback ? result.error : null;
        _dataSourceLabel = result.fromFallback ? 'Local fallback' : 'Firestore';
        _isLoading = false;
      });
      _filterAttractions();
    } catch (e) {
      setState(() {
        _allAttractions = [];
        filteredAttractions = [];
        selectedAttraction = null;
        _isLoading = false;
        _friendlyError =
            "We couldn't load places from Firebase or local backup. Please try again.";
      });
      debugPrint('Place loading failed: $e');
    }
  }

  void _filterAttractions() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredAttractions = _allAttractions.where((attraction) {
        bool matchesSearch = attraction.name.toLowerCase().contains(query);
        bool matchesCategory = selectedCategory == "All" ||
            attraction.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();

      if (selectedAttraction != null &&
          !filteredAttractions.contains(selectedAttraction)) {
        selectedAttraction = null;
      }
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
    _filterAttractions();
  }

  void _onMarkerTap(Attraction attraction) {
    setState(() {
      selectedAttraction = attraction;
    });
  }

  Future<void> _seedFirestore() async {
    setState(() {
      _isSeeding = true;
    });
    try {
      final seededCount = await _placeService.seedSamplePlaces();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$seededCount places seeded successfully')),
      );
      await _loadAttractions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seed failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  Future<void> _createDemoUsers() async {
    setState(() {
      _isCreatingDemoUsers = true;
    });
    try {
      await _authService.createDemoUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo users are ready')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo user creation failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingDemoUsers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(4.2105, 101.9758),
              initialZoom: 6.5,
              minZoom: 5,
              maxZoom: 15,
              onTap: (_, __) {
                setState(() {
                  selectedAttraction = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.malaysia_travel',
              ),
              MarkerLayer(
                markers: filteredAttractions.map((attraction) {
                  final isSelected = selectedAttraction?.id == attraction.id;

                  return Marker(
                    width: isSelected ? 62 : 54,
                    height: isSelected ? 62 : 54,
                    point: attraction.coordinates,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(attraction),
                      child:
                          _buildMapMarker(attraction, isSelected: isSelected),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          // 搜索栏
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search places...",
                  prefixIcon: Icon(Icons.search, color: Colors.teal),
                  border: InputBorder.none,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            _filterAttractions();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          // 筛选芯片
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", Icons.explore),
                  _buildFilterChip("Nature", Icons.forest),
                  _buildFilterChip("Historical", Icons.history_edu),
                  _buildFilterChip("Food", Icons.restaurant),
                ],
              ),
            ),
          ),
          if (_fallbackMessage != null)
            Positioned(
              top: 160,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _fallbackMessage!,
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                ),
              ),
            ),
          if (_friendlyError != null)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text(
                        _friendlyError!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAttractions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (kDebugMode)
            Positioned(
              top: 200,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _seedFirestore,
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload, size: 16),
                    label: Text(_isSeeding ? 'Seeding...' : 'Seed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isCreatingDemoUsers ? null : _createDemoUsers,
                    icon: _isCreatingDemoUsers
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text(
                      _isCreatingDemoUsers
                          ? 'Creating...'
                          : 'Create Demo Users',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (kDebugMode && _friendlyError == null && !_isLoading)
            Positioned(
              bottom: selectedAttraction == null ? 70 : 210,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Data source: $_dataSourceLabel',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          // 详情卡片
          if (selectedAttraction != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(selectedAttraction!.iconEmoji,
                                style: TextStyle(fontSize: 28)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedAttraction!.name,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () =>
                                setState(() => selectedAttraction = null),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(selectedAttraction!.description,
                          style: TextStyle(fontSize: 14)),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${selectedAttraction!.city}, ${selectedAttraction!.state}',
                              style: TextStyle(color: Colors.teal.shade700),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            selectedAttraction!.priceRange.isEmpty
                                ? 'N/A'
                                : selectedAttraction!.priceRange,
                            style: TextStyle(color: Colors.teal.shade700),
                          ),
                          Spacer(),
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            selectedAttraction!.rating.toStringAsFixed(1),
                            style: TextStyle(color: Colors.teal.shade700),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(selectedAttraction!.category,
                              style: TextStyle(color: Colors.teal.shade700)),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "More info about ${selectedAttraction!.name} coming soon!")),
                              );
                            },
                            child: Text("Learn More",
                                style: TextStyle(color: Colors.teal)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 提示文字
          if (selectedAttraction == null && filteredAttractions.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30)),
                child: Text(
                  "Tap on any marker to see details",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, IconData icon) {
    bool isSelected = selectedCategory == category;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.teal.shade700),
            SizedBox(width: 6),
            Text(category),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(category),
        backgroundColor: Colors.white,
        selectedColor: Colors.teal.shade600,
        labelStyle:
            TextStyle(color: isSelected ? Colors.white : Colors.teal.shade800),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: StadiumBorder(),
      ),
    );
  }

  Widget _buildMapMarker(
    Attraction attraction, {
    required bool isSelected,
  }) {
    final markerStyle = _markerStyleFor(attraction);
    final imageUrl = attraction.imageUrl.trim();
    final size = isSelected ? 58.0 : 48.0;
    final contentSize = isSelected ? 46.0 : 38.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: isSelected ? 1.08 : 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isSelected ? Colors.teal.shade700 : Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isSelected ? 0.28 : 0.18,
                ),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: contentSize,
                    height: contentSize,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildCategoryMarkerIcon(markerStyle);
                    },
                    errorBuilder: (_, __, ___) {
                      return _buildCategoryMarkerIcon(markerStyle);
                    },
                  )
                : _buildCategoryMarkerIcon(markerStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryMarkerIcon(_MarkerStyle markerStyle) {
    return Container(
      color: markerStyle.backgroundColor,
      alignment: Alignment.center,
      child: Icon(
        markerStyle.icon,
        color: markerStyle.iconColor,
        size: 24,
      ),
    );
  }

  _MarkerStyle _markerStyleFor(Attraction attraction) {
    final category = attraction.category.toLowerCase();
    final nameIndex = attraction.name.hashCode.abs();

    if (category == 'food') {
      return _foodMarkerStyles[nameIndex % _foodMarkerStyles.length];
    }

    if (category == 'nature') {
      return _natureMarkerStyles[nameIndex % _natureMarkerStyles.length];
    }

    if (category == 'historical') {
      return _historicalMarkerStyles[
          nameIndex % _historicalMarkerStyles.length];
    }

    return _defaultMarkerStyle;
  }
}

class _MarkerStyle {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _MarkerStyle({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}

final List<_MarkerStyle> _foodMarkerStyles = [
  _MarkerStyle(
    icon: Icons.restaurant,
    backgroundColor: Colors.orange.shade50,
    iconColor: Colors.deepOrange.shade600,
  ),
  _MarkerStyle(
    icon: Icons.fastfood,
    backgroundColor: Colors.amber.shade50,
    iconColor: Colors.orange.shade800,
  ),
  _MarkerStyle(
    icon: Icons.local_cafe,
    backgroundColor: Colors.brown.shade50,
    iconColor: Colors.brown.shade600,
  ),
];

final List<_MarkerStyle> _natureMarkerStyles = [
  _MarkerStyle(
    icon: Icons.forest,
    backgroundColor: Colors.green.shade50,
    iconColor: Colors.green.shade700,
  ),
  _MarkerStyle(
    icon: Icons.terrain,
    backgroundColor: Colors.teal.shade50,
    iconColor: Colors.teal.shade700,
  ),
  _MarkerStyle(
    icon: Icons.park,
    backgroundColor: Colors.lightGreen.shade50,
    iconColor: Colors.lightGreen.shade700,
  ),
];

final List<_MarkerStyle> _historicalMarkerStyles = [
  _MarkerStyle(
    icon: Icons.account_balance,
    backgroundColor: Colors.blueGrey.shade50,
    iconColor: Colors.blueGrey.shade700,
  ),
  _MarkerStyle(
    icon: Icons.location_city,
    backgroundColor: Colors.teal.shade50,
    iconColor: Colors.teal.shade800,
  ),
  _MarkerStyle(
    icon: Icons.history_edu,
    backgroundColor: Colors.indigo.shade50,
    iconColor: Colors.indigo.shade500,
  ),
];

final _MarkerStyle _defaultMarkerStyle = _MarkerStyle(
  icon: Icons.place,
  backgroundColor: Colors.teal.shade50,
  iconColor: Colors.teal.shade700,
);
