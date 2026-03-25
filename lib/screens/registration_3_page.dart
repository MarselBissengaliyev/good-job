import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:goodjob/screens/login_page.dart';
import 'package:goodjob/screens/offer_page.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Добавить импорт
import 'package:provider/provider.dart';

import '../models/city.dart';
import '../role_provider.dart';
import '../services/api_service.dart';
import 'registration_4_page.dart';

class Registration3Page extends StatefulWidget {
  const Registration3Page({super.key});

  @override
  State<Registration3Page> createState() => _Registration3PageState();
}

class _Registration3PageState extends State<Registration3Page> {
  int? selectedCityId;
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  // Форматтер маски для телефона
  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  bool _loadingCities = false;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;

  // Список городов из API
  List<City> _cities = [];

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _surnameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  // Для управления прокруткой
  final ScrollController _scrollController = ScrollController();

  // Функция для очистки номера телефона от всех символов кроме цифр
  String _getCleanPhoneNumber(String maskedNumber) {
    // Удаляем все нецифровые символы
    String cleanNumber = maskedNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Если номер начинается с 8 (российский формат), заменяем на 7
    if (cleanNumber.startsWith('8') && cleanNumber.length == 11) {
      cleanNumber = '7${cleanNumber.substring(1)}';
    }

    // Добавляем + в начало, если его нет
    if (!cleanNumber.startsWith('7')) {
      cleanNumber = '7$cleanNumber';
    }

    return '+$cleanNumber';
  }

  bool get isFormValid {
    // Проверяем, что все поля заполнены и телефон содержит достаточно цифр
    String cleanPhone = _getCleanPhoneNumber(phoneController.text);
    return nameController.text.isNotEmpty &&
        surnameController.text.isNotEmpty &&
        cleanPhone.length >= 12 && // +7 и 10 цифр = 12 символов
        selectedCityId != null;
  }

  @override
  void initState() {
    super.initState();
    // Загружаем города при инициализации
    _loadCities();

    // Добавляем слушатели фокуса для автоматической прокрутки
    _nameFocusNode.addListener(_handleFocusChange);
    _surnameFocusNode.addListener(_handleFocusChange);
    _phoneFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _surnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_nameFocusNode.hasFocus ||
        _surnameFocusNode.hasFocus ||
        _phoneFocusNode.hasFocus) {
      // Небольшая задержка, чтобы клавиатура успела появиться
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _loadCities() async {
    if (_loadingCities) return;

    setState(() {
      _loadingCities = true;
    });

    try {
      print('[DEBUG] Загрузка списка городов из API...');
      final citiesData = await ApiService.getCities();

      // Преобразуем данные в список City
      final List<City> cities = citiesData
          .map<City>((cityJson) => City.fromJson(cityJson))
          .toList();

      print('[DEBUG] Загружено ${cities.length} городов');

      if (mounted) {
        setState(() {
          _cities = cities;
          _loadingCities = false;
        });
      }
    } catch (e) {
      print('[ERROR] Ошибка при загрузке городов: $e');

      if (mounted) {
        setState(() {
          _loadingCities = false;
          _errorMessage =
              'Не удалось загрузить список городов. Проверьте подключение к интернету.';
          _cities = []; // Очищаем список в случае ошибки
        });
      }
    }
  }

  // Метод для извлечения сообщений об ошибках из ответа API
  String _extractErrorMessage(dynamic error) {
    try {
      print('[DEBUG] Обработка ошибки: $error');

      if (error is String) {
        // Пробуем распарсить JSON ошибки
        if (error.contains('{') && error.contains('}')) {
          try {
            final errorJson = json.decode(error);
            return _parseApiError(errorJson);
          } catch (e) {
            print('[DEBUG] Не удалось распарсить как JSON: $e');
            return error;
          }
        }
        return error;
      } else if (error is Map<String, dynamic>) {
        return _parseApiError(error);
      } else if (error is Exception) {
        return error.toString().replaceAll('Exception: ', '');
      }

      return error.toString();
    } catch (e) {
      print('[ERROR] Ошибка при обработке сообщения об ошибке: $e');
      return 'Произошла неизвестная ошибка';
    }
  }

  String _parseApiError(Map<String, dynamic> errorJson) {
    try {
      print('[DEBUG] Парсинг ошибки API: $errorJson');

      // Проверяем, есть ли raw_response с оригинальным ответом API
      if (errorJson.containsKey('raw_response')) {
        try {
          final rawResponse = errorJson['raw_response'];
          if (rawResponse is String && rawResponse.isNotEmpty) {
            final parsedResponse = json.decode(rawResponse);
            if (parsedResponse is Map<String, dynamic>) {
              print('[DEBUG] Распарсенный raw_response: $parsedResponse');
              // Рекурсивно обрабатываем распарсенный ответ
              return _parseApiError(parsedResponse);
            }
          }
        } catch (e) {
          print('[DEBUG] Ошибка парсинга raw_response: $e');
        }
      }

      // Извлекаем основное сообщение
      String mainMessage = errorJson['message']?.toString() ?? '';

      // Переводим системные сообщения на русский
      if (mainMessage.contains('validation.phone')) {
        mainMessage = 'Ошибка валидации номера телефона';
      } else if (mainMessage.contains('validation.')) {
        mainMessage = 'Ошибка валидации данных';
      } else if (mainMessage.contains('Failed to register: 422')) {
        mainMessage = 'Ошибка при регистрации (422)';
      } else if (mainMessage.contains('Failed to register')) {
        mainMessage = 'Ошибка при регистрации';
      }

      // Извлекаем ошибки полей
      if (errorJson['errors'] != null && errorJson['errors'] is Map) {
        final errors = errorJson['errors'] as Map<String, dynamic>;
        _fieldErrors = {};

        // Собираем ошибки для каждого поля
        for (var entry in errors.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            String errorText = (entry.value as List).first.toString();

            // Переводим ошибки полей на русский
            if (errorText.contains('validation.phone')) {
              errorText = 'Некорректный номер телефона';
            } else if (errorText.contains('validation.required')) {
              errorText = 'Это поле обязательно для заполнения';
            } else if (errorText.contains('validation.')) {
              errorText = 'Некорректное значение';
            }

            _fieldErrors![entry.key] = errorText;
          }
        }

        // Формируем детальное сообщение
        if (_fieldErrors != null && _fieldErrors!.isNotEmpty) {
          final fieldMessages = _fieldErrors!.entries
              .map((e) {
                String fieldName;
                String errorText = e.value;

                switch (e.key) {
                  case 'firstname':
                    fieldName = 'Имя';
                    break;
                  case 'lastname':
                    fieldName = 'Фамилия';
                    break;
                  case 'city_id':
                    fieldName = 'Город';
                    break;
                  case 'active_mode':
                    fieldName = 'Режим работы';
                    break;
                  case 'telephone':
                    fieldName = 'Телефон';
                    // Дополнительная информация для телефона
                    if (errorText.contains('Некорректный номер')) {
                      errorText +=
                          '\nПример правильного формата: +7 (777) 123-45-67';
                    }
                    break;
                  default:
                    fieldName = e.key;
                }
                return '• $fieldName: $errorText';
              })
              .join('\n');

          return '${mainMessage.isNotEmpty ? "$mainMessage\n\n" : ""}$fieldMessages';
        }
      }

      // Если нет детальных ошибок, возвращаем основное сообщение
      if (mainMessage.isEmpty) {
        // Пробуем найти другие ключи с сообщениями
        for (var key in ['error', 'Error', 'message', 'Message']) {
          if (errorJson.containsKey(key)) {
            mainMessage = errorJson[key].toString();
            break;
          }
        }
      }

      return mainMessage.isNotEmpty ? mainMessage : 'Ошибка при регистрации';
    } catch (e) {
      print('[ERROR] Ошибка парсинга API ошибки: $e');
      return 'Ошибка обработки ответа сервера';
    }
  }

  // Получить сообщение об ошибке для конкретного поля
  String? _getFieldError(String fieldName) {
    if (_fieldErrors == null) return null;

    // Маппинг русских названий полей на английские (как в API)
    String apiFieldName;
    switch (fieldName) {
      case 'Имя':
        apiFieldName = 'firstname';
        break;
      case 'Фамилия':
        apiFieldName = 'lastname';
        break;
      case 'Город':
        apiFieldName = 'city_id';
        break;
      case 'Телефон':
        apiFieldName = 'telephone';
        break;
      default:
        apiFieldName = fieldName.toLowerCase();
    }

    return _fieldErrors![apiFieldName];
  }

  Future<void> _registerUser(BuildContext context) async {
    if (!isFormValid) {
      setState(() {
        _errorMessage = 'Заполните все обязательные поля корректно';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = null;
    });

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);

      // Получаем очищенный номер телефона
      String phoneNumber = _getCleanPhoneNumber(phoneController.text);
      print('[DEBUG] Исходный номер телефона: ${phoneController.text}');
      print('[DEBUG] Очищенный номер телефона: $phoneNumber');

      // Регистрируем пользователя
      print('[DEBUG] Начинаем регистрацию пользователя...');
      print('[DEBUG] Данные для регистрации:');
      print('[DEBUG] - Имя: ${nameController.text.trim()}');
      print('[DEBUG] - Фамилия: ${surnameController.text.trim()}');
      print('[DEBUG] - Телефон: $phoneNumber');
      print('[DEBUG] - City ID: $selectedCityId');
      print(
        '[DEBUG] - Режим: ${roleProvider.selectedRole == 'Мастер' ? 'master' : 'client'}',
      );

      // Получаем данные формы
      final firstname = nameController.text.trim();
      final lastname = surnameController.text.trim();

      // Проверяем, что поля не пустые
      if (firstname.isEmpty || lastname.isEmpty || selectedCityId == null) {
        throw Exception('Все поля обязательны для заполнения');
      }

      // 1. Регистрация пользователя
      print('[DEBUG] Вызываем ApiService.registerUser...');
      final registerResponse = await ApiService.registerUser(
        firstname: firstname,
        lastname: lastname,
        telephone: phoneNumber, // Используем очищенный номер
        cityId: selectedCityId!,
        activeMode: roleProvider.selectedRole == UserRole.master
            ? 'master'
            : 'client',
      );

      int ttl = 60;
      if (registerResponse is Map<String, dynamic> &&
          registerResponse.containsKey('codeTtl')) {
        ttl = registerResponse['codeTtl'];
      }

      print('[DEBUG] Регистрация успешна. Ответ: $registerResponse');
      print('[DEBUG] Пользователь успешно зарегистрирован');

      print(
        '[DEBUG] Переход на страницу подтверждения кода: Registration4Page',
      );

      // Переходим на страницу подтверждения
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Registration4Page(
            phoneNumber: phoneNumber, // Передаем очищенный номер
            codeTtl: ttl, // Передаем полученное время
          ),
        ),
      );

      print('[DEBUG] Навигация выполнена');
    } catch (e) {
      print('[ERROR] Произошла ошибка при регистрации:');
      print('[ERROR] Тип ошибки: ${e.runtimeType}');
      print('[ERROR] Полный объект ошибки: $e');
      print('[ERROR] Stack trace: ${StackTrace.current}');

      // Обрабатываем ошибку
      final errorMessage = _extractErrorMessage(e);

      // Проверяем mounted перед setState
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      } else {
        print(
          '[WARNING] Widget не mounted, не могу обновить состояние с ошибкой',
        );
      }
    } finally {
      print('[DEBUG] Завершение процесса регистрации');

      // Проверяем mounted перед setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      } else {
        print(
          '[WARNING] Widget не mounted, не могу обновить состояние загрузки',
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Верхняя панель с логотипом
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new),
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Image.asset('assets/logo.png', height: 28),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),

                      // Основной контент формы
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Регистрация',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  roleProvider.isMasterSelected
                                      ? 'Регистрация для мастера'
                                      : 'Регистрация для клиента',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Поле имени
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      focusNode: _nameFocusNode,
                                      onChanged: (_) {
                                        setState(() {
                                          // Очищаем ошибку поля при изменении
                                          if (_fieldErrors != null) {
                                            _fieldErrors!.remove('firstname');
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Имя',
                                        labelStyle: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Colors.grey,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 16,
                                      ),
                                    ),
                                    _buildFieldError('Имя'),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Поле фамилии
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: surnameController,
                                      focusNode: _surnameFocusNode,
                                      onChanged: (_) {
                                        setState(() {
                                          if (_fieldErrors != null) {
                                            _fieldErrors!.remove('lastname');
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Фамилия',
                                        labelStyle: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Colors.grey,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 16,
                                      ),
                                    ),
                                    _buildFieldError('Фамилия'),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Выбор города
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_loadingCities)
                                      // Показать индикатор загрузки
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 8),
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Text(
                                              'Загрузка городов...',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_cities.isEmpty)
                                      // Показать сообщение об ошибке
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Не удалось загрузить города',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: _loadCities,
                                              child: const Text(
                                                'Попробовать снова',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  color: Colors.blue,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      // Показать нормальный выпадающий список
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                _getFieldError('Город') != null
                                                ? Colors.red
                                                : Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButtonFormField<int>(
                                            value: selectedCityId,
                                            onChanged: (value) {
                                              print(
                                                '[DEBUG] Выбран город с ID: $value',
                                              );
                                              setState(() {
                                                selectedCityId = value;
                                                if (_fieldErrors != null) {
                                                  _fieldErrors!.remove(
                                                    'city_id',
                                                  );
                                                }
                                              });
                                            },
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: 'Город',
                                              labelStyle: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color:
                                                    _getFieldError('Город') !=
                                                        null
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16,
                                                  ),
                                              suffixIcon: const Icon(
                                                Icons.arrow_drop_down,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                            icon: const SizedBox.shrink(),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            // Добавляем placeholder текст
                                            hint: selectedCityId == null
                                                ? const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8.0,
                                                        ),
                                                    child: Text(
                                                      'Выберите город',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                            items: _cities.map((city) {
                                              return DropdownMenuItem<int>(
                                                value: city.id,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                      ),
                                                  child: Text(
                                                    city.name,
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'Plus Jakarta Sans',
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    _buildFieldError('Город'),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Поле телефона с маской
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: phoneController,
                                      focusNode: _phoneFocusNode,
                                      inputFormatters: [
                                        maskFormatter,
                                      ], // Применяем маску
                                      onChanged: (_) {
                                        setState(() {
                                          if (_fieldErrors != null) {
                                            _fieldErrors!.remove('telephone');
                                          }
                                        });
                                      },
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: 'Телефон',
                                        labelStyle: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Colors.grey,
                                        ),
                                        hintText: '+7 (___) ___-__-__',
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        helperStyle: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        suffixIcon:
                                            phoneController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Color(0xFF9AA0A6),
                                                ),
                                                onPressed: () => setState(
                                                  () => phoneController.clear(),
                                                ),
                                              )
                                            : null,
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // Подсказка о формате номера
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: Color(0xFF9AA0A6),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Введите номер в формате: +7 (777) 777-77-77',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  _getFieldError('Телефон') !=
                                                      null
                                                  ? Colors.red
                                                  : const Color(0xFF9AA0A6),
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildFieldError('Телефон'),
                                  ],
                                ),

                                // Общая ошибка
                                if (_errorMessage != null &&
                                    (_fieldErrors == null ||
                                        _fieldErrors!.isEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
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

                                // Соглашение
                                const Text(
                                  'Создавая аккаунт, вы принимаете',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    print('[DEBUG] Открытие договора офферты');
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OfferPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Договор публичной офферты',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Фиксированная область с кнопками
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Кнопка регистрации
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isFormValid && !_isLoading
                                    ? () => _registerUser(context)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFormValid && !_isLoading
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
                                        'Получить код подтверждения',
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

                            // Кнопка входа
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(),
                                          ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF0F7EDE),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Войти',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Color(0xFF0F7EDE),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
