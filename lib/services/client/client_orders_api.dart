// lib/services/client/client_orders_api.dart
import 'dart:io';
import 'package:flutter_application_1/services/client/order_images_api.dart';
import '../api/api_client.dart';
import '../api/api_logger.dart';

class ClientOrdersApi {
  final ApiClient _client;
  final OrderImagesApi _imagesApi;

  ClientOrdersApi({
    ApiClient? client,
    OrderImagesApi? imagesApi,
  })  : _client = client ?? ApiClient(),
        _imagesApi = imagesApi ?? OrderImagesApi();

  Future<Map<String, dynamic>> getClientOrders() async {
    const method = 'GET';
    const url = '/me/client/orders';

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

  Future<Map<String, dynamic>> updateClientOrder({
    required String orderId,
    String? title,
    String? description,
    String? status,
  }) async {
    const method = 'PUT';
    final url = '/me/client/orders/$orderId';
    
    final body = <String, dynamic>{};
    if (title != null && title.isNotEmpty) body['title'] = title;
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (status != null && status.isNotEmpty) body['status'] = status;

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

  Future<Map<String, dynamic>> createOrder({
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
    List<String> images = const [],
    List<File>? imageFiles,
  }) async {
    const method = 'POST';
    const url = '/orders';

    ApiLogger.logRequest(method, url, body: {
      'category_id': categoryId,
      'city_id': cityId,
      'title': title,
      'description': description,
      'is_active': isActive,
      'address_street': addressStreet,
      'address_house': addressHouse,
      'address_apartment': addressApartment,
      'telephone': telephone,
      'price': price,
      'images_count': images.length,
      'image_files_count': imageFiles?.length ?? 0,
      'client_telephone': clientTelephone,
    });

    try {
      // Загружаем изображения, если они переданы как файлы
      List<String> finalImages = List.from(images);
      
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final uploadedPaths = await _imagesApi.uploadOrderImages(imageFiles);
        finalImages.addAll(uploadedPaths);
      }

      final body = {
        'category_id': categoryId,
        'city_id': cityId,
        'title': title,
        'description': description,
        'is_active': isActive,
        'address_street': addressStreet,
        'address_house': addressHouse,
        'address_apartment': addressApartment,
        'telephone': telephone,
        'price': price,
        'images': finalImages,
      };

      if (clientTelephone != null && clientTelephone.isNotEmpty) {
        body['client_telephone'] = clientTelephone;
      }

      final response = await _client.post(url, body: body);
      ApiLogger.logResponse(201, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}