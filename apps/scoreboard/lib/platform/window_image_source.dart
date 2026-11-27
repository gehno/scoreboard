import 'dart:async';
import 'dart:ui';

import '../settings/image_source.dart';
import 'window_control.dart';

/// [ImageSource] backed by a native desktop runner.
class WindowImageSource implements ImageSource {
  @override
  bool get canPick => true;

  @override
  Future<String?> pick() => WindowControl.chooseFile(
    save: false,
    filterName: 'Images',
    pattern: supportedImageExtensions.map((e) => '*.$e').join(';'),
  );

  @override
  Stream<DroppedImage> get drops => WindowControl.droppedFiles.expand((drop) {
    final scale = PlatformDispatcher.instance.views.first.devicePixelRatio;
    return [
      for (final path in drop.paths) DroppedImage(path, drop.position / scale),
    ];
  });
}

ImageSource createImageSource() =>
    WindowControl.isSupported ? WindowImageSource() : const NoImageSource();
