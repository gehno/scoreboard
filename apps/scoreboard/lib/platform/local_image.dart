import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Shows an image file from disk (raster formats and SVG); renders nothing if
/// it cannot be read.
class LocalImage extends StatelessWidget {
  const LocalImage(this.path, {super.key});

  final String path;

  bool get _isSvg => path.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) => _isSvg
      ? SvgPicture.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        )
      : Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
}
