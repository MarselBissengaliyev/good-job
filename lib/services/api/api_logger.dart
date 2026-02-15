// lib/services/api/api_logger.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static const bool _enabled = kDebugMode; // отключается в release

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
    _print('''
══════════════════════════════════════════════
➡️  REQUEST
Method: $method
URL: $url
''');

    if (headers != null) {
      _print('📨 Headers:\n${_prettyJson(headers)}');
    }

    if (body != null) {
      _print('📦 Body:\n${_prettyJson(body)}');
    }

    _print('══════════════════════════════════════════════');
  }

  static void logResponse(int statusCode, dynamic body) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';

    _print('''
══════════════════════════════════════════════
$icon RESPONSE
Status: $statusCode
''');

    if (body != null) {
      _print('📦 Body:\n${_prettyJson(body)}');
    }

    _print('══════════════════════════════════════════════');
  }

  static void logError(dynamic error) {
    _print('''
══════════════════════════════════════════════
🔥 ERROR
$error
══════════════════════════════════════════════
''');
  }

  static String _prettyJson(dynamic input) {
    try {
      dynamic decoded;

      if (input is String) {
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
