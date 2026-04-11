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

  // Получение заголовков с токеном (только если requireAuth=true и токен есть)
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    
    if (requireAuth) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      // НЕ бросаем исключение, просто не добавляем токен
      // Если API требует авторизацию, то вернет 401
    }
    
    return headers;
  }

  // Основной метод запроса с поддержкой refresh token
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    // Строим URI с query параметрами
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    // Функция выполнения запроса
    Future<dynamic> executeRequest() async {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final body = data != null ? jsonEncode(data) : null;
      
      ApiLogger.logRequest(method, uri.toString(), headers: headers, body: data);
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
      
      ApiLogger.logResponse(response.statusCode, response.body);
      return _handleResponse(response);
    }
    
    try {
      return await executeRequest().timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw ApiException('Превышено время ожидания'),
      );
    } on UnauthorizedException catch (e) {
      // Если токен истек и требуется авторизация
      if (requireAuth) {
        // Пытаемся обновить токен
        final newToken = await _refreshToken();
        
        if (newToken != null) {
          // Повторяем запрос с новым токеном
          final newHeaders = await _getHeaders(requireAuth: true);
          final body = data != null ? jsonEncode(data) : null;
          
          http.Response retryResponse;
          
          switch (method.toUpperCase()) {
            case 'GET':
              retryResponse = await http.get(uri, headers: newHeaders);
              break;
            case 'POST':
              retryResponse = await http.post(uri, headers: newHeaders, body: body);
              break;
            case 'PUT':
              retryResponse = await http.put(uri, headers: newHeaders, body: body);
              break;
            case 'DELETE':
              retryResponse = await http.delete(uri, headers: newHeaders);
              break;
            case 'PATCH':
              retryResponse = await http.patch(uri, headers: newHeaders, body: body);
              break;
            default:
              throw ApiException('Unsupported HTTP method: $method');
          }
          
          ApiLogger.logResponse(retryResponse.statusCode, retryResponse.body);
          return _handleResponse(retryResponse);
        } else {
          // Не удалось обновить токен - очищаем данные
          await AuthService.clearAuthData();
          rethrow;
        }
      }
      rethrow;
    } on SocketException {
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      rethrow;
    }
  }
  
  // Обновление токена с очередью запросов
  Future<String?> _refreshToken() async {
    // Если уже идет обновление, добавляем запрос в очередь
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _pendingRequests.add(completer);
      return completer.future;
    }
    
    _isRefreshing = true;
    
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }
      
      // Вызываем API обновления (без авторизации)
      final response = await request(
        'POST',
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        requireAuth: false, // Важно: не требуем авторизацию
      );
      
      if (response['accessToken'] != null && response['refreshToken'] != null) {
        // Сохраняем новые токены
        await AuthService.saveToken(response['accessToken']);
        await AuthService.saveRefreshToken(response['refreshToken']);
        
        if (response['ttl'] != null) {
          await AuthService.saveTokenExpiry(response['ttl']);
        }
        if (response['refreshTtl'] != null) {
          await AuthService.saveRefreshTokenExpiry(response['refreshTtl']);
        }
        
        // Обрабатываем ожидающие запросы
        for (final completer in _pendingRequests) {
          completer.complete(response['accessToken']);
        }
        _pendingRequests.clear();
        
        return response['accessToken'];
      }
      
      return null;
    } catch (e) {
      print('❌ Ошибка обновления токена: $e');
      
      // Обрабатываем ожидающие запросы с ошибкой
      for (final completer in _pendingRequests) {
        completer.completeError(e);
      }
      _pendingRequests.clear();
      
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  // Обработка ответа
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
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

  // Упрощенные публичные методы
  Future<dynamic> get(String path, {Map<String, String>? queryParams, bool requireAuth = true}) {
    return request('GET', path, queryParams: queryParams, requireAuth: requireAuth);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data, bool requireAuth = true}) {
    return request('POST', path, data: data, requireAuth: requireAuth);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? data, bool requireAuth = true}) {
    return request('PUT', path, data: data, requireAuth: requireAuth);
  }

  Future<dynamic> delete(String path, {bool requireAuth = true}) {
    return request('DELETE', path, requireAuth: requireAuth);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? data, bool requireAuth = true}) {
    return request('PATCH', path, data: data, requireAuth: requireAuth);
  }
}

// Исключения
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
        data['message'] ?? 'Ошибка валидации данных',
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