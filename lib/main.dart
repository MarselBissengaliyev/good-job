import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/screens/account_master_page.dart';
import 'package:flutter_application_1/screens/account_client_page.dart';
import 'package:provider/provider.dart';
import 'role_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          fontFamily: 'Plus Jakarta Sans',
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFAFAFA),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthChecker(),
          '/registration': (context) => const MyHomePage(),
          '/account-master': (context) => const AccountMasterPage(),
          '/account-client': (context) => const AccountClientPage(),
        },
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (mounted) {
      if (isLoggedIn) {
        // Если авторизован, получаем роль и переходим на соответствующую страницу
        try {
          final role = await _getUserRole();
          
          if (role == 'master') {
            Navigator.pushReplacementNamed(context, '/account-master');
          } else {
            Navigator.pushReplacementNamed(context, '/account-client');
          }
        } catch (e) {
          // Если ошибка при получении роли, показываем экран регистрации
          print('Ошибка получения роли: $e');
          Navigator.pushReplacementNamed(context, '/registration');
        }
      } else {
        // Если не авторизован, идем на регистрацию
        Navigator.pushReplacementNamed(context, '/registration');
      }
    }
  }

  Future<String> _getUserRole() async {
    // 1. Сначала пытаемся получить роль из SharedPreferences
    final savedRole = await AuthService.getUserRole();
    if (savedRole != null && savedRole.isNotEmpty) {
      return savedRole;
    }

    // 2. Если нет сохраненной роли, запрашиваем профиль с API
    try {
      final profileResponse = await ApiService.getProfile();
      final activeMode = profileResponse['data']['active_mode'] as String;
      
      // Сохраняем роль для будущего использования
      await AuthService.saveUserRole(activeMode);
      
      return activeMode;
    } catch (e) {
      print('Ошибка при получении профиля: $e');
      throw Exception('Не удалось определить роль пользователя');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Проверка авторизации...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}