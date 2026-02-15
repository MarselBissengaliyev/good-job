import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/auth/auth_service.dart';

// Добавьте этот импорт для навигации
import 'edit_portfolio_master_page.dart'; // Раскомментируйте и укажите правильный путь

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

  // Для управления модалкой
  final List<TextEditingController> _codeControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(4, (index) => FocusNode());
  bool _canResendCode = false;
  int _resendTimer = 44;
  Timer? _timer; // Убрал late, просто nullable

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
    
    // Очистка контроллеров и фокусов кода
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    
    _timer?.cancel();
    super.dispose();
  }

  // Проверка, все ли поля кода заполнены
  bool get _isCodeComplete {
    return _codeControllers.every((controller) => controller.text.isNotEmpty);
  }

  // Функция для открытия модалки
  void _openVerificationModal() {
    // Очищаем предыдущие значения кода
    for (var controller in _codeControllers) {
      controller.clear();
    }
    
    // Сбрасываем таймер
    _resetTimer();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return VerificationModal(
          phoneNumber: _phoneController.text,
          codeControllers: _codeControllers,
          codeFocusNodes: _codeFocusNodes,
          isCodeComplete: _isCodeComplete,
          resendTimer: _resendTimer,
          canResendCode: _canResendCode,
          onResendCode: _requestNewCode,
          onConfirm: () {
            // Закрыть модалку
            Navigator.pop(context);
            // TODO: Добавить логику сохранения данных
            print('Код подтвержден, сохраняем изменения...');
          },
        );
      },
    );
  }

  // Сброс таймера
  void _resetTimer() {
    _timer?.cancel();
    _canResendCode = false;
    _resendTimer = 44;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResendCode = true;
        });
        timer.cancel();
      }
    });
  }

  // Функция для запроса нового кода
  void _requestNewCode() {
    if (_canResendCode) {
      _resetTimer();
      // TODO: Отправить запрос на новый код
      print('Запрос нового кода...');
    }
  }

  // Функция для перехода на страницу портфолио
  void _navigateToPortfolioPage() {
    // Раскомментируйте и настройте правильную навигацию
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPortfolioMasterPage(),
      ),
    );
    
  
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
          IconButton(
            onPressed: () async {
              await AuthService.clearAuthData();
              if (mounted)
                Navigator.pushReplacementNamed(context, '/registration');
            },
            icon: Image.asset('assets/logout.png', width: 22, height: 22),
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

              // КНОПКА "СОХРАНИТЬ"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _openVerificationModal,
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
              
              // КНОПКА "МОИ РАБОТЫ" - добавлена
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _navigateToPortfolioPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF0F7EDE),
                        width: 2,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Мои работы',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F7EDE),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.account, // Указываем активную вкладку
        accountType: AccountType.master,
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
}

// Упрощенный виджет модального окна
class VerificationModal extends StatefulWidget {
  final String phoneNumber;
  final List<TextEditingController> codeControllers;
  final List<FocusNode> codeFocusNodes;
  final bool isCodeComplete;
  final int resendTimer;
  final bool canResendCode;
  final VoidCallback onResendCode;
  final VoidCallback onConfirm;

  const VerificationModal({
    super.key,
    required this.phoneNumber,
    required this.codeControllers,
    required this.codeFocusNodes,
    required this.isCodeComplete,
    required this.resendTimer,
    required this.canResendCode,
    required this.onResendCode,
    required this.onConfirm,
  });

  @override
  State<VerificationModal> createState() => _VerificationModalState();
}

class _VerificationModalState extends State<VerificationModal> {
  late int _modalResendTimer;
  late bool _modalCanResendCode;
  Timer? _modalTimer;

  @override
  void initState() {
    super.initState();
    _modalResendTimer = widget.resendTimer;
    _modalCanResendCode = widget.canResendCode;
    
    // Запускаем таймер, если еще не истек
    if (_modalResendTimer > 0 && !_modalCanResendCode) {
      _startModalTimer();
    }
  }

  void _startModalTimer() {
    _modalTimer?.cancel();
    _modalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_modalResendTimer > 0) {
        setState(() {
          _modalResendTimer--;
        });
      } else {
        setState(() {
          _modalCanResendCode = true;
        });
        timer.cancel();
      }
    });
  }

  void _handleResendCode() {
    if (_modalCanResendCode) {
      setState(() {
        _modalResendTimer = 44;
        _modalCanResendCode = false;
      });
      
      // Запускаем таймер заново
      _startModalTimer();
      
      // Вызываем callback из основного виджета
      widget.onResendCode();
    }
  }

  @override
  void dispose() {
    _modalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Для подтверждения смены номера',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Код отправлен на номер ${widget.phoneNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5F6368),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 24),
            
            // Поля ввода кода
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: TextField(
                    controller: widget.codeControllers[index],
                    focusNode: widget.codeFocusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF41454A),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.codeFocusNodes[index].hasFocus
                              ? const Color(0xFF0F7EDE)
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F7EDE),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        FocusScope.of(context).requestFocus(widget.codeFocusNodes[index + 1]);
                      }
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(widget.codeFocusNodes[index - 1]);
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Таймер / Повторная отправка
            Center(
              child: GestureDetector(
                onTap: _modalCanResendCode ? _handleResendCode : null,
                child: Text(
                  _modalCanResendCode
                      ? 'Запросить новый код'
                      : 'Запросить новый код через 00:${_modalResendTimer.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _modalCanResendCode
                        ? const Color(0xFF0F7EDE)
                        : const Color(0xFF9AA0A6),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Кнопка подтверждения
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.isCodeComplete ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isCodeComplete
                      ? const Color(0xFF0F7EDE)
                      : const Color(0xFFE0E0E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Подтвердить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isCodeComplete
                        ? Colors.white
                        : const Color(0xFF9AA0A6),
                    fontFamily: 'Plus Jakarta Sans',
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