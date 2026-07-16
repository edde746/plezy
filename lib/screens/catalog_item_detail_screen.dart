import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/focusable_action_bar.dart';
import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../models/catalog/catalog_cast_member.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../services/catalog/catalog_library_matcher.dart';
import '../services/catalog/catalog_source.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../utils/app_logger.dart';
import '../utils/desktop_window_padding.dart';
import '../utils/formatters.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/app_icon.dart';
import '../widgets/backend_badge.dart';
import '../widgets/cast_member_strip.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/hub_section.dart';
import '../widgets/optimized_media_image.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/seerr_request_sheet.dart';
import '../widgets/settings_section.dart';
import '../widgets/stat_chip.dart';

/// Detail screen for a catalog item (Explore tab). Renders from provider
/// data — no media server required — and resolves library availability in
/// place: an "In these libraries" list when the item is owned, tappable
/// through to the normal media detail screen.
class CatalogItemDetailScreen extends StatefulWidget {
  final CatalogItem item;

  const CatalogItemDetailScreen({super.key, required this.item});

  @override
  State<CatalogItemDetailScreen> createState() => _CatalogItemDetailScreenState();
}

class _CatalogItemDetailScreenState extends State<CatalogItemDetailScreen> {
  final _actionBarKey = GlobalKey<FocusableActionBarState>();
  final _castSectionKey = GlobalKey();
  final _castStripKey = GlobalKey<CastMemberStripState>();
  final _relatedSectionKey = GlobalKey<HubSectionState>();
  final ScrollController _scrollController = ScrollController();
  List<FocusNode> _libraryMatchFocusNodes = const [];
  CatalogSource? _watchlistSource;
  SeerrCatalogSource? _requestSource;
  bool _mutatingWatchlist = false;

  /// Library items matching this catalog item; null while resolving.
  List<MediaItem>? _matches;

  /// Cast/characters from the item's own source; null while loading (the
  /// section only renders once loaded non-empty).
  List<CatalogCastMember>? _cast;

  /// "More like this" from the item's own source; null while loading (the
  /// row only renders once loaded non-empty).
  List<CatalogItem>? _related;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveMatches());
    unawaited(_loadCast());
    unawaited(_loadRelated());
    final sources = context.read<CatalogSourcesProvider>();
    _watchlistSource = sources.watchlistSourceFor(widget.item);
    // Request needs a connected Seerr, the permission for this kind, and a
    // tmdb id (Trakt items carry one natively; MAL items get theirs from the
    // Fribb mapping at row time).
    final seerr = sources.seerrSource;
    if (seerr != null && widget.item.ids.tmdb != null && seerr.canRequest(widget.item.kind)) {
      _requestSource = seerr;
    }
    final source = _watchlistSource;
    if (source != null) {
      source.watchlistChanges.addListener(_onWatchlistChanged);
      if (source.isOnWatchlist(widget.item.kind, widget.item.ids) == null) {
        unawaited(source.ensureWatchlistLoaded());
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actionBarKey.currentState?.requestFocusOnFirst();
    });
  }

  @override
  void dispose() {
    _watchlistSource?.watchlistChanges.removeListener(_onWatchlistChanged);
    for (final node in _libraryMatchFocusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onWatchlistChanged() {
    // ignore: no-empty-block - membership state lives in the source
    setState(() {});
  }

  Future<void> _resolveMatches() async {
    try {
      _setMatches(await context.read<CatalogLibraryMatcher>().match(widget.item));
    } catch (e) {
      appLogger.w('Catalog library match failed for ${widget.item.identityKey}', error: e);
      _setMatches(const []);
    }
  }

  void _setMatches(List<MediaItem> matches) {
    if (!mounted) return;
    for (final node in _libraryMatchFocusNodes) {
      node.dispose();
    }
    _libraryMatchFocusNodes = [
      for (var index = 0; index < matches.length; index++)
        FocusNode(
          debugLabel: 'catalog_library_match_$index',
          onKeyEvent: (node, event) => _handleLibraryMatchKey(index, event),
        ),
    ];
    setState(() => _matches = matches);
  }

  CatalogSource? get _ownSource =>
      context.read<CatalogSourcesProvider>().connectedSources.firstWhereOrNull((s) => s.id == widget.item.source);

  /// One lazy request against the item's own source; failures just leave the
  /// section hidden.
  Future<void> _loadCast() async {
    final source = _ownSource;
    if (source == null) return;
    try {
      final cast = await source.fetchCast(widget.item);
      if (mounted) setState(() => _cast = cast);
    } catch (e) {
      appLogger.d('Catalog cast load failed for ${widget.item.identityKey}', error: e);
    }
  }

  /// One lazy request against the item's own source; failures just leave the
  /// row hidden.
  Future<void> _loadRelated() async {
    final source = _ownSource;
    if (source == null) return;
    try {
      final related = await source.fetchRelated(widget.item);
      if (mounted) setState(() => _related = related);
    } catch (e) {
      appLogger.d('Catalog related load failed for ${widget.item.identityKey}', error: e);
    }
  }

  bool get _hasActions => _watchlistSource != null || _requestSource != null;

  bool get _hasLibraryMatches => _libraryMatchFocusNodes.isNotEmpty;

  void _revealFocusNode(FocusNode? node, {double alignment = 0.3}) {
    final focusContext = node?.context;
    if (focusContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        focusContext,
        alignment: alignment,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  void _requestLibraryMatchFocus(int index) {
    if (index < 0 || index >= _libraryMatchFocusNodes.length) return;
    final node = _libraryMatchFocusNodes[index];
    node.requestFocus();
    _revealFocusNode(node);
  }

  bool _focusSectionBelowLibraryMatches() {
    if (_cast?.isNotEmpty ?? false) {
      _requestCastFocus();
      return true;
    }
    if (_related?.isNotEmpty ?? false) {
      _requestRelatedFocus();
      return true;
    }
    return false;
  }

  KeyEventResult _handleLibraryMatchKey(int index, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key.isUpKey) {
      if (index > 0) {
        _requestLibraryMatchFocus(index - 1);
      } else if (_hasActions) {
        _requestActionBarFocus();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      if (index + 1 < _libraryMatchFocusNodes.length) {
        _requestLibraryMatchFocus(index + 1);
      } else if (!_focusSectionBelowLibraryMatches()) {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _requestCastFocus() {
    if (!(_cast?.isNotEmpty ?? false)) return;
    _castStripKey.currentState?.requestFocus();
    final sectionContext = _castSectionKey.currentContext;
    if (sectionContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        sectionContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  void _requestActionBarFocus() {
    _actionBarKey.currentState?.requestFocusOnFirst();
    if (!_scrollController.hasClients) return;
    unawaited(_scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
  }

  void _requestRelatedFocus() {
    _relatedSectionKey.currentState?.requestFocusFromMemory();
  }

  void _focusSectionBelowActions() {
    if (_hasLibraryMatches) {
      _requestLibraryMatchFocus(0);
    } else if (_cast?.isNotEmpty ?? false) {
      _requestCastFocus();
    } else {
      _requestRelatedFocus();
    }
  }

  void _focusSectionAboveCast() {
    if (_hasLibraryMatches) {
      _requestLibraryMatchFocus(_libraryMatchFocusNodes.length - 1);
    } else {
      _requestActionBarFocus();
    }
  }

  void _focusSectionAboveRelated() {
    if (_cast?.isNotEmpty ?? false) {
      _requestCastFocus();
    } else if (_hasLibraryMatches) {
      _requestLibraryMatchFocus(_libraryMatchFocusNodes.length - 1);
    } else {
      _requestActionBarFocus();
    }
  }

  bool? get _isOnWatchlist => _watchlistSource?.isOnWatchlist(widget.item.kind, widget.item.ids);

  Future<void> _toggleWatchlist() async {
    final source = _watchlistSource;
    final current = _isOnWatchlist;
    if (source == null || current == null || _mutatingWatchlist) return;
    _mutatingWatchlist = true;
    try {
      if (current) {
        await source.removeFromWatchlist(widget.item.kind, widget.item.ids);
      } else {
        await source.addToWatchlist(widget.item.kind, widget.item.ids);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.explore.watchlistUpdateFailed);
    } finally {
      _mutatingWatchlist = false;
    }
  }

  Widget _buildLibraryMatchTile(MediaItem match, int index) {
    return FocusableListTile(
      focusNode: _libraryMatchFocusNodes[index],
      dense: false,
      visualDensity: VisualDensity.standard,
      leading: BackendBadge(backend: match.backend, size: 24),
      // Plex matches carry their library title; Jellyfin's search-based
      // lookup doesn't, so fall back to the server name alone.
      title: Text(match.libraryTitle ?? match.serverName ?? match.backend.name),
      subtitle: match.libraryTitle != null && match.serverName != null ? Text(match.serverName!) : null,
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => unawaited(navigateToMediaItemDetails(context, match)),
    );
  }

  /// Library availability, resolved in place: a progress row while the
  /// matcher runs, "Not in your library" when nothing matched, otherwise an
  /// "In these libraries" list whose rows open the normal media detail
  /// screen. Rows are focusable tiles (dpad-safe, background focus effect).
  Widget _buildLibrarySection(ThemeData theme) {
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5));
    final matches = _matches;

    if (matches == null) {
      return Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Text(t.explore.checkingLibrary, style: mutedStyle),
        ],
      );
    }

    if (matches.isEmpty) {
      return Row(
        children: [
          AppIcon(Symbols.info_rounded, fill: 1, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(t.explore.notInLibrary, style: mutedStyle),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(t.explore.inTheseLibraries, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // M3E grouped cards, same row anatomy as the settings/trackers hub:
        // server-type logo leading, name, chevron trailing.
        SettingsGroup(
          margin: EdgeInsets.zero,
          children: [
            for (var index = 0; index < matches.length; index++) _buildLibraryMatchTile(matches[index], index),
          ],
        ),
      ],
    );
  }

  String get _metaLine {
    final item = widget.item;
    final parts = <String>[
      if (item.year != null) '${item.year}',
      if (item.runtimeMinutes != null) formatDurationTextual(Duration(minutes: item.runtimeMinutes!).inMilliseconds),
      if (item.certification != null && item.certification!.isNotEmpty) item.certification!,
    ];
    return parts.join(' • ');
  }

  static String _statusLabel(CatalogAirStatus status) => switch (status) {
    CatalogAirStatus.airing => t.explore.status.airing,
    CatalogAirStatus.ended => t.explore.status.ended,
    CatalogAirStatus.canceled => t.explore.status.canceled,
    CatalogAirStatus.upcoming => t.explore.status.upcoming,
  };

  /// Score (with a compact vote count), airing status, episode count, and
  /// network/studio — all data that rode along on the row fetch.
  Widget? _buildStatsChips(ThemeData theme) {
    final item = widget.item;
    String? score;
    if (item.rating != null) {
      score = item.rating!.toStringAsFixed(1);
      if (item.votes != null && item.votes! > 0) {
        final compactVotes = NumberFormat.compact(locale: LocaleSettings.currentLocale.languageCode);
        score = '$score (${compactVotes.format(item.votes)})';
      }
    }
    final chips = <Widget>[
      if (score != null) StatChip(icon: Symbols.star_rounded, iconColor: Colors.amber, label: score),
      if (item.airStatus != null) StatChip(label: _statusLabel(item.airStatus!)),
      if (item.episodeCount != null) StatChip(label: t.explore.episodeCount(n: item.episodeCount!)),
      if (item.network != null) StatChip(label: item.network!),
    ];
    if (chips.isEmpty) return null;
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  /// Horizontal cast strip — the same [CastMemberStrip] cards as the media
  /// detail screen. Trakt serves actors with their character; MAL serves
  /// characters with their role, so the section is titled accordingly.
  Widget _buildCastSection(ThemeData theme, List<CatalogCastMember> cast) {
    return Column(
      key: _castSectionKey,
      crossAxisAlignment: .start,
      children: [
        Text(
          widget.item.source == CatalogSourceId.mal ? t.explore.characters : t.explore.cast,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        CastMemberStrip(
          key: _castStripKey,
          members: [
            for (final member in cast) (name: member.name, secondary: member.secondary, imagePath: member.imageUrl),
          ],
          onNavigateUp: _hasLibraryMatches || _hasActions ? _focusSectionAboveCast : null,
          onNavigateDown: (_related?.isNotEmpty ?? false) ? _requestRelatedFocus : null,
          debugLabel: 'catalog_cast_row',
        ),
      ],
    );
  }

  /// "More like this" from the item's own source, rendered through the
  /// standard shelf so cards, long-press menus, and taps behave exactly like
  /// the Explore rows (tap opens another catalog detail screen).
  Widget _buildRelatedSection(List<CatalogItem> related) {
    return HubSection(
      key: _relatedSectionKey,
      hub: MediaHub(
        id: 'catalog-related:${widget.item.source.name}:${widget.item.identityKey}',
        identifier: 'explore.related',
        title: t.discover.moreLikeThis,
        type: 'mixed',
        items: [for (final item in related) item.toMediaItem()],
        size: related.length,
      ),
      icon: Symbols.recommend_rounded,
      inset: true,
      onNavigateUp: _focusSectionAboveRelated,
      cardSizing: HubCardSizing.grid,
    );
  }

  void _handleSystemBack() {
    if (BackKeyCoordinator.consumeIfHandled()) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final onWatchlist = _isOnWatchlist;

    final viewInsets = MediaQuery.paddingOf(context);
    final blockSystemBack = PlatformDetector.isTV() || InputModeTracker.shouldBlockSystemBack(context);
    // Match the established detail-screen back policy: TV/keyboard back is
    // owned by the focus tree, while native mobile back and iOS swipe-back
    // remain route-driven. The overlay host always gets first refusal.
    return OverlaySheetHost(
      canPop: !blockSystemBack,
      onSystemBack: _handleSystemBack,
      child: Builder(
        builder: (hostContext) => Focus(
          onKeyEvent: (_, event) => handleBackKeyNavigation(hostContext, event),
          child: Scaffold(
            body: Stack(
              children: [
                SingleChildScrollView(
                  key: const Key('catalog_detail_scroll'),
                  controller: _scrollController,
                  // The backdrop lives inside the scrollable so it moves with
                  // the content (it extends under the status bar, so the safe
                  // areas are baked into the content padding instead of a
                  // SafeArea around the scroll view).
                  child: Stack(
                    children: [
                      if (item.backdropUrl != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 320,
                          child: ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black, Colors.black.withValues(alpha: 0.0)],
                              stops: const [0.3, 1.0],
                            ).createShader(rect),
                            blendMode: BlendMode.dstIn,
                            child: OptimizedMediaImage.thumb(
                              imagePath: item.backdropUrl,
                              width: double.infinity,
                              height: 320,
                              fit: BoxFit.cover,
                              fallbackIcon: null,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, viewInsets.top + 120, 24, viewInsets.bottom + 32),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Row(
                              crossAxisAlignment: .start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: OptimizedMediaImage.poster(imagePath: item.posterUrl, width: 140, height: 210),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: theme.textTheme.headlineMedium,
                                        maxLines: 3,
                                        overflow: .ellipsis,
                                      ),
                                      if (_metaLine.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _metaLine,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                      if (item.genres?.isNotEmpty ?? false) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          item.genres!.join(' • '),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      if (_watchlistSource != null || _requestSource != null)
                                        FocusableActionBar(
                                          key: _actionBarKey,
                                          onNavigateDown: _focusSectionBelowActions,
                                          actions: [
                                            if (_watchlistSource != null)
                                              FocusableAction(
                                                icon: onWatchlist ?? false
                                                    ? Symbols.bookmark_added_rounded
                                                    : Symbols.bookmark_add_rounded,
                                                tooltip: onWatchlist ?? false
                                                    ? t.explore.removeFromWatchlist
                                                    : t.explore.addToWatchlist,
                                                onPressed: onWatchlist == null
                                                    ? () {}
                                                    : () => unawaited(_toggleWatchlist()),
                                              ),
                                            if (_requestSource case final SeerrCatalogSource seerr)
                                              FocusableAction(
                                                icon: Symbols.download_rounded,
                                                tooltip: t.seerr.request,
                                                onPressed: () => unawaited(
                                                  showSeerrRequestSheet(
                                                    hostContext,
                                                    source: seerr,
                                                    kind: item.kind,
                                                    tmdbId: item.ids.tmdb!,
                                                    title: item.title,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_buildStatsChips(theme) case final Widget chips) ...[const SizedBox(height: 20), chips],
                            const SizedBox(height: 24),
                            if (item.overview != null) Text(item.overview!, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 24),
                            _buildLibrarySection(theme),
                            if (_cast case final List<CatalogCastMember> cast when cast.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _buildCastSection(theme, cast),
                            ],
                            if (_related case final List<CatalogItem> related when related.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildRelatedSection(related),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: DesktopAppBarHelper.buildAdjustedLeading(
                    const AppBarBackButton(style: BackButtonStyle.circular),
                    context: hostContext,
                  )!,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
