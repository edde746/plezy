import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_icon.dart';
import '../i18n/strings.g.dart';
import '../media/catalog_item_ref.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_role.dart';
import '../media/media_server_client.dart';
import '../models/catalog/catalog_item.dart';
import '../navigation/main_screen_scope.dart';
import '../navigation/profile_navigation_scope.dart';
import '../services/music/music_playback_service.dart';
import '../services/playback_coordinator.dart';
import '../services/settings_service.dart';
import '../services/theme_song_controller.dart';
import '../utils/debouncer.dart';
import '../utils/layout_constants.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import 'cast_member_strip.dart';
import 'tv_browse_rail.dart';
import 'tv_spotlight_background.dart';

class TvSpotlightController extends ValueNotifier<MediaItem?> {
  TvSpotlightController({Duration settleDelay = const Duration(milliseconds: 150)})
    : _settleDelay = settleDelay,
      _debouncer = Debouncer(settleDelay),
      super(null);

  final Duration _settleDelay;
  final Debouncer _debouncer;

  MediaHub? _hub;

  /// The row the spotlighted item was focused in, when the caller knows it.
  /// The same title can sit in several rows (a movie in both a merged
  /// Recently Released row and a Plex hub), so the item alone can't say which
  /// row's Hero setting applies.
  MediaHub? get hub => _hub;

  void select(MediaItem item, {MediaHub? hub}) {
    void apply() {
      final sameHub = hubIdentityOf(_hub) == hubIdentityOf(hub);
      if (value?.globalKey == item.globalKey && sameHub) return;
      _hub = hub;
      if (value?.globalKey == item.globalKey) {
        notifyListeners();
      } else {
        value = item;
      }
    }

    if (_settleDelay == Duration.zero) {
      apply();
    } else {
      _debouncer.run(apply);
    }
  }

  MediaItem? resolve(Iterable<MediaHub> hubs) {
    MediaItem? fallback;
    final current = value;
    for (final hub in hubs) {
      if (hub.items.isEmpty) continue;
      fallback ??= hub.items.first;
      if (current == null) continue;
      for (final item in hub.items) {
        if (item.globalKey == current.globalKey) return item;
      }
    }
    return fallback;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

/// Stable identity for a hub across reloads (hub objects are rebuilt on every
/// refresh), matching the identity the TV screens key their focus state by.
String? hubIdentityOf(MediaHub? hub) => hub == null ? null : '${hub.serverId ?? ''}:${hub.identifier ?? hub.id}';

typedef TvSpotlightClientResolver = MediaServerClient? Function(MediaItem? item);

/// Shared full-screen TV backdrop and foreground stack used by hub rails.
class TvSpotlightScaffold extends StatelessWidget {
  const TvSpotlightScaffold({
    super.key,
    required this.hubs,
    required this.spotlightListenable,
    required this.resolveSpotlight,
    required this.resolveClient,
    required this.foreground,
    this.hideSpoilers,
    this.additionalForegroundHeight = 0,
  });

  final List<MediaHub> hubs;
  final ValueListenable<MediaItem?> spotlightListenable;
  final MediaItem? Function() resolveSpotlight;
  final TvSpotlightClientResolver resolveClient;
  final Widget foreground;

  final bool? hideSpoilers;
  final double additionalForegroundHeight;

  /// The spotlighted item only carries its own data, not which hub it came
  /// from — needed to check that hub's Hero setting, the same way
  /// `TvSpotlightController.resolve` already scans `hubs` to find the item
  /// itself.
  MediaHub? _hubFor(MediaItem item) {
    final listenable = spotlightListenable;
    final focusedHub = listenable is TvSpotlightController ? listenable.hub : null;
    if (focusedHub != null) {
      final identity = hubIdentityOf(focusedHub);
      for (final hub in hubs) {
        if (hubIdentityOf(hub) == identity && hub.items.any((i) => i.globalKey == item.globalKey)) return hub;
      }
    }
    for (final hub in hubs) {
      if (hub.items.any((i) => i.globalKey == item.globalKey)) return hub;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final settings = SettingsService.instance;
    final scale = TvLayoutConstants.scaleForSize(size);
    final railSize = MainScreenFocusScope.foregroundSizeOf(context);
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    final railHeight = hubs.isEmpty
        ? 0.0
        : TvBrowseRailLayout.estimateHeight(
            size: railSize,
            hubs: hubs,
            density: settings.read(SettingsService.libraryDensity),
            episodePosterMode: settings.read(SettingsService.episodePosterMode),
            fullCardLayout: settings.read(SettingsService.tvFullCardLayout),
            gridSpacing: settings.read(SettingsService.gridSpacing),
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
            widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
          );
    final spotlightTop = (size.height * 0.075).clamp(64.0 * scale, 120.0 * scale).toDouble();
    final minimumSpotlightBottom = railHeight + additionalForegroundHeight + (8 * scale);
    final baseSpotlightBottom = (size.height * 0.48).clamp(160.0, 820.0).toDouble();
    final desiredSpotlightBottom = minimumSpotlightBottom > baseSpotlightBottom
        ? minimumSpotlightBottom
        : baseSpotlightBottom;
    final maxSpotlightBottom = (size.height - spotlightTop - (96 * scale)).clamp(0.0, double.infinity).toDouble();
    final spotlightBottom = desiredSpotlightBottom > maxSpotlightBottom ? maxSpotlightBottom : desiredSpotlightBottom;
    final spotlightLeft = (24 * scale).clamp(18.0, 40.0).toDouble();

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Builder(
              builder: (context) {
                final foregroundLeft = MainScreenFocusScope.foregroundLeftOf(context);
                return SideNavigationBleedBuilder(
                  targetBleed: foregroundLeft,
                  child: ValueListenableBuilder<MediaItem?>(
                    valueListenable: spotlightListenable,
                    builder: (context, _, _) {
                      final spotlight = resolveSpotlight();
                      final spotlightHub = spotlight == null ? null : _hubFor(spotlight);
                      final isHeroRow = spotlightHub?.heroStyle ?? false;
                      // Position within the hub's own item list, purely to
                      // decide which chevron (if either) to draw — a visual
                      // "there's more this way" hint mirroring PC's hero
                      // card arrows, not a click target; actual paging is
                      // still driven by the rail's own d-pad handling.
                      final spotlightIndex = (spotlight == null || spotlightHub == null)
                          ? -1
                          : spotlightHub.items.indexWhere((i) => i.globalKey == spotlight.globalKey);
                      return _CatalogSpotlightBackground(
                        item: spotlight,
                        client: resolveClient(spotlight),
                        hideSpoilers: hideSpoilers ?? settings.read(SettingsService.hideSpoilers),
                        // Hero rows put the info at the top, in the same band
                        // plain rows use (just below the row label), and keep
                        // the bottom for the cast bubbles.
                        contentTop: isHeroRow ? spotlightTop + 30 * scale : spotlightTop,
                        contentBottom: spotlightBottom,
                        labelTop: spotlightTop,
                        castTop: size.height - spotlightBottom + 12 * scale,
                        showCast: isHeroRow && settings.read(SettingsService.tvHeroCastBubbles),
                        contentLeft: spotlightLeft + foregroundLeft,
                        targetWidthPx: (size.width * MediaQuery.devicePixelRatioOf(context)).ceil(),
                        // "Hero" (banner) treatment — full title/logo/summary —
                        // is reserved for hubs the user has
                        // actually marked Hero in the Organizer, same as PC's
                        // HeroHubSection vs a plain HubSection. A non-hero row
                        // keeps its own poster size and gets a plain backdrop only
                        // (showInfo: false below), never the banner.
                        isHeroRow: isHeroRow,
                        hubTitle: spotlightHub?.title,
                        hasPrevious: isHeroRow && spotlightIndex > 0,
                        hasNext:
                            isHeroRow && spotlightIndex >= 0 && spotlightIndex < (spotlightHub?.items.length ?? 0) - 1,
                      );
                    },
                  ),
                  builder: (context, animatedBleed, child) => PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    start: -animatedBleed,
                    width: fullBleedWidth,
                    child: child!,
                  ),
                );
              },
            ),
            foreground,
            _TvSpotlightThemeSongListener(
              spotlightListenable: spotlightListenable,
              resolveSpotlight: resolveSpotlight,
              resolveClient: resolveClient,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogSpotlightBackground extends StatefulWidget {
  const _CatalogSpotlightBackground({
    required this.item,
    required this.client,
    required this.hideSpoilers,
    required this.contentTop,
    required this.contentBottom,
    required this.contentLeft,
    required this.targetWidthPx,
    required this.isHeroRow,
    this.labelTop,
    this.castTop = 0,
    this.showCast = false,
    this.hubTitle,
    this.hasPrevious = false,
    this.hasNext = false,
  });

  final double? labelTop;
  final double castTop;
  final bool showCast;
  final MediaItem? item;
  final MediaServerClient? client;
  final bool hideSpoilers;
  final double contentTop;
  final double contentBottom;
  final double contentLeft;
  final int targetWidthPx;
  final bool isHeroRow;
  // The row's own name (e.g. "Continue Watching") — shown as a small label
  // on the banner now that hero rows no longer have a visible header of
  // their own in the rail (per user request 2026-09-10: "the banner is the
  // row"), so this is the only place that name still appears.
  final String? hubTitle;
  final bool hasPrevious;
  final bool hasNext;

  @override
  State<_CatalogSpotlightBackground> createState() => _CatalogSpotlightBackgroundState();
}

class _CatalogSpotlightBackgroundState extends State<_CatalogSpotlightBackground> {
  CatalogItem? _catalogItem;
  MediaItem? _renderItem;
  Color? _accentColor;

  @override
  void initState() {
    super.initState();
    _rehydrateCatalogItem();
  }

  @override
  void didUpdateWidget(_CatalogSpotlightBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.item, oldWidget.item)) {
      _rehydrateCatalogItem();
    } else if (widget.targetWidthPx != oldWidget.targetWidthPx) {
      _projectArtwork();
    }
  }

  void _rehydrateCatalogItem() {
    _catalogItem = widget.item?.catalogItem;
    _projectArtwork();
  }

  void _projectArtwork() {
    final item = widget.item;
    final catalogItem = _catalogItem;
    if (item == null || catalogItem == null) {
      _renderItem = item;
      _accentColor = null;
      return;
    }

    final bannerUrl = catalogItem.bannerUrl;
    final backdrop = bannerUrl != null && bannerUrl.isNotEmpty
        ? bannerUrl
        : catalogItem.backdropFor(widget.targetWidthPx);
    final logoUrl = catalogItem.logoUrl;
    _renderItem = item.copyWith(
      artPath: backdrop ?? item.artPath,
      backdropPaths: backdrop == null ? item.backdropPaths : [backdrop],
      clearLogoPath: logoUrl != null && logoUrl.isNotEmpty ? logoUrl : null,
    );
    _accentColor = _parseAccentColor(catalogItem.accentColor);
  }

  Color? _parseAccentColor(String? value) {
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value ?? '');
    final hex = match?.group(1);
    if (hex == null) return null;
    return Color(0xff000000 | int.parse(hex, radix: 16));
  }

  Widget? _buildNextEpisodeMetadata(BuildContext context) {
    final nextEpisode = _catalogItem?.nextEpisode;
    if (nextEpisode == null) return null;
    final duration = formatDurationTextual(nextEpisode.timeUntil(DateTime.now()).inMilliseconds);
    final episode = nextEpisode.episode;
    final label = episode == null
        ? t.explore.badge.nextAiringIn(duration: duration)
        : t.explore.badge.nextEpisodeIn(episode: episode, duration: duration);
    final scale = TvLayoutConstants.scaleOf(context);
    return Text(
      label,
      maxLines: 1,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  /// Purely a "there's more this way" visual hint over the static poster,
  /// mirroring PC's hero card chevrons — d-pad still does the actual
  /// paging via the rail's own key handling, so these aren't tap targets.
  /// The row's own name — e.g. "Continue Watching" — since hero rows no
  /// longer have a visible header of their own in the rail (the banner
  /// fully replaces it). Sits in the free space above the bottom-aligned
  /// title block, within the same safe-for-text left band
  /// TvSpotlightBackground's own info block already respects.
  Widget _buildHubLabel(BuildContext context) {
    final title = widget.hubTitle;
    if (title == null || title.isEmpty) return const SizedBox.shrink();
    final scale = TvLayoutConstants.scaleOf(context);
    final theme = Theme.of(context);
    return PositionedDirectional(
      start: widget.contentLeft,
      end: 24 * scale,
      top: widget.labelTop ?? widget.contentTop,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: 15 * scale,
        ),
      ),
    );
  }

  Widget _buildChevron(BuildContext context, {required AlignmentDirectional alignment}) {
    final scale = TvLayoutConstants.scaleOf(context);
    final size = 44 * scale;
    // contentLeft includes the side nav's reserved width, so the leading hint
    // sits inside the content area instead of over the nav.
    final isStart = alignment.start < 0;
    final pointsLeft = isStart != (Directionality.of(context) == TextDirection.rtl);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: isStart
            ? EdgeInsetsDirectional.only(
                start: (widget.contentLeft - size - 8 * scale).clamp(16 * scale, double.infinity),
              )
            : EdgeInsetsDirectional.only(end: 16 * scale),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.38), shape: BoxShape.circle),
          child: AppIcon(
            pointsLeft ? Symbols.chevron_left_rounded : Symbols.chevron_right_rounded,
            color: Colors.white,
            size: size * 0.68,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _accentColor;
    final background = TvSpotlightBackground(
      item: _renderItem,
      client: widget.client,
      hideSpoilers: widget.hideSpoilers,
      contentTop: widget.contentTop,
      contentBottom: widget.contentBottom,
      contentLeft: widget.contentLeft,
      compact: true,
      // Every focused item gets its title/facts (hero or not — only the
      // bigger banner reservation is hero-gated, per 2026-09-10 feedback).
      showInfo: true,
      metadataTrailing: _buildNextEpisodeMetadata(context),
    );
    final themed = accentColor == null
        ? background
        : Theme(
            data: theme.copyWith(
              scaffoldBackgroundColor: Color.alphaBlend(
                accentColor.withValues(alpha: 0.18),
                theme.scaffoldBackgroundColor,
              ),
            ),
            child: background,
          );
    if (!widget.isHeroRow) return themed;
    return Stack(
      fit: StackFit.expand,
      children: [
        themed,
        _buildHubLabel(context),
        if (widget.showCast && widget.item != null)
          PositionedDirectional(
            start: widget.contentLeft,
            end: 0,
            top: widget.castTop,
            child: _HeroCastRow(item: widget.item!, client: widget.client),
          ),
        if (widget.hasPrevious) _buildChevron(context, alignment: AlignmentDirectional.centerStart),
        if (widget.hasNext) _buildChevron(context, alignment: AlignmentDirectional.centerEnd),
      ],
    );
  }
}

/// The cast for a TV hero banner, drawn with the details page's own
/// [CastMemberStrip] so it looks identical. Display only: the rail keeps the
/// d-pad, so the strip is excluded from focus and pointer input.
///
/// Hub items carry at most a few cast names without photos, so the full item
/// is fetched once per title (after a short settle delay, so auto-slide and
/// fast paging don't fire a request per card) and cached for the session.
class _HeroCastRow extends StatefulWidget {
  const _HeroCastRow({required this.item, required this.client});

  final MediaItem item;
  final MediaServerClient? client;

  @override
  State<_HeroCastRow> createState() => _HeroCastRowState();
}

class _HeroCastRowState extends State<_HeroCastRow> {
  static final Map<String, List<MediaRole>> _cache = {};
  static const _maxCached = 200;

  Timer? _settle;
  List<MediaRole> _roles = const [];

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_HeroCastRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.globalKey != widget.item.globalKey) _resolve();
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _resolve() {
    _settle?.cancel();
    final item = widget.item;
    final cached = _cache[item.globalKey];
    if (cached != null) {
      setState(() => _roles = cached);
      return;
    }
    setState(() => _roles = const []);
    final client = widget.client;
    if (client == null) return;
    _settle = Timer(const Duration(milliseconds: 400), () async {
      try {
        final full = await client.fetchItem(item.id);
        final roles = [
          for (final role in full?.roles ?? const <MediaRole>[])
            if (role.tag.trim().isNotEmpty) role,
        ];
        if (_cache.length >= _maxCached) _cache.remove(_cache.keys.first);
        _cache[item.globalKey] = roles;
        if (mounted && widget.item.globalKey == item.globalKey) setState(() => _roles = roles);
      } catch (_) {
        // No cast is fine; the banner still shows its info.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = TvLayoutConstants.scaleOf(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _roles.isEmpty
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : ExcludeFocus(
              key: ValueKey(widget.item.globalKey),
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AppIcon(Symbols.group_rounded, size: 20 * scale, color: theme.colorScheme.onSurface),
                        SizedBox(width: 8 * scale),
                        Text(
                          t.discover.cast,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),
                    CastMemberStrip(
                      members: [
                        for (final role in _roles) (name: role.tag, secondary: role.role, imagePath: role.thumbPath),
                      ],
                      imageClient: widget.client,
                      debugLabel: 'hero_cast_row',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Pins a toolbar to the top of the viewport across the full bleed width,
/// sliding with the sidebar so it stays put while the content box translates.
///
/// Excluded from default focus traversal so that initial/tab-switch focus
/// lands on content (hero/rails) rather than the toolbar; its buttons stay
/// reachable via explicit UP from the content. Reads the offset aspect from
/// its own element, so a sidebar flip rebuilds only this overlay.
class TvToolbarOverlay extends StatelessWidget {
  const TvToolbarOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    return SideNavigationBleedBuilder(
      targetBleed: MainScreenFocusScope.sideNavigationBleedOf(context),
      child: ExcludeFocusTraversal(child: child),
      builder: (context, animatedBleed, child) =>
          PositionedDirectional(top: 0, start: -animatedBleed, width: fullBleedWidth, child: child!),
    );
  }
}

/// Plays the focused item's theme while its spotlight is actually visible.
/// TickerMode covers tab changes; RouteAware covers detail/settings routes.
class _TvSpotlightThemeSongListener extends StatefulWidget {
  const _TvSpotlightThemeSongListener({
    required this.spotlightListenable,
    required this.resolveSpotlight,
    required this.resolveClient,
  });

  final ValueListenable<MediaItem?> spotlightListenable;
  final MediaItem? Function() resolveSpotlight;
  final TvSpotlightClientResolver resolveClient;

  @override
  State<_TvSpotlightThemeSongListener> createState() => _TvSpotlightThemeSongListenerState();
}

class _TvSpotlightThemeSongListenerState extends State<_TvSpotlightThemeSongListener>
    with WidgetsBindingObserver, RouteAware {
  static const _themeRequestDelay = Duration(milliseconds: 350);

  PageRoute<dynamic>? _route;
  RouteObserver<PageRoute<dynamic>>? _routeObserver;
  MusicPlaybackService? _music;
  SettingsService? _settings;
  ValueListenable<bool>? _themeEnabled;
  ValueListenable<double>? _themeVolume;
  bool _routeVisible = false;
  bool _tabVisible = true;
  String? _requestedGlobalKey;
  Timer? _requestTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.spotlightListenable.addListener(_onSpotlightChanged);
    PlaybackCoordinator.instance.videoSessionActive.addListener(_updateThemeSong);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabVisible = TickerMode.valuesOf(context).enabled;
    final route = ModalRoute.of(context);
    final observer = ProfileNavigationScope.maybeOf(context)?.routeObserver;
    if (route != _route || observer != _routeObserver) {
      _routeObserver?.unsubscribe(this);
      _route = route is PageRoute<dynamic> ? route : null;
      _routeObserver = observer;
      _routeVisible = _route?.isCurrent ?? false;
      if (_route != null && observer != null) observer.subscribe(this, _route!);
    }
    final music = context.read<MusicPlaybackService?>();
    if (_music != music) {
      _music?.removeListener(_updateThemeSong);
      _music = music;
      _music?.addListener(_updateThemeSong);
    }
    final settings = SettingsService.instanceOrNull;
    if (_settings != settings) {
      _themeEnabled?.removeListener(_updateThemeSong);
      _themeVolume?.removeListener(_onThemeVolumeChanged);
      _settings = settings;
      _themeEnabled = settings?.listenable(SettingsService.themeSongsEnabled);
      _themeVolume = settings?.listenable(SettingsService.themeSongVolume);
      _themeEnabled?.addListener(_updateThemeSong);
      _themeVolume?.addListener(_onThemeVolumeChanged);
    }
    _updateThemeSong();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _updateThemeSong();

  @override
  void didPush() {
    _routeVisible = true;
    _updateThemeSong();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _updateThemeSong();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _updateThemeSong();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _updateThemeSong();
  }

  void _onSpotlightChanged() {
    _requestedGlobalKey = null;
    _updateThemeSong();
  }

  void _onThemeVolumeChanged() {
    final settings = _settings;
    if (settings != null && _requestedGlobalKey != null) {
      unawaited(ThemeSongController.instance.setVolume(settings.read(SettingsService.themeSongVolume)));
    }
  }

  void _updateThemeSong() {
    _requestTimer?.cancel();
    final settings = _settings ?? SettingsService.instanceOrNull;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final visible =
        mounted &&
        _routeVisible &&
        _tabVisible &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive);
    final item = visible ? widget.resolveSpotlight() : null;
    final allowed =
        visible &&
        item != null &&
        item.isVideoContent &&
        (settings?.read(SettingsService.themeSongsEnabled) ?? false) &&
        _music?.currentTrack == null &&
        !PlaybackCoordinator.instance.hasVideoSession;
    if (!allowed) {
      _requestedGlobalKey = null;
      ThemeSongController.instance.release(this, immediate: true);
      return;
    }

    final spotlight = item;
    if (_requestedGlobalKey == spotlight.globalKey) return;
    _requestedGlobalKey = spotlight.globalKey;
    _requestTimer = Timer(_themeRequestDelay, () {
      if (!mounted || !_routeVisible || !_tabVisible || _requestedGlobalKey != spotlight.globalKey) return;
      final client = widget.resolveClient(widget.resolveSpotlight());
      if (client == null) {
        ThemeSongController.instance.release(this, immediate: true);
        return;
      }
      final volume = _settings?.read(SettingsService.themeSongVolume) ?? SettingsService.themeSongVolume.defaultValue;
      unawaited(
        ThemeSongController.instance.request(this, resolveUrl: () => client.getThemeSongUrl(spotlight), volume: volume),
      );
    });
  }

  @override
  void dispose() {
    _requestTimer?.cancel();
    widget.spotlightListenable.removeListener(_onSpotlightChanged);
    _music?.removeListener(_updateThemeSong);
    _themeEnabled?.removeListener(_updateThemeSong);
    _themeVolume?.removeListener(_onThemeVolumeChanged);
    PlaybackCoordinator.instance.videoSessionActive.removeListener(_updateThemeSong);
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver?.unsubscribe(this);
    ThemeSongController.instance.release(this, immediate: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
