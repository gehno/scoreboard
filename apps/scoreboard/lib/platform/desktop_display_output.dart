import 'dart:io';

import 'package:scoreboard_core/scoreboard_core.dart';

import '../display/display_output.dart';
import 'display_connection.dart';
import 'window_control.dart';

/// Desktop display: a second instance of this app, started as a child
/// process, that receives the scoreboard over a loopback WebSocket.
class DesktopDisplayOutput implements DisplayOutput {
  DesktopDisplayOutput._(this._server);

  final DisplayServer _server;
  Process? _window;

  static Future<DesktopDisplayOutput> start() async =>
      DesktopDisplayOutput._(await DisplayServer.start());

  @override
  bool get isAvailable => true;

  @override
  Future<int> monitorCount() => WindowControl.monitorCount();

  @override
  Future<void> open({int? monitor}) async {
    _window?.kill();
    _window = await Process.start(Platform.resolvedExecutable, [
      '${DisplayLaunchArguments.portFlag}${_server.port}',
      if (monitor != null) '${DisplayLaunchArguments.monitorFlag}$monitor',
    ]);
  }

  @override
  void show(DisplayMessage message) => _server.show(message);

  @override
  Future<void> dispose() async {
    _window?.kill();
    await _server.close();
  }
}

/// Command-line contract between the operator and its display process.
class DisplayLaunchArguments {
  const DisplayLaunchArguments({required this.port, this.monitor});

  static const portFlag = '--display=';
  static const monitorFlag = '--monitor=';

  final int port;
  final int? monitor;

  /// Null when [args] do not describe a display process.
  static DisplayLaunchArguments? tryParse(List<String> args) {
    String? valueOf(String flag) => args
        .where((a) => a.startsWith(flag))
        .map((a) => a.substring(flag.length))
        .firstOrNull;

    final port = int.tryParse(valueOf(portFlag) ?? '');
    if (port == null) return null;
    return DisplayLaunchArguments(
      port: port,
      monitor: int.tryParse(valueOf(monitorFlag) ?? ''),
    );
  }
}

/// Windows and Linux get a real display; other platforms none.
Future<DisplayOutput> createDisplayOutput() async =>
    Platform.isWindows || Platform.isLinux
    ? DesktopDisplayOutput.start()
    : const NoDisplayOutput();
