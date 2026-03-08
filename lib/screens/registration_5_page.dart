import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/screens/edit_profile_page.dart';
import 'package:provider/provider.dart';
import '../role_provider.dart';

class Registration5Page extends StatelessWidget {
  const Registration5Page({super.key});

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Верхняя панель
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Image.asset('assets/logo.png', height: 28),
                  const Spacer(flex: 2),
                ],
              ),

              const SizedBox(height: 24),

              // Центрированный контент
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Регистрация\nпройдена',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Image.asset('assets/check.png', width: 180, height: 180),
                    ],
                  ),
                ),
              ),

              // Кнопка "Далее" снизу
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Навигация на разные страницы в зависимости от роли
                    if (roleProvider.isMasterSelected) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountPage(accountType: AccountType.master),
                        ),
                      );
                    } else if (roleProvider.isClientSelected) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountPage(accountType: AccountType.client),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F7EDE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Далее',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}