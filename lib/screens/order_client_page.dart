import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/edit_order_page.dart';
import 'package:goodjob/screens/interested_in_order_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:goodjob/services/api_service.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class OrderClientPage extends StatefulWidget {
  final String orderId;
  final bool isMyOrder;

  const OrderClientPage({
    super.key,
    required this.orderId,
    this.isMyOrder = true,
  });

  @override
  State<OrderClientPage> createState() => _OrderClientPageState();
}

class _OrderClientPageState extends State<OrderClientPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasMarkedAsViewed = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoadingData = false; // Add this flag to prevent multiple loads

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
    // Load data here instead of initState
    if (!_isLoadingData) {
      _isLoadingData = true;
      _loadOrderData();
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
    _pageController.dispose();
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    final appLocalizations = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderResponse = await ApiService.getOrderById(widget.orderId);
      setState(() {
        _order = orderResponse['data'];
      });

      if (!widget.isMyOrder && !_hasMarkedAsViewed && mounted) {
        _hasMarkedAsViewed = true;
        ApiService.markOrderAsViewed(widget.orderId).catchError((error) {
          print('Failed to mark order as viewed: $error');
        });
      }
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

  void _showCustomSnackBar({required String message, required bool isSuccess}) {
    final appLocalizations = AppLocalizations.of(context);
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
          label: appLocalizations?.translate('ok') ?? 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  bool _isOrderActive() {
    if (_order == null) return false;
    final isActive = _order?['is_active'] ?? false;
    final status = _order?['status']?.toString().toLowerCase();
    if (status == 'active') return true;
    if (status == 'archived') return false;
    if (status == 'canceled') return false;
    return isActive == true;
  }

  void _openInterestedInPage(Map<String, dynamic> viewer) {
    if (_order != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InterestedInOrderPage(viewer: viewer, order: _order!),
        ),
      );
    }
  }

  Future<void> _withdrawOrder() async {
    final appLocalizations = AppLocalizations.of(context);
    if (_order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appLocalizations?.translate('withdraw_order') ?? 'Отозвать заказ',
        ),
        content: Text(
          appLocalizations?.translate('withdraw_order_confirm') ??
              'Вы уверены, что хотите отозвать этот заказ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalizations?.translate('cancel') ?? 'Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              appLocalizations?.translate('withdraw') ?? 'Отозвать',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showCustomSnackBar(
          message:
              appLocalizations?.translate('withdrawing_order') ??
              'Отзыв заказа...',
          isSuccess: true,
        );

        // Используем новый метод revokeOrder
        await ApiService.revokeOrder(widget.orderId);

        setState(() {
          _order?['status'] = 'canceled';
          _order?['is_active'] = false;
        });

        _showCustomSnackBar(
          message:
              appLocalizations?.translate('order_withdrawn') ??
              'Заказ успешно отозван',
          isSuccess: true,
        );
      } catch (e) {
        _showCustomSnackBar(
          message:
              '${appLocalizations?.translate('error') ?? 'Ошибка'}: ${e.toString().replaceAll('Exception: ', '')}',
          isSuccess: false,
        );
      }
    }
  }

  void _editOrder() {
    if (_order == null) return;
    final orderId = _order!['id'].toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditOrderPage(orderId: orderId, onOrderUpdated: _loadOrderData),
      ),
    );
  }

  Future<void> _publishOrder() async {
    final appLocalizations = AppLocalizations.of(context);
    try {
      _showCustomSnackBar(
        message:
            appLocalizations?.translate('publishing_order') ??
            'Публикация заказа...',
        isSuccess: true,
      );

      // Используем новый метод publishOrder
      await ApiService.publishOrder(widget.orderId);

      setState(() {
        _order?['status'] = 'active';
        _order?['is_active'] = true;
      });

      _showCustomSnackBar(
        message:
            appLocalizations?.translate('order_published') ??
            'Заказ успешно опубликован',
        isSuccess: true,
      );
    } catch (e) {
      _showCustomSnackBar(
        message:
            '${appLocalizations?.translate('error') ?? 'Ошибка'}: ${e.toString().replaceAll('Exception: ', '')}',
        isSuccess: false,
      );
    }
  }

  Future<void> _unpublishOrder() async {
    final appLocalizations = AppLocalizations.of(context);
    try {
      _showCustomSnackBar(
        message:
            appLocalizations?.translate('unpublishing_order') ??
            'Отзыв публикации...',
        isSuccess: true,
      );

      // Используем новый метод revokeOrder
      await ApiService.revokeOrder(widget.orderId);

      setState(() {
        _order?['status'] = 'canceled';
        _order?['is_active'] = false;
      });

      _showCustomSnackBar(
        message:
            appLocalizations?.translate('order_unpublished') ??
            'Публикация отозвана',
        isSuccess: true,
      );
    } catch (e) {
      _showCustomSnackBar(
        message:
            '${appLocalizations?.translate('error') ?? 'Ошибка'}: ${e.toString().replaceAll('Exception: ', '')}',
        isSuccess: false,
      );
    }
  }

  Future<void> _archiveOrder() async {
    final appLocalizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appLocalizations?.translate('archive_order') ?? 'Архивировать заказ?',
        ),
        content: Text(
          appLocalizations?.translate('archive_order_confirm') ??
              'Вы уверены, что хотите архивировать этот заказ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalizations?.translate('cancel') ?? 'Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              appLocalizations?.translate('archive') ?? 'Архивировать',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showCustomSnackBar(
          message:
              appLocalizations?.translate('archiving_order') ??
              'Архивация заказа...',
          isSuccess: true,
        );

        await ApiService.archiveOrder(widget.orderId);

        setState(() {
          _order?['status'] = 'archived';
          _order?['is_active'] = false;
        });

        _showCustomSnackBar(
          message:
              appLocalizations?.translate('order_archived') ??
              'Заказ архивирован',
          isSuccess: true,
        );
      } catch (e) {
        _showCustomSnackBar(
          message:
              '${appLocalizations?.translate('error') ?? 'Ошибка'}: ${e.toString().replaceAll('Exception: ', '')}',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _deleteOrder() async {
    final appLocalizations = AppLocalizations.of(context);
    final orderIdInt = int.tryParse(widget.orderId) ?? 0;
    if (orderIdInt == 0) {
      _showCustomSnackBar(
        message:
            appLocalizations?.translate('invalid_order_id') ??
            'Неверный ID заказа',
        isSuccess: false,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appLocalizations?.translate('delete_order') ?? 'Удалить заказ?',
        ),
        content: Text(
          appLocalizations?.translate('delete_order_confirm') ??
              'Вы уверены, что хотите удалить этот заказ?\nЭто действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalizations?.translate('cancel') ?? 'Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(appLocalizations?.translate('delete') ?? 'Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showCustomSnackBar(
          message:
              appLocalizations?.translate('deleting_order') ??
              'Удаление заказа...',
          isSuccess: true,
        );

        await ApiService.deleteOrder(orderIdInt);

        _showCustomSnackBar(
          message:
              appLocalizations?.translate('order_deleted') ??
              'Заказ успешно удален',
          isSuccess: true,
        );

        if (mounted) {
          Navigator.pop(context, 'deleted');
        }
      } catch (e) {
        _showCustomSnackBar(
          message:
              '${appLocalizations?.translate('error') ?? 'Ошибка'}: ${e.toString().replaceAll('Exception: ', '')}',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _contactAuthor() async {
    final appLocalizations = AppLocalizations.of(context);
    final phone = _order?['telephone'];

    if (phone == null || phone.toString().isEmpty) {
      _showCustomSnackBar(
        message:
            appLocalizations?.translate('no_subscription') ??
            'У вас нет подписки',
        isSuccess: false,
      );
      return;
    }

    _launchUrl('tel:$phone');
  }

  void _showOrderOptionsModal() {
    final appLocalizations = AppLocalizations.of(context);
    final isActive = _isOrderActive();

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
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLocalizations?.translate('manage') ??
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
                              _order?['title']?.length > 30
                                  ? '${_order?['title'].substring(0, 30)}...'
                                  : _order?['title'] ??
                                        appLocalizations?.translate('order') ??
                                        'Заказ',
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
                              isActive
                                  ? appLocalizations?.translate('active') ??
                                        'Активен'
                                  : appLocalizations?.translate('inactive') ??
                                        'Не активен',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildCompactOption(
                          icon: Icons.edit_note_rounded,
                          label:
                              appLocalizations?.translate('edit') ??
                              'Редактировать',
                          color: const Color(0xFF2196F3),
                          onTap: () {
                            Navigator.pop(context);
                            _editOrder();
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCompactOption(
                          icon: isActive
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          label: isActive
                              ? appLocalizations?.translate('hide') ?? 'Скрыть'
                              : appLocalizations?.translate('publish') ??
                                    'Опубликовать',
                          color: isActive
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.pop(context);
                            if (isActive) {
                              _unpublishOrder();
                            } else {
                              _publishOrder();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCompactOption(
                          icon: Icons.archive_rounded,
                          label:
                              appLocalizations?.translate('archive') ??
                              'В архив',
                          color: const Color(0xFF795548),
                          onTap: () {
                            Navigator.pop(context);
                            _archiveOrder();
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCompactOption(
                          icon: Icons.delete_forever_rounded,
                          label:
                              appLocalizations?.translate('delete') ??
                              'Удалить',
                          color: const Color(0xFFF44336),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteOrder();
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      child: Text(
                        appLocalizations?.translate('close') ?? 'Закрыть',
                        style: const TextStyle(
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

  Future<void> _launchUrl(String url) async {
    final appLocalizations = AppLocalizations.of(context);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showCustomSnackBar(
          message:
              appLocalizations?.translate('failed_to_open_link') ??
              'Не удалось открыть ссылку',
          isSuccess: false,
        );
      }
    }
  }

  String _formatPrice(String price) {
    final appLocalizations = AppLocalizations.of(context);
    try {
      final number = double.parse(price);
      final formatted = number.toStringAsFixed(0);
      final parts = formatted.split('.');
      final integerPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );
      return '$integerPart ${appLocalizations?.translate('tenge') ?? '₸'}';
    } catch (e) {
      return '$price ${appLocalizations?.translate('tenge') ?? '₸'}';
    }
  }

  String? _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return 'https://good-job.kz/storage/$imagePath';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
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
            widget.isMyOrder
                ? appLocalizations?.translate('my_orders') ?? 'Мои заказы'
                : appLocalizations?.translate('order') ?? 'Заказ',
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
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, color: Color(0xFF41454A)),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildBody(appLocalizations),
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
              accountType: widget.isMyOrder
                  ? AccountType.client
                  : AccountType.master,
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

  Widget _buildBody(AppLocalizations? appLocalizations) {
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
                appLocalizations?.translate('loading_error') ??
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
                child: Text(
                  appLocalizations?.translate('retry') ?? 'Повторить',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Center(
        child: Text(
          appLocalizations?.translate('order_not_found') ?? 'Заказ не найден',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    if (!widget.isMyOrder && _order?['client'] != null) ...[
                      _buildAuthorInfo(_order!['client'], appLocalizations),
                      const SizedBox(height: 24),
                    ],
                    _buildImageGallery(appLocalizations),
                    const SizedBox(height: 16),
                    Text(
                      _order?['title'] ??
                          appLocalizations?.translate('no_title') ??
                          'Нет названия',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_order?['category'] != null)
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
                        child: Text(
                          _order?['category']['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0F7EDE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_order?['description'] != null &&
                        _order!['description'].toString().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalizations?.translate('description') ??
                                'Описание',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _order?['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    if (_order?['price'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE3F2FD),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appLocalizations?.translate('price') ?? 'Цена:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF41454A),
                              ),
                            ),
                            Text(
                              _formatPrice(_order?['price'].toString() ?? '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F7EDE),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_order?['city'] != null)
                      _buildInfoRow(
                        appLocalizations?.translate('city') ?? 'Город:',
                        _order?['city']['name'] ?? '',
                        Icons.location_on_outlined,
                        appLocalizations,
                      ),
                    if (_order?['address_street'] != null)
                      _buildInfoRow(
                        appLocalizations?.translate('address') ?? 'Адрес:',
                        '${_order?['address_street']}, д. ${_order?['address_house'] ?? ''}${_order?['address_apartment'] != null ? ', кв. ${_order?['address_apartment']}' : ''}',
                        Icons.home_outlined,
                        appLocalizations,
                      ),
                    if (_order?['telephone'] != null)
                      _buildInfoRow(
                        appLocalizations?.translate('phone') ?? 'Телефон:',
                        _order?['telephone'],
                        Icons.phone_outlined,
                        appLocalizations,
                      ),
                    if (_order?['createdAt'] != null)
                      _buildInfoRow(
                        appLocalizations?.translate('publication_date') ??
                            'Дата публикации:',
                        _formatDate(_order?['createdAt']),
                        Icons.calendar_today_outlined,
                        appLocalizations,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(_order?['status']),
                                size: 16,
                                color: _getStatusTextColor(_order?['status']),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(
                                  _order?['status'],
                                  appLocalizations,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusTextColor(_order?['status']),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.isMyOrder)
                      _buildMyOrderFooter(appLocalizations)
                    else
                      _buildOtherOrderFooter(appLocalizations),
                    if (widget.isMyOrder) ...[
                      _buildViewsSection(appLocalizations),
                      const SizedBox(height: 24),
                    ],
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

  Widget _buildImageGallery(AppLocalizations? appLocalizations) {
    final List<dynamic> images = _order?['images'] ?? [];

    if (images.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations?.translate('no_images') ?? 'Нет изображений',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  final imageUrl = _getFullImageUrl(images[index].toString());
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appLocalizations?.translate(
                                      'image_load_error',
                                    ) ??
                                    'Ошибка загрузки',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              if (images.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentImageIndex > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF41454A),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentImageIndex < images.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF41454A),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = _getFullImageUrl(images[index].toString());
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F7EDE)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.broken_image,
                              size: 20,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthorInfo(
    Map<String, dynamic> author,
    AppLocalizations? appLocalizations,
  ) {
    final String fullName =
        '${author['firstname'] ?? ''} ${author['lastname'] ?? ''}'.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: author['avatar'] != null
                ? NetworkImage(_getFullImageUrl(author['avatar'])!)
                : null,
            child: author['avatar'] == null
                ? const Icon(Icons.person, color: Colors.grey, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty
                      ? fullName
                      : appLocalizations?.translate('user') ?? 'Пользователь',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF41454A),
                  ),
                ),
                if (author['rating'] != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${author['rating']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (author['orders_count'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${author['orders_count']} ${appLocalizations?.translate('orders') ?? 'заказов'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyOrderFooter(AppLocalizations? appLocalizations) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          if (_order?['status'] == 'active')
            Expanded(
              child: OutlinedButton(
                onPressed: _withdrawOrder,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5F6368),
                  side: const BorderSide(color: Color(0xFF5F6368), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  appLocalizations?.translate('withdraw') ?? 'Отозвать',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          if (_order?['status'] == 'active') const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _showOrderOptionsModal,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5F6368),
                side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/more.png',
                    width: 20,
                    height: 20,
                    color: const Color(0xFF5F6368),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations?.translate('more') ?? 'Ещё',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Plus Jakarta Sans',
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

  Widget _buildOtherOrderFooter(AppLocalizations? appLocalizations) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _contactAuthor,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF41454A),
                side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations?.translate('contact') ?? 'Связаться',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Plus Jakarta Sans',
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

  Widget _buildViewsSection(AppLocalizations? appLocalizations) {
    final views = _order?['views'] as List?;

    if (views == null || views.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(20),
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_off_outlined,
                size: 30,
                color: Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              appLocalizations?.translate('no_views_yet') ??
                  'Пока никто не просмотрел',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appLocalizations?.translate('views_will_appear') ??
                  'Когда мастера проявят интерес,\nони появятся здесь',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 18,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations?.translate('views') ?? 'Просмотры',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${views.length} ${_getViewsWord(views.length, appLocalizations)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: views.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final view = views[index];
              final master = view['master'] ?? {};
              final viewedAt = view['viewedAt'] ?? view['viewed_at'] ?? '';

              return InkWell(
                onTap: () => _openInterestedInPage(view),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline,
                            size: 28,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${master['firstname'] ?? ''} ${master['lastname'] ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    appLocalizations?.translate('master') ??
                                        'Мастер',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF757575),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ApiService.formatDateTime(viewedAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getViewsWord(int count, AppLocalizations? appLocalizations) {
    if (count % 10 == 1 && count % 100 != 11)
      return appLocalizations?.translate('view') ?? 'просмотр';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return appLocalizations?.translate('views_few') ?? 'просмотра';
    }
    return appLocalizations?.translate('views_many') ?? 'просмотров';
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    AppLocalizations? appLocalizations,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF41454A),
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

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'canceled':
        return Icons.cancel_outlined;
      case 'archived':
        return Icons.archive_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String? status, AppLocalizations? appLocalizations) {
    switch (status) {
      case 'active':
        return appLocalizations?.translate('active') ?? 'Активен';
      case 'completed':
        return appLocalizations?.translate('completed') ?? 'Завершен';
      case 'canceled':
        return appLocalizations?.translate('canceled') ?? 'Отменен';
      case 'archived':
        return appLocalizations?.translate('archived') ?? 'Архивирован';
      default:
        return status ?? appLocalizations?.translate('unknown') ?? 'Неизвестно';
    }
  }
}
