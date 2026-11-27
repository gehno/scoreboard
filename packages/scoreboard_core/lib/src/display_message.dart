import 'dart:convert';

import 'layout.dart';

/// What the operator sends to a display: the layout and the live bindings.
class DisplayMessage {
  const DisplayMessage(this.layout, this.values);

  factory DisplayMessage.decode(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return DisplayMessage(
      ScoreboardLayout.decode(json['layout']! as String),
      (json['values']! as Map).cast<String, Object>(),
    );
  }

  final ScoreboardLayout layout;
  final Map<String, Object> values;

  String encode() => jsonEncode({'layout': layout.encode(), 'values': values});
}
