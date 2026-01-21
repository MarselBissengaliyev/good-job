import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/custom_bottom_navbar.dart';
import 'package:flutter_application_1/models/work-photo.dart';
import 'package:flutter_application_1/screens/account_page.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'orders_master_page.dart';

class EditPortfolioMasterPage extends StatefulWidget {
  const EditPortfolioMasterPage({super.key});

  @override
  State<EditPortfolioMasterPage> createState() =>
      _EditPortfolioMasterPageState();
}

class _EditPortfolioMasterPageState extends State<EditPortfolioMasterPage> {
  List<WorkPhoto> _portfolioImages = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadWorkPhotos();
  }

  Future<void> _loadWorkPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photos = await ApiService.getWorkPhotos();
      setState(() {
        _portfolioImages = photos.isNotEmpty ? photos : [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки работ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Мои работы',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Image.asset('assets/logout.png', width: 22, height: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F7EDE)),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 4,
                        right: 4,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: _portfolioImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _portfolioImages.length) {
                            return GestureDetector(
                              onTap: () {
                                _addNewWork();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 32,
                                        color: Color(0xFF0F7EDE),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'http://gj-back.checkedout.kz/storage/${_portfolioImages[index].path}',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () {
                                      _deleteWork(_portfolioImages[index].id);
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F7EDE),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/close.png',
                                          width: 14,
                                          height: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.portfolio, // Указываем активную вкладку
        accountType: AccountType.master,
      ),
    );
  }

  Future<void> _addNewWork() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Добавить работу',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0F7EDE),
                ),
                title: const Text(
                  'Выбрать из галереи',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F7EDE)),
                title: const Text(
                  'Сделать фото',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    print('=== НАЧАЛО ВЫБОРА ИЗОБРАЖЕНИЯ ===');
    print('Источник: ${source == ImageSource.camera ? "КАМЕРА" : "ГАЛЕРЕЯ"}');
    print('Платформа: ${Platform.operatingSystem}');

    try {
      print('Запуск пикера изображений...');
      final XFile? image = await _picker
          .pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 2048,
            maxHeight: 2048,
          )
          .catchError((error, stackTrace) {
            print('❌ Ошибка в pickImage:');
            print('  Тип ошибки: ${error.runtimeType}');
            print('  Сообщение: $error');
            print('  Stack trace: $stackTrace');

            // Обработка специфических ошибок
            if (error is PlatformException) {
              print('  Код ошибки: ${error.code}');
              print('  Сообщение: ${error.message}');

              switch (error.code) {
                case 'photo_access_denied':
                case 'camera_access_denied':
                  _showPermissionError(context, source);
                  break;
                case 'no_available_camera':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Камера не найдена на устройстве'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  break;
                case 'already_active':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Камера уже используется другим приложением',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  break;
                case 'permission_not_granted':
                  _showPermissionError(context, source);
                  break;
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка доступа: ${error.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Неизвестная ошибка: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return null;
          });

      print(
        'Результат pickImage: ${image != null ? "УСПЕХ" : "ОТМЕНА/ОШИБКА"}',
      );

      if (image != null) {
        print('Изображение выбрано:');
        print('  Путь: ${image.path}');
        print('  Имя: ${image.name}');
        print('  Размер: ${image.length()} байт');
        print('  MIME тип: ${image.mimeType}');

        try {
          // Проверяем размер файла
          final file = File(image.path);
          final fileSize = await file.length();
          print('  Размер файла: $fileSize байт');

          if (fileSize > 10 * 1024 * 1024) {
            // 10MB limit
            print('❌ Файл слишком большой: ${fileSize ~/ (1024 * 1024)}MB');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Файл слишком большой (максимум 10MB)'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Проверяем, что файл существует и читаем
          if (!await file.exists()) {
            print('❌ Файл не существует по указанному пути');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Выбранный файл не найден'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          print('Начинаем загрузку изображения на сервер...');
          await _uploadImage(file);
        } catch (e) {
          print('❌ Ошибка при обработке выбранного файла:');
          print('  Тип ошибки: ${e.runtimeType}');
          print('  Сообщение: $e');
          print('  Stack trace: ${e is Error ? e.stackTrace : ""}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка обработки файла: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('⚠️ Пользователь отменил выбор изображения или произошла ошибка');
        // Не показываем ошибку, если пользователь просто отменил выбор
      }
    } catch (e) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА в _pickImage:');
      print('  Тип ошибки: ${e.runtimeType}');
      print('  Сообщение: $e');
      print('  Stack trace: ${e is Error ? e.stackTrace : ""}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Критическая ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      print('=== КОНЕЦ ВЫБОРА ИЗОБРАЖЕНИЯ ===\n');
    }
  }


  // Показ ошибки разрешений
  void _showPermissionError(BuildContext context, ImageSource source) {
    String message = source == ImageSource.camera
        ? 'Для использования камеры необходимо предоставить разрешение'
        : 'Для доступа к галерее необходимо предоставить разрешение';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется разрешение'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Здесь можно открыть настройки приложения
              if (Platform.isAndroid || Platform.isIOS) {
                // Для открытия настроек можно использовать url_launcher
                print('Нужно открыть настройки приложения');
              }
            },
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage(File imageFile) async {
    print('=== НАЧАЛО ЗАГРУЗКИ ИЗОБРАЖЕНИЯ ===');
    print('Файл: ${imageFile.path}');

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F7EDE)),
        ),
      );

      Navigator.pop(context); // Закрываем индикатор загрузки

      // Обновляем список изображений
      await _loadWorkPhotos();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Изображение успешно загружено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Закрываем индикатор загрузки
      print('❌ Ошибка загрузки изображения на сервер:');
      print('  Тип ошибки: ${e.runtimeType}');
      print('  Сообщение: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      print('=== КОНЕЦ ЗАГРУЗКИ ИЗОБРАЖЕНИЯ ===\n');
    }
  }

  Future<void> _deleteWork(int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Удалить работу?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: const Text(
            'Вы уверены, что хотите удалить эту работу из портфолио?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ApiService.deleteWorkPhoto(id);
                  await _loadWorkPhotos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Работа удалена'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка удаления: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Удалить',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Enum для статусов разрешений (упрощенный)
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
}

// Также добавьте в pubspec.yaml для полноценной работы с разрешениями:
// permission_handler: ^10.4.3
// url_launcher: ^6.1.14
