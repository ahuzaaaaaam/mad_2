import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Login with API
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);

      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with API
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.register(name, email, password);
      return result['success'] == true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout with API
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check authentication status
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    
    if (token != null) {
      // TODO: Implement API call to get user details
      // For now, we'll just assume the user is authenticated if there's a token
      _user = User(
        id: '1',
        name: 'Authenticated User',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Mock login for offline mode or testing
  Future<bool> mockLogin(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Mockup users
      final Map<String, Map<String, dynamic>> mockUsers = {
        'user@user.com': {
          'id': '1',
          'name': 'John Doe',
          'email': 'user@user.com',
          'role': 'user',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        'admin@admin.com': {
          'id': '2',
          'name': 'Admin User',
          'email': 'admin@admin.com',
          'role': 'admin',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      };

      final Map<String, String> mockPasswords = {
        'user@user.com': '123456',
        'admin@admin.com': '123456',
      };

      final mockUser = mockUsers[email];
      final correctPassword = mockPasswords[email];

      if (mockUser != null && correctPassword == password) {
        _user = User.fromJson(mockUser);
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
