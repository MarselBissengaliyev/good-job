import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth_service.dart';

class HttpClient {
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await AuthService.getToken();
    
    final defaultHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    return await http.post(
      url,
      headers: defaultHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // Аналогичные методы для get, put, delete
}