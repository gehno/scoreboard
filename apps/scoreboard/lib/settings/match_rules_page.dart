import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../l10n/localized_values.dart';
import '../match/match_session.dart';
import 'settings_page.dart';
import 'settings_scope.dart';
import 'sport_rule.dart';

/// Per-sport rules; edits stay a draft until the user applies them.
class MatchRulesPage extends StatefulWidget {
  const MatchRulesPage({super.key, required this.session});

  final MatchSession session;

  @override
  State<MatchRulesPage> createState() => _MatchRulesPageState();
}

class _MatchRulesPageState extends State<MatchRulesPage> {
  late String _sportId = widget.session.controller.state.sport.id;
  SportRule? _draft;

  SportDefinition get _sport => SportRegistry.byId(_sportId)!;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final rule = _draft ?? SportRule.of(settings.effectiveSport(_sport));

    return SettingsSubpage(
      title: context.l10n.matchRules,
      children: [
        _row(context.l10n.sport, _sportDropdown()),
        _Stepper(
          label: context.l10n.numberOfPeriodsSets,
          value: rule.periods,
          min: 1,
          max: 10,
          onChanged: (v) => _edit(rule.copyWith(periods: v)),
        ),
        if (_sport.hasClock)
          _Stepper(
            label: context.l10n.minutesPerPeriod,
            value: rule.minutes,
            min: 1,
            max: 180,
            onChanged: (v) => _edit(rule.copyWith(minutes: v)),
          ),
        _Stepper(
          label: context.l10n.timeoutsPerTeam,
          value: rule.timeouts,
          min: 0,
          max: 20,
          onChanged: (v) => _edit(rule.copyWith(timeouts: v)),
        ),
        if (rule.timeouts > 0)
          _Stepper(
            label: context.l10n.timeoutLengthSeconds,
            value: rule.timeoutSeconds,
            min: 10,
            max: 600,
            step: 10,
            onChanged: (v) => _edit(rule.copyWith(timeoutSeconds: v)),
          ),
        if (_sport.hasClock)
          _row(
            context.l10n.clockDirection,
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(context.l10n.countUp)),
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.countDown),
                ),
              ],
              selected: {rule.countUp},
              onSelectionChanged: (v) => _edit(rule.copyWith(countUp: v.first)),
            ),
          ),
        const SizedBox(height: 12),
        Text(context.l10n.applyingStartsANewMatchForThisSportTeamNamesAreKept),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () => _apply(rule),
              child: Text(context.l10n.apply),
            ),
            if (settings.hasRule(_sportId))
              TextButton(
                onPressed: _resetToDefaults,
                child: Text(context.l10n.resetToDefaults),
              ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, Widget control) => Row(
    children: [
      Expanded(child: Text(label)),
      control,
    ],
  );

  Widget _sportDropdown() => DropdownButton<String>(
    value: _sportId,
    items: [
      for (final sport in SportRegistry.all)
        DropdownMenuItem(
          value: sport.id,
          child: Text(localizedSportName(context.l10n, sport)),
        ),
    ],
    onChanged: (id) {
      final sport = SportRegistry.byId(id ?? _sportId)!;
      widget.session.selectSport(sport);
      setState(() {
        _sportId = sport.id;
        _draft = null;
      });
    },
  );

  void _edit(SportRule rule) => setState(() => _draft = rule);

  void _apply(SportRule rule) {
    context.readSettings.setRule(_sportId, rule);
    setState(() => _draft = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.rulesAppliedNewMatchStarted)),
    );
  }

  void _resetToDefaults() {
    context.readSettings.resetRule(_sportId);
    setState(() => _draft = null);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(
        onPressed: value > min
            ? () => onChanged((value - step).clamp(min, max))
            : null,
        icon: const Icon(Icons.remove),
      ),
      SizedBox(width: 40, child: Center(child: Text('$value'))),
      IconButton(
        onPressed: value < max
            ? () => onChanged((value + step).clamp(min, max))
            : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );
}
