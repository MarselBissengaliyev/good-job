import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка проверки
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: Color(0xFF0F7EDE),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            
            // Заголовок
            const Text(
              'Подтверждение номера',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2125),
              ),
            ),
            const SizedBox(height: 12),
            
            // Описание
            Text.rich(
              TextSpan(
                text: 'Код отправлен на номер\n',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5F6368),
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D2125),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Поля для кода
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.codeControllers[index].text.isNotEmpty
                          ? const Color(0xFF0F7EDE)
                          : const Color(0xFFE0E0E0),
                      width: 2,
                    ),
                    color: Colors.white,
                    boxShadow: widget.codeControllers[index].text.isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F7EDE).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: TextField(
                    controller: widget.codeControllers[index],
                    focusNode: widget.codeFocusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D2125),
                    ),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        widget.codeFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        widget.codeFocusNodes[index - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Таймер/повторная отправка
            GestureDetector(
              onTap: widget.canResendCode ? widget.onResendCode : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: widget.canResendCode
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF0F7EDE),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Отправить код повторно',
                            style: TextStyle(
                              color: Color(0xFF0F7EDE),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : RichText(
                        text: TextSpan(
                          text: 'Повторная отправка через ',
                          style: const TextStyle(
                            color: Color(0xFF8A8D90),
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: '${widget.resendTimer}с',
                              style: const TextStyle(
                                color: Color(0xFF0F7EDE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        color: Color(0xFF5F6368),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isCodeComplete ? widget.onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF0F7EDE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Подтвердить',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileClientPage extends StatefulWidget {
  const EditProfileClientPage({super.key});

  @override
  State<EditProfileClientPage> createState() => _EditProfileClientPageState();
}

class _EditProfileClientPageState extends State<EditProfileClientPage> {
  // Контроллеры полей
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _phoneController;

  // Состояние данных
  bool _isLoading = true;
  String _activeMode = 'client';
  int? _selectedCityId;
  List<dynamic> _cities = [];

  // Управление модалкой
  final List<TextEditingController> _codeControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(4, (index) => FocusNode());
  bool _canResendCode = false;
  int _resendTimer = 44;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _patronymicController = TextEditingController();
    _phoneController = TextEditingController();
    _loadInitialData();
  }

  // Загрузка городов и данных профиля
  Future<void> _loadInitialData() async {
    try {
      final citiesData = await ApiService.getCities();
      final profileData = await ApiService.getProfile();
      final user = profileData['data'];

      setState(() {
        _cities = citiesData;
        _nameController.text = user['firstname'] ?? '';
        _surnameController.text = user['lastname'] ?? '';
        _patronymicController.text = user['patronymic'] ?? '';
        _phoneController.text = user['telephone'] ?? '';
        _activeMode = user['active_mode'] ?? 'client';
        _selectedCityId = user['city']['id'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _patronymicController.dispose();
    _phoneController.dispose();
    for (var c in _codeControllers) c.dispose();
    for (var f in _codeFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool get _isCodeComplete =>
      _codeControllers.every((c) => c.text.isNotEmpty);

  // Сохранение профиля через API
  Future<void> _updateProfile() async {
    try {
      await ApiService.updateProfile(
        firstname: _nameController.text,
        lastname: _surnameController.text,
        patronymic: _patronymicController.text,
        cityId: _selectedCityId ?? 0,
        activeMode: _activeMode,
      );
      if (!mounted) return;
      
      // Показать красивый SnackBar при успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Профиль успешно обновлен',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      // Закрыть страницу после успешного обновления
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text('Ошибка обновления: $e')),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _openVerificationModal() {
    for (var c in _codeControllers) c.clear();
    _resetTimer();

    showDialog(
      context: context,
      builder: (context) => VerificationModal(
        phoneNumber: _phoneController.text,
        codeControllers: _codeControllers,
        codeFocusNodes: _codeFocusNodes,
        isCodeComplete: _isCodeComplete,
        resendTimer: _resendTimer,
        canResendCode: _canResendCode,
        onResendCode: _requestNewCode,
        onConfirm: () async {
          Navigator.pop(context); // Закрываем модалку
          await _updateProfile(); // Вызываем PUT запрос
        },
      ),
    );
  }

  void _resetTimer() {
    _timer?.cancel();
    _canResendCode = false;
    _resendTimer = 44;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        if (mounted) setState(() => _canResendCode = true);
        timer.cancel();
      }
    });
  }

  void _requestNewCode() {
    if (_canResendCode) {
      _resetTimer();
      
      // Показать уведомление об отправке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Новый код отправлен'),
          backgroundColor: const Color(0xFF0F7EDE),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0F7EDE)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Загрузка профиля...',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF5F6368),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
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
        centerTitle: true,
        title: const Text(
          'Редактировать профиль',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF1D2125),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Аватар
            _buildAvatarSection(),
            const SizedBox(height: 32),
            
            // Переключатель режима
            _buildModeSwitcher(),
            const SizedBox(height: 32),
            
            // Основная информация
            _buildSectionHeader('Основная информация'),
            const SizedBox(height: 16),
            
            // Поля ввода
            _buildInputField('Имя', _nameController, Icons.person_outline),
            const SizedBox(height: 12),
            _buildInputField('Фамилия', _surnameController, Icons.person_outline),
            const SizedBox(height: 12),
            _buildInputField('Отчество', _patronymicController, Icons.person_outline),
            const SizedBox(height: 16),
            
            // Выбор города
            _buildCityDropdown(),
            const SizedBox(height: 32),
            
            // Контактная информация
            _buildSectionHeader('Контактная информация'),
            const SizedBox(height: 16),
            
            _buildPhoneField(),
            const SizedBox(height: 40),
            
            // Кнопка сохранения
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF96C5EB), Color(0xFF0F7EDE)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F7EDE).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // TODO: Реализовать изменение аватара
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF0F7EDE),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton('Заказчик', 'client'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton('Мастер', 'master'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    bool isActive = _activeMode == mode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _activeMode = mode),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF0F7EDE) : const Color(0xFF8A8D90),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1D2125),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1D2125),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
          prefixIcon: Icon(icon, color: const Color(0xFF8A8D90), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: Color(0xFF8A8D90)),
                  onPressed: () => setState(() => controller.clear()),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF8A8D90), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCityId,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF8A8D90)),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1D2125),
                  fontWeight: FontWeight.w500,
                ),
                hint: const Text(
                  "Выберите город",
                  style: TextStyle(color: Color(0xFF8A8D90)),
                ),
                items: _cities.map((city) {
                  return DropdownMenuItem<int>(
                    value: city['id'],
                    child: Text(city['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCityId = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1D2125),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Телефон',
          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
          prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF8A8D90), size: 20),
          suffixIcon: _phoneController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: Color(0xFF8A8D90)),
                  onPressed: () => setState(() => _phoneController.clear()),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF0F7EDE),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openVerificationModal,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F7EDE), Color(0xFF4A9CE4)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7EDE).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Сохранить изменения',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}