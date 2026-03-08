// lib/screens/price_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/page_service.dart';
import 'package:flutter_application_1/models/page_model.dart';
import 'package:flutter_application_1/widgets/html_table_widget.dart';

class PricePage extends StatefulWidget {
  @override
  _PricePageState createState() => _PricePageState();
}

class _PricePageState extends State<PricePage>
    with SingleTickerProviderStateMixin {
  final PageService _pageService = PageService();
  late Future<PageModel> _pageFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic>? userData;
  bool isLoadingProfile = true;
  bool isLoadingPage = true;
  bool isRefreshing = false;
  dynamic _activeMode;
  PageModel? _cachedPage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPageData();

    // Анимация для плавного появления контента
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    try {
      setState(() => isLoadingProfile = true);
      final response = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          userData = response['data'];
          final activeValue = userData?['activeMode'];

          if (activeValue != null) {
            _activeMode = activeValue;
          }

          print('Загружены данные пользователя: $userData');
          print('Active mode: $_activeMode');
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingProfile = false);
        print('Ошибка загрузки профиля: $e');
        // Не показываем ошибку пользователю, так как профиль не критичен для этой страницы
      }
    }
  }

  Future<void> _loadPageData() async {
    if (!mounted) return;

    setState(() {
      isLoadingPage = true;
      _errorMessage = null;
    });

    try {
      final page = await _pageService.getPageBySlug('price').timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Превышено время ожидания'),
      );

      if (mounted) {
        setState(() {
          _cachedPage = page;
          isLoadingPage = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingPage = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      _errorMessage = null;
      _animationController.reset();
    });

    try {
      // Обновляем профиль в фоне
      _loadUserProfile();

      // Обновляем страницу
      final page = await _pageService.getPageBySlug('price').timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Превышено время ожидания'),
      );

      if (mounted) {
        setState(() {
          _cachedPage = page;
          isRefreshing = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isRefreshing = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  AccountType? get _accountTypeForNavBar {
    if (_activeMode == null) return null;
    if (_activeMode == 'master') return AccountType.master;
    return AccountType.client;
  }

  bool get _isLoading => isLoadingPage || isLoadingProfile;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              width: 40,
              height: 40,
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF41454A),
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Прайс-лист',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF0F7EDE),
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _accountTypeForNavBar == null
            ? null
            : SafeArea(
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
                    activeItem: NavItem.price,
                    accountType: _accountTypeForNavBar!,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _cachedPage == null) {
      return _buildSkeletonLoader();
    }

    if (_errorMessage != null && _cachedPage == null) {
      return _buildErrorWidget();
    }

    if (_cachedPage != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная карточка с контентом
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок (если есть)
                    if (_cachedPage!.name.isNotEmpty &&
                        _cachedPage!.name != 'Прайс-лист')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F7EDE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _cachedPage!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D2125),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // HTML контент (таблица)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: HtmlTableWidget(
                        htmlContent: _cachedPage!.content,
                      ),
                    ),

                    // Индикатор обновления (если идет рефреш)
                    if (isRefreshing)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0F7EDE),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Дата обновления
            _buildUpdateInfo(),

            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        // Скелетон основной карточки
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок скелетона
                Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                // Строки таблицы
                for (int i = 0; i < 5; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i < 4) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Скелетон даты
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateInfo() {
    if (_cachedPage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.update,
              size: 16,
              color: Color(0xFF0F7EDE),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Последнее обновление',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8D90),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(_cachedPage!.updatedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2125),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
          if (isRefreshing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F7EDE)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Не удалось загрузить прайс-лист',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Попробуйте повторить позже',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadPageData,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7EDE),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F7EDE).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Попробовать снова',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
        ],
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socketexception') || 
        errorStr.contains('network') ||
        errorStr.contains('internet')) {
      return 'Проверьте подключение к интернету';
    }
    if (errorStr.contains('timeout')) {
      return 'Сервер не отвечает. Попробуйте позже';
    }
    if (errorStr.contains('404')) {
      return 'Страница не найдена';
    }
    if (errorStr.contains('500')) {
      return 'Ошибка на сервере. Попробуйте позже';
    }
    return 'Что-то пошло не так';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Сегодня в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Вчера в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        return '${days[date.weekday - 1]} в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        final months = [
          'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
          'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}