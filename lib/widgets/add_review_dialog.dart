// lib/widgets/add_review_dialog.dart

import 'package:flutter/material.dart';

class AddReviewDialog extends StatefulWidget {
  final Function(int rating, String comment) onSave;
  final int? initialRating;
  final String? initialComment;

  const AddReviewDialog({
    super.key,
    required this.onSave,
    this.initialRating,
    this.initialComment,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _commentController.text = widget.initialComment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Оцените мастера',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 20),
            
            // Звезды рейтинга
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: index < _rating ? Colors.amber : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 8),
            Text(
              _getRatingText(_rating),
              style: TextStyle(
                fontSize: 14,
                color: _rating > 0 ? const Color(0xFF0F7EDE) : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Поле для комментария
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered 
                      ? const Color(0xFF0F7EDE) 
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 2000,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                decoration: InputDecoration(
                  hintText: 'Напишите ваш отзыв (необязательно)',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                onTap: () {
                  setState(() => _isHovered = true);
                },
                onEditingComplete: () {
                  setState(() => _isHovered = false);
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating == 0 
                        ? null 
                        : () {
                            widget.onSave(
                              _rating, 
                              _commentController.text.trim(),
                            );
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7EDE),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.initialRating != null ? 'Сохранить' : 'Отправить',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Plus Jakarta Sans',
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Ужасно';
      case 2:
        return 'Плохо';
      case 3:
        return 'Нормально';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично';
      default:
        return 'Выберите оценку';
    }
  }
}