import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  // Shake detection threshold
  static const double _shakeThreshold = 10.0;
  
  // Minimum time between two shake events (in milliseconds)
  static const int _minTimeBetweenShakes = 1000;
  
  // Timestamp of the last shake
  DateTime? _lastShakeTime;
  
  // Stream subscription for accelerometer events
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Stream controller for shake events
  final _shakeStreamController = StreamController<void>.broadcast();
  
  // Public stream of shake events
  Stream<void> get shakeStream => _shakeStreamController.stream;

  // Start monitoring for shake events
  void startAccelerometerListening() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _detectShake(event);
    });
  }

  // Stop monitoring for shake events
  void stopAccelerometerListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  // Calculate acceleration magnitude and detect shake
  void _detectShake(AccelerometerEvent event) {
    final double x = event.x;
    final double y = event.y;
    final double z = event.z;
    
    // Calculate acceleration magnitude
    final double acceleration = sqrt(x * x + y * y + z * z);
    
    final now = DateTime.now();
    
    // Check if acceleration exceeds threshold and enough time has passed since last shake
    if (acceleration > _shakeThreshold) {
      if (_lastShakeTime == null || now.difference(_lastShakeTime!).inMilliseconds > _minTimeBetweenShakes) {
        _lastShakeTime = now;
        _shakeStreamController.add(null); // Emit shake event
      }
    }
  }

  // Dispose resources
  void dispose() {
    stopAccelerometerListening();
    _shakeStreamController.close();
  }
} 