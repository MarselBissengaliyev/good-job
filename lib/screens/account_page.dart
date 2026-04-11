import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/models/work-photo.dart';
import 'package:goodjob/models/master_review.dart';
import 'package:goodjob/screens/edit_portfolio_master_page.dart';
import 'package:goodjob/screens/edit_profile_page.dart';
import 'package:goodjob/screens/help_page.dart';
import 'package:goodjob/screens/offer_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/auth/auth_service.dart';
import 'my_orders_client_page.dart';

enum AccountType { client, master }

class AccountPage extends StatefulWidget {
  final AccountType accountType;

  const AccountPage({super.key, required this.accountType});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isLoadingWorks = false;
  List<WorkPhoto> portfolioImages = [];
  String? selectedCategory;
  dynamic _activeMode;
  List<dynamic> categories = [];
  bool isLoadingCategories = false;
  List<MasterReview> _reviews = [];
  bool _isLoadingReviews = false;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initAnimation();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
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
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final appLocalizations = AppLocalizations.of(context);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations?.translate('failed_to_open_link') ?? 'Не удалось открыть ссылку'}: $url',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openSocialLink(String? username, String platform) async {
    final appLocalizations = AppLocalizations.of(context);
    if (username == null || username.isEmpty) {
      _showSnackBar(
        appLocalizations?.translate('username_not_specified') ??
            'Имя пользователя не указано',
        isError: true,
      );
      return;
    }

    String url;
    final cleanUsername = username.replaceAll('@', '');

    switch (platform) {
      case 'instagram':
        url = 'https://instagram.com/$cleanUsername';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$cleanUsername';
        break;
      default:
        return;
    }

    try {
      _launchUrl(url);
    } catch (e) {
      _showSnackBar(
        appLocalizations?.translate('error_opening_link') ??
            'Ошибка при открытии ссылки',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF0F7EDE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final appLocalizations = AppLocalizations.of(context);
    if (!mounted) return;

    try {
      setState(() => isLoading = true);
      final response = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          userData = response['data'];
          final activeValue = userData?['activeMode'];
          if (activeValue != null) {
            _activeMode = activeValue;
          }

          if (_isMaster) {
            _loadMasterWorks();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar(
          '${appLocalizations?.translate('error_loading_profile') ?? 'Ошибка загрузки профиля'}: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadMasterWorks() async {
    if (!mounted || !_isMaster) return;

    try {
      setState(() => isLoadingWorks = true);
      final works = await ApiService.getWorkPhotos();

      if (mounted) {
        setState(() {
          portfolioImages = works;
          isLoadingWorks = false;
        });
      }
      await _loadMasterReviews();
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingWorks = false);
      }
    }
  }

  Future<void> _loadMasterReviews() async {
    final appLocalizations = AppLocalizations.of(context);
    if (!mounted || !_isMaster || userData == null) return;

    setState(() => _isLoadingReviews = true);

    try {
      final masterId = userData!['id'].toString();
      final response = await ApiService.getMasterReviews(masterId);

      if (response['data'] != null) {
        final List<dynamic> reviewsData = response['data'];
        setState(() {
          _reviews = MasterReview.fromJsonList(reviewsData);
          _totalReviews = _reviews.length;

          if (_reviews.isNotEmpty) {
            final sum = _reviews.fold(
              0,
              (prev, review) => prev + review.rating,
            );
            _averageRating = sum / _reviews.length;
          } else {
            _averageRating = 0.0;
          }
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  bool get _isMaster => _activeMode == 'master';

  AccountType? get _accountTypeForNavBar {
    if (_activeMode == null) return null;
    if (_activeMode == 'master') return AccountType.master;
    return AccountType.client;
  }

  void _navigateToEditProfile() {
    final appLocalizations = AppLocalizations.of(context);
    ProfileMode mode = _isMaster ? ProfileMode.master : ProfileMode.client;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(initialMode: mode),
      ),
    ).then((result) {
      if (mounted) {
        _loadUserProfile();
        if (_isMaster) _loadMasterWorks();
      }
    });
  }

  void _openEditPortfolioPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditPortfolioMasterPage()),
    ).then((_) {
      if (mounted) _loadMasterWorks();
    });
  }

  String _formatDate(String dateString) {
    return ApiService.formatDateTime(dateString);
  }

Widget _buildTermsAndConditions(AppLocalizations? appLocalizations) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E8E8)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.description_outlined,
          size: 18,
          color: Colors.grey.shade600,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OfferPage()),
            );
          },
          child: Text(
            appLocalizations?.translate('public_offer') ?? 'публичной офертой',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F7EDE),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
  );
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
          title: Text(
            appLocalizations?.translate('account') ?? 'Аккаунт',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            _buildLanguageButton(context, languageProvider, appLocalizations),
            IconButton(
              onPressed: () async {
                await AuthService.clearAuthData();
                if (mounted)
                  Navigator.pushReplacementNamed(context, '/registration');
              },
              icon: Image.asset('assets/logout.png', width: 22, height: 22),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: isLoading
              ? _buildLoadingState(appLocalizations)
              : (_isMaster
                    ? _buildMasterContent(appLocalizations)
                    : _buildClientContent(appLocalizations)),
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
                    activeItem: NavItem.account,
                    accountType: _accountTypeForNavBar!,
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

  Widget _buildLoadingState(AppLocalizations? appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F7EDE)),
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizations?.translate('loading_profile') ??
                'Загрузка профиля...',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

Widget _buildClientContent(AppLocalizations? appLocalizations) {
  final String lastName =
      userData?['lastname'] ??
      appLocalizations?.translate('not_specified') ??
      'Не указано';
  final String firstName = userData?['firstname'] ?? '';
  final String patronymic = userData?['patronymic'] ?? '';
  final String phone =
      userData?['telephone'] ??
      appLocalizations?.translate('not_specified') ??
      'Не указан';

  return RefreshIndicator(
    onRefresh: _loadUserProfile,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  _buildAvatar(
                    isMaster: _isMaster,
                    appLocalizations: appLocalizations,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lastName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D2125),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (firstName.isNotEmpty || patronymic.isNotEmpty)
                    Text(
                      '$firstName $patronymic'.trim(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F7EDE),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildMenuButton(
              icon: 'assets/list.png',
              title: appLocalizations?.translate('my_orders') ?? 'Мои заказы',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyOrdersClientPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              icon: 'assets/help.png',
              title: appLocalizations?.translate('help') ?? 'Помощь',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
            const SizedBox(height: 30),
            _buildTermsAndConditions(appLocalizations),
            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  );
}
Widget _buildMasterContent(AppLocalizations? appLocalizations) {
  final String lastName =
      userData?['lastname'] ??
      appLocalizations?.translate('not_specified') ??
      'Не указано';
  final String firstName = userData?['firstname'] ?? '';
  final String patronymic = userData?['patronymic'] ?? '';
  final String phone =
      userData?['telephone'] ??
      appLocalizations?.translate('not_specified') ??
      'Не указан';

  return RefreshIndicator(
    onRefresh: () async {
      await _loadUserProfile();
      await _loadMasterWorks();
    },
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  _buildAvatar(
                    isMaster: _isMaster,
                    appLocalizations: appLocalizations,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lastName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D2125),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$firstName $patronymic'.trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5F6368),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F7EDE),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCategorySelector(appLocalizations),
            const SizedBox(height: 20),
            _buildSocialLinks(appLocalizations),
            const SizedBox(height: 20),
            _buildSubscriptionBlock(appLocalizations),
            const SizedBox(height: 24),
            _buildReviewsStats(appLocalizations),
            const SizedBox(height: 20),
            _buildReviewsList(appLocalizations),
            const SizedBox(height: 24),
            _buildMyWorksSection(appLocalizations),
            const SizedBox(height: 30),
            _buildTermsAndConditions(appLocalizations),
            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildAvatar({
    required bool isMaster,
    required AppLocalizations? appLocalizations,
  }) {
    String? avatarUrl = userData?['avatar'];
    String displayLetter = userData?['firstname']?.isNotEmpty == true
        ? userData!['firstname'][0].toUpperCase()
        : '?';

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF96C5EB), Color(0xFF0F7EDE)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7EDE).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    'http://gj-back.checkedout.kz/storage/$avatarUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          displayLetter,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      displayLetter,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _navigateToEditProfile,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0F7EDE),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AppLocalizations? appLocalizations) {
    final categoriesList = userData?['categories'] as List?;
    final hasCategories = categoriesList != null && categoriesList.isNotEmpty;

    if (!hasCategories) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations?.translate('my_categories') ?? 'Мои категории',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToEditProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0F7EDE).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F7EDE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: Color(0xFF0F7EDE),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLocalizations?.translate('add_categories') ??
                                  'Добавить категории',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D2125),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appLocalizations?.translate(
                                    'select_service_categories',
                                  ) ??
                                  'Выберите категории услуг',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8D90),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF0F7EDE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLocalizations?.translate('my_categories') ?? 'Мои категории',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF41454A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${categoriesList.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F7EDE),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoriesList.map((category) {
              final colors = [
                const Color(0xFFE3F2FD),
                const Color(0xFFE8F5E9),
                const Color(0xFFFFF3E0),
                const Color(0xFFF3E5F5),
                const Color(0xFFFFEBEE),
                const Color(0xFFE0F2F1),
              ];
              final colorIndex =
                  (category['name']?.hashCode ?? 0).abs() % colors.length;
              final bgColor = colors[colorIndex];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: bgColor.withOpacity(0.5)),
                ),
                child: Text(
                  category['name'] ??
                      appLocalizations?.translate('category') ??
                      'Категория',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: bgColor.computeLuminance() > 0.5
                        ? const Color(0xFF1D2125)
                        : Colors.white,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToEditProfile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF0F7EDE),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appLocalizations?.translate('edit_categories') ??
                          'Редактировать категории',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F7EDE),
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
    );
  }

  Widget _buildSocialLinks(AppLocalizations? appLocalizations) {
    final hasTikTok =
        userData?['ttUsername'] != null &&
        userData!['ttUsername'].toString().isNotEmpty;
    final hasInstagram =
        userData?['instUsername'] != null &&
        userData!['instUsername'].toString().isNotEmpty;

    if (!hasTikTok && !hasInstagram) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations?.translate('social_media') ?? 'Социальные сети',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToEditProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0F7EDE).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F7EDE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.alternate_email,
                          color: Color(0xFF0F7EDE),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLocalizations?.translate('add_social_media') ??
                                  'Добавить соцсети',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D2125),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appLocalizations?.translate(
                                    'instagram_and_tiktok',
                                  ) ??
                                  'Instagram и TikTok',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8D90),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF0F7EDE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations?.translate('social_media') ?? 'Социальные сети',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: 'assets/tiktok.png',
                  username: userData?['ttUsername'],
                  platform: 'tiktok',
                  color: Colors.black,
                  appLocalizations: appLocalizations,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  icon: 'assets/instagram.png',
                  username: userData?['instUsername'],
                  platform: 'instagram',
                  color: const Color(0xFFE4405F),
                  appLocalizations: appLocalizations,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String? username,
    required String platform,
    required Color color,
    required AppLocalizations? appLocalizations,
  }) {
    final hasUsername = username != null && username.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasUsername
            ? () => _openSocialLink(username, platform)
            : _navigateToEditProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasUsername ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUsername
                  ? color.withOpacity(0.3)
                  : const Color(0xFFE8E8E8),
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                icon,
                width: 32,
                height: 32,
                color: hasUsername ? null : Colors.grey,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    platform == 'tiktok'
                        ? Icons.music_note
                        : Icons.alternate_email,
                    color: hasUsername ? color : Colors.grey,
                    size: 32,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                hasUsername
                    ? '@${username.length > 10 ? '${username.substring(0, 10)}...' : username}'
                    : appLocalizations?.translate('not_specified') ??
                          'Не указан',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasUsername ? FontWeight.w500 : FontWeight.w400,
                  color: hasUsername
                      ? const Color(0xFF41454A)
                      : const Color(0xFF9AA0A6),
                  fontFamily: 'Plus Jakarta Sans',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasUsername) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: Color(0xFF0F7EDE),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBlock(AppLocalizations? appLocalizations) {
    final subscriptions = userData?['subscriptions'] as List?;
    final hasSubscription = subscriptions != null && subscriptions.isNotEmpty;

    if (!hasSubscription) {
      return GestureDetector(
        onTap: () => _launchUrl(
          'https://qr.kaspi.kz/19134627698424934147714893150004931409130',
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F7EDE), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7EDE).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        appLocalizations?.translate('premium_subscription') ??
                            'Премиум\nподписка',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '2 000 ₸',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        Text(
                          '/месяц',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                            fontFamily: 'Plus Jakarta Sans',
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
      );
    }

    final subscription = subscriptions!.first;
    final endAt = subscription['endAt'] as String?;

    String formattedDate = '';
    if (endAt != null) {
      try {
        final dateTime = DateTime.parse(endAt);
        formattedDate =
            '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
      } catch (e) {
        formattedDate =
            appLocalizations?.translate('date_not_specified') ??
            'Дата не указана';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F4FF), Color(0xFFD4E9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7EDE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.stars, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizations?.translate('subscription_active') ??
                      'Подписка активна',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appLocalizations?.translate('until') ?? 'до'} $formattedDate',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1565C0),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              appLocalizations?.translate('active') ?? 'Активно',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionFeature(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsStats(AppLocalizations? appLocalizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations?.translate('client_reviews') ?? 'Отзывы клиентов',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9E7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF41454A),
                        ),
                      ),
                      Text(
                        appLocalizations?.translate('out_of_5') ?? 'из 5',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8A8D90),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(
                      5,
                      _getRatingPercentage(5),
                      appLocalizations,
                    ),
                    _buildRatingBar(
                      4,
                      _getRatingPercentage(4),
                      appLocalizations,
                    ),
                    _buildRatingBar(
                      3,
                      _getRatingPercentage(3),
                      appLocalizations,
                    ),
                    _buildRatingBar(
                      2,
                      _getRatingPercentage(2),
                      appLocalizations,
                    ),
                    _buildRatingBar(
                      1,
                      _getRatingPercentage(1),
                      appLocalizations,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appLocalizations?.translate('total_reviews') ??
                      'Всего отзывов:',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5F6368),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                Text(
                  '$_totalReviews',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F7EDE),
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

  Widget _buildRatingBar(
    int stars,
    double percentage,
    AppLocalizations? appLocalizations,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$stars ★',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF41454A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8D90)),
            ),
          ),
        ],
      ),
    );
  }

  double _getRatingPercentage(int stars) {
    if (_reviews.isEmpty) return 0;
    final count = _reviews.where((r) => r.rating == stars).length;
    return count / _reviews.length;
  }

  Widget _buildReviewsList(AppLocalizations? appLocalizations) {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F7EDE)),
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              appLocalizations?.translate('no_reviews_yet') ??
                  'Пока нет отзывов',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5F6368),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations?.translate('reviews_will_appear') ??
                  'Когда клиенты начнут оставлять отзывы, они появятся здесь',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0E0E0),
                    child: Text(
                      review.client.firstname.isNotEmpty
                          ? review.client.firstname[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF41454A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.client.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        if (review.createdAt != null)
                          Text(
                            _formatDate(review.createdAt!.toIso8601String()),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          review.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF41454A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review.comment!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMyWorksSection(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appLocalizations?.translate('my_works') ?? 'Мои работы',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D2125),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            if (isLoadingWorks)
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
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: portfolioImages.isEmpty && !isLoadingWorks
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appLocalizations?.translate('no_works_uploaded') ??
                              'Нет загруженных работ',
                          style: const TextStyle(
                            color: Color(0xFF8A8D90),
                            fontSize: 16,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openEditPortfolioPage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F7EDE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                appLocalizations?.translate('add_work') ??
                                    'Добавить работу',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                    itemCount: portfolioImages.length + 1,
                    itemBuilder: (context, index) {
                      const double r = 12;
                      BorderRadius radius = BorderRadius.zero;

                      if (index == 0)
                        radius = const BorderRadius.only(
                          topLeft: Radius.circular(r),
                        );
                      else if (index == 2)
                        radius = const BorderRadius.only(
                          topRight: Radius.circular(r),
                        );
                      else if (index == 6)
                        radius = const BorderRadius.only(
                          bottomLeft: Radius.circular(r),
                        );
                      else if (index == 8)
                        radius = const BorderRadius.only(
                          bottomRight: Radius.circular(r),
                        );

                      if (index == portfolioImages.length) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openEditPortfolioPage,
                            borderRadius: radius,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: radius,
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 32,
                                    color: Color(0xFF0F7EDE),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Добавить',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0F7EDE),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (index < portfolioImages.length) {
                        final workPhoto = portfolioImages[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openEditPortfolioPage,
                            borderRadius: radius,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'http://gj-back.checkedout.kz/storage/${workPhoto.path}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: radius,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon == 'assets/help.png')
                const Icon(
                  Icons.help_outline,
                  color: Color(0xFF41454A),
                  size: 24,
                )
              else
                Image.asset(
                  icon,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.help_outline,
                      color: Color(0xFF41454A),
                      size: 24,
                    );
                  },
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF9AA0A6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
