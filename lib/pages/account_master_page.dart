import 'package:flutter/material.dart';
import 'edit_profile_info_page_master.dart';
import 'dart:ui';

class AccountMasterPage extends StatelessWidget {
  const AccountMasterPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // УБРАН const перед EditProfileInfoPageMaster()
                                  builder: (context) => EditProfileInfoPageMaster(),
                                ),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F7EDE),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/edit.png',
                                  width: 18,
                                  height: 18,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Константинов',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const Text(
                      'Константин Константинович',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '+ 7 (777) 777-77-77',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 🔽 Select / Category
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
                          border: Border.all(color: Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/handyman.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Категория',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const Spacer(),
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
              // 🔹 Subscription block
              GestureDetector(
                onTap: () {
                  _showSubscribeModal(context);
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7EDE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
              ),
              const SizedBox(height: 34),
              const Text(
                'Мои работы',
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

                  // последний блок "+"
                  if (index == 8) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: radius,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          size: 26,
                          color: Color(0xFF0F7EDE),
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      image: const DecorationImage(
                        image: AssetImage('assets/work_sample.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 80,
              ), // Отступ чтобы не заезжала под bottom nav
            ],
          ),
        ),
      ),

      // 🔽 Bottom Navigation Bar
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(54),
          topRight: Radius.circular(54),
        ),
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Работа
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/work.png',
                    width: 24,
                    height: 24,
                    color: Color(0xFF5F6368),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Работа',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
              // Прайс
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/price.png',
                    width: 24,
                    height: 24,
                    color: Color(0xFF5F6368),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Прайс',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
              // Аккаунт (активная)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/account.png',
                    width: 24,
                    height: 24,
                    color: Color(0xFF0F7EDE),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Аккаунт',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F7EDE),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Функция для отображения модального окна подписки
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
                          onTap: () {
                            setState(() => isSent = true);
                          },
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
                          onTap: () {
                            Navigator.pop(context);
                          },
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

  // Вспомогательный метод для полей (чтобы не дублировать код)
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

  // Вспомогательный метод для кнопки
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