import 'layout.dart';
import 'theme.dart';

/// Built-in handball layout on a 1920x1080 canvas.
ScoreboardLayout defaultHandballLayout() {
  LayoutElement t(
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
    visibleWhen: visibleWhen,
  );

  return ScoreboardLayout(
    name: 'Handball Classic',
    sportId: 'handball',
    background: ScoreboardTheme.classic.background,
    elements: [
      t('clock', 660, 60, 600, 220, '{{clock}}', size: 200, color: 0xFFFFD400),
      t('period', 760, 290, 400, 80, '{{period.label}}', size: 56, bold: false),
      t('home_name', 60, 420, 800, 120, '{{home.name}}', size: 90),
      t('away_name', 1060, 420, 800, 120, '{{away.name}}', size: 90),
      t(
        'home_score',
        60,
        550,
        800,
        340,
        '{{home.score}}',
        size: 300,
        bg: 0x33FFFFFF,
      ),
      t(
        'away_score',
        1060,
        550,
        800,
        340,
        '{{away.score}}',
        size: 300,
        bg: 0x33FFFFFF,
      ),
      for (final side in ['home', 'away'])
        for (var i = 0; i < 4; i++)
          t(
            '${side}_susp$i',
            (side == 'home' ? 60 : 1060) + (i % 2) * 420,
            905 + (i ~/ 2) * 85,
            380,
            80,
            '{{$side.suspension.$i.player}} {{$side.suspension.$i}}',
            size: 40,
            color: 0xFFFF6B6B,
            visibleWhen: '$side.suspension.$i',
          ),
      t(
        'timeout',
        460,
        130,
        1000,
        160,
        'TIMEOUT {{timeout.clock}}',
        size: 110,
        color: 0xFF000000,
        bg: 0xFFFFD400,
        visibleWhen: 'timeout.active',
      ),
    ],
  );
}
