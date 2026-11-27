import 'layout.dart';
import 'presets.dart';
import 'theme.dart';

LayoutElement _t(
  String id,
  double x,
  double y,
  double w,
  double h,
  String text, {
  double size = 64,
  int color = 0xFFFFFFFF,
  int bg = 0,
  bool bold = true,
  String align = 'center',
  String? visibleWhen,
}) => LayoutElement(
  id: id,
  type: ElementType.text,
  x: x,
  y: y,
  width: w,
  height: h,
  text: text,
  fontSize: size,
  color: color,
  background: bg,
  bold: bold,
  align: align,
  visibleWhen: visibleWhen,
);

ScoreboardLayout defaultFootballLayout() => ScoreboardLayout(
  name: 'Football Classic',
  sportId: 'football',
  background: ScoreboardTheme.classic.background,
  elements: [
    _t('clock', 660, 60, 600, 220, '{{clock}}', size: 200, color: 0xFFFFD400),
    _t('period', 760, 290, 400, 80, '{{period.label}}', size: 56, bold: false),
    _t('home_name', 60, 420, 800, 120, '{{home.name}}', size: 90),
    _t('away_name', 1060, 420, 800, 120, '{{away.name}}', size: 90),
    _t(
      'home_score',
      60,
      550,
      800,
      400,
      '{{home.score}}',
      size: 340,
      bg: 0x33FFFFFF,
    ),
    _t(
      'away_score',
      1060,
      550,
      800,
      400,
      '{{away.score}}',
      size: 340,
      bg: 0x33FFFFFF,
    ),
  ],
);

/// Set-based layout: one row per team with sets, optional games, and points.
ScoreboardLayout _setLayout(
  String name,
  String sportId,
  int background, {
  required bool games,
  required String points,
}) {
  final cols = <(String, String)>[
    ('Sets', 'sets'),
    if (games) ('Games', 'games'),
    ('Pts', points),
  ];
  final colW = 240.0;
  final left = 1860 - colW * cols.length;
  final elements = <LayoutElement>[
    _t(
      'title',
      60,
      40,
      1800,
      120,
      '{{period.label}}',
      size: 80,
      bold: false,
      color: 0xFFFFD400,
    ),
  ];
  for (var i = 0; i < cols.length; i++) {
    elements.add(
      _t(
        'hdr$i',
        left + colW * i,
        190,
        colW,
        70,
        cols[i].$1,
        size: 44,
        bold: false,
        color: 0xFFB0B8C0,
      ),
    );
  }
  for (final (row, side) in [(0, 'home'), (1, 'away')]) {
    final y = 280.0 + row * 340;
    elements.add(
      _t(
        '${side}_name',
        60,
        y,
        left - 80,
        300,
        '{{$side.name}}',
        size: 120,
        align: 'left',
        bg: 0x22FFFFFF,
      ),
    );
    for (var i = 0; i < cols.length; i++) {
      final last = i == cols.length - 1;
      elements.add(
        _t(
          '${side}_c$i',
          left + colW * i,
          y,
          colW - 10,
          300,
          '{{$side.${cols[i].$2}}}',
          size: 200,
          color: last ? 0xFFFFD400 : 0xFFFFFFFF,
          bg: 0x33FFFFFF,
        ),
      );
    }
  }
  return ScoreboardLayout(
    name: name,
    sportId: sportId,
    background: background,
    elements: elements,
  );
}

ScoreboardLayout defaultVolleyballLayout() => _setLayout(
  'Volleyball Classic',
  'volleyball',
  ScoreboardTheme.classic.background,
  games: false,
  points: 'score',
);

ScoreboardLayout defaultTableTennisLayout() => _setLayout(
  'Table Tennis Classic',
  'tabletennis',
  ScoreboardTheme.classic.background,
  games: false,
  points: 'score',
);

ScoreboardLayout defaultTennisLayout() => _setLayout(
  'Tennis Classic',
  'tennis',
  ScoreboardTheme.classic.background,
  games: true,
  points: 'points',
);

ScoreboardLayout _retarget(
  ScoreboardLayout base,
  String name,
  String sportId,
  int background,
) => ScoreboardLayout(
  name: name,
  sportId: sportId,
  background: background,
  elements: base.elements,
);

ScoreboardLayout defaultBasketballLayout() => _retarget(
  defaultFootballLayout(),
  'Basketball Classic',
  'basketball',
  ScoreboardTheme.classic.background,
);

ScoreboardLayout defaultLayoutFor(String sportId) =>
    _withTeamLogos(_baseLayoutFor(sportId));

/// Adds an image element per team, bound to the optional team logo.
ScoreboardLayout _withTeamLogos(ScoreboardLayout layout) {
  LayoutElement logo(String side, double x) => LayoutElement(
    id: '${side}_logo',
    type: ElementType.image,
    x: x,
    y: 60,
    width: 300,
    height: 300,
    imagePath: '{{$side.logo}}',
  );
  return layout.copyWith(
    elements: [...layout.elements, logo('home', 60), logo('away', 1560)],
  );
}

ScoreboardLayout _baseLayoutFor(String sportId) => switch (sportId) {
  'football' => defaultFootballLayout(),
  'basketball' => defaultBasketballLayout(),
  'icehockey' => _retarget(
    defaultHandballLayout(),
    'Ice Hockey Classic',
    'icehockey',
    ScoreboardTheme.classic.background,
  ),
  'volleyball' => defaultVolleyballLayout(),
  'tabletennis' => defaultTableTennisLayout(),
  'tennis' => defaultTennisLayout(),
  _ => defaultHandballLayout(),
};
