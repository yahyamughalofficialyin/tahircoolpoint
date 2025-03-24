import 'package:flutter/material.dart';

class Category extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // Star Rating
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '4.5',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  Icon(Icons.star_half, color: Colors.amber, size: 20),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 6 Rows with Cards
            _buildCardRow(
              image: 'images/electrician.jpg',
              heading: 'Electrician',
              subheading: 'Professional Services',
              price: '\$50/hr',
              rating: 4.5,
            ),
            _buildCardRow(
              image: 'images/painter.jpg',
              heading: 'Painter',
              subheading: 'Wall Painting',
              price: '\$40/hr',
              rating: 4.0,
            ),
            _buildCardRow(
              image: 'images/carpenter.jpg',
              heading: 'Carpenter',
              subheading: 'Furniture Repair',
              price: '\$60/hr',
              rating: 4.7,
            ),
            _buildCardRow(
              image: 'images/ac.jpg',
              heading: 'Air Conditioner',
              subheading: 'AC Repair',
              price: '\$70/hr',
              rating: 4.2,
            ),
            _buildCardRow(
              image: 'images/gyser.jpg',
              heading: 'Geyser',
              subheading: 'Geyser Installation',
              price: '\$80/hr',
              rating: 4.8,
            ),
            _buildCardRow(
              image: 'images/washingmachine.jpg',
              heading: 'Haeir',
              subheading: 'Hair Styling',
              price: '\$30/hr',
              rating: 4.3,
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
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.home, color: Color(0xFF00A7DD)), // Footer icon color
                tooltip: 'Home',
                onPressed: () {},
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
    );
  }

  Widget _buildCardRow({
    required String image,
    required String heading,
    required String subheading,
    required String price,
    required double rating,
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
            // Heading, Subheading, Price, and Star Ratings in the center
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subheading,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    price,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star_half, color: Colors.amber, size: 16),
                      SizedBox(width: 5),
                      Text(
                        rating.toString(),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add to Cart Button on the right
            ElevatedButton(
              onPressed: () {
                // Add to cart logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00A7DD), // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners for button
                ),
              ),
              child: Icon(
                Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }
}