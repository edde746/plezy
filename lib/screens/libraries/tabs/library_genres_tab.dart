import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/ids.dart';
import '../../../media/library_genre.dart';
import '../../../media/media_server_client.dart';
import '../../../mixins/grid_focus_node_mixin.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/media_image_helper.dart';
import '../../../utils/platform_detector.dart';
import '../../../utils/provider_extensions.dart';
import '../../../widgets/nested_tab_scrollbar.dart';
import '../../../widgets/optimized_media_image.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Genres tab: one tile per genre of the library, the way Plex Web's
/// Categories tab lays them out. Opening a tile hands the genre to
/// [onGenreSelected]; the libraries screen shows it in Browse.
class LibraryGenresTab extends BaseLibraryTab<LibraryGenre> {
  final ValueChanged<LibraryGenre> onGenreSelected;

  const LibraryGenresTab({
    super.key,
    required super.library,
    required this.onGenreSelected,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
  });

  @override
  State<LibraryGenresTab> createState() => _LibraryGenresTabState();
}

class _LibraryGenresTabState extends BaseLibraryTabState<LibraryGenre, LibraryGenresTab>
    with GridFocusNodeMixin, LibraryTabFocusMixin {
  static const double _gap = 12;

  /// Matches the Browse chips bar, so tiles line up with the tab chips.
  static const double _horizontalInset = 16;

  /// Room above the first row for the focus border and scale.
  static const double _focusDecorationPadding = 8;

  /// Widest a tile grows before the grid adds a column.
  static const double _maxTileWidth = 320;
  static const int _minColumns = 2;

  /// Below this tile width the title steps down a size so two-column phone
  /// grids keep long names on two lines.
  static const double _compactTileWidth = 220;

  @override
  String get focusNodeDebugLabel => 'genres_first_item';

  @override
  int get itemCount => items.length;

  @override
  IconData get emptyIcon => Symbols.theater_comedy_rounded;

  @override
  String get emptyMessage => t.libraries.noGenres;

  @override
  String get errorContext => t.libraries.tabs.genres;

  @override
  Future<void> loadItems() => runLoadTransaction(() {
    final library = widget.library;
    return getMediaClientForLibrary().fetchLibraryGenres(library.id, libraryKind: library.kind);
  });

  @override
  void dispose() {
    disposeGridFocusNodes();
    super.dispose();
  }

  FocusNode _tileFocusNode(int index) => index == 0 ? firstItemFocusNode : getGridItemFocusNode(index, prefix: 'genre');

  void _focusTile(int index) {
    if (index < 0 || index >= items.length) return;
    final node = _tileFocusNode(index);
    if (node.context != null) {
      node.requestFocus();
    } else {
      // Not built yet: the grid realizes the next row as focus scrolls to it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) node.requestFocus();
      });
    }
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  @override
  Widget buildContent(List<LibraryGenre> items) {
    final client = context.tryGetMediaClientForServer(serverIdOrNull(widget.library.serverId));
    return NestedTabScrollbar(
      child: CustomScrollView(
        // Let the focus border and scale draw past the scroll bounds.
        clipBehavior: Clip.none,
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_horizontalInset, _focusDecorationPadding, _horizontalInset, 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = math.max(_minColumns, ((width + _gap) / (_maxTileWidth + _gap)).ceil());
                final tileWidth = (width - _gap * (columns - 1)) / columns;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: _gap,
                    crossAxisSpacing: _gap,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildTile(
                    items,
                    index,
                    columns: columns,
                    client: client,
                    compact: tileWidth < _compactTileWidth,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Explicit D-pad moves, as the other library grids use: framework
  /// traversal scrolls through the NestedScrollView coordinator and can snap
  /// the inner list back to the top on UP.
  Widget _buildTile(
    List<LibraryGenre> items,
    int index, {
    required int columns,
    required MediaServerClient? client,
    required bool compact,
  }) {
    final genre = items[index];
    final count = items.length;
    final column = index % columns;
    final row = index ~/ columns;
    final lastRow = (count - 1) ~/ columns;
    return _GenreTile(
      key: ValueKey(genre.filterValue),
      genre: genre,
      client: client,
      compact: compact,
      focusNode: focusNodeForIndex(index, firstItemFocusNode, prefix: 'genre', itemIdentity: genre.filterValue),
      onOpen: () => widget.onGenreSelected(genre),
      onNavigateUp: row == 0 ? widget.onBack : () => _focusTile(index - columns),
      // A short last row: DOWN from a column it lacks lands on its last tile.
      onNavigateDown: row == lastRow ? _ignore : () => _focusTile(math.min(index + columns, count - 1)),
      onNavigateLeft: column == 0 ? _navigateToSidebar : () => _focusTile(index - 1),
      onNavigateRight: column == columns - 1 || index == count - 1 ? _ignore : () => _focusTile(index + 1),
      onBack: widget.onBack,
      onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
    );
  }

  /// Keeps focus on a grid edge instead of letting traversal wander off it.
  static void _ignore() {}
}

/// Plex Web's category tints. Plex assigns one per genre; genres from a
/// backend that publishes none take one from here by name, so a genre keeps
/// its colour across visits.
const List<int> _fallbackAccents = [
  0x91293D,
  0x494616,
  0x4C561B,
  0x883E7D,
  0x8B6122,
  0x8B4D43,
  0x23533C,
  0x33486E,
  0x846E49,
  0x2B717E,
  0x347431,
  0x51284C,
  0x37397A,
  0x7A281A,
  0x3B8265,
  0x892959,
  0x673E8B,
  0x57222B,
  0x704A23,
  0x884624,
];

int _fallbackAccent(String title) {
  var hash = 0;
  for (final unit in title.codeUnits) {
    hash = (hash * 31 + unit) & 0x3fffffff;
  }
  return _fallbackAccents[hash % _fallbackAccents.length];
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({
    super.key,
    required this.genre,
    required this.client,
    required this.compact,
    required this.focusNode,
    required this.onOpen,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onNavigateLeft,
    required this.onNavigateRight,
    required this.onBack,
    required this.onFocusChange,
  });

  final LibraryGenre genre;
  final MediaServerClient? client;
  final bool compact;
  final FocusNode focusNode;
  final VoidCallback onOpen;
  final VoidCallback? onNavigateUp;
  final VoidCallback onNavigateDown;
  final VoidCallback onNavigateLeft;
  final VoidCallback onNavigateRight;
  final VoidCallback? onBack;
  final ValueChanged<bool> onFocusChange;

  /// How much of the art shows through the tint.
  static const double _tintAlpha = 0.78;

  @override
  Widget build(BuildContext context) {
    final radius = tokens(context).radiusSm;
    final accent = Color(0xFF000000 | ((genre.accentRgb ?? _fallbackAccent(genre.title)) & 0xFFFFFF));
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = (compact ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)],
    );
    final artPath = genre.artPath;

    return FocusableWrapper(
      focusNode: focusNode,
      semanticLabel: genre.title,
      includeFocusSemantics: !PlatformDetector.isTV() || MediaQuery.accessibleNavigationOf(context),
      borderRadius: radius,
      onSelect: onOpen,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      onNavigateLeft: onNavigateLeft,
      onNavigateRight: onNavigateRight,
      onBack: onBack,
      onFocusChange: onFocusChange,
      useComfortableZone: !PlatformDetector.isTV(), // Always center on TV
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _TileTapRegion(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: accent),
              if (artPath != null)
                OptimizedMediaImage(
                  client: client,
                  imagePath: artPath,
                  imageType: ImageType.thumb,
                  placeholder: _emptyArt,
                  errorWidget: _emptyArtError,
                ),
              ColoredBox(color: accent.withValues(alpha: _tintAlpha)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    genre.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _emptyArt(BuildContext context, String _) => const SizedBox.shrink();

  // A tile without art is the plain tint, never a broken-image glyph.
  static Widget _emptyArtError(BuildContext context, String _, dynamic _) => const SizedBox.shrink();
}

/// Pointer/touch surface: an [InkWell] on desktop where hover feedback
/// matters, a bare [GestureDetector] on TV and touch devices, as media rows
/// do. Keyboard focus belongs to the enclosing [FocusableWrapper].
class _TileTapRegion extends StatelessWidget {
  const _TileTapRegion({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isDesktopOS()) {
      return GestureDetector(excludeFromSemantics: true, behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              excludeFromSemantics: true,
              mouseCursor: SystemMouseCursors.click,
              canRequestFocus: false,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}
