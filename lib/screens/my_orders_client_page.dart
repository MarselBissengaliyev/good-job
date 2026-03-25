import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/edit_order_page.dart';
import 'package:goodjob/services/api_service.dart';
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
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _loadOrders();

    // Устанавливаем цвет системной навигации
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    // Возвращаем стандартные настройки при выходе
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
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

  List<dynamic> get _filteredOrders {
    return _orders.where((order) {
      final title = order['title']?.toString().toLowerCase() ?? '';
      final description = order['description']?.toString().toLowerCase() ?? '';
      final matchesSearch =
          _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase());

      final isActive = _isOrderActive(order);
      final matchesFilter =
          _filterStatus == 'all' ||
          (_filterStatus == 'active' && isActive) ||
          (_filterStatus == 'inactive' && !isActive);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showCustomSnackBar({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openOrderDetails(order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        image: firstImage != null
                            ? DecorationImage(
                                image: NetworkImage(
                                  _getFullImageUrl(firstImage),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: firstImage == null
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFF5F5F5),
                                    const Color(0xFFEEEEEE),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFFBDBDBD),
                                  size: 36,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F7EDE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F7EDE),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: const Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            if (clientName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFBDBDBD),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFEEEEEE).withOpacity(0.7),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFF9E9E9E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle
                            : Icons.remove_circle_outline,
                        size: 14,
                        color: isActive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF9E9E9E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Активен' : 'Не активен',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF9E9E9E),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!isActive)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _publishOrder(orderId),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.publish_rounded,
                              size: 16,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Опубликовать',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4CAF50),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showOrderOptionsModal(context, order),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: Color(0xFF5F6368),
                        ),
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
      _showCustomSnackBar(
        message: 'Не удалось открыть заказ',
        isSuccess: false,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderClientPage(orderId: orderId),
      ),
    ).then((value) {
      if (value == true || value == 'updated' || value == 'deleted') {
        _loadOrders();
      }
    });
  }

  void _addNewOrder() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddOrderClientPage()),
    ).then((_) {
      _loadOrders();
    });
  }

  Future<void> _publishOrder(String orderId) async {
    HapticFeedback.mediumImpact();

    try {
      _showCustomSnackBar(message: 'Публикация заказа...', isSuccess: true);

      await ApiService.changeOrderStatus(orderId: orderId, status: 'active');

      HapticFeedback.heavyImpact();
      _showCustomSnackBar(
        message: 'Заказ успешно опубликован',
        isSuccess: true,
      );

      _loadOrders();
    } catch (e) {
      HapticFeedback.vibrate();
      _showCustomSnackBar(
        message: 'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
        isSuccess: false,
      );
    }
  }

  void _showOrderOptionsModal(BuildContext context, dynamic order) {
    final orderId = order['id']?.toString() ?? '0';
    final title = order['title']?.toString() ?? 'Без названия';
    final isActive = _isOrderActive(order);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Индикатор прокрутки
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Заголовок
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Управление',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D1F),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title.length > 30
                                  ? '${title.substring(0, 30)}...'
                                  : title,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF9E9E9E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: const Color(0xFF5F6368),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Статус заказа (компактный)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF4CAF50).withOpacity(0.08)
                            : const Color(0xFF9E9E9E).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF4CAF50).withOpacity(0.2)
                              : const Color(0xFF9E9E9E).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isActive
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              size: 16,
                              color: isActive
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isActive ? 'Активен' : 'Не активен',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF9E9E9E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Опции действий (компактные)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildCompactOption(
                          icon: Icons.edit_note_rounded,
                          label: 'Редактировать',
                          color: const Color(0xFF2196F3),
                          onTap: () {
                            Navigator.pop(context);
                            _editOrder(order);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCompactOption(
                          icon: isActive
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          label: isActive ? 'Скрыть' : 'Опубликовать',
                          color: isActive
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.pop(context);
                            if (isActive) {
                              _unpublishOrder(orderId);
                            } else {
                              _publishOrder(orderId);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCompactOption(
                          icon: Icons.archive_rounded,
                          label: 'В архив',
                          color: const Color(0xFF795548),
                          onTap: () {
                            Navigator.pop(context);
                            _archiveOrder(orderId);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCompactOption(
                          icon: Icons.delete_forever_rounded,
                          label: 'Удалить',
                          color: const Color(0xFFF44336),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteOrder(orderId);
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Компактная кнопка закрытия
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5F6368),
                        side: BorderSide(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Закрыть',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive
                  ? const Color(0xFFFFCDD2)
                  : const Color(0xFFEEEEEE),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, size: 18, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDestructive
                        ? const Color(0xFFF44336)
                        : const Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: const Color(0xFFBDBDBD),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editOrder(dynamic order) {
    if (order == null) return;
  
  final orderId = order!['id'].toString();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditOrderPage(
        orderId: orderId,
        onOrderUpdated: () => {},
      ),
    ),
  );
  }
  Future<void> _unpublishOrder(String orderId) async {
    HapticFeedback.mediumImpact();

    try {
      _showCustomSnackBar(message: 'Отзыв публикации...', isSuccess: true);

      await ApiService.changeOrderStatus(orderId: orderId, status: 'canceled');

      HapticFeedback.heavyImpact();
      _showCustomSnackBar(message: 'Публикация отозвана', isSuccess: true);

      _loadOrders();
    } catch (e) {
      HapticFeedback.vibrate();
      _showCustomSnackBar(
        message: 'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
        isSuccess: false,
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
    HapticFeedback.mediumImpact();

    try {
      _showCustomSnackBar(message: 'Архивация заказа...', isSuccess: true);

      await ApiService.changeOrderStatus(orderId: orderId, status: 'archived');

      HapticFeedback.heavyImpact();
      _showCustomSnackBar(message: 'Заказ архивирован', isSuccess: true);

      _loadOrders();
    } catch (e) {
      HapticFeedback.vibrate();
      _showCustomSnackBar(
        message: 'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
        isSuccess: false,
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    final orderIdInt = int.tryParse(orderId) ?? 0;
    if (orderIdInt == 0) {
      _showCustomSnackBar(message: 'Неверный ID заказа', isSuccess: false);
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
    HapticFeedback.mediumImpact();

    try {
      _showCustomSnackBar(message: 'Удаление заказа...', isSuccess: true);

      await ApiService.deleteOrder(orderId);

      HapticFeedback.heavyImpact();
      _showCustomSnackBar(message: 'Заказ успешно удален', isSuccess: true);

      _loadOrders();
    } catch (e) {
      HapticFeedback.vibrate();
      _showCustomSnackBar(
        message: 'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset:
            false, // Предотвращает сжатие при открытии клавиатуры
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (_filterStatus != 'all' || _searchQuery.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_filterStatus != 'all')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F7EDE,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _filterStatus == 'active'
                                          ? 'Активные'
                                          : 'Неактивные',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0F7EDE),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _filterStatus = 'all';
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFF0F7EDE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_searchQuery.isNotEmpty &&
                                _filterStatus != 'all')
                              const SizedBox(width: 8),
                            if (_searchQuery.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F7EDE,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Поиск: "$_searchQuery"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0F7EDE),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFF0F7EDE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${_filteredOrders.length} из ${_orders.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 1.0 + (value * 0.1).clamp(0.9, 1.1),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0F7EDE),
                              ),
                              strokeWidth: 3,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Загрузка ваших заказов...',
                        style: TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Это займет всего несколько секунд',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 14,
                        ),
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
            else if (_filteredOrders.isEmpty)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F7EDE,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 60,
                                  color: Color(0xFF0F7EDE),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty || _filterStatus != 'all'
                              ? 'Ничего не найдено'
                              : 'У вас пока нет заказов',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _searchQuery.isNotEmpty || _filterStatus != 'all'
                                ? 'Попробуйте изменить параметры поиска'
                                : 'Создайте свой первый заказ и начните получать предложения от мастеров',
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color(0xFF9E9E9E),
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _filterStatus != 'all')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _filterStatus = 'all';
                                });
                              },
                              child: const Text('Сбросить фильтры'),
                            ),
                          ),
                      ],
                    ),
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
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildOrderItem(order),
                      );
                    },
                  ),
                ),
              ),
            if (!_isLoading && !_hasError)
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _orders.isEmpty
                              ? Icons.add_circle_outline
                              : Icons.add,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _orders.isEmpty
                              ? 'Создать первый заказ'
                              : 'Добавить заказ',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
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
        bottomNavigationBar: SafeArea(
          top: false, // SafeArea только снизу
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
              activeItem: NavItem.orders,
              accountType: AccountType.client,
            ),
          ),
        ),
      ),
    );
  }
}
