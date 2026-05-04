// lib/services/auth/auth_service.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:goodjob/services/api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenExpiryKey = 'refreshToken_expiry';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  static Future<void> saveUserId(String userId) async {
    await _write(_userIdKey, userId);
  }

  // Используем secure storage только для мобильных платформ
  static final FlutterSecureStorage? _secureStorage = !kIsWeb
      ? FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        )
      : null;

  // Для Web используем localStorage
  static void _saveToLocalStorage(String key, String value) {
    if (kIsWeb) {
      html.window.localStorage[key] = value;
      print('💾 Web: Saved $key to localStorage');
    }
  }

  static String? _getFromLocalStorage(String key) {
    if (kIsWeb) {
      return html.window.localStorage[key];
    }
    return null;
  }

  static void _removeFromLocalStorage(String key) {
    if (kIsWeb) {
      html.window.localStorage.remove(key);
      print('🗑️ Web: Removed $key from localStorage');
    }
  }

  // Универсальный метод записи
  static Future<void> _write(String key, String value) async {
    try {
      if (kIsWeb) {
        _saveToLocalStorage(key, value);
      } else {
        await _secureStorage?.write(key: key, value: value);
      }
      print('✅ Saved $key successfully');
    } catch (e) {
      print('❌ Error saving $key: $e');
      // Fallback для Web если localStorage не работает
      if (kIsWeb) {
        try {
          html.window.sessionStorage[key] = value;
          print('💾 Fallback: Saved $key to sessionStorage');
        } catch (e2) {
          print('❌ Fallback also failed: $e2');
        }
      }
    }
  }

  // Универсальный метод чтения
  static Future<String?> _read(String key) async {
    try {
      if (kIsWeb) {
        return _getFromLocalStorage(key);
      } else {
        return await _secureStorage?.read(key: key);
      }
    } catch (e) {
      print('❌ Error reading $key: $e');
      return null;
    }
  }

  // Универсальный метод удаления
  static Future<void> _delete(String key) async {
    try {
      if (kIsWeb) {
        _removeFromLocalStorage(key);
      } else {
        await _secureStorage?.delete(key: key);
      }
      print('✅ Deleted $key successfully');
    } catch (e) {
      print('❌ Error deleting $key: $e');
    }
  }

  // Проверка авторизации с обновлением токена
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _read(_tokenKey);
      final refreshToken = await _read(_refreshTokenKey);

      print('🔍 Checking login: token=$token, refreshToken=$refreshToken');

      if (token == null || token.isEmpty) return false;
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final expiryStr = await _read(_tokenExpiryKey);
      if (expiryStr != null) {
        final expiry = int.tryParse(expiryStr);
        if (expiry != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (now >= expiry) {
            print('⏰ Token expired, refreshing...');
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
      final refreshToken = await _read(_refreshTokenKey);

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
    await _write(_tokenKey, token);
  }

  // Сохранение refresh токена
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _write(_refreshTokenKey, refreshToken);
  }

  // Сохранение времени жизни access токена
  static Future<void> saveTokenExpiry(int ttlSeconds) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _write(_tokenExpiryKey, (now + ttlSeconds).toString());
    } catch (e) {
      print('Ошибка сохранения expiry: $e');
    }
  }

  // Сохранение времени жизни refresh токена
  static Future<void> saveRefreshTokenExpiry(int ttlSeconds) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _write(_refreshTokenExpiryKey, (now + ttlSeconds).toString());
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
    print('💾 Saving token pair...');
    await saveToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveTokenExpiry(ttl);
    await saveRefreshTokenExpiry(refreshTtl);
    await debugPrintStoredData(); // Проверяем что сохранилось
  }

  static Future<void> debugPrintStoredData() async {
    print('=== DEBUG AUTH DATA ===');
    final token = await _read(_tokenKey);
    final refreshToken = await _read(_refreshTokenKey);
    final tokenExpiry = await _read(_tokenExpiryKey);
    final refreshExpiry = await _read(_refreshTokenExpiryKey);
    final userRole = await _read(_userRoleKey);
    final userId = await _read(_userIdKey);

    print(
      'Token: ${token != null ? '${token.substring(0, min(20, token.length))}...' : 'null'}',
    );
    print(
      'Refresh Token: ${refreshToken != null ? '${refreshToken.substring(0, min(20, refreshToken.length))}...' : 'null'}',
    );
    print('Token Expiry: $tokenExpiry');
    print('Refresh Expiry: $refreshExpiry');
    print('User Role: $userRole');
    print('User ID: $userId');

    print('======================');
  }

  // Добавьте вспомогательную функцию min если её нет
  static int min(int a, int b) => a < b ? a : b;

  // Сохранение роли пользователя
  static Future<void> saveUserRole(String role) async {
    await _write(_userRoleKey, role);
  }

  // Получение роли пользователя
  static Future<String?> getUserRole() async {
    return await _read(_userRoleKey);
  }

  // Очистка всех данных авторизации
  static Future<void> clearAuthData() async {
    await _delete(_tokenKey);
    await _delete(_refreshTokenKey);
    await _delete(_tokenExpiryKey);
    await _delete(_refreshTokenExpiryKey);
    await _delete(_userRoleKey);
    await _delete(_userIdKey);
    print('✅ Данные авторизации очищены');
  }

  // Получение access токена
  static Future<String?> getToken() async {
    return await _read(_tokenKey);
  }

  // Получение refresh токена
  static Future<String?> getRefreshToken() async {
    return await _read(_refreshTokenKey);
  }

  // Получение ID пользователя из профиля
  static Future<String?> getCurrentUserId() async {
    try {
      final profile = await ApiService.getProfile();
      if (profile['data'] != null) {
        final userId = profile['data']['id']?.toString();
        if (userId != null) {
          await _write(_userIdKey, userId);
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
    return await _read(_userIdKey);
  }

  // Проверка валидности access токена
  static Future<bool> isTokenValid() async {
    try {
      final expiryStr = await _read(_tokenExpiryKey);
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
      final expiryStr = await _read(_refreshTokenExpiryKey);
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
      final expiryStr = await _read(_tokenExpiryKey);
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
