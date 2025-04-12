import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tahircoolpoint/profile.dart';
import 'dart:convert';
import 'home.dart';

class Order extends StatefulWidget {
  @override
  _OrderState createState() => _OrderState();
}

class _OrderState extends State<Order> {
  List<dynamic> orders = [];
  Map<String, dynamic> productsCache = {}; // Cache for product details
  bool isLoading = true;
  String? userId;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserIdAndOrders();
  }

  Future<void> _loadUserIdAndOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getString('userId');
      });
      
      if (userId != null) {
        await _fetchOrders();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'User not logged in';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading user data';
      });
    }
  }

  Future<void> _fetchOrders() async {
    try {
      // First fetch all orders for the user
      final ordersResponse = await http.get(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/api/my-orders/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (ordersResponse.statusCode == 200) {
        final List<dynamic> fetchedOrders = json.decode(ordersResponse.body);
        
        // Then fetch all products to get details
        final productsResponse = await http.get(
          Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/api/products/'),
          headers: {'Content-Type': 'application/json'},
        );

        if (productsResponse.statusCode == 200) {
          final List<dynamic> allProducts = json.decode(productsResponse.body);
          
          // Create a map of productId to product details for quick lookup
          for (var product in allProducts) {
            productsCache[product['_id']] = product;
          }

          // Combine orders with their product details
          final List<dynamic> ordersWithProducts = [];
          for (var order in fetchedOrders) {
            final productId = order['productId'];
            final productDetails = productsCache[productId];
            
            ordersWithProducts.add({
              ...order,
              'productDetails': productDetails,
            });
          }

          setState(() {
            orders = ordersWithProducts;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load products: ${productsResponse.statusCode}');
        }
      } else if (ordersResponse.statusCode == 404) {
        setState(() {
          isLoading = false;
          errorMessage = 'No orders found';
        });
      } else {
        throw Exception('Failed to load orders: ${ordersResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Orders',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : orders.isEmpty
                  ? Center(child: Text('No orders found'))
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final product = order['productDetails'];
                          
                          return _buildOrderCard(
                            context: context,
                            order: order,
                            product: product,
                            cardColor: cardColor,
                            textColor: textColor,
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: _buildBottomNavigationBar(isDarkMode),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required dynamic order,
    required dynamic product,
    required Color cardColor,
    required Color textColor,
  }) {
    Color statusColor;
    switch (order['status']?.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'in progress':
        statusColor = Colors.orange;
        break;
      case 'requested':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product != null && product['productImage'] != null
                      ? Image.network(
                          product['productImage'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 80),
                        )
                      : Icon(Icons.shopping_bag, size: 80),
                ),
                SizedBox(width: 16),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product != null ? product['title'] : 'Unknown Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Price: ${order['price'] ?? product?['price'] ?? 'N/A'}',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      if (product != null && product['categoryId'] != null)
                        Text(
                          'Category: ${product['categoryId']['name']}',
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                      SizedBox(height: 8),
                      Chip(
                        label: Text(
                          order['status']?.toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: statusColor,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24, thickness: 1),
            // Location Section
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['locationName'] ?? 'Unknown location',
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Date Section
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Ordered on: ${_formatDate(order['createdAt'])}',
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    return BottomAppBar(
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Color(0xFF00A7DD)),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Order()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.home, color: Color(0xFF00A7DD)),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.person, color: Color(0xFF00A7DD)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}