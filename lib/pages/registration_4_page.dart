// registration_4_page.dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'registration_5_page.dart';

class Registration4Page extends StatefulWidget {
  const Registration4Page({super.key});

  @override
  State<Registration4Page> createState() => _Registration4PageState();
}

class _Registration4PageState extends State<Registration4Page> {
  final TextEditingController _c0 = TextEditingController();
  final TextEditingController _c1 = TextEditingController();
  final TextEditingController _c2 = TextEditingController();
  final TextEditingController _c3 = TextEditingController();

  final FocusNode _f0 = FocusNode();
  final FocusNode _f1 = FocusNode();
  final FocusNode _f2 = FocusNode();
  final FocusNode _f3 = FocusNode();

  Timer? _timer;
  int _remainingSeconds = 44;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remainingSeconds = 44);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  String _formattedRemaining() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _code => '${_c0.text}${_c1.text}${_c2.text}${_c3.text}';

  void _setSelectionToEnd() {
    _c0.selection = TextSelection.fromPosition(
      TextPosition(offset: _c0.text.length),
    );
    _c1.selection = TextSelection.fromPosition(
      TextPosition(offset: _c1.text.length),
    );
    _c2.selection = TextSelection.fromPosition(
      TextPosition(offset: _c2.text.length),
    );
    _c3.selection = TextSelection.fromPosition(
      TextPosition(offset: _c3.text.length),
    );
  }

  void _onChanged(String value, int index) {
    if (value.isEmpty) return;
    final ch = value.characters.first;

    switch (index) {
      case 0:
        _c0.text = ch;
        _f1.requestFocus();
        break;
      case 1:
        _c1.text = ch;
        _f2.requestFocus();
        break;
      case 2:
        _c2.text = ch;
        _f3.requestFocus();
        break;
      case 3:
        _c3.text = ch;
        _f3.unfocus();
        break;
    }

    _setSelectionToEnd();

    // Если код полностью введён
    if (_code.length == 4 && !_code.contains('')) {
      setState(() {}); // обновляем цвет текста
      // Переход на следующую страницу через небольшую задержку (чтобы цвет обновился)
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Registration5Page()),
        );
      });
    }
  }

  Widget _codeField(
    TextEditingController controller,
    FocusNode node,
    int index,
  ) {
    final isFullCode = _code.length == 4 && !_code.contains('');
    return SizedBox(
      width: 64,
      height: 88,
      child: TextField(
        controller: controller,
        focusNode: node,
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          letterSpacing: 2,
          color: isFullCode ? const Color(0xFF0F7EDE) : Colors.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (v) => _onChanged(v, index),
        onSubmitted: (_) {
          if (index < 3) {
            switch (index) {
              case 0:
                _f1.requestFocus();
                break;
              case 1:
                _f2.requestFocus();
                break;
              case 2:
                _f3.requestFocus();
                break;
            }
          } else {
            node.unfocus();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c0.dispose();
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    _f0.dispose();
    _f1.dispose();
    _f2.dispose();
    _f3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isCodeFull =
        _c0.text.isNotEmpty &&
        _c1.text.isNotEmpty &&
        _c2.text.isNotEmpty &&
        _c3.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Верхняя панель
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Image.asset('assets/logo.png', height: 28),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: mq.size.width * 0.9,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Введите код из смс',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Код отправлен на номер +7 777 777-77-77',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _codeField(_c0, _f0, 0),
                              const SizedBox(width: 12),
                              _codeField(_c1, _f1, 1),
                              const SizedBox(width: 12),
                              _codeField(_c2, _f2, 2),
                              const SizedBox(width: 12),
                              _codeField(_c3, _f3, 3),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _remainingSeconds == 0
                                ? () {
                                    _startTimer();
                                  }
                                : null,
                            child: Text(
                              _remainingSeconds == 0
                                  ? 'Запросить новый код'
                                  : 'Запросить новый код через ${_formattedRemaining()}',
                              style: TextStyle(
                                fontSize: 15,
                                color: _remainingSeconds == 0
                                    ? Theme.of(context).primaryColor
                                    : const Color(0xFF5F6368),
                                decoration: _remainingSeconds == 0
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
            // Кнопки внизу
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFAFAFA),
                            side: const BorderSide(
                              color: Color(0xFF5F6368),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(
                              'Войти',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5F6368),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isCodeFull
                                ? const Color(0xFF0F7EDE)
                                : const Color(0xFFBABABA),
                            side: BorderSide(
                              color: isCodeFull
                                  ? const Color(0xFF0F7EDE)
                                  : const Color(0xFFBABABA),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isCodeFull
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const Registration5Page(),
                                    ),
                                  );
                                }
                              : null,

                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(
                              'Подтвердить',
                              style: TextStyle(
                                fontSize: 16,
                                color: isCodeFull
                                    ? Colors.white
                                    : const Color(0xFF5F6368),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
