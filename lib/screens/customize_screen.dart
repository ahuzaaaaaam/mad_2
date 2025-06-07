import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({super.key});

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  String _selectedBase = 'Thin Crust';
  String _selectedSauce = 'BBQ';
  final List<String> _selectedToppings = [];
  bool _isVegetarian = true;
  
  // Prices
  final Map<String, double> _basePrices = {
    'Thin Crust': 10.99,
    'Regular Crust': 12.99,
    'Thick Crust': 14.99,
    'Stuffed Crust': 16.99,
  };
  
  final Map<String, double> _saucePrices = {
    'BBQ': 1.50,
    'Garlic': 1.50,
    'Pesto': 2.00,
  };
  
  final Map<String, double> _toppingPrices = {
    'Cheese': 1.00,
    'Pepperoni': 1.50,
    'Mushrooms': 1.00,
    'Onions': 0.75,
    'Bell Peppers': 0.75,
    'Olives': 1.00,
    'Pineapple': 1.25,
    'Ham': 1.50,
    'Bacon': 1.50,
    'Chicken': 2.00,
  };

  double get _totalPrice {
    double basePrice = _basePrices[_selectedBase] ?? 0;
    double saucePrice = _selectedSauce.isEmpty ? 0 : (_saucePrices[_selectedSauce] ?? 0);
    double toppingsPrice = _selectedToppings.fold(0, (sum, topping) => sum + (_toppingPrices[topping] ?? 0));
    
    return basePrice + saucePrice + toppingsPrice;
  }
  
  void _toggleTopping(String topping) {
    setState(() {
      if (_selectedToppings.contains(topping)) {
        _selectedToppings.remove(topping);
      } else {
        _selectedToppings.add(topping);
      }
      
      // Check if vegetarian
      _updateVegetarianStatus();
    });
  }
  
  void _updateVegetarianStatus() {
    final nonVegToppings = ['Pepperoni', 'Ham', 'Bacon', 'Chicken'];
    setState(() {
      _isVegetarian = !_selectedToppings.any((topping) => nonVegToppings.contains(topping));
    });
  }
  
  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Create description based on selected options
    String description = 'Base: $_selectedBase';
    if (_selectedSauce.isNotEmpty) {
      description += ', Sauce: $_selectedSauce';
    } else {
      description += ', No Sauce';
    }
    
    if (_selectedToppings.isNotEmpty) {
      description += ', Toppings: ${_selectedToppings.join(", ")}';
    } else {
      description += ', No Extra Toppings';
  }

    // Create custom pizza product
    final customPizza = Product(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Pizza',
      description: description,
      price: _totalPrice,
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
      isVeg: _isVegetarian,
    );
    
    cartProvider.addProduct(customPizza);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom pizza added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pizza Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1513104890138-7c749659a591'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Base selection
          Text(
            'Base',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                _buildBaseOption('Thin Crust', _basePrices['Thin Crust']!),
                _buildBaseOption('Regular Crust', _basePrices['Regular Crust']!),
                _buildBaseOption('Thick Crust', _basePrices['Thick Crust']!),
                _buildBaseOption('Stuffed Crust', _basePrices['Stuffed Crust']!),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Sauce selection
          Text(
            'Sauce',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          const SizedBox(height: 8),
          Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildSauceOption('BBQ', _saucePrices['BBQ']!),
                _buildSauceOption('Garlic', _saucePrices['Garlic']!),
                _buildSauceOption('Pesto', _saucePrices['Pesto']!),
                ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Toppings selection
          Text(
            'Toppings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _toppingPrices.keys.map((topping) {
                  return _buildToppingChip(topping, _toppingPrices[topping]!);
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Total and add to cart button
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                        'Total Price',
                    style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '\$${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                            fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
                  ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBaseOption(String base, double price) {
    final isSelected = _selectedBase == base;
    return RadioListTile<String>(
      title: Text(base),
      subtitle: Text('\$${price.toStringAsFixed(2)}'),
      value: base,
      groupValue: _selectedBase,
      onChanged: (value) {
        setState(() {
          _selectedBase = value!;
        });
      },
      activeColor: Theme.of(context).primaryColor,
      selected: isSelected,
    );
  }
  
  Widget _buildSauceOption(String sauce, double price) {
    final isSelected = _selectedSauce == sauce;
    return ListTile(
      title: Text(sauce),
      subtitle: Text('+\$${price.toStringAsFixed(2)}'),
      leading: isSelected 
        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) 
        : Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() {
          // If already selected, deselect it (set to null)
          if (_selectedSauce == sauce) {
            _selectedSauce = '';
          } else {
            _selectedSauce = sauce;
          }
        });
      },
      selected: isSelected,
    );
  }
  
  Widget _buildToppingChip(String topping, double price) {
    final isSelected = _selectedToppings.contains(topping);
    return FilterChip(
      label: Text('$topping +\$${price.toStringAsFixed(2)}'),
      selected: isSelected,
      onSelected: (_) => _toggleTopping(topping),
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
