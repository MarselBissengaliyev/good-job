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

  Future<Map<String, dynamic>> updateCategory({required int categoryId}) async {
    const method = 'PUT';
    const profileUrl = '/me';
    const url = '/me'; // тот же URL для обновления профиля

    ApiLogger.logRequest(method, url, body: {'category_id': categoryId});

    try {
      // Получаем текущий профиль
      ApiLogger.logRequest('GET', profileUrl, body: {'action': 'get current profile for update'});
      
      final profileResponse = await _client.get(profileUrl);
      final data = profileResponse['data'];
      
      if (data == null) {
        throw ApiException('Не удалось получить данные профиля');
      }
      
      ApiLogger.logResponse(200, {'profile_data': 'получен для обновления'});

      // Формируем тело запроса
      final body = {
        'category_id': categoryId,
        'firstname': data['firstname'],
        'lastname': data['lastname'],
        'patronymic': data['patronymic'],
        'telephone': data['telephone'],
        if (data['city'] != null) 'city_id': data['city']['id'],
        'active_mode': data['activeMode'],
        'description': data['description'],
        'ttUrl': data['ttUrl'],
        'instUrl': data['instUrl'],
        'workPhotos': data['workPhotos'] ?? [],
        'subscriptions': data['subscriptions'] ?? [],
      };
      
      // Удаляем null значения
      body.removeWhere((key, value) => value == null);

      ApiLogger.logRequest(method, url, body: {
        ...body,
        'workPhotos': '${(body['workPhotos'] as List).length} photos',
        'subscriptions': '${(body['subscriptions'] as List).length} subscriptions',
      });

      final response = await _client.put(url, body: body);
      ApiLogger.logResponse(200, response);
      
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}