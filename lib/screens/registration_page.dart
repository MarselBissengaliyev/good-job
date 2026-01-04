import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../role_provider.dart';
import 'registration_3_page.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

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
              // Верхняя панель со стрелкой и логотипом
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  Image.asset('assets/logo.png', height: 28),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 50),

              // Центрированный блок с заголовком, подзаголовком и выбором роли
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок H1
                      const Text(
                        'Регистрация',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Подзаголовок Body_text
                      const Text(
                        'Кем вы являетесь?',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Ряд с двумя ролями
                      Row(
                        children: [
                          // Мастер
                          Expanded(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    roleProvider.selectMaster();
                                  },
                                  child: Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: roleProvider.isMasterSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: roleProvider.isMasterSelected
                                            ? 2
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: roleProvider.isMasterSelected
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      left: 12,
                                      right: 12,
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Image.asset(
                                        'assets/master.png',
                                        fit: BoxFit.contain,
                                        color: roleProvider.isMasterSelected
                                            ? Colors.blue
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Я - Мастер',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: roleProvider.isMasterSelected
                                        ? Colors.blue
                                        : Colors.black,
                                    fontWeight: roleProvider.isMasterSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Заказчик
                          Expanded(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    roleProvider.selectClient();
                                  },
                                  child: Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: roleProvider.isClientSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: roleProvider.isClientSelected
                                            ? 2
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: roleProvider.isClientSelected
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      left: 12,
                                      right: 12,
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Image.asset(
                                        'assets/client.png',
                                        fit: BoxFit.contain,
                                        color: roleProvider.isClientSelected
                                            ? Colors.blue
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Я - Заказчик',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: roleProvider.isClientSelected
                                        ? Colors.blue
                                        : Colors.black,
                                    fontWeight: roleProvider.isClientSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Кнопка "Далее" внизу
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: roleProvider.isRoleSelected
                      ? () {
                          // Переход на Registration3Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Registration3Page(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleProvider.isRoleSelected
                        ? Colors.blue
                        : Colors.grey,
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