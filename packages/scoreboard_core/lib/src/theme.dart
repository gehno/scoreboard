import 'layout.dart';

/// A sport-independent look (colors, corner style, font) applied on top of any
/// layout. Layouts keep defining *what* is shown and *where*; the theme
/// decides how it is colored.
class ScoreboardTheme {
  const ScoreboardTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.panel,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.warning,
    this.radiusScale = 1,
    this.fontFamily,
    this.dark = true,
    this.identity = false,
  });

  final String id;
  final String name;
  final int background, panel, text, muted, accent, onAccent, warning;
  final double radiusScale;
  final String? fontFamily;
  final bool dark;

  /// Leaves the layout untouched (keeps each sport's own colors).
  final bool identity;

  // Colors used by the built-in layouts, mapped to theme roles.
  static const _textRole = 0xFFFFFFFF;
  static const _accentRole = 0xFFFFD400;
  static const _mutedRole = 0xFFB0B8C0;
  static const _warningRole = 0xFFFF6B6B;
  static const _onAccentRole = 0xFF000000;
  static const _defaultRect = 0xFF334455;

  int _foreground(int c) => switch (c) {
    _textRole => text,
    _accentRole => accent,
    _mutedRole => muted,
    _warningRole => warning,
    _onAccentRole => onAccent,
    _ => c,
  };

  int _fill(int c) => switch (c) {
    0x33FFFFFF || 0x22FFFFFF || _defaultRect => panel,
    _accentRole => accent,
    _ => c,
  };

  ScoreboardLayout apply(ScoreboardLayout layout) {
    if (identity) return layout;
    return layout.copyWith(
      background: background,
      elements: [
        for (final e in layout.elements)
          e.copyWith(
            color: _foreground(e.color),
            background: _fill(e.background),
            cornerRadius: e.cornerRadius * radiusScale,
            fontFamily: e.fontFamily ?? fontFamily,
          ),
      ],
    );
  }

  static const classic = ScoreboardTheme(
    id: 'classic',
    name: 'Classic',
    background: 0xFF0B1B2B,
    panel: 0x33FFFFFF,
    text: 0xFFFFFFFF,
    muted: 0xFFB0B8C0,
    accent: 0xFFFFD400,
    onAccent: 0xFF000000,
    warning: 0xFFFF6B6B,
    identity: true,
  );

  static const midnight = ScoreboardTheme(
    id: 'midnight',
    name: 'Midnight',
    background: 0xFF05070D,
    panel: 0xFF141B2D,
    text: 0xFFE8EEFF,
    muted: 0xFF7F8BA8,
    accent: 0xFF4C8DFF,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFFF5C7A,
    radiusScale: 1.5,
  );

  static const daylight = ScoreboardTheme(
    id: 'daylight',
    name: 'Daylight',
    background: 0xFFF4F6FA,
    panel: 0xFFFFFFFF,
    text: 0xFF14213D,
    muted: 0xFF5C6B84,
    accent: 0xFFE63946,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFC1121F,
    dark: false,
    radiusScale: 1.2,
  );

  static const neon = ScoreboardTheme(
    id: 'neon',
    name: 'Neon',
    background: 0xFF0A0014,
    panel: 0xFF1F0A3D,
    text: 0xFF00F0FF,
    muted: 0xFFB36BFF,
    accent: 0xFFFF2BD6,
    onAccent: 0xFF0A0014,
    warning: 0xFFFFE600,
    radiusScale: 0.5,
  );

  static const terminal = ScoreboardTheme(
    id: 'terminal',
    name: 'Terminal',
    background: 0xFF000000,
    panel: 0xFF0B2410,
    text: 0xFF39FF6A,
    muted: 0xFF2BA84A,
    accent: 0xFFB6FF00,
    onAccent: 0xFF000000,
    warning: 0xFFFF9500,
    radiusScale: 0,
    fontFamily: 'Consolas',
  );

  static const highContrast = ScoreboardTheme(
    id: 'highcontrast',
    name: 'High contrast',
    background: 0xFF000000,
    panel: 0xFF222222,
    text: 0xFFFFFFFF,
    muted: 0xFFDDDDDD,
    accent: 0xFFFFFF00,
    onAccent: 0xFF000000,
    warning: 0xFFFF7070,
    radiusScale: 0,
  );

  static const forest = ScoreboardTheme(
    id: 'forest',
    name: 'Forest',
    background: 0xFF0D2818,
    panel: 0xFF1C4A2E,
    text: 0xFFF1F7EE,
    muted: 0xFFA7C4B0,
    accent: 0xFFF2C94C,
    onAccent: 0xFF0D2818,
    warning: 0xFFFF8A65,
    radiusScale: 1.3,
  );

  static const sunrise = ScoreboardTheme(
    id: 'sunrise',
    name: 'Sunrise',
    background: 0xFFFFF1E0,
    panel: 0xFFFFD9B0,
    text: 0xFF3B1F0F,
    muted: 0xFF8A5A3C,
    accent: 0xFFE8590C,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFB5179E,
    dark: false,
    radiusScale: 1.6,
  );

  static const mint = ScoreboardTheme(
    id: 'mint',
    name: 'Mint',
    background: 0xFFEAF7F0,
    panel: 0xFFC9ECD9,
    text: 0xFF0F3D2A,
    muted: 0xFF4F7A68,
    accent: 0xFF0B8457,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFC2410C,
    dark: false,
    radiusScale: 1.3,
  );

  static const sky = ScoreboardTheme(
    id: 'sky',
    name: 'Sky',
    background: 0xFFE6F1FD,
    panel: 0xFFBFDDF8,
    text: 0xFF0B2545,
    muted: 0xFF48709B,
    accent: 0xFF0B6BCB,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFD62828,
    dark: false,
    radiusScale: 1.4,
  );

  static const paper = ScoreboardTheme(
    id: 'paper',
    name: 'Paper',
    background: 0xFFFAF8F3,
    panel: 0xFFE9E4D8,
    text: 0xFF222222,
    muted: 0xFF6E6A60,
    accent: 0xFF1F6F5C,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFB3261E,
    dark: false,
    radiusScale: 0.8,
  );

  static const highContrastLight = ScoreboardTheme(
    id: 'highcontrastlight',
    name: 'High contrast light',
    background: 0xFFFFFFFF,
    panel: 0xFFE0E0E0,
    text: 0xFF000000,
    muted: 0xFF333333,
    accent: 0xFF0000CC,
    onAccent: 0xFFFFFFFF,
    warning: 0xFFCC0000,
    dark: false,
    radiusScale: 0,
  );

  /// Dark and light themes alternate so both groups stay equally represented.
  static const all = [
    classic,
    daylight,
    midnight,
    sunrise,
    neon,
    mint,
    forest,
    sky,
    terminal,
    paper,
    highContrast,
    highContrastLight,
  ];

  static ScoreboardTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classic);
}
