import 'package:material_ui/material_ui.dart';

import '../display/display_output.dart';
import '../l10n/app_localizations.dart';
import '../operator/operator_page.dart';
import '../settings/image_source.dart';
import '../settings/app_settings.dart';
import '../settings/settings_scope.dart';
import '../storage/backup_service.dart';
import '../storage/layout_repository.dart';
import 'operator_theme.dart';

/// The operator window. Takes ownership of [output] and closes it on dispose.
class OperatorApp extends StatefulWidget {
  const OperatorApp({
    super.key,
    required this.settings,
    required this.layouts,
    required this.output,
    this.images = const NoImageSource(),
    this.backup,
    this.onTitleChanged,
  });

  final AppSettings settings;
  final LayoutRepository layouts;
  final DisplayOutput output;
  final ImageSource images;
  final BackupService? backup;

  /// Called with the localized app title, e.g. to set the native window title.
  final ValueChanged<String>? onTitleChanged;

  @override
  State<OperatorApp> createState() => _OperatorAppState();
}

class _OperatorAppState extends State<OperatorApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_syncTitle);
    _syncTitle();
  }

  void _syncTitle() => widget.onTitleChanged?.call(
    lookupAppLocalizations(Locale(widget.settings.language.name)).scoreboard,
  );

  @override
  void dispose() {
    widget.settings.removeListener(_syncTitle);
    widget.output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsScope(
    settings: widget.settings,
    child: ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => MaterialApp(
        locale: Locale(widget.settings.language.name),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          // material_ui uses its own Material and Cupertino localization types.
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (context) => context.l10n.scoreboard,
        debugShowCheckedModeBanner: false,
        theme: operatorTheme(widget.settings.theme),
        home: OperatorPage(
          settings: widget.settings,
          layouts: widget.layouts,
          output: widget.output,
          images: widget.images,
          backup: widget.backup,
        ),
      ),
    ),
  );
}
