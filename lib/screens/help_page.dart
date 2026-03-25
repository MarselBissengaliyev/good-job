// lib/screens/help_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'Как создать заказ?',
      'answer':
          'Чтобы создать заказ, перейдите в раздел "Главная" и нажмите на кнопку "Создать заказ". Заполните все необходимые поля: категорию услуги, описание, адрес и контактные данные.',
      'expanded': false,
    },
    {
      'question': 'Как связаться с мастером?',
      'answer':
          'После создания заказа мастера смогут откликнуться на него. Вы увидите список откликнувшихся мастеров и сможете выбрать подходящего, просмотрев их портфолио и рейтинг.',
      'expanded': false,
    },
    {
      'question': 'Как стать мастером?',
      'answer':
          'В профиле вы можете переключить режим на "Мастер". После этого вам станут доступны дополнительные функции: добавление портфолио, выбор категории услуг и оформление подписки для получения заказов.',
      'expanded': false,
    },
    {
      'question': 'Сколько стоит подписка для мастера?',
      'answer':
          'Подписка для мастеров стоит 4 999 тг в месяц. Она включает публикацию услуг и отображение номера заказчика для связи.',
      'expanded': false,
    },
    {
      'question': 'Как оплатить подписку?',
      'answer':
          'В разделе профиля мастера нажмите на блок "Купить подписку". В открывшемся окне укажите вашу почту и номер телефона, после чего наш менеджер свяжется с вами для подтверждения оплаты.',
      'expanded': false,
    },
    {
      'question': 'Как изменить данные профиля?',
      'answer':
          'Нажмите на иконку редактирования рядом с вашим аватаром в профиле. Вы сможете изменить имя, фамилию, контактные данные и другую информацию.',
      'expanded': false,
    },
    {
      'question': 'Что делать, если не приходит код подтверждения?',
      'answer':
          'Проверьте правильность введенного номера телефона. Убедитесь, что у вас есть стабильное интернет-соединение. Если код так и не приходит, попробуйте запросить его повторно через 60 секунд.',
      'expanded': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Устанавливаем цвет системной навигации
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    // Возвращаем стандартные настройки при выходе
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  void _toggleFaq(int index) {
    setState(() {
      _faqItems[index]['expanded'] = !_faqItems[index]['expanded'];
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть ссылку: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: false, // Предотвращает сжатие при открытии клавиатуры
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF41454A),
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Помощь',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(  
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF0F7EDE),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Чем мы можем помочь?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D2125),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Найдите ответы на частые вопросы\nили свяжитесь с нами',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Раздел "Частые вопросы"
              const Text(
                'Частые вопросы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2125),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 16),

              // Список FAQ
              ..._faqItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildFaqItem(
                  question: item['question'],
                  answer: item['answer'],
                  isExpanded: item['expanded'],
                  onTap: () => _toggleFaq(index),
                );
              }),

              const SizedBox(height: 32),

              // Раздел "Свяжитесь с нами"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Свяжитесь с нами',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D2125),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      icon: Icons.phone_outlined,
                      title: 'Телефон',
                      subtitle: '+7 (700) 123-45-67',
                      onTap: () => _launchUrl('tel:+77001234567'),
                    ),
                    const Divider(height: 24),
                    _buildContactItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'support@gj.kz',
                      onTap: () => _launchUrl('mailto:support@gj.kz'),
                    ),
                    const Divider(height: 24),
                    _buildContactItem(
                      icon: Icons.chat_outlined,
                      title: 'WhatsApp',
                      subtitle: 'Написать в поддержку',
                      onTap: () => _launchUrl('https://wa.me/77001234567'),
                    ),
                    const Divider(height: 24),
                    _buildContactItem(
                      icon: Icons.telegram,
                      title: 'Telegram',
                      subtitle: '@gj_support',
                      onTap: () => _launchUrl('https://t.me/gj_support'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Дополнительная информация
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Время работы поддержки',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D2125),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Пн-Пт: 09:00 - 20:00\nСб-Вс: 10:00 - 18:00',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                        height: 1.5,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Среднее время ответа: до 2 часов',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F7EDE),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: CustomBottomNavBar(
              activeItem: NavItem.account,
              accountType: AccountType.client, // По умолчанию клиент
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          onExpansionChanged: (_) => onTap(),
          initiallyExpanded: isExpanded,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpanded ? Icons.remove : Icons.add,
              color: const Color(0xFF0F7EDE),
              size: 20,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                height: 1.5,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF0F7EDE), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A8D90),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D2125),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF9AA0A6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}