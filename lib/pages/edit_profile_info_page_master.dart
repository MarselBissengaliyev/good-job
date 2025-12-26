import 'package:flutter/material.dart';

class EditProfileInfoPageMaster extends StatefulWidget {
  const EditProfileInfoPageMaster({super.key});

  @override
  State<EditProfileInfoPageMaster> createState() =>
      _EditProfileInfoPageMasterState();
}

class _EditProfileInfoPageMasterState
    extends State<EditProfileInfoPageMaster> {
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _username1Controller;
  late final TextEditingController _username2Controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Константин');
    _surnameController = TextEditingController(text: 'Константинов');
    _patronymicController = TextEditingController(text: 'Константинович');
    _phoneController = TextEditingController(text: '+7 (777) 777-77-77');
    _username1Controller = TextEditingController(text: '@username');
    _username2Controller = TextEditingController(text: '@username');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _patronymicController.dispose();
    _phoneController.dispose();
    _username1Controller.dispose();
    _username2Controller.dispose();
    super.dispose();
  }

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
          'Редактировать профиль',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Сохранить изменения
              Navigator.pop(context);
            },
            child: const Text(
              'Сохранить',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F7EDE),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF96C5EB),
                        border: Border.all(
                          color: const Color(0xFF0F7EDE),
                          width: 3,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/avatar.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
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
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Два блока под аватаркой
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Блок "Мастер" с синим фоном
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F7EDE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Мастер',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Расстояние между блоками 10 пикселей
                  const SizedBox(width: 10),

                  // Блок "Заказчик" с белым фоном
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Center(
                        child: Text(
                          'Заказчик',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5F6368),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Секция "Основная информация"
              _buildSectionHeader('Основная информация'),
              const SizedBox(height: 16),
              _buildTextFieldWithClear('Имя', _nameController),
              const SizedBox(height: 8),
              _buildTextFieldWithClear('Фамилия', _surnameController),
              const SizedBox(height: 8),
              _buildTextFieldWithClear('Отчество', _patronymicController),
              const SizedBox(height: 32),

              // Секция "Контактная информация"
              _buildSectionHeader('Контактная информация'),
              const SizedBox(height: 16),
              _buildTextFieldWithClear('Телефон', _phoneController),
              const SizedBox(height: 8),
              _buildTextFieldWithClear('Username 1', _username1Controller),
              const SizedBox(height: 8),
              _buildTextFieldWithClear('Username 2', _username2Controller),
              const SizedBox(height: 32),

              // СИНЯЯ КНОПКА "СОХРАНИТЬ" (часть скролла)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Сохранить изменения
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F7EDE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Отступ перед Bottom Navigation Bar
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar (остается фиксированным внизу)
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
                    color: const Color(0xFF5F6368),
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
                    color: const Color(0xFF5F6368),
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
                    color: const Color(0xFF0F7EDE),
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

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF41454A),
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildTextFieldWithClear(
      String hint, TextEditingController controller) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF41454A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9AA0A6),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
            // Кнопка очистки появляется только если есть текст
            if (controller.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => controller.clear(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close,
                        color: Color(0xFF9AA0A6),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return GestureDetector(
      onTap: () {
        // TODO: открыть выбор категории
      },
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
            Image.asset('assets/handyman.png', width: 24, height: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Сантехник',
                style: TextStyle(
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
}