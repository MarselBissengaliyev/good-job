// lib/services/api_service.dart (обновленный)
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:goodjob/models/work-photo.dart';
import 'package:goodjob/services/api/api_logger.dart';
import 'package:goodjob/services/api/avatar_api.dart';
import 'package:goodjob/services/auth/auth_service.dart';
import 'package:goodjob/services/client/order_images_api.dart';

import 'api/api_client.dart';
import 'auth/auth_api.dart';
import 'client/client_orders_api.dart';
import 'common/cities_api.dart';
import 'common/profile_api.dart';
import 'master/categories_api.dart';
import 'master/work_photos_api.dart';
import 'orders/orders_api.dart';
import 'master/master_api.dart';

export 'api/api_client.dart';
export 'api/api_logger.dart' show ApiLogger;

// Единый фасад для обратной совместимости
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  // API клиенты
  static final ApiClient _client = ApiClient();
  static final AvatarApi _avatarApi = AvatarApi(client: _client);
  static final AuthApi _authApi = AuthApi(client: _client);
  static final ProfileApi _profileApi = ProfileApi(client: _client);
  static final CitiesApi _citiesApi = CitiesApi(client: _client);
  static final CategoriesApi _categoriesApi = CategoriesApi(client: _client);
  static final WorkPhotosApi _workPhotosApi = WorkPhotosApi(client: _client);
  static final OrdersApi _ordersApi = OrdersApi(client: _client);
  static final MasterApi _masterApi = MasterApi(
    client: _client,
  ); // <-- Добавляем

  static final ClientOrdersApi _clientOrdersApi = ClientOrdersApi(
    client: _client,
  );
  static final OrderImagesApi _orderImagesApi = OrderImagesApi(client: _client);

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) {
    return _avatarApi.uploadAvatar(imageFile);
  }

  static Future<Map<String, dynamic>> uploadAvatarWeb(FormData formData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw UnauthorizedException('Токен не найден');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://good-job.kz/api',
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final response = await dio.put('/me/avatar', data: formData);
      return response.data;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  // Master методы
  static Future<Map<String, dynamic>> getMasterById(String masterId) {
    return _masterApi.getMasterById(masterId);
  }

  // Auth методы
  static Future<dynamic> login({required String telephone}) =>
      _authApi.login(telephone: telephone);

  static Future<dynamic> registerUser({
    required String firstname,
    required String lastname,
    required String telephone,
    required int cityId,
    required String activeMode,
  }) => _authApi.register(
    firstname: firstname,
    lastname: lastname,
    telephone: telephone,
    cityId: cityId,
    activeMode: activeMode,
  );

  static Future<dynamic> confirmPhone({
    required String telephone,
    required String code,
  }) => _authApi.confirmPhone(telephone: telephone, code: code);

  static Future<dynamic> refreshToken({required String refreshToken}) =>
      _authApi.refreshToken(refreshToken: refreshToken);

  static Future<String?> getDebugSmsCode(String telephone) =>
      _authApi.getDebugSmsCode(telephone);

  // Profile методы
  static Future<Map<String, dynamic>> getProfile() => _profileApi.getProfile();

  static Future<Map<String, dynamic>> updateProfile({
    required String firstname,
    required String lastname,
    String? patronymic,
    required int cityId,
    required String activeMode,
    required List<int> categoryIds,
    String? instUsername,
    String? ttUsername,
  }) => _profileApi.updateProfile(
    firstname: firstname,
    lastname: lastname,
    patronymic: patronymic,
    cityId: cityId,
    activeMode: activeMode,
    categoryIds: categoryIds,
    instUsername: instUsername,
    ttUsername: ttUsername,
  );

  // НОВЫЙ МЕТОД: Обновление профиля мастера (description, socials, categories)
  static Future<Map<String, dynamic>> updateMasterProfile({
    String? description,
    List<dynamic>? categories,
    String? ttUsername,
    String? instUsername,
  }) => _profileApi.updateMasterProfile(
    description: description,
    categories: categories,
    ttUsername: ttUsername,
    instUsername: instUsername,
  );

  // Добавьте этот метод в ApiService (в конец класса)
  static Future<Map<String, dynamic>> updateClientOrder({
    required String orderId,
    String? title,
    String? description,
    String? status,
    double? price,
    int? categoryId,
    int? cityId,
    String? addressStreet,
    String? addressHouse,
    String? addressApartment,
    String? telephone,
    List<String>? images,
  }) => _clientOrdersApi.updateClientOrder(
    orderId: orderId,
    title: title,
    description: description,
    status: status,
    price: price,
    categoryId: categoryId,
    cityId: cityId,
    addressStreet: addressStreet,
    addressHouse: addressHouse,
    addressApartment: addressApartment,
    telephone: telephone,
    images: images,
  );

  // Этот метод больше не нужен, так как категории обновляются через updateMasterProfile
  // Но оставим для обратной совместимости
  static Future<Map<String, dynamic>> updateMasterCategories({
    required List<int> categoryIds,
  }) async {
    print('⚠️ updateMasterCategories устарел, используйте updateMasterProfile');
    // Возвращаем пустой ответ, чтобы не ломать существующий код
    return {'data': {}};
  }

  static Future<Map<String, dynamic>> updateTelephone({
    required String telephone,
  }) => _profileApi.updateTelephone(telephone: telephone);

  static Future<Map<String, dynamic>> confirmNewTelephone({
    required String telephone,
    required String code,
  }) => _profileApi.confirmNewTelephone(telephone: telephone, code: code);

  // Categories методы
  static Future<List<dynamic>> getCategories() =>
      _categoriesApi.getCategories();

  static Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
  }) => _categoriesApi.updateCategory(categoryId: categoryId);

  static Future<Map<String, dynamic>> updateUserCategory(int categoryId) =>
      updateCategory(categoryId: categoryId);

  // Work Photos методы
  static Future<Map<String, dynamic>> uploadWorkPhoto(File imageFile) =>
      _workPhotosApi.uploadWorkPhoto(imageFile);

  static Future<List<WorkPhoto>> getWorkPhotos() =>
      _workPhotosApi.getWorkPhotos();

  static Future<void> deleteWorkPhoto(int id) =>
      _workPhotosApi.deleteWorkPhoto(id);

  // Orders методы
  static Future<Map<String, dynamic>> getOrders({
    int? page,
    int? perPage,
    DateTime? startDate,
    DateTime? endDate,
  }) => _ordersApi.getOrders(
    page: page,
    endDate: endDate,
    perPage: perPage,
    startDate: startDate,
  );

  static Future<Map<String, dynamic>> getOrderById(String orderId) =>
      _ordersApi.getOrderById(orderId);

  static String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '';

    try {
      // Пробуем разные форматы даты
      DateTime date;
      if (dateTimeString.contains(' ')) {
        // Формат: "2026-02-26 16:03:19"
        final parts = dateTimeString.split(' ');
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');

        date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );
      } else {
        // ISO формат: "2026-02-26T15:53:58.000000Z"
        date = DateTime.parse(dateTimeString).toLocal();
      }

      // Форматируем для отображения
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${_getDaysWord(difference.inDays)} назад';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${_getHoursWord(difference.inHours)} назад';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${_getMinutesWord(difference.inMinutes)} назад';
      } else {
        return 'только что';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  static String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if (days % 10 >= 2 &&
        days % 10 <= 4 &&
        (days % 100 < 10 || days % 100 >= 20))
      return 'дня';
    return 'дней';
  }

  static String _getHoursWord(int hours) {
    if (hours % 10 == 1 && hours % 100 != 11) return 'час';
    if (hours % 10 >= 2 &&
        hours % 10 <= 4 &&
        (hours % 100 < 10 || hours % 100 >= 20))
      return 'часа';
    return 'часов';
  }

  static String _getMinutesWord(int minutes) {
    if (minutes % 10 == 1 && minutes % 100 != 11) return 'минуту';
    if (minutes % 10 >= 2 &&
        minutes % 10 <= 4 &&
        (minutes % 100 < 10 || minutes % 100 >= 20))
      return 'минуты';
    return 'минут';
  }

  static Future<void> deleteOrder(int orderId) =>
      _ordersApi.deleteOrder(orderId);

  // Новые методы для управления статусами заказов
  static Future<void> publishOrder(String orderId) =>
      _ordersApi.publishOrder(orderId);

  static Future<void> revokeOrder(String orderId) =>
      _ordersApi.revokeOrder(orderId);

  static Future<void> archiveOrder(String orderId) =>
      _ordersApi.archiveOrder(orderId);

  static Future<void> changeOrderStatus({
    required String orderId,
    required String status,
  }) => _ordersApi.changeOrderStatus(orderId: orderId, status: status);

  static Future<void> markOrderAsViewed(String orderId) =>
      _ordersApi.markOrderAsViewed(orderId);

  // Client Orders методы
  static Future<Map<String, dynamic>> getClientOrders() =>
      _clientOrdersApi.getClientOrders();

  static Future<Map<String, dynamic>> createOrder({
    required int categoryId,
    required int cityId,
    required String title,
    required String description,
    required String addressStreet,
    required String addressHouse,
    required String addressApartment,
    required String telephone,
    required double price,
    bool isActive = true,
    String? clientTelephone,
    required List<String> images,
    List<File>? imageFiles,
  }) => _clientOrdersApi.createOrder(
    categoryId: categoryId,
    cityId: cityId,
    title: title,
    description: description,
    addressStreet: addressStreet,
    addressHouse: addressHouse,
    addressApartment: addressApartment,
    telephone: telephone,
    price: price,
    isActive: isActive,
    clientTelephone: clientTelephone,
    images: images,
    imageFiles: imageFiles,
  );

  // Order Images методы
  static Future<List<String>> uploadOrderImages(List<File> imageFiles) =>
      _orderImagesApi.uploadOrderImages(imageFiles);

  // Cities методы
  static Future<List<dynamic>> getCities() => _citiesApi.getCities();

  // Master Reviews методы
  static Future<Map<String, dynamic>> getMasterReviews(String masterId) {
    return _masterApi.getMasterReviews(masterId);
  }

  static Future<Map<String, dynamic>> createMasterReview({
    required String masterId,
    required int rating,
    String? comment,
  }) {
    return _masterApi.createMasterReview(
      masterId: masterId,
      rating: rating,
      comment: comment,
    );
  }

  static Future<Map<String, dynamic>> updateMasterReview({
    required String masterId,
    required String reviewId,
    int? rating,
    String? comment,
  }) {
    return _masterApi.updateMasterReview(
      masterId: masterId,
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );
  }

  static Future<Map<String, dynamic>> deleteMasterReview({
    required String masterId,
    required String reviewId,
  }) {
    return _masterApi.deleteMasterReview(
      masterId: masterId,
      reviewId: reviewId,
    );
  }
}
