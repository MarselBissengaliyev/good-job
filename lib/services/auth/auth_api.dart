// lib/services/auth/auth_api.dart
import 'package:goodjob/services/auth/auth_service.dart';

import '../api/api_client.dart';
import '../api/api_logger.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> login({required String telephone}) async {
    const method = 'POST';
    const url = '/auth/login';
    final body = {'telephone': telephone};

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

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String telephone,
    required int cityId,
    required String activeMode,
  }) async {
    const method = 'POST';
    const url = '/auth/register';
    final body = {
      'firstname': firstname,
      'lastname': lastname,
      'telephone': telephone,
      'city_id': cityId,
      'active_mode': activeMode,
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

  // lib/services/auth/auth_api.dart - исправленный confirmPhone
  Future<Map<String, dynamic>> confirmPhone({
    required String telephone,
    required String code,
  }) async {
    const method = 'POST';
    const url = '/auth/confirm';
    final body = {'telephone': telephone, 'code': code};

    ApiLogger.logRequest(method, url, body: body);

    try {
      final response = await _client.post(url, data: body);
      ApiLogger.logResponse(200, response);

      // ВАЖНО: Сохраняем токены при успешной авторизации
      if (response['accessToken'] != null) {
        await AuthService.saveToken(response['accessToken']);

        if (response['ttl'] != null) {
          await AuthService.saveTokenExpiry(response['ttl']);
        }

        // Если API вернет refreshToken (когда бэкендеры добавят)
        if (response['refreshToken'] != null) {
          await AuthService.saveRefreshToken(response['refreshToken']);
        }
      }

      return response;
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> refreshToken({required String refreshToken}) async {
    const method = 'POST';
    const url = '/auth/refresh';
    final body = {'refreshToken': refreshToken};

    ApiLogger.logRequest(method, url, body: body);

    try {
      final client = ApiClient(); // без токена
      final response = await client.post(url, data: body);
      ApiLogger.logResponse(200, response);
      return response;
    } catch (e) {
      ApiLogger.logError(e);
      return null;
    }
  }

  Future<String?> getDebugSmsCode(String telephone) async {
    const method = 'GET';
    final cleanPhone = telephone.replaceAll(RegExp(r'\D'), '');
    final url = '/sms-codes/$cleanPhone';

    ApiLogger.logRequest(method, url);

    try {
      final client = ApiClient(); // без токена
      final response = await client.get(url);
      ApiLogger.logResponse(200, response);

      final code = response['data']?['code']?.toString();
      if (code != null) {
        return code;
      }

      return null;
    } catch (e) {
      ApiLogger.logError(e);
      return null;
    }
  }
}
