// lib/services/api_service.dart (обновленный)
import 'dart:io';

import 'package:flutter_application_1/models/work-photo.dart';
import 'package:flutter_application_1/services/api/avatar_api.dart';
import 'package:flutter_application_1/services/client/order_images_api.dart';

import 'api/api_client.dart';
import 'auth/auth_api.dart';
import 'client/client_orders_api.dart';
import 'common/cities_api.dart';
import 'common/profile_api.dart';
import 'master/categories_api.dart';
import 'master/work_photos_api.dart';
import 'orders/orders_api.dart';

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
  static final ClientOrdersApi _clientOrdersApi = ClientOrdersApi(
    client: _client,
  );
  static final OrderImagesApi _orderImagesApi = OrderImagesApi(client: _client);

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) {
    return _avatarApi.uploadAvatar(imageFile);
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

  static Future<dynamic> refreshToken({required String token}) =>
      _authApi.refreshToken(token: token);

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
    required int categoryId,
  }) => _profileApi.updateProfile(
    firstname: firstname,
    lastname: lastname,
    patronymic: patronymic,
    cityId: cityId,
    activeMode: activeMode,
    categoryId: categoryId,
  );

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

  static Future<void> deleteOrder(int orderId) =>
      _ordersApi.deleteOrder(orderId);

  static Future<void> changeOrderStatus({
    required String orderId,
    required String status,
  }) => _ordersApi.changeOrderStatus(orderId: orderId, status: status);

  // Client Orders методы
  static Future<Map<String, dynamic>> getClientOrders() =>
      _clientOrdersApi.getClientOrders();

  static Future<Map<String, dynamic>> updateClientOrder({
    required String orderId,
    String? title,
    String? description,
    String? status,
  }) => _clientOrdersApi.updateClientOrder(
    orderId: orderId,
    title: title,
    description: description,
    status: status,
  );

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
}
