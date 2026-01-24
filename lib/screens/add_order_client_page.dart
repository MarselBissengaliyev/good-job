import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCities();
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

  void _showCategorySelector() {
    if (_isLoadingCategories || _categories.isEmpty) {
      if (_categories.isEmpty && !_isLoadingCategories) {
        _showError('Категории не загружены');
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Заголовок с хэндлом для перетаскивания
                    Container(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAED),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Заголовок
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Выберите категорию',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 24,
                              color: Color(0xFF5F6368),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE8EAED)),

                    // Список категорий
                    Expanded(
                      child: _categories.isEmpty
                          ? const Center(
                              child: Text(
                                'Категории не найдены',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final categoryId = category['id']?.toString();
                                final categoryName =
                                    category['name']?.toString() ??
                                    'Без названия';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/handyman.png',
                                        width: 24,
                                        height: 24,
                                        color: const Color(0xFF5F6368),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF41454A),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  trailing: _selectedCategoryId == categoryId
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF0F7EDE),
                                          size: 24,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId = categoryId;
                                      _selectedCategoryName = categoryName;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCitySelector() {
    if (_isLoadingCities || _cities.isEmpty) {
      if (_cities.isEmpty && !_isLoadingCities) {
        _showError('Города не загружены');
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Заголовок с хэндлом для перетаскивания
                    Container(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAED),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Заголовок
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Выберите город',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 24,
                              color: Color(0xFF5F6368),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE8EAED)),

                    // Список городов
                    Expanded(
                      child: _cities.isEmpty
                          ? const Center(
                              child: Text(
                                'Города не найдены',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _cities.length,
                              itemBuilder: (context, index) {
                                final city = _cities[index];
                                final cityId = city['id']?.toString();
                                final cityName =
                                    city['name']?.toString() ?? 'Без названия';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.location_on,
                                        color: Color(0xFF5F6368),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    cityName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF41454A),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  trailing: _selectedCityId == cityId
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF0F7EDE),
                                          size: 24,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCityId = cityId;
                                      _selectedCityName = cityName;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();

      // Показываем диалог выбора источника
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0F7EDE),
                ),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F7EDE)),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      if (source == ImageSource.gallery) {
        // Выбор нескольких фото из галереи
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
              }
            }
          });
        }
      } else {
        // Сделать одно фото
        final pickedFile = await picker.pickImage(
          source: source,
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
    } catch (e) {
      _showError('Ошибка при выборе изображений: $e');
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

    if (_houseController.text.isEmpty) {
      _showError('Введите номер дома');
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError('Введите номер телефона');
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

      // 2. Создаем заказ
      final result = await ApiService.createOrder(
        categoryId: int.parse(_selectedCategoryId!),
        cityId: int.parse(_selectedCityId!),
        title: _taskController.text,
        description: _descriptionController.text,
        addressStreet: _districtController.text,
        addressHouse: _houseController.text,
        addressApartment: _apartmentController.text,
        telephone: _phoneController.text,
        price: price,
        images: uploadedImagePaths,
      );

      // 3. Показываем успешное сообщение
      _showSuccess('Заказ успешно создан!');

      // ДОБАВЛЕНО: Отладочный вывод
      print('✅ Заказ создан успешно! Данные: $result');
      if (result['data'] != null) {
        final orderData = result['data'];
        print('ID заказа: ${orderData['id']}');
        print('Название: ${orderData['title']}');
        print('Цена: ${orderData['price']}');
        print('Категория: ${orderData['category']}');
      }

      // 4. Возвращаемся назад через 1 секунду
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Ошибка создания заказа: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                          setState(() {}); // Принудительно обновляем состояние
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
                      GestureDetector(
                        onTap: () => _showCategorySelector(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8EAED)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/handyman.png',
                                        width: 20,
                                        height: 20,
                                        color: const Color(0xFF5F6368),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedCategoryName ??
                                              'Выберите категорию',
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: _selectedCategoryName == null
                                                ? const Color(
                                                    0xFF41454A,
                                                  ).withOpacity(0.6)
                                                : const Color(0xFF41454A),
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF5F6368),
                                  size: 24,
                                ),
                              ],
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
                                  color: const Color(0xFFF5F5F5),
                                  border: Border.all(
                                    color: const Color(0xFFE8EAED),
                                  ),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        color: Color(0xFF5F6368),
                                        size: 32,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Добавить',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF5F6368),
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
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
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
                      GestureDetector(
                        onTap: () => _showCitySelector(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8EAED)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCityName ?? 'Выберите город',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedCityName == null
                                        ? const Color(0xFFCBCDCE)
                                        : const Color(0xFF41454A),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF5F6368),
                                size: 24,
                              ),
                            ],
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

                      // Поле "Номер телефона"
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Номер телефона',
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

      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.addOrder,
        accountType: AccountType.client,
      ),
    );
  }
}
