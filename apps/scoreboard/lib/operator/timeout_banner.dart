import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../settings/settings_scope.dart';
import '../settings/shortcuts.dart';

class TimeoutBanner extends StatelessWidget {
  const TimeoutBanner({super.key, required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final side = state.timeoutSide == Side.home
        ? context.l10n.homeUpper
        : context.l10n.awayUpper;
    final abortKey = context.settings
        .binding(ShortcutAction.cancelTimeout)
        .label;
    return Card(
      color: Colors.amber.shade800,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${context.l10n.timeoutSide(side)}  '
                '${formatClock(state.timeoutRemaining!)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            FilledButton.tonal(
              onPressed: controller.cancelTimeout,
              child: Text('${context.l10n.abortRefund} – $abortKey'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: controller.endTimeout,
              child: Text(context.l10n.endNow),
            ),
          ],
        ),
      ),
    );
  }
}
