class AppConfig {
  // API configuration
  static const String apiBaseUrl = 'https://ssp-sem2-host.onrender.com/api';
  
  // API request timeouts (in seconds)
  static const int defaultTimeout = 10;
  static const int loginTimeout = 15;
  static const int connectivityCheckTimeout = 5;
  
  // Feature flags
  static const bool useOfflineFallback = true;
  static const bool enableCaching = true;
  
  // App version
  static const String appVersion = '1.0.0';
} 