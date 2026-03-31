import '../api/api_client.dart';
import '../api/api_logger.dart';

class OrdersApi {
  final ApiClient _client;

  OrdersApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getOrders({
    int? page,
    int? perPage,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const method = 'GET';
    const url = '/orders?limit=100';

    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();

    // Добавляем фильтрацию по дате
    if (startDate != null && endDate != null) {
      // Форматируем даты в нужный формат: YYYY-MM-DDTHH:MM
      final startFormatted = _formatDateForApi(startDate);
      final endFormatted = _formatDateForApi(endDate);
      queryParams['filter[created_at]'] = '$startFormatted,$endFormatted';
    } else if (startDate != null) {
      // Если только начальная дата, фильтруем с начала дня
      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        23,
        59,
      );
      final startFormatted = _formatDateForApi(startOfDay);
      final endFormatted = _formatDateForApi(endOfDay);
      queryParams['filter[created_at]'] = '$startFormatted,$endFormatted';
    }

    ApiLogger.logRequest(method, url, body: queryParams);

    try {
      final response = await _client.get(url, queryParams: queryParams);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  String _formatDateForApi(DateTime date) {
    // Формат: YYYY-MM-DDTHH:MM
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T'
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    const method = 'GET';
    final url = '/orders/$orderId';

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

  Future<void> deleteOrder(int orderId) async {
    const method = 'DELETE';
    final url = '/orders/$orderId';

    ApiLogger.logRequest(method, url);

    try {
      await _client.delete(url);
      ApiLogger.logResponse(200, {'message': 'Order deleted successfully'});
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<void> changeOrderStatus({
    required String orderId,
    required String status,
  }) async {
    const method = 'PUT';
    final url = '/orders/$orderId';

    final body = {'status': status};

    ApiLogger.logRequest(method, url, body: body);

    try {
      await _client.put(url, body: body);
      ApiLogger.logResponse(200, {'message': 'Order status changed'});
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

    // Новый метод: публикация заказа (status -> active)
  Future<void> publishOrder(String orderId) async {
    const method = 'POST';
    final url = '/orders/$orderId/publish';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.post(url);
      ApiLogger.logResponse(200, response);
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  // Новый метод: отзыв заказа (status -> canceled)
  Future<void> revokeOrder(String orderId) async {
    const method = 'POST';
    final url = '/orders/$orderId/revoke';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.post(url);
      ApiLogger.logResponse(200, response);
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }


  Future<void> markOrderAsViewed(String orderId) async {
    try {
      await _client.post('/orders/$orderId/view');
    } catch (e) {
      print('Error marking order as viewed: $e');
    }
  }
}
