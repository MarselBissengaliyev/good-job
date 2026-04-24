import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodjob/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:goodjob/models/master_review.dart';
import 'package:goodjob/widgets/add_review_dialog.dart';

class InterestedInOrderPage extends StatefulWidget {
  final Map<String, dynamic> viewer;
  final Map<String, dynamic> order;

  const InterestedInOrderPage({
    super.key,
    required this.viewer,
    required this.order,
  });

  @override
  State<InterestedInOrderPage> createState() => _InterestedInOrderPageState();
}

class _InterestedInOrderPageState extends State<InterestedInOrderPage> {
  Map<String, dynamic>? _masterData;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  
  // Новые переменные для отзывов
  List<MasterReview> _reviews = [];
  bool _isLoadingReviews = false;
  String? _myReviewId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
    _getCurrentUser();

    // Устанавливаем цвет системной навигации
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();

    // Возвращаем стандартные настройки при выходе
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    super.dispose();
  }

  Future<void> _getCurrentUser() async {

    
    // Здесь нужно получить ID текущего пользователя
    // Это можно сделать через API профиля
    try {
      final profile = await ApiService.getProfile();
      if (profile['data'] != null) {
        setState(() {
          _currentUserId = profile['data']['id']?.toString();
        });
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _loadMasterData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final masterId =
          widget.viewer['master_id'] ??
          widget.viewer['master']['id'] ??
          widget.viewer['id'];

      if (masterId == null) {
        throw Exception('ID мастера не найден');
      }

      // Загружаем данные мастера с сервера
      final response = await ApiService.getMasterById(masterId.toString());

      setState(() {
        _masterData = response['data'];
      });
      
      // Загружаем отзывы
      await _loadReviews(masterId.toString());
      
    } catch (e) {
      print('Error loading master data: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews(String masterId) async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final response = await ApiService.getMasterReviews(masterId);
      
      if (response['data'] != null) {
        final List<dynamic> reviewsData = response['data'];
        setState(() {
          _reviews = MasterReview.fromJsonList(reviewsData);
          
          // Проверяем, есть ли отзыв от текущего пользователя
          if (_currentUserId != null) {
            try {
              final myReview = _reviews.firstWhere(
                (review) => review.client.id == _currentUserId,
              );
              _myReviewId = myReview.id.toString();
            } catch (e) {
              _myReviewId = null;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        _showCustomSnackBar(
          message: 'Ошибка загрузки отзывов',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _openAddReviewDialog() {
    final existingReview = _myReviewId != null 
        ? _reviews.firstWhere((r) => r.id.toString() == _myReviewId)
        : null;

    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        initialRating: existingReview?.rating,
        initialComment: existingReview?.comment,
        onSave: (rating, comment) async {
          try {
            final masterId = _masterData!['id'].toString();
            
            if (_myReviewId != null) {
              // Обновляем существующий отзыв
              await ApiService.updateMasterReview(
                masterId: masterId,
                reviewId: _myReviewId!,
                rating: rating,
                comment: comment.isEmpty ? null : comment,
              );
              _showCustomSnackBar(
                message: 'Отзыв обновлен',
                isSuccess: true,
              );
            } else {
              // Создаем новый отзыв
              await ApiService.createMasterReview(
                masterId: masterId,
                rating: rating,
                comment: comment.isEmpty ? null : comment,
              );
              _showCustomSnackBar(
                message: 'Отзыв добавлен',
                isSuccess: true,
              );
            }
            
            // Обновляем список отзывов
            await _loadReviews(masterId);
            // Обновляем рейтинг мастера
            await _loadMasterData();
            
          } catch (e) {
            _showCustomSnackBar(
              message: 'Ошибка при сохранении отзыва: $e',
              isSuccess: false,
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteReview() async {
    if (_myReviewId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Удаление отзыва',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        content: const Text(
          'Вы уверены, что хотите удалить свой отзыв?',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final masterId = _masterData!['id'].toString();
        await ApiService.deleteMasterReview(
          masterId: masterId,
          reviewId: _myReviewId!,
        );
        
        _showCustomSnackBar(
          message: 'Отзыв удален',
          isSuccess: true,
        );
        
        _myReviewId = null;
        await _loadReviews(masterId);
        await _loadMasterData();
        
      } catch (e) {
        _showCustomSnackBar(
          message: 'Ошибка при удалении отзыва',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadMasterData();
  }

  void _showCustomSnackBar({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showCustomSnackBar(
          message: 'Не удалось открыть ссылку',
          isSuccess: false,
        );
      }
    }
  }

  String? _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return 'https://good-job.kz/storage/$imagePath';
  }

  Widget _buildImageGallery() {
    final workPhotos = _masterData?['workPhotos'] as List? ?? [];

    if (workPhotos.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Нет работ мастера',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Основное изображение с PageView
        Container(
          height: 200,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: workPhotos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final photo = workPhotos[index];
                  final imageUrl = _getFullImageUrl(
                    photo['image_url'] ?? photo['image'],
                  );

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ошибка загрузки',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              if (workPhotos.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentImageIndex > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF41454A),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentImageIndex < workPhotos.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF41454A),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${workPhotos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (workPhotos.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: workPhotos.length,
              itemBuilder: (context, index) {
                final photo = workPhotos[index];
                final imageUrl = _getFullImageUrl(
                  photo['image_url'] ?? photo['image'],
                );
                final isSelected = index == _currentImageIndex;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F7EDE)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.broken_image,
                              size: 16,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Отзывы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF41454A),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                Row(
                  children: [
              
                      IconButton(
                        onPressed: _openAddReviewDialog,
                        icon: Icon(
                          _myReviewId != null ? Icons.edit : Icons.add,
                          color: const Color(0xFF0F7EDE),
                          size: 24,
                        ),
                        tooltip: _myReviewId != null 
                            ? 'Редактировать отзыв' 
                            : 'Добавить отзыв',
                      ),
                    if (_myReviewId != null)
                      IconButton(
                        onPressed: _deleteReview,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                        tooltip: 'Удалить отзыв',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingReviews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Пока нет отзывов',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                     
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _openAddReviewDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F7EDE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Оставить отзыв'),
                        ),
                     
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  final isMyReview = review.client.id == _currentUserId;
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: isMyReview
                        ? BoxDecoration(
                            color: const Color(0xFFE3F2FD).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF0F7EDE).withOpacity(0.3),
                            ),
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFE0E0E0),
                              child: Text(
                                review.client.firstname.isNotEmpty 
                                    ? review.client.firstname[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.client.fullName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF41454A),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  if (review.createdAt != null)
                                    Text(
                                      ApiService.formatDateTime(
                                        review.createdAt!.toIso8601String(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9E9E9E),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    review.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF41454A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (review.comment != null && review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 42),
                            child: Text(
                              review.comment!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5F6368),
                                fontFamily: 'Plus Jakarta Sans',
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF41454A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Мастер',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, color: Color(0xFF41454A)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ошибка загрузки',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Информация о мастере
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Аватар и основная информация
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    backgroundImage:
                                        _masterData?['avatar'] != null
                                        ? NetworkImage(
                                            _getFullImageUrl(
                                              _masterData!['avatar'],
                                            )!,
                                          )
                                        : null,
                                    child: _masterData?['avatar'] == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _masterData?['name'] ??
                                              '${_masterData?['firstname'] ?? ''} ${_masterData?['lastname'] ?? ''}'
                                                  .trim(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF41454A),
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (_masterData?['city'] != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 16,
                                                color: Color(0xFF9E9E9E),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _masterData!['city']['name'] ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF757575),
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _masterData?['rating']
                                                            ?.toString() ??
                                                        '0.0',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF41454A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${_masterData?['reviewsCount'] ?? 0} отзывов',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF757575),
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Категории мастера
                              if (_masterData?['categories'] != null &&
                                  (_masterData!['categories'] as List)
                                      .isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (_masterData!['categories'] as List)
                                      .map(
                                        (category) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFBBDEFB),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            category['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1976D2),
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),

                              const SizedBox(height: 16),

                        
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Социальные сети
                      if (_masterData?['ttUsername'] != null ||
                          _masterData?['instUsername'] != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Социальные сети',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF41454A),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_masterData?['ttUsername'] != null)
                                  _buildSocialRow(
                                    'TikTok',
                                    '@${_masterData!['ttUsername']}',
                                    'assets/tiktok.png',
                                    () => _launchUrl(
                                      'https://tiktok.com/@${_masterData!['ttUsername']}',
                                    ),
                                  ),
                                if (_masterData?['instUsername'] != null)
                                  _buildSocialRow(
                                    'Instagram',
                                    '@${_masterData!['instUsername']}',
                                    'assets/instagram.png',
                                    () => _launchUrl(
                                      'https://instagram.com/${_masterData!['instUsername']}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Работы мастера
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Работы мастера',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF41454A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildImageGallery(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Секция отзывов
                      _buildReviewsSection(),
                    ],
                  ),
                ),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Кнопка "Связаться"
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final phone = _masterData?['telephone'];
                        if (phone != null) {
                          _launchUrl('tel:$phone');
                        } else {
                          _showCustomSnackBar(
                            message: 'Телефон не указан',
                            isSuccess: false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7EDE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Связаться',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow(
    String platform,
    String username,
    String iconPath,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.public,
                    size: 16,
                    color: Color(0xFF9E9E9E),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F7EDE),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}