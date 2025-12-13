import 'package:flutter/material.dart';

import 'registration_4_page.dart';

class Registration3Page extends StatefulWidget {
  const Registration3Page({super.key});

  @override
  State<Registration3Page> createState() => _Registration3PageState();
}

class _Registration3PageState extends State<Registration3Page> {
  String? selectedCity;
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  bool get isFormValid {
    // Проверяем, заполнены ли все поля
    return nameController.text.isNotEmpty &&
        surnameController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        selectedCity != null;
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // фон всего экрана
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

              const Spacer(),

              // Нижний контент
              Column(
                children: [
                  const Text(
                    'Регистрация',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                      color: Color(0xFF41454A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Форма
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      labelStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: 'Фамилия',
                      labelStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Выпадающий список для города
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    isExpanded: true,
                    hint: const Text('Выберите город'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Уральск',
                        child: Text('Уральск'),
                      ),
                      DropdownMenuItem(value: 'Алматы', child: Text('Алматы')),
                      DropdownMenuItem(value: 'Астана', child: Text('Астана')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Телефон',
                      labelStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Текст с подчеркиванием
                  // Текст с подчеркиванием на отдельной строке
                  Column(
                    children: [
                      const Text(
                        'Создавая аккаунт, вы принимаете',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF5F6368),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 4,
                      ), // небольшой отступ между строками
                      Text(
                        'Договор публичной офферты',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF5F6368),
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Кнопка с проверкой состояния формы
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFormValid
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const Registration4Page(),
                                ),
                              );
                            }
                          : null, // Кнопка неактивна, если форма невалидна
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFormValid
                            ? Colors.blue
                            : const Color(0xFFBABABA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Получить код подтверждения',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'Plus Jakarta Sans',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'или',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF5F6368),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
