import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:goodjob/screens/login_page.dart';
import 'package:goodjob/screens/offer_page.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/city.dart';
import '../providers/language_provider.dart';
import '../role_provider.dart';
import '../services/api_service.dart';
import 'registration_4_page.dart';

class Registration3Page extends StatefulWidget {
  const Registration3Page({super.key});

  @override
  State<Registration3Page> createState() => _Registration3PageState();
}

class _Registration3PageState extends State<Registration3Page> with SingleTickerProviderStateMixin {
  int? selectedCityId;
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  bool _loadingCities = false;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;
  List<City> _cities = [];

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _surnameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  bool get isFormValid {
    String cleanPhone = _getCleanPhoneNumber(phoneController.text);
    return nameController.text.isNotEmpty &&
        surnameController.text.isNotEmpty &&
        cleanPhone.length >= 12 &&
        selectedCityId != null;
  }

  @override
  void initState() {
    super.initState();
    _loadCities();
    
    _nameFocusNode.addListener(_handleFocusChange);
    _surnameFocusNode.addListener(_handleFocusChange);
    _phoneFocusNode.addListener(_handleFocusChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _surnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_nameFocusNode.hasFocus || _surnameFocusNode.hasFocus || _phoneFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _loadCities() async {
    if (_loadingCities) return;
    setState(() => _loadingCities = true);

    try {
      final citiesData = await ApiService.getCities();
      final List<City> cities = citiesData.map<City>((cityJson) => City.fromJson(cityJson)).toList();
      
      if (mounted) {
        setState(() {
          _cities = cities;
          _loadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCities = false;
          _errorMessage = 'Не удалось загрузить список городов';
          _cities = [];
        });
      }
    }
  }

  String _extractErrorMessage(dynamic error, AppLocalizations appLocalizations) {
    try {
      if (error is String && error.contains('{')) {
        try {
          final errorJson = json.decode(error);
          return _parseApiError(errorJson, appLocalizations);
        } catch (e) {
          return error;
        }
      } else if (error is Map<String, dynamic>) {
        return _parseApiError(error, appLocalizations);
      }
      return error.toString();
    } catch (e) {
      return appLocalizations.translate('unknown_error');
    }
  }

  String _parseApiError(Map<String, dynamic> errorJson, AppLocalizations appLocalizations) {
    try {
      if (errorJson.containsKey('raw_response')) {
        final rawResponse = errorJson['raw_response'];
        if (rawResponse is String && rawResponse.isNotEmpty) {
          final parsedResponse = json.decode(rawResponse);
          if (parsedResponse is Map<String, dynamic>) {
            return _parseApiError(parsedResponse, appLocalizations);
          }
        }
      }

      String mainMessage = errorJson['message']?.toString() ?? '';
      
      if (errorJson['errors'] != null && errorJson['errors'] is Map) {
        final errors = errorJson['errors'] as Map<String, dynamic>;
        _fieldErrors = {};

        for (var entry in errors.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            String errorText = (entry.value as List).first.toString();
            
            if (errorText.contains('validation.phone')) {
              errorText = appLocalizations.translate('invalid_phone');
            } else if (errorText.contains('validation.required')) {
              errorText = appLocalizations.translate('field_required');
            } else if (errorText.contains('validation.')) {
              errorText = appLocalizations.translate('invalid_value');
            }

            _fieldErrors![entry.key] = errorText;
          }
        }

        if (_fieldErrors!.isNotEmpty) {
          return appLocalizations.translate('please_fix_errors');
        }
      }

      return mainMessage.isNotEmpty ? mainMessage : appLocalizations.translate('registration_error');
    } catch (e) {
      return appLocalizations.translate('registration_error');
    }
  }

  String? _getFieldError(String fieldName, AppLocalizations appLocalizations) {
    if (_fieldErrors == null) return null;
    
    Map<String, String> fieldMapping = {
      'Имя': 'firstname',
      'Фамилия': 'lastname',
      'Город': 'city_id',
      'Телефон': 'telephone',
    };
    
    String apiFieldName = fieldMapping[fieldName] ?? fieldName.toLowerCase();
    return _fieldErrors![apiFieldName];
  }

  Widget _buildFieldError(String fieldName, AppLocalizations appLocalizations) {
    final error = _getFieldError(fieldName, appLocalizations);
    if (error == null) return const SizedBox.shrink();

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0, left: 4.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerUser(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    
    if (!isFormValid) {
      setState(() => _errorMessage = appLocalizations.translate('fill_all_fields'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = null;
    });

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String phoneNumber = _getCleanPhoneNumber(phoneController.text);
      final firstname = nameController.text.trim();
      final lastname = surnameController.text.trim();

      final registerResponse = await ApiService.registerUser(
        firstname: firstname,
        lastname: lastname,
        telephone: phoneNumber,
        cityId: selectedCityId!,
        activeMode: roleProvider.selectedRole == UserRole.master ? 'master' : 'client',
      );

      int ttl = 60;
      if (registerResponse is Map<String, dynamic> && registerResponse.containsKey('codeTtl')) {
        ttl = registerResponse['codeTtl'];
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Registration4Page(
              phoneNumber: phoneNumber,
              codeTtl: ttl,
            ),
          ),
        );
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e, appLocalizations);
      if (mounted) {
        setState(() => _errorMessage = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final roleProvider = Provider.of<RoleProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Верхняя панель с логотипом и селектором языка
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new),
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Image.asset('assets/logo.png', height: 28),
                            const Spacer(),
                            _buildLanguageButton(context, languageProvider, appLocalizations),
                          ],
                        ),
                      ),

                      // Основной контент с анимацией
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Иконка
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.blue.shade400, Colors.blue.shade700],
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
                                      child: const Icon(Icons.person_outline, size: 40, color: Colors.white),
                                    ),
                                    const SizedBox(height: 24),

                                    Text(
                                      appLocalizations.translate('registration'),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),

                                    Text(
                                      roleProvider.isMasterSelected
                                          ? appLocalizations.translate('register_as_master')
                                          : appLocalizations.translate('register_as_client'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),

                                    // Поле имени
                                    _buildTextField(
                                      controller: nameController,
                                      focusNode: _nameFocusNode,
                                      label: appLocalizations.translate('first_name'),
                                      onChanged: () => _clearFieldError('firstname'),
                                      errorWidget: _buildFieldError('Имя', appLocalizations),
                                    ),
                                    const SizedBox(height: 12),

                                    // Поле фамилии
                                    _buildTextField(
                                      controller: surnameController,
                                      focusNode: _surnameFocusNode,
                                      label: appLocalizations.translate('last_name'),
                                      onChanged: () => _clearFieldError('lastname'),
                                      errorWidget: _buildFieldError('Фамилия', appLocalizations),
                                    ),
                                    const SizedBox(height: 12),

                                    // Выбор города
                                    _buildCitySelector(appLocalizations),
                                    const SizedBox(height: 12),

                                    // Поле телефона
                                    _buildPhoneField(appLocalizations),
                                    const SizedBox(height: 24),

                                    // Общая ошибка
                                    if (_errorMessage != null && (_fieldErrors == null || _fieldErrors!.isEmpty))
                                      _buildErrorMessage(appLocalizations),

                                    // Соглашение
                                    _buildTermsAndConditions(appLocalizations),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Фиксированная область с кнопками
                      _buildBottomButtons(appLocalizations),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, LanguageProvider languageProvider, AppLocalizations appLocalizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('RU', const Locale('ru'), languageProvider.locale.languageCode == 'ru', languageProvider, context),
          _buildLanguageOption('KZ', const Locale('kk'), languageProvider.locale.languageCode == 'kk', languageProvider, context),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, Locale locale, bool isActive, LanguageProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.setLanguage(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.languageCode == 'ru' ? 'Язык изменен на русский' : 'Тіл қазақшаға өзгертілді'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required VoidCallback onChanged,
    required Widget errorWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
          ),
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16),
        ),
        errorWidget,
      ],
    );
  }

  Widget _buildCitySelector(AppLocalizations appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadingCities)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 16),
                Text(
                  appLocalizations.translate('loading_cities'),
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey),
                ),
              ],
            ),
          )
        else if (_cities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizations.translate('failed_to_load_cities'),
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _loadCities,
                  child: Text(
                    appLocalizations.translate('try_again'),
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _getFieldError('Город', appLocalizations) != null ? Colors.red : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<int>(
                value: selectedCityId,
                onChanged: (value) {
                  setState(() {
                    selectedCityId = value;
                    _clearFieldError('city_id');
                  });
                },
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.translate('city'),
                  labelStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: _getFieldError('Город', appLocalizations) != null ? Colors.red : Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(Icons.location_city, color: Colors.grey.shade600),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                hint: selectedCityId == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          appLocalizations.translate('select_city'),
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey),
                        ),
                      )
                    : null,
                items: _cities.map((city) {
                  return DropdownMenuItem<int>(
                    value: city.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(city.name, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        _buildFieldError('Город', appLocalizations),
      ],
    );
  }

  Widget _buildPhoneField(AppLocalizations appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: phoneController,
          focusNode: _phoneFocusNode,
          inputFormatters: [maskFormatter],
          onChanged: (_) => _clearFieldError('telephone'),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: appLocalizations.translate('phone'),
            labelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey),
            hintText: '+7 (___) ___-__-__',
            hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Plus Jakarta Sans'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(Icons.phone, color: Colors.grey.shade600),
            suffixIcon: phoneController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => phoneController.clear()),
                  )
                : null,
          ),
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                appLocalizations.translate('phone_format_hint'),
                style: TextStyle(
                  fontSize: 11,
                  color: _getFieldError('Телефон', appLocalizations) != null ? Colors.red : Colors.grey.shade600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
        _buildFieldError('Телефон', appLocalizations),
      ],
    );
  }

  Widget _buildErrorMessage(AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.translate('error'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions(AppLocalizations appLocalizations) {
    return Column(
      children: [
        Text(
          appLocalizations.translate('creating_account_agreement'),
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OfferPage()));
          },
          child: Text(
            appLocalizations.translate('public_offer'),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(AppLocalizations appLocalizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isFormValid && !_isLoading ? () => _registerUser(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFormValid && !_isLoading ? Colors.blue.shade700 : Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isFormValid && !_isLoading ? 2 : 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(
                      appLocalizations.translate('get_verification_code'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Plus Jakarta Sans', color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(appLocalizations.translate('or'), style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                appLocalizations.translate('login'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Plus Jakarta Sans', color: Colors.blue.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFieldError(String fieldName) {
    setState(() {
      if (_fieldErrors != null) _fieldErrors!.remove(fieldName);
      _errorMessage = null;
    });
  }
}