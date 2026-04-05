import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/order_client_page.dart';
import 'package:goodjob/screens/subscription_success_page.dart';
import 'package:goodjob/services/api_service.dart';
import 'package:goodjob/services/common/profile_api.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class OrdersMasterPage extends StatefulWidget {
  const OrdersMasterPage({super.key});

  @override
  State<OrdersMasterPage> createState() => _OrdersMasterPageState();
}

class _OrdersMasterPageState extends State<OrdersMasterPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  bool _initialized = false;
  String _errorMessage = '';

  String? _selectedCategory;
  String? _selectedPrice;
  String? _selectedCity; // Добавлено для города
  DateTime? _selectedDate;

  final ProfileApi _profileApi = ProfileApi();
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;
  bool _userDataLoaded = false;
  bool _hasSubscription = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _cities = []; // Добавлено для списка городов

  OverlayEntry? _categoryOverlayEntry;
  OverlayEntry? _priceOverlayEntry;
  OverlayEntry? _cityOverlayEntry; // Добавлено для города
  final LayerLink _categoryLayerLink = LayerLink();
  final LayerLink _priceLayerLink = LayerLink();
  final LayerLink _cityLayerLink = LayerLink(); // Добавлено для города
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _priceKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey(); // Добавлено для города

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? _selectedCategoryRaw;
  String? _selectedPriceRaw;
  String? _selectedCityRaw; // Добавлено для города

  @override
  void initState() {
    super.initState();
    _selectedCategoryRaw = 'all_categories';
    _selectedPriceRaw = 'any_price';
    _selectedCityRaw = 'all_cities'; // Добавлено для города

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
  
  if (!_initialized) {
    _initialized = true;
    _loadUserProfile();
    _loadCategories();
    _loadCities(); // Добавьте эту строку
    _fetchOrders();
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
    _removePriceOverlay();
    _removeCityOverlay(); // Добавлено для города
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  void _updateFilterDisplayValues() {
    final appLocalizations = AppLocalizations.of(context);
    setState(() {
      _selectedCategory = _getLocalizedCategory(
        _selectedCategoryRaw,
        appLocalizations,
      );
      _selectedPrice = _getLocalizedPrice(_selectedPriceRaw, appLocalizations);
      _selectedCity = _getLocalizedCity(_selectedCityRaw, appLocalizations);
    });
  }

  String _getLocalizedCategory(
    String? rawValue,
    AppLocalizations? appLocalizations,
  ) {
    if (rawValue == null)
      return appLocalizations?.translate('all_categories') ?? 'Все категории';
    if (rawValue == 'all_categories') {
      return appLocalizations?.translate('all_categories') ?? 'Все категории';
    }
    return rawValue;
  }

  String _getLocalizedPrice(
    String? rawValue,
    AppLocalizations? appLocalizations,
  ) {
    if (rawValue == null)
      return appLocalizations?.translate('any_price') ?? 'Любая стоимость';
    if (rawValue == 'any_price') {
      return appLocalizations?.translate('any_price') ?? 'Любая стоимость';
    }
    return rawValue;
  }

  String _getLocalizedCity(
    String? rawValue,
    AppLocalizations? appLocalizations,
  ) {
    if (rawValue == null || rawValue == 'all_cities') {
      return appLocalizations?.translate('all_cities') ?? 'Все города';
    }
    return rawValue;
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    final appLocalizations = AppLocalizations.of(context);
    print('🔄 Начало загрузки профиля пользователя...');

    try {
      final response = await _profileApi.getProfile();
      print('✅ Получен ответ от API: $response');

      if (mounted) {
        final user = response['data'];
        print('📱 Данные пользователя: $user');
        print('📋 Подписки: ${user['subscriptions']}');

        bool hasActiveSub = false;
        final subscriptions = user['subscriptions'] as List?;
        if (subscriptions != null && subscriptions.isNotEmpty) {
          final subscription = subscriptions.first;
          if (subscription['endAt'] != null) {
            final endAt = DateTime.parse(subscription['endAt'] as String);
            final now = DateTime.now();
            hasActiveSub = endAt.isAfter(now.subtract(const Duration(days: 1)));
            print('📅 Подписка до: $endAt, активна: $hasActiveSub');
          }
        }

        setState(() {
          _userData = user;
          _isLoadingUser = false;
          _userDataLoaded = true;
          _hasSubscription = hasActiveSub;
        });

        print('✅ Профиль загружен, подписка активна: $_hasSubscription');
      }
    } on UnauthorizedException catch (e) {
      print('❌ Ошибка авторизации: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _userDataLoaded = true;
          _hasSubscription = false;
        });
        _showError(
          appLocalizations?.translate('session_expired') ?? 'Сессия истекла',
        );
      }
    } on ApiException catch (e) {
      print('❌ API ошибка: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _userDataLoaded = true;
          _hasSubscription = false;
        });
        _showError(
          '${appLocalizations?.translate('error_loading_profile') ?? 'Ошибка загрузки профиля'}: ${e.message}',
        );
      }
    } catch (e) {
      print('❌ Неизвестная ошибка: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _userDataLoaded = true;
          _hasSubscription = false;
        });
        _showError(
          appLocalizations?.translate('unknown_error') ?? 'Неизвестная ошибка',
        );
      }
    }
  }

  bool _hasActiveSubscription() {
    print(
      '🔍 Проверка подписки: _userDataLoaded=$_userDataLoaded, _hasSubscription=$_hasSubscription',
    );
    return _userDataLoaded && _hasSubscription;
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    final appLocalizations = AppLocalizations.of(context);
    try {
      final categories = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categories);
        });
        _updateFilterDisplayValues();
      }
    } catch (e) {
      _showError(
        '${appLocalizations?.translate('error_loading_categories') ?? 'Ошибка загрузки категорий'}: $e',
      );
    }
  }

// Добавьте этот метод в класс:
Future<void> _loadCities() async {
  if (!mounted) return;
  
  try {
    final cities = await ApiService.getCities();
    if (mounted) {
      setState(() {
        _cities = List<Map<String, dynamic>>.from(cities);
      });
    }
  } catch (e) {
    print('Ошибка загрузки городов: $e');
  }
}
  void _showError(String message) {
    if (!mounted) return;

    final appLocalizations = AppLocalizations.of(context);
    if (message.length > 100) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(appLocalizations?.translate('error') ?? 'Ошибка'),
          content: SingleChildScrollView(child: Text(message)),
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

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> response;
      if (_selectedDate != null) {
        final startOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          0,
          0,
        );
        final endOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          23,
          59,
        );
        response = await ApiService.getOrders(
          startDate: startOfDay,
          endDate: endOfDay,
        );
      } else {
        response = await ApiService.getOrders();
      }

      final List<dynamic> orders = response['data'] ?? [];

      if (mounted) {
        setState(() {
          _orders = orders;
          _filteredOrders = List.from(orders);
          _isLoading = false;
        });
        _applyLocalFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _applyLocalFilters() {
  if (!mounted) return;

  List<dynamic> filtered = List.from(_orders);
  final appLocalizations = AppLocalizations.of(context);

  final isAllCategories = _selectedCategoryRaw == 'all_categories';
  final isAnyPrice = _selectedPriceRaw == 'any_price';
  final isAllCities = _selectedCityRaw == 'all_cities';

  // Фильтр по категории
  if (!isAllCategories && _selectedCategoryRaw != null) {
    filtered = filtered.where((order) {
      final category = order['category']?['name']?.toString() ?? '';
      return category.toLowerCase().contains(
        _selectedCategoryRaw!.toLowerCase(),
      );
    }).toList();
  }

  // Фильтр по цене
  if (!isAnyPrice &&
      _selectedPriceRaw != null &&
      _selectedPriceRaw!.contains('-')) {
    try {
      final priceRange = _selectedPriceRaw!.replaceAll(' тг', '').split('-');
      final minPrice = double.tryParse(priceRange[0].trim()) ?? 0;
      final maxPrice =
          double.tryParse(priceRange[1].trim()) ?? double.infinity;
      filtered = filtered.where((order) {
        final priceStr = order['price']?.toString() ?? '0';
        final price = double.tryParse(priceStr) ?? 0;
        return price >= minPrice && price <= maxPrice;
      }).toList();
    } catch (e) {}
  }

  // Фильтр по городу (НОВЫЙ)
  if (!isAllCities && _selectedCityRaw != null) {
    filtered = filtered.where((order) {
      final city = order['city']?['name']?.toString() ?? '';
      return city.toLowerCase() == _selectedCityRaw!.toLowerCase();
    }).toList();
  }

  setState(() => _filteredOrders = filtered);
}

  void _applyFilters() {
    if (!mounted) return;

    List<dynamic> filtered = List.from(_orders);
    final appLocalizations = AppLocalizations.of(context);

    final isAllCategories = _selectedCategoryRaw == 'all_categories';
    final isAnyPrice = _selectedPriceRaw == 'any_price';
    final isAllCities =
        _selectedCityRaw == 'all_cities' || _selectedCityRaw == null;

    if (!isAllCategories && _selectedCategoryRaw != null) {
      filtered = filtered.where((order) {
        final category = order['category']?['name']?.toString() ?? '';
        return category.toLowerCase().contains(
          _selectedCategoryRaw!.toLowerCase(),
        );
      }).toList();
    }

    if (!isAnyPrice &&
        _selectedPriceRaw != null &&
        _selectedPriceRaw!.contains('-')) {
      try {
        final priceRange = _selectedPriceRaw!.replaceAll(' тг', '').split('-');
        final minPrice = double.tryParse(priceRange[0].trim()) ?? 0;
        final maxPrice =
            double.tryParse(priceRange[1].trim()) ?? double.infinity;
        filtered = filtered.where((order) {
          final priceStr = order['price']?.toString() ?? '0';
          final price = double.tryParse(priceStr) ?? 0;
          return price >= minPrice && price <= maxPrice;
        }).toList();
      } catch (e) {}
    }

    // Фильтр по городу
    if (!isAllCities && _selectedCityRaw != null) {
      filtered = filtered.where((order) {
        final city = order['city']?['name']?.toString() ?? '';
        return city.toLowerCase().contains(_selectedCityRaw!.toLowerCase());
      }).toList();
    }

    if (_selectedDate != null) {
      filtered = filtered.where((order) {
        if (order['created_at'] == null) return false;
        try {
          final orderDate = DateTime.parse(order['created_at']);
          return orderDate.year == _selectedDate!.year &&
              orderDate.month == _selectedDate!.month &&
              orderDate.day == _selectedDate!.day;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    setState(() => _filteredOrders = filtered);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations?.translate('failed_to_open_link') ?? 'Не удалось открыть ссылку'}: $url',
            ),
          ),
        );
      }
    }
  }

void _resetFilters() {
  final appLocalizations = AppLocalizations.of(context);
  setState(() {
    _selectedCategoryRaw = 'all_categories';
    _selectedPriceRaw = 'any_price';
    _selectedCityRaw = 'all_cities'; // Добавьте
    _selectedCategory = appLocalizations?.translate('all_categories') ?? 'Все категории';
    _selectedPrice = appLocalizations?.translate('any_price') ?? 'Любая стоимость';
    _selectedCity = appLocalizations?.translate('all_cities') ?? 'Все города'; // Добавьте
    _selectedDate = null;
  });
  _removeCategoryOverlay();
  _removePriceOverlay();
  _removeCityOverlay(); // Добавьте
  _fetchOrders();
}

  void _navigateToOrderDetail(Map<String, dynamic> order) {
    final appLocalizations = AppLocalizations.of(context);

    print(
      '🔍 Переход к заказу: _userDataLoaded=$_userDataLoaded, _hasSubscription=$_hasSubscription',
    );

    if (!_userDataLoaded) {
      print('⏳ Данные пользователя еще загружаются...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations?.translate('loading_profile') ??
                'Загрузка профиля...',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final orderId = order['id']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      print('✅ Открываем заказ с ID: $orderId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OrderClientPage(orderId: orderId, isMyOrder: false),
        ),
      );
    } else {
      print('❌ ID заказа не найден');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations?.translate('order_id_not_found') ??
                'ID заказа не найден',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhoneNumber(String phoneNumber) {
    final appLocalizations = AppLocalizations.of(context);

    print(
      '🔍 Показ телефона: _userDataLoaded=$_userDataLoaded, _hasSubscription=$_hasSubscription',
    );

    if (!_userDataLoaded) {
      print('⏳ Данные пользователя еще загружаются...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations?.translate('loading_profile') ??
                'Загрузка профиля...',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final hasSubscription = _hasActiveSubscription();
    print('🔍 Проверка подписки при показе телефона: $hasSubscription');

    if (!hasSubscription) {
      print('❌ Нет активной подписки, открываем QR код');
      _launchUrl(
        'https://qr.kaspi.kz/19134627698424934147714893150004931409130',
      );
      return;
    }

    print('✅ Подписка активна, показываем телефон: $phoneNumber');
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_rounded,
                  size: 48,
                  color: Color(0xFF0F7EDE),
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations?.translate('contact_phone') ??
                      'Контактный телефон',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appLocalizations?.translate('client_phone_number') ??
                      'Номер телефона клиента',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5F6368),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3F2FD)),
                  ),
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F7EDE),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5F6368),
                          side: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          appLocalizations?.translate('close') ?? 'Закрыть',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _launchUrl('tel:+$phoneNumber');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7EDE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          appLocalizations?.translate('call') ?? 'Позвонить',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleCategoryOverlay() {
    if (_categoryOverlayEntry != null) {
      _removeCategoryOverlay();
    } else {
      _removePriceOverlay();
      _removeCityOverlay();
      _showCategoryOverlay();
    }
  }

  void _showCategoryOverlay() {
    final appLocalizations = AppLocalizations.of(context);
    final renderBox =
        _categoryKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _categoryOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        child: CompositedTransformFollower(
          link: _categoryLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: size.width,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                    child: Row(
                      children: [
                        Text(
                          appLocalizations?.translate('category') ??
                              'Категория',
                          style: const TextStyle(
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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildCategoryItem(
                          'all_categories',
                          appLocalizations?.translate('all_categories') ??
                              'Все категории',
                        ),
                        ..._categories
                            .map(
                              (category) => _buildCategoryItem(
                                category['name'],
                                category['name'],
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_categoryOverlayEntry!);
  }

  Widget _buildCategoryItem(String rawValue, String displayName) {
    final isSelected = _selectedCategoryRaw == rawValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryRaw = rawValue;
          _selectedCategory = displayName;
        });
        _applyFilters();
        _removeCategoryOverlay();
      },
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
                displayName,
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

  void _removeCategoryOverlay() {
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
  }

  void _togglePriceOverlay() {
    if (_priceOverlayEntry != null) {
      _removePriceOverlay();
    } else {
      _removeCategoryOverlay();
      _removeCityOverlay();
      _showPriceOverlay();
    }
  }

  void _showPriceOverlay() {
    final appLocalizations = AppLocalizations.of(context);
    final renderBox =
        _priceKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    double minValue = 0;
    double maxValue = 100000;
    double currentMinValue = 0;
    double currentMaxValue = 100000;

    if (_selectedPriceRaw != null &&
        _selectedPriceRaw != 'any_price' &&
        _selectedPriceRaw!.contains('-')) {
      final parts = _selectedPriceRaw!.replaceAll(' тг', '').split('-');
      currentMinValue = double.tryParse(parts[0].trim()) ?? 0;
      currentMaxValue = double.tryParse(parts[1].trim()) ?? 100000;
    }

    _priceOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        child: CompositedTransformFollower(
          link: _priceLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Material(
                color: Colors.transparent,
                child: Container(
                  width: size.width * 1.5,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                        child: Row(
                          children: [
                            Text(
                              appLocalizations?.translate('price') ??
                                  'Стоимость',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _removePriceOverlay,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: currentMinValue
                                            .toInt()
                                            .toString(),
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            appLocalizations?.translate(
                                              'from',
                                            ) ??
                                            'От',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9E9E9E),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF41454A),
                                      ),
                                      onChanged: (value) {
                                        final doubleValue =
                                            double.tryParse(value) ?? 0;
                                        if (doubleValue <= currentMaxValue) {
                                          setState(
                                            () => currentMinValue = doubleValue,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '-',
                                  style: TextStyle(color: Color(0xFF5F6368)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: currentMaxValue
                                            .toInt()
                                            .toString(),
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            appLocalizations?.translate('to') ??
                                            'До',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9E9E9E),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF41454A),
                                      ),
                                      onChanged: (value) {
                                        final doubleValue =
                                            double.tryParse(value) ?? 100000;
                                        if (doubleValue >= currentMinValue) {
                                          setState(
                                            () => currentMaxValue = doubleValue,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  appLocalizations?.translate('tenge') ?? 'тг',
                                  style: const TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentMinValue.toInt()} ${appLocalizations?.translate('tenge') ?? 'тг'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                                Text(
                                  '${currentMaxValue.toInt()} ${appLocalizations?.translate('tenge') ?? 'тг'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RangeSlider(
                              values: RangeValues(
                                currentMinValue,
                                currentMaxValue,
                              ),
                              min: minValue,
                              max: maxValue,
                              divisions: 100,
                              activeColor: const Color(0xFF0F7EDE),
                              inactiveColor: const Color(0xFFE0E0E0),
                              onChanged: (values) {
                                setState(() {
                                  currentMinValue = values.start;
                                  currentMaxValue = values.end;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    currentMinValue = minValue;
                                    currentMaxValue = maxValue;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF5F6368),
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: Text(
                                  appLocalizations?.translate('reset') ??
                                      'Сбросить',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final appLocalizations = AppLocalizations.of(
                                    context,
                                  );
                                  setState(() {
                                    if (currentMinValue == minValue &&
                                        currentMaxValue == maxValue) {
                                      _selectedPriceRaw = 'any_price';
                                      _selectedPrice =
                                          appLocalizations?.translate(
                                            'any_price',
                                          ) ??
                                          'Любая стоимость';
                                    } else {
                                      final priceString =
                                          '${currentMinValue.toInt()} - ${currentMaxValue.toInt()} тг';
                                      _selectedPriceRaw = priceString;
                                      _selectedPrice = priceString;
                                    }
                                  });
                                  _applyFilters();
                                  _removePriceOverlay();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F7EDE),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  appLocalizations?.translate('apply') ??
                                      'Применить',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_priceOverlayEntry!);
  }

  void _removePriceOverlay() {
    _priceOverlayEntry?.remove();
    _priceOverlayEntry = null;
  }

void _toggleCityOverlay() {
  if (_cityOverlayEntry != null) {
    _removeCityOverlay();
  } else {
    _removeCategoryOverlay();
    _removePriceOverlay();
    _showCityOverlay();
  }
}


Widget _buildCityItem(String rawValue, String displayName) {
  final isSelected = _selectedCityRaw == rawValue;

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedCityRaw = rawValue;
        _selectedCity = displayName;
      });
      _applyLocalFilters();
      _removeCityOverlay();
    },
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
              displayName,
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

  void _removeCityOverlay() {
    _cityOverlayEntry?.remove();
    _cityOverlayEntry = null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F7EDE),
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F7EDE),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilterDisplayValues();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: false,
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
          title: Text(
            appLocalizations?.translate('work') ?? 'Работа',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            _buildLanguageButton(context, languageProvider, appLocalizations),
            IconButton(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh, color: Color(0xFF41454A)),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFiltersRow(appLocalizations),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator(appLocalizations)
                    : _errorMessage.isNotEmpty
                    ? _buildErrorWidget(appLocalizations)
                    : _filteredOrders.isEmpty
                    ? _buildEmptyState(appLocalizations)
                    : _buildOrdersList(appLocalizations),
              ),
            ],
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
              activeItem: NavItem.work,
              accountType: AccountType.master,
            ),
          ),
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
        _updateFilterDisplayValues();
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

void _showCityOverlay() {
  final appLocalizations = AppLocalizations.of(context);
  final renderBox = _cityKey.currentContext?.findRenderObject() as RenderBox?;
  final size = renderBox?.size ?? Size.zero;
  final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

  _cityOverlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      left: offset.dx,
      top: offset.dy + size.height + 4,
      child: CompositedTransformFollower(
        link: _cityLayerLink,
        showWhenUnlinked: false,
        offset: Offset(0, size.height + 4),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        appLocalizations?.translate('city') ?? 'Город',
                        style: const TextStyle(
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
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildCityItem(
                        'all_cities',
                        appLocalizations?.translate('all_cities') ?? 'Все города',
                      ),
                      ..._cities
                          .map(
                            (city) => _buildCityItem(
                              city['name'],
                              city['name'],
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(_cityOverlayEntry!);
}

  Widget _buildFiltersRow(AppLocalizations? appLocalizations) {
    final allCategories =
        appLocalizations?.translate('all_categories') ?? 'Все категории';
    final anyPrice =
        appLocalizations?.translate('any_price') ?? 'Любая стоимость';
    final allCities = appLocalizations?.translate('all_cities') ?? 'Все города';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Горизонтальный скролл для фильтров
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Фильтр по категории
                  CompositedTransformTarget(
                    link: _categoryLayerLink,
                    child: GestureDetector(
                      key: _categoryKey,
                      onTap: _toggleCategoryOverlay,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 140),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _categoryOverlayEntry != null
                                ? const Color(0xFF0F7EDE)
                                : const Color(0xFFCBCDCE),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 18,
                              color: Color(0xFF5F6368),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCategory ?? allCategories,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedCategoryRaw != 'all_categories'
                                    ? const Color(0xFF41454A)
                                    : const Color(0xFF9E9E9E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _categoryOverlayEntry != null
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 20,
                              color: const Color(0xFF5F6368),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Фильтр по цене
                  CompositedTransformTarget(
                    link: _priceLayerLink,
                    child: GestureDetector(
                      key: _priceKey,
                      onTap: _togglePriceOverlay,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 140),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _priceOverlayEntry != null
                                ? const Color(0xFF0F7EDE)
                                : const Color(0xFFCBCDCE),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_money_outlined,
                              size: 18,
                              color: Color(0xFF5F6368),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedPrice ?? anyPrice,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedPriceRaw != 'any_price'
                                    ? const Color(0xFF41454A)
                                    : const Color(0xFF9E9E9E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _priceOverlayEntry != null
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 20,
                              color: const Color(0xFF5F6368),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ФИЛЬТР ПО ГОРОДУ (НОВЫЙ)
                  CompositedTransformTarget(
                    link: _cityLayerLink,
                    child: GestureDetector(
                      key: _cityKey,
                      onTap: _toggleCityOverlay,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 140),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _cityOverlayEntry != null
                                ? const Color(0xFF0F7EDE)
                                : const Color(0xFFCBCDCE),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Color(0xFF5F6368),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCity ?? allCities,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedCityRaw != 'all_cities'
                                    ? const Color(0xFF41454A)
                                    : const Color(0xFF9E9E9E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _cityOverlayEntry != null
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 20,
                              color: const Color(0xFF5F6368),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Фильтр по дате
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFCBCDCE),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFF5F6368),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                                : appLocalizations?.translate('date') ?? 'Дата',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedDate != null
                                  ? const Color(0xFF41454A)
                                  : const Color(0xFF9E9E9E),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: Color(0xFF5F6368),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Кнопка сброса
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _resetFilters,
            child: Container(
              height: 39,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color:
                    (_selectedCategoryRaw != 'all_categories' ||
                        _selectedPriceRaw != 'any_price' ||
                        _selectedCityRaw != 'all_cities' ||
                        _selectedDate != null)
                    ? const Color(0xFF0F7EDE)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (_selectedCategoryRaw != 'all_categories' ||
                          _selectedPriceRaw != 'any_price' ||
                          _selectedCityRaw != 'all_cities' ||
                          _selectedDate != null)
                      ? const Color(0xFF0F7EDE)
                      : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.clear_all,
                    size: 18,
                    color:
                        (_selectedCategoryRaw != 'all_categories' ||
                            _selectedPriceRaw != 'any_price' ||
                            _selectedCityRaw != 'all_cities' ||
                            _selectedDate != null)
                        ? Colors.white
                        : const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appLocalizations?.translate('reset') ?? 'Сбросить',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          (_selectedCategoryRaw != 'all_categories' ||
                              _selectedPriceRaw != 'any_price' ||
                              _selectedCityRaw != 'all_cities' ||
                              _selectedDate != null)
                          ? Colors.white
                          : const Color(0xFF9E9E9E),
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(AppLocalizations? appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0F7EDE)),
          const SizedBox(height: 16),
          Text(
            appLocalizations?.translate('loading_orders') ??
                'Загрузка заказов...',
            style: const TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(AppLocalizations? appLocalizations) {
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
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F6368),
                fontSize: 16,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchOrders,
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

  Widget _buildEmptyState(AppLocalizations? appLocalizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline,
                color: Color(0xFF0F7EDE),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations?.translate('no_orders_found') ??
                  'Заказы не найдены',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations?.translate('change_filters_or_check_later') ??
                  'Измените параметры фильтра или проверьте позже',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            if (_selectedCategoryRaw != 'all_categories' ||
                _selectedPriceRaw != 'any_price' ||
                _selectedCityRaw != 'all_cities' ||
                _selectedDate != null)
              const SizedBox(height: 24),
            if (_selectedCategoryRaw != 'all_categories' ||
                _selectedPriceRaw != 'any_price' ||
                _selectedCityRaw != 'all_cities' ||
                _selectedDate != null)
              ElevatedButton(
                onPressed: _resetFilters,
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
                child: Text(
                  appLocalizations?.translate('reset_filters') ??
                      'Сбросить фильтры',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(AppLocalizations? appLocalizations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return GestureDetector(
          onTap: () => _navigateToOrderDetail(order),
          child: _buildOrderItem(order, appLocalizations),
        );
      },
    );
  }

  Widget _buildOrderItem(
    Map<String, dynamic> order,
    AppLocalizations? appLocalizations,
  ) {
    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (e) {
        return dateString;
      }
    }

    String formatPrice(String price) {
      try {
        final number = double.parse(price);
        final formatted = number.toStringAsFixed(2);
        final parts = formatted.split('.');
        final integerPart = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
        return '$integerPart ${appLocalizations?.translate('tenge') ?? 'тг'}';
      } catch (e) {
        return '$price ${appLocalizations?.translate('tenge') ?? 'тг'}';
      }
    }

    String? getFirstImage() {
      final images = order['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final image = images[0];
        return image is String ? image : null;
      }
      return null;
    }

    return GestureDetector(
      onTap: () => _navigateToOrderDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFF8FBFF),
                    ),
                    child: getFirstImage() != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'http://gj-back.checkedout.kz/storage/${getFirstImage()}',
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFF8FBFF),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFFCBCDCE),
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFFCBCDCE),
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['title']?.toString() ??
                              appLocalizations?.translate('untitled') ??
                              'Без названия',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (order['category'] != null &&
                            order['category']['name'] != null)
                          Text(
                            order['category']['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          formatPrice(order['price']?.toString() ?? '0'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F7EDE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (order['city'] != null &&
                            order['city']['name'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE3F2FD),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: Color(0xFF0F7EDE),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order['city']['name'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0F7EDE),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFFE3F2FD), width: 1),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF5F6368),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(order['createdAt']?.toString() ?? ''),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5F6368),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (order['telephone'] != null &&
                      order['telephone'].toString().isNotEmpty)
                    OutlinedButton(
                      onPressed: () {
                        if (_hasActiveSubscription()) {
                          _showPhoneNumber(order['telephone'].toString());
                        } else {
                          print('❌ Нет активной подписки, открываем QR код');
                          _launchUrl(
                            'https://qr.kaspi.kz/19134627698424934147714893150004931409130',
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F7EDE),
                        side: const BorderSide(
                          color: Color(0xFF0F7EDE),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            appLocalizations?.translate('show_phone') ??
                                'Показать телефон',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionSuccessPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appLocalizations?.translate('no_subscription') ??
                                'Нет подписки',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
