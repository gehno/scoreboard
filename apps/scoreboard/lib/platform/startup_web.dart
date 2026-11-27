import 'package:material_ui/material_ui.dart';

import '../app/operator_app.dart';
import '../display/display_output.dart';
import '../settings/app_settings.dart';
import '../storage/app_storage.dart';
import '../storage/layout_repository.dart';

Future<void> start(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = MemoryStorage();
  runApp(
    OperatorApp(
      settings: await AppSettings.load(storage),
      layouts: LayoutRepository(storage),
      output: const NoDisplayOutput(),
    ),
  );
}
