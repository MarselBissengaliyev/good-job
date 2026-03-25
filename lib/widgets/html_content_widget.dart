// lib/widgets/html_content_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final Function(double height)? onHeightChanged;

  const HtmlContentWidget({
    Key? key,
    required this.htmlContent,
    this.onHeightChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: HtmlWidget(
        htmlContent,
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Color(0xFF41454A),
          fontSize: 14,
          height: 1.5,
        ),
        onLoadingBuilder: (context, element, loadingProgress) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF0F7EDE),
                  ),
                ),
              ),
            ),
          );
        },
        onErrorBuilder: (context, element, error) {
          return Text(
            'Ошибка загрузки контента: $error',
            style: const TextStyle(color: Colors.red),
          );
        },
        renderMode: RenderMode.column,
        customStylesBuilder: (element) {
          if (element.localName == 'img') {
            return {
              'max-width': '100%',
              'height': 'auto',
              'border-radius': '12px',
            };
          }
          if (element.localName == 'table') {
            return {
              'width': '100%',
              'border-collapse': 'collapse',
              'margin': '16px 0',
            };
          }
          if (element.localName == 'td' || element.localName == 'th') {
            return {
              'padding': '12px',
              'border': '1px solid #E0E0E0',
              'text-align': 'left',
            };
          }
          if (element.localName == 'th') {
            return {
              'background-color': '#F0F0F0',
              'font-weight': '600',
            };
          }
          if (element.localName == 'a') {
            return {
              'color': '#0F7EDE',
              'text-decoration': 'underline',
            };
          }
          if (element.localName == 'h1') {
            return {
              'font-size': '24px',
              'font-weight': '600',
              'margin': '0 0 16px 0',
            };
          }
          if (element.localName == 'h2') {
            return {
              'font-size': '20px',
              'font-weight': '600',
              'margin': '0 0 12px 0',
            };
          }
          if (element.localName == 'h3') {
            return {
              'font-size': '18px',
              'font-weight': '600',
              'margin': '0 0 8px 0',
            };
          }
          return null;
        },
      ),
    );
  }
}