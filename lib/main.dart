import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_history_provider.dart';
import 'services/connectivity_service.dart';
import 'services/battery_service.dart';
import 'services/data_sync_service.dart';
import 'screens/profile_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/store_locator_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_ffi for Windows
  try {
    sqfliteFfiInit();
  } catch (e) {
    print('SQLite initialization error: $e');
    // Continue anyway, app can function without SQLite
  }
  
  // Initialize local storage with default data
  try {
    await DataSyncService.initLocalStorage();
  } catch (e) {
    print('Local storage initialization error: $e');
    // Continue anyway, the DataSyncService has fallbacks
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (context) {
          final cartProvider = CartProvider();
          // Initialize cart from local storage
          Future.microtask(() => cartProvider.init().catchError((e) {
            print('Cart initialization error: $e');
            // Continue anyway, an empty cart is fine
          }));
          return cartProvider;
        }),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (context) {
          final orderHistoryProvider = OrderHistoryProvider();
          // Initialize order history from local/API
          Future.microtask(() => orderHistoryProvider.init().catchError((e) {
            print('Order history initialization error: $e');
            // Continue anyway, empty order history is fine
          }));
          return orderHistoryProvider;
        }),
        Provider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => BatteryService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'PizzApp',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/order-history': (context) => const OrderHistoryScreen(),
        '/store-locator': (context) => const StoreLocatorScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
