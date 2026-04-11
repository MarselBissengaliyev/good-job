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

  // Получение заголовков с токеном
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    ApiLogger.logDebug('📋 _getHeaders: requireAuth=$requireAuth');
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    
    if (requireAuth) {
      final token = await AuthService.getToken();
      ApiLogger.logDebug('🔑 Получен токен: ${token != null ? "есть (${token.substring(0, token.length > 20 ? 20 : token.length)}...)" : "нет"}');
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        ApiLogger.logDebug('✅ Токен добавлен в заголовки');
      } else {
        ApiLogger.logDebug('⚠️ Токен отсутствует, но requireAuth=true');
      }
    } else {
      ApiLogger.logDebug('ℹ️ Авторизация не требуется');
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
    bool isRefreshAttempt = false, // Флаг для предотвращения рекурсии
  }) async {
    ApiLogger.logDebug('🚀 request START: $method $path');
    ApiLogger.logDebug('📝 Параметры: requireAuth=$requireAuth, isRefreshAttempt=$isRefreshAttempt, data=${data != null ? "есть" : "нет"}, queryParams=${queryParams != null ? "есть" : "нет"}');
    
    // Строим URI с query параметрами
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
      ApiLogger.logDebug('🔧 Добавлены query параметры: $queryParams');
    }
    
    ApiLogger.logDebug('🌐 Полный URL: $uri');

    // Функция выполнения запроса
    Future<dynamic> executeRequest() async {
      ApiLogger.logDebug('📡 executeRequest: начало выполнения');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final body = data != null ? jsonEncode(data) : null;
      
      ApiLogger.logRequest(method, uri.toString(), headers: headers, body: data);
      
      http.Response response;
      
      try {
        switch (method.toUpperCase()) {
          case 'GET':
            ApiLogger.logDebug('📤 Выполняем GET запрос');
            response = await http.get(uri, headers: headers);
            break;
          case 'POST':
            ApiLogger.logDebug('📤 Выполняем POST запрос');
            response = await http.post(uri, headers: headers, body: body);
            break;
          case 'PUT':
            ApiLogger.logDebug('📤 Выполняем PUT запрос');
            response = await http.put(uri, headers: headers, body: body);
            break;
          case 'DELETE':
            ApiLogger.logDebug('📤 Выполняем DELETE запрос');
            response = await http.delete(uri, headers: headers);
            break;
          case 'PATCH':
            ApiLogger.logDebug('📤 Выполняем PATCH запрос');
            response = await http.patch(uri, headers: headers, body: body);
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }
        
        ApiLogger.logDebug('📥 Получен ответ: statusCode=${response.statusCode}');
        ApiLogger.logResponse(response.statusCode, response.body);
        return _handleResponse(response);
      } catch (e) {
        ApiLogger.logError(e);
        rethrow;
      }
    }
    
    try {
      ApiLogger.logDebug('⏱️ Запускаем запрос с таймаутом ${ApiConfig.connectionTimeout} секунд');
      final result = await executeRequest().timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () {
          ApiLogger.logDebug('⏰ Таймаут! Превышено время ожидания');
          throw ApiException('Превышено время ожидания');
        },
      );
      ApiLogger.logDebug('✅ request успешно завершен');
      return result;
    } on UnauthorizedException catch (e) {
      ApiLogger.logDebug('🔐 Получена 401 ошибка (Unauthorized)');
      // Если токен истек и требуется авторизация, и это не попытка обновления
      if (requireAuth && !isRefreshAttempt) {
        ApiLogger.logDebug('🔄 Пытаемся обновить токен...');
        // Пытаемся обновить токен
        final newToken = await _refreshToken();
        
        if (newToken != null) {
          ApiLogger.logDebug('✅ Токен успешно обновлен, повторяем запрос');
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
          
          ApiLogger.logDebug('📥 Получен повторный ответ: statusCode=${retryResponse.statusCode}');
          ApiLogger.logResponse(retryResponse.statusCode, retryResponse.body);
          return _handleResponse(retryResponse);
        } else {
          ApiLogger.logDebug('❌ Не удалось обновить токен, очищаем данные');
          // Не удалось обновить токен - очищаем данные
          await AuthService.clearAuthData();
          rethrow;
        }
      }
      ApiLogger.logDebug('❌ Unauthorized, но requireAuth=false или isRefreshAttempt=true, пробрасываем дальше');
      rethrow;
    } on SocketException catch (e) {
      ApiLogger.logDebug('🌐 Ошибка сети: $e');
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      ApiLogger.logDebug('💥 Непредвиденная ошибка: $e');
      rethrow;
    }
  }
  
  // Обновление токена с очередью запросов
  Future<String?> _refreshToken() async {
    ApiLogger.logDebug('🔄 _refreshToken: начало');
    
    // Если уже идет обновление, добавляем запрос в очередь
    if (_isRefreshing) {
      ApiLogger.logDebug('⏳ Уже идет обновление токена, добавляем в очередь');
      final completer = Completer<String?>();
      _pendingRequests.add(completer);
      ApiLogger.logDebug('📋 В очереди ${_pendingRequests.length} запросов');
      return completer.future;
    }
    
    _isRefreshing = true;
    ApiLogger.logDebug('🔒 Начинаем обновление токена');
    
    try {
      final refreshToken = await AuthService.getRefreshToken();
      ApiLogger.logDebug('🔑 Получен refresh токен: ${refreshToken != null ? "есть (${refreshToken.substring(0, refreshToken.length > 20 ? 20 : refreshToken.length)}...)" : "нет"}');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        ApiLogger.logDebug('❌ Refresh токен отсутствует');
        return null;
      }
      
      ApiLogger.logDebug('📡 Отправляем запрос на обновление токена (isRefreshAttempt=true)');
      
      // ВАЖНО: Используем прямой HTTP запрос, чтобы избежать рекурсии
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
      final body = jsonEncode({'refresh_token': refreshToken});
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: ApiConfig.connectionTimeout));
      
      ApiLogger.logDebug('📥 Получен ответ от /auth/refresh: statusCode=${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ApiLogger.logDebug('📦 Ответ от сервера: ${data.keys}');
        
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          ApiLogger.logDebug('✅ Получены новые токены');
          
          // Сохраняем новые токены
          await AuthService.saveToken(data['accessToken']);
          await AuthService.saveRefreshToken(data['refreshToken']);
          
          if (data['ttl'] != null) {
            await AuthService.saveTokenExpiry(data['ttl']);
            ApiLogger.logDebug('⏱️ Сохранен TTL access токена: ${data['ttl']} секунд');
          }
          if (data['refreshTtl'] != null) {
            await AuthService.saveRefreshTokenExpiry(data['refreshTtl']);
            ApiLogger.logDebug('⏱️ Сохранен TTL refresh токена: ${data['refreshTtl']} секунд');
          }
          
          // Обрабатываем ожидающие запросы
          ApiLogger.logDebug('📋 Обрабатываем ${_pendingRequests.length} ожидающих запросов');
          for (final completer in _pendingRequests) {
            completer.complete(data['accessToken']);
          }
          _pendingRequests.clear();
          
          ApiLogger.logDebug('✅ Обновление токена успешно завершено');
          return data['accessToken'];
        } else {
          ApiLogger.logDebug('❌ Ответ не содержит accessToken или refreshToken');
          return null;
        }
      } else if (response.statusCode == 401) {
        ApiLogger.logDebug('❌ Refresh токен истек или недействителен (401)');
        await AuthService.clearAuthData();
        return null;
      } else {
        ApiLogger.logDebug('❌ Неожиданный статус ответа: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      ApiLogger.logDebug('❌ Ошибка обновления токена: $e');
      
      // Обрабатываем ожидающие запросы с ошибкой
      for (final completer in _pendingRequests) {
        completer.completeError(e);
      }
      _pendingRequests.clear();
      
      return null;
    } finally {
      _isRefreshing = false;
      ApiLogger.logDebug('🔓 Обновление токена завершено, флаг сброшен');
    }
  }

  // Обработка ответа
  dynamic _handleResponse(http.Response response) {
    ApiLogger.logDebug('📊 _handleResponse: statusCode=${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      ApiLogger.logDebug('✅ Успешный ответ (${response.statusCode})');
      if (response.body.isEmpty) {
        ApiLogger.logDebug('📭 Пустое тело ответа');
        return {};
      }
      try {
        final decoded = jsonDecode(response.body);
        ApiLogger.logDebug('📦 Ответ декодирован успешно');
        return decoded;
      } catch (e) {
        ApiLogger.logDebug('⚠️ Не удалось декодировать JSON: $e');
        return response.body;
      }
    } else if (response.statusCode == 401) {
      ApiLogger.logDebug('🔐 401 Unauthorized - сессия истекла');
      throw UnauthorizedException('Сессия истекла. Пожалуйста, войдите снова.');
    } else if (response.statusCode == 422) {
      ApiLogger.logDebug('⚠️ 422 Validation Error');
      throw ValidationException.fromResponse(response);
    } else if (response.statusCode == 404) {
      ApiLogger.logDebug('🔍 404 Not Found');
      throw NotFoundException('Ресурс не найден');
    } else if (response.statusCode >= 500) {
      ApiLogger.logDebug('💥 ${response.statusCode} Server Error');
      throw ServerException('Внутренняя ошибка сервера');
    } else {
      ApiLogger.logDebug('❌ Неизвестная ошибка: ${response.statusCode}');
      throw ApiException('Ошибка: ${response.statusCode}');
    }
  }

  // Упрощенные публичные методы
  Future<dynamic> get(String path, {Map<String, String>? queryParams, bool requireAuth = true}) {
    ApiLogger.logDebug('📡 GET вызов: $path');
    return request('GET', path, queryParams: queryParams, requireAuth: requireAuth);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data, bool requireAuth = true}) {
    ApiLogger.logDebug('📡 POST вызов: $path');
    return request('POST', path, data: data, requireAuth: requireAuth);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? data, bool requireAuth = true}) {
    ApiLogger.logDebug('📡 PUT вызов: $path');
    return request('PUT', path, data: data, requireAuth: requireAuth);
  }

  Future<dynamic> delete(String path, {bool requireAuth = true}) {
    ApiLogger.logDebug('📡 DELETE вызов: $path');
    return request('DELETE', path, requireAuth: requireAuth);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? data, bool requireAuth = true}) {
    ApiLogger.logDebug('📡 PATCH вызов: $path');
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