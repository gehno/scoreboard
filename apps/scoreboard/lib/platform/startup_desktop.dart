import 'package:material_ui/material_ui.dart';

import '../app/operator_app.dart';
import '../display/display_app.dart';
import '../settings/app_settings.dart';
import '../storage/backup_service.dart';
import '../storage/layout_repository.dart';
import 'desktop_display_output.dart';
import 'file_storage.dart';
import 'window_backup_files.dart';
import 'window_control.dart';
import 'window_image_source.dart';

Future<void> start(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final displayArguments = DisplayLaunchArguments.tryParse(args);
  if (displayArguments != null) {
    runApp(
      DisplayApp(
        port: displayArguments.port,
        monitor: displayArguments.monitor,
      ),
    );
    return;
  }

  final storage = await FileStorage.open();
  runApp(
    OperatorApp(
      settings: await AppSettings.load(storage),
      layouts: LayoutRepository(storage),
      output: await createDisplayOutput(),
      images: createImageSource(),
      onTitleChanged: WindowControl.setTitle,
      backup: BackupService(storage, createBackupFiles()),
    ),
  );
}
