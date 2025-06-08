import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'dart:convert';

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

  // Register with local storage (no API available)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Skip API registration attempt and directly use mockRegister
      return await mockRegister(name: name, email: email, password: password);
    } catch (e) {
      print('Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock register for offline mode or testing
  Future<bool> mockRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Get existing users from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString('mock_users');
      
      // Parse existing users or create empty map
      Map<String, dynamic> mockUsers = {};
      if (usersJson != null) {
        mockUsers = json.decode(usersJson);
      }
      
      // Check if email already exists
      if (mockUsers.containsKey(email)) {
        return false; // Email already registered
      }
      
      // Create new user
      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'email': email,
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Add user to mock users
      mockUsers[email] = newUser;
      
      // Add password to mock passwords
      final String? passwordsJson = prefs.getString('mock_passwords');
      Map<String, dynamic> mockPasswords = {};
      if (passwordsJson != null) {
        mockPasswords = json.decode(passwordsJson);
      }
      mockPasswords[email] = password;
      
      // Save updated users and passwords
      await prefs.setString('mock_users', json.encode(mockUsers));
      await prefs.setString('mock_passwords', json.encode(mockPasswords));
      
      return true;
    } catch (e) {
      print('Mock registration error: $e');
      return false;
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
      
      // Default mockup users
      Map<String, Map<String, dynamic>> defaultMockUsers = {
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

      Map<String, String> defaultMockPasswords = {
        'user@user.com': '123456',
        'admin@admin.com': '123456',
      };
      
      // Get registered users from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString('mock_users');
      final String? passwordsJson = prefs.getString('mock_passwords');
      
      // Combine default and registered users
      Map<String, Map<String, dynamic>> mockUsers = {...defaultMockUsers};
      Map<String, String> mockPasswords = {...defaultMockPasswords};
      
      if (usersJson != null) {
        final Map<String, dynamic> registeredUsers = json.decode(usersJson);
        registeredUsers.forEach((key, value) {
          mockUsers[key] = Map<String, dynamic>.from(value);
        });
      }
      
      if (passwordsJson != null) {
        final Map<String, dynamic> registeredPasswords = json.decode(passwordsJson);
        registeredPasswords.forEach((key, value) {
          mockPasswords[key] = value.toString();
        });
      }

      final mockUser = mockUsers[email];
      final correctPassword = mockPasswords[email];

      if (mockUser != null && correctPassword == password) {
        _user = User.fromJson(mockUser);
        
        // Save to SharedPreferences
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
