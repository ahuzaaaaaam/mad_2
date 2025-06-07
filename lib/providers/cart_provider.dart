import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../services/data_sync_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  // Create from map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'] is int ? (map['price'] as int).toDouble() : map['price'],
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isInitialized = false;

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }
  
  // Initialize cart from local storage
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final cartData = await DataSyncService.getLocalCart();
      
      if (cartData.isNotEmpty) {
        _items.clear();
        
        for (var item in cartData) {
          try {
            final cartItem = CartItem.fromMap(item);
            _items[cartItem.id] = cartItem;
          } catch (e) {
            print('Error parsing cart item: $e');
            // Skip this item and continue
          }
        }
        
        notifyListeners();
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing cart: $e');
      // Continue with empty cart
      _isInitialized = true;
    }
  }
  
  // Save cart to local storage
  Future<void> _saveCartToLocal() async {
    try {
      final cartItems = _items.values.map((item) => item.toMap()).toList();
      await DataSyncService.saveCartToLocal(cartItems);
    } catch (e) {
      print('Error saving cart to local storage: $e');
    }
  }

  // Add item to cart
  void addItem({
    required String id,
    required String name,
    required double price,
    required String imageUrl,
  }) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        id,
        () => CartItem(
          id: id,
          name: name,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    }
    _saveCartToLocal();
    notifyListeners();
  }

  // Add product to cart
  void addProduct(Product product) {
    addItem(
      id: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
    );
  }

  // Remove item from cart
  void removeItem(String id) {
    _items.remove(id);
    _saveCartToLocal();
    notifyListeners();
  }

  // Update quantity
  void updateQuantity(String id, int quantity) {
    if (_items.containsKey(id)) {
      if (quantity > 0) {
        _items.update(
          id,
          (existingItem) => CartItem(
            id: existingItem.id,
            name: existingItem.name,
            price: existingItem.price,
            imageUrl: existingItem.imageUrl,
            quantity: quantity,
          ),
        );
      } else {
        _items.remove(id);
      }
      _saveCartToLocal();
      notifyListeners();
    }
  }

  // Clear cart
  void clear() {
    _items.clear();
    _saveCartToLocal();
    notifyListeners();
  }

  // Save order to local database and order history
  Future<bool> saveOrder() async {
    if (_items.isEmpty) return false;

    try {
      final orderItems = _items.values.map((item) => item.toMap()).toList();
      
      // Create the order object
      final order = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'total_amount': totalAmount,
        'item_count': itemCount,
        'items': orderItems,
        'date': DateTime.now().toIso8601String(),
        'status': 'Completed'
      };

      // Try to save to database, but don't fail if it doesn't work
      try {
        await _dbHelper.saveOrder(
          totalAmount,
          itemCount,
          orderItems,
        );
        print('Order saved to local database');
      } catch (dbError) {
        print('Database save error (continuing anyway): $dbError');
        // Continue even if database save fails
      }
      
      // Add to order history JSON file (this is the most important part)
      await DataSyncService.addOrderToHistory(order);
      print('Order saved to JSON history file');
      
      // Clear the cart
      clear();
      return true;
    } catch (e) {
      print('Error saving order: $e');
      return false;
    }
  }

  // Add random product to cart (for accelerometer feature)
  void addRandomProduct(Product product) {
    addItem(
      id: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
    );
  }
}
