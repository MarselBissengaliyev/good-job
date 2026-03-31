import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/custom_bottom_navbar.dart';
import 'package:goodjob/models/work-photo.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/services/api_service.dart';
import 'package:goodjob/services/auth/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'orders_master_page.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class EditPortfolioMasterPage extends StatefulWidget {
  const EditPortfolioMasterPage({super.key});

  @override
  State<EditPortfolioMasterPage> createState() =>
      _EditPortfolioMasterPageState();
}

class _EditPortfolioMasterPageState extends State<EditPortfolioMasterPage>
    with SingleTickerProviderStateMixin {
  List<WorkPhoto> _portfolioImages = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDataLoaded = false; // Add this flag to prevent multiple loads

  @override
  void initState() {
    super.initState();
    _initAnimation();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data here instead of initState
    if (!_isDataLoaded && mounted) {
      _isDataLoaded = true;
      _loadWorkPhotos();
    }
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

  @override
  void dispose() {
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

 Future<void> _loadWorkPhotos() async {
    // Don't access AppLocalizations here anymore
    setState(() => _isLoading = true);

    try {
      final photos = await ApiService.getWorkPhotos();
      setState(() {
        _portfolioImages = photos.isNotEmpty ? photos : [];
      });
    } catch (e) {
      if (mounted) {
        // Access appLocalizations only when showing the snackbar
        final appLocalizations = AppLocalizations.of(context);
        _showSnackBar(
          '${appLocalizations?.translate('error_loading_works') ?? 'Ошибка загрузки работ'}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: false,
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
          title: Text(
            appLocalizations?.translate('my_works') ?? 'Мои работы',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
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
          child: _isLoading
              ? _buildLoadingIndicator(appLocalizations)
              : _buildContent(appLocalizations),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
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
              activeItem: NavItem.portfolio,
              accountType: AccountType.master,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    LanguageProvider languageProvider,
    AppLocalizations? appLocalizations,
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

  Widget _buildLoadingIndicator(AppLocalizations? appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0F7EDE)),
          const SizedBox(height: 16),
          Text(
            appLocalizations?.translate('loading_works') ?? 'Загрузка работ...',
            style: const TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations? appLocalizations) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_portfolioImages.isEmpty)
              _buildEmptyState(appLocalizations)
            else
              _buildPortfolioGrid(appLocalizations),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library,
              size: 60,
              color: Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            appLocalizations?.translate('no_works_yet') ?? 'Пока нет работ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizations?.translate('add_first_work') ??
                'Нажмите на кнопку "+", чтобы добавить первую работу',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A8D90),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _addNewWork,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7EDE),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F7EDE).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations?.translate('add_work') ??
                        'Добавить работу',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioGrid(AppLocalizations? appLocalizations) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _portfolioImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _portfolioImages.length) {
          return _buildAddButton(appLocalizations);
        }

        final row = (index / 3).floor();
        final column = index % 3;

        return Container(
          margin: EdgeInsets.only(
            right: column == 2 ? 4 : 0,
            left: column == 0 ? 4 : 0,
            top: row == 0 ? 4 : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'http://gj-back.checkedout.kz/storage/${_portfolioImages[index].path}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Color(0xFFBDBDBD),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () =>
                      _deleteWork(_portfolioImages[index].id, appLocalizations),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton(AppLocalizations? appLocalizations) {
    return GestureDetector(
      onTap: _addNewWork,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F7EDE).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 32, color: Color(0xFF0F7EDE)),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations?.translate('add') ?? 'Добавить',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0F7EDE),
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewWork() async {
    final appLocalizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            appLocalizations?.translate('add_work') ?? 'Добавить работу',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(
                icon: Icons.photo_library,
                title:
                    appLocalizations?.translate('choose_from_gallery') ??
                    'Выбрать из галереи',
                subtitle:
                    appLocalizations?.translate('select_existing_photo') ??
                    'Выберите существующее фото',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, appLocalizations);
                },
              ),
              const SizedBox(height: 8),
              _buildDialogOption(
                icon: Icons.camera_alt,
                title:
                    appLocalizations?.translate('take_photo') ?? 'Сделать фото',
                subtitle:
                    appLocalizations?.translate('use_camera') ??
                    'Использовать камеру',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, appLocalizations);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                appLocalizations?.translate('cancel') ?? 'Отмена',
                style: const TextStyle(
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7EDE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0F7EDE), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF41454A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A8D90),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFBDBDBD),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    AppLocalizations? appLocalizations,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          _showSnackBar(
            appLocalizations?.translate('file_too_large') ??
                'Файл слишком большой (максимум 10MB)',
            isError: true,
          );
          return;
        }

        if (!await file.exists()) {
          _showSnackBar(
            appLocalizations?.translate('file_not_found') ?? 'Файл не найден',
            isError: true,
          );
          return;
        }

        await _uploadImage(file, appLocalizations);
      }
    } catch (e) {
      if (e is PlatformException) {
        _handlePlatformException(e, source, appLocalizations);
      } else {
        _showSnackBar(
          '${appLocalizations?.translate('error_picking_image') ?? 'Ошибка выбора изображения'}: $e',
          isError: true,
        );
      }
    }
  }

  void _handlePlatformException(
    PlatformException error,
    ImageSource source,
    AppLocalizations? appLocalizations,
  ) {
    switch (error.code) {
      case 'photo_access_denied':
      case 'camera_access_denied':
      case 'permission_not_granted':
        _showPermissionError(source, appLocalizations);
        break;
      case 'no_available_camera':
        _showSnackBar(
          appLocalizations?.translate('no_camera') ?? 'Камера не найдена',
          isError: true,
        );
        break;
      case 'already_active':
        _showSnackBar(
          appLocalizations?.translate('camera_busy') ??
              'Камера уже используется',
          isError: true,
        );
        break;
      default:
        _showSnackBar(
          '${appLocalizations?.translate('error') ?? 'Ошибка'}: ${error.message}',
          isError: true,
        );
    }
  }

  void _showPermissionError(
    ImageSource source,
    AppLocalizations? appLocalizations,
  ) {
    String message = source == ImageSource.camera
        ? appLocalizations?.translate('camera_permission_required') ??
              'Для использования камеры необходимо предоставить разрешение'
        : appLocalizations?.translate('gallery_permission_required') ??
              'Для доступа к галерее необходимо предоставить разрешение';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appLocalizations?.translate('permission_required') ??
              'Требуется разрешение',
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations?.translate('cancel') ?? 'Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Здесь можно открыть настройки приложения
              if (Platform.isAndroid || Platform.isIOS) {
                // Для открытия настроек можно использовать url_launcher
              }
            },
            child: Text(appLocalizations?.translate('settings') ?? 'Настройки'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage(
    File imageFile,
    AppLocalizations? appLocalizations,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0F7EDE)),
              const SizedBox(height: 16),
              Text(
                appLocalizations?.translate('uploading') ?? 'Загрузка...',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await ApiService.uploadWorkPhoto(imageFile);
      if (mounted) {
        Navigator.pop(context);
        await _loadWorkPhotos();
        _showSnackBar(
          appLocalizations?.translate('image_uploaded') ??
              'Изображение успешно загружено',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          '${appLocalizations?.translate('error_uploading_image') ?? 'Ошибка загрузки изображения'}: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteWork(int id, AppLocalizations? appLocalizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          appLocalizations?.translate('delete_work') ?? 'Удалить работу?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        content: Text(
          appLocalizations?.translate('delete_work_confirm') ??
              'Вы уверены, что хотите удалить эту работу из портфолио?',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF5F6368),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              appLocalizations?.translate('cancel') ?? 'Отмена',
              style: const TextStyle(
                color: Color(0xFF5F6368),
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              appLocalizations?.translate('delete') ?? 'Удалить',
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteWorkPhoto(id);
        await _loadWorkPhotos();
        _showSnackBar(
          appLocalizations?.translate('work_deleted') ?? 'Работа удалена',
        );
      } catch (e) {
        _showSnackBar(
          '${appLocalizations?.translate('error_deleting_work') ?? 'Ошибка удаления'}: $e',
          isError: true,
        );
      }
    }
  }
}
