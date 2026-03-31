import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final bool showAsButton;
  
  const LanguageSelector({super.key, this.showAsButton = false});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    if (showAsButton) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageButton(
              context: context,
              code: 'RU',
              locale: const Locale('ru'),
              isActive: languageProvider.locale.languageCode == 'ru',
            ),
            _buildLanguageButton(
              context: context,
              code: 'KZ',
              locale: const Locale('kk'),
              isActive: languageProvider.locale.languageCode == 'kk',
            ),
          ],
        ),
      );
    }
    
    return PopupMenuButton<Locale>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.language, color: Colors.white),
      ),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (Locale locale) {
        languageProvider.setLanguage(locale);
        _showLanguageChangedSnackBar(context, appLocalizations, locale);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: const Locale('ru'),
          child: Row(
            children: [
              const Icon(Icons.check, color: Colors.transparent),
              const SizedBox(width: 8),
              Text(
                appLocalizations.translate('russian'),
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              if (languageProvider.locale.languageCode == 'ru')
                const Icon(Icons.check, color: Colors.blue, size: 20),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('kk'),
          child: Row(
            children: [
              const Icon(Icons.check, color: Colors.transparent),
              const SizedBox(width: 8),
              Text(
                appLocalizations.translate('kazakh'),
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              if (languageProvider.locale.languageCode == 'kk')
                const Icon(Icons.check, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required String code,
    required Locale locale,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        languageProvider.setLanguage(locale);
        final appLocalizations = AppLocalizations.of(context)!;
        _showLanguageChangedSnackBar(context, appLocalizations, locale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showLanguageChangedSnackBar(BuildContext context, AppLocalizations appLocalizations, Locale locale) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale.languageCode == 'ru' 
              ? 'Язык изменен на русский' 
              : 'Тіл қазақшаға өзгертілді',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}