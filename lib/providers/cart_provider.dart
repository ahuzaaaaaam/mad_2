import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

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
    };
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
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
      notifyListeners();
    }
  }

  // Clear cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Save order to database
  Future<bool> saveOrder() async {
    try {
      if (_items.isEmpty) return false;

      final orderItems = _items.values.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
      }).toList();

      await _dbHelper.saveOrder(
        totalAmount,
        itemCount,
        orderItems,
      );

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
