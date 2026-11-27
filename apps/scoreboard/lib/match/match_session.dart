import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../display/display_output.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_values.dart';
import '../settings/app_settings.dart';
import '../storage/layout_repository.dart';

/// The running match plus everything derived from it: the layout to show,
/// the clock ticker and the feed to the display. Notifies on every change.
class MatchSession extends ChangeNotifier {
  MatchSession({
    required AppSettings settings,
    required this._layouts,
    required this._output,
  }) : _settings = settings,
       controller = MatchController(
         MatchState.initial(settings.effectiveSport(handball)),
       ),
       layout = defaultLayoutFor(handball.id) {
    _settings.addListener(_onSettingsChanged);
    _watchController();
    // A monotonic stopwatch keeps the clock exact regardless of frame rate.
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = _stopwatch.elapsed;
      controller.tick(now - _lastTick);
      _lastTick = now;
    });
    _publish();
    unawaited(_loadSavedLayout(handball.id));
  }
  final AppSettings _settings;
  final LayoutRepository _layouts;
  final DisplayOutput _output;
  final _stopwatch = Stopwatch()..start();
  late final Timer _ticker;
  Duration _lastTick = Duration.zero;
  StreamSubscription<MatchState>? _changes;
  bool _isDisposed = false;

  MatchController controller;
  ScoreboardLayout layout;

  /// The layout with the selected theme applied, as the display shows it.
  ScoreboardLayout get themedLayout => _settings.theme.apply(layout);

  /// Live values for the layout, with period labels in the user's language.
  Map<String, Object> get bindings {
    final state = controller.state;
    final l10n = lookupAppLocalizations(Locale(_settings.language.name));
    return state.toBindings()
      ..['period.label'] = localizedPeriodLabel(
        l10n,
        state.sport,
        state.period,
      );
  }

  /// Starts a new match for [base] (with the user's rules) and loads its layout.
  void selectSport(SportDefinition base, {bool keepTeams = false}) {
    final sport = _settings.effectiveSport(base);
    final previous = controller;
    final home = previous.state.home;
    final away = previous.state.away;
    controller = MatchController(
      MatchState.initial(
        sport,
        home: keepTeams ? home.name : 'HOME',
        away: keepTeams ? away.name : 'AWAY',
        homeLogo: home.logoPath,
        awayLogo: away.logoPath,
      ),
    );
    _watchController();
    unawaited(previous.dispose());
    layout = defaultLayoutFor(sport.id);
    _publish();
    unawaited(_loadSavedLayout(sport.id));
  }

  Future<void> saveLayout(ScoreboardLayout edited) async {
    layout = edited;
    _publish();
    await _layouts.save(edited);
  }

  void _watchController() {
    unawaited(_changes?.cancel());
    _changes = controller.changes.listen((_) => _publish());
  }

  Future<void> _loadSavedLayout(String sportId) async {
    final saved = await _layouts.load(sportId);
    if (_isDisposed || controller.state.sport.id != sportId) return;
    layout = saved;
    _publish();
  }

  void _onSettingsChanged() {
    final current = controller.state.sport;
    final updated = _settings.effectiveSport(SportRegistry.byId(current.id)!);
    if (_hasDifferentRules(updated, current)) {
      selectSport(SportRegistry.byId(current.id)!, keepTeams: true);
    } else {
      _publish();
    }
  }

  bool _hasDifferentRules(SportDefinition a, SportDefinition b) =>
      a.periods != b.periods ||
      a.periodDuration != b.periodDuration ||
      a.timeoutsPerMatch != b.timeoutsPerMatch ||
      a.timeoutDuration != b.timeoutDuration ||
      a.countUp != b.countUp;

  void _publish() {
    if (_isDisposed) return;
    _output.show(DisplayMessage(themedLayout, bindings));
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _settings.removeListener(_onSettingsChanged);
    _ticker.cancel();
    unawaited(_changes?.cancel());
    unawaited(controller.dispose());
    super.dispose();
  }
}
