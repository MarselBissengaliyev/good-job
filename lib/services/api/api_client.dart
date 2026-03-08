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
  
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await AuthService.getToken();
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      return headers;
    } catch (e) {
      ApiLogger.logError(e);
      return ApiConfig.defaultHeaders;
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
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

  Future<dynamic> post(String path, {dynamic body}) async {
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

  Future<dynamic> put(String path, {dynamic body}) async {
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

  
  Future<dynamic> patch(String path, {dynamic body}) async {
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

  Future<dynamic> delete(String path) async {
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
      AuthService.clearAuthData();
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