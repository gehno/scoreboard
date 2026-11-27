import 'package:scoreboard_core/scoreboard_core.dart';
import 'package:test/test.dart';

void main() {
  late MatchController c;
  setUp(() => c = MatchController(MatchState.initial(handball)));

  test('score changes, clamps and undoes', () {
    c.changeScore(Side.home, 1);
    c.changeScore(Side.home, 1);
    c.changeScore(Side.away, -1);
    expect(c.state.home.score, 2);
    expect(c.state.away.score, 0);
    c.undo();
    expect(c.state.home.score, 1);
    c.redo();
    expect(c.state.home.score, 2);
  });

  test('clock runs only when started and stops at period end', () {
    c.tick(const Duration(seconds: 5));
    expect(c.state.clock, Duration.zero);
    c.startClock();
    c.tick(const Duration(minutes: 29, seconds: 59));
    c.tick(const Duration(seconds: 5));
    expect(c.state.clock, handball.periodDuration);
    expect(c.state.running, isFalse);
    expect(c.isPeriodOver, isTrue);
  });

  test('suspensions count down only while clock runs, no team limit', () {
    expect(c.addSuspension(Side.home), isTrue);
    c.tick(const Duration(seconds: 30));
    expect(c.state.home.suspensions.first, const Duration(minutes: 2));
    c.startClock();
    c.tick(const Duration(seconds: 30));
    expect(c.state.home.suspensions.first, const Duration(seconds: 90));
    expect(c.addSuspension(Side.home), isTrue);
    expect(c.addSuspension(Side.home), isTrue);
    expect(c.state.home.suspensions.length, 3);
    c.tick(const Duration(seconds: 90));
    expect(c.state.home.suspensions.length, 2);
  });

  test('suspension shows jersey number and ticks in sync with the clock', () {
    c.startClock();
    c.tick(const Duration(milliseconds: 10400));
    c.addSuspension(Side.home, player: '7');
    var b = c.state.toBindings();
    expect(b['home.suspension.0.player'], '#7');
    expect(b['home.suspension.0'], '02:00');
    expect(b['clock'], '00:10');
    c.tick(const Duration(milliseconds: 600)); // clock 11.0 s
    b = c.state.toBindings();
    expect(b['clock'], '00:11');
    expect(b['home.suspension.0'], '01:59');
    c.tick(const Duration(seconds: 120));
    expect(c.state.toBindings()['home.suspension.0.player'], '');
  });

  test('default layouts only use the classic palette, so every theme recolors them fully', () {
    final c0 = ScoreboardTheme.classic;
    final allowed = {c0.text, c0.accent, c0.muted, c0.warning, c0.onAccent};
    for (final sport in SportRegistry.all) {
      final l = defaultLayoutFor(sport.id);
      expect(l.background, c0.background, reason: sport.id);
      for (final e in l.elements) {
        expect(allowed, contains(e.color), reason: '${sport.id}/${e.id}');
      }
    }
  });

  test('dark and light themes are balanced', () {
    final dark = ScoreboardTheme.all.where((t) => t.dark).length;
    expect(dark, ScoreboardTheme.all.length - dark);
    expect(
      ScoreboardTheme.all.map((t) => t.id).toSet().length,
      ScoreboardTheme.all.length,
    );
  });

  test('timeouts stop clock, limited per match', () {
    c.startClock();
    expect(c.callTimeout(Side.away), isTrue);
    expect(c.state.running, isFalse);
    c.tick(const Duration(seconds: 61));
    expect(c.state.timeoutRemaining, isNull);
    c.callTimeout(Side.away);
    c.callTimeout(Side.away);
    expect(c.callTimeout(Side.away), isFalse);
  });

  test('aborting a timeout refunds it and blocks overlapping timeouts', () {
    expect(c.callTimeout(Side.home), isTrue);
    expect(c.state.timeoutSide, Side.home);
    expect(c.callTimeout(Side.away), isFalse);
    c.cancelTimeout();
    expect(c.state.timeoutRemaining, isNull);
    expect(c.state.home.timeoutsUsed, 0);
    c.cancelTimeout();
    expect(c.state.home.timeoutsUsed, 0);
  });

  test('next period resets clock; countdown sports start at full time', () {
    c.setClock(const Duration(minutes: 30));
    expect(c.nextPeriod(), isTrue);
    expect(c.state.clock, Duration.zero);
    expect(c.nextPeriod(), isFalse);
    final b = MatchController(MatchState.initial(basketball));
    expect(b.state.clock, basketball.periodDuration);
  });

  test('set-based sports: sets, tennis point labels, reset on next set', () {
    final t = MatchController(MatchState.initial(tennis));
    for (var i = 0; i < 6; i++) {
      t.changeScore(Side.home, 1);
    }
    expect(t.state.toBindings()['home.points'], 'AD');
    t.changeGames(Side.home, 3);
    t.changeSets(Side.away, 1);
    t.startClock();
    expect(t.state.running, isFalse);
    expect(t.nextPeriod(), isTrue);
    expect(t.state.home.score, 0);
    expect(t.state.home.games, 0);
    expect(t.state.away.sets, 1);
  });

  test('every registered sport has a layout with matching sportId', () {
    for (final s in SportRegistry.all) {
      final l = defaultLayoutFor(s.id);
      expect(l.sportId, s.id);
      expect(l.elements, isNotEmpty);
      final keys = MatchState.initial(s).toBindings().keys.toSet();
      for (final e in l.elements) {
        for (final m in RegExp(r'\{\{\s*([\w.]+)\s*\}\}').allMatches(e.text)) {
          expect(keys, contains(m.group(1)), reason: '${s.id}/${e.id}');
        }
      }
    }
  });

  test('layout JSON round trip and bindings', () {
    final layout = defaultHandballLayout();
    final decoded = ScoreboardLayout.decode(layout.encode());
    expect(decoded.elements.length, layout.elements.length);
    c.changeScore(Side.home, 7);
    final values = c.state.toBindings();
    expect(
      resolveBindings('{{home.score}}:{{away.score}} {{nope}}', values),
      '7:0 ',
    );
    expect(isVisible('timeout.active', values), isFalse);
    expect(isVisible('!timeout.active', values), isTrue);
  });

  test('themes recolor any layout without touching geometry', () {
    for (final sport in SportRegistry.all) {
      final base = defaultLayoutFor(sport.id);
      for (final th in ScoreboardTheme.all) {
        final themed = th.apply(base);
        expect(themed.elements.length, base.elements.length);
        expect(themed.elements.first.x, base.elements.first.x);
        if (!th.identity) expect(themed.background, th.background);
      }
    }
    final l = ScoreboardTheme.daylight.apply(defaultHandballLayout());
    expect(
      l.elements.any((e) => e.color == ScoreboardTheme.daylight.accent),
      isTrue,
    );
    expect(ScoreboardTheme.byId('nope'), same(ScoreboardTheme.classic));
  });
  test('sport copyWith overrides periods and length', () {
    final youth = handball.copyWith(
      periods: 3,
      periodDuration: const Duration(minutes: 20),
    );
    expect(youth.periods, 3);
    expect(youth.periodDuration.inMinutes, 20);
    expect(youth.periodLabel(3), 'Period 3');
    expect(handball.copyWith().periodLabel(1), '1st half');
    expect(volleyball.copyWith(periods: 3).periodLabel(2), 'Set 2');
    expect(MatchState.initial(youth.copyWith()).sport.periods, 3);
    final r = handball.copyWith(timeoutsPerMatch: 1, countUp: false);
    expect(r.timeoutsPerMatch, 1);
    expect(MatchState.initial(r).clock, r.periodDuration);
  });
}
