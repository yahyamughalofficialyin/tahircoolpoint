import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Product {
  final String id;
  final String title;
  final double price;
  final String categoryId;
  final String productImage;
  final String cloudinaryId;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.categoryId,
    required this.productImage,
    required this.cloudinaryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      title: json['title'],
      price: json['price'].toDouble(),
      categoryId: json['categoryId'],
      productImage: json['productImage'],
      cloudinaryId: json['cloudinaryId'],
    );
  }
}

class LocationSearchResult {
  final String placeId;
  final String displayName;
  final double lat;
  final double lon;

  LocationSearchResult({
    required this.placeId,
    required this.displayName,
    this.lat = 0.0,
    this.lon = 0.0,
  });
}

class Category extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const Category({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://tahircoolpoint.shaheencodecrafters.com/products/category/${widget.categoryId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load products: ${response.statusCode}';
          _isLoading = false;
        });
        print('Error response: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching products: $e';
        _isLoading = false;
      });
      print('Exception: $e');
    }
  }

  Future<void> _createOrder(
    Product product,
    String locationName,
    LatLng location,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getString('sessionCookies');
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        Fluttertoast.showToast(
          msg: "Please login again",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/orders'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': cookies ?? '',
        },
        body: jsonEncode({
          'productId': product.id,
          'locationName': locationName,
          'locationLong': location.longitude,
          'locationLat': location.latitude,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: "Order placed successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to place order. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error creating order: $e');
      Fluttertoast.showToast(
        msg: "Network error. Please check your connection.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (product) =>
              product.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<List<LocationSearchResult>> _searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&countrycodes=pk&limit=5',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => LocationSearchResult(
                placeId: item['osm_id'].toString(),
                displayName: item['display_name'],
                lat: double.parse(item['lat']),
                lon: double.parse(item['lon']),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Places search error: $e');
      return [];
    }
  }

  Future<String> _getAddressFromCoordinates(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ??
            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      }
      return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
    } catch (e) {
      return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LatLng(33.6844, 73.0479);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LatLng(33.6844, 73.0479);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LatLng(33.6844, 73.0479);
      }

      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return const LatLng(33.6844, 73.0479);
    }
  }

  void _showLocationBottomSheet(BuildContext context, Product product) {
    final TextEditingController _addressController = TextEditingController();
    LatLng? _selectedLocation;
    final MapController _mapController = MapController();
    bool _isLoadingLocation = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Delivery Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TypeAheadField<LocationSearchResult>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        hintText: 'Search for an address...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: () async {
                            setState(() => _isLoadingLocation = true);
                            final location = await _getCurrentLocation();
                            final address = await _getAddressFromCoordinates(
                              location,
                            );
                            if (mounted) {
                              setState(() {
                                _selectedLocation = location;
                                _addressController.text = address;
                                _isLoadingLocation = false;
                              });
                            }
                            _mapController.move(location, 15);
                          },
                        ),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return await _searchPlaces(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion.displayName),
                      );
                    },
                    onSuggestionSelected: (suggestion) async {
                      setState(() => _isLoadingLocation = true);
                      final location = LatLng(
                        suggestion.lat,
                        suggestion.lon,
                      );
                      final address = suggestion.displayName;
                      if (mounted) {
                        setState(() {
                          _selectedLocation = location;
                          _addressController.text = address;
                          _isLoadingLocation = false;
                        });
                      }
                      _mapController.move(location, 15);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              center: _selectedLocation ?? const LatLng(33.6844, 73.0479),
                              zoom: 15.0,
                              onTap: (tapPosition, point) async {
                                final address = await _getAddressFromCoordinates(
                                  point,
                                );
                                if (mounted) {
                                  setState(() {
                                    _selectedLocation = point;
                                    _addressController.text = address;
                                  });
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  if (_selectedLocation != null)
                                    Marker(
                                      point: _selectedLocation!,
                                      builder: (ctx) => const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (_isLoadingLocation)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              backgroundColor: const Color(0xFF00A7DD),
                              onPressed: () async {
                                setState(() => _isLoadingLocation = true);
                                final location = await _getCurrentLocation();
                                final address = await _getAddressFromCoordinates(
                                  location,
                                );
                                if (mounted) {
                                  setState(() {
                                    _selectedLocation = location;
                                    _addressController.text = address;
                                    _isLoadingLocation = false;
                                  });
                                }
                                _mapController.move(location, 15);
                              },
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedLocation != null) {
                          _createOrder(
                            product,
                            _addressController.text,
                            _selectedLocation!,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.title} will be delivered to: ${_addressController.text}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A7DD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CONFIRM LOCATION',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(child: Text(_errorMessage))
            else if (_filteredProducts.isEmpty)
              const Center(child: Text('No products found'))
            else
              Column(
                children: _filteredProducts
                    .map(
                      (product) => _buildProductCard(
                        product: product,
                        isDarkMode: isDarkMode,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Color(0xFF00A7DD)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF00A7DD)),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF00A7DD)),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required Product product,
    required bool isDarkMode,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.productImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 80),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.categoryName,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Starting From PKR. ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star_half, color: Colors.amber, size: 16),
                      SizedBox(width: 5),
                      Text('4.5', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showLocationBottomSheet(context, product),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A7DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}