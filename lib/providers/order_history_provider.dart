import 'package:flutter/foundation.dart';
import '../services/data_sync_service.dart';

class OrderItem {
  final String id;
  final double totalAmount;
  final int itemCount;
  final List<dynamic> items;
  final DateTime date;

  OrderItem({
    required this.id,
    required this.totalAmount,
    required this.itemCount,
    required this.items,
    required this.date,
  });

  // Create from map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      totalAmount: map['total_amount'] is int 
          ? (map['total_amount'] as int).toDouble() 
          : map['total_amount'],
      itemCount: map['item_count'],
      items: map['items'],
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'item_count': itemCount,
      'items': items,
      'date': date.toIso8601String(),
    };
  }
}

class OrderHistoryProvider with ChangeNotifier {
  List<OrderItem> _orders = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<OrderItem> get orders => [..._orders];
  bool get isLoading => _isLoading;

  // Initialize order history from storage
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      await fetchOrderHistory();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing order history: $e');
      _isInitialized = true;
      _isLoading = false;
    }
  }

  // Fetch order history from API or local storage
  Future<void> fetchOrderHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use the data sync service to get order history with automatic syncing
      final orderData = await DataSyncService.syncOrderHistory();
      
      // Convert to OrderItem objects
      _orders = [];
      for (var json in orderData) {
        try {
          _orders.add(OrderItem.fromMap(json));
        } catch (e) {
          print('Error parsing order item: $e');
          // Skip this item and continue
        }
      }
      
      // Sort by date (newest first)
      _orders.sort((a, b) => b.date.compareTo(a.date));
      
    } catch (e) {
      print('Error fetching order history: $e');
      
      // Try to load from local storage as fallback
      try {
        final orderData = await DataSyncService.getLocalOrderHistory();
        _orders = [];
        for (var json in orderData) {
          try {
            _orders.add(OrderItem.fromMap(json));
          } catch (e) {
            print('Error parsing order item (fallback): $e');
            // Skip this item and continue
          }
        }
        _orders.sort((a, b) => b.date.compareTo(a.date));
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        // Continue with empty orders list
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new order to history
  Future<void> addOrder(double totalAmount, int itemCount, List<dynamic> items) async {
    final order = OrderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      totalAmount: totalAmount,
      itemCount: itemCount,
      items: items,
      date: DateTime.now(),
    );

    _orders.insert(0, order); // Add to beginning (newest first)
    notifyListeners();

    // Add to order history and sync
    await DataSyncService.addOrderToHistory(order.toMap());
  }
} 