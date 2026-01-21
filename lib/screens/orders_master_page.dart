import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'edit_portfolio_master_page.dart';

class OrdersMasterPage extends StatefulWidget {
  const OrdersMasterPage({super.key});

  @override
  State<OrdersMasterPage> createState() => _OrdersMasterPageState();
}

class _OrdersMasterPageState extends State<OrdersMasterPage> {
  // Данные для примеров заказов
  final List<Map<String, dynamic>> _orders = [
    {
      'image': 'assets/work_sample.png',
      'title': 'Укладка плитки в ванной комнате',
      'description': 'Плиточные работы',
      'price': '50 000 тг',
      'date': '26.11.2025',
      'category': 'Ремонт',
      'status': 'Новый',
    },
    {
      'image': 'assets/work_sample.png',
      'title': 'Установка натяжных потолков',
      'description': 'Потолочные работы',
      'price': '75 000 тг',
      'date': '25.11.2025',
      'category': 'Ремонт',
      'status': 'В работе',
    },
    {
      'image': 'assets/work_sample.png',
      'title': 'Покраска стен в квартире',
      'description': 'Малярные работы',
      'price': '35 000 тг',
      'date': '24.11.2025',
      'category': 'Ремонт',
      'status': 'Завершен',
    },
    {
      'image': 'assets/work_sample.png',
      'title': 'Монтаж гипсокартонных перегородок',
      'description': 'Отделочные работы',
      'price': '90 000 тг',
      'date': '23.11.2025',
      'category': 'Ремонт',
      'status': 'Новый',
    },
    {
      'image': 'assets/work_sample.png',
      'title': 'Установка сантехники',
      'description': 'Сантехнические работы',
      'price': '60 000 тг',
      'date': '22.11.2025',
      'category': 'Сантехника',
      'status': 'В работе',
    },
  ];

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
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
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
                onPressed: () {
                  // Можно добавить логику для истории
                },
                icon: Image.asset('assets/history.png', width: 22, height: 22),
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
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Список заказов
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderItem(order);
                  },
                ),
              ),
            ],
          ),
          
          // Bottom Navigation Bar
          bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.work, // Указываем активную вкладку
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
                  child: Image.asset(
                    'assets/close.png',
                    width: 24,
                    height: 24,
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

  // Модалка для стоимости
 // Модалка для стоимости
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
                      child: Image.asset(
                        'assets/close.png',
                        width: 24,
                        height: 24,
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
                    // Range Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
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
                            divisions: 20, // Количество делений
                            labels: RangeLabels(
                              '${_currentMinValue.toInt()} тг',
                              '${_currentMaxValue.toInt()} тг',
                            ),
                            activeColor: const Color(0xFF0F7EDE), // Цвет активной части (между точками)
                            inactiveColor: const Color(0xFFE0E0E0), // Цвет неактивной части
                            onChanged: (RangeValues values) {
                              setState(() {
                                _currentMinValue = values.start;
                                _currentMaxValue = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                        ],
                      ),
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
                    image: const DecorationImage(
                      image: AssetImage('assets/work_sample.png'),
                      fit: BoxFit.cover,
                    ),
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
                        order['title'],
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
                      
                      // Описание
                      Text(
                        order['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F6368),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Цена
                      Text(
                        order['price'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F7EDE),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Категория и статус
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order['category'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0F7EDE),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order['status']),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order['status'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusTextColor(order['status']),
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
                      _showPhoneNumber();
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
                  order['date'],
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
      });
    }
  }

  // Функция для показа номера телефона
  void _showPhoneNumber() {
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
              const Text(
                '+7 (777) 123-45-67',
                style: TextStyle(
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

  // Функции для цветов статусов
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Новый':
        return const Color(0xFFE8F4FF);
      case 'В работе':
        return const Color(0xFFFFF8E1);
      case 'Завершен':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Новый':
        return const Color(0xFF0F7EDE);
      case 'В работе':
        return const Color(0xFFFF9800);
      case 'Завершен':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF5F6368);
    }
  }
}