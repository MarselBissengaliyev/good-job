import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/edit_profile_page.dart';
import 'package:goodjob/screens/home_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'role_provider.dart';
import 'services/api_service.dart';
import 'services/auth/auth_service.dart';
import 'providers/language_provider.dart';
import 'localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(const Duration(milliseconds: 100));

  // Проверяем, авторизован ли пользователь
  final isLoggedIn = await AuthService.isLoggedIn();
  final userRole = await AuthService.getUserRole();

  print('Main - isLoggedIn: $isLoggedIn, userRole: $userRole'); // Отладка

  runApp(MyApp(initialRoute: _getInitialRoute(isLoggedIn, userRole)));
}

String _getInitialRoute(bool isLoggedIn, String? userRole) {
  if (!isLoggedIn) {
    return '/registration';
  }

  // Определяем куда перенаправить в зависимости от роли
  if (userRole == 'master') {
    return '/master-home';
  } else {
    return '/client-home';
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'GoodJob',
            locale: languageProvider.locale,
            supportedLocales: const [Locale('ru', ''), Locale('kk', '')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
              '/registration': (context) => const MyHomePage(),
              '/master-home': (context) => const MasterHomePage(),
              '/client-home': (context) => const ClientHomePage(),
            },
            onGenerateRoute: (settings) {
              // Обработка динамических маршрутов
              if (settings.name == '/account-master') {
                return MaterialPageRoute(
                  builder: (context) => const EditProfilePage(initialMode: ProfileMode.master),
                );
              }
              if (settings.name == '/account-client') {
                return MaterialPageRoute(
                  builder: (context) => const AccountPage(accountType: AccountType.client),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

// Главная страница для мастера
class MasterHomePage extends StatelessWidget {
  const MasterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfilePage(initialMode: ProfileMode.master);
  }
}

// Главная страница для клиента
class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountPage(accountType: AccountType.client);
  }
}

// Удаляем AuthChecker, так как он больше не нужен и вызывает проблемы