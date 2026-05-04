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
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';

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
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
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
            Text(
              appLocalizations.translate('phone_verification'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2125),
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: '${appLocalizations.translate('code_sent_to')}\n',
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
              children: List.generate(4, (index) => _buildOtpField(index)),
            ),
            const SizedBox(height: 24),
            _buildTimerOrResend(appLocalizations),
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
                    child: Text(
                      appLocalizations.translate('cancel'),
                      style: const TextStyle(
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
                        ? () => Navigator.of(context).pop(_currentInputCode)
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
                        : Text(
                            appLocalizations.translate('confirm'),
                            style: const TextStyle(
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

  Widget _buildOtpField(int index) {
    return SizedBox(
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
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
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
      return Text(
        '${appLocalizations.translate('resend_code_in')} $mins:$secs',
        style: const TextStyle(color: Color(0xFF8A8D90), fontSize: 16),
      );
    }
    return GestureDetector(
      onTap: _isLoading ? null : () => Navigator.of(context).pop('resend'),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF0F7EDE),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              appLocalizations.translate('resend_code'),
              style: const TextStyle(
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

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  // Контроллеры полей
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _instagramController;
  late final TextEditingController _tiktokController;

  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = true;
  bool _isSaving = false;
  ProfileMode _currentProfileMode = ProfileMode.client;
  int? _selectedCityId;
  List<dynamic> _cities = [];
  Map<String, dynamic>? _userData;
  List<int> _selectedCategoryIds = [];
  List<dynamic> _categories = [];
  File? _avatarImage;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  String? _newPhoneNumber;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late _EditableProfileData _editableData;
  late _EditableProfileData _originalData;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimation();
    _loadInitialData();
    _setupSystemUI();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _patronymicController = TextEditingController();
    _phoneController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();

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

  void _setupSystemUI() {
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
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

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

  // Убираем использование AppLocalizations из _loadInitialData
  Future<void> _loadInitialData() async {
    try {
      final citiesData = await ApiService.getCities();
      final profileData = await ApiService.getProfile();
      final user = profileData['data'];
      _userData = user;
      final categoriesData = await ApiService.getCategories();

      final activeMode = user['activeMode'] ?? 'client';
      final currentMode = activeMode == 'master'
          ? ProfileMode.master
          : ProfileMode.client;

      List<int> categoryIds = [];
      if (currentMode == ProfileMode.master && user['categories'] != null) {
        final categoriesList = user['categories'] as List;
        if (categoriesList.isNotEmpty && categoriesList.first is Map) {
          categoryIds = categoriesList.map((cat) => cat['id'] as int).toList();
        }
      }

      String formattedPhone = _formatPhone(user['telephone'] ?? '');

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

      _editableData = _originalData.copyWith();

      // Проверяем, что виджет еще активен перед обновлением состояния
      if (mounted) {
        setState(() {
          _cities = citiesData;
          _categories = categoriesData;
          _currentProfileMode = currentMode;
          _selectedCityId = user['city']['id'];
          _avatarUrl = user['avatar'];
          _isLoading = false;
        });

        _updateControllersFromEditableData();
      }
    } catch (e) {
      print('[ERROR] Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Показываем ошибку через SnackBar, но без использования AppLocalizations
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatPhone(String phone) {
    if (phone.isEmpty) return '';
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 11 && cleanPhone.startsWith('7')) {
      String areaCode = cleanPhone.substring(1, 4);
      String firstPart = cleanPhone.substring(4, 7);
      String secondPart = cleanPhone.substring(7, 9);
      String thirdPart = cleanPhone.substring(9, 11);
      return '+7 ($areaCode) $firstPart-$secondPart-$thirdPart';
    }
    return phone;
  }

  bool get _hasChanges {
    _updateEditableDataFromControllers();
    return _editableData.firstname != _originalData.firstname ||
        _editableData.lastname != _originalData.lastname ||
        _editableData.patronymic != _originalData.patronymic ||
        _editableData.cityId != _originalData.cityId ||
        _editableData.phone != _originalData.phone ||
        _editableData.selectedMode != _originalData.selectedMode ||
        (_editableData.selectedMode == ProfileMode.master &&
            (_editableData.instagram != _originalData.instagram ||
                _editableData.tiktok != _originalData.tiktok ||
                !_listsAreEqual(
                  _editableData.categoryIds,
                  _originalData.categoryIds,
                )));
  }

  bool _listsAreEqual(List<int>? list1, List<int>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    return list1.every((item) => list2.contains(item));
  }

  Future<void> _updateProfile() async {
    final appLocalizations = AppLocalizations.of(context)!;
    _updateEditableDataFromControllers();

    if (_editableData.firstname.isEmpty ||
        _editableData.lastname.isEmpty ||
        _editableData.cityId == null) {
      _showErrorSnackBar(appLocalizations.translate('fill_required_fields'));
      return;
    }

    setState(() => _isSaving = true);

    try {
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
            ? _editableData.instagram.trim()
            : null,
        ttUsername: _editableData.selectedMode == ProfileMode.master
            ? _editableData.tiktok.trim()
            : null,
      );

      if (_editableData.selectedMode == ProfileMode.master) {
        await _updateMasterProfileIfNeeded();
      }

      setState(() {
        _originalData = _editableData.copyWith();
        _currentProfileMode = _editableData.selectedMode;
      });

      final currentPhone = _getCleanPhoneNumber(_editableData.phone);
      if (await _hasPhoneChanged(currentPhone)) {
        _newPhoneNumber = currentPhone;
        await _handlePhoneVerification();
      } else {
        _showSuccessSnackBar(appLocalizations.translate('profile_updated'));
        _navigateBack();
      }
    } catch (e) {
      _showErrorSnackBar(
        '${appLocalizations.translate('error_updating_profile')}: $e',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateMasterProfileIfNeeded() async {
    final masterDataChanged =
        _editableData.instagram != _originalData.instagram ||
        _editableData.tiktok != _originalData.tiktok ||
        !_listsAreEqual(_editableData.categoryIds, _originalData.categoryIds);

    if (masterDataChanged) {
      try {
        await ApiService.updateMasterProfile(
          categories: _editableData.categoryIds.isNotEmpty
              ? _editableData.categoryIds
              : null,
          ttUsername: _editableData.tiktok.trim().isEmpty
              ? null
              : _editableData.tiktok.trim(),
          instUsername: _editableData.instagram.trim().isEmpty
              ? null
              : _editableData.instagram.trim(),
        );
      } catch (e) {
        print('⚠️ Error updating master profile: $e');
      }
    }
  }

  Future<bool> _hasPhoneChanged(String newPhone) async {
    try {
      final profileData = await ApiService.getProfile();
      final currentPhone = profileData['data']['telephone'] ?? '';
      return newPhone.isNotEmpty &&
          newPhone.length >= 10 &&
          newPhone != currentPhone;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handlePhoneVerification() async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      await ApiService.updateTelephone(telephone: _newPhoneNumber!);
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => VerificationModal(phoneNumber: _newPhoneNumber!),
      );

      if (result == 'resend') {
        await _resendCode();
        if (mounted) await _handlePhoneVerification();
      } else if (result != null) {
        await _confirmNewPhone(result, appLocalizations);
      }
    } catch (e) {
      if (e.toString().contains('Code already sent')) {
        await _showVerificationModalDirectly();
      } else {
        _showErrorSnackBar(
          '${appLocalizations.translate('error_sending_code')}: $e',
        );
      }
    }
  }

  Future<void> _showVerificationModalDirectly() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationModal(phoneNumber: _newPhoneNumber!),
    );

    if (result == 'resend') {
      await _resendCode();
      if (mounted) await _showVerificationModalDirectly();
    } else if (result != null) {
      await _confirmNewPhone(result, appLocalizations);
    }
  }

  Future<void> _confirmNewPhone(
    String code,
    AppLocalizations appLocalizations,
  ) async {
    try {
      await ApiService.confirmNewTelephone(
        telephone: _newPhoneNumber!,
        code: code,
      );
      _showSuccessSnackBar(appLocalizations.translate('phone_verified'));
      _updateControllersFromEditableData();
    } catch (e) {
      if (e.toString().contains('500') || e.toString().contains('422')) {
        _showInfoSnackBar(
          appLocalizations.translate('phone_sent_for_verification'),
        );
      } else {
        _showErrorSnackBar(appLocalizations.translate('invalid_code'));
        if (mounted) await _showVerificationModalDirectly();
      }
    }
  }

  Future<void> _resendCode() async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      await ApiService.updateTelephone(telephone: _newPhoneNumber!);
      _showSuccessSnackBar(appLocalizations.translate('code_resent'));
    } catch (e) {
      if (!e.toString().contains('Code already sent')) {
        _showErrorSnackBar(appLocalizations.translate('error_resending_code'));
      }
    }
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(
        context,
        _currentProfileMode == ProfileMode.master
            ? '/account-master'
            : '/account-client',
      );
    }
  }

  // В edit_profile_page.dart измените только метод _pickImage и _buildAvatarSection

  Future<void> _pickImage(ImageSource source) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          // Для Web - сохраняем XFile напрямую
          setState(() => _avatarImageFile = image);
          await _uploadAvatarWeb();
        } else {
          // Для мобильных - конвертируем в File
          setState(() => _avatarImage = File(image.path));
          await _uploadAvatar();
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        '${appLocalizations.translate('error_picking_image')}: $e',
      );
    }
  }

  // Добавьте новую переменную в класс
  XFile? _avatarImageFile; // Для Web

  Future<void> _uploadAvatarWeb() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_avatarImageFile == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      // Для Web нужно использовать специальный подход
      // Создаем MultipartFile из XFile для Web
      final bytes = await _avatarImageFile!.readAsBytes();
      final fileName = _avatarImageFile!.name;

      // Используем FormData для отправки
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      // Здесь нужно использовать ваш Dio клиент для отправки
      // Если у вас нет прямого доступа к Dio, добавьте метод в ApiService
      final response = await ApiService.uploadAvatarWeb(formData);

      if (mounted) {
        setState(() {
          _avatarUrl = response['data']?['avatar'];
          _isUploadingAvatar = false;
          _avatarImageFile = null;
        });
        _showSuccessSnackBar(appLocalizations.translate('avatar_updated'));
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showErrorSnackBar(
          '${appLocalizations.translate('error_uploading_avatar')}: $e',
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_avatarImage == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final response = await ApiService.uploadAvatar(_avatarImage!);
      if (mounted) {
        setState(() {
          _avatarUrl = response['data']?['avatar'];
          _isUploadingAvatar = false;
          _avatarImage = null;
        });
        _showSuccessSnackBar(appLocalizations.translate('avatar_updated'));
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showErrorSnackBar(
          '${appLocalizations.translate('error_uploading_avatar')}: $e',
        );
      }
    }
  }

  Widget _buildAvatarSection(AppLocalizations appLocalizations) {
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
                  : _getAvatarImage(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingAvatar
                  ? null
                  : () => _showImageSourceDialog(appLocalizations),
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

  Widget _getAvatarImage() {
    if (kIsWeb) {
      // Для Web - используем XFile или network
      if (_avatarImageFile != null) {
        return FutureBuilder<Uint8List?>(
          future: _avatarImageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return Container(color: Colors.grey[200]);
          },
        );
      } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        // Важно: проверьте правильный URL для аватаров
        final avatarPath = _avatarUrl!.startsWith('http')
            ? _avatarUrl!
            : 'https://good-job.kz/storage/${_avatarUrl!.replaceFirst('storage/', '')}';
        return Image.network(
          avatarPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading avatar: $error');
            return const Icon(Icons.person, size: 60, color: Colors.white);
          },
        );
      } else {
        return const Icon(Icons.person, size: 60, color: Colors.white);
      }
    } else {
      // Для мобильных - используем File
      if (_avatarImage != null) {
        return Image.file(
          _avatarImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        final avatarPath = _avatarUrl!.startsWith('http')
            ? _avatarUrl!
            : 'https://good-job.kz/storage/${_avatarUrl!.replaceFirst('storage/', '')}';
        return Image.network(
          avatarPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading avatar: $error');
            return const Icon(Icons.person, size: 60, color: Colors.white);
          },
        );
      } else {
        return const Icon(Icons.person, size: 60, color: Colors.white);
      }
    }
  }

  void _showSuccessSnackBar(String message) =>
      _showSnackBar(message, const Color(0xFF4CAF50));
  void _showErrorSnackBar(String message) =>
      _showSnackBar(message, const Color(0xFFE53935));
  void _showInfoSnackBar(String message) =>
      _showSnackBar(message, const Color(0xFF2196F3));

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

  void _showCategoriesDialog() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_categories.isEmpty) {
      try {
        final categories = await ApiService.getCategories();
        setState(() => _categories = categories);
      } catch (e) {
        _showErrorSnackBar(
          appLocalizations.translate('error_loading_categories'),
        );
        return;
      }
    }

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
                    Text(
                      appLocalizations.translate('select_categories'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2125),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.translate('select_multiple_categories'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                      ),
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
                            child: Text(
                              appLocalizations.translate('cancel'),
                              style: const TextStyle(
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
                            child: Text(
                              appLocalizations.translate('done'),
                              style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return _buildLoadingScreen(appLocalizations);
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
            onPressed: _navigateBack,
          ),
          centerTitle: true,
          title: Text(
            appLocalizations.translate('edit_profile'),
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF1D2125),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            _buildLanguageButton(context, languageProvider, appLocalizations),
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(appLocalizations),
                    const SizedBox(height: 20),
                    _buildModeSwitcher(appLocalizations),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      appLocalizations.translate('basic_info'),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      appLocalizations.translate('first_name'),
                      _nameController,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      appLocalizations.translate('last_name'),
                      _surnameController,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      appLocalizations.translate('patronymic'),
                      _patronymicController,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildCityDropdown(appLocalizations),
                    _buildCategoriesSection(appLocalizations),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      appLocalizations.translate('contact_info'),
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneField(appLocalizations),
                    const SizedBox(height: 32),
                    if (_editableData.selectedMode == ProfileMode.master) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        appLocalizations.translate('social_media'),
                      ),
                      const SizedBox(height: 16),
                      _buildSocialField(
                        'Instagram',
                        _instagramController,
                        'assets/instagram.png',
                        Icons.alternate_email,
                      ),
                      const SizedBox(height: 12),
                      _buildSocialField(
                        'TikTok',
                        _tiktokController,
                        'assets/tiktok.png',
                        Icons.music_note,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoHint(
                        appLocalizations.translate('username_without_at'),
                      ),
                      const SizedBox(height: 32),
                    ],
                    _buildSaveButton(appLocalizations),
                    const SizedBox(height: 12),
                    if (_editableData.selectedMode == ProfileMode.master)
                      _buildPortfolioButton(appLocalizations),
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

  Widget _buildLanguageButton(
    BuildContext context,
    LanguageProvider languageProvider,
    AppLocalizations appLocalizations,
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
    final appLocalizations = AppLocalizations.of(context)!;
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

  Widget _buildLoadingScreen(AppLocalizations appLocalizations) {
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
            Text(
              appLocalizations.translate('loading_profile'),
              style: const TextStyle(
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

  Future<void> _showImageSourceDialog(AppLocalizations appLocalizations) async {
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
                Text(
                  appLocalizations.translate('select_source'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2125),
                  ),
                ),
                const SizedBox(height: 20),
                _buildImageSourceTile(
                  Icons.camera_alt_rounded,
                  appLocalizations.translate('take_photo'),
                  appLocalizations.translate('use_camera'),
                  () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                _buildImageSourceTile(
                  Icons.photo_library_rounded,
                  appLocalizations.translate('choose_from_gallery'),
                  appLocalizations.translate('select_existing_photo'),
                  () => _pickImage(ImageSource.gallery),
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
                    child: Text(
                      appLocalizations.translate('cancel'),
                      style: const TextStyle(
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

  Widget _buildImageSourceTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: title.contains('фото')
              ? const Color(0xFFE8F4FF)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: title.contains('фото')
              ? const Color(0xFF0F7EDE)
              : const Color(0xFF5F6368),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1D2125),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: Color(0xFF8A8D90)),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildModeSwitcher(AppLocalizations appLocalizations) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              appLocalizations.translate('client'),
              ProfileMode.client,
              appLocalizations,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton(
              appLocalizations.translate('master'),
              ProfileMode.master,
              appLocalizations,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    ProfileMode mode,
    AppLocalizations appLocalizations,
  ) {
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
              _editableData = _editableData.copyWith(selectedMode: mode);
              if (mode == ProfileMode.client) {
                _instagramController.clear();
                _tiktokController.clear();
                _selectedCategoryIds.clear();
                _editableData = _editableData.copyWith(
                  instagram: '',
                  tiktok: '',
                  categoryIds: [],
                );
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
        onChanged: (_) => setState(() => _updateEditableDataFromControllers()),
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

  Widget _buildCityDropdown(AppLocalizations appLocalizations) {
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
                hint: Text(
                  appLocalizations.translate('select_city'),
                  style: const TextStyle(color: Color(0xFF8A8D90)),
                ),
                items: _cities
                    .map(
                      (city) => DropdownMenuItem<int>(
                        value: city['id'],
                        child: Text(city['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedCityId = val;
                  _updateEditableDataFromControllers();
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(AppLocalizations appLocalizations) {
    if (_editableData.selectedMode != ProfileMode.master)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionHeader(appLocalizations.translate('service_categories')),
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
                      Text(
                        appLocalizations.translate('service_categories'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _editableData.categoryIds.isEmpty
                            ? appLocalizations.translate('not_selected')
                            : '${appLocalizations.translate('selected')}: ${_editableData.categoryIds.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _editableData.categoryIds.isEmpty
                              ? const Color(0xFF8A8D90)
                              : const Color(0xFF0F7EDE),
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
                orElse: () => {'name': 'Category $id'},
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
                      onTap: () => setState(() {
                        _editableData.categoryIds.remove(id);
                        _selectedCategoryIds.remove(id);
                        _editableData = _editableData.copyWith(
                          categoryIds: List.from(_editableData.categoryIds),
                        );
                      }),
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

  Widget _buildPhoneField(AppLocalizations appLocalizations) {
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
        onChanged: (_) => setState(() => _updateEditableDataFromControllers()),
      ),
    );
  }

  Widget _buildSocialField(
    String label,
    TextEditingController controller,
    String assetPath,
    IconData fallbackIcon,
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
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF8A8D90)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  assetPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(fallbackIcon, size: 24),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? _buildClearButton(() => setState(() => controller.clear()))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (_) => setState(() => _updateEditableDataFromControllers()),
      ),
    );
  }

  Widget _buildInfoHint(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF0F7EDE)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations appLocalizations) {
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
            : Text(
                appLocalizations.translate('save_changes'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPortfolioButton(AppLocalizations appLocalizations) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditPortfolioMasterPage(),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Color(0xFF0F7EDE), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          appLocalizations.translate('my_works'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F7EDE),
          ),
        ),
      ),
    );
  }
}
