import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static const bool _enabled = kDebugMode;
  static const int _maxLogLength = 2000; // Лимит для обычного Body

  static void _print(String message) {
    if (_enabled) {
      debugPrint(message);
    }
  }

  static void logRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    final token = headers?['Authorization'];
    _print('➡️ $method: $url');

    // Если токен есть, выводим его отдельной строкой полностью
    if (token != null) {
      _print('🔑 Auth: $token'); 
    }

    if (body != null) {
      _print('📦 Body: ${_truncate(_prettyJson(body))}');
    }
  }

  static void logResponse(int statusCode, dynamic body) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    
    _print('$icon STATUS: $statusCode');

    if (body != null) {
      _print('📥 Body: ${_truncate(_prettyJson(body))}');
    }
    _print('---');
  }

  static void logError(dynamic error) {
    _print('🔥 ERROR: $error');
  }

  static String _truncate(String text) {
    if (text.length > _maxLogLength) {
      return '${text.substring(0, _maxLogLength)}... [ОБРЕЗАНО]';
    }
    return text;
  }

  static String _prettyJson(dynamic input) {
    try {
      dynamic decoded = (input is String) ? jsonDecode(input) : input;
      return jsonEncode(decoded);
    } catch (_) {
      return input.toString();
    }
  }
}