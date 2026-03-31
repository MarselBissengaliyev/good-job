// lib/screens/subscription_success_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class SubscriptionSuccessPage extends StatefulWidget {
  const SubscriptionSuccessPage({super.key});

  @override
  State<SubscriptionSuccessPage> createState() =>
      _SubscriptionSuccessPageState();
}

class _SubscriptionSuccessPageState extends State<SubscriptionSuccessPage> {
  int _secondsRemaining = 5;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 1) {
        timer.cancel();
        _navigateToKaspi();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final appLocalizations = AppLocalizations.of(context);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations?.translate('failed_to_open_link') ?? 'Не удалось открыть ссылку'}: $url',
            ),
          ),
        );
      }
    }
  }

  Future<void> _navigateToKaspi() async {
    const url = 'https://qr.kaspi.kz/19134627698424934147714893150004931409130';

    await _launchUrl(url);

       if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
          appLocalizations?.translate('subscription_payment') ??
              'Оплата подписки',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2125),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          _buildLanguageButton(context, languageProvider, appLocalizations),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSuccessAnimation(),
                const SizedBox(height: 32),
                _buildPaymentMessage(appLocalizations),
                const SizedBox(height: 48),
                _buildTimerSection(appLocalizations),
                const SizedBox(height: 24),
                _buildManualButton(appLocalizations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    LanguageProvider languageProvider,
    AppLocalizations? appLocalizations,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            'RU',
            const Locale('ru'),
            languageProvider.locale.languageCode == 'ru',
            languageProvider,
            context,
          ),
          _buildLanguageOption(
            'KZ',
            const Locale('kk'),
            languageProvider.locale.languageCode == 'kk',
            languageProvider,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String code,
    Locale locale,
    bool isActive,
    LanguageProvider provider,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        provider.setLanguage(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.languageCode == 'ru'
                  ? 'Язык изменен на русский'
                  : 'Тіл қазақшаға өзгертілді',
            ),
            backgroundColor: const Color(0xFF0F7EDE),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isActive ? const Color(0xFF0F7EDE) : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F7EDE), Color(0xFF0056B3)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F7EDE).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMessage(AppLocalizations? appLocalizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            appLocalizations?.translate('payment_success_title') ??
                '✅ Покупка подписки через Kaspi',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2125),
              fontFamily: 'Plus Jakarta Sans',
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(height: 2, width: 50, color: const Color(0xFF0F7EDE)),
          const SizedBox(height: 16),
          Text(
            appLocalizations?.translate('payment_verification_message') ??
                'В течение часа мы подтвердим вашу покупку\nи активируем подписку',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF0F7EDE),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  appLocalizations?.translate('verification_time') ??
                      '⏱️ Обычно занимает 5-10 минут',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F7EDE),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(AppLocalizations? appLocalizations) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: _secondsRemaining / 5,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0F7EDE),
                  ),
                ),
              ),
              Text(
                '$_secondsRemaining',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2125),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          appLocalizations?.translate('redirect_message') ??
              'Переход на страницу оплаты Kaspi',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF5F6368),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appLocalizations?.translate('redirect_countdown') ??
              'Автоматический переход через',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8A8D90),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildManualButton(AppLocalizations? appLocalizations) {
    return OutlinedButton(
      onPressed: _navigateToKaspi,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F7EDE),
        side: const BorderSide(color: Color(0xFF0F7EDE), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 20),
          const SizedBox(width: 12),
          Text(
            appLocalizations?.translate('pay_now_button') ??
                '💳 Перейти к оплате сейчас',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}
