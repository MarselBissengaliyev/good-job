// lib/services/api/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://good-job.kz/api';
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}