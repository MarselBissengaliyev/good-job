// lib/services/api/avatar_api.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'api_client.dart';
import 'api_logger.dart';
import '../auth/auth_service.dart';

class AvatarApi {
  final ApiClient _client;

  AvatarApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Загрузка/обновление аватара профиля
  /// PUT /api/me/avatar с multipart/form-data
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    const method = 'PUT';
    const url = '/me/avatar';
    final fullUrl = Uri.parse('${_client.baseUrl}$url');

    ApiLogger.logRequest(method, fullUrl.toString(), body: {
      'file': imageFile.path,
      'size': '${imageFile.lengthSync()} bytes',
    });

    try {
      final token = await AuthService.getToken();

      if (token == null) {
        throw UnauthorizedException('Токен не найден. Пожалуйста, войдите снова.');
      }

      // Создаем multipart запрос с методом PUT
      var request = http.MultipartRequest(method, fullUrl);

      // Добавляем заголовки
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      // Добавляем файл с именем поля 'image' (как требует API)
      var stream = http.ByteStream(
        DelegatingStream.typed(imageFile.openRead()),
      );
      var length = await imageFile.length();
      var filename = path.basename(imageFile.path);

      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: filename,
      );

      request.files.add(multipartFile);

      // Отправляем запрос
      var streamedResponse = await request.send();
      var responseString = await streamedResponse.stream.bytesToString();

      ApiLogger.logResponse(streamedResponse.statusCode, responseString);

      // Обрабатываем ответ
      if (streamedResponse.statusCode == 200) {
        try {
          final responseData = json.decode(responseString);
          return responseData;
        } catch (e) {
          ApiLogger.logError(e);
          throw ApiException('Ошибка обработки ответа сервера');
        }
      } else if (streamedResponse.statusCode == 401) {
        await AuthService.clearAuthData();
        throw UnauthorizedException('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (streamedResponse.statusCode == 422) {
        try {
          final errorData = json.decode(responseString);
          throw ValidationException(
            errorData['errors'] ?? {},
            'Ошибка валидации изображения',
          );
        } catch (e) {
          if (e is ValidationException) rethrow;
          throw ValidationException({}, 'Ошибка валидации изображения');
        }
      } else if (streamedResponse.statusCode == 413) {
        throw ApiException('Файл слишком большой. Максимальный размер: 2MB');
      } else if (streamedResponse.statusCode == 415) {
        throw ApiException(
          'Неподдерживаемый формат изображения. Используйте JPEG, PNG или WEBP',
        );
      } else {
        throw ApiException('Ошибка загрузки аватара: ${streamedResponse.statusCode}');
      }
    } on SocketException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Ошибка сети. Проверьте подключение к интернету.');
    } on TimeoutException catch (e) {
      ApiLogger.logError(e);
      throw ApiException('Превышено время ожидания');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  /// Удаление аватара (если API поддерживает)
  Future<void> deleteAvatar() async {
    const method = 'DELETE';
    const url = '/me/avatar';
    final fullUrl = Uri.parse('${_client.baseUrl}$url');

    ApiLogger.logRequest(method, fullUrl.toString());

    try {
      await _client.delete(url);
      ApiLogger.logResponse(200, 'Аватар успешно удален');
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}