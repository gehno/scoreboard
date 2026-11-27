import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../match/match_session.dart';
import '../platform/local_image.dart';
import 'image_source.dart';
import 'settings_page.dart';
import 'settings_scope.dart';

/// Name and optional logo of both teams.
class TeamNamesPage extends StatelessWidget {
  const TeamNamesPage({super.key, required this.session, required this.images});

  final MatchSession session;
  final ImageSource images;

  @override
  Widget build(BuildContext context) => SettingsSubpage(
    title: context.l10n.teamNames,
    children: [
      for (final side in Side.values)
        _TeamBlock(session: session, images: images, side: side),
    ],
  );
}

class _TeamBlock extends StatefulWidget {
  const _TeamBlock({
    required this.session,
    required this.images,
    required this.side,
  });

  final MatchSession session;
  final ImageSource images;
  final Side side;

  @override
  State<_TeamBlock> createState() => _TeamBlockState();
}

class _TeamBlockState extends State<_TeamBlock> {
  late final TextEditingController _logo = TextEditingController(
    text: widget.session.controller.state.team(widget.side).logoPath,
  );
  StreamSubscription<DroppedImage>? _drops;

  @override
  void initState() {
    super.initState();
    _drops = widget.images.drops.listen(_onDrop);
  }

  @override
  void dispose() {
    _drops?.cancel();
    _logo.dispose();
    super.dispose();
  }

  void _onDrop(DroppedImage drop) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final area = box.localToGlobal(Offset.zero) & box.size;
    if (area.contains(drop.position)) _setLogo(drop.path);
  }

  Future<void> _pick() async {
    final path = await widget.images.pick();
    if (path != null) _setLogo(path);
  }

  void _setLogo(String path) {
    if (!isSupportedImage(path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.unsupportedImageType}: '
            '${supportedImageExtensions.join(', ')}',
          ),
        ),
      );
      return;
    }
    _logo.text = path;
    widget.session.controller.setTeamLogo(widget.side, path);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.session.controller;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          TextFormField(
            initialValue: controller.state.team(widget.side).name,
            decoration: InputDecoration(
              labelText: widget.side == Side.home
                  ? context.l10n.home
                  : context.l10n.away,
            ),
            onChanged: (name) => controller.setTeamName(widget.side, name),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _logo,
                  decoration: InputDecoration(
                    labelText: context.l10n.logoImageFilePathOptional,
                    helperText: widget.images.canPick
                        ? context.l10n.chooseAFileOrDropAnImageHere
                        : null,
                    suffixIcon: widget.images.canPick
                        ? IconButton(
                            tooltip: context.l10n.chooseImage,
                            icon: const Icon(Icons.folder_open),
                            onPressed: _pick,
                          )
                        : null,
                  ),
                  onChanged: (path) =>
                      controller.setTeamLogo(widget.side, path.trim()),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: ListenableBuilder(
                  listenable: widget.session,
                  builder: (context, _) {
                    final path = controller.state.team(widget.side).logoPath;
                    return path.isEmpty
                        ? const SizedBox.shrink()
                        : LocalImage(path);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
