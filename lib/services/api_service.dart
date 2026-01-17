import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://gj-back.checkedout.kz/api';

  

  // Регистрация нового пользователя
  static Future<Map<String, dynamic>> registerUser({
    required String firstname,
    required String lastname,
    required String telephone,
    required int cityId,
    required String activeMode,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'firstname': firstname,
        'lastname': lastname,
        'telephone': telephone,
        'city_id': cityId,
        'active_mode': activeMode,
      }),
    );

    print('[API DEBUG] Статус код регистрации: ${response.statusCode}');
    print('[API DEBUG] Тело ответа: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        print('[API DEBUG] Ошибка в формате JSON: $errorBody');

        // Если есть структурированная ошибка, бросаем ее как Map
        if (errorBody is Map<String, dynamic>) {
          throw errorBody; // Бросаем Map вместо Exception
        } else {
          throw {
            'message': 'Failed to register: ${response.statusCode}',
            'raw_error': errorBody.toString(),
          };
        }
      } catch (e) {
        print('[API DEBUG] Ошибка парсинга ответа: $e');
        // Если не удалось распарсить JSON, бросаем строку
        throw {
          'message': 'Failed to register: ${response.statusCode}',
          'raw_response': response.body,
        };
      }
    }
  }

  static Future<String?> getDebugSmsCode(String telephone) async {
    try {
      final cleanPhone = telephone.replaceAll(RegExp(r'\D'), '');
      final url = Uri.parse('$baseUrl/sms-codes/$cleanPhone');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      print('[API DEBUG] SMS Code status: ${response.statusCode}');
      print('[API DEBUG] SMS Code body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['code'] != null) {
          return data['data']['code'].toString();
        }
      }
      return null;
    } catch (e) {
      print('[API DEBUG] Error fetching debug SMS code: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDebugSmsData(String telephone) async {
    try {
      // Очищаем номер от лишних символов
      final cleanPhone = telephone.replaceAll(RegExp(r'\D'), '');
      final response = await http.get(
        Uri.parse('$baseUrl/sms-codes/$cleanPhone'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data']; // Возвращает {code: "4088", payload: {...}}
      }
      return null;
    } catch (e) {
      return null;
    }
  }
 


  // Подтверждение телефона
  static Future<Map<String, dynamic>> confirmPhone({
    required String telephone,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/auth/confirm');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'telephone': telephone, 'code': code}),
    );

    print('[API DEBUG] Статус код подтверждения: ${response.statusCode}');
    print('[API DEBUG] Тело ответа подтверждения: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        print('[API DEBUG] Ошибка подтверждения: $errorBody');

        if (errorBody is Map<String, dynamic>) {
          throw errorBody;
        } else {
          throw {
            'message': 'Failed to confirm phone: ${response.statusCode}',
            'raw_error': errorBody.toString(),
          };
        }
      } catch (e) {
        print('[API DEBUG] Ошибка парсинга ответа подтверждения: $e');
        throw {
          'message': 'Failed to confirm phone: ${response.statusCode}',
          'raw_response': response.body,
        };
      }
    }
  }

  // Обновление токена
  static Future<Map<String, dynamic>> refreshToken({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/refresh');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh token: ${response.statusCode}');
    }
  }

  // Получение информации о профиле
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

   static Future<dynamic> login({
    required String telephone,
  }) async {
    try {
      print('[DEBUG] Отправка запроса на вход...');
      print('[DEBUG] Телефон: $telephone');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: json.encode({
          'telephone': telephone,
        }),
      );

      print('[DEBUG] Статус ответа: ${response.statusCode}');
      print('[DEBUG] Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('[DEBUG] Успешный вход, код отправлен');
        return responseData;
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        print('[DEBUG] Ошибка валидации: $errorData');
        throw errorData;
      } else {
        final errorData = json.decode(response.body);
        print('[DEBUG] Ошибка сервера: $errorData');
        throw errorData ?? 'Ошибка сервера ${response.statusCode}';
      }
    } catch (e) {
      print('[ERROR] Исключение в методе login: $e');
      rethrow;
    }
  }

  // Пример обновления метода getProfile
  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/me');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await AuthService.clearAuthData();
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<List<dynamic>> getCities() async {
    final url = Uri.parse('$baseUrl/cities');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load cities');
    }
  }

  // Обновление профиля (PUT /me)
  static Future<Map<String, dynamic>> updateProfile({
    required String firstname,
    required String lastname,
    String? patronymic,
    required int cityId,
    required String activeMode,
  }) async {
    final url = Uri.parse('$baseUrl/me');
    final headers = await _getHeaders();

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        'firstname': firstname,
        'lastname': lastname,
        'patronymic': patronymic ?? '', // или null, если API позволяет
        'city_id': cityId,
        'active_mode': activeMode,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update profile');
    }
  }

  static Future<Map<String, dynamic>> updateTelephone({
    required String telephone,
  }) async {
    final url = Uri.parse('$baseUrl/me/tel');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'telephone': telephone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update telephone');
    }
  }

  static Future<Map<String, dynamic>> confirmNewTelephone({
    required String telephone,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/me/tel/confirm');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'telephone': telephone, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Сохраняем новый токен
      if (data['access_token'] != null) {
        await AuthService.saveToken(data['access_token']);
      }
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to confirm telephone');
    }
  }
}
