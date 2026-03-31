// lib/screens/help_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _faqItems;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initFaqItems();
    _initAnimation();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _initFaqItems() {
    _faqItems = [
      {
        'questionKey': 'how_to_create_order',
        'answerKey': 'how_to_create_order_answer',
        'expanded': false,
      },
      {
        'questionKey': 'how_to_contact_master',
        'answerKey': 'how_to_contact_master_answer',
        'expanded': false,
      },
      {
        'questionKey': 'how_to_become_master',
        'answerKey': 'how_to_become_master_answer',
        'expanded': false,
      },
      {
        'questionKey': 'subscription_price',
        'answerKey': 'subscription_price_answer',
        'expanded': false,
      },
      {
        'questionKey': 'how_to_pay_subscription',
        'answerKey': 'how_to_pay_subscription_answer',
        'expanded': false,
      },
      {
        'questionKey': 'how_to_edit_profile',
        'answerKey': 'how_to_edit_profile_answer',
        'expanded': false,
      },
      {
        'questionKey': 'code_not_received',
        'answerKey': 'code_not_received_answer',
        'expanded': false,
      },
    ];
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    final appLocalizations = AppLocalizations.of(context);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLocalizations?.translate('failed_to_open_link') ?? 'Не удалось открыть ссылку'}: $url'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: false,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF41454A),
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            appLocalizations?.translate('help') ?? 'Помощь',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            _buildLanguageButton(context, languageProvider, appLocalizations),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(appLocalizations),
                const SizedBox(height: 32),
                _buildFaqSection(appLocalizations),
                const SizedBox(height: 32),
                _buildContactSection(appLocalizations),
                const SizedBox(height: 24),
                _buildSupportHours(appLocalizations),
                const SizedBox(height: 40),
              ],
            ),
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
              accountType: AccountType.client,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, LanguageProvider languageProvider, AppLocalizations? appLocalizations) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('RU', const Locale('ru'), languageProvider.locale.languageCode == 'ru', languageProvider, context),
          _buildLanguageOption('KZ', const Locale('kk'), languageProvider.locale.languageCode == 'kk', languageProvider, context),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, Locale locale, bool isActive, LanguageProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.setLanguage(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.languageCode == 'ru' ? 'Язык изменен на русский' : 'Тіл қазақшаға өзгертілді'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? appLocalizations) {
    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizations?.translate('how_can_we_help') ?? 'Чем мы можем помочь?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizations?.translate('help_subtitle') ?? 'Найдите ответы на частые вопросы\nили свяжитесь с нами',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection(AppLocalizations? appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.question_answer_outlined,
                color: Color(0xFF0F7EDE),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appLocalizations?.translate('frequently_asked_questions') ?? 'Частые вопросы',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2125),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildFaqItem(
            question: appLocalizations?.translate(item['questionKey']) ?? item['questionKey'],
            answer: appLocalizations?.translate(item['answerKey']) ?? item['answerKey'],
            isExpanded: item['expanded'],
            onTap: () => _toggleFaq(index),
          );
        }),
      ],
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isExpanded ? Icons.remove : Icons.add,
                key: ValueKey(isExpanded),
                color: const Color(0xFF0F7EDE),
                size: 20,
              ),
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                height: 1.6,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(AppLocalizations? appLocalizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support_outlined,
                  color: Color(0xFF0F7EDE),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                appLocalizations?.translate('contact_us') ?? 'Свяжитесь с нами',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2125),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.phone_outlined,
            title: appLocalizations?.translate('phone') ?? 'Телефон',
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
            subtitle: appLocalizations?.translate('write_to_support') ?? 'Написать в поддержку',
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0F7EDE), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8D90),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D2125),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF9AA0A6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportHours(AppLocalizations? appLocalizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule, color: Color(0xFF0F7EDE), size: 32),
          const SizedBox(height: 12),
          Text(
            appLocalizations?.translate('support_hours') ?? 'Время работы поддержки',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appLocalizations?.translate('support_hours_schedule') ?? 'Пн-Пт: 09:00 - 20:00\nСб-Вс: 10:00 - 18:00',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5F6368),
              height: 1.5,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.blue.shade200,
          ),
        ],
      ),
    );
  }
}