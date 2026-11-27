import 'dart:async';
import 'dart:io';

import 'package:scoreboard_core/scoreboard_core.dart';

/// Loopback WebSocket server that pushes the latest [DisplayMessage] to every
/// connected display window. Fully local, no external network.
class DisplayServer {
  DisplayServer._(this._server);

  final HttpServer _server;
  final _clients = <WebSocket>[];
  String? _latest;

  int get port => _server.port;

  static Future<DisplayServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final displayServer = DisplayServer._(server);
    unawaited(server.forEach(displayServer._handleRequest));
    return displayServer;
  }

  void show(DisplayMessage message) {
    _latest = message.encode();
    for (final client in List.of(_clients)) {
      client.add(_latest!);
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final client = await WebSocketTransformer.upgrade(request);
    _clients.add(client);
    unawaited(client.done.then((_) => _clients.remove(client)));
    if (_latest != null) client.add(_latest!);
  }

  Future<void> close() async {
    for (final client in List.of(_clients)) {
      await client.close();
    }
    await _server.close(force: true);
  }
}

/// Display side: yields the operator's updates. The stream ends once the
/// operator is gone, so the display can close with it.
Stream<DisplayMessage> connectToOperator(int port) async* {
  const maxAttempts = 5;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      await for (final raw in socket) {
        yield DisplayMessage.decode(raw as String);
      }
      return;
    } on SocketException {
      // Operator not reachable yet; retry below.
    } on WebSocketException {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
