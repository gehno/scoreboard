import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Native window control (Windows only for now), implemented without a plugin.
abstract final class WindowControl {
  static const _channel = MethodChannel('scoreboard/window');

  static bool get isSupported => Platform.isWindows;

  static Future<int> monitorCount() =>
      _invoke<int>('monitorCount', fallback: 1);

  /// Borderless fullscreen on [monitor] (0-based), or on the current monitor.
  static Future<void> setFullScreen(bool value, {int? monitor}) =>
      _invoke<void>(
        'setFullScreen',
        arguments: {'value': value, 'monitor': monitor ?? -1},
      );

  static Future<bool> isFullScreen() =>
      _invoke<bool>('isFullScreen', fallback: false);

  /// Sets the native window title.
  static Future<void> setTitle(String title) =>
      _invoke<void>('setTitle', arguments: {'title': title});

  /// Native open or save dialog; null if cancelled or unsupported. [pattern]
  /// is a semicolon separated filter such as `*.png;*.jpg`.
  static Future<String?> chooseFile({
    required bool save,
    required String filterName,
    required String pattern,
    String defaultName = '',
  }) => _invoke<String?>(
    'chooseFile',
    arguments: {
      'save': save,
      'filterName': filterName,
      'pattern': pattern,
      'defaultName': defaultName,
    },
  );

  /// Files dropped on the window, with the drop position in physical pixels.
  static Stream<DroppedFiles> get droppedFiles {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'filesDropped') return;
      final arguments = call.arguments as Map;
      _drops.add(
        DroppedFiles(
          (arguments['files'] as List).cast<String>(),
          Offset(
            (arguments['x'] as int).toDouble(),
            (arguments['y'] as int).toDouble(),
          ),
        ),
      );
    });
    return _drops.stream;
  }

  static final _drops = StreamController<DroppedFiles>.broadcast();

  static Future<T> _invoke<T>(
    String method, {
    Object? arguments,
    T? fallback,
  }) async {
    if (!isSupported) return fallback as T;
    try {
      return await _channel.invokeMethod<T>(method, arguments) ?? fallback as T;
    } on PlatformException {
      return fallback as T;
    }
  }
}

class DroppedFiles {
  const DroppedFiles(this.paths, this.position);

  final List<String> paths;
  final Offset position;
}
