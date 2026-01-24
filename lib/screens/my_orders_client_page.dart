import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'add_order_client_page.dart';
import 'order_client_page.dart';

class MyOrdersClientPage extends StatefulWidget {
  const MyOrdersClientPage({super.key});

  @override
  State<MyOrdersClientPage> createState() => _MyOrdersClientPageState();
}

class _MyOrdersClientPageState extends State<MyOrdersClientPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.getClientOrders();

      setState(() {
        _orders = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    final baseUrl = 'http://gj-back.checkedout.kz';
    return '$baseUrl/storage/$imagePath';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Дата не указана';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  bool _isOrderActive(dynamic order) {
    final isActive = order['is_active'] ?? false;
    final status = order['status']?.toString().toLowerCase();

    if (status == 'active') return true;
    if (status == 'archived') return false;
    if (status == 'canceled') return false;

    return isActive == true;
  }

  Widget _buildOrderItem(dynamic order) {
    final orderId = order['id']?.toString() ?? '0';
    final title = order['title']?.toString() ?? 'Без названия';
    final price = order['price']?.toString() ?? '0.00';
    final formattedPrice = double.tryParse(price) != null
        ? '${double.parse(price).toInt()} ₸'
        : '$price ₸';
    final date = _formatDate(order['createdAt']?.toString());
    final client = order['client'] ?? {};
    final clientName =
        '${client['firstname'] ?? ''} ${client['lastname'] ?? ''}'.trim();
    final images = (order['images'] as List?)?.cast<String>() ?? [];
    final firstImage = images.isNotEmpty ? images.first : null;
    final isActive = _isOrderActive(order);

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
          GestureDetector(
            onTap: () => _openOrderDetails(order),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFF5F5F5),
                      image: firstImage != null
                          ? DecorationImage(
                              image: NetworkImage(_getFullImageUrl(firstImage)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: firstImage == null
                        ? const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFF9E9E9E),
                              size: 32,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
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

                        if (clientName.isNotEmpty)
                          Text(
                            clientName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),

                        const SizedBox(height: 8),

                        Text(
                          formattedPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F7EDE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: Row(
              children: [
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
                    isActive ? 'Активен' : 'Не активен',
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

                if (!isActive)
                  OutlinedButton(
                    onPressed: () => _publishOrder(orderId),
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

                GestureDetector(
                  onTap: () => _showOrderOptionsModal(context, order),
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

  void _openOrderDetails(dynamic order) {
    final orderId = order['id']?.toString();
    if (orderId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось открыть заказ')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderClientPage(orderId: orderId),
      ),
    ).then((value) {
      // Обновляем заказы если вернулись с каким-то результатом
      if (value == true || value == 'updated' || value == 'deleted') {
        _loadOrders();
      }
    });
  }

  void _addNewOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddOrderClientPage()),
    ).then((_) {
      _loadOrders();
    });
  }

  Future<void> _publishOrder(String orderId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Публикация заказа...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ApiService.changeOrderStatus(orderId: orderId, status: 'active');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ опубликован'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showOrderOptionsModal(BuildContext context, dynamic order) {
    final orderId = order['id']?.toString() ?? '0';
    final isActive = _isOrderActive(order);

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
                    Text(
                      'Заказ #$orderId',
                      style: const TextStyle(
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

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    _buildOptionButton(
                      icon: 'assets/edit.png',
                      text: 'Редактировать',
                      onTap: () {
                        Navigator.pop(context);
                        _editOrder(order);
                      },
                    ),
                    const SizedBox(height: 8),

                    if (isActive)
                      _buildOptionButton(
                        icon: 'assets/chat_error.png',
                        text: 'Отозвать публикацию',
                        onTap: () {
                          Navigator.pop(context);
                          _unpublishOrder(orderId);
                        },
                      )
                    else
                      _buildOptionButton(
                        icon: Icons.publish,
                        text: 'Опубликовать',
                        onTap: () {
                          Navigator.pop(context);
                          _publishOrder(orderId);
                        },
                      ),
                    const SizedBox(height: 8),

                    _buildOptionButton(
                      icon: 'assets/archive.png',
                      text: 'Архивировать',
                      onTap: () {
                        Navigator.pop(context);
                        _archiveOrder(orderId);
                      },
                    ),
                    const SizedBox(height: 8),

                    // НОВАЯ КНОПКА: Удалить
                    _buildOptionButton(
                      icon: 'assets/delete.png',
                      text: 'Удалить',
                      onTap: () {
                        Navigator.pop(context);
                        _deleteOrder(orderId);
                      },
                      isDelete: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required dynamic icon,
    required String text,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    final iconWidget = icon is IconData
        ? Icon(
            icon,
            size: 24,
            color: isDelete ? const Color(0xFFF44336) : const Color(0xFF41454A),
          )
        : Image.asset(
            icon as String,
            width: 24,
            height: 24,
            color: isDelete ? const Color(0xFFF44336) : const Color(0xFF41454A),
          );

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
            iconWidget,
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

  void _editOrder(dynamic order) {
    _showEditOrderDialog(context, order);
  }

  void _showEditOrderDialog(BuildContext context, dynamic order) {
    final orderId = order['id']?.toString() ?? '0';
    final titleController = TextEditingController(
      text: order['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: order['description']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать заказ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 70,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 9000,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Заполните все поля'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _updateOrder(orderId, title, description);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOrder(
    String orderId,
    String title,
    String description,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сохранение изменений...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ApiService.updateClientOrder(
        orderId: orderId,
        title: title,
        description: description,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ успешно обновлен'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _unpublishOrder(String orderId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отзыв публикации...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ApiService.changeOrderStatus(orderId: orderId, status: 'canceled');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Публикация отозвана'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _archiveOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Архивировать заказ?'),
          content: const Text(
            'Вы уверены, что хотите архивировать этот заказ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmArchiveOrder(orderId);
              },
              child: const Text('Архивировать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmArchiveOrder(String orderId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Архивация заказа...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ApiService.changeOrderStatus(orderId: orderId, status: 'archived');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ архивирован'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // НОВЫЙ МЕТОД: Удаление заказа
  Future<void> _deleteOrder(String orderId) async {
    final orderIdInt = int.tryParse(orderId) ?? 0;
    if (orderIdInt == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный ID заказа'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить заказ?'),
          content: const Text(
            'Вы уверены, что хотите удалить этот заказ?\n'
            'Это действие нельзя отменить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmDeleteOrder(orderIdInt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteOrder(int orderId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Удаление заказа...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ApiService.deleteOrder(orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ успешно удален'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh, color: Color(0xFF41454A)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F7EDE),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Загрузка заказов...',
                      style: TextStyle(color: Color(0xFF5F6368), fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFF44336),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Color(0xFF41454A),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7EDE),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          else if (_orders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/no_orders.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'У вас пока нет заказов',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF41454A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Создайте свой первый заказ прямо сейчас',
                      style: TextStyle(color: Color(0xFF5F6368), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                color: const Color(0xFF0F7EDE),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderItem(order);
                  },
                ),
              ),
            ),

          if (!_isLoading && !_hasError)
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
                    side: const BorderSide(color: Color(0xFF0F7EDE), width: 1),
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
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.orders,
        accountType: AccountType.client,
      ),
    );
  }
}
