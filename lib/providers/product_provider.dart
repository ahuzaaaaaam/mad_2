import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

enum ProductLoadingStatus {
  initial,
  loading,
  loaded,
  error,
}

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _favoriteProducts = [];
  ProductLoadingStatus _status = ProductLoadingStatus.initial;
  String _errorMessage = '';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get favoriteProducts => _favoriteProducts;
  ProductLoadingStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Fetch products from API or local storage
  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_status == ProductLoadingStatus.loading && !forceRefresh) return;
    
    _status = ProductLoadingStatus.loading;
    notifyListeners();

    try {
      // Check if we're online
      final isOnline = await ApiService.isOnline();
      
      List<dynamic> productData = [];
      bool apiSuccess = false;
      
      if (isOnline) {
        try {
          // Fetch from API with a timeout
          productData = await ApiService.getProducts();
          apiSuccess = productData.isNotEmpty;
        } catch (e) {
          print('API fetch error: ${e.toString()}');
          apiSuccess = false;
        }
        
        // If API call fails, use local data
        if (!apiSuccess) {
          print('API fetch failed, using local data');
          productData = await ApiService.getLocalProducts();
        }
      } else {
        // Use local data if offline
        print('Device is offline, using local data');
        productData = await ApiService.getLocalProducts();
      }
      
      // Convert to Product objects
      _products = productData.map((json) => Product.fromJson(json)).toList();
      
      // Filter featured products
      _featuredProducts = _products.where((product) => product.isFeatured).toList();
      
      // Load favorites
      await loadFavorites();
      
      _status = ProductLoadingStatus.loaded;
    } catch (e) {
      _status = ProductLoadingStatus.error;
      _errorMessage = 'Failed to load products: ${e.toString()}';
      print('Product provider error: $_errorMessage');
    }
    
    notifyListeners();
  }

  // Load favorite products from database
  Future<void> loadFavorites() async {
    try {
      final favoriteData = await _dbHelper.getFavorites();
      _favoriteProducts = favoriteData.map((json) => Product.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Add product to favorites
  Future<void> addToFavorites(Product product) async {
    try {
      await _dbHelper.addFavorite(product.toJson());
      if (!_favoriteProducts.any((p) => p.id == product.id)) {
        _favoriteProducts.add(product);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  // Remove product from favorites
  Future<void> removeFromFavorites(String productId) async {
    try {
      await _dbHelper.removeFavorite(productId);
      _favoriteProducts.removeWhere((product) => product.id == productId);
      notifyListeners();
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  // Check if product is favorite
  Future<bool> isFavorite(String productId) async {
    return await _dbHelper.isFavorite(productId);
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    if (category == 'All') {
      return _products;
    } else if (category == 'Veg') {
      return _products.where((product) => product.isVeg).toList();
    } else {
      return _products.where((product) => !product.isVeg).toList();
    }
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get random product
  Product? getRandomProduct() {
    if (_products.isEmpty) return null;
    _products.shuffle();
    return _products.first;
  }
} 