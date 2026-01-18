import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

void logApi(String message, {bool isError = false}) {
  final timestamp = DateTime.now().toIso8601String();
  final prefix = isError ? '[API ERROR]' : '[API DEBUG]';
  print('$prefix [$timestamp] $message');
}

class ApiService {
  static const String baseUrl = 'http://gj-back.checkedout.kz/api';

 static Future<List<dynamic>> getCategories() async {
    final url = Uri.parse('$baseUrl/categories');

    logApi('Getting categories:');
    logApi('  URL: $url');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          logApi('Categories loaded successfully');
          logApi('Categories count: ${data['data']?.length ?? 0}');
          return data['data'] ?? [];
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse categories response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Unauthorized - clearing auth data', isError: true);
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else {
        logApi(
          'Failed to load categories, status: ${response.statusCode}',
          isError: true,
        );
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания при загрузке категорий');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  // Обновление категории пользователя
  static Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    String? patronymic,
    int? cityId,
    String? activeMode,
    String? firstname,
    String? lastname,
    String? telephone,
  }) async {
    final url = Uri.parse('$baseUrl/me');

    logApi('Updating user category:');
    logApi('  URL: $url');
    logApi('  categoryId: $categoryId');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      // Подготавливаем тело запроса
      final body = <String, dynamic>{
        'category_id': categoryId,
      };

      // Добавляем опциональные поля, если они переданы
      if (patronymic != null) body['patronymic'] = patronymic;
      if (cityId != null) body['city_id'] = cityId;
      if (activeMode != null) body['active_mode'] = activeMode;
      if (firstname != null) body['firstname'] = firstname;
      if (lastname != null) body['lastname'] = lastname;
      if (telephone != null) body['telephone'] = telephone;

      logApi('Request body: $body');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Category updated successfully');
          logApi('Response data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Unauthorized - Token may be invalid or expired', isError: true);
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 422) {
        try {
          final errorData = jsonDecode(response.body);
          logApi('Validation error: $errorData', isError: true);

          String errorMessage = 'Ошибка валидации: ';
          final errors = errorData['errors'] ?? {};

          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '\n• $field: ${messages.join(', ')}';
            }
          });

          throw Exception(
            errorMessage.isNotEmpty ? errorMessage : 'Ошибка валидации данных',
          );
        } catch (e) {
          logApi('Error parsing validation response: $e', isError: true);
          throw Exception(
            'Ошибка валидации данных (код: ${response.statusCode})',
          );
        }
      } else if (response.statusCode == 500) {
        logApi('Server error: ${response.body}', isError: true);
        throw Exception('Внутренняя ошибка сервера. Попробуйте позже.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              errorBody['error'] ??
              'Failed to update category (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception(
            'Failed to update category: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception(
        'Превышено время ожидания. Проверьте подключение к интернету.',
      );
    } on http.ClientException catch (e) {
      logApi('Client exception: $e', isError: true);
      throw Exception('Ошибка сети: ${e.message}');
    } on FormatException catch (e) {
      logApi('Format exception: $e', isError: true);
      throw Exception('Ошибка формата данных: $e');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  // Простое обновление только категории (упрощенный метод)
  static Future<Map<String, dynamic>> updateUserCategory(int categoryId) async {
    return await updateCategory(categoryId: categoryId);
  }

  // Регистрация нового пользователя
  static Future<Map<String, dynamic>> registerUser({
    required String firstname,
    required String lastname,
    required String telephone,
    required int cityId,
    required String activeMode,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    logApi('Starting user registration:');
    logApi('  URL: $url');
    logApi('  firstname: $firstname');
    logApi('  lastname: $lastname');
    logApi('  telephone: $telephone');
    logApi('  cityId: $cityId');
    logApi('  activeMode: $activeMode');

    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      logApi('Request headers: $headers');

      final body = jsonEncode({
        'firstname': firstname,
        'lastname': lastname,
        'telephone': telephone,
        'city_id': cityId,
        'active_mode': activeMode,
      });
      logApi('Request body: $body');

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Registration successful');
          logApi('Response data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 422) {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('Validation error: $errorBody', isError: true);

          String errorMessage = 'Ошибка валидации: ';
          final errors = errorBody['errors'] ?? {};

          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '\n• $field: ${messages.join(', ')}';
            }
          });

          throw Exception(
            errorMessage.isNotEmpty ? errorMessage : 'Ошибка валидации данных',
          );
        } catch (e) {
          logApi('Error parsing validation response: $e', isError: true);
          throw Exception(
            'Ошибка валидации данных (код: ${response.statusCode})',
          );
        }
      } else if (response.statusCode == 409) {
        logApi('User already exists with this phone', isError: true);
        throw Exception('Пользователь с таким номером телефона уже существует');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              errorBody['error'] ??
              'Failed to register (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception(
            'Failed to register: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception(
        'Превышено время ожидания. Проверьте подключение к интернету.',
      );
    } on http.ClientException catch (e) {
      logApi('Client exception: $e', isError: true);
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  static Future<String?> getDebugSmsCode(String telephone) async {
    try {
      final cleanPhone = telephone.replaceAll(RegExp(r'\D'), '');
      final url = Uri.parse('$baseUrl/sms-codes/$cleanPhone');

      logApi('Fetching debug SMS code:');
      logApi('  URL: $url');
      logApi('  Clean phone: $cleanPhone');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          logApi('Debug SMS data: $data');

          if (data['data'] != null && data['data']['code'] != null) {
            final code = data['data']['code'].toString();
            logApi('Found debug SMS code: $code');
            return code;
          } else {
            logApi('No debug code found in response');
            return null;
          }
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          return null;
        }
      } else {
        logApi(
          'Failed to fetch debug SMS code, status: ${response.statusCode}',
          isError: true,
        );
        return null;
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      return null;
    } catch (e) {
      logApi('Error fetching debug SMS code: $e', isError: true);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDebugSmsData(String telephone) async {
    try {
      final cleanPhone = telephone.replaceAll(RegExp(r'\D'), '');
      final url = Uri.parse('$baseUrl/sms-codes/$cleanPhone');

      logApi('Fetching debug SMS data:');
      logApi('  URL: $url');
      logApi('  Clean phone: $cleanPhone');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          logApi('Debug SMS data received: $decoded');
          return decoded['data'];
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          return null;
        }
      } else {
        logApi(
          'Failed to fetch debug SMS data, status: ${response.statusCode}',
          isError: true,
        );
        return null;
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      return null;
    } catch (e) {
      logApi('Error fetching debug SMS data: $e', isError: true);
      return null;
    }
  }

  // Подтверждение телефона
  static Future<Map<String, dynamic>> confirmPhone({
    required String telephone,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/auth/confirm');

    logApi('Confirming phone:');
    logApi('  URL: $url');
    logApi('  telephone: $telephone');
    logApi('  code: $code');

    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      logApi('Request headers: $headers');

      final body = jsonEncode({'telephone': telephone, 'code': code});
      logApi('Request body: $body');

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Phone confirmation successful');
          logApi('Response data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('Invalid code error: $errorBody', isError: true);

          String errorMessage = 'Неверный код подтверждения';
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          } else if (errorBody['errors'] != null &&
              errorBody['errors']['code'] != null) {
            errorMessage = errorBody['errors']['code'].join(', ');
          }

          throw Exception(errorMessage);
        } catch (e) {
          logApi('Error parsing error response: $e', isError: true);
          throw Exception('Неверный код подтверждения');
        }
      } else if (response.statusCode == 404) {
        logApi('Phone number not found for confirmation', isError: true);
        throw Exception('Номер телефона не найден');
      } else if (response.statusCode == 410) {
        logApi('Confirmation code expired', isError: true);
        throw Exception('Срок действия кода истек. Запросите новый код.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              errorBody['error'] ??
              'Failed to confirm phone (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception(
            'Failed to confirm phone: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания');
    } on http.ClientException catch (e) {
      logApi('Client exception: $e', isError: true);
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  // Обновление токена
  static Future<Map<String, dynamic>> refreshToken({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/refresh');

    logApi('Refreshing token:');
    logApi('  URL: $url');
    logApi('  Token length: ${token.length}');

    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      logApi('Request headers: ${headers.keys.join(', ')}');

      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Token refresh successful');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Token refresh failed - invalid token', isError: true);
        throw Exception('Недействительный токен. Пожалуйста, войдите снова.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('Token refresh error: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              'Failed to refresh token (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception('Failed to refresh token: ${response.statusCode}');
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  // Получение информации о профиле
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await AuthService.getToken();

      logApi('Getting headers:');
      logApi('  Token exists: ${token != null}');
      logApi('  Token length: ${token?.length ?? 0}');
      if (token != null) {
        logApi(
          '  Token first 10 chars: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
        );
      }

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      logApi('Headers prepared: ${headers.keys.join(', ')}');

      return headers;
    } catch (e) {
      logApi('Error getting headers: $e', isError: true);
      return {'Accept': 'application/json', 'Content-Type': 'application/json'};
    }
  }

  static Future<dynamic> login({required String telephone}) async {
    final url = Uri.parse('$baseUrl/auth/login');

    logApi('User login:');
    logApi('  URL: $url');
    logApi('  telephone: $telephone');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final body = json.encode({'telephone': telephone});
      logApi('Request body: $body');

      final response = await http
          .post(Uri.parse('$baseUrl/auth/login'), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          logApi('Login request successful, SMS sent');
          logApi('Response data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 422) {
        try {
          final errorData = json.decode(response.body);
          logApi('Validation error: $errorData', isError: true);

          String errorMessage = 'Некорректный номер телефона';
          final errors = errorData['errors'] ?? {};

          if (errors.containsKey('telephone') && errors['telephone'] is List) {
            errorMessage = errors['telephone'].join(', ');
          }

          throw Exception(errorMessage);
        } catch (e) {
          logApi('Error parsing validation response: $e', isError: true);
          throw Exception('Некорректный номер телефона');
        }
      } else if (response.statusCode == 404) {
        logApi('User not found', isError: true);
        throw Exception('Пользователь с таким номером не найден');
      } else {
        try {
          final errorData = json.decode(response.body);
          logApi('Server error: $errorData', isError: true);

          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Ошибка сервера ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception('Ошибка сервера ${response.statusCode}');
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception(
        'Превышено время ожидания. Проверьте подключение к интернету.',
      );
    } on http.ClientException catch (e) {
      logApi('Client exception: $e', isError: true);
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/me');

    logApi('Getting profile:');
    logApi('  URL: $url');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Profile loaded successfully');
          logApi('Profile data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Unauthorized - clearing auth data', isError: true);
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 404) {
        logApi('Profile not found', isError: true);
        throw Exception('Профиль не найден');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              'Failed to load profile (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception('Failed to load profile: ${response.statusCode}');
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  static Future<List<dynamic>> getCities() async {
    final url = Uri.parse('$baseUrl/cities');

    logApi('Getting cities:');
    logApi('  URL: $url');

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          logApi('Cities loaded successfully');
          logApi('Cities count: ${data['data']?.length ?? 0}');
          return data['data'];
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else {
        logApi(
          'Failed to load cities, status: ${response.statusCode}',
          isError: true,
        );
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания при загрузке городов');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
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

    logApi('Updating profile:');
    logApi('  URL: $url');
    logApi('  firstname: $firstname');
    logApi('  lastname: $lastname');
    logApi('  patronymic: $patronymic');
    logApi('  cityId: $cityId');
    logApi('  activeMode: $activeMode');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final body = {
        'firstname': firstname,
        'lastname': lastname,
        'patronymic': patronymic ?? '',
        'city_id': cityId,
        'active_mode': activeMode,
      };

      // ВРЕМЕННОЕ РЕШЕНИЕ: Добавляем пустой массив категорий для мастера
      // если сервер этого требует
      if (activeMode == 'master') {
        body['category_id'] = 1; // Пустой массив
      }
      logApi('Request body: $body');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Profile updated successfully');
          logApi('Response data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Unauthorized - Token may be invalid or expired', isError: true);
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 422) {
        try {
          final errorData = jsonDecode(response.body);
          logApi('Validation error: $errorData', isError: true);

          String errorMessage = 'Ошибка валидации: ';
          final errors = errorData['errors'] ?? {};

          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '\n• $field: ${messages.join(', ')}';
            }
          });

          throw Exception(
            errorMessage.isNotEmpty ? errorMessage : 'Ошибка валидации данных',
          );
        } catch (e) {
          logApi('Error parsing validation response: $e', isError: true);
          throw Exception(
            'Ошибка валидации данных (код: ${response.statusCode})',
          );
        }
      } else if (response.statusCode == 500) {
        logApi('Server error: ${response.body}', isError: true);
        throw Exception('Внутренняя ошибка сервера. Попробуйте позже.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              errorBody['error'] ??
              'Failed to update profile (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception(
            'Failed to update profile: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception(
        'Превышено время ожидания. Проверьте подключение к интернету.',
      );
    } on http.ClientException catch (e) {
      logApi('Client exception: $e', isError: true);
      throw Exception('Ошибка сети: ${e.message}');
    } on FormatException catch (e) {
      logApi('Format exception: $e', isError: true);
      throw Exception('Ошибка формата данных: $e');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTelephone({
    required String telephone,
  }) async {
    final url = Uri.parse('$baseUrl/me/tel');

    logApi('Updating telephone:');
    logApi('  URL: $url');
    logApi('  telephone: $telephone');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final body = {'telephone': telephone};
      logApi('Request body: $body');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          logApi('Telephone update request sent successfully');
          logApi('Response data: $responseData');
          return responseData;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Unauthorized - Token may be invalid or expired', isError: true);
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 422) {
        try {
          final errorData = jsonDecode(response.body);
          logApi('Validation error: $errorData', isError: true);

          String errorMessage = 'Некорректный номер телефона';
          final errors = errorData['errors'] ?? {};

          if (errors.containsKey('telephone') && errors['telephone'] is List) {
            errorMessage = errors['telephone'].join(', ');
          }

          throw Exception(errorMessage);
        } catch (e) {
          logApi('Error parsing validation response: $e', isError: true);
          throw Exception('Некорректный формат телефона');
        }
      } else if (response.statusCode == 409) {
        logApi('Phone number conflict: ${response.body}', isError: true);
        throw Exception(
          'Этот номер телефона уже используется другим пользователем',
        );
      } else if (response.statusCode == 500) {
        logApi('Server error: ${response.body}', isError: true);
        throw Exception('Внутренняя ошибка сервера. Попробуйте позже.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              errorBody['error'] ??
              'Failed to update telephone (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception(
            'Failed to update telephone: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception(
        'Превышено время ожидания. Проверьте подключение к интернету.',
      );
    } on http.ClientException catch (e) {
      logApi('Client exception: $e', isError: true);
      throw Exception('Ошибка сети: ${e.message}');
    } on FormatException catch (e) {
      logApi('Format exception: $e', isError: true);
      throw Exception('Ошибка формата данных: $e');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  static Future<Map<String, dynamic>> confirmNewTelephone({
    required String telephone,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/me/tel/confirm');

    logApi('Confirming new telephone:');
    logApi('  URL: $url');
    logApi('  telephone: $telephone');
    logApi('  code: $code');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final body = {'telephone': telephone, 'code': code};
      logApi('Request body: $body');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response headers: ${response.headers}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          logApi('Telephone confirmed successfully');

          if (data['access_token'] != null) {
            await AuthService.saveToken(data['access_token']);
            logApi('New token saved successfully');
          } else {
            logApi('No new token in response');
          }

          return data;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        try {
          final errorData = jsonDecode(response.body);
          logApi('Invalid code error: $errorData', isError: true);

          final errorMessage =
              errorData['message'] ??
              'Неверный код подтверждения. Попробуйте еще раз.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Неверный код подтверждения');
        }
      } else if (response.statusCode == 404) {
        logApi('Phone number not found for confirmation', isError: true);
        throw Exception('Запрос на подтверждение телефона не найден');
      } else if (response.statusCode == 410) {
        logApi('Confirmation code expired', isError: true);
        throw Exception('Срок действия кода истек. Запросите новый код.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          logApi('API error response: $errorBody', isError: true);

          final errorMessage =
              errorBody['message'] ??
              'Failed to confirm telephone (${response.statusCode})';
          throw Exception(errorMessage);
        } catch (e) {
          logApi('Raw error response: ${response.body}', isError: true);
          throw Exception(
            'Failed to confirm telephone: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }
}
