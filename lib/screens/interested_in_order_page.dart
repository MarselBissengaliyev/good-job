import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/auth/auth_service.dart';

class InterestedInOrderPage extends StatelessWidget {
  final Map<String, dynamic> viewer;
  final Map<String, dynamic> order;

  const InterestedInOrderPage({
    super.key,
    required this.viewer,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    // Используем данные из параметров viewer
    final viewerName = viewer['name'] ?? 'Константинов';
    final viewerPhone = viewer['phone'] ?? '+7 (777) 777-77-77';
    final viewerSpecialty = viewer['specialty'] ?? 'Мастер';
    final viewerAvatar = viewer['avatar'] ?? 'assets/avatar.png';

    // Парсим имя и фамилию
    final nameParts = viewerName.split(' ');
    final lastName = nameParts.isNotEmpty ? nameParts[0] : 'Константинов';
    final fullName = nameParts.length > 1
        ? nameParts[1]
        : 'Константин Константинович';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF41454A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Мастер',
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
            },
            icon: Image.asset('assets/logout.png', width: 22, height: 22),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF96C5EB),
                            border: Border.all(
                              color: const Color(0xFF0F7EDE),
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: AssetImage(viewerAvatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      viewerPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 🔽 Select / Category с данными из viewer
                    GestureDetector(
                      onTap: () {
                        // TODO: открыть bottom sheet / dropdown
                      },
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
                            Image.asset(
                              'assets/handyman.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                viewerSpecialty,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF9AA0A6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // 🔹 TikTok
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
                          Image.asset(
                            'assets/tiktok.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'TikTok',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 🔹 Instagram
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
                          Image.asset(
                            'assets/instagram.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Instagram',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 🔹 Работы мастера
              const Text(
                'Работы мастера',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF41454A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 16),
              // Grid of works
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childAspectRatio: 1,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  const double r = 12;

                  BorderRadius radius = BorderRadius.zero;

                  if (index == 0) {
                    radius = const BorderRadius.only(
                      topLeft: Radius.circular(r),
                    );
                  } else if (index == 2) {  
                    radius = const BorderRadius.only(
                      topRight: Radius.circular(r),
                    );
                  } else if (index == 6) {
                    radius = const BorderRadius.only(
                      bottomLeft: Radius.circular(r),
                    );
                  } else if (index == 8) {
                    radius = const BorderRadius.only(
                      bottomRight: Radius.circular(r),
                    );
                  }

                  // Тут можно заменить на реальный список изображений
                  final List<String?> works = [
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    'assets/work_sample.png',
                    null, // последний блок пустой
                  ];

                  final workImage = works[index];

                  if (workImage == null) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: radius,
                      ),
                      child: const SizedBox.shrink(), // ничего не показываем
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      image: DecorationImage(
                        image: AssetImage(workImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Отступ чтобы контент не заезжал под кнопку
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Кнопка фиксированная над навигацией
      floatingActionButton: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.fromLTRB(61, 0, 61, 77), // 61px от боков, 16px от навигации
        child: ElevatedButton(
          onPressed: () {
            // TODO: Логика связи с мастером
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F7EDE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/call.png',
                width: 22,
                height: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Text(
                'Связаться с мастером',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔽 Bottom Navigation Bar
    bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.account, // Указываем активную вкладку
        accountType: AccountType.client,
      ),
    );
  }
}