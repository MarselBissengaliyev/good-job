// lib/widgets/html_content_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Добавьте зависимость в pubspec.yaml

class HtmlContentWidget extends StatefulWidget {
  final String htmlContent;

  const HtmlContentWidget({Key? key, required this.htmlContent}) : super(key: key);

  @override
  _HtmlContentWidgetState createState() => _HtmlContentWidgetState();
}

class _HtmlContentWidgetState extends State<HtmlContentWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFAFAFA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Открываем ссылки во внешнем браузере
            if (request.url.startsWith('http')) {
              // Здесь можно добавить открытие ссылок в браузере
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_getFullHtml());
  }

  String _getFullHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            body {
                font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
                margin: 0;
                padding: 0;
                color: #41454A;
                background-color: #FAFAFA;
                line-height: 1.5;
            }
            img {
                max-width: 100%;
                height: auto;
                border-radius: 12px;
            }
            h1 { font-size: 24px; font-weight: 600; }
            h2 { font-size: 20px; font-weight: 600; }
            h3 { font-size: 18px; font-weight: 600; }
            a { color: #41454A; text-decoration: underline; }
            table {
                width: 100%;
                border-collapse: collapse;
                margin: 16px 0;
            }
            td, th {
                padding: 12px;
                border: 1px solid #E0E0E0;
                text-align: left;
            }
            th {
                background-color: #F0F0F0;
                font-weight: 600;
            }
        </style>
    </head>
    <body>
        ${widget.htmlContent}
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // Настройте высоту по необходимости
      child: WebViewWidget(controller: _controller),
    );
  }
}