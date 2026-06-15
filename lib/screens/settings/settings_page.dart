import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/settings/preference_tile.dart';
import '../../widgets/settings/section_card.dart';
import '../../widgets/settings/debug_section.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/localization_provider.dart';
import 'language_picker_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.settings,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              SectionCard(
                child: Column(
                  children: [
                    PreferenceTile(
                      icon: Icons.person,
                      title: loc.profile,
                      onTap: () => _showComingSoon(context, loc.profile),
                    ),

                    const Divider(),

                    Consumer<LocalizationProvider>(
                      builder: (context, localeProvider, _) {
                        return PreferenceTile(
                          icon: Icons.language,
                          title: loc.languageSetting,
                          subtitle: localeProvider.isEnglish ? 'English' : '繁體中文',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LanguagePickerPage()),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const DebugSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${loc.comingSoon}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00BFA6),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
