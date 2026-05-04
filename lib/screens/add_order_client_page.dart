import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class AddOrderClientPage extends StatefulWidget {
  const AddOrderClientPage({super.key});

  @override
  State<AddOrderClientPage> createState() => _AddOrderClientPageState();
}

class _AddOrderClientPageState extends State<AddOrderClientPage> with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _selectedCityId;

  List<dynamic> _categories = [];
  List<dynamic> _cities = [];
  bool _isLoadingCategories = false;
  bool _isLoadingCities = false;

  String? _selectedCategoryName;
  String? _selectedCityName;

  OverlayEntry? _categoryOverlayEntry;
  OverlayEntry? _cityOverlayEntry;
  final LayerLink _categoryLayerLink = LayerLink();
  final LayerLink _cityLayerLink = LayerLink();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isInitialized = false;

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

  @override
  void initState() {
    super.initState();
    _initAnimation();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadCategories();
      _loadCities();
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
    _removeCategoryOverlay();
    _removeCityOverlay();
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final appLocalizations = AppLocalizations.of(context);
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);

    try {
      final categories = await ApiService.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
      if (categories.isEmpty) {
        _showError(appLocalizations?.translate('categories_not_loaded') ?? 'Категории не загружены');
      }
    } catch (e) {
      if (mounted) {
        _showError('${appLocalizations?.translate('error_loading_categories') ?? 'Ошибка загрузки категорий'}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadCities() async {
    final appLocalizations = AppLocalizations.of(context);
    if (!mounted) return;
    setState(() => _isLoadingCities = true);

    try {
      final cities = await ApiService.getCities();
      if (!mounted) return;
      setState(() => _cities = cities);
    } catch (e) {
      if (mounted) {
        _showError('${appLocalizations?.translate('error_loading_cities') ?? 'Ошибка загрузки городов'}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  void _toggleCategoryOverlay() {
    if (_categoryOverlayEntry != null) {
      _removeCategoryOverlay();
    } else {
      _removeCityOverlay();
      _showCategoryOverlay();
    }
  }

  void _showCategoryOverlay() {
    final appLocalizations = AppLocalizations.of(context);
    if (_isLoadingCategories || _categories.isEmpty) {
      if (_categories.isEmpty && !_isLoadingCategories) {
        _showError(appLocalizations?.translate('categories_not_loaded') ?? 'Категории не загружены');
      }
      return;
    }

    final renderBox = _categoryKey.currentContext?.findRenderObject() as RenderBox?;
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
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 1)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        appLocalizations?.translate('category') ?? 'Категория',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
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
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF5F6368)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (_categories.length * 44.0).clamp(100.0, 300.0),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final categoryId = category['id']?.toString();
                      final categoryName = category['name']?.toString() ?? appLocalizations?.translate('untitled') ?? 'Без названия';
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

  void _toggleCityOverlay() {
    if (_cityOverlayEntry != null) {
      _removeCityOverlay();
    } else {
      _removeCategoryOverlay();
      _showCityOverlay();
    }
  }

  void _showCityOverlay() {
    final appLocalizations = AppLocalizations.of(context);
    if (_isLoadingCities || _cities.isEmpty) {
      if (_cities.isEmpty && !_isLoadingCities) {
        _showError(appLocalizations?.translate('cities_not_loaded') ?? 'Города не загружены');
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
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 1)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        appLocalizations?.translate('city') ?? 'Город',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
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
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF5F6368)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (_cities.length * 44.0).clamp(100.0, 300.0),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      final cityId = city['id']?.toString();
                      final cityName = city['name']?.toString() ?? appLocalizations?.translate('untitled') ?? 'Без названия';
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
          border: isSelected ? const Border(left: BorderSide(color: Color(0xFF0F7EDE), width: 3)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF0F7EDE) : const Color(0xFFCBCDCE), width: 1.5),
                color: isSelected ? const Color(0xFF0F7EDE) : Colors.white,
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? const Color(0xFF0F7EDE) : const Color(0xFF41454A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final appLocalizations = AppLocalizations.of(context);
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  appLocalizations?.translate('add_photos') ?? 'Добавить фото',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.photo_library,
                      label: appLocalizations?.translate('gallery') ?? 'Галерея',
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickFromGallery();
                      },
                    ),
                    _buildImageSourceButton(
                      icon: Icons.camera_alt,
                      label: appLocalizations?.translate('camera') ?? 'Камера',
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
      _showError('${appLocalizations?.translate('error_picking_images') ?? 'Ошибка при выборе изображений'}: $e');
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
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF41454A))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final appLocalizations = AppLocalizations.of(context);
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(maxWidth: 1200, maxHeight: 1200, imageQuality: 80);

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var pickedFile in pickedFiles) {
          if (_selectedImages.length < 10) {
            _selectedImages.add(pickedFile);
          } else {
            _showError(appLocalizations?.translate('max_images_error') ?? 'Максимум 10 изображений');
            break;
          }
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final appLocalizations = AppLocalizations.of(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        if (_selectedImages.length < 10) {
          _selectedImages.add(pickedFile);
        } else {
          _showError(appLocalizations?.translate('max_images_error') ?? 'Максимум 10 изображений');
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _createOrder() async {
    final appLocalizations = AppLocalizations.of(context);

    if (_taskController.text.isEmpty || _taskController.text.length < 16) {
      _showError(appLocalizations?.translate('title_min_length_error') ?? 'Введите название задачи (минимум 16 символов)');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showError(appLocalizations?.translate('at_least_one_image_error') ?? 'Добавьте хотя бы одно изображение');
      return;
    }

    if (_descriptionController.text.isEmpty || _descriptionController.text.length < 40) {
      _showError(appLocalizations?.translate('description_min_length_error') ?? 'Введите описание (минимум 40 символов)');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError(appLocalizations?.translate('select_category_error') ?? 'Выберите категорию');
      return;
    }

    if (_selectedCityId == null) {
      _showError(appLocalizations?.translate('select_city_error') ?? 'Выберите город');
      return;
    }

    if (_districtController.text.isEmpty) {
      _showError(appLocalizations?.translate('enter_street_error') ?? 'Введите улицу/район');
      return;
    }

    String cleanPhone = _getCleanPhoneNumber(_phoneController.text);
    if (cleanPhone.length < 12) {
      _showError(appLocalizations?.translate('valid_phone_error') ?? 'Введите корректный номер телефона');
      return;
    }

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showError(appLocalizations?.translate('enter_price_error') ?? 'Введите цену');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError(appLocalizations?.translate('valid_price_error') ?? 'Введите корректную цену (больше 0)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> uploadedImagePaths = [];
      if (_selectedImages.isNotEmpty) {
        // Конвертируем XFile в File для загрузки
        List<File> imageFiles = [];
        for (var xfile in _selectedImages) {
          if (!kIsWeb) {
            // На мобильных платформах
            imageFiles.add(File(xfile.path));
          } else {
            // На Web - временное решение, нужно будет переделать API для приема XFile
            // Пока покажем ошибку
            throw Exception('Загрузка изображений на Web временно недоступна. Используйте мобильное приложение.');
          }
        }
        uploadedImagePaths = await ApiService.uploadOrderImages(imageFiles);
      }

      String adressHouse = _houseController.text;
      if (adressHouse == "") adressHouse = "-";
      String adressApartment = _apartmentController.text;
      if (adressApartment == "") adressApartment = "-";

      await ApiService.createOrder(
        categoryId: int.parse(_selectedCategoryId!),
        cityId: int.parse(_selectedCityId!),
        title: _taskController.text,
        description: _descriptionController.text,
        addressStreet: _districtController.text,
        addressHouse: adressHouse,
        addressApartment: adressApartment,
        telephone: cleanPhone,
        price: price,
        images: uploadedImagePaths,
      );

      _showSuccess(appLocalizations?.translate('order_created_success') ?? 'Заказ успешно создан!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      String errorMessage = _handleError(e, appLocalizations);
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _handleError(dynamic e, AppLocalizations? appLocalizations) {
    if (e is DioException) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final buffer = StringBuffer();
          buffer.writeln('${appLocalizations?.translate('validation_error') ?? 'Ошибка валидации данных:'}');
          errors.forEach((field, messages) {
            if (messages is List) {
              for (var msg in messages) {
                buffer.writeln('• $field: $msg');
              }
            } else if (messages is String) {
              buffer.writeln('• $field: $messages');
            }
          });
          return buffer.toString().trim();
        } else if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    }
    return e.toString();
  }

  void _showError(String message) {
    final appLocalizations = AppLocalizations.of(context);
    if (message.length > 100) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(appLocalizations?.translate('error') ?? 'Ошибка'),
          content: SingleChildScrollView(child: Text(message)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations?.translate('ok') ?? 'OK'),
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
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
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
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF41454A), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            appLocalizations?.translate('add_order') ?? 'Добавить заказ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF41454A)),
          ),
          actions: [
            _buildLanguageButton(context, languageProvider, appLocalizations),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations?.translate('basic_info') ?? 'Основная информация',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
                      ),
                      const SizedBox(height: 16),
                      _buildTaskField(appLocalizations),
                      const SizedBox(height: 20),
                      _buildCategorySelector(appLocalizations),
                      const SizedBox(height: 20),
                      _buildPhotosSection(appLocalizations),
                      const SizedBox(height: 20),
                      _buildDescriptionField(appLocalizations),
                      const SizedBox(height: 20),
                      Text(
                        appLocalizations?.translate('address') ?? 'Адрес',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
                      ),
                      const SizedBox(height: 12),
                      _buildCitySelector(appLocalizations),
                      const SizedBox(height: 12),
                      _buildDistrictField(appLocalizations),
                      const SizedBox(height: 12),
                      _buildAddressFields(appLocalizations),
                      const SizedBox(height: 20),
                      Text(
                        appLocalizations?.translate('contact_info') ?? 'Контактная информация',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
                      ),
                      const SizedBox(height: 12),
                      _buildPhoneField(appLocalizations),
                      const SizedBox(height: 12),
                      _buildPriceField(appLocalizations),
                      const SizedBox(height: 20),
                      _buildSubmitButton(appLocalizations),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

  Widget _buildLanguageButton(BuildContext context, LanguageProvider languageProvider, AppLocalizations? appLocalizations) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('RU', const Locale('ru'), languageProvider.locale.languageCode == 'ru', languageProvider, context),
          _buildLanguageOption('KZ', const Locale('kk'), languageProvider.locale.languageCode == 'kk', languageProvider, context),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, Locale locale, bool isActive, LanguageProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.setLanguage(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.languageCode == 'ru' ? 'Язык изменен на русский' : 'Тіл қазақшаға өзгертілді'),
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

  Widget _buildTaskField(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _taskController,
          maxLength: 70,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: appLocalizations?.translate('what_to_do') ?? 'Что нужно выполнить?',
            hintStyle: const TextStyle(fontSize: 17, color: Color(0xFFCBCDCE)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 17, color: Color(0xFF41454A)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _taskController.text.length < 16
                  ? appLocalizations?.translate('min_chars_required') ?? 'Введите не менее 16 символов'
                  : appLocalizations?.translate('enough_chars') ?? 'Достаточно символов',
              style: TextStyle(
                fontSize: 12,
                color: _taskController.text.length < 16 ? Colors.red : const Color(0xFF5F6368),
              ),
            ),
            Text('${_taskController.text.length}/70', style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AppLocalizations? appLocalizations) {
    return CompositedTransformTarget(
      link: _categoryLayerLink,
      child: GestureDetector(
        key: _categoryKey,
        onTap: _toggleCategoryOverlay,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _categoryOverlayEntry != null ? const Color(0xFF0F7EDE) : const Color(0xFFE8EAED), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20,
                        color: _selectedCategoryName == null ? const Color(0xFF5F6368) : const Color(0xFF0F7EDE)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategoryName ?? appLocalizations?.translate('select_category') ?? 'Выберите категорию',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCategoryName == null ? const Color(0xFF5F6368) : const Color(0xFF41454A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(_categoryOverlayEntry != null ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: const Color(0xFF5F6368), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSection(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appLocalizations?.translate('photos') ?? 'Фото',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
            ),
            Text(
              '${appLocalizations?.translate('can_upload') ?? 'Можно загрузить'} ${10 - _selectedImages.length} ${appLocalizations?.translate('photos') ?? 'фото'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF8FBFF),
                    border: Border.all(color: const Color(0xFFE3F2FD)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0F7EDE), size: 28),
                      const SizedBox(height: 4),
                      Text(appLocalizations?.translate('add') ?? 'Добавить',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F7EDE))),
                    ],
                  ),
                ),
              );
            } else {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? FutureBuilder<Uint8List?>(
                            future: _selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              }
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          )
                        : Image.file(
                            File(_selectedImages[index].path),
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
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations?.translate('description') ?? 'Описание',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF41454A)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          maxLength: 9000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: appLocalizations?.translate('description_hint') ??
                'Подумайте, какие подробности вы хотели бы указать в заказе и добавьте их в описание.',
            hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFCBCDCE)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 16, color: Color(0xFF41454A)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _descriptionController.text.length < 40
                  ? appLocalizations?.translate('min_chars_required_40') ?? 'Введите не менее 40 символов'
                  : appLocalizations?.translate('enough_chars') ?? 'Достаточно символов',
              style: TextStyle(
                fontSize: 12,
                color: _descriptionController.text.length < 40 ? Colors.red : const Color(0xFF5F6368),
              ),
            ),
            Text('${_descriptionController.text.length}/9000', style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
          ],
        ),
      ],
    );
  }

  Widget _buildCitySelector(AppLocalizations? appLocalizations) {
    return CompositedTransformTarget(
      link: _cityLayerLink,
      child: GestureDetector(
        key: _cityKey,
        onTap: _toggleCityOverlay,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _cityOverlayEntry != null ? const Color(0xFF0F7EDE) : const Color(0xFFE8EAED), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 20,
                        color: _selectedCityName == null ? const Color(0xFF5F6368) : const Color(0xFF0F7EDE)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCityName ?? appLocalizations?.translate('select_city') ?? 'Выберите город',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCityName == null ? const Color(0xFF5F6368) : const Color(0xFF41454A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(_cityOverlayEntry != null ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: const Color(0xFF5F6368), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictField(AppLocalizations? appLocalizations) {
    return TextField(
      controller: _districtController,
      decoration: InputDecoration(
        hintText: appLocalizations?.translate('street_or_district') ?? 'Район или улица',
        hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFCBCDCE)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.place_outlined, size: 20, color: Color(0xFF5F6368)),
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFF41454A)),
    );
  }

  Widget _buildAddressFields(AppLocalizations? appLocalizations) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _houseController,
            decoration: InputDecoration(
              hintText: appLocalizations?.translate('house') ?? 'Дом',
              hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFCBCDCE)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF41454A)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _apartmentController,
            decoration: InputDecoration(
              hintText: appLocalizations?.translate('apartment_optional') ?? 'Квартира (необязательно)',
              hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFCBCDCE)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF41454A)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(AppLocalizations? appLocalizations) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [maskFormatter],
      decoration: InputDecoration(
        hintText: '+7 (___) ___-__-__',
        hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFCBCDCE)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF5F6368)),
        suffixIcon: _phoneController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF9AA0A6)),
                onPressed: () => setState(() => _phoneController.clear()),
              )
            : null,
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFF41454A)),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPriceField(AppLocalizations? appLocalizations) {
    return TextField(
      controller: _priceController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: appLocalizations?.translate('price_tenge') ?? 'Цена (тенге)',
        hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFCBCDCE)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F7EDE))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.attach_money_outlined, size: 20, color: Color(0xFF5F6368)),
        suffixText: appLocalizations?.translate('tenge') ?? '₸',
        suffixStyle: const TextStyle(color: Color(0xFF41454A), fontWeight: FontWeight.bold),
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFF41454A)),
    );
  }

  Widget _buildSubmitButton(AppLocalizations? appLocalizations) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? const Color(0xFF5F6368) : const Color(0xFF0F7EDE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : Text(
                appLocalizations?.translate('add_order') ?? 'Добавить заказ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }
}