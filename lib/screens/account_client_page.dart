import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_client_page.dart';
import 'my_orders_client_page.dart';

class AccountClientPage extends StatefulWidget {
  const AccountClientPage({super.key});

  @override
  State<AccountClientPage> createState() => _AccountClientPageState();
}

class _AccountClientPageState extends State<AccountClientPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiService.getProfile();
      setState(() {
        userData = response['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки профиля: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Формируем ФИО из данных API
    final String lastName = userData?['lastname'] ?? 'Загрузка...';
    final String firstName = userData?['firstname'] ?? '';
    final String patronymic = userData?['patronymic'] ?? '';
    final String phone = userData?['telephone'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF41454A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
              if (mounted) Navigator.pushReplacementNamed(context, '/registration');
            },
            icon: Image.asset('assets/logout.png', width: 22, height: 22),
          ),
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          _buildAvatar(),
                          const SizedBox(height: 16),
                          // Отображаем Фамилию
                          Text(
                            lastName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          // Отображаем Имя и Отчество
                          Text(
                            '$firstName $patronymic',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Телефон
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
                        MaterialPageRoute(builder: (context) => const MyOrdersClientPage()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: 'assets/help.png',
                      title: 'Помощь',
                      onTap: () { /* Действие */ },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAvatar() {
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfileClientPage()),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF0F7EDE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset('assets/edit.png', width: 18, height: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({required String icon, required String title, required VoidCallback onTap}) {
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
                    style: const TextStyle(fontSize: 17, color: Color(0xFF41454A)),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF9AA0A6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(54), topRight: Radius.circular(54)),
      child: Container(
        height: 70,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem('assets/work.png', 'Работа', false),
            _navItem('assets/price.png', 'Прайс', false),
            _navItem('assets/account.png', 'Аккаунт', true),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String icon, String label, bool isActive) {
    final color = isActive ? const Color(0xFF0F7EDE) : const Color(0xFF5F6368);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(icon, width: 24, height: 24, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}