import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/attraction.dart';
import '../data/attractions_data.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = "All";
  Attraction? selectedAttraction;
  List<Attraction> filteredAttractions = [];

  @override
  void initState() {
    super.initState();
    filteredAttractions = List.from(allAttractions);
    searchController.addListener(_filterAttractions);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterAttractions() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredAttractions = allAttractions.where((attraction) {
        bool matchesSearch = attraction.name.toLowerCase().contains(query);
        bool matchesCategory =
            selectedCategory == "All" || attraction.category == selectedCategory;
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
      _filterAttractions();
    });
  }

  void _onMarkerTap(Attraction attraction) {
    setState(() {
      selectedAttraction = attraction;
    });
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
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.malaysia_travel',
              ),
              MarkerLayer(
                markers: filteredAttractions.map((attraction) {
                  return Marker(
                    width: 50,
                    height: 50,
                    point: attraction.coordinates,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(attraction),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.teal.shade600,
                          child: Text(attraction.iconEmoji, style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
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
                  BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 3)),
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
                            child: Text(selectedAttraction!.iconEmoji, style: TextStyle(fontSize: 28)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedAttraction!.name,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () => setState(() => selectedAttraction = null),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(selectedAttraction!.description, style: TextStyle(fontSize: 14)),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(selectedAttraction!.category, style: TextStyle(color: Colors.teal.shade700)),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("More info about ${selectedAttraction!.name} coming soon!")),
                              );
                            },
                            child: Text("Learn More", style: TextStyle(color: Colors.teal)),
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
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
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
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.teal.shade700),
            SizedBox(width: 6),
            Text(category),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(category),
        backgroundColor: Colors.white,
        selectedColor: Colors.teal.shade600,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.teal.shade800),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: StadiumBorder(),
      ),
    );
  }
}