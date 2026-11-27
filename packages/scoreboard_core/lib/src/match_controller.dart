import 'dart:async';

import 'match_state.dart';

/// Applies operator actions to [MatchState]; keeps undo/redo history.
/// Time is advanced explicitly via [tick] so it is deterministic and testable;
/// a UI layer feeds it deltas from a monotonic stopwatch.
class MatchController {
  MatchController(MatchState initial) : _state = initial;

  MatchState _state;
  final List<MatchState> _undo = [];
  final List<MatchState> _redo = [];
  final _changes = StreamController<MatchState>.broadcast();

  MatchState get state => _state;
  Stream<MatchState> get changes => _changes.stream;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void _set(MatchState s, {bool record = true}) {
    if (record) {
      _undo.add(_state);
      if (_undo.length > 200) _undo.removeAt(0);
      _redo.clear();
    }
    _state = s;
    _changes.add(s);
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_state);
    _state = _undo.removeLast();
    _changes.add(_state);
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_state);
    _state = _redo.removeLast();
    _changes.add(_state);
  }

  void changeScore(Side side, int delta) {
    final t = _state.team(side);
    final labels = _state.sport.scoreLabels;
    final next = (t.score + delta).clamp(
      0,
      labels == null ? 999 : labels.length - 1,
    );
    if (next == t.score) return;
    _set(_state.withTeam(side, t.copyWith(score: next)));
  }

  void changeSets(Side side, int delta) {
    final t = _state.team(side);
    final next = (t.sets + delta).clamp(0, 9);
    if (next == t.sets) return;
    _set(_state.withTeam(side, t.copyWith(sets: next)));
  }

  void changeGames(Side side, int delta) {
    final t = _state.team(side);
    final next = (t.games + delta).clamp(0, 99);
    if (next == t.games) return;
    _set(_state.withTeam(side, t.copyWith(games: next)));
  }

  void setTeamName(Side side, String name) =>
      _set(_state.withTeam(side, _state.team(side).copyWith(name: name)));

  /// An empty [path] removes the logo.
  void setTeamLogo(Side side, String path) =>
      _set(_state.withTeam(side, _state.team(side).copyWith(logoPath: path)));

  void setTeamColor(Side side, int colorValue) => _set(
    _state.withTeam(side, _state.team(side).copyWith(colorValue: colorValue)),
  );

  void startClock() {
    if (!_state.sport.hasClock ||
        _state.running ||
        _state.timeoutRemaining != null) {
      return;
    }
    _set(_state.copyWith(running: true));
  }

  void stopClock() {
    if (!_state.running) return;
    _set(_state.copyWith(running: false));
  }

  void toggleClock() => _state.running ? stopClock() : startClock();

  /// Starts a time penalty. Returns false if the rules forbid it.
  bool addSuspension(Side side, {String player = ''}) {
    final dur = _state.sport.suspensionDuration;
    if (dur == null) return false;
    final t = _state.team(side);
    // Align the penalty's sub-second phase with the game clock so both
    // displays change seconds at the same instant.
    final frac = Duration(microseconds: _state.clock.inMicroseconds % 1000000);
    final aligned = _state.sport.countUp ? dur - frac : dur + frac;
    _set(
      _state.withTeam(
        side,
        t.copyWith(
          suspensions: [...t.suspensions, aligned],
          suspensionPlayers: [...t.suspensionPlayers, player.trim()],
        ),
      ),
    );
    return true;
  }

  void removeSuspension(Side side, int index) {
    final t = _state.team(side);
    if (index < 0 || index >= t.suspensions.length) return;
    final list = [...t.suspensions]..removeAt(index);
    final players = [...t.suspensionPlayers]..removeAt(index);
    _set(
      _state.withTeam(
        side,
        t.copyWith(suspensions: list, suspensionPlayers: players),
      ),
    );
  }

  /// Starts a team timeout, stopping the game clock. False if none left.
  bool callTimeout(Side side) {
    if (_state.timeoutRemaining != null) return false;
    final t = _state.team(side);
    if (t.timeoutsUsed >= _state.sport.timeoutsPerMatch) return false;
    _set(
      _state
          .withTeam(side, t.copyWith(timeoutsUsed: t.timeoutsUsed + 1))
          .copyWith(
            running: false,
            timeoutRemaining: _state.sport.timeoutDuration,
            timeoutSide: side,
          ),
    );
    return true;
  }

  void endTimeout() {
    if (_state.timeoutRemaining == null) return;
    _set(_state.copyWith(clearTimeout: true));
  }

  /// Aborts a timeout that was called by mistake and gives it back to the team.
  void cancelTimeout() {
    final side = _state.timeoutSide;
    if (_state.timeoutRemaining == null) return;
    var s = _state;
    if (side != null) {
      final t = s.team(side);
      s = s.withTeam(
        side,
        t.copyWith(timeoutsUsed: (t.timeoutsUsed - 1).clamp(0, 99)),
      );
    }
    _set(s.copyWith(clearTimeout: true));
  }

  bool get isPeriodOver {
    final s = _state;
    return s.sport.countUp
        ? s.clock >= s.sport.periodDuration
        : s.clock <= Duration.zero;
  }

  /// Moves to the next period and resets the clock. False after the last one.
  bool nextPeriod() {
    if (_state.period >= _state.sport.periods) return false;
    final resetPoints = !_state.sport.hasClock;
    TeamState reset(TeamState t) =>
        resetPoints ? t.copyWith(score: 0, games: 0) : t;
    _set(
      _state.copyWith(
        home: reset(_state.home),
        away: reset(_state.away),
        period: _state.period + 1,
        running: false,
        clock: _state.sport.countUp
            ? Duration.zero
            : _state.sport.periodDuration,
      ),
    );
    return true;
  }

  void setClock(Duration d) => _set(_state.copyWith(clock: d));

  /// Advances running timers by [delta]. Not recorded in undo history.
  void tick(Duration delta) {
    var s = _state;
    if (s.timeoutRemaining != null) {
      final left = s.timeoutRemaining! - delta;
      s = left <= Duration.zero
          ? s.copyWith(clearTimeout: true)
          : s.copyWith(timeoutRemaining: left);
      _set(s, record: false);
      return;
    }
    if (!s.running) return;

    final limit = s.sport.periodDuration;
    var clock = s.sport.countUp ? s.clock + delta : s.clock - delta;
    var running = true;
    var applied = delta;
    if (s.sport.countUp && clock >= limit) {
      applied -= clock - limit;
      clock = limit;
      running = false;
    } else if (!s.sport.countUp && clock <= Duration.zero) {
      applied += clock;
      clock = Duration.zero;
      running = false;
    }

    TeamState tick(TeamState t) {
      if (t.suspensions.isEmpty) return t;
      final next = <Duration>[];
      final players = <String>[];
      for (var i = 0; i < t.suspensions.length; i++) {
        final left = t.suspensions[i] - applied;
        if (left > Duration.zero) {
          next.add(left);
          players.add(t.suspensionPlayers[i]);
        }
      }
      return t.copyWith(suspensions: next, suspensionPlayers: players);
    }

    _set(
      s.copyWith(
        clock: clock,
        running: running,
        home: tick(s.home),
        away: tick(s.away),
      ),
      record: false,
    );
  }

  Future<void> dispose() => _changes.close();
}
