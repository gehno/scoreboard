import 'sport.dart';

enum Side { home, away }

class TeamState {
  const TeamState({
    this.name = '',
    this.score = 0,
    this.timeoutsUsed = 0,
    this.suspensions = const [],
    this.suspensionPlayers = const [],
    this.colorValue = 0xFFFFFFFF,
    this.logoPath = '',
    this.sets = 0,
    this.games = 0,
  });

  final String name;
  final int score;
  final int sets;
  final int games;
  final int timeoutsUsed;

  /// Remaining durations of running suspensions.
  final List<Duration> suspensions;

  /// Jersey number of the suspended player per entry in [suspensions]
  /// (same length; empty string when unknown).
  final List<String> suspensionPlayers;
  final int colorValue;

  /// Path of the optional team logo image; empty when none is set.
  final String logoPath;

  TeamState copyWith({
    String? name,
    int? score,
    int? sets,
    int? games,
    int? timeoutsUsed,
    List<Duration>? suspensions,
    List<String>? suspensionPlayers,
    int? colorValue,
    String? logoPath,
  }) => TeamState(
    name: name ?? this.name,
    score: score ?? this.score,
    sets: sets ?? this.sets,
    games: games ?? this.games,
    timeoutsUsed: timeoutsUsed ?? this.timeoutsUsed,
    suspensions: suspensions ?? this.suspensions,
    suspensionPlayers: suspensionPlayers ?? this.suspensionPlayers,
    colorValue: colorValue ?? this.colorValue,
    logoPath: logoPath ?? this.logoPath,
  );
}

class MatchState {
  const MatchState({
    required this.sport,
    required this.home,
    required this.away,
    this.period = 1,
    this.clock = Duration.zero,
    this.running = false,
    this.timeoutRemaining,
    this.timeoutSide,
  });

  factory MatchState.initial(
    SportDefinition sport, {
    String home = 'HOME',
    String away = 'AWAY',
    String homeLogo = '',
    String awayLogo = '',
  }) => MatchState(
    sport: sport,
    home: TeamState(name: home, logoPath: homeLogo),
    away: TeamState(name: away, logoPath: awayLogo),
    clock: sport.countUp ? Duration.zero : sport.periodDuration,
  );

  final SportDefinition sport;
  final TeamState home;
  final TeamState away;
  final int period;

  /// Elapsed (count-up) or remaining (count-down) game time.
  final Duration clock;
  final bool running;

  /// Non-null while a team timeout is running.
  final Duration? timeoutRemaining;

  /// Team that called the running timeout.
  final Side? timeoutSide;

  TeamState team(Side s) => s == Side.home ? home : away;

  /// Formats a penalty so it ticks together with the game clock: the clock
  /// shows floor(seconds), so a penalty running against a count-up clock
  /// must round up.
  String penaltyClock(Duration d) => sport.countUp
      ? formatClock(Duration(seconds: (d.inMicroseconds / 1000000).ceil()))
      : formatClock(d);

  MatchState copyWith({
    TeamState? home,
    TeamState? away,
    int? period,
    Duration? clock,
    bool? running,
    Duration? timeoutRemaining,
    Side? timeoutSide,
    bool clearTimeout = false,
  }) => MatchState(
    sport: sport,
    home: home ?? this.home,
    away: away ?? this.away,
    period: period ?? this.period,
    clock: clock ?? this.clock,
    running: running ?? this.running,
    timeoutRemaining: clearTimeout
        ? null
        : (timeoutRemaining ?? this.timeoutRemaining),
    timeoutSide: clearTimeout ? null : (timeoutSide ?? this.timeoutSide),
  );

  MatchState withTeam(Side s, TeamState t) =>
      s == Side.home ? copyWith(home: t) : copyWith(away: t);

  /// Flat values addressable from layout bindings, e.g. `home.score`.
  Map<String, Object> toBindings() => {
    'home.name': home.name,
    'home.logo': home.logoPath,
    'home.score': home.score,
    'home.points': sport.scoreLabel(home.score),
    'home.sets': home.sets,
    'home.games': home.games,
    'home.timeouts': home.timeoutsUsed,
    'home.suspensions': home.suspensions.length,
    'away.name': away.name,
    'away.logo': away.logoPath,
    'away.score': away.score,
    'away.points': sport.scoreLabel(away.score),
    'away.sets': away.sets,
    'away.games': away.games,
    'away.timeouts': away.timeoutsUsed,
    'away.suspensions': away.suspensions.length,
    'period': period,
    'period.label': sport.periodLabel(period),
    'clock': formatClock(clock),
    'clock.running': running,
    'timeout.active': timeoutRemaining != null,
    'timeout.clock': formatClock(timeoutRemaining ?? Duration.zero),
    for (var i = 0; i < 4; i++) ...{
      'home.suspension.$i': i < home.suspensions.length
          ? penaltyClock(home.suspensions[i])
          : '',
      'away.suspension.$i': i < away.suspensions.length
          ? penaltyClock(away.suspensions[i])
          : '',
      'home.suspension.$i.player': _playerLabel(home, i),
      'away.suspension.$i.player': _playerLabel(away, i),
    },
  };
}

String _playerLabel(TeamState t, int i) =>
    i < t.suspensionPlayers.length && t.suspensionPlayers[i].isNotEmpty
    ? '#${t.suspensionPlayers[i]}'
    : '';

String formatClock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Inverse of [formatClock]; null unless [text] is `m:ss` to `mmm:ss`.
Duration? parseClock(String text) {
  final match = RegExp(r'^(\d{1,3}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  return Duration(
    minutes: int.parse(match.group(1)!),
    seconds: int.parse(match.group(2)!),
  );
}
