import 'package:flutter/material.dart';
import 'package:tahircoolpoint/profile.dart';
import 'category.dart';
import 'order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String cloudinaryId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cloudinaryId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      cloudinaryId: json['cloudinaryId'],
    );
  }
}

class SliderModel {
  final String id;
  final String imageUrl;
  final String cloudinaryId;

  SliderModel({
    required this.id,
    required this.imageUrl,
    required this.cloudinaryId,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      id: json['_id'],
      imageUrl: json['imageUrl'],
      cloudinaryId: json['cloudinaryId'],
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isDarkMode = false;
  String _userName = "Guest";
  List<CategoryModel> _categories = [];
  List<SliderModel> _sliders = [];
  bool _isLoading = true;
  bool _isSliderLoading = true;
  String _errorMessage = '';
  String _sliderErrorMessage = '';
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserData();
      await _fetchSliders();
      await _fetchCategories();
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(Duration(seconds: 5)).then((_) {
      if (_pageController.hasClients && _sliders.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _sliders.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('userName');

      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _userName = savedName;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _fetchSliders() async {
    setState(() {
      _isSliderLoading = true;
      _sliderErrorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/sliders'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _sliders = data.map((json) => SliderModel.fromJson(json)).toList();
          _isSliderLoading = false;
        });
      } else {
        setState(() {
          _sliderErrorMessage = 'Failed to load sliders: ${response.statusCode}';
          _isSliderLoading = false;
        });
        print('Error response: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _sliderErrorMessage = 'Error fetching sliders: $e';
        _isSliderLoading = false;
      });
      print('Exception: $e');
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load categories: ${response.statusCode}';
          _isLoading = false;
        });
        print('Error response: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching categories: $e';
        _isLoading = false;
      });
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final carouselHeight = MediaQuery.of(context).size.width * 0.5;

    return Scaffold(
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Row(
          children: [
            Image.asset('images/icon.png', height: 60),
            Spacer(),
            Text(
              'Hi, $_userName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Slider Carousel Section
            if (_isSliderLoading)
              Container(
                height: carouselHeight,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sliderErrorMessage.isNotEmpty)
              Container(
                height: carouselHeight,
                child: Center(child: Text(_sliderErrorMessage)),
              )
            else if (_sliders.isNotEmpty)
              _buildSliderCarousel(carouselHeight),
            SizedBox(height: 20),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(child: Text(_errorMessage))
            else
              _buildCategoriesGrid(),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  child: BottomAppBar(
    color: Colors.white, // Keep the bar white
    elevation: 4,
    child: Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGradientIconButton(
            icon: Icons.shopping_cart,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Order()),
            ),
          ),
          _buildGradientIconButton(
            icon: Icons.home,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            ),
          ),
          _buildGradientIconButton(
            icon: Icons.person,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
        ],
      ),
    ),
  ),
),


    );
  }

// Add this helper method to your _HomeState class
Widget _buildGradientIconButton({required IconData icon, required VoidCallback onPressed}) {
  return IconButton(
    icon: ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [Color(0xFFfe0000), Color(0xFF000000)],
          stops: [0.0, 0.8],
        ).createShader(bounds);
      },
      child: Icon(icon, size: 28, color: Colors.white),
    ),
    onPressed: onPressed,
  );
}

  Widget _buildSliderCarousel(double height) {
    return Column(
      children: [
        Container(
          height: height,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _sliders.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _sliders[index].imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 10),
        if (_sliders.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_sliders.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.4),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
  return GridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.all(12),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85, // Slightly adjusted for better proportions
    ),
    itemCount: _categories.length,
    itemBuilder: (context, index) {
      return _buildCategoryCard(_categories[index]);
    },
  );
}

  Widget _buildCategoryCard(CategoryModel category) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Category(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
      );
    },
    child: Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Image container with same size but smaller image
          Container(
            height: 100, // Maintain container height
            padding: EdgeInsets.all(5),
            child: Center( // Center the smaller image
              child: Container(
                width: 80, // Smaller image width
                height: 50, // Smaller image height
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: category.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Category name
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
}