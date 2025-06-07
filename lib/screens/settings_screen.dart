import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/connectivity_service.dart';
import '../services/battery_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final result = await connectivityService.checkConnectivity();
    setState(() {
      _connectionStatus = result;
    });
  }

  String _getConnectionString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Connected to WiFi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Connected to Bluetooth';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown Connection';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final batteryService = Provider.of<BatteryService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('System Theme'),
                  subtitle: const Text('Follow system settings'),
                  value: 'system',
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Light Theme'),
                  subtitle: const Text('Use light theme'),
                  value: 'light',
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Use dark theme'),
                  value: 'dark',
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Battery Status
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Battery',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Battery Level'),
                  subtitle: LinearProgressIndicator(
                    value: batteryService.batteryLevel / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getBatteryColor(batteryService.batteryLevel),
                    ),
                  ),
                  trailing: Text(
                    '${batteryService.batteryLevel}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  title: const Text('Battery Status'),
                  subtitle: Text(batteryService.getBatteryStateString()),
                  trailing: _getBatteryIcon(batteryService.batteryState, batteryService.batteryLevel),
                ),
                FutureBuilder<bool>(
                  future: batteryService.isInLowPowerMode(),
                  builder: (context, snapshot) {
                    final isLowPowerMode = snapshot.data ?? false;
                    return SwitchListTile(
                      title: const Text('Low Power Mode'),
                      subtitle: Text(isLowPowerMode ? 'Enabled' : 'Disabled'),
                      value: isLowPowerMode,
                      onChanged: null, // Read-only, cannot be changed programmatically
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Network Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Network',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Connection Status'),
                  subtitle: Text(_getConnectionString(_connectionStatus)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _checkConnectivity,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // About Section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                const ListTile(
                  title: Text('Terms of Service'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const ListTile(
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getBatteryColor(int level) {
    if (level <= 15) {
      return Colors.red;
    } else if (level <= 30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  Widget _getBatteryIcon(BatteryState state, int level) {
    IconData iconData;
    Color color;
    
    // Determine icon based on battery level and state
    if (state == BatteryState.charging) {
      iconData = Icons.battery_charging_full;
      color = Colors.green;
    } else {
      if (level <= 15) {
        iconData = Icons.battery_alert;
        color = Colors.red;
      } else if (level <= 30) {
        iconData = Icons.battery_2_bar;
        color = Colors.orange;
      } else if (level <= 60) {
        iconData = Icons.battery_4_bar;
        color = Colors.yellow;
      } else if (level <= 90) {
        iconData = Icons.battery_5_bar;
        color = Colors.lightGreen;
      } else {
        iconData = Icons.battery_full;
        color = Colors.green;
      }
    }
    
    return Icon(iconData, color: color);
  }
} 