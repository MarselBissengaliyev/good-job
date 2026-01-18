import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'registration_4_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _phoneHasError = false;
  Map<String, dynamic>? _fieldErrors;

  // Получить сообщение об ошибке для конкретного поля
  String? _getFieldError(String fieldName) {
    if (_fieldErrors == null) return null;

    // Маппинг русских названий полей на английские (как в API)
    String apiFieldName;
    switch (fieldName) {
      case 'Телефон':
        apiFieldName = 'telephone';
        break;
      default:
        apiFieldName = fieldName.toLowerCase();
    }

    return _fieldErrors![apiFieldName];
  }

  // Виджет для отображения ошибки поля
  Widget _buildFieldError(String fieldName) {
    final error = _getFieldError(fieldName);
    if (error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите номер телефона';
        _phoneHasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = null;
      _phoneHasError = false;
    });

    try {
      print('[DEBUG] Начало процесса входа...');
      print('[DEBUG] Телефон: ${_phoneController.text}');

      // 1. Отправляем запрос на вход (получение кода)
      final response = await ApiService.login(
        telephone: _phoneController.text,
      );

      print('[DEBUG] Ответ от API логина: $response');

      // Извлекаем TTL кода из ответа
      int codeTtl = 60; // значение по умолчанию
      if (response is Map<String, dynamic>) {
        if (response.containsKey('code_ttl')) {
          codeTtl = response['code_ttl'] as int;
        }
      }

      print('[DEBUG] TTL кода: $codeTtl секунд');

      // Переходим на страницу подтверждения кода
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Registration4Page(
            phoneNumber: _phoneController.text,
            codeTtl: codeTtl,
          ),
        ),
      );

      print('[DEBUG] Переход на страницу подтверждения кода выполнен');

    } catch (e) {
      print('[ERROR] Ошибка при входе: $e');

      // Обрабатываем ошибку API
      String errorMessage = 'Ошибка при входе';

      if (e is Map<String, dynamic>) {
        // Если это ошибка валидации от API
        if (e['errors'] != null) {
          final errors = e['errors'] as Map<String, dynamic>;
          _fieldErrors = {};

          for (var entry in errors.entries) {
            if (entry.value is List && (entry.value as List).isNotEmpty) {
              String errorText = (entry.value as List).first.toString();

              // Переводим ошибки на русский
              if (errorText.contains('validation.phone')) {
                errorText = 'Некорректный номер телефона';
              } else if (errorText.contains('validation.required')) {
                errorText = 'Это поле обязательно для заполнения';
              } else if (errorText.contains('User not found')) {
                errorText = 'Пользователь не найден';
              }

              _fieldErrors![entry.key] = errorText;
            }
          }

          // Формируем сообщение об ошибке
          if (_fieldErrors!.isNotEmpty) {
            errorMessage = _fieldErrors!.values.join('\n');
          }
        } else if (e['message'] != null) {
          errorMessage = e['message'].toString();
        }
      } else if (e is String) {
        if (e.contains('User not found')) {
          errorMessage = 'Пользователь не найден';
        } else {
          errorMessage = e;
        }
      }

      setState(() {
        _errorMessage = errorMessage;
        _phoneHasError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Image.asset('assets/logo.png', height: 28),
                  const Spacer(flex: 2),
                ],
              ),
            ),

            // Форма входа
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Вход',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'Введите номер телефона, чтобы войти',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Поле телефона
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _phoneController,
                            onChanged: (_) {
                              setState(() {
                                _phoneHasError = false;
                                if (_fieldErrors != null) {
                                  _fieldErrors!.remove('telephone');
                                }
                                _errorMessage = null;
                              });
                            },
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Телефон',
                              labelStyle: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: _phoneHasError
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              helperStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildFieldError('Телефон'),
                        ],
                      ),

                      // Общая ошибка
                      if (_errorMessage != null &&
                          (_fieldErrors == null || _fieldErrors!.isEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Ошибка',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Кнопка входа
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _login(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _phoneController.text.isNotEmpty &&
                                    !_isLoading
                                ? const Color(0xFF0F7EDE)
                                : const Color(0xFFBABABA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Войти',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'или',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Кнопка регистрации
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  print('[DEBUG] Переход к регистрации');
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistrationPage(),
                                    ),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0F7EDE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Зарегистрироваться',
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF0F7EDE),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}