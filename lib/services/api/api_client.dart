// lib/services/api/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'api_config.dart';
import 'api_logger.dart';

class ApiClient {
  final String baseUrl;
  bool _isRefreshing = false;
  final List<Completer<dynamic>> _pendingRequests = [];

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await AuthService.getToken();
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      return headers;
    } catch (e) {
      ApiLogger.logError(e);
      return ApiConfig.defaultHeaders;
    }
  }

  // Метод для выполнения запросов с автоматическим обновлением токена
  Future<dynamic> _requestWithRefresh(Future<dynamic> Function() request) async {
    try {
      return await request();
    } on UnauthorizedException catch (e) {
      // Если уже идет обновление токена, добавляем запрос в очередь
      if (_isRefreshing) {
        final completer = Completer<dynamic>();
        _pendingRequests.add(completer);
        return completer.future;
      }

      // Пытаемся обновить токен
      _isRefreshing = true;
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          // Сохраняем новый токен
          await AuthService.saveToken(newToken);
          
          // Освобождаем ожидающие запросы
          _pendingRequests.forEach((completer) {
            completer.complete(request());
          });
          _pendingRequests.clear();
          
          // Повторяем исходный запрос с новым токеном
          return await request();
        } else {
          // Не удалось обновить токен - разлогиниваем
          await AuthService.clearAuthData();
          _pendingRequests.forEach((completer) {
            completer.completeError(UnauthorizedException('Сессия истекла'));
          });
          _pendingRequests.clear();
          rethrow;
        }
      } catch (refreshError) {
        // Ошибка при обновлении токена
        _pendingRequests.forEach((completer) {
          completer.completeError(refreshError);
        });
        _pendingRequests.clear();
        rethrow;
      } finally {
        _isRefreshing = false;
      }
    }
  }

 // lib/services/api/api_client.dart - исправленный _refreshToken
Future<String?> _refreshToken() async {
  try {
    final oldToken = await AuthService.getToken();
    if (oldToken == null) return null;

    // Важно: используем http напрямую, чтобы избежать циклических вызовов
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $oldToken', // токен в заголовке, как в документации
      },
    ).timeout(const Duration(seconds: ApiConfig.connectionTimeout));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    }
    return null;
  } catch (e) {
    ApiLogger.logError('Refresh token error: $e');
    return null;
  }
}

  // Обновленные методы с поддержкой refresh
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) {
    return _requestWithRefresh(() => _get(path, queryParams: queryParams));
  }

  Future<dynamic> _get(String path, {Map<String, String>? queryParams}) async {
    final method = 'GET';
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      ApiLogger.logRequest(method, uri.toString(), headers: headers);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      ApiLogger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Превышено время ожидания');
    } on SocketException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<dynamic> post(String path, {dynamic body}) {
    return _requestWithRefresh(() => _post(path, body: body));
  }

  Future<dynamic> _post(String path, {dynamic body}) async {
    final method = 'POST';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final headers = await _getHeaders();
      ApiLogger.logRequest(method, uri.toString(), headers: headers, body: body);

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      ApiLogger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Превышено время ожидания');
    } on SocketException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<dynamic> put(String path, {dynamic body}) {
    return _requestWithRefresh(() => _put(path, body: body));
  }

  Future<dynamic> _put(String path, {dynamic body}) async {
    final method = 'PUT';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final headers = await _getHeaders();
      ApiLogger.logRequest(method, uri.toString(), headers: headers, body: body);

      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      ApiLogger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Превышено время ожидания');
    } on SocketException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) {
    return _requestWithRefresh(() => _patch(path, body: body));
  }

  Future<dynamic> _patch(String path, {dynamic body}) async {
    final method = 'PATCH';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final headers = await _getHeaders();
      ApiLogger.logRequest(method, uri.toString(), headers: headers, body: body);

      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      ApiLogger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Превышено время ожидания');
    } on SocketException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<dynamic> delete(String path) {
    return _requestWithRefresh(() => _delete(path));
  }

  Future<dynamic> _delete(String path) async {
    final method = 'DELETE';
    final uri = Uri.parse('$baseUrl$path');

    try {
      final headers = await _getHeaders();
      ApiLogger.logRequest(method, uri.toString(), headers: headers);

      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      ApiLogger.logResponse(response.statusCode, response.body);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Превышено время ожидания');
    } on SocketException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body;
      }
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Сессия истекла. Пожалуйста, войдите снова.');
    } else if (response.statusCode == 422) {
      throw ValidationException.fromResponse(response);
    } else if (response.statusCode == 404) {
      throw NotFoundException('Ресурс не найден');
    } else if (response.statusCode >= 500) {
      throw ServerException('Внутренняя ошибка сервера');
    } else {
      throw ApiException('Ошибка: ${response.statusCode}');
    }
  }
}

// Исключения остаются без изменений
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;

  ValidationException(this.errors, String message) : super(message);

  static ValidationException fromResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return ValidationException(
        data['errors'] ?? {},
        'Ошибка валидации данных',
      );
    } catch (e) {
      return ValidationException({}, 'Ошибка валидации данных');
    }
  }
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}