import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/settings_scope.dart';

/// Version and author, read from the bundled pubspec.yaml so they are
/// maintained in one place only.
class AppInfo {
  const AppInfo({required this.version, required this.author});

  factory AppInfo.parse(String pubspec) {
    String field(String name) =>
        RegExp('^$name:[ \\t]*(.+?)[ \\t]*\$', multiLine: true)
            .firstMatch(pubspec)
            ?.group(1)
            ?.replaceAll(RegExp('^["\']|["\']\$'), '') ??
        '';
    return AppInfo(
      version: field('version').split('+').first,
      author: field('app_author'),
    );
  }

  static Future<AppInfo> load() async =>
      AppInfo.parse(await rootBundle.loadString('pubspec.yaml'));

  final String version;
  final String author;
}

/// Shows version and author; its button lists all package licenses.
Future<void> showAbout(BuildContext context) async {
  final info = await AppInfo.load();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AboutDialog(
      applicationName: context.l10n.scoreboard,
      applicationIcon: Image.asset('assets/icon/app_icon.png', width: 64),
      applicationVersion: '${context.l10n.version} ${info.version}',
      applicationLegalese:
          '${context.l10n.author}: ${info.author}\n'
          '${context.l10n.releasedUnderTheGnuAgplv3}',
      children: [
        const SizedBox(height: 12),
        Text(context.l10n.builtWithAiAgenticCoding),
      ],
    ),
  );
}
