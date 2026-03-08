// lib/widgets/html_table_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HtmlTableWidget extends StatelessWidget {
  final String htmlContent;

  const HtmlTableWidget({Key? key, required this.htmlContent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Парсим HTML и создаем виджеты
    return _parseHtmlToWidgets(context);
  }

  Widget _parseHtmlToWidgets(BuildContext context) {
    try {
      // Простой парсинг для таблиц
      if (htmlContent.contains('<table>') || htmlContent.contains('<table ')) {
        return _buildTableFromHtml();
      }
      
      // Если это просто текст
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _stripHtmlTags(htmlContent),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      );
    } catch (e) {
      return Text(
        htmlContent,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF41454A),
        ),
      );
    }
  }

  Widget _buildTableFromHtml() {
    // Извлекаем строки таблицы
    List<TableRow> tableRows = [];
    
    // Простой парсинг строк таблицы
    RegExp rowRegex = RegExp(r'<tr>(.*?)</tr>', dotAll: true);
    Iterable<RegExpMatch> rowMatches = rowRegex.allMatches(htmlContent);
    
    bool isFirstRow = true;
    
    for (var rowMatch in rowMatches) {
      String rowContent = rowMatch.group(1) ?? '';
      
      // Извлекаем ячейки (th или td)
      RegExp cellRegex = RegExp(r'<(th|td)[^>]*>(.*?)</\1>', dotAll: true);
      Iterable<RegExpMatch> cellMatches = cellRegex.allMatches(rowContent);
      
      List<Widget> cells = [];
      
      for (var cellMatch in cellMatches) {
        String cellType = cellMatch.group(1) ?? 'td';
        String cellContent = cellMatch.group(2) ?? '';
        
        // Очищаем от HTML тегов внутри ячейки
        String cleanContent = _stripHtmlTags(cellContent).trim();
        
        cells.add(
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
              color: cellType == 'th' ? const Color(0xFFF5F5F5) : Colors.white,
            ),
            child: Text(
              cleanContent,
              style: TextStyle(
                fontSize: 14,
                fontWeight: cellType == 'th' ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF41454A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        );
      }
      
      // Добавляем пустые ячейки если нужно
      while (cells.length < 2) {
        cells.add(
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Text(''),
          ),
        );
      }
      
      tableRows.add(
        TableRow(
          decoration: BoxDecoration(
            color: isFirstRow ? const Color(0xFFF9F9F9) : Colors.white,
          ),
          children: cells,
        ),
      );
      
      isFirstRow = false;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
            verticalInside: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          children: tableRows.isNotEmpty ? tableRows : [
            TableRow(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text('Нет данных'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) return '';
    
    // Удаляем HTML теги
    String text = htmlString.replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ');
    
    // Декодируем HTML сущности
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    
    // Убираем множественные пробелы
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }
}