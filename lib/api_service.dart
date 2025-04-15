// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<http.Response> makeAuthenticatedRequest(
    String url, {
    dynamic body,
    String method = 'POST',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cookies = prefs.getString('sessionCookies') ?? '';

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(
          Uri.parse(url),
          headers: headers,
        );
      case 'POST':
        return await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      case 'PUT':
        return await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      case 'DELETE':
        return await http.delete(
          Uri.parse(url),
          headers: headers,
        );
      default:
        throw Exception('Unsupported HTTP method');
    }
  }

  // You can add other API-related functions here
  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }
}