// lib/services/master/work_photos_api.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../models/work-photo.dart';
import '../api/api_client.dart';
import '../api/api_logger.dart';
import '../auth/auth_service.dart';

class WorkPhotosApi {
  final ApiClient _client;

  WorkPhotosApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> uploadWorkPhoto(File imageFile) async {
    const method = 'POST';
    final url = Uri.parse('${_client.baseUrl}/me/master/work-photos');

    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Токен не найден. Пожалуйста, войдите снова.');
    }

    ApiLogger.logRequest(
      method,
      url.toString(),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ***',
      },
      body: {
        'file_name': path.basename(imageFile.path),
        'file_size': await imageFile.length(),
      },
    );

    try {
      final request = http.MultipartRequest(method, url)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: path.basename(imageFile.path),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes);

      dynamic decodedBody;
      try {
        decodedBody = jsonDecode(responseString);
      } catch (_) {
        decodedBody = responseString;
      }

      ApiLogger.logResponse(streamedResponse.statusCode, decodedBody);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        return decodedBody;
      } else if (streamedResponse.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else if (streamedResponse.statusCode == 422) {
        throw Exception(decodedBody['message'] ?? 'Ошибка валидации изображения');
      } else {
        throw Exception('Ошибка загрузки: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<List<WorkPhoto>> getWorkPhotos() async {
    const method = 'GET';
    const url = '/me/master';

    ApiLogger.logRequest(method, url);

    try {
      final response = await _client.get(url);
      ApiLogger.logResponse(200, response);

      final masterData = response['data'];

      if (masterData != null && masterData.containsKey('workPhotos')) {
        final workPhotos = masterData['workPhotos'];

        if (workPhotos is List) {
          return workPhotos
              .map((photo) => WorkPhoto.fromJson(photo))
              .toList();
        }
      }

      return [];
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }

  Future<void> deleteWorkPhoto(int id) async {
    const method = 'DELETE';
    final url = '/me/master/work-photos/$id';

    ApiLogger.logRequest(method, url);

    try {
      await _client.delete(url);
      ApiLogger.logResponse(200, {'message': 'Work photo deleted'});
    } catch (e) {
      ApiLogger.logError(e);
      rethrow;
    }
  }
}
