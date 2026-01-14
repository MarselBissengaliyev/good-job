import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class Registration4Page extends StatefulWidget {
  final String phoneNumber;
  final int codeTtl;

  const Registration4Page({
    super.key,
    required this.phoneNumber,
    this.codeTtl = 60,
  });

  @override
  State<Registration4Page> createState() => _Registration4PageState();
}

class _Registration4PageState extends State<Registration4Page> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  late int _remainingSeconds;
  bool _isLoading = false;

  // Данные из API для проверки
  String? _expectedCode;
  Map<String, dynamic>? _serverPayload;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.codeTtl;
    _startTimer();
    _fetchDebugInfo(); // Просто загружаем данные в память, не заполняя поля автоматически
  }

  Future<void> _fetchDebugInfo() async {
    final data = await ApiService.getDebugSmsData(widget.phoneNumber);
    if (data != null && mounted) {
      setState(() {
        _expectedCode = data['code'].toString();
        _serverPayload = data['payload'];
      });
      print('[DEBUG] Получен код для проверки: $_expectedCode');
      print('[DEBUG] Payload: $_serverPayload');
    }
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
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // Обновляем состояние кнопки "Подтвердить"
  }

  Future<void> _confirmCode() async {
    final code = _currentInputCode;
    if (code.length != 4 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.confirmPhone(
        telephone: widget.phoneNumber,
        code: code,
      );

      // ВАЖНО: Ключ в вашем логе "accessToken", а не "access_token"
      final token = response['accessToken'];
      if (token != null) {
        await AuthService.saveToken(token);
      }

      // Определяем роль
      String? roleToSave;
      if (_serverPayload != null && _serverPayload!['activeMode'] != null) {
        roleToSave = _serverPayload!['activeMode'];
      } else {
        // Если payload нет, запрашиваем профиль (токен уже сохранен выше)
        final profile = await ApiService.getProfile();
        roleToSave = profile['data']['active_mode'];
      }

      if (roleToSave != null) {
        await AuthService.saveUserRole(roleToSave);
      }

      if (!mounted) return;

      // РЕДИРЕКТ в зависимости от роли
      if (roleToSave == 'master') {
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
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCodeFull = _currentInputCode.length == 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/logo.png', height: 28),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Введите код из смс',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Код отправлен на номер ${widget.phoneNumber}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (index) => _buildOtpField(index),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTimerOrResend(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(isCodeFull),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 60,
      height: 70,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (v) => _onChanged(v, index),
      ),
    );
  }

  Widget _buildTimerOrResend() {
    if (_remainingSeconds > 0) {
      final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
      final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
      return Text(
        'Запросить новый код через $mins:$secs',
        style: const TextStyle(color: Colors.grey),
      );
    }
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              /* Логика переотправки */
            },
      child: const Text(
        'Запросить новый код',
        style: TextStyle(decoration: TextDecoration.underline),
      ),
    );
  }

  Widget _buildBottomButtons(bool isCodeFull) {
    return Padding(
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
                    ? const Color(0xFF0F7EDE)
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Подтвердить',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
