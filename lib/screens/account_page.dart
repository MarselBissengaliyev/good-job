import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/models/work-photo.dart';
import 'package:flutter_application_1/screens/edit_portfolio_master_page.dart';
import 'package:flutter_application_1/screens/edit_profile_page.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  List<WorkPhoto> portfolioImages = []; // Для мастеров - реальные работы
  String? selectedCategory; // Для мастеров
  dynamic _activeMode; // Храним режим пользователя
  List<dynamic> categories = [];
  bool isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

          // Если пользователь мастер - загружаем категории и работы
          if (_isMaster) {
            _loadCategories();
            _loadMasterWorks();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки профиля: $e')));
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

  Future<void> _loadCategories() async {
    if (!mounted) return;

    try {
      setState(() => isLoadingCategories = true);

      final categoriesData = await ApiService.getCategories();

      if (mounted) {
        setState(() {
          categories = categoriesData;
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки категорий: $e')),
        );
      }
    }
  }

  Future<void> _updateUserCategory(int categoryId) async {
    try {
      setState(() => isLoading = true);

      final response = await ApiService.updateUserCategory(categoryId);

      if (mounted) {
        setState(() {
          // Обновляем данные пользователя
          if (userData != null && response['data'] != null) {
            userData!['category'] = response['data']['category'];
          }

          // Находим выбранную категорию для отображения
          final selectedCategoryData = categories.firstWhere(
            (cat) => cat['id'] == categoryId,
            orElse: () => null,
          );

          if (selectedCategoryData != null) {
            selectedCategory = selectedCategoryData['name'];
          }

          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Категория успешно обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления категории: $e')),
        );
      }
    }
  }

  bool get _isMaster => _activeMode == 'master';

  // Метод для определения типа аккаунта для bottom navigation
  AccountType? get _accountTypeForNavBar {
    if (_activeMode == null) return null; // Еще загружается
    if (_activeMode == 'master') return AccountType.master;
    return AccountType.client;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        centerTitle: true,
        title: const Text(
          'Аккаунт',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
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
      body: isLoading
          ? _buildLoadingState()
          : (_isMaster ? _buildMasterContent() : _buildClientContent()),
      bottomNavigationBar: _accountTypeForNavBar == null
          ? null // Пока не определился тип аккаунта, не показываем навигацию
          : CustomBottomNavBar(
              activeItem: NavItem.account,
              accountType: _accountTypeForNavBar!,
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
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF41454A),
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
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
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
                  MaterialPageRoute(
                    builder: (context) => const MyOrdersClientPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                icon: 'assets/help.png',
                title: 'Помощь',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Раздел "Помощь" в разработке'),
                    ),
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
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    Text(
                      '$firstName $patronymic'.trim(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildCategorySelector(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildSocialLinks(),
              const SizedBox(height: 24),
              _buildSubscriptionBlock(),
              const SizedBox(height: 34),
              _buildMyWorksSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isMaster}) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF96C5EB),
            border: Border.all(color: const Color(0xFF0F7EDE), width: 2),
            image: const DecorationImage(
              image: AssetImage('assets/avatar.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      initialMode: isMaster
                          ? ProfileMode.master
                          : ProfileMode.client,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _loadUserProfile();
                }),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0F7EDE),
                shape: BoxShape.circle,
                boxShadow: isMaster
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Image.asset(
                  'assets/edit.png',
                  width: 18,
                  height: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Выберите категорию',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF41454A),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Поле поиска (опционально)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск категорий...',
                        hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9AA0A6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Список категорий
                  Expanded(
                    child: isLoadingCategories
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0F7EDE),
                              ),
                            ),
                          )
                        : categories.isEmpty
                        ? const Center(
                            child: Text(
                              'Категории не найдены',
                              style: TextStyle(
                                color: Color(0xFF9AA0A6),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected =
                                  userData?['category']?['id'] ==
                                  category['id'];

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _updateUserCategory(category['id']);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category['name'] ?? 'Без названия',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? const Color(0xFF0F7EDE)
                                                  : const Color(0xFF41454A),
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check,
                                            color: Color(0xFF0F7EDE),
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Кнопка закрытия
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Закрыть',
                        style: TextStyle(
                          color: Color(0xFF41454A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return GestureDetector(
      onTap: () => _showCategoryBottomSheet(context),
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Image.asset('assets/handyman.png', width: 24, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userData?['category']?['name'] ?? 'Выберите категорию',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF41454A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9AA0A6)),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Row(
      children: [
        // TikTok
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Image.asset('assets/tiktok.png', width: 24, height: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userData?['ttUrl'] ?? 'TikTok',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF41454A),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Instagram
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Image.asset('assets/instagram.png', width: 24, height: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userData?['instUrl'] ?? 'Instagram',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF41454A),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBlock() {
    return GestureDetector(
      onTap: () => _showSubscribeModal(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F7EDE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Купить\nподписку',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        '4 999',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'тг. / мес.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0x36FFFFFF)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/check.png',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Публикация услуг',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.asset(
                        'assets/check.png',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Отображение номера заказчика',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
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
                fontWeight: FontWeight.w500,
                color: Color(0xFF41454A),
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

        // Отображение работ в виде сетки
        if (portfolioImages.isEmpty && !isLoadingWorks)
          Center(
            child: Column(
              children: [
                Icon(Icons.photo_library, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text(
                  'Нет загруженных работ',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Нажмите + чтобы добавить первую работу',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1,
            ),
            itemCount: portfolioImages.length + 1, // +1 для кнопки добавления
            itemBuilder: (context, index) {
              const double r = 12;
              BorderRadius radius = BorderRadius.zero;

              // Определяем скругления углов
              if (index == 0)
                radius = const BorderRadius.only(topLeft: Radius.circular(r));
              else if (index == 2)
                radius = const BorderRadius.only(topRight: Radius.circular(r));
              else if (index == 6)
                radius = const BorderRadius.only(
                  bottomLeft: Radius.circular(r),
                );
              else if (index == 8)
                radius = const BorderRadius.only(
                  bottomRight: Radius.circular(r),
                );

              // Кнопка добавления (последняя ячейка)
              if (index == portfolioImages.length) {
                return GestureDetector(
                  onTap: () => _openEditPortfolioPage(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: radius,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 32,
                        color: Color(0xFF0F7EDE),
                      ),
                    ),
                  ),
                );
              }

              // Отображение реальных работ
              if (index < portfolioImages.length) {
                final workPhoto = portfolioImages[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    image: DecorationImage(
                      image: NetworkImage(
                        'http://gj-back.checkedout.kz/storage/${workPhoto.path}',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Градиент для лучшей видимости (опционально)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Можно добавить иконку удаления или другую информацию
                    ],
                  ),
                );
              }

              // Пустые ячейки (если работ меньше 8)
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: radius,
                ),
              );
            },
          ),
      ],
    );
  }

  void _openEditPortfolioPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditPortfolioMasterPage()),
    ).then((_) {
      // Обновляем список работ после возвращения со страницы редактирования
      if (mounted) {
        _loadMasterWorks();
      }
    });
  }

  Widget _buildMenuButton({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Image.asset(icon, width: 24, height: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF41454A),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Color(0xFF9AA0A6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Методы для модального окна подписки
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
                  borderRadius: BorderRadius.circular(12),
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
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Почта', TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildTextField('Номер', TextInputType.phone),
                        const SizedBox(height: 32),
                        _buildButton(
                          text: 'Отправить',
                          onTap: () => setState(() => isSent = true),
                        ),
                      ] else ...[
                        const Text(
                          'Запрос отправлен',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF41454A),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Image.asset(
                          'assets/check.png',
                          width: 80,
                          height: 80,
                          color: const Color(0xFF1DCE6A),
                        ),
                        const SizedBox(height: 32),
                        _buildButton(
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

  Widget _buildButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
      ),
    );
  }
}