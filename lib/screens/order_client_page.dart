import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/screens/interested_in_order_page.dart';

import 'edit_portfolio_master_page.dart';

class OrderClientPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderClientPage({super.key, required this.order});

  @override
  State<OrderClientPage> createState() => _OrderClientPageState();
}

class _OrderClientPageState extends State<OrderClientPage> {
  // Пример данных для просмотров
  final List<Map<String, dynamic>> _viewers = [
    {
      'name': 'Константин Константинов',
      'specialty': 'Плиточные работы, отделочные работы',
      'avatar': 'assets/avatar.png',
      'id': '1',
      'rating': 4.8,
      'reviews': 24,
    },
    {
      'name': 'Алексей Мастеров',
      'specialty': 'Сантехнические работы',
      'avatar': 'assets/avatar.png',
      'id': '2',
      'rating': 4.5,
      'reviews': 18,
    },
  ];

  // Метод для перехода на страницу interested_in_page
  void _openInterestedInPage(Map<String, dynamic> viewer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterestedInOrderPage(
          viewer: viewer,
          order: widget.order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order; // Получаем данные заказа

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная карточка с информацией о заказе
            Container(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Изображение заказа
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage('assets/work_sample.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Заголовок
                    Text(
                      order['title'] ?? 'Укладка плитки в ванной комнате',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Описание и цена в ряд
                    Row(
                      children: [
                        // Описание слева
                        Expanded(
                          child: Text(
                            order['description'] ?? 'Плиточные работы',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),

                        // Цена справа
                        Text(
                          order['price'] ?? '50 000 тг',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F7EDE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Подробное описание работы
                    Text(
                      order['fullDescription'] ??
                          'Нужно уложить плитку в ванной комнате. Площадь — примерно 5–6 м². Требуется снять старую плитку, подготовить стены и пол, выровнять поверхность и аккуратно уложить новую плитку (настенную и напольную). Хочу, чтобы швы были ровные, без сколов и перепадов. Также нужна затирка и герметизация мест вокруг ванны и раковины. Материал уже куплен, нужен аккуратный и опытный мастер.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Футер с кнопками
                    Container(
                      padding: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Статус "Активен"
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1DCE6A),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              order['status'] ?? 'Активен',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1DCE6A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Кнопка "Отозвать"
                          if (order['isActive'] == true)
                            OutlinedButton(
                              onPressed: () {
                                // Логика отзыва публикации
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
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Отозвать',
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
              ),
            ),

            const SizedBox(height: 34), // Отступ 34 пикселя
            // Секция "Просмотрено"
            const Text(
              'Просмотрено',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),

            const SizedBox(height: 24),

            // Список просмотров
            Column(
              children: List.generate(_viewers.length, (index) {
                final viewer = _viewers[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _viewers.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _openInterestedInPage(viewer);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Аватарка
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBC696),
                                borderRadius: BorderRadius.circular(21),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(21),
                                child: Image.asset(
                                  viewer['avatar'],
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Информация о просмотревшем
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Имя
                                  Text(
                                    viewer['name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF41454A),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  // Специальность
                                  Text(
                                    viewer['specialty'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color: Color(0xFF5F6368),
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
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.work, // Указываем активную вкладку
        accountType: AccountType.client,
      ),
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
                        // _editOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Отозвать публикацию
                    _buildOptionButton(
                      icon: 'assets/chat_error.png',
                      text: 'Отозвать публикацию',
                      onTap: () {
                        Navigator.pop(context);
                        // _unpublishOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Архивировать
                    _buildOptionButton(
                      icon: 'assets/archive.png',
                      text: 'Архивировать',
                      onTap: () {
                        Navigator.pop(context);
                        // _archiveOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Удалить
                    _buildOptionButton(
                      icon: 'assets/delete.png',
                      text: 'Удалить',
                      onTap: () {
                        Navigator.pop(context);
                        // _deleteOrder(order);
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
}