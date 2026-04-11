// lib/services/api/api_logger.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static const bool _enabled = kDebugMode;
  static const int _maxLogLength = 2000; // Лимит для обычного Body
  static const int _maxTokenLength = 100; // Лимит для токена

  static void _print(String message) {
    if (_enabled) {
      debugPrint(message);
    }
  }

  static void logDebug(String message) {
    _print('🐛 DEBUG: $message');
  }

  static void logRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _print('➡️ $method: $url');
    
    // Выводим заголовки (кроме Authorization)
    if (headers != null && headers.isNotEmpty) {
      _print('📋 Headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          final token = value.toString();
          if (token.length > _maxTokenLength) {
            _print('   $key: Bearer ${token.substring(0, _maxTokenLength)}...');
          } else {
            _print('   $key: $value');
          }
        } else {
          _print('   $key: $value');
        }
      });
    }

    if (body != null) {
      _print('📦 Body: ${_truncate(_prettyJson(body))}');
    }
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static void logResponse(int statusCode, dynamic body, {bool isRetry = false}) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    final retryMark = isRetry ? ' [RETRY]' : '';
    
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _print('$icon STATUS: $statusCode$retryMark');

    if (body != null && body.isNotEmpty) {
      _print('📥 Body: ${_truncate(_prettyJson(body))}');
    } else {
      _print('📥 Body: <empty>');
    }
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static void logError(dynamic error) {
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _print('🔥 ERROR: $error');
    if (error is StackTrace) {
      _print('📚 StackTrace: $error');
    }
    _print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static String _truncate(String text) {
    if (text.length > _maxLogLength) {
      return '${text.substring(0, _maxLogLength)}... [ОБРЕЗАНО, всего ${text.length} символов]';
    }
    return text;
  }

  static String _prettyJson(dynamic input) {
    try {
      dynamic decoded;
      if (input is String) {
        if (input.isEmpty) return '<empty>';
        decoded = jsonDecode(input);
      } else {
        decoded = input;
      }
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return input.toString();
    }
  }
}