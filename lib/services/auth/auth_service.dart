// lib/services/auth/auth_service.dart (дополненный)
import 'package:goodjob/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token'; // Добавляем
  static const String _tokenExpiryKey = 'token_expiry'; // Добавляем
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  // lib/services/auth/auth_service.dart - исправленный isLoggedIn
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null || token.isEmpty) return false;

      final expiry = prefs.getInt(_tokenExpiryKey);
      if (expiry != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now >= expiry) {
          // Токен истек, пробуем обновить
          return await refreshTokenIfNeeded();
        }
      }

      // Проверяем, что токен действительно рабочий (опционально)
      // Можно сделать легкий запрос к API для проверки
      return true;
    } catch (e) {
      return false;
    }
  }

  // lib/services/auth/auth_service.dart - исправленный refreshTokenIfNeeded
  static Future<bool> refreshTokenIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      // У вас сейчас требуется refreshToken, но API его не возвращает
      // Нужно пробовать обновить только с access_token
      if (token == null) return false;

      // Пытаемся обновить токен
      final response = await ApiService.refreshToken(token: token);

      if (response != null && response['access_token'] != null) {
        await saveToken(response['access_token']);

        if (response['ttl'] != null) {
          await saveTokenExpiry(response['ttl']);
        }

        // Если API вернет refresh_token в будущем
        if (response['refresh_token'] != null) {
          await saveRefreshToken(response['refresh_token']);
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Ошибка обновления токена: $e');
      return false;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Ошибка сохранения токена: $e');
    }
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, refreshToken);
    } catch (e) {
      print('Ошибка сохранения refresh токена: $e');
    }
  }

  static Future<void> saveTokenExpiry(int ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(_tokenExpiryKey, now + ttl);
    } catch (e) {
      print('Ошибка сохранения expiry: $e');
    }
  }

  static Future<void> saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
    } catch (e) {
      print('Ошибка сохранения роли: $e');
    }
  }

  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      print('Ошибка получения роли: $e');
      return null;
    }
  }

  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      print('Ошибка очистки данных: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getCurrentUserId() async {
    try {
      final profile = await ApiService.getProfile();
      if (profile['data'] != null) {
        final userId = profile['data']['id']?.toString();
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userIdKey, userId);
        }
        return userId;
      }
      return null;
    } catch (e) {
      print('Ошибка получения ID пользователя: $e');
      return null;
    }
  }

  static Future<String?> getStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Метод для проверки валидности токена
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getInt(_tokenExpiryKey);

      if (expiry == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now < expiry;
    } catch (e) {
      return false;
    }
  }
}
