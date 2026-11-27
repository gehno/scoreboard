import 'package:scoreboard_core/scoreboard_core.dart';

/// Where the operator sends the scoreboard to; hides how a display is
/// reached (separate window, external screen, ...).
abstract interface class DisplayOutput {
  bool get isAvailable;

  Future<int> monitorCount();

  /// Opens the display, fullscreen on [monitor] (0-based) when given.
  Future<void> open({int? monitor});

  void show(DisplayMessage message);

  Future<void> dispose();
}

/// Used where no display output exists (tests, non-Windows platforms).
class NoDisplayOutput implements DisplayOutput {
  const NoDisplayOutput();

  @override
  bool get isAvailable => false;

  @override
  Future<int> monitorCount() async => 0;

  @override
  Future<void> open({int? monitor}) async {}

  @override
  void show(DisplayMessage message) {}

  @override
  Future<void> dispose() async {}
}
