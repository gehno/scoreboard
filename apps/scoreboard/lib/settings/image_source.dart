import 'dart:async';
import 'dart:ui';

/// Where users can get image files from besides typing a path: a native file
/// chooser and files dropped onto the window.
abstract interface class ImageSource {
  bool get canPick;

  /// Opens the file chooser; null if cancelled.
  Future<String?> pick();

  /// Dropped image paths with the drop position in logical pixels.
  Stream<DroppedImage> get drops;
}

class DroppedImage {
  const DroppedImage(this.path, this.position);

  final String path;
  final Offset position;
}

/// Used where no chooser or drag and drop exists (tests, other platforms).
class NoImageSource implements ImageSource {
  const NoImageSource();

  @override
  bool get canPick => false;

  @override
  Future<String?> pick() async => null;

  @override
  Stream<DroppedImage> get drops => const Stream.empty();
}

const supportedImageExtensions = [
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
  'svg',
];

bool isSupportedImage(String path) {
  final dot = path.lastIndexOf('.');
  return dot >= 0 &&
      supportedImageExtensions.contains(path.substring(dot + 1).toLowerCase());
}
