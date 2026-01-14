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
    return AlertDialog(
      title: const Text('Подтверждение номера'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Введите код отправленный на ${widget.phoneNumber}'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 50,
                child: TextField(
                  controller: widget.codeControllers[index],
                  focusNode: widget.codeFocusNodes[index],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 3) {
                      widget.codeFocusNodes[index + 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          if (widget.canResendCode)
            GestureDetector(
              onTap: widget.onResendCode,
              child: const Text('Отправить код снова', style: TextStyle(color: Color(0xFF0F7EDE))),
            )
          else
            Text('Отправить код снова через ${widget.resendTimer}с'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: widget.isCodeComplete ? widget.onConfirm : null,
          child: const Text('Подтвердить'),
        ),
      ],
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
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно обновлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
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
      ApiService.sendVerificationCode(telephone: _phoneController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF41454A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Редактировать профиль', 
          style: TextStyle(fontSize: 20, color: Color(0xFF41454A), fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 20),
            _buildModeSwitcher(),
            const SizedBox(height: 32),
            _buildSectionHeader('Основная информация'),
            const SizedBox(height: 16),
            _buildTextFieldWithClear('Имя', _nameController),
            const SizedBox(height: 8),
            _buildTextFieldWithClear('Фамилия', _surnameController),
            const SizedBox(height: 8),
            _buildTextFieldWithClear('Отчество', _patronymicController),
            const SizedBox(height: 16),
            _buildCityDropdown(),
            const SizedBox(height: 32),
            _buildSectionHeader('Контактная информация'),
            const SizedBox(height: 16),
            _buildTextFieldWithClear('Телефон', _phoneController),
            const SizedBox(height: 32),
            _buildSaveButton(),
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
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF96C5EB),
              border: Border.all(color: const Color(0xFF0F7EDE), width: 3),
              image: const DecorationImage(image: AssetImage('assets/avatar.png'), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Color(0xFF0F7EDE), shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Row(
      children: [
        _modeButton('Мастер', 'master'),
        const SizedBox(width: 10),
        _modeButton('Заказчик', 'client'),
      ],
    );
  }

  Widget _modeButton(String label, String mode) {
    bool isActive = _activeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMode = mode),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F7EDE) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE0E0E0)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF5F6368),
              fontWeight: FontWeight.w500
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCityId,
          isExpanded: true,
          hint: const Text("Выберите город"),
          items: _cities.map((city) {
            return DropdownMenuItem<int>(
              value: city['id'],
              child: Text(city['name']),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCityId = val),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _openVerificationModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F7EDE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Сохранить', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(alignment: Alignment.centerLeft, child: Text(title, 
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF41454A))));
  }

  Widget _buildTextFieldWithClear(String hint, TextEditingController controller) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E0E0))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: InputBorder.none))),
          if (controller.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => controller.clear())),
        ],
      ),
    );
  }
}