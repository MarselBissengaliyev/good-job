// lib/services/common/cities_api.dart
import '../api/api_client.dart';
import '../api/api_logger.dart';

class CitiesApi {
  final ApiClient _client;

  CitiesApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<dynamic>> getCities() async {
    const method = 'GET';
    const url = '/cities';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.get(url);
      ApiLogger.logResponse(200, response);
      
      final cities = response['data'] ?? [];
      ApiLogger.logRequest(method, '✅ Получено ${cities.length} городов');
      
      return cities;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}