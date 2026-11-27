import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'app_settings.dart';

/// Makes [AppSettings] available to the widget tree.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);
}

extension SettingsContext on BuildContext {
  /// Settings; the widget rebuilds when they change.
  AppSettings get settings =>
      dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Settings without subscribing, for use in event handlers.
  AppSettings get readSettings =>
      getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
