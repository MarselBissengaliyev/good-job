// lib/services/auth/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:goodjob/services/api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenExpiryKey = 'refreshToken_expiry';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  // Используем secure storage для токенов
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Включаем шифрование на Android
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Для обычных данных (не токенов) можно оставить SharedPreferences
  // Но для единообразия лучше все хранить в secure storage

  // Проверка авторизации с обновлением токена
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (token == null || token.isEmpty) return false;
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        final expiry = int.tryParse(expiryStr);
        if (expiry != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (now >= expiry) {
            // Токен истек, пробуем обновить
            return await refreshTokenPair();
          }
        }
      }

      return true;
    } catch (e) {
      print('Ошибка проверки авторизации: $e');
      return false;
    }
  }

  // Обновление пары токенов (ротация)
  static Future<bool> refreshTokenPair() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Вызываем API для обновления токенов
      final response = await ApiService.refreshToken(
        refreshToken: refreshToken,
      );

      if (response != null &&
          response['accessToken'] != null &&
          response['refreshToken'] != null) {
        // Сохраняем новые токены
        await saveToken(response['accessToken']);
        await saveRefreshToken(response['refreshToken']);

        // Сохраняем время жизни токенов
        if (response['ttl'] != null) {
          await saveTokenExpiry(response['ttl']);
        }
        if (response['refreshTtl'] != null) {
          await saveRefreshTokenExpiry(response['refreshTtl']);
        }

        print('✅ Токены успешно обновлены');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Ошибка обновления токенов: $e');
      // Если refresh токен тоже просрочен, очищаем все данные
      await clearAuthData();
      return false;
    }
  }

  // Сохранение access токена
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      print('Ошибка сохранения токена: $e');
    }
  }

  // Сохранение refresh токена
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      print('Ошибка сохранения refresh токена: $e');
    }
  }

  // Сохранение времени жизни access токена
  static Future<void> saveTokenExpiry(int ttlSeconds) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _secureStorage.write(
        key: _tokenExpiryKey,
        value: (now + ttlSeconds).toString(),
      );
    } catch (e) {
      print('Ошибка сохранения expiry: $e');
    }
  }

  // Сохранение времени жизни refresh токена
  static Future<void> saveRefreshTokenExpiry(int ttlSeconds) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _secureStorage.write(
        key: _refreshTokenExpiryKey,
        value: (now + ttlSeconds).toString(),
      );
    } catch (e) {
      print('Ошибка сохранения refresh expiry: $e');
    }
  }

  // Сохранение пары токенов после логина/регистрации
  static Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required int ttl,
    required int refreshTtl,
  }) async {
    await saveToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveTokenExpiry(ttl);
    await saveRefreshTokenExpiry(refreshTtl);
  }

  static Future<void> debugPrintStoredData() async {
    print('=== DEBUG AUTH DATA ===');
    print('Token: ${await _secureStorage.read(key: _tokenKey)}');
    print('Refresh Token: ${await _secureStorage.read(key: _refreshTokenKey)}');
    print('Token Expiry: ${await _secureStorage.read(key: _tokenExpiryKey)}');
    print(
      'Refresh Expiry: ${await _secureStorage.read(key: _refreshTokenExpiryKey)}',
    );
    print('User Role: ${await _secureStorage.read(key: _userRoleKey)}');
    print('User ID: ${await _secureStorage.read(key: _userIdKey)}');
    print('======================');
  }

  // Сохранение роли пользователя
  static Future<void> saveUserRole(String role) async {
    try {
      await _secureStorage.write(key: _userRoleKey, value: role);
    } catch (e) {
      print('Ошибка сохранения роли: $e');
    }
  }

  // Получение роли пользователя
  static Future<String?> getUserRole() async {
    try {
      return await _secureStorage.read(key: _userRoleKey);
    } catch (e) {
      print('Ошибка получения роли: $e');
      return null;
    }
  }

  // Очистка всех данных авторизации
  static Future<void> clearAuthData() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _refreshTokenExpiryKey);
      await _secureStorage.delete(key: _userRoleKey);
      await _secureStorage.delete(key: _userIdKey);
      print('✅ Данные авторизации очищены');
    } catch (e) {
      print('Ошибка очистки данных: $e');
    }
  }

  // Получение access токена
  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Получение refresh токена
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  // Получение ID пользователя из профиля
  static Future<String?> getCurrentUserId() async {
    try {
      final profile = await ApiService.getProfile();
      if (profile['data'] != null) {
        final userId = profile['data']['id']?.toString();
        if (userId != null) {
          await _secureStorage.write(key: _userIdKey, value: userId);
        }
        return userId;
      }
      return null;
    } catch (e) {
      print('Ошибка получения ID пользователя: $e');
      return null;
    }
  }

  // Получение сохраненного ID пользователя
  static Future<String?> getStoredUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Проверка валидности access токена
  static Future<bool> isTokenValid() async {
    try {
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return false;

      final expiry = int.tryParse(expiryStr);
      if (expiry == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now < expiry;
    } catch (e) {
      return false;
    }
  }

  // Проверка валидности refresh токена
  static Future<bool> isRefreshTokenValid() async {
    try {
      final expiryStr = await _secureStorage.read(key: _refreshTokenExpiryKey);
      if (expiryStr == null) return false;

      final expiry = int.tryParse(expiryStr);
      if (expiry == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now < expiry;
    } catch (e) {
      return false;
    }
  }

  // Получение времени до истечения access токена (в секундах)
  static Future<int?> getTokenTimeToLive() async {
    try {
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return null;

      final expiry = int.tryParse(expiryStr);
      if (expiry == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = expiry - now;

      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return null;
    }
  }
}
