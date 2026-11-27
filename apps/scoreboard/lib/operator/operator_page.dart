import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../app/about.dart';
import '../display/display_output.dart';
import '../editor/editor_page.dart';
import '../l10n/localized_values.dart';
import '../match/match_session.dart';
import '../scoreboard/scoreboard_view.dart';
import '../settings/app_settings.dart';
import '../settings/image_source.dart';
import '../settings/settings_page.dart';
import '../settings/settings_scope.dart';
import '../settings/shortcuts.dart';
import '../storage/backup_service.dart';
import '../storage/layout_repository.dart';
import 'clock_card.dart';
import 'operator_dialogs.dart';
import 'team_card.dart';
import 'timeout_banner.dart';

class OperatorPage extends StatefulWidget {
  const OperatorPage({
    super.key,
    required this.settings,
    required this.layouts,
    required this.output,
    required this.images,
    this.backup,
  });

  final AppSettings settings;
  final LayoutRepository layouts;
  final DisplayOutput output;
  final ImageSource images;
  final BackupService? backup;

  @override
  State<OperatorPage> createState() => _OperatorPageState();
}

class _OperatorPageState extends State<OperatorPage> {
  /// Design widths the controls are laid out at before being scaled to fit.
  static const _controlsWidthWide = 640.0;
  static const _controlsWidthNarrow = 520.0;

  late final MatchSession _session = MatchSession(
    settings: widget.settings,
    layouts: widget.layouts,
    output: widget.output,
  );

  MatchController get _match => _session.controller;

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _session,
    builder: (context, _) => CallbackShortcuts(
      bindings: _shortcutBindings(context),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
      ),
    ),
  );

  Widget _buildBody(BuildContext context) {
    final layout = _session.layout;
    final preview = AspectRatio(
      aspectRatio: layout.width / layout.height,
      child: ScoreboardView(
        layout: _session.themedLayout,
        values: _session.bindings,
      ),
    );
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_match.state.timeoutRemaining != null)
          TimeoutBanner(controller: _match),
        ClockCard(controller: _match),
        Row(
          children: [
            for (final side in Side.values) ...[
              if (side == Side.away) const SizedBox(width: 8),
              Expanded(
                child: TeamCard(
                  side: side,
                  controller: _match,
                  onTimeout: () => _callTimeout(side),
                  onSuspension: () => _addSuspension(side),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isHorizontal = constraints.maxWidth > constraints.maxHeight;
        final scaledControls = Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: isHorizontal ? _controlsWidthWide : _controlsWidthNarrow,
              child: controls,
            ),
          ),
        );
        if (!context.settings.showPreview) return scaledControls;
        if (isHorizontal) {
          return Row(
            children: [
              Expanded(child: scaledControls),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(child: preview),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
              child: Padding(padding: const EdgeInsets.all(12), child: preview),
            ),
            Expanded(child: scaledControls),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final settings = context.settings;
    String withKey(String text, ShortcutAction action) =>
        '$text (${settings.binding(action).label})';

    return AppBar(
      title: Text(localizedSportName(context.l10n, _match.state.sport)),
      actions: [
        IconButton(
          tooltip: withKey(context.l10n.undo, ShortcutAction.undo),
          onPressed: _match.canUndo ? _match.undo : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          tooltip: withKey(context.l10n.redo, ShortcutAction.redo),
          onPressed: _match.canRedo ? _match.redo : null,
          icon: const Icon(Icons.redo),
        ),
        IconButton(
          tooltip: context.l10n.openDisplayWindow,
          onPressed: _openDisplay,
          icon: const Icon(Icons.tv),
        ),
        PopupMenuButton<VoidCallback>(
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            _menuItem(
              context,
              Icons.design_services,
              context.l10n.editLayout,
              _editLayout,
            ),
            _menuItem(
              context,
              Icons.settings,
              context.l10n.settings,
              _openSettings,
            ),
            _menuItem(
              context,
              Icons.info_outline,
              context.l10n.about,
              () => showAbout(context),
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<VoidCallback> _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback action,
  ) => PopupMenuItem(
    value: action,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      contentPadding: EdgeInsets.zero,
    ),
  );

  void _openSettings() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SettingsPage(
        session: _session,
        images: widget.images,
        backup: widget.backup,
      ),
    ),
  );
  Map<ShortcutActivator, VoidCallback> _shortcutBindings(BuildContext context) {
    final actions = <ShortcutAction, VoidCallback>{
      ShortcutAction.toggleClock: _match.toggleClock,
      ShortcutAction.cancelTimeout: _match.cancelTimeout,
      ShortcutAction.homePlus: () => _match.changeScore(Side.home, 1),
      ShortcutAction.homeMinus: () => _match.changeScore(Side.home, -1),
      ShortcutAction.awayPlus: () => _match.changeScore(Side.away, 1),
      ShortcutAction.awayMinus: () => _match.changeScore(Side.away, -1),
      ShortcutAction.homeTimeout: () => _callTimeout(Side.home),
      ShortcutAction.awayTimeout: () => _callTimeout(Side.away),
      ShortcutAction.homeSuspension: () => _addSuspension(Side.home),
      ShortcutAction.awaySuspension: () => _addSuspension(Side.away),
      ShortcutAction.nextPeriod: _nextPeriod,
      ShortcutAction.undo: _match.undo,
      ShortcutAction.redo: _match.redo,
    };
    return {
      for (final entry in actions.entries)
        context.settings.binding(entry.key).activator: () {
          if (!_isTyping) entry.value();
        },
    };
  }

  bool get _isTyping =>
      FocusManager.instance.primaryFocus?.context?.widget is EditableText;

  void _nextPeriod() {
    if (_match.state.period < _match.state.sport.periods) _match.nextPeriod();
  }

  void _callTimeout(Side side) {
    if (_match.state.sport.timeoutsPerMatch > 0 && !_match.callTimeout(side)) {
      _showMessage(context.l10n.noTimeoutsLeft);
    }
  }

  Future<void> _addSuspension(Side side) async {
    if (_match.state.sport.suspensionDuration == null) return;
    final player = await askJerseyNumber(context);
    if (player == null || !mounted) return;
    if (!_match.addSuspension(side, player: player)) {
      _showMessage(context.l10n.maxSuspensionsReached);
    }
  }

  Future<void> _editLayout() async {
    final edited = await Navigator.push<ScoreboardLayout>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditorPage(layout: _session.layout, values: _session.bindings),
      ),
    );
    if (edited != null) await _session.saveLayout(edited);
  }

  Future<void> _openDisplay() async {
    final output = widget.output;
    if (!output.isAvailable) {
      _showMessage(context.l10n.displayOutputIsNotAvailableOnThisPlatform);
      return;
    }
    int? monitor;
    final count = await output.monitorCount();
    if (count > 1) {
      if (!mounted) return;
      monitor = await pickMonitor(context, count);
      if (monitor == null) return;
    }
    await output.open(monitor: monitor);
  }

  void _showMessage(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
  );
}
