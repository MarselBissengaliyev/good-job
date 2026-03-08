import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/models/work-photo.dart';
import 'package:flutter_application_1/screens/edit_portfolio_master_page.dart';
import 'package:flutter_application_1/screens/edit_profile_page.dart';
import 'package:flutter_application_1/screens/help_page.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isLoadingWorks = false;
  List<WorkPhoto> portfolioImages = [];
  String? selectedCategory;
  dynamic _activeMode;
  List<dynamic> categories = [];
  bool isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть ссылку: $url')),
        );
      }
    }
  }

  Future<void> _openSocialLink(String? username, String platform) async {
    if (username == null || username.isEmpty) {
      _showSnackBar('Имя пользователя не указано', isError: true);
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
      _showSnackBar('Ошибка при открытии ссылки', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF0F7EDE),
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

          print('Загружены данные пользователя: $userData');
          print('Active mode: $_activeMode');
          print('Категории мастера: ${userData?['categories']}');

          if (_isMaster) {
            _loadMasterWorks();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
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
          print('✅ Загружено ${portfolioImages.length} работ мастера');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingWorks = false);
        print('❌ Ошибка загрузки работ мастера: $e');
      }
    }
  }

  bool get _isMaster => _activeMode == 'master';

  AccountType? get _accountTypeForNavBar {
    if (_activeMode == null) return null;
    if (_activeMode == 'master') return AccountType.master;
    return AccountType.client;
  }

  void _navigateToEditProfile() {
    ProfileMode mode = _isMaster ? ProfileMode.master : ProfileMode.client;

    print('Навигация на EditProfilePage с режимом: $mode');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage(initialMode: mode)),
    ).then((result) {
      if (mounted) {
        _loadUserProfile();
        if (_isMaster) {
          _loadMasterWorks();
        }
      }
    });
  }

  void _openEditPortfolioPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditPortfolioMasterPage()),
    ).then((_) {
      if (mounted) {
        _loadMasterWorks();
      }
    });
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
          title: const Text(
            'Аккаунт',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await AuthService.clearAuthData();
                if (mounted) Navigator.pushReplacementNamed(context, '/registration');
              },
              icon: Image.asset('assets/logout.png', width: 22, height: 22),
            ),
          ],
        ),
        body: isLoading
            ? _buildLoadingState()
            : (_isMaster ? _buildMasterContent() : _buildClientContent()),
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F7EDE)),
          ),
          SizedBox(height: 16),
          Text(
            'Загрузка профиля...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientContent() {
    final String lastName = userData?['lastname'] ?? 'Не указано';
    final String firstName = userData?['firstname'] ?? '';
    final String patronymic = userData?['patronymic'] ?? '';
    final String phone = userData?['telephone'] ?? 'Не указан';

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
                    _buildAvatar(isMaster: _isMaster),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                title: 'Мои заказы',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersClientPage()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                icon: 'assets/help.png',
                title: 'Помощь',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpPage()),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterContent() {
    final String lastName = userData?['lastname'] ?? 'Не указано';
    final String firstName = userData?['firstname'] ?? '';
    final String patronymic = userData?['patronymic'] ?? '';
    final String phone = userData?['telephone'] ?? 'Не указан';

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
                    _buildAvatar(isMaster: _isMaster),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              _buildCategorySelector(),
              const SizedBox(height: 20),
              _buildSocialLinks(),
              const SizedBox(height: 20),
              _buildSubscriptionBlock(),
              const SizedBox(height: 24),
              _buildMyWorksSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isMaster}) {
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
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
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
            const Text(
              'Мои категории',
              style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Добавить категории',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D2125),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Выберите категории услуг',
                              style: TextStyle(
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
              const Text(
                'Мои категории',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF41454A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              final colorIndex = (category['name']?.hashCode ?? 0).abs() % colors.length;
              final bgColor = colors[colorIndex];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: bgColor.withOpacity(0.5)),
                ),
                child: Text(
                  category['name'] ?? 'Категория',
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F7EDE)),
                    SizedBox(width: 8),
                    Text(
                      'Редактировать категории',
                      style: TextStyle(
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

  Widget _buildSocialLinks() {
    final hasTikTok = userData?['ttUsername'] != null &&
        userData!['ttUsername'].toString().isNotEmpty;
    final hasInstagram = userData?['instUsername'] != null &&
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
            const Text(
              'Социальные сети',
              style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Добавить соцсети',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D2125),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Instagram и TikTok',
                              style: TextStyle(
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
          const Text(
            'Социальные сети',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSocialButton(
                icon: 'assets/tiktok.png',
                username: userData?['ttUsername'],
                platform: 'tiktok',
                color: Colors.black,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSocialButton(
                icon: 'assets/instagram.png',
                username: userData?['instUsername'],
                platform: 'instagram',
                color: const Color(0xFFE4405F),
              )),
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
  }) {
    final hasUsername = username != null && username.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasUsername ? () => _openSocialLink(username, platform) : _navigateToEditProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasUsername ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUsername ? color.withOpacity(0.3) : const Color(0xFFE8E8E8),
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
                    platform == 'tiktok' ? Icons.music_note : Icons.alternate_email,
                    color: hasUsername ? color : Colors.grey,
                    size: 32,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                hasUsername
                    ? '@${username.length > 10 ? '${username.substring(0, 10)}...' : username}'
                    : 'Не указан',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasUsername ? FontWeight.w500 : FontWeight.w400,
                  color: hasUsername ? const Color(0xFF41454A) : const Color(0xFF9AA0A6),
                  fontFamily: 'Plus Jakarta Sans',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasUsername) ...[
                const SizedBox(height: 4),
                const Icon(Icons.open_in_new, size: 14, color: Color(0xFF0F7EDE)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBlock() {
    final subscriptions = userData?['subscriptions'] as List?;
    final hasSubscription = subscriptions != null && subscriptions.isNotEmpty;

    if (!hasSubscription) {
      return GestureDetector(
        onTap: () => _launchUrl(
            'https://qr.kaspi.kz/19134627698424934147714893150004931409130'),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Премиум\nподписка',
                        style: TextStyle(
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
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubscriptionFeature('Публикация услуг'),
                    _buildSubscriptionFeature('Просмотр номеров'),
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
        formattedDate = 'Дата не указана';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF),
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
                const Text(
                  'Подписка активна',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'до $formattedDate',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1565C0),
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

  Widget _buildMyWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Мои работы',
              style: TextStyle(
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
                        Icon(Icons.photo_library, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text(
                          'Нет загруженных работ',
                          style: TextStyle(
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
                              child: const Text(
                                'Добавить работу',
                                style: TextStyle(
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: portfolioImages.length + 1,
                    itemBuilder: (context, index) {
                      const double r = 12;
                      BorderRadius radius = BorderRadius.zero;

                      if (index == 0) {
                        radius = const BorderRadius.only(topLeft: Radius.circular(r));
                      } else if (index == 2) {
                        radius = const BorderRadius.only(topRight: Radius.circular(r));
                      } else if (index == 6) {
                        radius = const BorderRadius.only(
                          bottomLeft: Radius.circular(r),
                        );
                      } else if (index == 8) {
                        radius = const BorderRadius.only(
                          bottomRight: Radius.circular(r),
                        );
                      }

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
                                  Icon(Icons.add, size: 32, color: Color(0xFF0F7EDE)),
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
                const Icon(Icons.help_outline, color: Color(0xFF41454A), size: 24)
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
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9AA0A6)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscribeModal(BuildContext context) {
    bool isSent = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSent) ...[
                        const Text(
                          'Подтвердите\nзапрос на оплату',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D2125),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Почта', TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildTextField('Номер', TextInputType.phone),
                        const SizedBox(height: 24),
                        _buildDialogButton(
                          text: 'Отправить',
                          onTap: () => setState(() => isSent = true),
                        ),
                      ] else ...[
                        const Text(
                          'Запрос отправлен',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D2125),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Color(0xFF4CAF50),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDialogButton(
                          text: 'На главную',
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String hint, TextInputType type) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          keyboardType: type,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({required String text, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF0F7EDE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}