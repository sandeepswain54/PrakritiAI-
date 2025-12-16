import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/Widgets/posting_grid_tile_ui.dart';
import 'package:service_app/views/view_posting_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Booking extends StatefulWidget {
  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = "name";
  bool _isNameSelected = false;
  bool _isCitySelected = false;
  bool _isTypeSelected = false;

  // Ayurvedic colors
  final Color _primaryColor = Color(0xFF2E7D32); // Deep green
  final Color _secondaryColor = Color(0xFF8BC34A); // Light green
  final Color _accentColor = Color(0xFF795548); // Earth brown
  final Color _backgroundColor = Color(0xFFF5F5DC); // Beige background
  final Color _cardColor = Color(0xFFFFFDE7); // Light yellow
  final Color _textColor = Color(0xFF5D4037); // Dark brown

  final List<String> carouselImages = [
    'assets/jj.png',
    'assets/jj6.png',
    'assets/jj5.png',
    'assets/jj9.png',
    'assets/jj10.png',
  ];
  int _currentCarouselIndex = 0;

  // Location variables
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _getCurrentLocation();
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentLocation = '${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}'.trim();
          if (_currentLocation.endsWith(',')) {
            _currentLocation = _currentLocation.substring(0, _currentLocation.length - 1);
          }
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Unable to get location';
        _isLoadingLocation = false;
      });
    }
  }

  Stream<QuerySnapshot> get _postingsStream =>
    FirebaseFirestore.instance.collection('postings').snapshots();

  Stream<QuerySnapshot> get _serviceListingsStream =>
    FirebaseFirestore.instance.collection('service_listings').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            expandedHeight: 260, // Reduced height to prevent overflow
            backgroundColor: _primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0), // Reduced top padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location widget with Ayurvedic styling
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _primaryColor,
                              size: 20, // Smaller icon
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _currentLocation,
                                style: TextStyle(
                                  fontSize: 15, // Smaller font
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (_isLoadingLocation)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: _primaryColor,
                                    size: 18, // Smaller icon
                                  ),
                                  onPressed: _getCurrentLocation,
                                  padding: EdgeInsets.all(6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20), // Reduced spacing
                      // Carousel with Ayurvedic styling
                      Container(
                        height: 140, // Reduced height
                        child: CarouselSlider(
                          items: carouselImages.map((image) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: AssetImage(image),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          options: CarouselOptions(
                            height: 140, // Reduced height
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            autoPlayInterval: Duration(seconds: 4),
                            onPageChanged: (index, reason) {
                              setState(() => _currentCarouselIndex = index);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 10), // Reduced spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: carouselImages.asMap().entries.map((entry) {
                          return Container(
                            width: 8, // Smaller dots
                            height: 8,
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentCarouselIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchBarDelegate(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Recommended Therapy heading with Ayurvedic styling
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 4), // Reduced padding
                      child: Column(
                        children: [
                          Icon(
                            Icons.spa,
                            color: _primaryColor,
                            size: 24, // Smaller icon
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Recommended Ayurvedic Therapy",
                            style: TextStyle(
                              fontSize: 18, // Smaller font
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 2), // Reduced spacing
                          Text(
                            "Discover holistic healing treatments",
                            style: TextStyle(
                              fontSize: 11, // Smaller font
                              color: _textColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 0),
                    // Search bar with Ayurvedic styling
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search Ayurvedic treatments, therapies...",
                          hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search, color: _primaryColor, size: 20), // Smaller icon
                          filled: true,
                          fillColor: _cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Reduced padding
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(12), // Reduced padding
              child: StreamBuilder<QuerySnapshot>(
                stream: _postingsStream,
                builder: (context, postingsSnapshot) {
                  if (!postingsSnapshot.hasData) {
                    return Container(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                        ),
                      ),
                    );
                  }

                  // Nest a second StreamBuilder to also listen to service_listings in real-time
                  return StreamBuilder<QuerySnapshot>(
                    stream: _serviceListingsStream,
                    builder: (context, servicesSnapshot) {
                      if (!servicesSnapshot.hasData) {
                        return Container(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                            ),
                          ),
                        );
                      }

                      // Map postings collection
                      final postingsList = postingsSnapshot.data!.docs.map((doc) {
                        final posting = PostingModel.fromMap(doc.data() as Map<String, dynamic>);
                        posting.id = doc.id;
                        return posting;
                      }).toList();

                      // Map service_listings collection (created by hosts via Create Posting screen)
                      final servicesList = servicesSnapshot.data!.docs.map((doc) {
                        final posting = PostingModel.fromMap(doc.data() as Map<String, dynamic>);
                        posting.id = doc.id;
                        return posting;
                      }).toList();

                      // Combine both lists and dedupe by id (service_listings may contain different ids)
                      final Map<String, PostingModel> combinedMap = {};
                      for (final p in postingsList) combinedMap[p.id ?? ''] = p;
                      for (final s in servicesList) combinedMap[s.id ?? ''] = s;

                      final allItems = combinedMap.values.toList();

                      final query = _searchController.text.trim().toLowerCase();
                      final results = allItems.where((posting) {
                        if (query.isEmpty) return true;
                        switch (_searchType) {
                          case 'name':
                            return (posting.name ?? '').toLowerCase().contains(query);
                          case 'city':
                            return (posting.city ?? '').toLowerCase().contains(query);
                          case 'type':
                            return (posting.type ?? '').toLowerCase().contains(query);
                          case 'address':
                            return (posting.address ?? '').toLowerCase().contains(query);
                          default:
                            return false;
                        }
                      }).toList();

                      if (results.isEmpty) {
                        return Container(
                          height: 200, // Fixed height for empty state
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.spa,
                                size: 50, // Smaller icon
                                color: _primaryColor.withOpacity(0.3),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "No treatments found",
                                style: TextStyle(
                                  fontSize: 16, // Smaller font
                                  color: _textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Try searching with different keywords",
                                style: TextStyle(
                                  color: _textColor.withOpacity(0.6),
                                  fontSize: 12, // Smaller font
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12, // Reduced spacing
                          mainAxisSpacing: 12, // Reduced spacing
                          childAspectRatio: 0.70, // Reduced aspect ratio to make items shorter
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return InkResponse(
                            onTap: () => Get.to(ViewPostingScreen(posting: item)),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12), // Smaller radius
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4, // Reduced blur
                                    offset: Offset(0, 2), // Smaller offset
                                  ),
                                ],
                              ),
                              child: PostingGridTileUi(
                                posting: item,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSearch(String type, bool nameSelected, bool citySelected, bool typeSelected, [String? value]) {
    setState(() {
      _searchType = type;
      _isNameSelected = nameSelected;
      _isCitySelected = citySelected;
      _isTypeSelected = typeSelected;
      if (value != null) {
        _searchController.text = value;
      }
    });
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        backgroundColor: isSelected ? _primaryColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? _primaryColor : Colors.grey[300]!),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(text),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchBarDelegate({required this.child});

  @override
  double get minExtent => 160; // Reduced height
  @override
  double get maxExtent => 160; // Reduced height

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}