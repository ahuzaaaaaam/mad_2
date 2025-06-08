import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../config/app_config.dart';

class ApiService {
  // Base URL for API calls - from config
  static final String baseUrl = AppConfig.apiBaseUrl;
  
  // Token key for storage
  static const String tokenKey = 'auth_token';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save token to storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Clear token from storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Headers with authorization
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login user
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/tokens'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': 'flutter_app',
        }),
      ).timeout(Duration(seconds: AppConfig.loginTimeout));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out. Please try again.'};
    } on SocketException {
      return {'success': false, 'message': 'Network error. Please check your internet connection.'};
    } catch (e) {
      print('Login error: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Register user
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Logout user
  static Future<bool> logout() async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tokens'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await clearToken();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get all products
  static Future<List<dynamic>> getProducts() async {
    try {
      print('Fetching products from API: $baseUrl/products');
      
      // First check if we're online
      final bool online = await isOnline();
      if (!online) {
        print('Device is offline, using local products');
        return await getLocalProducts();
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: await getHeaders(),
      ).timeout(Duration(seconds: AppConfig.defaultTimeout));

      print('Products API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Products API response success, retrieved ${(data['data'] as List?)?.length ?? 0} products');
        return data['data'] ?? [];
      }
      print('Failed to fetch products. Status: ${response.statusCode}');
      
      // If API call fails, fall back to local data
      return await getLocalProducts();
    } on TimeoutException catch (_) {
      print('API request timed out, using local products');
      return await getLocalProducts();
    } on SocketException catch (_) {
      print('Network error (SocketException), using local products');
      return await getLocalProducts();
    } catch (e) {
      print('Error fetching products: ${e.toString()}');
      // Return local products on error
      return await getLocalProducts();
    }
  }

  // Get product details
  static Future<Map<String, dynamic>?> getProduct(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Log product activity
  static Future<bool> logProductActivity(String activity, String? productId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/product-activity'),
        headers: headers,
        body: jsonEncode({
          'activity': activity,
          'product_id': productId,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Get products from local JSON file (for offline mode)
  static Future<List<dynamic>> getLocalProducts() async {
    try {
      print('Fetching products from local JSON file');
      final jsonString = await rootBundle.loadString('assets/data/products.json');
      final products = json.decode(jsonString);
      print('Loaded ${products.length} products from local JSON');
      return products;
    } catch (e) {
      print('Error loading local products: ${e.toString()}');
      return [];
    }
  }

  // Check if online and API is reachable
  static Future<bool> isOnline() async {
    if (kIsWeb) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/ping'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      } catch (e) {
        print('API connectivity check failed: $e');
        return false;
      }
    } else {
      try {
        // More robust connectivity check for mobile
        final List<InternetAddress> result = await InternetAddress.lookup('google.com');
        final bool hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        
        if (hasConnection) {
          // If internet is available, check if our API is reachable
          try {
            final response = await http.get(
              Uri.parse('$baseUrl/products'),
              headers: {'Accept': 'application/json'},
            ).timeout(const Duration(seconds: 3));
            
            return response.statusCode >= 200 && response.statusCode < 400;
          } catch (e) {
            print('API endpoint check failed: $e');
            return false;
          }
        }
        
        return false;
      } on SocketException catch (_) {
        print('No internet connection available');
        return false;
      }
    }
  }
  
  // Helper function to limit string length
  static int min(int a, int b) {
    return a < b ? a : b;
  }

  // Get order history - NOTE: This is not used, we use local JSON files instead
  static Future<List<dynamic>> getOrderHistory() async {
    // Return empty list as we only use local JSON storage for orders
    print('Using local JSON for order history instead of API');
    return [];
  }

  // Save order to API - NOTE: This is not used, we use local JSON files instead
  static Future<bool> saveOrder(Map<String, dynamic> order) async {
    // Always return false as we only use local JSON storage for orders
    print('Using local JSON for order saving instead of API');
    return false;
  }
} 