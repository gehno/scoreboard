import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../platform/display_connection.dart';
import '../platform/window_control.dart';
import '../scoreboard/scoreboard_view.dart';

/// The scoreboard output, running in its own window. Goes fullscreen on the
/// chosen monitor; F11 or a double-click toggles, Esc leaves fullscreen. Exits
/// when the operator window is closed.
class DisplayApp extends StatefulWidget {
  const DisplayApp({super.key, required this.port, this.monitor});

  final int port;
  final int? monitor;

  @override
  State<DisplayApp> createState() => _DisplayAppState();
}

class _DisplayAppState extends State<DisplayApp> {
  late final Stream<DisplayMessage> _messages = connectToOperator(widget.port)
      .transform(
        StreamTransformer.fromHandlers(
          handleDone: (sink) {
            sink.close();
            exit(0);
          },
        ),
      );

  @override
  void initState() {
    super.initState();
    final monitor = widget.monitor;
    if (monitor != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => WindowControl.setFullScreen(true, monitor: monitor),
      );
    }
  }

  Future<void> _toggleFullScreen() async =>
      WindowControl.setFullScreen(!await WindowControl.isFullScreen());

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              WindowControl.setFullScreen(false),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _toggleFullScreen,
            child: StreamBuilder<DisplayMessage>(
              stream: _messages,
              builder: (context, snapshot) {
                final message = snapshot.data;
                if (message == null) return const SizedBox.expand();
                return ScoreboardView(
                  layout: message.layout,
                  values: message.values,
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
