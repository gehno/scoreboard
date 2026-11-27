import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../platform/local_image.dart';
import '../settings/settings_scope.dart';

/// One team: identity, score, secondary counters and penalty actions.
class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.side,
    required this.controller,
    required this.onTimeout,
    required this.onSuspension,
  });

  final Side side;
  final MatchController controller;
  final VoidCallback onTimeout;
  final VoidCallback onSuspension;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final sport = state.sport;
    final team = state.team(side);
    final textTheme = Theme.of(context).textTheme;
    final hasActions =
        sport.suspensionDuration != null || sport.timeoutsPerMatch > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ColoredBox(
            color: Color(team.colorValue),
            child: const SizedBox(height: 6, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  side == Side.home
                      ? context.l10n.homeUpper
                      : context.l10n.awayUpper,
                  style: textTheme.labelSmall,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (team.logoPath.isNotEmpty) ...[
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: LocalImage(team.logoPath),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        team.name,
                        style: textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ScoreRow(
                  label: sport.scoreLabel(team.score),
                  onChange: (delta) => controller.changeScore(side, delta),
                ),
                if (sport.tracksGames || sport.tracksSets) ...[
                  const Divider(height: 32),
                  if (sport.tracksGames)
                    _Counter(
                      label: context.l10n.games,
                      value: team.games,
                      onChange: (delta) => controller.changeGames(side, delta),
                    ),
                  if (sport.tracksSets)
                    _Counter(
                      label: context.l10n.sets,
                      value: team.sets,
                      onChange: (delta) => controller.changeSets(side, delta),
                    ),
                ],
                if (hasActions) ...[
                  const Divider(height: 32),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (sport.timeoutsPerMatch > 0)
                        OutlinedButton.icon(
                          onPressed: onTimeout,
                          icon: const Icon(Icons.timer_outlined),
                          label: Text(
                            '${context.l10n.timeout} '
                            '(${sport.timeoutsPerMatch - team.timeoutsUsed})',
                          ),
                        ),
                      if (sport.suspensionDuration != null)
                        OutlinedButton.icon(
                          onPressed: onSuspension,
                          icon: const Icon(Icons.person_off_outlined),
                          label: Text('2 min (${team.suspensions.length})'),
                        ),
                    ],
                  ),
                ],
                for (var i = 0; i < team.suspensions.length; i++)
                  _SuspensionTile(
                    text: _suspensionText(context, state, team, i),
                    onRemove: () => controller.removeSuspension(side, i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _suspensionText(
    BuildContext context,
    MatchState state,
    TeamState team,
    int index,
  ) {
    final remaining = state.penaltyClock(team.suspensions[index]);
    final player = team.suspensionPlayers[index];
    return context.l10n.suspensionT(remaining) +
        (player.isEmpty ? '' : '  #$player');
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.onChange});

  final String label;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        iconSize: 32,
        onPressed: () => onChange(-1),
        icon: const Icon(Icons.remove),
      ),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
      IconButton.filled(
        iconSize: 32,
        onPressed: () => onChange(1),
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onChange,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(onPressed: () => onChange(-1), icon: const Icon(Icons.remove)),
      SizedBox(
        width: 32,
        child: Center(
          child: Text('$value', style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      IconButton(onPressed: () => onChange(1), icon: const Icon(Icons.add)),
    ],
  );
}

class _SuspensionTile extends StatelessWidget {
  const _SuspensionTile({required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(text),
    trailing: IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
  );
}
