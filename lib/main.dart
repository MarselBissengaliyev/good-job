import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:provider/provider.dart';

import 'role_provider.dart';
import 'services/api_service.dart';
import 'services/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Проверяем, авторизован ли пользователь
  final isLoggedIn = await AuthService.isLoggedIn();
  final userRole = await AuthService.getUserRole();

  runApp(MyApp(initialRoute: _getInitialRoute(isLoggedIn, userRole)));
}

String _getInitialRoute(bool isLoggedIn, String? userRole) {
  if (!isLoggedIn) {
    return '/';
  }

  // Определяем куда перенаправить в зависимости от роли
  if (userRole == 'master') {
    return '/account-master';
  } else {
    return '/account-client';
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => RoleProvider())],
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
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const AuthChecker(),
          '/registration': (context) => const MyHomePage(),
          '/account-master': (context) =>
              const AccountPage(accountType: AccountType.master),
          '/account-client': (context) =>
              const AccountPage(accountType: AccountType.client),
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
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final role = await _getUserRole();

      if (mounted) {
        if (role == 'master') {
          Navigator.pushReplacementNamed(context, '/account-master');
        } else {
          Navigator.pushReplacementNamed(context, '/account-client');
        }
      }
    } catch (e) {
      print('Авторизация не пройдена: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/registration');
      }
    }
  }

  Future<String> _getUserRole() async {
    try {
      final profileResponse = await ApiService.getProfile();
      final activeMode = profileResponse['data']['active_mode'] as String;
      await AuthService.saveUserRole(activeMode);

      return activeMode;
    } catch (e) {
      rethrow;
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
