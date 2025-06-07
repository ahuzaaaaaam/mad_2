import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class BatteryService with ChangeNotifier {
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  
  BatteryService() {
    _init();
  }
  
  void _init() async {
    // Get initial battery level
    _updateBatteryLevel();
    
    // Listen to battery state changes
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
      _batteryState = state;
      _updateBatteryLevel();
    });
  }
  
  Future<void> _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (level != _batteryLevel) {
      _batteryLevel = level;
      notifyListeners();
    }
  }
  
  String getBatteryStateString() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.unknown:
      default:
        return 'Unknown';
    }
  }
  
  Future<bool> isInLowPowerMode() async {
    return await _battery.isInBatterySaveMode;
  }
  
  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    super.dispose();
  }
} 