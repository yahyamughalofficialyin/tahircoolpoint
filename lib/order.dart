import 'package:flutter/material.dart';
import 'home.dart';

class Order extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        title: Text(
          'Orders',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // First Card
            _buildOrderCard(
              image: 'images/electrician.jpg',
              title: 'Electrician',
              location: 'Karachi, Pakistan',
            ),
            // Second Card
            _buildOrderCard(
              image: 'images/painter.jpg',
              title: 'Painter',
              location: 'Lahore, Pakistan',
            ),
            // Third Card
            _buildOrderCard(
              image: 'images/carpenter.jpg',
              title: 'Carpenter',
              location: 'Islamabad, Pakistan',
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Rounded corners for BottomAppBar
        ),
        child: BottomAppBar(
          color: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF), // Footer color
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
                  ); // Navigate to Home page
                },
              ),
              IconButton(
                icon: Icon(Icons.person, color: Color(0xFF00A7DD)), // Footer icon color
                tooltip: 'Profile',
                onPressed: () {
                  // Add profile navigation logic here
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String image,
    required String title,
    required String location,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners for cards
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Image on the left
            ClipRRect(
              borderRadius: BorderRadius.circular(10), // Rounded corners for image
              child: Image.asset(
                image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            // Title in the center
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 16),
            // Location on the right
            Text(
              location,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}