import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/data_sync_service.dart';

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
      // Use the data sync service to get products with automatic syncing
      final productData = await DataSyncService.syncProducts();
      
      // Convert to Product objects
      _products = [];
      for (var json in productData) {
        try {
          _products.add(Product.fromJson(json));
        } catch (e) {
          print('Error parsing product: $e');
          // Skip this item and continue
        }
      }
      
      // Filter featured products
      _featuredProducts = _products.where((product) => product.isFeatured).toList();
      
      // Load favorites
      await loadFavorites();
      
      _status = ProductLoadingStatus.loaded;
    } catch (e) {
      _status = ProductLoadingStatus.error;
      _errorMessage = 'Failed to load products: ${e.toString()}';
      print('Product provider error: $_errorMessage');
      
      // Try to load from local storage as fallback
      try {
        final productData = await DataSyncService.getLocalProducts();
        _products = [];
        for (var json in productData) {
          try {
            _products.add(Product.fromJson(json));
          } catch (e) {
            print('Error parsing product (fallback): $e');
            // Skip this item and continue
          }
        }
        _featuredProducts = _products.where((product) => product.isFeatured).toList();
        await loadFavorites().catchError((e) {
          print('Error loading favorites: $e');
          // Continue without favorites
        });
        _status = ProductLoadingStatus.loaded;
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        // Keep error status
      }
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