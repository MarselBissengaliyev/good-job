import '../api/api_client.dart';
import '../api/api_logger.dart';

class MasterApi {
  final ApiClient _client;

  MasterApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Получить данные мастера по ID
  Future<Map<String, dynamic>> getMasterById(String masterId) async {
    const method = 'GET';
    final url = '/masters/$masterId';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.get(url);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  /// Получить список работ мастера по ID мастера
  Future<Map<String, dynamic>> getMasterWorkPhotos(String masterId) async {
    const method = 'GET';
    final url = '/masters/$masterId/work-photos';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.get(url);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  /// Поиск мастеров по параметрам
  Future<Map<String, dynamic>> searchMasters({
    int? cityId,
    int? categoryId,
    String? query,
    int? page,
    int? perPage,
  }) async {
    const method = 'GET';
    const url = '/masters';

    final queryParams = <String, dynamic>{};
    if (cityId != null) queryParams['city_id'] = cityId;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (query != null) queryParams['query'] = query;
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    final fullUrl = queryParams.isNotEmpty
        ? '$url?${Uri(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString()))).query}'
        : url;

    ApiLogger.logRequest(method, fullUrl);

    try {
      final response = await _client.get(fullUrl);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  // lib/services/api/master_api.dart (добавьте эти методы в существующий класс)

  /// Получить отзывы о мастере
  Future<Map<String, dynamic>> getMasterReviews(String masterId) async {
    const method = 'GET';
    final url = '/masters/$masterId/reviews';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.get(url);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  /// Создать отзыв о мастере
  Future<Map<String, dynamic>> createMasterReview({
    required String masterId,
    required int rating,
    String? comment,
  }) async {
    const method = 'POST';
    final url = '/masters/$masterId/reviews';

    final body = {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    ApiLogger.logRequest(method, url, body: body);

    try {
      final response = await _client.post(url, body: body);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  /// Обновить отзыв о мастере
  Future<Map<String, dynamic>> updateMasterReview({
    required String masterId,
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    const method = 'PUT';
    final url = '/masters/$masterId/reviews/$reviewId';

    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;

    ApiLogger.logRequest(method, url, body: body);

    try {
      final response = await _client.put(url, body: body);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  /// Удалить отзыв о мастере
  Future<Map<String, dynamic>> deleteMasterReview({
    required String masterId,
    required String reviewId,
  }) async {
    const method = 'DELETE';
    final url = '/masters/$masterId/reviews/$reviewId';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.delete(url);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}
