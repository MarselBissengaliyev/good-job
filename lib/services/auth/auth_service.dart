// lib/services/auth/auth_service.dart
import 'package:goodjob/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenExpiryKey = 'refreshToken_expiry';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  // Проверка авторизации с обновлением токена
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (token == null || token.isEmpty) return false;
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final expiry = prefs.getInt(_tokenExpiryKey);
      if (expiry != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now >= expiry) {
          // Токен истек, пробуем обновить
          return await refreshTokenPair();
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
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Вызываем API для обновления токенов
      final response = await ApiService.refreshToken(refreshToken: refreshToken);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Ошибка сохранения токена: $e');
    }
  }

  // Сохранение refresh токена
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, refreshToken);
    } catch (e) {
      print('Ошибка сохранения refresh токена: $e');
    }
  }

  // Сохранение времени жизни access токена
  static Future<void> saveTokenExpiry(int ttlSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(_tokenExpiryKey, now + ttlSeconds);
    } catch (e) {
      print('Ошибка сохранения expiry: $e');
    }
  }

  // Сохранение времени жизни refresh токена
  static Future<void> saveRefreshTokenExpiry(int ttlSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(_refreshTokenExpiryKey, now + ttlSeconds);
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

  // Сохранение роли пользователя
  static Future<void> saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
    } catch (e) {
      print('Ошибка сохранения роли: $e');
    }
  }

  // Получение роли пользователя
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      print('Ошибка получения роли: $e');
      return null;
    }
  }

  // Очистка всех данных авторизации
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_refreshTokenExpiryKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userIdKey);
      print('✅ Данные авторизации очищены');
    } catch (e) {
      print('Ошибка очистки данных: $e');
    }
  }

  // Получение access токена
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Получение refresh токена
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
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

  // Получение сохраненного ID пользователя
  static Future<String?> getStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Проверка валидности access токена
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

  // Проверка валидности refresh токена
  static Future<bool> isRefreshTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getInt(_refreshTokenExpiryKey);

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
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getInt(_tokenExpiryKey);
      
      if (expiry == null) return null;
      
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = expiry - now;
      
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return null;
    }
  }
}