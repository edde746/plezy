import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
import '../services/playback_coordinator.dart';
import '../services/settings_service.dart';
import '../services/theme_song_controller.dart';
import '../utils/debouncer.dart';
import '../utils/layout_constants.dart';
import 'package:provider/provider.dart';
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
            gridSpacing: settings.read(SettingsService.gridSpacing),
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
            widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
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
                  child: ValueListenableBuilder<MediaItem?>(
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
                  builder: (context, animatedBleed, child) =>
                      Positioned(top: 0, bottom: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
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
