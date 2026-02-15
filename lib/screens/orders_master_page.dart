import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/api_service.dart';

class OrdersMasterPage extends StatefulWidget {
  const OrdersMasterPage({super.key});

  @override
  State<OrdersMasterPage> createState() => _OrdersMasterPageState();
}

class _OrdersMasterPageState extends State<OrdersMasterPage> {
  // Списки для заказов
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Значения для селектов
  String? _selectedCategory = 'Все категории';
  String? _selectedPrice = 'Любая стоимость';
  DateTime? _selectedDate;

  // Списки для выпадающих меню - ИЗМЕНЕНО: теперь храним объекты категорий
  List<Map<String, dynamic>> _categories = [];

  // Для управления модалками
  OverlayEntry? _categoryOverlayEntry;
  OverlayEntry? _priceOverlayEntry;
  final LayerLink _categoryLayerLink = LayerLink();
  final LayerLink _priceLayerLink = LayerLink();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _priceKey = GlobalKey();

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = List<Map<String, dynamic>>.from(categories);
      });
    } catch (e) {
      _showError('Ошибка загрузки категорий: $e');
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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchOrders();
  }

  @override
  void dispose() {
    _removeCategoryOverlay();
    _removePriceOverlay();
    super.dispose();
  }

  // Функция для получения заказов с сервера
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> response;

      // Если выбрана дата, передаем её в API
      if (_selectedDate != null) {
        // Создаем даты для начала и конца выбранного дня
        final startOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          0,
          0, // 00:00
        );
        final endOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          23,
          59, // 23:59
        );

        response = await ApiService.getOrders(
          startDate: startOfDay,
          endDate: endOfDay,
        );
      } else {
        // Если дата не выбрана, получаем все заказы
        response = await ApiService.getOrders();
      }

      final List<dynamic> orders = response['data'] ?? [];
      print("orders $orders");

      setState(() {
        _orders = orders;
        _filteredOrders = List.from(orders);
        _isLoading = false;
      });

      // После загрузки применяем локальные фильтры (категория и цена)
      _applyLocalFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _applyLocalFilters() {
    List<dynamic> filtered = List.from(_orders);

    // Фильтрация по категории
    if (_selectedCategory != null && _selectedCategory != 'Все категории') {
      filtered = filtered.where((order) {
        final category = order['category']?['name']?.toString() ?? '';
        return category.toLowerCase().contains(
          _selectedCategory!.toLowerCase(),
        );
      }).toList();
    }

    // Фильтрация по стоимости
    if (_selectedPrice != null && _selectedPrice != 'Любая стоимость') {
      if (_selectedPrice!.contains('-')) {
        try {
          final priceRange = _selectedPrice!.replaceAll(' тг', '').split('-');
          final minPrice = double.tryParse(priceRange[0].trim()) ?? 0;
          final maxPrice =
              double.tryParse(priceRange[1].trim()) ?? double.infinity;

          filtered = filtered.where((order) {
            final priceStr = order['price']?.toString() ?? '0';
            final price = double.tryParse(priceStr) ?? 0;
            return price >= minPrice && price <= maxPrice;
          }).toList();
        } catch (e) {
          print('Ошибка при парсинге диапазона цен: $e');
        }
      }
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  // Функция для фильтрации заказов
  void _applyFilters() {
    List<dynamic> filtered = List.from(_orders);

    // Фильтрация по категории
    if (_selectedCategory != null && _selectedCategory != 'Все категории') {
      filtered = filtered.where((order) {
        final category = order['category']?['name']?.toString() ?? '';
        return category.toLowerCase().contains(
          _selectedCategory!.toLowerCase(),
        );
      }).toList();
    }

    // Фильтрация по стоимости
    if (_selectedPrice != null && _selectedPrice != 'Любая стоимость') {
      if (_selectedPrice!.contains('-')) {
        try {
          final priceRange = _selectedPrice!.replaceAll(' тг', '').split('-');
          final minPrice = double.tryParse(priceRange[0].trim()) ?? 0;
          final maxPrice =
              double.tryParse(priceRange[1].trim()) ?? double.infinity;

          filtered = filtered.where((order) {
            final priceStr = order['price']?.toString() ?? '0';
            final price = double.tryParse(priceStr) ?? 0;
            return price >= minPrice && price <= maxPrice;
          }).toList();
        } catch (e) {
          print('Ошибка при парсинге диапазона цен: $e');
        }
      }
    }

    // Фильтрация по дате
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

    setState(() {
      _filteredOrders = filtered;
    });
  }

  // Функция для сброса фильтров
  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Все категории';
      _selectedPrice = 'Любая стоимость';
      _selectedDate = null;
    });
    _removeCategoryOverlay();
    _removePriceOverlay();
    // Загружаем все заказы без фильтрации по дате
    _fetchOrders();
  }

  // Функция для показа номера телефона
  void _showPhoneNumber(String phoneNumber) {
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
                const Text(
                  'Контактный телефон',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Номер телефона клиента',
                  style: TextStyle(
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
                    border: Border.all(color: Color(0xFFE3F2FD)),
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
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
                        child: const Text('Закрыть'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Вызов инициирован...'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
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
                        child: const Text('Позвонить'),
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

  // Управление оверлеями для категории
  void _toggleCategoryOverlay() {
    if (_categoryOverlayEntry != null) {
      _removeCategoryOverlay();
    } else {
      _removePriceOverlay();
      _showCategoryOverlay();
    }
  }

  // ИСПРАВЛЕНО: метод для отображения категорий
  void _showCategoryOverlay() {
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

                  // ИСПРАВЛЕНО: Список категорий с опцией "Все категории"
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // Опция "Все категории"
                        _buildCategoryItem('Все категории', 'Все категории'),
                        // Категории из API
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

  // ИСПРАВЛЕНО: метод для построения элемента категории
  Widget _buildCategoryItem(String? categoryValue, String displayName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = displayName;
        });
        _applyFilters();
        _removeCategoryOverlay();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: _selectedCategory == displayName
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
                  color: _selectedCategory == displayName
                      ? const Color(0xFF0F7EDE)
                      : const Color(0xFFCBCDCE),
                  width: 1.5,
                ),
                color: _selectedCategory == displayName
                    ? const Color(0xFF0F7EDE)
                    : Colors.white,
              ),
              child: _selectedCategory == displayName
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedCategory == displayName
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

  // Управление оверлеями для стоимости
  void _togglePriceOverlay() {
    if (_priceOverlayEntry != null) {
      _removePriceOverlay();
    } else {
      _removeCategoryOverlay();
      _showPriceOverlay();
    }
  }

  void _showPriceOverlay() {
    final renderBox =
        _priceKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    double minValue = 0;
    double maxValue = 100000;
    double currentMinValue = 0;
    double currentMaxValue = 100000;

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
                      // Заголовок
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                        child: Row(
                          children: [
                            const Text(
                              'Стоимость',
                              style: TextStyle(
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

                      // Диапазон цен
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Текстовые поля
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
                                      decoration: InputDecoration(
                                        hintText: 'От',
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
                                          setState(() {
                                            currentMinValue = doubleValue;
                                          });
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
                                      decoration: InputDecoration(
                                        hintText: 'До',
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
                                          setState(() {
                                            currentMaxValue = doubleValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'тг',
                                  style: TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Цифровые значения
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentMinValue.toInt()} тг',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                                Text(
                                  '${currentMaxValue.toInt()} тг',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Слайдер
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

                      // Кнопки
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
                                child: const Text(
                                  'Сбросить',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedPrice =
                                        currentMinValue == minValue &&
                                            currentMaxValue == maxValue
                                        ? 'Любая стоимость'
                                        : '${currentMinValue.toInt()} - ${currentMaxValue.toInt()} тг';
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
                                child: const Text(
                                  'Применить',
                                  style: TextStyle(fontSize: 14),
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
          'Работа',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh, color: Color(0xFF41454A)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтры (селекты и датапикер)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Селект "Категория"
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
                              _selectedCategory!,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedCategory != 'Все категории'
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

                  // Селект "Стоимость"
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
                              _selectedPrice!,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedPrice != 'Любая стоимость'
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

                  // Датапикер
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
                                : 'Дата',
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

                  const SizedBox(width: 12),

                  // Кнопка сброса фильтров
                  if (_selectedCategory != 'Все категории' ||
                      _selectedPrice != 'Любая стоимость' ||
                      _selectedDate != null)
                    GestureDetector(
                      onTap: _resetFilters,
                      child: Container(
                        height: 39,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFCBCDCE),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.clear_all,
                              size: 18,
                              color: Color(0xFF5F6368),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Сбросить',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Контент (загрузка/ошибка/список заказов)
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.work,
        accountType: AccountType.master,
      ),
    );
  }

  // Функция для выбора даты
  Future<void> _selectDate(BuildContext context) async {
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
      setState(() {
        _selectedDate = picked;
      });
      // Загружаем заказы с фильтрацией по дате
      _fetchOrders();
    }
  }

  // Виджет загрузки
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF0F7EDE)),
          SizedBox(height: 16),
          Text(
            'Загрузка заказов...',
            style: TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  // Виджет ошибки
  Widget _buildErrorWidget() {
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
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет пустого состояния
  Widget _buildEmptyState() {
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
            const Text(
              'Заказы не найдены',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Измените параметры фильтра или проверьте позже',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedCategory != 'Все категории' ||
                _selectedPrice != 'Любая стоимость' ||
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
                child: const Text('Сбросить фильтры'),
              ),
          ],
        ),
      ),
    );
  }

  // Список заказов
  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderItem(order);
      },
    );
  }

  // Виджет для элемента списка заказов
  Widget _buildOrderItem(Map<String, dynamic> order) {
    // Форматирование даты
    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (e) {
        return dateString;
      }
    }

    // Форматирование цены
    String formatPrice(String price) {
      try {
        final number = double.parse(price);
        final formatted = number.toStringAsFixed(2);
        final parts = formatted.split('.');
        final integerPart = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
        return '$integerPart тг';
      } catch (e) {
        return '$price тг';
      }
    }

    // Получение первого изображения
    String? getFirstImage() {
      final images = order['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final image = images[0];
        return image is String ? image : null;
      }
      return null;
    }

    return Container(
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
                // Изображение
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

                // Текстовая информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок
                      Text(
                        order['title']?.toString() ?? 'Без названия',
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

                      // Категория
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

                      // Цена
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

                      // Категория и город
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Нижняя часть с кнопкой и датой
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
                // Дата
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

                // Кнопка "Показать телефон"
                OutlinedButton(
                  onPressed: () {
                    _showPhoneNumber(
                      order['telephone']?.toString() ?? '+7 (777) 123-45-67',
                    );
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
                  child: const Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Показать телефон',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
