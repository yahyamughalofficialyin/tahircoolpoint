import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tahircoolpoint/profile.dart';
import 'dart:convert';
import 'dart:ui';
import 'home.dart';
import 'payment.dart';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  List<dynamic> orders = [];
  Map<String, dynamic> productsCache = {};
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
      final ordersResponse = await http.get(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/my-orders/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (ordersResponse.statusCode == 200) {
        final List<dynamic> fetchedOrders = json.decode(ordersResponse.body);
        
        final productsResponse = await http.get(
          Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/products/'),
          headers: {'Content-Type': 'application/json'},
        );

        if (productsResponse.statusCode == 200) {
          final List<dynamic> allProducts = json.decode(productsResponse.body);
          
          for (var product in allProducts) {
            productsCache[product['_id']] = product;
          }

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
      _showErrorSnackbar('Error loading data: $e');
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

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildGradientIcon(IconData icon) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFFfe0000), Color(0xFF000000)],
          stops: [0.0, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: Icon(icon, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: _buildGradientIcon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFfe0000), Color(0xFF000000)],
              stops: [0.0, 0.8],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : orders.isEmpty
                        ? Center(
                            child: Text(
                              'No orders found',
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                final product = order['productDetails'];
                                
                                return _buildOrderCard(
                                  context: context,
                                  order: order,
                                  product: product,
                                );
                              },
                            ),
                          ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required dynamic order,
    required dynamic product,
  }) {
    Color statusColor;
    String statusText = order['status']?.toLowerCase() ?? 'unknown';
    
    switch (statusText) {
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
      case 'paid':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product != null && product['productImage'] != null
                      ? Image.network(
                          product['productImage'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => 
                              _buildGradientIcon(Icons.image),
                        )
                      : _buildGradientIcon(Icons.shopping_bag),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product != null ? product['title'] : 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ${order['price']?.toStringAsFixed(2) ?? product?['price']?.toStringAsFixed(2) ?? 'N/A'} PKR',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (product != null && product['categoryId'] != null)
                        Text(
                          'Category: ${product['categoryId']['name']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          statusText.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Colors.grey),
            Row(
              children: [
                _buildGradientIcon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['locationName'] ?? 'Unknown location',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGradientIcon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  'Ordered on: ${_formatDate(order['createdAt'])}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            if (statusText == 'completed' && order['price'] != null && order['status'] != 'paid') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          orderId: order['_id'],
                          amount: order['price'] is int 
                              ? order['price'].toDouble()
                              : order['price'],
                        ),
                      ),
                    ).then((_) => _fetchOrders());
                  },
                  child: const Text(
                    'PAY NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            if (statusText == 'paid') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGradientIcon(Icons.payment),
                  const SizedBox(width: 8),
                  Text(
                    'Paid via ${order['paymentMethod'] ?? 'unknown method'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: _buildGradientIcon(Icons.shopping_cart),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Order()),
              ),
            ),
            IconButton(
              icon: _buildGradientIcon(Icons.home),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              ),
            ),
            IconButton(
              icon: _buildGradientIcon(Icons.person),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}