import 'package:flutter/material.dart';
import 'category.dart';
import 'order.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Page',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Color(0xFFE0E0E0), // Light mode background color
        primaryColor: Color(0xFF00A7DD), // Set primary color for light theme
        colorScheme: ColorScheme.light(
          primary: Color(0xFF00A7DD), // Primary color
          secondary: Color(0xFF00A7DD), // Accent color
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212), // Dark mode background color
        primaryColor: Color(0xFF00A7DD), // Set primary color for dark theme
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00A7DD), // Primary color
          secondary: Color(0xFF00A7DD), // Accent color
        ),
      ),
      themeMode: ThemeMode.system, // Default to system theme
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.3; // 30% of screen width for each card
    final carouselHeight = screenWidth * 0.5; // 50% of screen width for carousel height

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: _isDarkMode ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212), // Dark mode background color
      ) : ThemeData.light().copyWith(
        scaffoldBackgroundColor: Color(0xFFE0E0E0), // Light mode background color
      ),
      home: Scaffold(
        appBar: AppBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20), // Rounded corners for AppBar
            ),
          ),
          title: Row(
            children: [
              Image.asset(
                'images/logo.png', // Replace with your logo image path
                height: 60, // Increased logo size
              ),
              Spacer(),
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Image Carousel with rounded corners
              Container(
                height: carouselHeight,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), // Rounded corners for carousel
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Clip carousel images to rounded corners
                  child: PageView(
                    children: [
                      Image.asset('images/carousel-1.jpg', fit: BoxFit.cover),
                      Image.asset('images/carousel-2.jpg', fit: BoxFit.cover),
                      Image.asset('images/carousel-3.jpg', fit: BoxFit.cover),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Rows of Cards
              _buildCardRow(['Electrician', 'Painter', 'Carpenter'], cardWidth), // First row with 3 cards
              _buildCardRow(['Air Conditioner', 'Geyser', 'Haeir'], cardWidth), // Second row with 3 cards
            ],
          ),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20), // Rounded corners for BottomAppBar
          ),
          child: BottomAppBar(
            color: _isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF), // Footer color
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: Color(0xFF00A7DD)), // Footer icon color
                  tooltip: 'Orders',
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Order()),
                  );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.home, color: Color(0xFF00A7DD)), // Footer icon color
                  tooltip: 'Home',
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Home()),
                  );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Color(0xFF00A7DD)), // Footer icon color
                  tooltip: 'Profile',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardRow(List<String> titles, double cardWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: titles.map((title) => _buildCard(title, 'images/${title.toLowerCase().replaceAll(' ', '-')}.png', cardWidth)).toList(),
      ),
    );
  }

  Widget _buildCard(String title, String imagePath, double cardWidth) {
    return GestureDetector(
      onTap: () {
        // Navigate to the Category screen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Category(), // Pass the title to the Category widget
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners for cards
        ),
        child: Container(
          width: cardWidth,
          height: cardWidth, // Make card height equal to width for a square shape
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10), // Rounded corners for card images
                child: Image.asset(
                  imagePath, // Use separate image for each card
                  fit: BoxFit.contain,
                  width: cardWidth * 0.5, // Image width as 50% of card width
                  height: cardWidth * 0.4, // Image height as 40% of card width
                ),
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontSize: cardWidth * 0.08, fontWeight: FontWeight.bold), // Responsive font size
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}