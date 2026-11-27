import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../l10n/localized_values.dart';
import '../settings/settings_scope.dart';
import '../settings/shortcuts.dart';
import 'operator_dialogs.dart';

/// Match time and period with the clock controls.
class ClockCard extends StatelessWidget {
  const ClockCard({super.key, required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final sport = state.sport;
    final textTheme = Theme.of(context).textTheme;
    final startStopKey = context.settings
        .binding(ShortcutAction.toggleClock)
        .label;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Chip(
              label: Text(
                localizedPeriodLabel(context.l10n, sport, state.period),
              ),
            ),
            if (sport.hasClock)
              Text(
                formatClock(state.clock),
                style: textTheme.displayLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (sport.hasClock)
                  FilledButton.icon(
                    onPressed: controller.toggleClock,
                    icon: Icon(state.running ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      '${state.running ? context.l10n.stop : context.l10n.start} '
                      '($startStopKey)',
                    ),
                  ),
                OutlinedButton(
                  onPressed: state.period < sport.periods
                      ? controller.nextPeriod
                      : null,
                  child: Text(
                    sport.hasClock
                        ? context.l10n.nextPeriod
                        : context.l10n.nextSet,
                  ),
                ),
                if (sport.hasClock)
                  OutlinedButton(
                    onPressed: () => _adjustClock(context),
                    child: Text(context.l10n.setClock),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustClock(BuildContext context) async {
    final clock = await askClock(context, controller.state.clock);
    if (clock != null) controller.setClock(clock);
  }
}
