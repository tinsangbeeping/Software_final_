import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/localization/app_localizations.dart';

class LanguagePickerPage extends StatelessWidget {
  const LanguagePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocalizationProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.languageSetting),
        backgroundColor: const Color(0xFF00BFA6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.languageSubtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 24),
            _LanguageOption(
              flag: '🇺🇸',
              languageName: loc.english,
              nativeName: 'English',
              isSelected: locProvider.isEnglish,
              onTap: () {
                locProvider.setLanguage('en');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.languageChanged),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF00BFA6),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _LanguageOption(
              flag: '🇹🇼',
              languageName: loc.traditionalChinese,
              nativeName: '繁體中文',
              isSelected: locProvider.isChinese,
              onTap: () {
                locProvider.setLanguage('zh');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.languageChangedZh),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF00BFA6),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String languageName;
  final String nativeName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.languageName,
    required this.nativeName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F7FA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BFA6) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF00BFA6).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(languageName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(nativeName, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00BFA6), size: 28),
          ],
        ),
      ),
    );
  }
}
