import 'dart:convert';

const layoutSchemaVersion = 1;

enum ElementType { text, rect, image }

/// A positioned element in a virtual canvas (e.g. 1920x1080).
class LayoutElement {
  const LayoutElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.text = '',
    this.fontSize = 48,
    this.fontFamily,
    this.bold = false,
    this.align = 'center',
    this.color = 0xFFFFFFFF,
    this.background = 0x00000000,
    this.cornerRadius = 0,
    this.imagePath,
    this.visibleWhen,
  });

  final String id;
  final ElementType type;
  final double x, y, width, height;

  /// May contain `{{binding}}` placeholders.
  final String text;
  final double fontSize;
  final String? fontFamily;
  final bool bold;
  final String align; // left | center | right
  final int color;
  final int background;
  final double cornerRadius;
  final String? imagePath;

  /// Binding key (optionally prefixed with `!`); element hidden when falsy.
  final String? visibleWhen;

  LayoutElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    double? fontSize,
    String? fontFamily,
    bool? bold,
    String? align,
    int? color,
    int? background,
    double? cornerRadius,
    String? imagePath,
    String? visibleWhen,
  }) => LayoutElement(
    id: id,
    type: type,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    text: text ?? this.text,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: fontFamily ?? this.fontFamily,
    bold: bold ?? this.bold,
    align: align ?? this.align,
    color: color ?? this.color,
    background: background ?? this.background,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    imagePath: imagePath ?? this.imagePath,
    visibleWhen: visibleWhen ?? this.visibleWhen,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'text': text,
    'fontSize': fontSize,
    if (fontFamily != null) 'fontFamily': fontFamily,
    'bold': bold,
    'align': align,
    'color': color,
    'background': background,
    'cornerRadius': cornerRadius,
    if (imagePath != null) 'imagePath': imagePath,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  factory LayoutElement.fromJson(Map<String, Object?> j) => LayoutElement(
    id: j['id'] as String,
    type: ElementType.values.byName(j['type'] as String),
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    width: (j['width'] as num).toDouble(),
    height: (j['height'] as num).toDouble(),
    text: (j['text'] as String?) ?? '',
    fontSize: ((j['fontSize'] as num?) ?? 48).toDouble(),
    fontFamily: j['fontFamily'] as String?,
    bold: (j['bold'] as bool?) ?? false,
    align: (j['align'] as String?) ?? 'center',
    color: (j['color'] as int?) ?? 0xFFFFFFFF,
    background: (j['background'] as int?) ?? 0,
    cornerRadius: ((j['cornerRadius'] as num?) ?? 0).toDouble(),
    imagePath: j['imagePath'] as String?,
    visibleWhen: j['visibleWhen'] as String?,
  );
}

class ScoreboardLayout {
  const ScoreboardLayout({
    required this.name,
    required this.sportId,
    this.width = 1920,
    this.height = 1080,
    this.background = 0xFF000000,
    this.elements = const [],
  });

  final String name;
  final String sportId;
  final double width, height;
  final int background;
  final List<LayoutElement> elements;

  ScoreboardLayout copyWith({
    String? name,
    int? background,
    List<LayoutElement>? elements,
  }) => ScoreboardLayout(
    name: name ?? this.name,
    sportId: sportId,
    width: width,
    height: height,
    background: background ?? this.background,
    elements: elements ?? this.elements,
  );

  Map<String, Object?> toJson() => {
    'version': layoutSchemaVersion,
    'name': name,
    'sportId': sportId,
    'width': width,
    'height': height,
    'background': background,
    'elements': [for (final e in elements) e.toJson()],
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory ScoreboardLayout.decode(String source) {
    final j = jsonDecode(source) as Map<String, Object?>;
    final version = (j['version'] as int?) ?? 1;
    if (version > layoutSchemaVersion) {
      throw FormatException('Unsupported layout version $version');
    }
    return ScoreboardLayout(
      name: j['name'] as String,
      sportId: j['sportId'] as String,
      width: (j['width'] as num).toDouble(),
      height: (j['height'] as num).toDouble(),
      background: (j['background'] as int?) ?? 0xFF000000,
      elements: [
        for (final e in (j['elements'] as List).cast<Map<String, Object?>>())
          LayoutElement.fromJson(e),
      ],
    );
  }
}

final _placeholder = RegExp(r'\{\{\s*([\w.]+)\s*\}\}');

/// Replaces `{{key}}` placeholders; unknown keys render as empty text.
String resolveBindings(String template, Map<String, Object> values) => template
    .replaceAllMapped(_placeholder, (m) => '${values[m.group(1)] ?? ''}');

bool isVisible(String? condition, Map<String, Object> values) {
  if (condition == null || condition.isEmpty) return true;
  final negate = condition.startsWith('!');
  final v = values[negate ? condition.substring(1) : condition];
  final truthy = v != null && v != false && v != 0 && v != '';
  return negate ? !truthy : truthy;
}
