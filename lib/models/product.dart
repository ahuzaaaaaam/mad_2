class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isVeg;
  final bool isFeatured;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isVeg,
    this.isFeatured = false,
  });

  // Create a Product from JSON data
  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle price conversion
    double price;
    if (json['price'] is int) {
      price = (json['price'] as int).toDouble();
    } else if (json['price'] is double) {
      price = json['price'] as double;
    } else if (json['price'] is String) {
      price = double.tryParse(json['price'] as String) ?? 0.0;
    } else {
      price = 0.0;
    }

    // Handle image URL (API might return 'image' or 'image_url')
    String imageUrl;
    if (json.containsKey('image_url') && json['image_url'] != null) {
      imageUrl = json['image_url'] as String;
    } else if (json.containsKey('image') && json['image'] != null) {
      imageUrl = json['image'] as String;
    } else {
      imageUrl = 'https://via.placeholder.com/150?text=No+Image';
    }

    return Product(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: price,
      imageUrl: imageUrl,
      isVeg: json['veg'] is bool ? json['veg'] as bool : json['veg'] == 'Yes',
      isFeatured: json.containsKey('featured') ? 
        (json['featured'] is bool ? json['featured'] as bool : json['featured'] == 'Yes') : 
        false,
    );
  }

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'veg': isVeg,
      'featured': isFeatured,
    };
  }

  // Create a copy of the Product with some properties changed
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isVeg,
    bool? isFeatured,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isVeg: isVeg ?? this.isVeg,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
} 