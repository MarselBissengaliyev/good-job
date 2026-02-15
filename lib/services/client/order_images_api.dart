// lib/services/orders/order_images_api.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import '../api/api_client.dart';
import '../api/api_logger.dart';
import '../auth/auth_service.dart';

class OrderImagesApi {
  final ApiClient _client;

  OrderImagesApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<String>> uploadOrderImages(List<File> imageFiles) async {
    const method = 'POST';
    const url = '/orders/images';
    final fullUrl = Uri.parse('${_client.baseUrl}$url');

    ApiLogger.logRequest(method, fullUrl.toString(), body: {
      'files_count': imageFiles.length,
      'files': imageFiles.map((f) => '${f.path} (${f.lengthSync()} bytes)').toList(),
    });

    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw UnauthorizedException('Токен не найден. Пожалуйста, войдите снова.');
      }

      final List<String> imagePaths = [];

      for (var i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        
        try {
          ApiLogger.logRequest(method, '$fullUrl (file ${i + 1}/${imageFiles.length})', body: {
            'file': imageFile.path,
            'size': '${imageFile.lengthSync()} bytes',
          });

          var request = http.MultipartRequest(method, fullUrl);
          request.headers['Accept'] = 'application/json';
          request.headers['Authorization'] = 'Bearer $token';

          var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
          var length = await imageFile.length();
          var filename = path.basename(imageFile.path);

          var multipartFile = http.MultipartFile('image', stream, length, filename: filename);
          request.files.add(multipartFile);

          var streamedResponse = await request.send();
          var responseString = await streamedResponse.stream.bytesToString();

          ApiLogger.logResponse(streamedResponse.statusCode, responseString);

          if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
            final responseData = json.decode(responseString);
            final imagePath = responseData['path'] ?? responseData['data']?['path'];
            
            if (imagePath != null && imagePath.toString().isNotEmpty) {
              imagePaths.add(imagePath.toString());
              ApiLogger.logRequest(method, '✅ Файл ${i + 1} загружен: $imagePath');
            } else {
              throw ApiException('Не удалось получить путь к загруженному изображению');
            }
          } else if (streamedResponse.statusCode == 401) {
            throw UnauthorizedException('Сессия истекла. Пожалуйста, войдите снова.');
          } else if (streamedResponse.statusCode == 422) {
            final errorData = json.decode(responseString);
            throw ValidationException(
              errorData['errors'] ?? {},
              'Ошибка валидации изображения',
            );
          } else if (streamedResponse.statusCode == 413) {
            throw ApiException('Файл слишком большой. Максимальный размер: 2MB');
          } else if (streamedResponse.statusCode == 415) {
            throw ApiException(
              'Неподдерживаемый формат изображения. Используйте JPEG, PNG или WEBP',
            );
          } else {
            throw ApiException('Ошибка загрузки изображения: ${streamedResponse.statusCode}');
          }
        } catch (e) {
          ApiLogger.logError(e);
          rethrow;
        }
      }

      ApiLogger.logRequest(method, '✅ Все ${imagePaths.length} файлов успешно загружены');
      return imagePaths;
      
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
}