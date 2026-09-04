import 'dart:io';

class ApiConfig {
  /// Local port for embedded Spring Boot backend inside Android APK
  static const int localPort = 18080;

  /// Centralized local API base URL
  static const String localApiBaseUrl = 'http://127.0.0.1:18080/tickoff';

  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    if (Platform.isAndroid) {
      return localApiBaseUrl;
    }
    return 'http://localhost:4000/tickoff';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
