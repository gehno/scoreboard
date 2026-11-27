import 'package:material_ui/material_ui.dart';

/// Local file paths are not available in the browser demo.
class LocalImage extends StatelessWidget {
  const LocalImage(this.path, {super.key});

  final String path;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
