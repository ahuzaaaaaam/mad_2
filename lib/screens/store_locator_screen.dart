import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String mapsUrl;
  double? distance;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.mapsUrl,
    this.distance,
  });
}

class StoreLocatorScreen extends StatefulWidget {
  const StoreLocatorScreen({super.key});

  @override
  State<StoreLocatorScreen> createState() => _StoreLocatorScreenState();
}

class _StoreLocatorScreenState extends State<StoreLocatorScreen> {
  final LocationService _locationService = LocationService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Store> _stores = [];
  double? _userLatitude;
  double? _userLongitude;
  String _userAddress = "Unable to get address";

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user location
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        
        // Get address from coordinates
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            setState(() {
              _userAddress = "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
            });
          }
        } catch (e) {
          print("Error getting address: $e");
          setState(() {
            _userAddress = "Unable to get address";
          });
        }
      }

      // Store data with Google Maps URLs
      final stores = [
        Store(
          id: '1',
          name: 'PizzApp Downtown',
          address: 'Independence Square, Colombo, Sri Lanka',
          latitude: 6.9102,
          longitude: 79.8683,
          imageUrl: 'https://images.pexels.com/photos/67468/pexels-photo-67468.jpeg',
          mapsUrl: 'https://maps.app.goo.gl/78x9aRe463yUezie8',
        ),
        Store(
          id: '2',
          name: 'PizzApp Uptown',
          address: 'Dutch Hospital, Colombo, Sri Lanka',
          latitude: 6.9344,
          longitude: 79.8428,
          imageUrl: 'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg',
          mapsUrl: 'https://maps.app.goo.gl/FMAoDcwPkDSS87X69',
        ),
      ];

      // Calculate distance to each store if user location is available
      if (_userLatitude != null && _userLongitude != null) {
        for (final store in stores) {
          store.distance = _locationService.calculateDistance(
            _userLatitude!,
            _userLongitude!,
            store.latitude,
            store.longitude,
          );
        }

        // Sort stores by distance
        stores.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
      }

      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load stores: $e';
        _isLoading = false;
      });
    }
  }

  // Launch directions from current location to store
  Future<void> _launchDirections(double destLat, double destLng) async {
    try {
      // If we have user location, use it for directions
      if (_userLatitude != null && _userLongitude != null) {
        // Create a Google Maps URL for directions from current location to destination
        final url = 'https://www.google.com/maps/dir/?api=1&origin=${_userLatitude!},${_userLongitude!}&destination=$destLat,$destLng&travelmode=driving';
        final Uri uri = Uri.parse(url);
        
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch maps application')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get your current location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Locator'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadStores,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // User location
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location, 
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  _userAddress,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Store list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stores.length,
                        itemBuilder: (context, index) {
                          final store = _stores[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Store image
                                SizedBox(
                                  width: double.infinity,
                                  height: 150,
                                  child: Image.network(
                                    store.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported, size: 50),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              store.name,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          if (store.distance != null)
                                            Text(
                                              '${(store.distance! / 1000).toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        store.address,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _launchDirections(store.latitude, store.longitude);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: const Text(
                                            'Directions',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
} 