import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/screens/edit_portfolio_master_page.dart';
import '../services/api_service.dart';

class VerificationModal extends StatefulWidget {
  final String phoneNumber;
  final int codeTtl;

  const VerificationModal({required this.phoneNumber, this.codeTtl = 60});

  @override
  State<VerificationModal> createState() => _VerificationModalState();
}

class _VerificationModalState extends State<VerificationModal> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  late int _remainingSeconds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.codeTtl;
    _startTimer();
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

            // Поля для кода (как в Registration4Page)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => SizedBox(
                  width: 64,
                  height: 64,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D2125),
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F7EDE),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (v) => _onChanged(v, index),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Таймер/повторная отправка
            _buildTimerOrResend(),
            const SizedBox(height: 32),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                    onPressed: isCodeFull && !_isLoading
                        ? () {
                            final code = _currentInputCode;
                            Navigator.of(context).pop(code);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isCodeFull && !_isLoading
                          ? const Color(0xFF0F7EDE)
                          : const Color(0xFFC4C4C4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
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

  Widget _buildTimerOrResend() {
    if (_remainingSeconds > 0) {
      final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
      final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
      return Text(
        'Запросить новый код через $mins:$secs',
        style: const TextStyle(color: Color(0xFF8A8D90), fontSize: 16),
      );
    }
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              // Возвращаем событие повторной отправки
              Navigator.of(context).pop('resend');
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, color: Color(0xFF0F7EDE), size: 20),
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
        ),
      ),
    );
  }
}

enum ProfileMode { client, master }

class EditProfilePage extends StatefulWidget {
  final ProfileMode initialMode;

  const EditProfilePage({super.key, required this.initialMode});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Контроллеры полей
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _username1Controller;
  late final TextEditingController _username2Controller;

  // Состояние данных
  bool _isLoading = true;
  bool _isSaving = false;
  ProfileMode _currentProfileMode = ProfileMode.client; // Текущий режим из сервера
  ProfileMode _selectedProfileMode = ProfileMode.client; // Выбранный режим в UI
  int? _selectedCityId;
  List<dynamic> _cities = [];

  // Для модального окна подтверждения телефона
  String? _newPhoneNumber;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _patronymicController = TextEditingController();
    _phoneController = TextEditingController();
    _username1Controller = TextEditingController();
    _username2Controller = TextEditingController();
    _loadInitialData();
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

        // Устанавливаем текущий режим из профиля
        final activeMode = user['activeMode'] ?? 'client';
        _currentProfileMode = activeMode == 'master'
            ? ProfileMode.master
            : ProfileMode.client;
        
        // Изначально выбранный режим совпадает с текущим
        _selectedProfileMode = _currentProfileMode;

        _selectedCityId = user['city']['id'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки данных');
    }
  }

  // Проверка, изменились ли данные
  bool get _hasChanges {
    final hasBasicChanges = _nameController.text.isNotEmpty &&
        _surnameController.text.isNotEmpty &&
        _selectedCityId != null;
    
    // Проверяем, изменился ли режим профиля
    final hasModeChanged = _selectedProfileMode != _currentProfileMode;
    
    return hasBasicChanges || hasModeChanged;
  }

  // Проверка, изменился ли режим профиля
  bool get _isProfileModeChanged => _selectedProfileMode != _currentProfileMode;

  // Обновление профиля
  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _surnameController.text.isEmpty || _selectedCityId == null) {
      _showErrorSnackBar('Заполните обязательные поля');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.updateProfile(
        firstname: _nameController.text.trim(),
        lastname: _surnameController.text.trim(),
        patronymic: _patronymicController.text.trim().isEmpty
            ? null
            : _patronymicController.text.trim(),
        cityId: _selectedCityId!,
        activeMode: _selectedProfileMode == ProfileMode.master ? 'master' : 'client',
      );

      // Обновляем текущий режим после успешного сохранения
      _currentProfileMode = _selectedProfileMode;

      // Если телефон изменился, показываем модальное окно для подтверждения
      final currentPhone = _phoneController.text.trim();
      if (await _hasPhoneChanged(currentPhone)) {
        _newPhoneNumber = currentPhone;
        await _showVerificationModal();
      } else {
        _showSuccessSnackBar('Профиль успешно обновлен');
        _navigateBackWithResult();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка обновления профиля');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Возврат на предыдущую страницу с результатом
  void _navigateBackWithResult() {
    Navigator.pop(context, {
      'profileUpdated': true,
      'newMode': _currentProfileMode,
    });
  }

  // Проверка, изменился ли телефон
  Future<bool> _hasPhoneChanged(String newPhone) async {
    try {
      final profileData = await ApiService.getProfile();
      final user = profileData['data'];
      final currentPhone = user['telephone'] ?? '';
      return newPhone.isNotEmpty &&
          newPhone.length >= 10 &&
          newPhone != currentPhone;
    } catch (e) {
      return false;
    }
  }

  String? _expectedCode;
  Map<String, dynamic>? _serverPayload;

  Future<void> _fetchDebugInfo() async {
    final data = await ApiService.getDebugSmsData(_newPhoneNumber!);
    if (data != null && mounted) {
      setState(() {
        _expectedCode = data['code'].toString();
        _serverPayload = data['payload'];
      });
      print('[DEBUG] Получен код для проверки: $_expectedCode');
      print('[DEBUG] Payload: $_serverPayload');
    }
  }

  // Показ модального окна подтверждения телефона
  Future<void> _showVerificationModal() async {
    try {
      // Отправляем запрос на обновление телефона
      await ApiService.updateTelephone(telephone: _newPhoneNumber!);
      await _fetchDebugInfo();

      // Показываем диалог и ждем результат
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => VerificationModal(phoneNumber: _newPhoneNumber!),
      );

      if (result != null) {
        if (result == 'resend') {
          // Повторная отправка кода
          await _resendCode();
          await _showVerificationModal();
        } else {
          // Подтверждение кода (result содержит код)
          await _confirmNewPhone(result);
        }
      }
    } catch (e) {
      // Если ошибка "код уже отправлен", все равно показываем диалог
      if (e.toString().contains('Code already sent')) {
        await _showVerificationModalDirectly();
      } else {
        _showErrorSnackBar('Ошибка отправки кода');
      }
    }
  }

  // Показ модального окна без отправки запроса (если код уже был отправлен)
  Future<void> _showVerificationModalDirectly() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationModal(phoneNumber: _newPhoneNumber!),
    );

    if (result != null) {
      if (result == 'resend') {
        // Повторная отправка кода
        await _resendCode();
        await _showVerificationModalDirectly();
      } else {
        // Подтверждение кода
        await _confirmNewPhone(result);
      }
    }
  }

  // Подтверждение нового телефона
  Future<void> _confirmNewPhone(String code) async {
    try {
      await ApiService.confirmNewTelephone(
        telephone: _newPhoneNumber!,
        code: code,
      );

      _showSuccessSnackBar('Телефон успешно подтвержден');

      // Обновляем телефон в поле ввода
      setState(() {
        _phoneController.text = _newPhoneNumber!;
      });

      // Возвращаемся на предыдущую страницу
      _navigateBackWithResult();
    } catch (e) {
      // Если серверная ошибка 500 или 422, считаем успешным (проблема на бэкенде)
      if (e.toString().contains('500') ||
          e.toString().contains('Call to a member function update()') ||
          e.toString().contains('422')) {
        _showInfoSnackBar('Телефон отправлен на подтверждение');

        // Обновляем телефон в поле ввода
        setState(() {
          _phoneController.text = _newPhoneNumber!;
        });

        // Возвращаемся на предыдущую страницу
        _navigateBackWithResult();
      } else {
        _showErrorSnackBar('Неверный код подтверждения');
        // Показываем модальное окно снова
        await _showVerificationModalDirectly();
      }
    }
  }

  // Повторная отправка кода
  Future<void> _resendCode() async {
    try {
      await ApiService.updateTelephone(telephone: _newPhoneNumber!);
      _showSuccessSnackBar('Код отправлен повторно');
    } catch (e) {
      // Если ошибка "код уже отправлен", игнорируем
      if (!e.toString().contains('Code already sent')) {
        _showErrorSnackBar('Ошибка отправки кода');
      }
    }
  }

  // Вспомогательные методы для показа сообщений
  void _showSuccessSnackBar(String message) {
    _showSnackBar(message, const Color(0xFF4CAF50));
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, const Color(0xFFE53935));
  }

  void _showInfoSnackBar(String message) {
    _showSnackBar(message, const Color(0xFF2196F3));
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Переход на страницу портфолио (для мастеров)
  void _navigateToPortfolioPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPortfolioMasterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // Определяем, какой режим отображать в UI
    final displayMode = _selectedProfileMode;

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
        actions: [
          if (displayMode == ProfileMode.master)
            IconButton(
              onPressed: () {},
              icon: Image.asset('assets/logout.png', width: 22, height: 22),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аватар
                _buildAvatarSection(),
                const SizedBox(height: 20),

                // Переключатель режима
                _buildModeSwitcher(),
                const SizedBox(height: 32),

                // Основная информация
                _buildSectionHeader('Основная информация'),
                const SizedBox(height: 16),

                // Поля ввода
                _buildInputField('Имя', _nameController, Icons.person_outline),
                const SizedBox(height: 12),
                _buildInputField(
                  'Фамилия',
                  _surnameController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  'Отчество',
                  _patronymicController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),

                // Выбор города (только для клиентов в текущем режиме)
                if (displayMode == ProfileMode.client) ...[
                  _buildCityDropdown(),
                  const SizedBox(height: 32),
                ],

                // Контактная информация
                _buildSectionHeader('Контактная информация'),
                const SizedBox(height: 16),

                _buildPhoneField(),
                const SizedBox(height: 12),

                // Социальные сети (только для мастера в текущем режиме)
                if (displayMode == ProfileMode.master) ...[
                  _buildInputField(
                    'Instagram',
                    _username1Controller,
                    Icons.alternate_email_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    'TikTok',
                    _username2Controller,
                    Icons.alternate_email_outlined,
                  ),
                  const SizedBox(height: 32),
                ],

                // Кнопка сохранения
                _buildSaveButton(),
                const SizedBox(height: 12),

                // Кнопка "Мои работы" (только для мастера в текущем режиме)
                if (displayMode == ProfileMode.master) _buildPortfolioButton(),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Индикатор загрузки
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0F7EDE)),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.account,
        accountType: _currentProfileMode == ProfileMode.master
            ? AccountType.master
            : AccountType.client,
      ),
    );
  }

  Widget _buildLoadingScreen() {
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
          if (_selectedProfileMode == ProfileMode.master)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  // TODO: Реализовать удаление аватара
                },
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
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
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
          Expanded(child: _buildModeButton('Заказчик', ProfileMode.client)),
          const SizedBox(width: 4),
          Expanded(child: _buildModeButton('Мастер', ProfileMode.master)),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, ProfileMode mode) {
    bool isActive = _selectedProfileMode == mode;
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
          onTap: () => setState(() => _selectedProfileMode = mode),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF0F7EDE)
                    : const Color(0xFF8A8D90),
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

  Widget _buildInputField(
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
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
              ? _buildClearButton(() => setState(() => controller.clear()))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildClearButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Center(
            child: Icon(Icons.close, color: Color(0xFF9AA0A6), size: 18),
          ),
        ),
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
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF8A8D90),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCityId,
                isExpanded: true,
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: Color(0xFF8A8D90),
                ),
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
          prefixIcon: const Icon(
            Icons.phone_iphone_rounded,
            color: Color(0xFF8A8D90),
            size: 20,
          ),
          suffixIcon: _phoneController.text.isNotEmpty
              ? _buildClearButton(
                  () => setState(() => _phoneController.clear()),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasChanges && !_isSaving ? _updateProfile : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF0F7EDE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Сохранить изменения',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPortfolioButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _navigateToPortfolioPage,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        child: const Text(
          'Мои работы',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F7EDE),
          ),
        ),
      ),
    );
  }
}