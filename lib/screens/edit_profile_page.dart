import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/edit_portfolio_master_page.dart';
import 'package:goodjob/services/auth/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

  String _formatPhoneNumber(String phone) {
    String cleanNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanNumber.startsWith('+7')) {
      cleanNumber = cleanNumber.substring(2);
    } else if (cleanNumber.startsWith('7')) {
      cleanNumber = cleanNumber.substring(1);
    } else if (cleanNumber.startsWith('8')) {
      cleanNumber = cleanNumber.substring(1);
    }

    if (cleanNumber.length == 10) {
      return '+7 (${cleanNumber.substring(0, 3)}) ${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6, 8)}-${cleanNumber.substring(8, 10)}';
    }

    return phone;
  }

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
    setState(() {});
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
            const Text(
              'Подтверждение номера',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2125),
              ),
            ),
            const SizedBox(height: 12),
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
                    text: _formatPhoneNumber(widget.phoneNumber),
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
            _buildTimerOrResend(),
            const SizedBox(height: 32),
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

// Класс для хранения изменяемых данных профиля
class _EditableProfileData {
  String firstname;
  String lastname;
  String patronymic;
  int? cityId;
  ProfileMode selectedMode;
  List<int> categoryIds;
  String instagram;
  String tiktok;
  String phone;

  _EditableProfileData({
    required this.firstname,
    required this.lastname,
    required this.patronymic,
    this.cityId,
    required this.selectedMode,
    required this.categoryIds,
    required this.instagram,
    required this.tiktok,
    required this.phone,
  });

  _EditableProfileData copyWith({
    String? firstname,
    String? lastname,
    String? patronymic,
    int? cityId,
    ProfileMode? selectedMode,
    List<int>? categoryIds,
    String? instagram,
    String? tiktok,
    String? phone,
  }) {
    return _EditableProfileData(
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      patronymic: patronymic ?? this.patronymic,
      cityId: cityId ?? this.cityId,
      selectedMode: selectedMode ?? this.selectedMode,
      categoryIds: categoryIds ?? List.from(this.categoryIds),
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      phone: phone ?? this.phone,
    );
  }
}

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
  late final TextEditingController _instagramController;
  late final TextEditingController _tiktokController;

  // Форматтер маски для телефона
  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Состояние данных
  bool _isLoading = true;
  bool _isSaving = false;
  ProfileMode _currentProfileMode = ProfileMode.client;
  int? _selectedCityId;
  List<dynamic> _cities = [];
  Map<String, dynamic>? _userData;

  // Для категорий (множественный выбор)
  List<int> _selectedCategoryIds = [];
  List<dynamic> _categories = [];

  // Для аватара
  File? _avatarImage;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  // Для модального окна подтверждения телефона
  String? _newPhoneNumber;

  // Изменяемые и оригинальные данные
  late _EditableProfileData _editableData;
  late _EditableProfileData _originalData;

  String _getCleanPhoneNumber(String maskedNumber) {
    String cleanNumber = maskedNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.startsWith('8') && cleanNumber.length == 11) {
      cleanNumber = '7${cleanNumber.substring(1)}';
    }

    if (!cleanNumber.startsWith('7')) {
      cleanNumber = '7$cleanNumber';
    }

    return '+$cleanNumber';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _patronymicController = TextEditingController();
    _phoneController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();

    // Инициализируем пустыми данными
    _editableData = _EditableProfileData(
      firstname: '',
      lastname: '',
      patronymic: '',
      cityId: null,
      selectedMode: widget.initialMode,
      categoryIds: [],
      instagram: '',
      tiktok: '',
      phone: '',
    );

    _loadInitialData();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _patronymicController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    super.dispose();
  }

  // Метод для обновления контроллеров из редактируемых данных
  void _updateControllersFromEditableData() {
    _nameController.text = _editableData.firstname;
    _surnameController.text = _editableData.lastname;
    _patronymicController.text = _editableData.patronymic;
    _phoneController.text = _editableData.phone;
    _instagramController.text = _editableData.instagram;
    _tiktokController.text = _editableData.tiktok;

    setState(() {
      _selectedCityId = _editableData.cityId;
      _selectedCategoryIds = List.from(_editableData.categoryIds);
    });
  }

  // Метод для обновления редактируемых данных из контроллеров
  void _updateEditableDataFromControllers() {
    _editableData = _editableData.copyWith(
      firstname: _nameController.text,
      lastname: _surnameController.text,
      patronymic: _patronymicController.text,
      cityId: _selectedCityId,
      categoryIds: _selectedCategoryIds,
      instagram: _instagramController.text,
      tiktok: _tiktokController.text,
      phone: _phoneController.text,
    );
  }

  Future<void> _loadInitialData() async {
    try {
      final citiesData = await ApiService.getCities();
      final profileData = await ApiService.getProfile();
      final user = profileData['data'];

      // Сохраняем userData
      _userData = user;

      final categoriesData = await ApiService.getCategories();

      // Определяем режим пользователя
      final activeMode = user['activeMode'] ?? 'client';
      final currentMode = activeMode == 'master'
          ? ProfileMode.master
          : ProfileMode.client;

      // Загружаем категории
      List<int> categoryIds = [];
      if (currentMode == ProfileMode.master) {
        if (user['categories'] != null && user['categories'] is List) {
          final categoriesList = user['categories'] as List;
          if (categoriesList.isNotEmpty) {
            if (categoriesList.first is Map &&
                categoriesList.first.containsKey('id')) {
              categoryIds = categoriesList
                  .map((cat) => cat['id'] as int)
                  .where((id) => id != null)
                  .toList();
            } else if (categoriesList.first is int) {
              categoryIds = List<int>.from(categoriesList);
            }
          }
        } else if (user['category'] != null) {
          if (user['category'] is Map && user['category'].containsKey('id')) {
            categoryIds = [user['category']['id'] as int];
          } else if (user['category'] is int) {
            categoryIds = [user['category'] as int];
          }
        }

        print('Загруженные категории мастера: $categoryIds');
      } else {
        print('Пользователь клиент, категории не загружаем');
      }

      // Форматируем телефон
      String phone = user['telephone'] ?? '';
      String formattedPhone = '';
      if (phone.isNotEmpty) {
        String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.length == 11 && cleanPhone.startsWith('7')) {
          String areaCode = cleanPhone.substring(1, 4);
          String firstPart = cleanPhone.substring(4, 7);
          String secondPart = cleanPhone.substring(7, 9);
          String thirdPart = cleanPhone.substring(9, 11);
          formattedPhone = '+7 ($areaCode) $firstPart-$secondPart-$thirdPart';
        } else {
          formattedPhone = phone;
        }
      }

      // Сохраняем оригинальные данные
      _originalData = _EditableProfileData(
        firstname: user['firstname'] ?? '',
        lastname: user['lastname'] ?? '',
        patronymic: user['patronymic'] ?? '',
        cityId: user['city']['id'],
        selectedMode: currentMode,
        categoryIds: categoryIds,
        instagram: user['instUsername'] ?? '',
        tiktok: user['ttUsername'] ?? '',
        phone: formattedPhone,
      );

      // Копируем в редактируемые данные
      _editableData = _originalData.copyWith();

      setState(() {
        _cities = citiesData;
        _categories = categoriesData;
        _currentProfileMode = currentMode;
        _selectedCityId = user['city']['id'];
        _avatarUrl = user['avatar'];
        _isLoading = false;
      });

      // Обновляем UI после загрузки данных
      _updateControllersFromEditableData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    }
  }

  bool get _hasChanges {
    _updateEditableDataFromControllers();

    final basicFieldsChanged =
        _editableData.firstname != _originalData.firstname ||
        _editableData.lastname != _originalData.lastname ||
        _editableData.patronymic != _originalData.patronymic ||
        _editableData.cityId != _originalData.cityId ||
        _editableData.phone != _originalData.phone;

    final modeChanged =
        _editableData.selectedMode != _originalData.selectedMode;

    final masterFieldsChanged =
        _editableData.selectedMode == ProfileMode.master &&
        (_editableData.instagram != _originalData.instagram ||
            _editableData.tiktok != _originalData.tiktok ||
            !_listsAreEqual(
              _editableData.categoryIds,
              _originalData.categoryIds,
            ));

    return basicFieldsChanged || modeChanged || masterFieldsChanged;
  }

  bool _listsAreEqual(List<int>? list1, List<int>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    return list1.every((item) => list2.contains(item));
  }

  Future<void> _updateProfile() async {
    _updateEditableDataFromControllers();

    if (_editableData.firstname.isEmpty ||
        _editableData.lastname.isEmpty ||
        _editableData.cityId == null) {
      _showErrorSnackBar('Заполните обязательные поля');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Сначала обновляем основные данные профиля
      await ApiService.updateProfile(
        firstname: _editableData.firstname.trim(),
        lastname: _editableData.lastname.trim(),
        patronymic: _editableData.patronymic.trim().isEmpty
            ? null
            : _editableData.patronymic.trim(),
        cityId: _editableData.cityId!,
        activeMode: _editableData.selectedMode == ProfileMode.master
            ? 'master'
            : 'client',
        categoryIds: _editableData.selectedMode == ProfileMode.master
            ? _editableData.categoryIds
            : [],
        instUsername: _editableData.selectedMode == ProfileMode.master
            ? (_editableData.instagram.trim().isEmpty
                  ? ""
                  : _editableData.instagram.trim())
            : null,
        ttUsername: _editableData.selectedMode == ProfileMode.master
            ? (_editableData.tiktok.trim().isEmpty
                  ? ""
                  : _editableData.tiktok.trim())
            : null,
      );

      // Если пользователь - мастер, проверяем нужно ли обновлять socials и категории
      if (_editableData.selectedMode == ProfileMode.master) {
        // Проверяем, изменились ли данные мастера
        final masterDataChanged =
            _editableData.instagram != _originalData.instagram ||
            _editableData.tiktok != _originalData.tiktok ||
            !_listsAreEqual(
              _editableData.categoryIds,
              _originalData.categoryIds,
            );

        // Для описания - если вы добавите поле позже
        final descriptionChanged = false; // Заглушка, пока нет поля

        if (masterDataChanged) {
          try {
            // Для категорий требуется минимум 1 элемент
            final categoriesToSend = _editableData.categoryIds.isEmpty
                ? [] // Если категории пустые, отправляем пустой массив (но API вернет ошибку)
                : _editableData.categoryIds;

            await ApiService.updateMasterProfile(
              categories: categoriesToSend.isNotEmpty ? categoriesToSend : null,
              ttUsername: _editableData.tiktok.trim().isEmpty
                  ? null
                  : _editableData.tiktok.trim(),
              instUsername: _editableData.instagram.trim().isEmpty
                  ? null
                  : _editableData.instagram.trim(),
            );
            print('✅ Профиль мастера успешно обновлен через PATCH /me/master');
          } catch (e) {
            print('⚠️ Ошибка при обновлении профиля мастера: $e');
            // Не прерываем выполнение, так как основные данные уже сохранены
          }
        } else {
          print('✅ Данные мастера не изменились, пропускаем PATCH /me/master');
        }
      }

      // Обновляем оригинальные данные после успешного сохранения
      setState(() {
        _originalData = _editableData.copyWith();
        _currentProfileMode = _editableData.selectedMode;
      });

      final currentPhone = _getCleanPhoneNumber(_editableData.phone);
      if (await _hasPhoneChanged(currentPhone)) {
        _newPhoneNumber = currentPhone;

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          setState(() => _isSaving = false);
          await _showVerificationModal();
        }
      } else {
  setState(() => _isSaving = false);
  _showSuccessSnackBar('Профиль успешно обновлен');
  if (mounted) {
    // Проверяем, можем ли мы вернуться назад
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      // Если не можем, идем на главный экран
      Navigator.pushReplacementNamed(
        context,
        _currentProfileMode == ProfileMode.master 
            ? '/account-master' 
            : '/account-client',
      );
    }
  }
}
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Ошибка обновления профиля: $e');
    }
  }

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

  Future<void> _fetchDebugInfo() async {
    final data = await ApiService.getDebugSmsCode(_newPhoneNumber!);
    if (data != null && mounted) {
      setState(() {
        _expectedCode = data;
      });
      print('[DEBUG] Получен код для проверки: $_expectedCode');
    }
  }

  Future<void> _showVerificationModal() async {
    if (!mounted) return;

    try {
      print(
        '[DEBUG] Отправляем запрос на обновление телефона: $_newPhoneNumber',
      );
      await ApiService.updateTelephone(telephone: _newPhoneNumber!);
      await _fetchDebugInfo();

      if (!mounted) return;

      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => VerificationModal(phoneNumber: _newPhoneNumber!),
      );

      if (result != null && mounted) {
        if (result == 'resend') {
          await _resendCode();
          if (mounted) {
            await _showVerificationModal();
          }
        } else {
          await _confirmNewPhone(result);
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('Code already sent')) {
        if (mounted) {
          await _showVerificationModalDirectly();
        }
      } else {
        print('[ERROR] Ошибка при отправке кода: $e');
        _showErrorSnackBar('${e}');
      }
    }
  }

  Future<void> _showVerificationModalDirectly() async {
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationModal(phoneNumber: _newPhoneNumber!),
    );

    if (result != null && mounted) {
      if (result == 'resend') {
        await _resendCode();
        if (mounted) {
          await _showVerificationModalDirectly();
        }
      } else {
        await _confirmNewPhone(result);
      }
    }
  }

  Future<void> _confirmNewPhone(String code) async {
    try {
      await ApiService.confirmNewTelephone(
        telephone: _newPhoneNumber!,
        code: code,
      );

      _showSuccessSnackBar('Телефон успешно подтвержден');

      setState(() {
        String cleanPhone = _newPhoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.length == 11 && cleanPhone.startsWith('7')) {
          String areaCode = cleanPhone.substring(1, 4);
          String firstPart = cleanPhone.substring(4, 7);
          String secondPart = cleanPhone.substring(7, 9);
          String thirdPart = cleanPhone.substring(9, 11);
          _phoneController.text =
              '+7 ($areaCode) $firstPart-$secondPart-$thirdPart';
        } else {
          _phoneController.text = _newPhoneNumber!;
        }
      });
    } catch (e) {
      if (e.toString().contains('500') ||
          e.toString().contains('Call to a member function update()') ||
          e.toString().contains('422')) {
        _showInfoSnackBar('Телефон отправлен на подтверждение');

        setState(() {
          String cleanPhone = _newPhoneNumber!.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          if (cleanPhone.length == 11 && cleanPhone.startsWith('7')) {
            String areaCode = cleanPhone.substring(1, 4);
            String firstPart = cleanPhone.substring(4, 7);
            String secondPart = cleanPhone.substring(7, 9);
            String thirdPart = cleanPhone.substring(9, 11);
            _phoneController.text =
                '+7 ($areaCode) $firstPart-$secondPart-$thirdPart';
          } else {
            _phoneController.text = _newPhoneNumber!;
          }
        });
      } else {
        _showErrorSnackBar('Неверный код подтверждения');
        await _showVerificationModalDirectly();
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      await ApiService.updateTelephone(telephone: _newPhoneNumber!);
      _showSuccessSnackBar('Код отправлен повторно');
    } catch (e) {
      if (!e.toString().contains('Code already sent')) {
        _showErrorSnackBar('Ошибка отправки кода');
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Выберите источник',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2125),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF0F7EDE),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Сделать фото',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D2125),
                    ),
                  ),
                  subtitle: const Text(
                    'Использовать камеру',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8A8D90)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFF5F6368),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Выбрать из галереи',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D2125),
                    ),
                  ),
                  subtitle: const Text(
                    'Выберите существующее фото',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8A8D90)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                    ),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _avatarImage = File(image.path);
        });

        await _uploadAvatar();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора изображения: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarImage == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final response = await ApiService.uploadAvatar(_avatarImage!);

      if (mounted) {
        setState(() {
          _avatarUrl = response['data']?['avatar'];
          _isUploadingAvatar = false;
        });

        _showSuccessSnackBar('Аватар успешно обновлен');
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showErrorSnackBar('Ошибка загрузки аватара: ${e.toString()}');
      }
    }
  }

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

  void _navigateToPortfolioPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPortfolioMasterPage()),
    );
  }

  Future<void> _showCategoriesDialog() async {
    if (_categories.isEmpty) {
      try {
        final categories = await ApiService.getCategories();
        setState(() {
          _categories = categories;
        });
      } catch (e) {
        _showErrorSnackBar('Ошибка загрузки категорий');
        return;
      }
    }

    // Используем текущие выбранные категории из редактируемых данных
    final tempSelectedIds = List<int>.from(_editableData.categoryIds);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите категории',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2125),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Вы можете выбрать несколько категорий',
                      style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE8E8E8)),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = tempSelectedIds.contains(
                            category['id'],
                          );

                          return InkWell(
                            onTap: () {
                              setStateDialog(() {
                                if (isSelected) {
                                  tempSelectedIds.remove(category['id']);
                                } else {
                                  tempSelectedIds.add(category['id']);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF0F7EDE)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0F7EDE)
                                            : const Color(0xFF8A8D90),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      category['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? const Color(0xFF0F7EDE)
                                            : const Color(0xFF1D2125),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

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
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategoryIds = List.from(
                                  tempSelectedIds,
                                );
                                _editableData = _editableData.copyWith(
                                  categoryIds: List.from(tempSelectedIds),
                                );
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF0F7EDE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Готово',
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
          },
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    // Показываем секцию категорий только если выбран режим мастера в редактируемых данных
    if (_editableData.selectedMode != ProfileMode.master) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionHeader('Категории услуг'),
        const SizedBox(height: 12),

        InkWell(
          onTap: _showCategoriesDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: Color(0xFF0F7EDE),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Категории услуг',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_editableData.categoryIds.isEmpty)
                        const Text(
                          'Не выбрано',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8A8D90),
                          ),
                        )
                      else
                        Text(
                          'Выбрано: ${_editableData.categoryIds.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F7EDE),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF8A8D90)),
              ],
            ),
          ),
        ),

        if (_editableData.categoryIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _editableData.categoryIds.map((id) {
              final category = _categories.firstWhere(
                (c) => c['id'] == id,
                orElse: () => {'name': 'Категория $id'},
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0F7EDE).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F7EDE),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _editableData.categoryIds.remove(id);
                          _selectedCategoryIds.remove(id);
                          _editableData = _editableData.copyWith(
                            categoryIds: List.from(_editableData.categoryIds),
                          );
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF0F7EDE),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
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
  onPressed: () {
    // Проверяем, можем ли мы вернуться назад
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Если не можем, идем на соответствующий экран аккаунта
      Navigator.pushReplacementNamed(
        context,
        _currentProfileMode == ProfileMode.master 
            ? '/account-master' 
            : '/account-client',
      );
    }
  },
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
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 20),
                  _buildModeSwitcher(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Основная информация'),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Имя',
                    _nameController,
                    Icons.person_outline,
                    onChanged: () {
                      _updateEditableDataFromControllers();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    'Фамилия',
                    _surnameController,
                    Icons.person_outline,
                    onChanged: () {
                      _updateEditableDataFromControllers();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    'Отчество',
                    _patronymicController,
                    Icons.person_outline,
                    onChanged: () {
                      _updateEditableDataFromControllers();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCityDropdown(),

                  // Секция категорий для мастера
                  _buildCategoriesSection(),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Контактная информация'),
                  const SizedBox(height: 16),
                  _buildPhoneField(),
                  const SizedBox(height: 12),

                  if (_editableData.selectedMode == ProfileMode.master) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Социальные сети'),
                    const SizedBox(height: 16),
                    Container(
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
                        controller: _instagramController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1D2125),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Instagram',
                          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/instagram.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.alternate_email,
                                      color: Color(0xFFE4405F),
                                      size: 24,
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          suffixIcon: _instagramController.text.isNotEmpty
                              ? _buildClearButton(() {
                                  setState(() {
                                    _instagramController.clear();
                                    _updateEditableDataFromControllers();
                                  });
                                })
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        onChanged: (_) {
                          _updateEditableDataFromControllers();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                        controller: _tiktokController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1D2125),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'TikTok',
                          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/tiktok.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.music_note,
                                      color: Color(0xFF000000),
                                      size: 24,
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          suffixIcon: _tiktokController.text.isNotEmpty
                              ? _buildClearButton(() {
                                  setState(() {
                                    _tiktokController.clear();
                                    _updateEditableDataFromControllers();
                                  });
                                })
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        onChanged: (_) {
                          _updateEditableDataFromControllers();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF0F7EDE),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Вводите имя пользователя без @',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F6368),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildSaveButton(),
                  const SizedBox(height: 12),

                  if (_editableData.selectedMode == ProfileMode.master)
                    _buildPortfolioButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            if (_isSaving || _isUploadingAvatar)
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
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              accountType: _currentProfileMode == ProfileMode.master
                  ? AccountType.master
                  : AccountType.client,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
            child: ClipOval(
              child: _isUploadingAvatar
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                  : _avatarImage != null
                  ? Image.file(
                      _avatarImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    )
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ? Image.network(
                      'http://gj-back.checkedout.kz/storage/${_avatarUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : _showImageSourceDialog,
              child: Container(
                width: 36,
                height: 36,
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
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
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
          Expanded(child: _buildModeButton('Заказчик', ProfileMode.client)),
          const SizedBox(width: 4),
          Expanded(child: _buildModeButton('Мастер', ProfileMode.master)),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, ProfileMode mode) {
    bool isActive = _editableData.selectedMode == mode;
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
          onTap: () {
            setState(() {
              // Меняем только режим в редактируемых данных
              _editableData = _editableData.copyWith(selectedMode: mode);

              // Если переключились на клиента - очищаем поля мастера
              if (mode == ProfileMode.client) {
                _instagramController.clear();
                _tiktokController.clear();
                _selectedCategoryIds.clear();

                _editableData = _editableData.copyWith(
                  instagram: '',
                  tiktok: '',
                  categoryIds: [],
                );
              } else {
                // Если переключились на мастера - восстанавливаем сохраненные данные мастера
                // или оставляем как есть
              }
            });
          },
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
    IconData icon, {
    String? hintText,
    VoidCallback? onChanged,
  }) {
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
          hintText: hintText ?? hint,
          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
          prefixIcon: Icon(icon, color: const Color(0xFF8A8D90), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? _buildClearButton(() {
                  setState(() {
                    controller.clear();
                    if (onChanged != null) onChanged();
                  });
                })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (_) {
          if (onChanged != null) onChanged();
          setState(() {});
        },
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
                onChanged: (val) {
                  setState(() {
                    _selectedCityId = val;
                    _updateEditableDataFromControllers();
                  });
                },
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
        inputFormatters: [maskFormatter],
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1D2125),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '+7 (___) ___-__-__',
          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
          prefixIcon: const Icon(
            Icons.phone_iphone_rounded,
            color: Color(0xFF8A8D90),
            size: 20,
          ),
          suffixIcon: _phoneController.text.isNotEmpty
              ? _buildClearButton(() {
                  setState(() {
                    _phoneController.clear();
                    _updateEditableDataFromControllers();
                  });
                })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (_) {
          _updateEditableDataFromControllers();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    String cleanPhone = _getCleanPhoneNumber(_phoneController.text);
    bool isPhoneValid = cleanPhone.length >= 12;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasChanges && !_isSaving && isPhoneValid
            ? _updateProfile
            : null,
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
