// lib/screens/edit_order_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:goodjob/services/api_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class EditOrderPage extends StatefulWidget {
  final String orderId;
  final Function() onOrderUpdated;

  const EditOrderPage({
    super.key,
    required this.orderId,
    required this.onOrderUpdated,
  });

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _phoneController = TextEditingController();

  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  List<dynamic> _categories = [];
  List<dynamic> _cities = [];
  int? _selectedCategoryId;
  int? _selectedCityId;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;
  bool _isDataLoaded = false; // Add this flag

  List<String> _existingImages = [];
  List<File> _newImages = [];
  List<String> _imagesToDelete = [];
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;


  @override
  void initState() {
    super.initState();
    _initAnimation();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data here instead of initState
    if (!_isDataLoaded && mounted) {
      _isDataLoaded = true;
      _loadAllData();
    }
  }


  void _initAnimation() {
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
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    _apartmentController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final appLocalizations = AppLocalizations.of(context);
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([_loadOrderData(), _loadCategoriesAndCities()]);
    } catch (e) {
      setState(() {
        _errorMessage =
            '${appLocalizations?.translate('error_loading_data') ?? 'Ошибка загрузки данных'}: $e';
      });
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadOrderData() async {
    try {
      final response = await ApiService.getOrderById(widget.orderId);
      final order = response['data'];

      if (mounted) {
        setState(() {
          _initializeForm(order);
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  void _initializeForm(Map<String, dynamic> order) {
    _titleController.text = order['title'] ?? '';
    _descriptionController.text = order['description'] ?? '';
    _priceController.text = (order['price'] as num?)?.toString() ?? '0';
    _streetController.text = order['addressStreet'] ?? '';
    _houseController.text = order['addressHouse'] ?? '';
    _apartmentController.text = order['addressApartment'] ?? '';

    final phone = order['telephone'] ?? '';
    if (phone.isNotEmpty) {
      String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length == 11 && cleanPhone.startsWith('7')) {
        String areaCode = cleanPhone.substring(1, 4);
        String firstPart = cleanPhone.substring(4, 7);
        String secondPart = cleanPhone.substring(7, 9);
        String thirdPart = cleanPhone.substring(9, 11);
        _phoneController.text =
            '+7 ($areaCode) $firstPart-$secondPart-$thirdPart';
      } else {
        _phoneController.text = phone;
      }
    }

    _selectedCategoryId = order['category']?['id'] is String
        ? int.tryParse(order['category']['id'].toString())
        : order['category']?['id'];
    _selectedCityId = order['city']?['id'];

    _existingImages = List<String>.from(order['images'] ?? []);
  }

  Future<void> _loadCategoriesAndCities() async {
    try {
      final categories = await ApiService.getCategories();
      final cities = await ApiService.getCities();

      if (mounted) {
        setState(() {
          _categories = categories;
          _cities = cities;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  String _getCleanPhoneNumber(String maskedNumber) {
    String cleanNumber = maskedNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('8') && cleanNumber.length == 11) {
      cleanNumber = '7${cleanNumber.substring(1)}';
    }
    if (!cleanNumber.startsWith('7')) {
      cleanNumber = '7$cleanNumber';
    }
    return '+$cleanNumber';
  }

  Future<void> _pickImage() async {
    final appLocalizations = AppLocalizations.of(context);
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
      _showSnackBar(
        appLocalizations?.translate('error_picking_image') ??
            'Ошибка при выборе изображения',
        isError: true,
      );
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
    final appLocalizations = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> uploadedImages = [];
      if (_newImages.isNotEmpty) {
        uploadedImages = await ApiService.uploadOrderImages(_newImages);
      }

      final finalImages = [..._existingImages, ...uploadedImages];

      final cleanPhone = _getCleanPhoneNumber(_phoneController.text);

      await ApiService.updateClientOrder(
        orderId: widget.orderId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId,
        cityId: _selectedCityId,
        addressStreet: _streetController.text.trim(),
        addressHouse: _houseController.text.trim(),
        addressApartment: _apartmentController.text.trim(),
        telephone: cleanPhone,
        images: finalImages,
      );

      if (mounted) {
        _showSnackBar(
          appLocalizations?.translate('order_updated_success') ??
              'Заказ успешно обновлен',
        );
        widget.onOrderUpdated();
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(
        '${appLocalizations?.translate('error_updating_order') ?? 'Ошибка при обновлении'}: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF41454A),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            appLocalizations?.translate('edit_order') ?? 'Редактировать заказ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            _buildLanguageButton(context, languageProvider, appLocalizations),
            if (!_isLoadingData && _errorMessage == null)
              TextButton(
                onPressed: _isLoading ? null : _saveOrder,
                child: Text(
                  appLocalizations?.translate('save') ?? 'Сохранить',
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildBody(appLocalizations),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    LanguageProvider languageProvider,
    AppLocalizations? appLocalizations,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            'RU',
            const Locale('ru'),
            languageProvider.locale.languageCode == 'ru',
            languageProvider,
            context,
          ),
          _buildLanguageOption(
            'KZ',
            const Locale('kk'),
            languageProvider.locale.languageCode == 'kk',
            languageProvider,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String code,
    Locale locale,
    bool isActive,
    LanguageProvider provider,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        provider.setLanguage(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.languageCode == 'ru'
                  ? 'Язык изменен на русский'
                  : 'Тіл қазақшаға өзгертілді',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations? appLocalizations) {
    if (_isLoadingData) {
      return _buildLoadingState(appLocalizations);
    }

    if (_errorMessage != null) {
      return _buildErrorState(appLocalizations);
    }

    return Form(
      key: _formKey,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagesSection(appLocalizations),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  appLocalizations?.translate('basic_info') ??
                      'Основная информация',
                ),
                const SizedBox(height: 16),
                _buildTitleField(appLocalizations),
                const SizedBox(height: 16),
                _buildCategoryDropdown(appLocalizations),
                const SizedBox(height: 16),
                _buildCityDropdown(appLocalizations),
                const SizedBox(height: 16),
                _buildDescriptionField(appLocalizations),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  appLocalizations?.translate('address') ?? 'Адрес',
                ),
                const SizedBox(height: 16),
                _buildStreetField(appLocalizations),
                const SizedBox(height: 16),
                _buildHouseApartmentRow(appLocalizations),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  appLocalizations?.translate('contact_info') ?? 'Контакты',
                ),
                const SizedBox(height: 16),
                _buildPhoneField(appLocalizations),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  appLocalizations?.translate('price') ?? 'Цена',
                ),
                const SizedBox(height: 8),
                _buildPriceField(appLocalizations),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF0F7EDE)),
                      const SizedBox(height: 16),
                      Text(
                        appLocalizations?.translate('saving') ??
                            'Сохранение...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F6368),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations? appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0F7EDE)),
          const SizedBox(height: 16),
          Text(
            appLocalizations?.translate('loading_order_data') ??
                'Загрузка данных заказа...',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations? appLocalizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations?.translate('failed_to_load_data') ??
                  'Не удалось загрузить данные',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7EDE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: Text(appLocalizations?.translate('retry') ?? 'Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(AppLocalizations? appLocalizations) {
    final hasImages = _existingImages.isNotEmpty || _newImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          appLocalizations?.translate('photos') ?? 'Фотографии',
        ),
        const SizedBox(height: 12),
        if (!hasImages)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations?.translate('no_photos') ??
                        'Нет фотографий',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              if (_existingImages.isNotEmpty) ...[
                Text(
                  appLocalizations?.translate('current_photos') ??
                      'Текущие фотографии',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
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
                              borderRadius: BorderRadius.circular(12),
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
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
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
              if (_newImages.isNotEmpty) ...[
                Text(
                  appLocalizations?.translate('new_photos') ??
                      'Новые фотографии',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
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
                              borderRadius: BorderRadius.circular(12),
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
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF0F7EDE),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF0F7EDE),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appLocalizations?.translate('add_photo') ??
                            'Добавить фото',
                        style: const TextStyle(
                          color: Color(0xFF0F7EDE),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Plus Jakarta Sans',
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
        fontSize: 20,
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

  Widget _buildTitleField(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(appLocalizations?.translate('title') ?? 'Название'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText:
                appLocalizations?.translate('enter_order_title') ??
                'Введите название заказа',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            counterText: '${_titleController.text.length}/70',
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
              borderSide: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLength: 70,
          validator: (value) {
            if (value == null || value.trim().length < 16) {
              return appLocalizations?.translate('title_min_length_error') ??
                  'Минимум 16 символов';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(appLocalizations?.translate('category') ?? 'Категория'),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            hint: Text(
              appLocalizations?.translate('select_category') ??
                  'Выберите категорию',
            ),
            items: _categories.map((category) {
              return DropdownMenuItem<int>(
                value: category['id'] is String
                    ? int.tryParse(category['id'].toString())
                    : category['id'],
                child: Text(
                  category['name'] ?? '',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            validator: (value) {
              if (value == null)
                return appLocalizations?.translate('select_category_error') ??
                    'Выберите категорию';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(appLocalizations?.translate('city') ?? 'Город'),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            hint: Text(
              appLocalizations?.translate('select_city') ?? 'Выберите город',
            ),
            items: _cities.map((city) {
              return DropdownMenuItem<int>(
                value: city['id'],
                child: Text(
                  city['name'] ?? '',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCityId = value),
            validator: (value) {
              if (value == null)
                return appLocalizations?.translate('select_city_error') ??
                    'Выберите город';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(appLocalizations?.translate('description') ?? 'Описание'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText:
                appLocalizations?.translate('describe_order_details') ??
                'Опишите детали заказа',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            counterText: '${_descriptionController.text.length}/9000',
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
              borderSide: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 6,
          maxLength: 9000,
          validator: (value) {
            if (value == null || value.trim().length < 40) {
              return appLocalizations?.translate(
                    'description_min_length_error',
                  ) ??
                  'Минимум 40 символов';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStreetField(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(appLocalizations?.translate('street') ?? 'Улица'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _streetController,
          decoration: InputDecoration(
            hintText: appLocalizations?.translate('enter_street') ?? 'Улица',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
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
              borderSide: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: const Icon(
              Icons.place_outlined,
              color: Color(0xFF9E9E9E),
            ),
          ),
          maxLength: 128,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return appLocalizations?.translate('enter_street_error') ??
                  'Введите улицу';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHouseApartmentRow(AppLocalizations? appLocalizations) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(appLocalizations?.translate('house') ?? 'Дом'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _houseController,
                decoration: InputDecoration(
                  hintText:
                      appLocalizations?.translate('house_number') ?? 'Дом',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF0F7EDE),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLength: 128,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations?.translate('enter_house_error') ??
                        'Введите дом';
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
              _buildLabel(
                appLocalizations?.translate('apartment') ?? 'Квартира',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apartmentController,
                decoration: InputDecoration(
                  hintText:
                      appLocalizations?.translate('apartment_office') ??
                      'Кв/офис',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF0F7EDE),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLength: 128,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(appLocalizations?.translate('phone') ?? 'Телефон'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          inputFormatters: [maskFormatter],
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+7 (___) ___-__-__',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
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
              borderSide: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: Color(0xFF9E9E9E),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return appLocalizations?.translate('enter_phone_error') ??
                  'Введите телефон';
            }
            final cleanPhone = _getCleanPhoneNumber(value);
            if (cleanPhone.length < 12) {
              return appLocalizations?.translate('valid_phone_error') ??
                  'Введите корректный номер телефона';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField(AppLocalizations? appLocalizations) {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        prefixText: '${appLocalizations?.translate('tenge') ?? '₸'} ',
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
          borderSide: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        prefixIcon: const Icon(
          Icons.attach_money_outlined,
          color: Color(0xFF9E9E9E),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return appLocalizations?.translate('enter_price_error') ??
              'Введите цену';
        }
        if (double.tryParse(value) == null) {
          return appLocalizations?.translate('enter_valid_number') ??
              'Введите число';
        }
        final price = double.parse(value);
        if (price <= 0) {
          return appLocalizations?.translate('price_positive_error') ??
              'Цена должна быть больше 0';
        }
        return null;
      },
    );
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    return 'http://gj-back.checkedout.kz/storage/$imagePath';
  }
}
