import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/screens/interested_in_order_page.dart';
import 'package:flutter_application_1/services/api_service.dart';


class OrderClientPage extends StatefulWidget {
  final String orderId; // Теперь принимаем ID заказа

  const OrderClientPage({super.key, required this.orderId});

  @override
  State<OrderClientPage> createState() => _OrderClientPageState();
}

class _OrderClientPageState extends State<OrderClientPage> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Загружаем данные заказа
      final orderResponse = await ApiService.getOrderById(widget.orderId);
      setState(() {
        _order = orderResponse['data'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadOrderData();
  }

  // Метод для перехода на страницу interested_in_page
  void _openInterestedInPage(Map<String, dynamic> viewer) {
    if (_order != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterestedInOrderPage(
            viewer: viewer,
            order: _order!,
          ),
        ),
      );
    }
  }

  // Метод для отзыва заказа
  Future<void> _withdrawOrder() async {
    if (_order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отозвать заказ'),
        content: const Text('Вы уверены, что хотите отозвать этот заказ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отозвать', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.changeOrderStatus(
          orderId: widget.orderId,
          status: 'canceled',
        );
        
        // Обновляем локальные данные
        setState(() {
          _order?['status'] = 'Отозван';
          _order?['isActive'] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ успешно отозван')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  // Метод для редактирования заказа
  void _editOrder() {
    // TODO: Реализовать переход на страницу редактирования заказа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование заказа (в разработке)')),
    );
  }

  // Метод для архивирования заказа
  Future<void> _archiveOrder() async {
    try {
      await ApiService.changeOrderStatus(
        orderId: widget.orderId,
        status: 'archived',
      );
      
      setState(() {
        _order?['status'] = 'Архивирован';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ перемещен в архив')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Метод для удаления заказа
  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заказ'),
        content: const Text('Вы уверены, что хотите удалить этот заказ? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteOrder(int.parse(widget.orderId));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ успешно удален')),
        );
        
        // Возвращаемся на предыдущую страницу
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
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
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.work,
        accountType: AccountType.client,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return const Center(
        child: Text('Заказ не найден'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
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
                    // Изображения заказа (если есть в API)
                    if (_order?['images'] != null && (_order?['images'] as List).isNotEmpty)
                      Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(
                                  'http://gj-back.checkedout.kz${_order?['images'][0]}',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      )
                    else
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      ),

                    // Заголовок
                    Text(
                      _order?['title'] ?? 'Нет названия',
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
                            _order?['description'] ?? 'Нет описания',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),

                        // Цена справа
                        if (_order?['price'] != null)
                          Text(
                            '${_order?['price']} ₸',
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

                    // Дополнительная информация
                    if (_order?['address_street'] != null)
                      _buildInfoRow('Адрес:', '${_order?['address_street']}, '
                          'д. ${_order?['address_house']}, '
                          'кв. ${_order?['address_apartment']}'),

                    if (_order?['telephone'] != null)
                      _buildInfoRow('Телефон:', _order?['telephone']),

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
                          // Статус
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_order?['status']),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusBorderColor(_order?['status']),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(_order?['status']),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getStatusTextColor(_order?['status']),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Кнопка "Отозвать" для активных заказов
                          if (_order?['status'] == 'active')
                            OutlinedButton(
                              onPressed: _withdrawOrder,
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
                              _showOrderOptionsModal(context);
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

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderOptionsModal(BuildContext context) {
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
                      onTap: () => Navigator.pop(context),
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
                    // Редактировать (только для активных заказов)
                    if (_order?['status'] == 'active')
                      Column(
                        children: [
                          _buildOptionButton(
                            icon: 'assets/edit.png',
                            text: 'Редактировать',
                            onTap: () {
                              Navigator.pop(context);
                              _editOrder();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Отозвать публикацию (только для активных заказов)
                    if (_order?['status'] == 'active')
                      Column(
                        children: [
                          _buildOptionButton(
                            icon: 'assets/chat_error.png',
                            text: 'Отозвать публикацию',
                            onTap: () {
                              Navigator.pop(context);
                              _withdrawOrder();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Архивировать
                    _buildOptionButton(
                      icon: 'assets/archive.png',
                      text: 'Архивировать',
                      onTap: () {
                        Navigator.pop(context);
                        _archiveOrder();
                      },
                    ),
                    const SizedBox(height: 8),

                    // Удалить
                    _buildOptionButton(
                      icon: 'assets/delete.png',
                      text: 'Удалить',
                      onTap: () {
                        Navigator.pop(context);
                        _deleteOrder();
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

  // Вспомогательные методы для статусов
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return const Color(0xFFE8F5E9);
      case 'completed':
        return const Color(0xFFE3F2FD);
      case 'canceled':
        return const Color(0xFFFFEBEE);
      case 'archived':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getStatusBorderColor(String? status) {
    switch (status) {
      case 'active':
        return const Color(0xFF1DCE6A);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'canceled':
        return const Color(0xFFF44336);
      case 'archived':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'active':
        return const Color(0xFF1DCE6A);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'canceled':
        return const Color(0xFFF44336);
      case 'archived':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'Активен';
      case 'completed':
        return 'Завершен';
      case 'canceled':
        return 'Отменен';
      case 'archived':
        return 'Архивирован';
      default:
        return status ?? 'Неизвестно';
    }
  }
}