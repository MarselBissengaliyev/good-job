import 'package:flutter/material.dart';

import 'edit_portfolio_master_page.dart';

class AddOrderClientPage extends StatefulWidget {
  const AddOrderClientPage({super.key});

  @override
  State<AddOrderClientPage> createState() => _AddOrderClientPageState();
}

class _AddOrderClientPageState extends State<AddOrderClientPage> {
  // Контроллеры для полей ввода
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Данные для примеров заказов
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
          'Добавить заказ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Основная карточка с белым фоном
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок "Основная информация"
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Инпут "Что нужно выполнить?"
                      TextField(
                        controller: _taskController,
                        decoration: InputDecoration(
                          hintText: 'Что нужно выполнить?',
                          hintStyle: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFFCBCDCE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F7EDE),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Счетчик символов
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Введите не менее 16 символов',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _taskController,
                            builder: (context, value, child) {
                              return Text(
                                '${value.text.length}/70',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5F6368),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Селект "Категория"
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE8EAED)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Заменяем иконку на изображение
                                  Image.asset(
                                 'assets/handyman.png',
                                    width:
                                        20, // соответствуем размеру предыдущей иконки
                                    height: 20,
                                    color: const Color(
                                      0xFF5F6368,
                                    ), // опционально, если нужно изменить цвет
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Категория',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: const Color(
                                        0xFF41454A,
                                      ).withOpacity(0.6),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF5F6368),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Заголовок "Фото"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Фото',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF41454A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const Text(
                            'Первое фото будет на обложке заказа',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Галерея фотографий
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: 6, // Пример 6 фотографий
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF5F5F5),
                              border: Border.all(
                                color: const Color(0xFFE8EAED),
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/work_sample.png',
                                width: 40,
                                height: 40,
                                color: const Color(0xFFCBCDCE),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Заголовок "Описание"
                      const Text(
                        'Описание',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Textarea для описания
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              'Подумайте, какие подробности вы хотели бы указать в заказе и добавьте их в описание.',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFCBCDCE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F7EDE),
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Счетчик символов для описания
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Введите не менее 40 символов',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F6368),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _descriptionController,
                            builder: (context, value, child) {
                              return Text(
                                '${value.text.length}/9000',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5F6368),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Заголовок "Адрес"
                      const Text(
                        'Адрес',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Поле "Город"
                      TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          hintText: 'Город',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFCBCDCE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F7EDE),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Поле "Район"
                      TextField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          hintText: 'Район',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFCBCDCE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F7EDE),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Поля "Дом" и "Квартира" в ряд
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _houseController,
                              decoration: InputDecoration(
                                hintText: 'Дом',
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFCBCDCE),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8EAED),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8EAED),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F7EDE),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _apartmentController,
                              decoration: InputDecoration(
                                hintText: 'Квартира',
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFCBCDCE),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8EAED),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8EAED),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F7EDE),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF41454A),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Заголовок "Контактная информация"
                      const Text(
                        'Контактная информация',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Поле "Номер телефона"
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Номер телефона',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFCBCDCE),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8EAED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F7EDE),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF41454A),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Кнопка "Добавить заказ"
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Обработка добавления заказа
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F7EDE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Добавить заказ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
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
              // Работа (активная)
              GestureDetector(
                onTap: () {
                  // Уже на этой странице
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/work.png',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF0F7EDE),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Работа',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F7EDE),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              // Прайс
              GestureDetector(
                onTap: () {
                  // Навигация на страницу прайса
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => PricePage()));
                },
                child: Column(
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
              ),
              // Аккаунт
              GestureDetector(
                onTap: () {
                  // Навигация на страницу редактирования портфолио
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPortfolioMasterPage(),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/account.png',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF5F6368),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Аккаунт',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
