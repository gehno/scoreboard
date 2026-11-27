import 'package:scoreboard_core/scoreboard_core.dart';

/// The user's rules for one sport, overriding the sport's defaults.
class SportRule {
  const SportRule({
    required this.periods,
    required this.minutes,
    required this.timeouts,
    required this.timeoutSeconds,
    required this.countUp,
  });

  /// The rule a [sport] currently plays by.
  factory SportRule.of(SportDefinition sport) => SportRule(
    periods: sport.periods,
    minutes: sport.periodDuration.inMinutes,
    timeouts: sport.timeoutsPerMatch,
    timeoutSeconds: sport.timeoutDuration.inSeconds,
    countUp: sport.countUp,
  );

  /// Reads a stored rule; missing values fall back to [base].
  factory SportRule.fromJson(Map<Object?, Object?> json, SportDefinition base) {
    final fallback = SportRule.of(base);
    return SportRule(
      periods: json['periods'] as int? ?? fallback.periods,
      minutes: json['minutes'] as int? ?? fallback.minutes,
      timeouts: json['timeouts'] as int? ?? fallback.timeouts,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? fallback.timeoutSeconds,
      countUp: json['countUp'] as bool? ?? fallback.countUp,
    ).clamped();
  }

  final int periods;
  final int minutes;
  final int timeouts;
  final int timeoutSeconds;
  final bool countUp;

  SportRule copyWith({
    int? periods,
    int? minutes,
    int? timeouts,
    int? timeoutSeconds,
    bool? countUp,
  }) => SportRule(
    periods: periods ?? this.periods,
    minutes: minutes ?? this.minutes,
    timeouts: timeouts ?? this.timeouts,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    countUp: countUp ?? this.countUp,
  );

  SportRule clamped() => SportRule(
    periods: periods.clamp(1, 10),
    minutes: minutes.clamp(1, 180),
    timeouts: timeouts.clamp(0, 20),
    timeoutSeconds: timeoutSeconds.clamp(10, 600),
    countUp: countUp,
  );

  Map<String, Object> toJson() => {
    'periods': periods,
    'minutes': minutes,
    'timeouts': timeouts,
    'timeoutSeconds': timeoutSeconds,
    'countUp': countUp,
  };
}
