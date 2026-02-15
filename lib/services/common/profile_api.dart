// lib/services/common/profile_api.dart

import 'package:flutter_application_1/services/auth/auth_service.dart';
import '../api/api_client.dart';
import '../api/api_logger.dart';

class ProfileApi {
  final ApiClient _client;

  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    const method = 'GET';
    const url = '/me';

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

  Future<Map<String, dynamic>> updateProfile({
    required String firstname,
    required String lastname,
    String? patronymic,
    required int cityId,
    required String activeMode,
    required categoryId,
  }) async {
    const method = 'PUT';
    const url = '/me';

    final body = {
      'firstname': firstname,
      'lastname': lastname,
      'patronymic': patronymic ?? '',
      'city_id': cityId,
      'active_mode': activeMode,
      'categoryId': categoryId
    };

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

  Future<Map<String, dynamic>> updateTelephone({
    required String telephone,
  }) async {
    const method = 'POST';
    const url = '/me/tel';

    final body = {'telephone': telephone};

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

  Future<Map<String, dynamic>> confirmNewTelephone({
    required String telephone,
    required String code,
  }) async {
    const method = 'POST';
    const url = '/me/tel/confirm';

    final body = {
      'telephone': telephone,
      'code': code,
    };

    ApiLogger.logRequest(method, url, body: body);

    try {
      final response = await _client.post(url, body: body);

      if (response['access_token'] != null) {
        await AuthService.saveToken(response['access_token']);
      }

      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}
