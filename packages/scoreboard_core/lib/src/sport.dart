/// Data-driven description of a sport's rules. New sports = new definitions.
class SportDefinition {
  const SportDefinition({
    required this.id,
    required this.name,
    required this.periods,
    required this.periodDuration,
    this.countUp = true,
    this.suspensionDuration,
    this.timeoutsPerMatch = 0,
    this.timeoutDuration = const Duration(minutes: 1),
    this.periodLabels = const [],
    this.hasClock = true,
    this.scoreLabels,
    this.tracksSets = false,
    this.tracksGames = false,
  });

  final String id;
  final String name;
  final int periods;
  final Duration periodDuration;

  /// False for set-based sports (tennis, table tennis, volleyball).
  final bool hasClock;

  /// Maps score value to display text (tennis: 0, 15, 30, 40, AD).
  final List<String>? scoreLabels;
  final bool tracksSets;
  final bool tracksGames;

  String scoreLabel(int score) {
    final l = scoreLabels;
    if (l == null) return '$score';
    return l[score.clamp(0, l.length - 1)];
  }

  /// Clock counts up (handball) or down (basketball).
  final bool countUp;

  /// Time-penalty length, null when the sport has none.
  final Duration? suspensionDuration;
  final int timeoutsPerMatch;
  final Duration timeoutDuration;
  final List<String> periodLabels;

  String periodLabel(int period) => period >= 1 && period <= periodLabels.length
      ? periodLabels[period - 1]
      : '$period';

  /// A copy with a different number of periods and/or period length (e.g.
  /// youth or training games). Labels become generic when the count changes.
  SportDefinition copyWith({
    int? periods,
    Duration? periodDuration,
    int? timeoutsPerMatch,
    Duration? timeoutDuration,
    bool? countUp,
  }) {
    final n = periods ?? this.periods;
    var labels = periodLabels;
    if (n != this.periods) {
      final first = periodLabels.isEmpty ? '' : periodLabels.first;
      final noun = first.startsWith('Game')
          ? 'Game'
          : (first.startsWith('Set') || !hasClock ? 'Set' : 'Period');
      labels = [for (var i = 1; i <= n; i++) '$noun $i'];
    }
    return SportDefinition(
      id: id,
      name: name,
      periods: n,
      periodDuration: periodDuration ?? this.periodDuration,
      countUp: countUp ?? this.countUp,
      suspensionDuration: suspensionDuration,
      timeoutsPerMatch: timeoutsPerMatch ?? this.timeoutsPerMatch,
      timeoutDuration: timeoutDuration ?? this.timeoutDuration,
      periodLabels: labels,
      hasClock: hasClock,
      scoreLabels: scoreLabels,
      tracksSets: tracksSets,
      tracksGames: tracksGames,
    );
  }
}

const handball = SportDefinition(
  id: 'handball',
  name: 'Handball',
  periods: 2,
  periodDuration: Duration(minutes: 30),
  suspensionDuration: Duration(minutes: 2),
  timeoutsPerMatch: 3,
  periodLabels: ['1st half', '2nd half'],
);

const basketball = SportDefinition(
  id: 'basketball',
  name: 'Basketball',
  periods: 4,
  periodDuration: Duration(minutes: 10),
  countUp: false,
  timeoutsPerMatch: 7,
  periodLabels: ['Q1', 'Q2', 'Q3', 'Q4'],
);

const football = SportDefinition(
  id: 'football',
  name: 'Football',
  periods: 2,
  periodDuration: Duration(minutes: 45),
  periodLabels: ['1st half', '2nd half'],
);

/// Best of 5 sets; set number is the "period".
const volleyball = SportDefinition(
  id: 'volleyball',
  name: 'Volleyball',
  periods: 5,
  periodDuration: Duration.zero,
  hasClock: false,
  tracksSets: true,
  timeoutsPerMatch: 2,
  periodLabels: ['Set 1', 'Set 2', 'Set 3', 'Set 4', 'Set 5'],
);

const tableTennis = SportDefinition(
  id: 'tabletennis',
  name: 'Table tennis',
  periods: 5,
  periodDuration: Duration.zero,
  hasClock: false,
  tracksSets: true,
  timeoutsPerMatch: 1,
  periodLabels: ['Game 1', 'Game 2', 'Game 3', 'Game 4', 'Game 5'],
);

/// Points show as 0/15/30/40/AD; games and sets are tracked separately.
const tennis = SportDefinition(
  id: 'tennis',
  name: 'Tennis',
  periods: 5,
  periodDuration: Duration.zero,
  hasClock: false,
  tracksSets: true,
  tracksGames: true,
  scoreLabels: ['0', '15', '30', '40', 'AD'],
  periodLabels: ['Set 1', 'Set 2', 'Set 3', 'Set 4', 'Set 5'],
);

const iceHockey = SportDefinition(
  id: 'icehockey',
  name: 'Ice hockey',
  periods: 3,
  periodDuration: Duration(minutes: 20),
  countUp: false,
  suspensionDuration: Duration(minutes: 2),
  timeoutsPerMatch: 1,
  timeoutDuration: Duration(seconds: 30),
  periodLabels: ['1st period', '2nd period', '3rd period'],
);

class SportRegistry {
  SportRegistry._();
  static final Map<String, SportDefinition> _sports = {
    for (final s in [
      handball,
      football,
      basketball,
      volleyball,
      tableTennis,
      tennis,
      iceHockey,
    ])
      s.id: s,
  };

  static void register(SportDefinition s) => _sports[s.id] = s;
  static SportDefinition? byId(String id) => _sports[id];
  static List<SportDefinition> get all => _sports.values.toList();
}
