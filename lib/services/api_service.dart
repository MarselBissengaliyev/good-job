import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_application_1/models/work-photo.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'auth_service.dart';
import 'package:async/async.dart';

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

  // В файле api_service.dart добавьте этот метод
  static Future<Map<String, dynamic>> getOrders({
    int? page,
    int? perPage,
  }) async {
    final url = Uri.parse('$baseUrl/orders');

    logApi('Getting orders:');
    logApi('  URL: $url');
    logApi('  Page: $page');
    logApi('  Per page: $perPage');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      // Добавляем query параметры, если они есть
      final Map<String, String> queryParams = {};
      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      final response = await http
          .get(url.replace(queryParameters: queryParams), headers: headers)
          .timeout(const Duration(seconds: 30));

      logApi('Response status: ${response.statusCode}');
      logApi('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          logApi('Orders loaded successfully');
          logApi('Orders count: ${data['data']?.length ?? 0}');
          return data;
        } catch (e) {
          logApi('JSON parsing error: $e', isError: true);
          throw Exception('Failed to parse orders response: $e');
        }
      } else if (response.statusCode == 401) {
        logApi('Unauthorized - clearing auth data', isError: true);
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else {
        logApi(
          'Failed to load orders, status: ${response.statusCode}',
          isError: true,
        );
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      logApi('Request timeout: $e', isError: true);
      throw Exception('Превышено время ожидания при загрузке заказов');
    } catch (e, stackTrace) {
      logApi('Unexpected error: $e', isError: true);
      logApi('Stack trace: $stackTrace', isError: true);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadWorkPhoto(File imageFile) async {
    final url = Uri.parse('$baseUrl/me/master/work-photos');

    print('=== ЗАГРУЗКА ИЗОБРАЖЕНИЯ НА СЕРВЕР ===');
    print('  URL: $url');
    print('  File path: ${imageFile.path}');
    print('  File size: ${imageFile.lengthSync()} bytes');

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Токен не найден');
        throw Exception('Токен не найден. Пожалуйста, войдите снова.');
      }

      print('  Token получен: ${token.substring(0, min(20, token.length))}...');

      // Создаем multipart запрос
      var request = http.MultipartRequest('POST', url);

      // Добавляем заголовки
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      print('  Headers: ${request.headers}');

      // Добавляем файл
      var stream = http.ByteStream(
        DelegatingStream.typed(imageFile.openRead()),
      );
      var length = await imageFile.length();
      var filename = path.basename(imageFile.path);

      print('  File name: $filename');
      print('  File length: $length bytes');

      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: filename,
      );

      request.files.add(multipartFile);

      // Отправляем запрос
      print('  Отправка запроса...');
      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      print('  Response status: ${response.statusCode}');
      print('  Response headers: ${response.headers}');
      print('  Response body: $responseString');

      // Обрабатываем как успешные статусы 200 и 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(responseString);
          print('✅ Work photo uploaded successfully!');
          print('  Response data: $responseData');
          return responseData;
        } catch (e) {
          print('❌ JSON parsing error: $e');
          throw Exception('Ошибка обработки ответа: $e');
        }
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized');
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 422) {
        try {
          final errorData = json.decode(responseString);
          print('❌ Validation error: $errorData');
          final errors = errorData['errors'] ?? {};
          final errorMessage = errors.isNotEmpty
              ? 'Ошибка валидации: $errors'
              : 'Ошибка валидации изображения';
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error parsing validation response: $e');
          throw Exception('Ошибка валидации изображения');
        }
      } else if (response.statusCode == 413) {
        print('❌ 413 Payload Too Large');
        throw Exception('Файл слишком большой');
      } else if (response.statusCode == 415) {
        print('❌ 415 Unsupported Media Type');
        throw Exception('Неподдерживаемый формат изображения');
      } else {
        print('❌ Unexpected error: ${response.statusCode}');
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('Превышено время ожидания');
    } on Exception catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  static Future<List<WorkPhoto>> getWorkPhotos() async {
    final url = Uri.parse('$baseUrl/me/master');

    print('=== ПОЛУЧЕНИЕ РАБОТ МАСТЕРА ===');
    print('  URL: $url');

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Токен не найден');
        throw Exception('Токен не найден. Пожалуйста, войдите снова.');
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('  Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('  Response status: ${response.statusCode}');
      print('  Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final masterData = responseData['data'];

        print('  Master data received: $masterData');
        print('  Master data type: ${masterData.runtimeType}');
        print('  Master data keys: ${masterData.keys}');

        // Проверяем, что workPhotos существует
        if (masterData != null && masterData.containsKey('workPhotos')) {
          final workPhotos = masterData['workPhotos'];

          print('  workPhotos found: $workPhotos');
          print('  workPhotos type: ${workPhotos.runtimeType}');
          print(
            '  workPhotos length: ${workPhotos is List ? workPhotos.length : "N/A"}',
          );

          // Проверяем, что workPhotos не null и является списком
          if (workPhotos is List) {
            print('  Parsing work photos...');
            final result = workPhotos.map((photo) {
              print('    Processing photo: $photo');
              try {
                final workPhoto = WorkPhoto.fromJson(photo);
                print(
                  '    ✅ Successfully parsed: ID=${workPhoto.id}, Path=${workPhoto.path}',
                );
                return workPhoto;
              } catch (e) {
                print('    ❌ Error parsing photo: $e');
                throw e;
              }
            }).toList();

            print('✅ Преобразовано ${result.length} фотографий');
            return result;
          } else {
            print(
              '⚠️ workPhotos не является списком. Тип: ${workPhotos.runtimeType}',
            );
            return []; // Возвращаем пустой список
          }
        } else {
          print(
            '⚠️ workPhotos не найдены в ответе API. Доступные ключи: ${masterData?.keys}',
          );
          return []; // Возвращаем пустой список
        }
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized');
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else {
        print('❌ Ошибка загрузки работ: ${response.statusCode}');
        throw Exception('Ошибка загрузки работ: ${response.statusCode}');
      }
    } on Exception catch (e) {
      print('❌ Get work photos error: $e');
      rethrow;
    }
  }

  static Future<void> deleteWorkPhoto(int id) async {
    final url = Uri.parse('$baseUrl/me/master/work-photos/$id');

    print('Deleting work photo:');
    print('  URL: $url');
    print('  ID: $id');

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Токен не найден. Пожалуйста, войдите снова.');
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(url, headers: headers);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Work photo deleted successfully');
      } else if (response.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 404) {
        throw Exception('Работа не найдена');
      } else {
        throw Exception('Ошибка удаления: ${response.statusCode}');
      }
    } on Exception catch (e) {
      print('Delete error: $e');
      rethrow;
    }
  }

  // Обновление категории пользователя
  static Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
  }) async {
    final url = Uri.parse('$baseUrl/me');

    logApi('Updating user category:');
    logApi('  URL: $url');
    logApi('  categoryId: $categoryId');

    try {
      final headers = await _getHeaders();
      logApi('Request headers: $headers');

      final profile = await getProfile();
      final data = profile['data'];

      logApi('DATA: $data');

      // Формируем полное тело запроса на основе данных профиля
      final body = <String, dynamic>{
        'category_id': categoryId, // новая категория
        // Копируем все существующие поля из профиля
        'firstname': data['firstname'],
        'lastname': data['lastname'], // обратите внимание на регистр!
        'patronymic': data['patronymic'],
        'telephone': data['telephone'],

        // Для вложенных объектов
        if (data['city'] != null) 'city_id': data['city']['id'],
        if (data['category'] != null)
          'category_id': categoryId, // перезаписываем категорию

        'active_mode':
            data['activeMode'], // или data['active_mode'] в зависимости от API
        'description': data['description'],
        'ttUrl': data['ttUrl'],
        'instUrl': data['instUrl'],

        // Для массивов
        'workPhotos': data['workPhotos'] ?? [],
        'subscriptions': data['subscriptions'] ?? [],
      };

      body.removeWhere((key, value) => value == null);

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
