// lib/screens/edit_order_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/api_service.dart';

class EditOrderPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function() onOrderUpdated;

  const EditOrderPage({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _phoneController = TextEditingController();

  List<dynamic> _categories = [];
  List<dynamic> _cities = [];
  int? _selectedCategoryId;
  int? _selectedCityId;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Изображения
  List<String> _existingImages = [];
  List<File> _newImages = [];
  List<String> _imagesToDelete = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeForm();
  }

  void _initializeForm() {
    final order = widget.order;
    
    _titleController.text = order['title'] ?? '';
    _descriptionController.text = order['description'] ?? '';
    _priceController.text = (order['price'] as num?)?.toString() ?? '0';
    _streetController.text = order['address_street'] ?? '';
    _houseController.text = order['address_house'] ?? '';
    _apartmentController.text = order['address_apartment'] ?? '';
    _phoneController.text = order['telephone'] ?? '';

    _selectedCategoryId = order['category']?['id'] is String
        ? int.tryParse(order['category']['id'].toString())
        : order['category']?['id'];
    _selectedCityId = order['city']?['id'];

    _existingImages = List<String>.from(order['images'] ?? []);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      final categories = await ApiService.getCategories();
      final cities = await ApiService.getCities();

      setState(() {
        _categories = categories;
        _cities = cities;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showSnackBar('Ошибка загрузки данных: $e', isError: true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showSnackBar('Ошибка при выборе изображения', isError: true);
    }
  }

  void _removeExistingImage(int index) {
    final imageToDelete = _existingImages[index];
    setState(() {
      _existingImages.removeAt(index);
      _imagesToDelete.add(imageToDelete);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Загружаем новые изображения, если есть
      List<String> uploadedImages = [];
      if (_newImages.isNotEmpty) {
        uploadedImages = await ApiService.uploadOrderImages(_newImages);
      }

      // Формируем финальный список изображений
      final finalImages = [
        ..._existingImages,
        ...uploadedImages,
      ];

      final orderId = widget.order['id'].toString();

      // Обновляем заказ
      await ApiService.updateClientOrder(
        orderId: orderId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId,
        cityId: _selectedCityId,
        addressStreet: _streetController.text.trim(),
        addressHouse: _houseController.text.trim(),
        addressApartment: _apartmentController.text.trim(),
        telephone: _phoneController.text.trim(),
        images: finalImages,
      );

      if (mounted) {
        _showSnackBar('Заказ успешно обновлен');
        widget.onOrderUpdated();
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Ошибка при обновлении: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF41454A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Редактировать заказ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveOrder,
              child: Text(
                'Сохранить',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображения
                _buildImagesSection(),
                const SizedBox(height: 24),

                // Основная информация
                _buildSectionTitle('Основная информация'),
                const SizedBox(height: 16),

                // Название
                _buildLabel('Название'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: _buildInputDecoration(
                    hint: 'Введите название заказа',
                    counterText: '${_titleController.text.length}/70',
                  ),
                  maxLength: 70,
                  validator: (value) {
                    if (value == null || value.trim().length < 16) {
                      return 'Минимум 16 символов';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Категория
                _buildLabel('Категория'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    hint: const Text('Выберите категорию'),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'] is String
                            ? int.tryParse(category['id'].toString())
                            : category['id'],
                        child: Text(category['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Выберите категорию';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Город
                _buildLabel('Город'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedCityId,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    hint: const Text('Выберите город'),
                    items: _cities.map((city) {
                      return DropdownMenuItem<int>(
                        value: city['id'],
                        child: Text(city['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCityId = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Выберите город';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Описание
                _buildLabel('Описание'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration(
                    hint: 'Опишите детали заказа',
                    counterText: '${_descriptionController.text.length}/9000',
                    maxLines: 6,
                  ),
                  maxLines: 6,
                  maxLength: 9000,
                  validator: (value) {
                    if (value == null || value.trim().length < 40) {
                      return 'Минимум 40 символов';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Адрес'),
                const SizedBox(height: 16),

                // Улица
                _buildLabel('Улица'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _streetController,
                  decoration: _buildInputDecoration(hint: 'Улица'),
                  maxLength: 128,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите улицу';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Дом и квартира в одной строке
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Дом'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _houseController,
                            decoration: _buildInputDecoration(hint: 'Дом'),
                            maxLength: 128,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите дом';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Квартира'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _apartmentController,
                            decoration: _buildInputDecoration(
                              hint: 'Кв/офис',
                            ),
                            maxLength: 128,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Контакты'),
                const SizedBox(height: 16),

                // Телефон
                _buildLabel('Телефон'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: _buildInputDecoration(hint: '+7 (___) ___-__-__'),
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите телефон';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Цена'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  decoration: _buildInputDecoration(
                    hint: '0',
                    prefixText: '₸ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите цену';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Введите число';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    final hasImages = _existingImages.isNotEmpty || _newImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Фотографии'),
        const SizedBox(height: 12),
        if (!hasImages)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Нет фотографий',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              // Существующие изображения
              if (_existingImages.isNotEmpty) ...[
                const Text(
                  'Текущие фотографии',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF41454A),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  _getFullImageUrl(_existingImages[index]),
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Новые изображения
              if (_newImages.isNotEmpty) ...[
                const Text(
                  'Новые фотографии',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF41454A),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_newImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Кнопка добавления
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF2196F3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Color(0xFF2196F3)),
                      SizedBox(width: 8),
                      Text(
                        'Добавить фото',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF41454A),
        fontFamily: 'Plus Jakarta Sans',
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF41454A),
        fontFamily: 'Plus Jakarta Sans',
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    String? counterText,
    int? maxLines,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      counterText: counterText,
      prefixText: prefixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    return 'http://gj-back.checkedout.kz/storage/$imagePath';
  }
}