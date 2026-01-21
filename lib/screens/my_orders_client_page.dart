import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';

import 'add_order_client_page.dart';
import 'edit_portfolio_master_page.dart';
import 'order_client_page.dart'; // Добавляем импорт страницы деталей заказа

class MyOrdersClientPage extends StatefulWidget {
  const MyOrdersClientPage({super.key});

  @override
  State<MyOrdersClientPage> createState() => _MyOrdersClientPageState();
}

class _MyOrdersClientPageState extends State<MyOrdersClientPage> {
  // Данные для примеров заказов
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '1',
      'image': 'assets/work_sample.png',
      'title': 'Укладка плитки в ванной комнате',
      'description': 'Плиточные работы',
      'price': '50 000 тг',
      'date': '26.11.2025',
      'category': 'Ремонт',
      'status': 'Активен',
      'isActive': true,
      'fullDescription': 'Полная детальная информация о заказе. Требуется укладка плитки в ванной комнате размером 3x3 метра. Материал уже закуплен заказчиком. Необходимо качественно выполнить работы в течение 3 дней.',
      'address': 'г. Алматы, ул. Абая 12',
      'deadline': '30.11.2025',
      'phone': '+7 777 123 45 67',
    },
    {
      'id': '2',
      'image': 'assets/work_sample.png',
      'title': 'Установка натяжных потолков',
      'description': 'Потолочные работы',
      'price': '75 000 тг',
      'date': '25.11.2025',
      'category': 'Ремонт',
      'status': 'Не активен',
      'isActive': false,
      'fullDescription': 'Требуется установка натяжных потолков в гостиной и спальне. Общая площадь 45 кв.м. Цвет матовый белый. Необходимо также установить светильники.',
      'address': 'г. Алматы, мкр. Коктем-1',
      'deadline': '05.12.2025',
      'phone': '+7 777 765 43 21',
    },
  ];

  void _openOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderClientPage(order: order),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    // Получаем значение isActive, обрабатывая null
    final isActive = order['isActive'] == true;

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
          // Обертка для кликабельной области (изображение и текст)
          GestureDetector(
            onTap: () {
              _openOrderDetails(order);
            },
            child: Padding(
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
                          order['title'] ?? '',
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
                          order['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F6368),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Цена
                        Text(
                          order['price'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
          ),

          // Нижняя часть со статусом и кнопками (не кликабельная)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Статус
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order['status'] ?? 'Не определен',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF9E9E9E),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),

                const Spacer(),

                // Кнопка "Опубликовать"
                if (!isActive)
                  OutlinedButton(
                    onPressed: () {
                      // Логика публикации
                      _publishOrder(order);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5F6368),
                      side: const BorderSide(
                        color: Color(0xFF5F6368),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Опубликовать',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Кнопка меню
                GestureDetector(
                  onTap: () {
                    _showOrderOptionsModal(context, order);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEEEEEE),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/more.png',
                        width: 20,
                        height: 20,
                        color: const Color(0xFF5F6368),
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

  void _addNewOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddOrderClientPage()),
    );
  }

  void _showOrderOptionsModal(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(bottom: 80),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок и кнопка закрытия
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Объявление',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/close.png',
                            width: 16,
                            height: 16,
                            color: const Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Список опций
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Редактировать
                    _buildOptionButton(
                      icon: 'assets/edit.png',
                      text: 'Редактировать',
                      onTap: () {
                        Navigator.pop(context);
                        _editOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Отозвать публикацию
                    _buildOptionButton(
                      icon: 'assets/chat_error.png',
                      text: 'Отозвать публикацию',
                      onTap: () {
                        Navigator.pop(context);
                        _unpublishOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Архивировать
                    _buildOptionButton(
                      icon: 'assets/archive.png',
                      text: 'Архивировать',
                      onTap: () {
                        Navigator.pop(context);
                        _archiveOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Удалить
                    _buildOptionButton(
                      icon: 'assets/delete.png',
                      text: 'Удалить',
                      onTap: () {
                        Navigator.pop(context);
                        _deleteOrder(order);
                      },
                      isDelete: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
              color: isDelete
                  ? const Color(0xFFF44336)
                  : const Color(0xFF41454A),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDelete
                    ? const Color(0xFFF44336)
                    : const Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _publishOrder(Map<String, dynamic> order) {
    setState(() {
      order['isActive'] = true;
      order['status'] = 'Активен';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Объявление опубликовано'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editOrder(Map<String, dynamic> order) {
    // Логика редактирования заказа
    print('Редактирование заказа: ${order['title']}');
  }

  void _unpublishOrder(Map<String, dynamic> order) {
    setState(() {
      order['isActive'] = false;
      order['status'] = 'Не активен';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Публикация отозвана'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _archiveOrder(Map<String, dynamic> order) {
    // Логика архивации
    print('Архивация заказа: ${order['title']}');
  }

  void _deleteOrder(Map<String, dynamic> order) {
    // Логика удаления с подтверждением
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить объявление?'),
          content: const Text('Вы уверены, что хотите удалить это объявление?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Здесь должна быть логика удаления из списка
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Объявление удалено'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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
          'Мои заказы',
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
        children: [
          // Фильтры (селекты и датапикер) - если есть
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

          // Кнопка "Добавить заказ" перед нижней навигацией
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ElevatedButton(
              onPressed: _addNewOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7EDE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFF0F7EDE),
                    width: 1,
                  ),
                ),
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
              child: const Text(
                'Добавить заказ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
    bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.orders, // Указываем активную вкладку
        accountType: AccountType.client,
      ),
    );
  }
}