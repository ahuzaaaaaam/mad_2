import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _isInitialized = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    // Skip database initialization on web platform
    if (kIsWeb) {
      print('Database operations not supported on web platform');
      return null;
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database operations not supported on web platform');
    }
    
    final path = join(await getDatabasesPath(), 'pizzapp.db');
    
    // Use the appropriate database factory based on platform
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop platforms
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDb,
        ),
      );
    } else {
      // For mobile platforms
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
      );
    }
  }

  Future<void> _createDb(Database db, int version) async {
    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        image_url TEXT NOT NULL,
        veg INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create order history table
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        items_count INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create order items table
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Create user preferences table
    await db.execute('''
      CREATE TABLE preferences(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // Favorites methods
  Future<int> addFavorite(Map<String, dynamic> product) async {
    if (kIsWeb) return -1;
    
    final db = await database;
    if (db == null) return -1;
    
    return await db.insert(
      'favorites',
      {
        'id': product['id'],
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'image_url': product['image_url'],
        'veg': product['veg'] ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return maps.map((map) {
      return {
        'id': map['id'],
        'name': map['name'],
        'description': map['description'],
        'price': map['price'],
        'image_url': map['image_url'],
        'veg': map['veg'] == 1,
      };
    }).toList();
  }

  Future<bool> isFavorite(String id) async {
    if (kIsWeb) return false;
    
    final db = await database;
    if (db == null) return false;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty;
  }

  Future<int> removeFavorite(String id) async {
    if (kIsWeb) return -1;
    
    final db = await database;
    if (db == null) return -1;
    
    return await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Order methods
  Future<int> saveOrder(double totalAmount, int itemsCount, List<Map<String, dynamic>> items) async {
    if (kIsWeb) return -1;
    
    final db = await database;
    if (db == null) return -1;
    
    // Begin transaction
    return await db.transaction((txn) async {
      // Insert order
      final orderId = await txn.insert(
        'orders',
        {
          'total_amount': totalAmount,
          'items_count': itemsCount,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      // Insert order items
      for (var item in items) {
        await txn.insert(
          'order_items',
          {
            'order_id': orderId,
            'product_id': item['id'],
            'name': item['name'],
            'price': item['price'],
            'quantity': item['quantity'],
          },
        );
      }
      
      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query('orders', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // Preferences methods
  Future<void> savePreference(String key, String value) async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    await db.insert(
      'preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    if (kIsWeb) return null;
    
    final db = await database;
    if (db == null) return null;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }
} 