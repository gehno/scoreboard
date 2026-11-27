import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import 'settings_page.dart';
import 'settings_scope.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    return SettingsSubpage(
      title: context.l10n.language,
      children: [
        RadioGroup<AppLanguage>(
          groupValue: settings.language,
          onChanged: (language) => settings.setLanguage(language!),
          child: Column(
            children: [
              for (final language in AppLanguage.values)
                RadioListTile<AppLanguage>(
                  value: language,
                  title: Text(language.displayName),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
