import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../l10n/localized_values.dart';
import 'settings_page.dart';
import 'settings_scope.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    return SettingsSubpage(
      title: context.l10n.theme,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final theme in ScoreboardTheme.all)
              _ThemeChip(
                theme: theme,
                isSelected: theme.id == settings.theme.id,
                onTap: () => settings.setTheme(theme.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final ScoreboardTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(theme.background),
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final color in [theme.panel, theme.accent, theme.warning])
                  _Swatch(color: Color(color), radiusScale: theme.radiusScale),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              localizedThemeName(context.l10n, theme),
              style: TextStyle(
                color: Color(theme.text),
                fontFamily: theme.fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.radiusScale});

  final Color color;
  final double radiusScale;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Colors.white24),
      borderRadius: BorderRadius.circular(4 * radiusScale.clamp(0, 2)),
    ),
  );
}
