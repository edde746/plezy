import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/card_focus_scope.dart';
import '../../focus/focusable_wrapper.dart';
import '../../games/game_artwork.dart';
import '../../games/game_models.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/media_grid_delegate.dart';
import '../../widgets/sliver_cross_axis_layout_builder.dart';

/// Games share the media browser's packing, gutters and poster focus treatment.
/// They keep their own model and actions instead of masquerading as films.
class GameCardGrid extends StatelessWidget {
  const GameCardGrid({super.key, required this.games, required this.builder});
  final List<StreamGame> games;
  final Widget Function(BuildContext, StreamGame) builder;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    sliver: SliverCrossAxisLayoutBuilder(
      builder: (context, width) {
        final geometry = MediaGridGeometry.resolve(
          context: context,
          crossAxisExtent: width,
          density: SettingsService.instance.read(SettingsService.libraryDensity),
        );
        // Captions grow with the user's font size; posters keep their shape.
        final scaler = MediaQuery.textScalerOf(context);
        final theme = Theme.of(context).textTheme;
        final titleHeight = scaler.scale(theme.bodyMedium?.fontSize ?? 14) * 1.4;
        final hostHeight = scaler.scale(theme.bodySmall?.fontSize ?? 12) * 1.4;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: geometry.columnCount,
            crossAxisSpacing: geometry.spacing,
            mainAxisSpacing: geometry.spacing,
            mainAxisExtent: (geometry.itemWidth - 12) * 1.5 + titleHeight + hostHeight + 22,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) => builder(context, games[index]),
        );
      },
    ),
  );
}

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.host,
    required this.artwork,
    required this.favorite,
    required this.onPlay,
    required this.onFavorite,
    this.focusNode,
  });
  final StreamGame game;
  final GameHost host;
  final GameArtworkLoader artwork;
  final bool favorite;
  final VoidCallback? onPlay;
  final VoidCallback? onFavorite;
  final FocusNode? focusNode;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  late Future<Uint8List?> _cover;

  @override
  void initState() {
    super.initState();
    _cover = widget.artwork.load(widget.host, widget.game);
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.key != widget.game.key ||
        oldWidget.host.address != widget.host.address ||
        oldWidget.host.port != widget.host.port ||
        oldWidget.artwork != widget.artwork) {
      _cover = widget.artwork.load(widget.host, widget.game);
    }
  }

  Future<void> _menu() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || widget.onPlay == null) return;
    final action = await showAdaptiveAppMenu<String>(
      context,
      title: widget.game.name,
      anchorRect: box.localToGlobal(Offset.zero) & box.size,
      focusFirstItem: true,
      entries: [
        AppMenuItem(value: 'play', label: t.games.play, icon: Symbols.play_arrow_rounded),
        AppMenuItem(
          value: 'favorite',
          label: widget.favorite ? t.games.unfavorite : t.games.favorite,
          icon: widget.favorite ? Symbols.favorite_rounded : Symbols.favorite_border_rounded,
        ),
      ],
    );
    if (!mounted) return;
    if (action == 'play') widget.onPlay?.call();
    if (action == 'favorite') widget.onFavorite?.call();
  }

  Widget _placeholder(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: AppIcon(Symbols.sports_esports_rounded, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final radius = tokens(context).radiusSm;
    final enabled = widget.onPlay != null;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: FocusableWrapper(
        focusNode: widget.focusNode,
        delegateFocusBorder: true,
        borderRadius: radius,
        descendantsAreFocusable: false,
        semanticLabel: '${widget.game.name}, ${widget.host.name}',
        semanticValue: widget.favorite ? t.games.favorites : null,
        onSelect: widget.onPlay,
        onLongPress: enabled ? _menu : null,
        enableLongPress: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPlay,
          onLongPress: enabled ? _menu : null,
          onSecondaryTap: enabled ? _menu : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardFocusBorder(
                borderRadius: radius,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: _cover,
                          builder: (context, snapshot) => snapshot.data == null
                              ? _placeholder(context)
                              : Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 360,
                                  excludeFromSemantics: true,
                                  errorBuilder: (context, _, _) => _placeholder(context),
                                ),
                        ),
                        if (widget.favorite)
                          PositionedDirectional(
                            end: 6,
                            top: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(5),
                                child: AppIcon(Symbols.favorite_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.game.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              Text(
                widget.host.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
