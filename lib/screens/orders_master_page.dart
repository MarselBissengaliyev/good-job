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

  // Списки для выпадающих меню
  final List<String> _categories = [
    'Все категории',
    'Ремонт',
    'Сантехника',
    'Электрика',
    'Отделочные работы',
    'Строительство'
  ];

  // Контроллеры для модалки стоимости
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Для управления модалками
  bool _showCategoryModal = false;
  bool _showPriceModal = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  // Функция для получения заказов с сервера
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getOrders();
      final List<dynamic> orders = response['data'] ?? [];
      
      setState(() {
        _orders = orders;
        _filteredOrders = List.from(orders);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Функция для фильтрации заказов
  void _applyFilters() {
    List<dynamic> filtered = List.from(_orders);

    // Фильтрация по категории
    if (_selectedCategory != null && _selectedCategory != 'Все категории') {
      filtered = filtered.where((order) {
        final category = order['category']?['name']?.toString() ?? '';
        return category.toLowerCase().contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    // Фильтрация по стоимости
    if (_selectedPrice != null && _selectedPrice != 'Любая стоимость') {
      if (_selectedPrice!.contains('-')) {
        try {
          final priceRange = _selectedPrice!.replaceAll(' тг', '').split('-');
          final minPrice = double.tryParse(priceRange[0].trim()) ?? 0;
          final maxPrice = double.tryParse(priceRange[1].trim()) ?? double.infinity;
          
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
      _filteredOrders = List.from(_orders);
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  // Функция для показа номера телефона
  void _showPhoneNumber(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Контактный телефон',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Номер телефона клиента:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                phoneNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F7EDE),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 16),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Закрыть'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Логика для звонка
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Вызов инициирован...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7EDE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Позвонить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                      SizedBox(
                        height: 39,
                        child: _buildCategoryButton(),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Селект "Стоимость"
                      SizedBox(
                        height: 39,
                        child: _buildPriceButton(),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Датапикер
                      SizedBox(
                        height: 39,
                        child: _buildDatePicker(),
                      ),

                      const SizedBox(width: 12),

                      // Кнопка сброса фильтров
                      if (_selectedCategory != 'Все категории' || 
                          _selectedPrice != 'Любая стоимость' || 
                          _selectedDate != null)
                        SizedBox(
                          height: 39,
                          child: GestureDetector(
                            onTap: _resetFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBCDCE), width: 1),
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
        ),

        // Блюр при открытых модалках
        if (_showCategoryModal || _showPriceModal)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showCategoryModal = false;
                  _showPriceModal = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.srcOver,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Модалка для категории
        if (_showCategoryModal)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildCategoryModal(),
          ),

        // Модалка для стоимости
        if (_showPriceModal)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildPriceModal(),
          ),
      ],
    );
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
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.work_outline,
            color: Color(0xFFCBCDCE),
            size: 100,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Сбросить фильтры'),
            ),
        ],
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

  // Кнопка категории
  Widget _buildCategoryButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showCategoryModal = true;
          _showPriceModal = false;
        });
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 140,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBCDCE), width: 1),
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
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Color(0xFF5F6368),
            ),
          ],
        ),
      ),
    );
  }

  // Кнопка стоимости
  Widget _buildPriceButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showPriceModal = true;
          _showCategoryModal = false;
        });
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 140,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBCDCE), width: 1),
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
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Color(0xFF5F6368),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для выбора даты
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () {
        _selectDate(context);
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 140,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBCDCE), width: 1),
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
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  // Модалка для категории
  Widget _buildCategoryModal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Категория',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCategoryModal = false;
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF41454A),
                  ),
                ),
              ],
            ),
          ),

          // Список категорий
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _showCategoryModal = false;
                      _applyFilters();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedCategory == category
                                  ? const Color(0xFF0F7EDE)
                                  : const Color(0xFFCBCDCE),
                              width: 2,
                            ),
                            color: _selectedCategory == category
                                ? const Color(0xFF0F7EDE)
                                : Colors.white,
                          ),
                          child: _selectedCategory == category
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCategory == category
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
              },
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
                        _selectedCategory = 'Все категории';
                        _showCategoryModal = false;
                        _applyFilters();
                      });
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
                    child: const Text(
                      'Сбросить',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showCategoryModal = false;
                        _applyFilters();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7EDE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Модалка для стоимости с RangeSlider
  Widget _buildPriceModal() {
    double _currentMinValue = 0;
    double _currentMaxValue = 100000;
    double _minPrice = 0;
    double _maxPrice = 100000;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFEEEEEE),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Стоимость',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPriceModal = false;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF41454A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Контент
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Поля ввода для точного значения
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              child: TextField(
                                controller: TextEditingController(
                                  text: _currentMinValue.toInt().toString(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final doubleValue = double.tryParse(value) ?? _currentMinValue;
                                  if (doubleValue >= _minPrice && doubleValue <= _currentMaxValue) {
                                    setState(() {
                                      _currentMinValue = doubleValue;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'От',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBCDCE),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBCDCE),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F7EDE),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF41454A),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 48,
                              child: TextField(
                                controller: TextEditingController(
                                  text: _currentMaxValue.toInt().toString(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final doubleValue = double.tryParse(value) ?? _currentMaxValue;
                                  if (doubleValue >= _currentMinValue && doubleValue <= _maxPrice) {
                                    setState(() {
                                      _currentMaxValue = doubleValue;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'До',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBCDCE),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBCDCE),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F7EDE),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Labels for slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentMinValue.toInt()} тг',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          Text(
                            '${_currentMaxValue.toInt()} тг',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Сам слайдер
                      RangeSlider(
                        values: RangeValues(_currentMinValue, _currentMaxValue),
                        min: _minPrice,
                        max: _maxPrice,
                        divisions: 20,
                        labels: RangeLabels(
                          '${_currentMinValue.toInt()} тг',
                          '${_currentMaxValue.toInt()} тг',
                        ),
                        activeColor: const Color(0xFF0F7EDE),
                        inactiveColor: const Color(0xFFE0E0E0),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _currentMinValue = values.start;
                            _currentMaxValue = values.end;
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
                              _currentMinValue = _minPrice;
                              _currentMaxValue = _maxPrice;
                              _selectedPrice = 'Любая стоимость';
                              _showPriceModal = false;
                              _applyFilters();
                            });
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
                          child: const Text(
                            'Сбросить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final minPrice = _currentMinValue.toInt();
                            final maxPrice = _currentMaxValue.toInt();

                            setState(() {
                              _selectedPrice = '$minPrice - $maxPrice тг';
                              _showPriceModal = false;
                              _applyFilters();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F7EDE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Сохранить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Plus Jakarta Sans',
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
        );
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
                    color: const Color(0xFFF5F5F5),
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
                                color: const Color(0xFFF5F5F5),
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
                      if (order['category'] != null && order['category']['name'] != null)
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
                      Row(
                        children: [
                          if (order['city'] != null && order['city']['name'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order['city']['name'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5F6368),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
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
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Кнопка "Показать телефон"
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showPhoneNumber(order['telephone']?.toString() ?? '+7 (777) 123-45-67');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F7EDE),
                      side: const BorderSide(
                        color: Color(0xFF0F7EDE),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Показать телефон',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Дата
                Text(
                  formatDate(order['createdAt']?.toString() ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                    fontFamily: 'Plus Jakarta Sans',
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