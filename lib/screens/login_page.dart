import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'registration_4_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _phoneHasError = false;
  Map<String, dynamic>? _fieldErrors;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Создаем форматтер маски для телефона
  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Получить сообщение об ошибке для конкретного поля
  String? _getFieldError(String fieldName, AppLocalizations appLocalizations) {
    if (_fieldErrors == null) return null;

    String apiFieldName;
    switch (fieldName) {
      case 'Телефон':
        apiFieldName = 'telephone';
        break;
      default:
        apiFieldName = fieldName.toLowerCase();
    }

    final error = _fieldErrors![apiFieldName];
    if (error == null) return null;

    // Переводим ошибки на текущий язык
    if (error.contains('validation.phone') || error.contains('Некорректный')) {
      return appLocalizations.translate('invalid_phone');
    } else if (error.contains('validation.required')) {
      return appLocalizations.translate('field_required');
    } else if (error.contains('User not found') || error.contains('не найден')) {
      return appLocalizations.translate('user_not_found');
    }
    
    return error;
  }

  // Виджет для отображения ошибки поля
  Widget _buildFieldError(String fieldName, AppLocalizations appLocalizations) {
    final error = _getFieldError(fieldName, appLocalizations);
    if (error == null) return const SizedBox.shrink();

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
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
      ),
    );
  }

  // Функция для очистки номера телефона от всех символов кроме цифр
  String _getCleanPhoneNumber() {
    String maskedNumber = _phoneController.text;
    String cleanNumber = maskedNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.startsWith('8') && cleanNumber.length == 11) {
      cleanNumber = '7${cleanNumber.substring(1)}';
    }

    if (!cleanNumber.startsWith('7')) {
      cleanNumber = '7$cleanNumber';
    }

    return '+$cleanNumber';
  }

  Future<void> _login() async {
    final appLocalizations = AppLocalizations.of(context)!;
    String cleanPhone = _getCleanPhoneNumber();

    if (cleanPhone.length < 12) {
      setState(() {
        _errorMessage = appLocalizations.translate('enter_valid_phone');
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
      final response = await ApiService.login(telephone: cleanPhone);

      int codeTtl = 60;
      if (response is Map<String, dynamic>) {
        if (response.containsKey('code_ttl')) {
          codeTtl = response['code_ttl'] as int;
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Registration4Page(
              phoneNumber: cleanPhone,
              codeTtl: codeTtl,
            ),
          ),
        );
      }
    } catch (e) {
      String errorMessage = appLocalizations.translate('login_error');

      if (e is Map<String, dynamic>) {
        if (e['errors'] != null) {
          final errors = e['errors'] as Map<String, dynamic>;
          _fieldErrors = {};

          for (var entry in errors.entries) {
            if (entry.value is List && (entry.value as List).isNotEmpty) {
              String errorText = (entry.value as List).first.toString();
              
              if (errorText.contains('validation.phone')) {
                errorText = appLocalizations.translate('invalid_phone');
              } else if (errorText.contains('validation.required')) {
                errorText = appLocalizations.translate('field_required');
              } else if (errorText.contains('User not found')) {
                errorText = appLocalizations.translate('user_not_found');
              }

              _fieldErrors![entry.key] = errorText;
            }
          }

          if (_fieldErrors!.isNotEmpty) {
            errorMessage = _fieldErrors!.values.join('\n');
          }
        } else if (e['message'] != null) {
          errorMessage = e['message'].toString();
        }
      } else if (e is String) {
        if (e.contains('User not found')) {
          errorMessage = appLocalizations.translate('user_not_found');
        } else {
          errorMessage = e;
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _phoneHasError = true;
        });
        
        // Показываем SnackBar для ошибок
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
    final appLocalizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Иконка с телефоном
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.phone_android,
                            size: 48,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        Text(
                          appLocalizations.translate('login'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          appLocalizations.translate('enter_phone_to_login'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Поле телефона с маской
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _phoneController,
                              inputFormatters: [maskFormatter],
                              enabled: !_isLoading,
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
                                labelText: appLocalizations.translate('phone'),
                                labelStyle: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: _phoneHasError ? Colors.red : Colors.grey,
                                ),
                                hintText: '+7 (___) ___-__-__',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: _phoneHasError ? Colors.red : Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildFieldError('Телефон', appLocalizations),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Кнопка входа
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _getCleanPhoneNumber().length < 12)
                                ? null
                                : () => _login(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    appLocalizations.translate('login'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Разделитель "или"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                appLocalizations.translate('or'),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),

                        // Кнопка регистрации
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegistrationPage(),
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.blue.shade700),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              appLocalizations.translate('register'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Plus Jakarta Sans',
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Подсказка
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appLocalizations.translate('login_hint'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}