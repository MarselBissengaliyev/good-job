// lib/services/master/categories_api.dart
import '../api/api_client.dart';
import '../api/api_logger.dart';

class CategoriesApi {
  final ApiClient _client;

  CategoriesApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<dynamic>> getCategories() async {
    const method = 'GET';
    const url = '/categories';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.get(url);
      ApiLogger.logResponse(200, response);
      
      final categories = response['data'] ?? [];
      ApiLogger.logRequest(method, '✅ Получено ${categories.length} категорий');
      
      return categories;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  // НОВЫЙ МЕТОД: Обновление категорий мастера через отдельный эндпоинт
  Future<Map<String, dynamic>> updateMasterCategories({
    required List<int> categoryIds,
  }) async {
    const method = 'POST';
    const url = '/me/master/categories';

    final body = {
      'category_ids': categoryIds,
    };

    ApiLogger.logRequest(method, url, body: body);

    try {
      final response = await _client.post(url, data: body);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  // Этот метод больше не нужен для обновления категорий
  // Оставлю для обратной совместимости, но пометю как deprecated
  @Deprecated('Используйте updateMasterCategories для обновления категорий мастера')
  Future<Map<String, dynamic>> updateCategory({required int categoryId}) async {
    // Этот метод больше не используется для обновления категорий
    throw UnimplementedError('Используйте updateMasterCategories');
  }
}