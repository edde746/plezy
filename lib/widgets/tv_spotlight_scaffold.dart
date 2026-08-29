import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../media/catalog_item_ref.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../models/catalog/catalog_item.dart';
import '../navigation/main_screen_scope.dart';
import '../navigation/profile_navigation_scope.dart';
import '../services/music/music_playback_service.dart';
import '../services/plex_client.dart';
import '../services/settings_service.dart';
import '../services/theme_music_player.dart';
import '../utils/app_logger.dart';
import '../utils/debouncer.dart';
import '../utils/layout_constants.dart';
import '../utils/formatters.dart';
import 'tv_browse_rail.dart';
import 'tv_spotlight_background.dart';

class TvSpotlightController extends ValueNotifier<MediaItem?> {
  TvSpotlightController({Duration settleDelay = const Duration(milliseconds: 150)})
    : _settleDelay = settleDelay,
      _debouncer = Debouncer(settleDelay),
      super(null);

  final Duration _settleDelay;
  final Debouncer _debouncer;

  void select(MediaItem item) {
    void apply() {
      if (value?.globalKey == item.globalKey) return;
      value = item;
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
  });

  final List<MediaHub> hubs;
  final ValueListenable<MediaItem?> spotlightListenable;
  final MediaItem? Function() resolveSpotlight;
  final TvSpotlightClientResolver resolveClient;
  final Widget foreground;
  final bool? hideSpoilers;

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
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
          );
    final spotlightTop = (size.height * 0.075).clamp(64.0 * scale, 120.0 * scale).toDouble();
    final minimumSpotlightBottom = railHeight + (8 * scale);
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TvSpotlightThemeMusicListener(
                        spotlightListenable: spotlightListenable,
                        resolveSpotlight: resolveSpotlight,
                        resolveClient: resolveClient,
                      ),
                      ValueListenableBuilder<MediaItem?>(
                        valueListenable: spotlightListenable,
                        builder: (context, _, _) {
                          final spotlight = resolveSpotlight();
                          return _CatalogSpotlightBackground(
                            item: spotlight,
                            client: resolveClient(spotlight),
                            hideSpoilers: hideSpoilers ?? settings.read(SettingsService.hideSpoilers),
                            contentTop: spotlightTop,
                            contentBottom: spotlightBottom,
                            contentLeft: spotlightLeft + foregroundLeft,
                            targetWidthPx: (size.width * MediaQuery.devicePixelRatioOf(context)).ceil(),
                          );
                        },
                      ),
                    ],
                  ),
                  builder: (context, animatedBleed, child) =>
                      Positioned(top: 0, bottom: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
                );
              },
            ),
            foreground,
          ],
        ),
      ),
    );
  }
}

class _TvSpotlightThemeMusicListener extends StatefulWidget {
  const _TvSpotlightThemeMusicListener({
    required this.spotlightListenable,
    required this.resolveSpotlight,
    required this.resolveClient,
  });

  final ValueListenable<MediaItem?> spotlightListenable;
  final MediaItem? Function() resolveSpotlight;
  final TvSpotlightClientResolver resolveClient;

  @override
  State<_TvSpotlightThemeMusicListener> createState() => _TvSpotlightThemeMusicListenerState();
}

class _TvSpotlightThemeMusicListenerState extends State<_TvSpotlightThemeMusicListener>
    with WidgetsBindingObserver, RouteAware {
  final Object _themeMusicOwner = Object();
  String? _itemKey;
  PageRoute<dynamic>? _route;
  RouteObserver<PageRoute<dynamic>>? _routeObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.spotlightListenable.addListener(_onSpotlightChanged);
    _onSpotlightChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeObserver = ProfileNavigationScope.maybeOf(context)?.routeObserver;
    final route = ModalRoute.of(context);
    if (routeObserver == null || route is! PageRoute<dynamic> || (route == _route && routeObserver == _routeObserver)) {
      return;
    }
    _routeObserver?.unsubscribe(this);
    _route = route;
    _routeObserver = routeObserver;
    routeObserver.subscribe(this, route);
  }

  void _onSpotlightChanged() {
    final item = widget.resolveSpotlight();
    final ratingKey = item?.isEpisode == true || item?.isSeason == true
      ? item?.grandparentId ?? item?.parentId
      : item?.id;
    final client = widget.resolveClient(item);
    if (item == null || client is! PlexClient || ratingKey == null ||
      !(item.isMovie || item.isShow || item.isSeason || item.isEpisode) ||
        SettingsService.instance.read(SettingsService.themeMusicMode) != ThemeMusicMode.everywhere ||
        context.read<MusicPlaybackService?>()?.isPlaying == true) {
      _itemKey = null;
      unawaited(context.read<ThemeMusicService?>()?.stop(_themeMusicOwner));
      return;
    }
    if (_itemKey == item.globalKey) return;
    _itemKey = item.globalKey;
    appLogger.d('TV theme music: ${item.globalKey} -> $ratingKey');
    unawaited(context.read<ThemeMusicService?>()?.play(_themeMusicOwner, client.themeUrl(ratingKey)));
  }

  @override
  void didPushNext() {
    _itemKey = null;
    unawaited(context.read<ThemeMusicService?>()?.stop(_themeMusicOwner));
  }

  @override
  void didPopNext() => _onSpotlightChanged();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = context.read<ThemeMusicService?>();
    unawaited(state == AppLifecycleState.resumed ? service?.resume(_themeMusicOwner) : service?.pause(_themeMusicOwner));
  }

  @override
  void dispose() {
    widget.spotlightListenable.removeListener(_onSpotlightChanged);
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver?.unsubscribe(this);
    unawaited(context.read<ThemeMusicService?>()?.stop(_themeMusicOwner));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
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
  });

  final MediaItem? item;
  final MediaServerClient? client;
  final bool hideSpoilers;
  final double contentTop;
  final double contentBottom;
  final double contentLeft;
  final int targetWidthPx;

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
    if (widget.item?.globalKey != oldWidget.item?.globalKey) {
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
      metadataTrailing: _buildNextEpisodeMetadata(context),
    );
    if (accentColor == null) return background;
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: Color.alphaBlend(accentColor.withValues(alpha: 0.18), theme.scaffoldBackgroundColor),
      ),
      child: background,
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
          Positioned(top: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
    );
  }
}
