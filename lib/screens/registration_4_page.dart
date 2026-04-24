import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/auth/auth_service.dart';

class Registration4Page extends StatefulWidget {
  final String phoneNumber;
  final int codeTtl;
  final bool isRegistering;
  final Map<String, dynamic>? registeringData;

  const Registration4Page({
    super.key,
    required this.phoneNumber,
    this.codeTtl = 60,
    this.isRegistering = false,
    this.registeringData,
  });

  @override
  State<Registration4Page> createState() => _Registration4PageState();
}

class _Registration4PageState extends State<Registration4Page>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  late int _remainingSeconds;
  bool _isLoading = false;
  Map<String, dynamic>? _serverPayload;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.codeTtl;
    _startTimer();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _currentInputCode => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Автоматическая отправка при полном вводе кода
    if (_currentInputCode.length == 4 && !_isLoading) {
      _confirmCode();
    }

    setState(() {});
  }

  Future<void> _confirmCode() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final code = _currentInputCode;

    if (code.length != 4 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.confirmPhone(
        telephone: widget.phoneNumber,
        code: code,
      );

      // Сохраняем пару токенов
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];
      final ttl = response['ttl'] ?? 3600; // обычно 1 час
      final refreshTtl = response['refreshTtl'] ?? 86400; // обычно 24 часа

      if (accessToken != null && refreshToken != null) {
        // Сохраняем токены с их временем жизни
        await AuthService.saveTokenPair(
          accessToken: accessToken,
          refreshToken: refreshToken,
          ttl: ttl,
          refreshTtl: refreshTtl,
        );
      } else {
        throw Exception('Токены не получены');
      }

      final profile = await ApiService.getProfile();
      final userId = profile['data']['id']?.toString();
      final userRole = profile['data']['activeMode']?.toString();

      if (userId != null) {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: 'user_id', value: userId);
      }

      if (userRole != null) {
        await AuthService.saveUserRole(userRole);
      }

      await AuthService.debugPrintStoredData();

      if (!mounted) return;

      // Показываем успешное уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalizations.translate('code_confirmed_success')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Редирект
      if (userRole == 'master') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/account-master',
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/account-client',
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${appLocalizations.translate('error')}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Очищаем поля при ошибке
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    final appLocalizations = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      if (widget.isRegistering) {
        await ApiService.registerUser(
          firstname: widget.registeringData?['firstname'] ?? 'temp',
          lastname: widget.registeringData?['lastname'] ?? 'temp',
          telephone: widget.phoneNumber,
          cityId: widget.registeringData?['city_id'] ?? 0,
          activeMode: widget.registeringData?['active_mode'] ?? 'client',
        );
      } else {
        await ApiService.login(telephone: widget.phoneNumber);
      }
      setState(() {
        _remainingSeconds = widget.codeTtl;
      });
      _startTimer();

      // Очищаем поля при повторной отправке
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalizations.translate('code_resent')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${appLocalizations.translate('error')}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isCodeFull = _currentInputCode.length == 4;
    final progress = _currentInputCode.length / 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Image.asset('assets/logo.png', height: 28),
        centerTitle: true,
        actions: [
          _buildLanguageButton(context, languageProvider, appLocalizations),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Анимированная иконка
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade700,
                                ],
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
                              Icons.sms,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            appLocalizations.translate('enter_sms_code'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            appLocalizations.translate('code_sent_to'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.phoneNumber,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Поля ввода кода
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              4,
                              (index) => _buildOtpField(index),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Прогресс бар
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildTimerOrResend(appLocalizations),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomButtons(isCodeFull, appLocalizations),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    LanguageProvider languageProvider,
    AppLocalizations appLocalizations,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
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

  Widget _buildOtpField(int index) {
    return Container(
      width: 65,
      height: 75,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
        maxLength: 1,
        enabled: !_isLoading,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Plus Jakarta Sans',
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2.5),
          ),
        ),
        onChanged: (v) => _onChanged(v, index),
      ),
    );
  }

  Widget _buildTimerOrResend(AppLocalizations appLocalizations) {
    if (_remainingSeconds > 0) {
      final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
      final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
      return Column(
        children: [
          Text(
            appLocalizations.translate('resend_code_in'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$mins:$secs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      );
    }

    return TextButton(
      onPressed: _isLoading ? null : _resendCode,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        appLocalizations.translate('resend_code'),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildBottomButtons(
    bool isCodeFull,
    AppLocalizations appLocalizations,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isCodeFull && !_isLoading ? _confirmCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCodeFull
                    ? Colors.blue.shade700
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isCodeFull ? 2 : 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      appLocalizations.translate('confirm'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
