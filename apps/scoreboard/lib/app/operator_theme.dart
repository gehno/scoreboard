import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

/// Styles the operator UI after the selected scoreboard theme.
ThemeData operatorTheme(ScoreboardTheme theme) {
  if (theme.identity) {
    return ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    );
  }
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12 * theme.radiusScale),
  );
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Color(theme.accent),
    brightness: theme.dark ? Brightness.dark : Brightness.light,
    surface: Color(theme.background),
    onSurface: Color(theme.text),
  ).copyWith(primary: Color(theme.accent), onPrimary: Color(theme.onAccent));

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Color(theme.background),
    fontFamily: theme.fontFamily,
    cardTheme: CardThemeData(color: Color(theme.panel), shape: shape),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(theme.panel),
      foregroundColor: Color(theme.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: shape),
    ),
  );
}
