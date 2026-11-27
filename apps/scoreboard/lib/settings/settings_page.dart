import 'package:material_ui/material_ui.dart';

import '../match/match_session.dart';
import '../storage/backup_service.dart';
import 'image_source.dart';
import 'language_page.dart';
import 'match_rules_page.dart';
import 'settings_scope.dart';
import 'shortcuts_page.dart';
import 'team_names_page.dart';
import 'theme_page.dart';

/// Settings hub with one page per topic.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.session,
    required this.images,
    this.backup,
  });

  final MatchSession session;
  final ImageSource images;
  final BackupService? backup;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.settings)),
    body: ListView(
      children: [
        _tile(
          context,
          Icons.groups,
          context.l10n.teamNames,
          TeamNamesPage(session: session, images: images),
        ),
        _tile(
          context,
          Icons.rule,
          context.l10n.matchRules,
          MatchRulesPage(session: session),
        ),
        _tile(context, Icons.palette, context.l10n.theme, const ThemePage()),
        _tile(
          context,
          Icons.language,
          context.l10n.language,
          const LanguagePage(),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.preview),
          title: Text(context.l10n.showPreviewInOperatorView),
          value: context.settings.showPreview,
          onChanged: context.readSettings.setShowPreview,
        ),
        _tile(
          context,
          Icons.keyboard,
          context.l10n.keyboardShortcuts,
          const ShortcutsPage(),
        ),
        if (backup case final backup? when backup.isAvailable) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.archive),
            title: Text(context.l10n.exportAllDataAsZip),
            onTap: () => _export(context, backup),
          ),
          ListTile(
            leading: const Icon(Icons.unarchive),
            title: Text(context.l10n.importDataFromZip),
            onTap: () => _import(context, backup),
          ),
        ],
      ],
    ),
  );

  Future<void> _export(BuildContext context, BackupService backup) async {
    final path = await backup.export();
    if (path != null && context.mounted) {
      _say(context, context.l10n.exportedToPath(path));
    }
  }

  Future<void> _import(BuildContext context, BackupService backup) async {
    int? count;
    try {
      count = await backup.import();
    } on FormatException {
      if (context.mounted) {
        _say(context, context.l10n.thisIsNotAValidBackupFile);
      }
      return;
    }
    if (count != null && context.mounted) {
      _say(
        context,
        context.l10n.importedCountFilesRestartTheAppToApplyThem(count),
      );
    }
  }

  void _say(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page)),
  );
}

/// Common frame of every settings topic page.
class SettingsSubpage extends StatelessWidget {
  const SettingsSubpage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: ListView(padding: const EdgeInsets.all(16), children: children),
  );
}
