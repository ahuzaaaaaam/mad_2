import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/product_card.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/sensor_service.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.showOnlyFeatured = false});

  final bool showOnlyFeatured;

  static List<Map<String, dynamic>> getFeaturedProducts() {
    return _MenuScreenState._allProducts
        .where((p) => p['isFeatured'] as bool)
        .toList();
  }

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  final SensorService _sensorService = SensorService();
  bool _isShakeToRandomizeActive = false;
  StreamSubscription? _shakeSubscription;

  static final List<Map<String, dynamic>> _allProducts = [
    {
      'id': '1',
      'name': 'Pepperoni Pizza',
      'description': 'Savory pepperoni, melted mozzarella, and zesty tomato sauce on a classic crust.',
      'price': 14.99,
      'imageUrl': 'https://www.cherryonmysundae.com/wp-content/uploads/2021/10/pepperoni-pizza-8.jpg',
      'isVeg': false,
      'isFeatured': true,
    },
    {
      'id': '2',
      'name': 'Hawaiian Pizza',
      'description': 'Sweet pineapple, savory ham, and melted mozzarella on a zesty tomato base.',
      'price': 15.99,
      'imageUrl': 'https://dinnerthendessert.com/wp-content/uploads/2024/07/Hawaiian-Pizza-1-2.jpg',
      'isVeg': false,
      'isFeatured': true,
    },
    {
      'id': '3',
      'name': 'Margherita Pizza',
      'description': 'Fresh mozzarella, basil, and tomato sauce on a classic crust.',
      'price': 13.99,
      'imageUrl': 'https://cb.scene7.com/is/image/Crate/frame-margherita-pizza-1?wid=800&qlt=70&op_sharpen=1',
      'isVeg': true,
      'isFeatured': true,
    },
    {
      'id': '4',
      'name': 'Veggie Supreme',
      'description': 'Mushrooms, bell peppers, onions, olives, and tomatoes.',
      'price': 15.99,
      'imageUrl': 'https://www.vegrecipesofindia.com/wp-content/uploads/2020/11/pizza-recipe-2.jpg',
      'isVeg': true,
      'isFeatured': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Load products from provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.fetchProducts();
    });
  }

  @override
  void dispose() {
    _stopShakeListener();
    super.dispose();
  }

  void _startShakeListener() {
    _sensorService.startAccelerometerListening();
    _shakeSubscription = _sensorService.shakeStream.listen((_) {
      _addRandomProductToCart();
    });
  }

  void _stopShakeListener() {
    _shakeSubscription?.cancel();
    _sensorService.stopAccelerometerListening();
  }

  void _toggleShakeToRandomize() {
    setState(() {
      _isShakeToRandomizeActive = !_isShakeToRandomizeActive;
      
      if (_isShakeToRandomizeActive) {
        _showShakeInstructions();
      } else {
        _stopShakeListener();
      }
    });
  }

  void _showShakeInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shake to Randomize'),
        content: const Text('Shake your phone to add a random pizza to your cart!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start listening for shake events only after user confirms
              _startShakeListener();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addRandomProductToCart() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    final randomProduct = productProvider.getRandomProduct();
    
    if (randomProduct != null) {
      cartProvider.addProduct(randomProduct);
      
      // Reset the shake to randomize state
      setState(() {
        _isShakeToRandomizeActive = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${randomProduct.name} to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final products = widget.showOnlyFeatured 
        ? _allProducts.where((p) => p['isFeatured'] as bool).toList()
        : _allProducts;

    if (widget.showOnlyFeatured || _selectedCategory == 'All') return products;
    return products.where((product) => 
      _selectedCategory == 'Veg' ? product['isVeg'] : !product['isVeg']
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context);

    // Use products from provider if loaded, otherwise use static data
    final useProviderData = productProvider.status == ProductLoadingStatus.loaded;

    return Column(
      children: [
        if (!widget.showOnlyFeatured) ...[
          // Categories
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Veg', 'Non-Veg'].map((category) {
                final isSelected = _selectedCategory == category;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
                ),
                const SizedBox(height: 12),
                // Shake to randomize button
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 250, // Fixed width instead of double.infinity
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _toggleShakeToRandomize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isShakeToRandomizeActive ? Colors.green : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                          shadowColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white.withOpacity(0.3) 
                              : Colors.black.withOpacity(0.3),
                        ),
                        child: Text(
                          _isShakeToRandomizeActive ? 'Shake Active' : 'Shake to Randomize',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Products
        Expanded(
          child: useProviderData
              ? _buildProductListFromProvider(productProvider, cartProvider)
              : _buildProductListFromStatic(cartProvider),
        ),
      ],
    );
  }

  Widget _buildProductListFromProvider(ProductProvider productProvider, CartProvider cartProvider) {
    final products = widget.showOnlyFeatured
        ? productProvider.featuredProducts
        : productProvider.getProductsByCategory(_selectedCategory);

    if (products.isEmpty) {
      return const Center(
        child: Text('No products found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProductCard(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            imageUrl: product.imageUrl,
            isVeg: product.isVeg,
            onAddToCart: () {
              cartProvider.addProduct(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${product.name} to cart'),
                  action: SnackBarAction(
                    label: 'View Cart',
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductListFromStatic(CartProvider cartProvider) {
    final products = _filteredProducts;

    return ListView.builder(
            padding: const EdgeInsets.all(16),
      itemCount: products.length,
            itemBuilder: (context, index) {
        final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProductCard(
                  id: product['id'] as String,
                  name: product['name'] as String,
                  description: product['description'] as String,
                  price: product['price'] as double,
                  imageUrl: product['imageUrl'] as String,
                  isVeg: product['isVeg'] as bool,
                  onAddToCart: () {
                    cartProvider.addItem(
                      id: product['id'] as String,
                      name: product['name'] as String,
                      price: product['price'] as double,
                      imageUrl: product['imageUrl'] as String,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${product['name']} to cart'),
                        action: SnackBarAction(
                          label: 'View Cart',
                          onPressed: () {
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
    );
  }
}
