import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Добавить импорт

class AddOrderClientPage extends StatefulWidget {
  const AddOrderClientPage({super.key});

  @override
  State<AddOrderClientPage> createState() => _AddOrderClientPageState();
}

class _AddOrderClientPageState extends State<AddOrderClientPage> {
  // Контроллеры для полей ввода
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Форматтер маски для телефона
  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _selectedCityId;

  // Переменные для выбора категории и города
  List<dynamic> _categories = [];
  List<dynamic> _cities = [];
  bool _isLoadingCategories = false;
  bool _isLoadingCities = false;

  // Переменные для хранения выбранных значений
  String? _selectedCategoryName;
  String? _selectedCityName;

  // Overlay для модалок
  OverlayEntry? _categoryOverlayEntry;
  OverlayEntry? _cityOverlayEntry;
  final LayerLink _categoryLayerLink = LayerLink();
  final LayerLink _cityLayerLink = LayerLink();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCities();

    // Устанавливаем цвет системной навигации
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _removeCategoryOverlay();
    _removeCityOverlay();

    // Возвращаем стандартные настройки при выходе
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      _showError('Ошибка загрузки категорий: $e');
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final cities = await ApiService.getCities();
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      _showError('Ошибка загрузки городов: $e');
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  // Управление overlay для категории
  void _toggleCategoryOverlay() {
    if (_categoryOverlayEntry != null) {
      _removeCategoryOverlay();
    } else {
      _removeCityOverlay();
      _showCategoryOverlay();
    }
  }

  void _showCategoryOverlay() {
    if (_isLoadingCategories || _categories.isEmpty) {
      if (_categories.isEmpty && !_isLoadingCategories) {
        _showError('Категории не загружены');
      }
      return;
    }

    final renderBox =
        _categoryKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _categoryOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width * 1.5,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Категория',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _removeCategoryOverlay,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Список категорий
                SizedBox(
                  height: (_categories.length * 44.0).clamp(100.0, 300.0),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final categoryId = category['id']?.toString();
                      final categoryName =
                          category['name']?.toString() ?? 'Без названия';
                      return _buildSelectableItem(
                        text: categoryName,
                        isSelected: _selectedCategoryId == categoryId,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = categoryId;
                            _selectedCategoryName = categoryName;
                          });
                          _removeCategoryOverlay();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_categoryOverlayEntry!);
  }

  void _removeCategoryOverlay() {
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
  }

  // Управление overlay для города
  void _toggleCityOverlay() {
    if (_cityOverlayEntry != null) {
      _removeCityOverlay();
    } else {
      _removeCategoryOverlay();
      _showCityOverlay();
    }
  }

  void _showCityOverlay() {
    if (_isLoadingCities || _cities.isEmpty) {
      if (_cities.isEmpty && !_isLoadingCities) {
        _showError('Города не загружены');
      }
      return;
    }

    final renderBox = _cityKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _cityOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width * 1.5,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Город',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _removeCityOverlay,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Список городов
                SizedBox(
                  height: (_cities.length * 44.0).clamp(100.0, 300.0),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      final cityId = city['id']?.toString();
                      final cityName =
                          city['name']?.toString() ?? 'Без названия';
                      return _buildSelectableItem(
                        text: cityName,
                        isSelected: _selectedCityId == cityId,
                        onTap: () {
                          setState(() {
                            _selectedCityId = cityId;
                            _selectedCityName = cityName;
                          });
                          _removeCityOverlay();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_cityOverlayEntry!);
  }

  void _removeCityOverlay() {
    _cityOverlayEntry?.remove();
    _cityOverlayEntry = null;
  }

  // Общий виджет для элементов выбора
  Widget _buildSelectableItem({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  left: BorderSide(color: Color(0xFF0F7EDE), width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F7EDE)
                      : const Color(0xFFCBCDCE),
                  width: 1.5,
                ),
                color: isSelected ? const Color(0xFF0F7EDE) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFF0F7EDE)
                      : const Color(0xFF41454A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();

      // Показываем компактный диалог выбора источника
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Добавить фото',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF41454A),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Кнопка галереи
                    _buildImageSourceButton(
                      icon: Icons.photo_library,
                      label: 'Галерея',
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickFromGallery();
                      },
                    ),

                    // Кнопка камеры
                    _buildImageSourceButton(
                      icon: Icons.camera_alt,
                      label: 'Камера',
                      onTap: () async {
                        Navigator.pop(context);
                        await _takePhoto();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _showError('Ошибка при выборе изображений: $e');
    }
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3F2FD)),
              ),
              child: Icon(icon, color: const Color(0xFF0F7EDE), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF41454A)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var pickedFile in pickedFiles) {
          if (_selectedImages.length < 10) {
            _selectedImages.add(File(pickedFile.path));
          } else {
            _showError('Максимум 10 изображений');
            break;
          }
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (_selectedImages.length < 10) {
          _selectedImages.add(File(pickedFile.path));
        } else {
          _showError('Максимум 10 изображений');
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createOrder() async {
    // Валидация основных полей
    if (_taskController.text.isEmpty || _taskController.text.length < 16) {
      _showError('Введите название задачи (минимум 16 символов)');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showError('Добавьте хотя бы одно изображение');
      return;
    }

    if (_descriptionController.text.isEmpty ||
        _descriptionController.text.length < 40) {
      _showError('Введите описание (минимум 40 символов)');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Выберите категорию');
      return;
    }

    if (_selectedCityId == null) {
      _showError('Выберите город');
      return;
    }

    if (_districtController.text.isEmpty) {
      _showError('Введите улицу/район');
      return;
    }

    // Валидация телефона
    String cleanPhone = _getCleanPhoneNumber(_phoneController.text);
    if (cleanPhone.length < 12) {
      // +7 и 10 цифр = 12 символов
      _showError('Введите корректный номер телефона');
      return;
    }

    // Валидация цены
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showError('Введите цену');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Введите корректную цену (больше 0)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Загружаем изображения
      List<String> uploadedImagePaths = [];
      if (_selectedImages.isNotEmpty) {
        uploadedImagePaths = await ApiService.uploadOrderImages(
          _selectedImages,
        );
      }

      String adressHouse = _houseController.text;
      if (adressHouse == "") {
        adressHouse = "-";
      }

      String adressApartment = _apartmentController.text;
      if (adressApartment == "") {
        adressApartment = "-";
      }

      // 2. Создаем заказ с очищенным номером телефона
      final result = await ApiService.createOrder(
        categoryId: int.parse(_selectedCategoryId!),
        cityId: int.parse(_selectedCityId!),
        title: _taskController.text,
        description: _descriptionController.text,
        addressStreet: _districtController.text,
        addressHouse: adressHouse,
        addressApartment: adressApartment,
        telephone: cleanPhone, // Отправляем очищенный номер
        price: price,
        images: uploadedImagePaths,
      );

      // 3. Показываем успешное сообщение
      _showSuccess('Заказ успешно создан!');

      // 4. Возвращаемся назад через 1 секунду
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Ошибка при создании заказа: $e');
      String errorMessage = 'Произошла ошибка';

      if (e is DioException) {
        final responseData = e.response?.data;

        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'];
          final errors = responseData['errors'];

          if (errors is Map<String, dynamic> && errors.isNotEmpty) {
            // Формируем сообщение об ошибках валидации
            final buffer = StringBuffer();
            buffer.writeln('Ошибка валидации данных:');

            errors.forEach((field, messages) {
              if (messages is List) {
                for (var msg in messages) {
                  buffer.writeln('• $field: $msg');
                }
              } else if (messages is String) {
                buffer.writeln('• $field: $messages');
              }
            });

            errorMessage = buffer.toString().trim();
          } else if (message != null && message.toString().isNotEmpty) {
            errorMessage = message.toString();
          }
        }
      } else {
        errorMessage = e.toString();
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    // Если сообщение слишком длинное, показываем его в диалоге
    if (message.length > 100) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset:
            true, // Предотвращает сжатие при открытии клавиатуры
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF41454A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Добавить заказ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Основная карточка с белым фоном
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок "Основная информация"
                        const Text(
                          'Основная информация',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Инпут "Что нужно выполнить?"
                        TextField(
                          controller: _taskController,
                          maxLength: 70,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Что нужно выполнить?',
                            hintStyle: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFFCBCDCE),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F7EDE),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Счетчик символов
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _taskController.text.length < 16
                                  ? 'Введите не менее 16 символов'
                                  : 'Достаточно символов',
                              style: TextStyle(
                                fontSize: 12,
                                color: _taskController.text.length < 16
                                    ? Colors.red
                                    : const Color(0xFF5F6368),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            Text(
                              '${_taskController.text.length}/70',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F6368),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Селект "Категория"
                        CompositedTransformTarget(
                          link: _categoryLayerLink,
                          child: GestureDetector(
                            key: _categoryKey,
                            onTap: _toggleCategoryOverlay,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _categoryOverlayEntry != null
                                      ? const Color(0xFF0F7EDE)
                                      : const Color(0xFFE8EAED),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.category_outlined,
                                            size: 20,
                                            color: _selectedCategoryName == null
                                                ? const Color(0xFF5F6368)
                                                : const Color(0xFF0F7EDE),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _selectedCategoryName ??
                                                  'Выберите категорию',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    _selectedCategoryName ==
                                                        null
                                                    ? const Color(0xFF5F6368)
                                                    : const Color(0xFF41454A),
                                                fontFamily: 'Plus Jakarta Sans',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _categoryOverlayEntry != null
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: const Color(0xFF5F6368),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Заголовок "Фото"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Фото',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            Text(
                              'Можно загрузить ${10 - _selectedImages.length} фото',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F6368),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Галерея фотографий
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              // Кнопка добавления
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFF8FBFF),
                                    border: Border.all(
                                      color: const Color(0xFFE3F2FD),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Color(0xFF0F7EDE),
                                          size: 28,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Добавить',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0F7EDE),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // Отображение выбранного изображения
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Заголовок "Описание"
                        const Text(
                          'Описание',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Textarea для описания
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          maxLength: 9000,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Подумайте, какие подробности вы хотели бы указать в заказе и добавьте их в описание.',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFCBCDCE),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F7EDE),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Счетчик символов для описания
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _descriptionController.text.length < 40
                                  ? 'Введите не менее 40 символов'
                                  : 'Достаточно символов',
                              style: TextStyle(
                                fontSize: 12,
                                color: _descriptionController.text.length < 40
                                    ? Colors.red
                                    : const Color(0xFF5F6368),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            Text(
                              '${_descriptionController.text.length}/9000',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F6368),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Заголовок "Адрес"
                        const Text(
                          'Адрес',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Селект города
                        CompositedTransformTarget(
                          link: _cityLayerLink,
                          child: GestureDetector(
                            key: _cityKey,
                            onTap: _toggleCityOverlay,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _cityOverlayEntry != null
                                      ? const Color(0xFF0F7EDE)
                                      : const Color(0xFFE8EAED),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 20,
                                          color: _selectedCityName == null
                                              ? const Color(0xFF5F6368)
                                              : const Color(0xFF0F7EDE),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedCityName ??
                                                'Выберите город',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _selectedCityName == null
                                                  ? const Color(0xFF5F6368)
                                                  : const Color(0xFF41454A),
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _cityOverlayEntry != null
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: const Color(0xFF5F6368),
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Поле "Район/Улица"
                        TextField(
                          controller: _districtController,
                          decoration: InputDecoration(
                            hintText: 'Район или улица',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFCBCDCE),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F7EDE),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.place_outlined,
                              size: 20,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Поля "Дом" и "Квартира" в ряд
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _houseController,
                                decoration: InputDecoration(
                                  hintText: 'Дом',
                                  hintStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFCBCDCE),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8EAED),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8EAED),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F7EDE),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _apartmentController,
                                decoration: InputDecoration(
                                  hintText: 'Квартира (необязательно)',
                                  hintStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFCBCDCE),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8EAED),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8EAED),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F7EDE),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Заголовок "Контактная информация"
                        const Text(
                          'Контактная информация',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Поле "Номер телефона" с маской
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [maskFormatter], // Применяем маску
                          decoration: InputDecoration(
                            hintText: '+7 (___) ___-__-__',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFCBCDCE),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F7EDE),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 20,
                              color: Color(0xFF5F6368),
                            ),
                            suffixIcon: _phoneController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Color(0xFF9AA0A6),
                                    ),
                                    onPressed: () => setState(
                                      () => _phoneController.clear(),
                                    ),
                                  )
                                : null,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Поле "Цена"
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Цена (тенге)',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFCBCDCE),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAED),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F7EDE),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.attach_money_outlined,
                              size: 20,
                              color: Color(0xFF5F6368),
                            ),
                            suffixText: '₸',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF41454A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Кнопка "Добавить заказ"
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLoading
                                  ? const Color(0xFF5F6368)
                                  : const Color(0xFF0F7EDE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Добавить заказ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom Navigation Bar с SafeArea
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: CustomBottomNavBar(
              activeItem: NavItem.addOrder,
              accountType: AccountType.client,
            ),
          ),
        ),
      ),
    );
  }
}
