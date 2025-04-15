import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final double amount;

  const PaymentPage({Key? key, required this.orderId, required this.amount}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _paymentIdController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitPayment(String method, [String? paymentId]) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/orders/payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': widget.orderId,
          'paymentMethod': method,
          'paymentId': paymentId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Order()),
        );
      } else {
        throw Exception('Payment failed: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showPaymentDialog(String method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter ${method.toUpperCase()} Payment ID'),
          content: TextField(
            controller: _paymentIdController,
            decoration: InputDecoration(
              hintText: 'Enter your ${method.toUpperCase()} transaction ID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_paymentIdController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter payment ID')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _submitPayment(method, _paymentIdController.text);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String imageAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                imageAsset,
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => Icon(Icons.payment, size: 50),
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount:',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
            ),
            Text(
              'PKR ${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Select Payment Method:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentOption(
                    imageAsset: 'images/easypaisa.png',
                    title: 'Easypaisa',
                    onTap: () => _showPaymentDialog('easypaisa'),
                  ),
                  SizedBox(height: 12),
                  _buildPaymentOption(
                    imageAsset: 'images/jazzcash.png',
                    title: 'JazzCash',
                    onTap: () => _showPaymentDialog('jazzcash'),
                  ),
                  SizedBox(height: 12),
                  _buildPaymentOption(
                    imageAsset: 'images/bankalhabib.png',
                    title: 'Bank Al-Habib',
                    onTap: () => _showPaymentDialog('bankalhabib'),
                  ),
                  SizedBox(height: 12),
                  _buildPaymentOption(
                    imageAsset: 'images/cash.png',
                    title: 'Cash',
                    onTap: () async {
                      await _submitPayment('cash');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    super.dispose();
  }
}