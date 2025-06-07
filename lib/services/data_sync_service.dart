import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/api_service.dart';
import '../config/app_config.dart';

class DataSyncService {
  // File paths for local data storage
  static const String _productsFileName = 'products.json';
  static const String _cartFileName = 'cart.json';
  static const String _orderHistoryFileName = 'order_history.json';
  
  // Getters for file names (for debugging)
  static String getProductsFileName() => _productsFileName;
  static String getCartFileName() => _cartFileName;
  static String getOrderHistoryFileName() => _orderHistoryFileName;
  
  // Flag to track if path_provider is available
  static bool _pathProviderAvailable = true;
  
  // Get application documents directory
  static Future<Directory?> get _localDir async {
    if (!_pathProviderAvailable) return null;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory;
    } catch (e) {
      print('Path provider error: $e');
      _pathProviderAvailable = false;
      return null;
    }
  }
  
  // Get local file path
  static Future<File?> _getLocalFile(String fileName) async {
    final dir = await _localDir;
    if (dir == null) return null;
    return File('${dir.path}/$fileName');
  }
  
  // Create directory and base files if they don't exist
  static Future<void> _ensureFileExists(String fileName, String defaultContent) async {
    if (kIsWeb) return; // Skip for web
    
    try {
      final file = await _getLocalFile(fileName);
      if (file != null && !await file.exists()) {
        // Create parent directories if they don't exist
        await file.parent.create(recursive: true);
        // Create the file with default content
        await file.writeAsString(defaultContent);
        print('Created $fileName with default content');
      }
    } catch (e) {
      print('Error ensuring file exists: $e');
    }
  }
  
  // Initialize local storage with default data if needed
  static Future<void> initLocalStorage() async {
    if (kIsWeb) {
      // Web platform doesn't support local file system in the same way
      _pathProviderAvailable = false;
      print('Running on web platform - file system access is limited');
      return;
    }
    
    try {
      // Check if path_provider is available
      final dir = await _localDir;
      if (dir == null) {
        _pathProviderAvailable = false;
        print('Path provider not available, using in-memory storage only');
        return;
      }
      
      print('Local storage directory: ${dir.path}');
      
      // Create files if they don't exist
      await _ensureFileExists(_productsFileName, '[]');
      await _ensureFileExists(_cartFileName, '[]');
      await _ensureFileExists(_orderHistoryFileName, '[]');
      
      // Check if products file exists
      final productsFile = await _getLocalFile(_productsFileName);
      if (productsFile != null && await productsFile.exists()) {
        // Check if the file is empty or contains just empty brackets
        final content = await productsFile.readAsString();
        if (content.trim().isEmpty || content.trim() == '[]') {
          // Initialize with default products from assets
          print('Products file is empty, initializing with default products');
          final jsonString = await rootBundle.loadString('assets/data/products.json');
          await productsFile.writeAsString(jsonString);
        }
      }
      
    } catch (e) {
      _pathProviderAvailable = false;
      print('Error initializing local storage: $e');
    }
  }
  
  // In-memory storage as fallback
  static final Map<String, List<dynamic>> _inMemoryStorage = {
    _productsFileName: [],
    _cartFileName: [],
    _orderHistoryFileName: [],
  };
  
  // Sync products from API to local storage
  static Future<List<dynamic>> syncProducts() async {
    try {
      final isOnline = await ApiService.isOnline();
      
      if (isOnline) {
        // Fetch products from API
        final apiProducts = await ApiService.getProducts();
        
        if (apiProducts.isNotEmpty) {
          // Save products to storage (file or memory)
          if (_pathProviderAvailable && !kIsWeb) {
            final productsFile = await _getLocalFile(_productsFileName);
            if (productsFile != null) {
              await productsFile.writeAsString(jsonEncode(apiProducts));
              print('Products synced to JSON file: ${apiProducts.length} items');
            }
          }
          
          // Always update in-memory cache as well
          _inMemoryStorage[_productsFileName] = apiProducts;
          
          return apiProducts;
        }
      }
      
      // If offline or API failed, get products from local storage
      return await getLocalProducts();
    } catch (e) {
      print('Error syncing products: $e');
      return await getLocalProducts();
    }
  }
  
  // Get products from local storage (file or memory)
  static Future<List<dynamic>> getLocalProducts() async {
    try {
      if (_pathProviderAvailable && !kIsWeb) {
        final productsFile = await _getLocalFile(_productsFileName);
        
        if (productsFile != null && await productsFile.exists()) {
          final jsonString = await productsFile.readAsString();
          if (jsonString.trim().isNotEmpty) {
            final products = jsonDecode(jsonString);
            // Update in-memory cache
            _inMemoryStorage[_productsFileName] = products;
            print('Products loaded from JSON file: ${products.length} items');
            return products;
          }
        }
      }
      
      // If in-memory cache has data, use it
      if (_inMemoryStorage[_productsFileName]!.isNotEmpty) {
        return _inMemoryStorage[_productsFileName]!;
      }
      
      // Use assets as fallback
      final jsonString = await rootBundle.loadString('assets/data/products.json');
      final products = jsonDecode(jsonString);
      // Update in-memory cache
      _inMemoryStorage[_productsFileName] = products;
      print('Products loaded from assets: ${products.length} items');
      return products;
    } catch (e) {
      print('Error reading local products: $e');
      
      // Last resort: use assets
      try {
        final jsonString = await rootBundle.loadString('assets/data/products.json');
        final products = jsonDecode(jsonString);
        // Update in-memory cache
        _inMemoryStorage[_productsFileName] = products;
        return products;
      } catch (_) {
        return [];
      }
    }
  }
  
  // Sync cart to local storage
  static Future<void> saveCartToLocal(List<dynamic> cartItems) async {
    try {
      // Always update in-memory cache
      _inMemoryStorage[_cartFileName] = cartItems;
      
      // For mobile platforms, ensure it's saved to a JSON file
      if (_pathProviderAvailable && !kIsWeb) {
        final cartFile = await _getLocalFile(_cartFileName);
        if (cartFile != null) {
          // Convert to pretty JSON for readability
          final jsonString = JsonEncoder.withIndent('  ').convert(cartItems);
          await cartFile.writeAsString(jsonString);
          print('Cart saved to JSON file: ${cartItems.length} items');
        }
      } else {
        print('Cart saved to memory (web or path_provider unavailable): ${cartItems.length} items');
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
  
  // Get cart from local storage
  static Future<List<dynamic>> getLocalCart() async {
    try {
      if (_pathProviderAvailable && !kIsWeb) {
        final cartFile = await _getLocalFile(_cartFileName);
        
        if (cartFile != null && await cartFile.exists()) {
          final jsonString = await cartFile.readAsString();
          if (jsonString.trim().isNotEmpty) {
            final cart = jsonDecode(jsonString);
            // Update in-memory cache
            _inMemoryStorage[_cartFileName] = cart;
            print('Cart loaded from JSON file: ${cart.length} items');
            return cart;
          }
        }
      }
      
      // Return from in-memory cache
      print('Cart loaded from memory: ${_inMemoryStorage[_cartFileName]!.length} items');
      return _inMemoryStorage[_cartFileName]!;
    } catch (e) {
      print('Error reading local cart: $e');
      return _inMemoryStorage[_cartFileName]!;
    }
  }
  
  // Sync order history from local storage only (no API)
  static Future<List<dynamic>> syncOrderHistory() async {
    // For order history, we only use local storage
    // We don't interact with the API for order history
    print('Syncing order history from local JSON storage only (no API)');
    return await getLocalOrderHistory();
  }
  
  // Get order history from local storage
  static Future<List<dynamic>> getLocalOrderHistory() async {
    try {
      if (_pathProviderAvailable && !kIsWeb) {
        final orderHistoryFile = await _getLocalFile(_orderHistoryFileName);
        
        if (orderHistoryFile != null && await orderHistoryFile.exists()) {
          final jsonString = await orderHistoryFile.readAsString();
          if (jsonString.trim().isNotEmpty) {
            final orderHistory = jsonDecode(jsonString);
            // Update in-memory cache
            _inMemoryStorage[_orderHistoryFileName] = orderHistory;
            print('Order history loaded from JSON file: ${orderHistory.length} items');
            return orderHistory;
          }
        }
      }
      
      // Return from in-memory cache
      print('Order history loaded from memory: ${_inMemoryStorage[_orderHistoryFileName]!.length} items');
      return _inMemoryStorage[_orderHistoryFileName]!;
    } catch (e) {
      print('Error reading local order history: $e');
      return _inMemoryStorage[_orderHistoryFileName]!;
    }
  }
  
  // Add new order to history
  static Future<void> addOrderToHistory(Map<String, dynamic> order) async {
    try {
      // Generate unique ID if not present
      if (!order.containsKey('id')) {
        order['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      // Add timestamp if not present
      if (!order.containsKey('date')) {
        order['date'] = DateTime.now().toIso8601String();
      }
      
      // Get current order history
      final orderHistory = await getLocalOrderHistory();
      
      // Add to history
      orderHistory.add(order);
      
      // Update in-memory cache
      _inMemoryStorage[_orderHistoryFileName] = orderHistory;
      
      // For mobile platforms, ensure it's saved to a JSON file
      if (_pathProviderAvailable && !kIsWeb) {
        final orderHistoryFile = await _getLocalFile(_orderHistoryFileName);
        if (orderHistoryFile != null) {
          // Convert to pretty JSON for readability
          final jsonString = JsonEncoder.withIndent('  ').convert(orderHistory);
          await orderHistoryFile.writeAsString(jsonString);
          print('Order saved to JSON file, total orders: ${orderHistory.length}');
        }
      } else {
        print('Order saved to memory (web or path_provider unavailable), total orders: ${orderHistory.length}');
      }
    } catch (e) {
      print('Error adding order to history: $e');
      
      // Last resort - just update in-memory storage
      try {
        final orderHistory = _inMemoryStorage[_orderHistoryFileName] ?? [];
        orderHistory.add(order);
        _inMemoryStorage[_orderHistoryFileName] = orderHistory;
        print('Order added to memory storage (fallback)');
      } catch (fallbackError) {
        print('Failed to add order even to memory: $fallbackError');
      }
    }
  }
  
  // Clear local data (for logout)
  static Future<void> clearLocalData() async {
    try {
      // Clear in-memory storage
      _inMemoryStorage[_cartFileName] = [];
      _inMemoryStorage[_orderHistoryFileName] = [];
      
      // Clear file storage if available
      if (_pathProviderAvailable && !kIsWeb) {
        final cartFile = await _getLocalFile(_cartFileName);
        final orderHistoryFile = await _getLocalFile(_orderHistoryFileName);
        
        if (cartFile != null && await cartFile.exists()) {
          await cartFile.writeAsString('[]');
          print('Cart cleared in JSON file');
        }
        
        if (orderHistoryFile != null && await orderHistoryFile.exists()) {
          await orderHistoryFile.writeAsString('[]');
          print('Order history cleared in JSON file');
        }
      }
      
      print('Local data cleared');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }
  
  // Debug method to print the contents of a JSON file
  static Future<void> debugPrintFileContents(String fileName) async {
    if (kIsWeb) {
      print('Web platform does not support file system access');
      return;
    }
    
    try {
      final file = await _getLocalFile(fileName);
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        print('Contents of $fileName:');
        print(content.substring(0, content.length > 500 ? 500 : content.length));
        if (content.length > 500) {
          print('... (truncated, total length: ${content.length})');
        }
        print('File size: ${(await file.length()) / 1024} KB');
      } else {
        print('File $fileName does not exist');
      }
    } catch (e) {
      print('Error reading file $fileName: $e');
    }
  }
  
  // Get current file paths for debugging
  static Future<void> debugPrintFilePaths() async {
    if (kIsWeb) {
      print('Web platform does not support file system access');
      return;
    }
    
    try {
      final dir = await _localDir;
      if (dir != null) {
        print('Local storage directory: ${dir.path}');
        final productsFile = await _getLocalFile(_productsFileName);
        final cartFile = await _getLocalFile(_cartFileName);
        final orderHistoryFile = await _getLocalFile(_orderHistoryFileName);
        
        print('Products file path: ${productsFile?.path}');
        print('Cart file path: ${cartFile?.path}');
        print('Order history file path: ${orderHistoryFile?.path}');
        
        print('Products file exists: ${await productsFile?.exists() ?? false}');
        print('Cart file exists: ${await cartFile?.exists() ?? false}');
        print('Order history file exists: ${await orderHistoryFile?.exists() ?? false}');
      } else {
        print('Local directory not available');
      }
    } catch (e) {
      print('Error getting file paths: $e');
    }
  }
} 