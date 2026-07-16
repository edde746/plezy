import 'dart:async';
import '../../media/ids.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../i18n/strings.g.dart';
import '../../media/live_tv_support.dart';
import '../../media/media_server_client.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_dvr.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_navigation_mixin.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_builder.dart';
import '../../utils/app_logger.dart';
import '../../utils/error_message_utils.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/platform_detector.dart';
import '../../utils/serial_future_queue.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/focusable_tab_chip.dart';
import '../../widgets/overlay_sheet.dart';
import '../libraries/state_messages.dart';
import 'reorder_favorites_sheet.dart';
import 'tabs/guide_tab.dart';
import 'tabs/recordings_tab.dart';
import 'tabs/whats_on_tab.dart';

enum LiveTvTab { guide, whatsOn, recordings }

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen>
    with TickerProviderStateMixin, TabNavigationMixin
    implements FocusableTab {
  final _guideTabFocusNode = FocusNode(debugLabel: 'tab_chip_guide');
  final _whatsOnTabFocusNode = FocusNode(debugLabel: 'tab_chip_whats_on');
  final _recordingsTabFocusNode = FocusNode(debugLabel: 'tab_chip_recordings');
  final _guideTabKey = GlobalKey<GuideTabState>();
  final _whatsOnTabKey = GlobalKey<WhatsOnTabState>();
  final _recordingsTabKey = GlobalKey<RecordingsTabState>();

  /// Visible tabs in the current session. Recordings tab is included only
  /// when at least one Live TV server has `liveTvDvr` capability.
  List<LiveTvTab> _visibleTabs = [LiveTvTab.guide, LiveTvTab.whatsOn];

  // App bar action bar
  final _actionBarKey = GlobalKey<FocusableActionBarState>();

  List<LiveTvChannel> _channels = [];
  bool _isLoading = true;
  String? _error;

  // Favorites
  bool _showFavoritesOnly = false;
  Set<String> _favoriteKeys = {};
  List<FavoriteChannel> _favoriteChannels = [];

  /// Source URI per Live TV server/DVR, built from machineIdentifier + EPG provider identifier.
  final Map<String, String> _favoriteSourceByLiveServer = {};
  final Map<String, String> _favoriteSourceByChannel = {};
  final Map<String, String> _favoriteStoreByLiveServer = {};
  final Map<String, String> _favoriteStoreByChannel = {};
  final Map<String, String> _favoriteStoreBySource = {};
  final Map<String, FavoriteChannelPersistenceMode> _favoriteModeByStore = {};
  Future<void>? _channelsLoadFuture;
  int _favoritesLoadGeneration = 0;
  Future<void>? _favoritesLoadFuture;
  final SerialFutureQueue _favoritesMutationQueue = SerialFutureQueue();
  bool _favoritesLoaded = false;

  List<LiveTvChannel> get _filteredChannels => filterLiveTvChannelsForFavorites(
    channels: _channels,
    favoritesOnly: _showFavoritesOnly,
    favorites: _favoriteChannels,
    sourceForChannel: _sourceForChannel,
  );

  String _liveServerScopeKey(LiveTvServerInfo serverInfo) => '${serverInfo.serverId}\u0000${serverInfo.dvrKey}';

  String _sourceForChannel(LiveTvChannel channel) {
    return channel.favoriteSource ?? _favoriteSourceByChannel[liveTvChannelScopeKey(channel)] ?? '';
  }

  String _favoriteKeyForChannel(LiveTvChannel channel) => favoriteChannelKey(_sourceForChannel(channel), channel.key);

  bool _isFavoriteChannel(LiveTvChannel channel) => _favoriteKeys.contains(_favoriteKeyForChannel(channel));

  void _refreshFavoriteKeys() {
    _favoriteKeys = _favoriteChannels.map((f) => f.stableKey).toSet();
  }

  @override
  List<FocusNode> get tabChipFocusNodes => [for (final tab in _visibleTabs) _focusNodeForTab(tab)];

  FocusNode _focusNodeForTab(LiveTvTab tab) => switch (tab) {
    LiveTvTab.guide => _guideTabFocusNode,
    LiveTvTab.whatsOn => _whatsOnTabFocusNode,
    LiveTvTab.recordings => _recordingsTabFocusNode,
  };

  @override
  void initState() {
    super.initState();
    suppressAutoFocus = true;
    _showFavoritesOnly = context.settingsRead(SettingsService.liveTvDefaultFavorites);
    initTabNavigation();
    _loadChannels();
  }

  @override
  void dispose() {
    _guideTabFocusNode.dispose();
    _whatsOnTabFocusNode.dispose();
    _recordingsTabFocusNode.dispose();
    disposeTabNavigation();
    super.dispose();
  }

  @override
  void onTabChanged() {
    if (!tabController.indexIsChanging) {
      super.onTabChanged();
      // Pause/resume timers based on active tab
      if (tabController.index >= _visibleTabs.length) return;
      switch (_visibleTabs[tabController.index]) {
        case LiveTvTab.guide:
          _whatsOnTabKey.currentState?.pauseRefresh();
          _recordingsTabKey.currentState?.pauseRefresh();
          _guideTabKey.currentState?.resumeRefresh();
        case LiveTvTab.whatsOn:
          _guideTabKey.currentState?.pauseRefresh();
          _recordingsTabKey.currentState?.pauseRefresh();
          _whatsOnTabKey.currentState?.resumeRefresh();
        case LiveTvTab.recordings:
          _guideTabKey.currentState?.pauseRefresh();
          _whatsOnTabKey.currentState?.pauseRefresh();
          _recordingsTabKey.currentState?.resumeRefresh();
      }
    }
  }

  LiveTvTab? get _currentTab {
    if (tabController.index < 0 || tabController.index >= _visibleTabs.length) return null;
    return _visibleTabs[tabController.index];
  }

  /// Tab-aware refresh handler bound to the AppBar refresh button.
  /// - Guide / What's On: server-side `reloadGuide` per DVR-capable client +
  ///   client-side channel re-fetch.
  /// - Recordings: re-fetches scheduled recordings + rules.
  Future<void> _onRefresh() async {
    if (_currentTab == LiveTvTab.recordings) {
      await _recordingsTabKey.currentState?.reload();
      return;
    }
    await _serverReloadGuide();
    await _loadChannels();
  }

  Future<void> _serverReloadGuide() async {
    final multiServer = context.read<MultiServerProvider>();
    final futures = <Future<void>>[];
    for (final serverInfo in multiServer.liveTvServers) {
      final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
      if (client == null || client.liveTvDvr == null) continue;
      futures.add(_reloadGuideSafe(client, serverInfo.dvrKey));
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
    if (!mounted) return;
    showSnackBar(context, t.liveTv.guideReloadRequested);
  }

  Future<void> _reloadGuideSafe(MediaServerClient client, String dvrId) async {
    try {
      final dvr = client.liveTvDvr;
      if (dvr == null) return;
      await dvr.reloadGuide(dvrId);
    } catch (e) {
      // 403 (admin only) and transient errors are non-fatal — caller still
      // re-fetches client-side channels.
      appLogger.d('Reload guide failed for DVR $dvrId: $e');
    }
  }

  Future<void> _processRecordingRules() async {
    final multiServer = context.read<MultiServerProvider>();
    final futures = <Future<void>>[];
    for (final serverInfo in multiServer.liveTvServers) {
      final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
      if (client == null || client.liveTvDvr == null) continue;
      futures.add(_processRulesSafe(client));
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
    if (!mounted) return;
    showSnackBar(context, t.liveTv.rulesProcessRequested);
    await _recordingsTabKey.currentState?.reload();
  }

  Future<void> _processRulesSafe(MediaServerClient client) async {
    try {
      final dvr = client.liveTvDvr;
      if (dvr == null) return;
      await dvr.processRecordingRules();
    } catch (e) {
      appLogger.d('processRecordingRules failed: $e');
    }
  }

  /// Recompute visible tabs from the current MultiServerProvider state.
  /// Re-inits the tab controller when the visible set changes (matches the
  /// libraries-screen pattern at libraries_screen.dart:365).
  void _refreshVisibleTabs(MultiServerProvider multiServer) {
    final hasDvr = multiServer.liveTvServers.any((s) {
      final c = multiServer.getClientForServer(ServerId(s.serverId));
      return c?.liveTvDvr != null;
    });
    final newTabs = [LiveTvTab.guide, LiveTvTab.whatsOn, if (hasDvr) LiveTvTab.recordings];
    if (listEquals(_visibleTabs, newTabs)) return;
    final currentTab = tabController.index < _visibleTabs.length ? _visibleTabs[tabController.index] : null;
    disposeTabNavigation();
    _visibleTabs = newTabs;
    initTabNavigation();
    if (currentTab != null) {
      final newIndex = newTabs.indexOf(currentTab);
      if (newIndex >= 0) tabController.index = newIndex;
    }
  }

  /// Extracts enabled channel keys from DVR mappings, returning null if no DVR has mapping data.
  Set<String>? _extractEnabledChannelKeys(List<LiveTvDvr> dvrs) {
    final enabledKeys = <String>{};
    bool hasMappings = false;
    for (final dvr in dvrs) {
      if (dvr.channelMappings.isEmpty) continue;
      hasMappings = true;
      for (final m in dvr.channelMappings) {
        if (m.enabled == true && m.channelKey != null) {
          enabledKeys.add(m.channelKey!);
        }
      }
    }
    return hasMappings ? enabledKeys : null;
  }

  Set<String>? _extractEnabledChannelKeysForServerInfo(LiveTvServerInfo serverInfo) {
    final matching = serverInfo.dvrs.where((dvr) => dvr.key == serverInfo.dvrKey).toList();
    return _extractEnabledChannelKeys(matching.isNotEmpty ? matching : serverInfo.dvrs);
  }

  String? _sourceTitleForServerInfo(LiveTvServerInfo serverInfo) {
    for (final dvr in serverInfo.dvrs) {
      if (dvr.key == serverInfo.dvrKey) {
        return _nonEmpty(dvr.lineupTitle) ?? _nonEmpty(dvr.lineupURL) ?? _nonEmpty(dvr.lineup);
      }
    }
    return _nonEmpty(serverInfo.lineup);
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _loadChannels() {
    final inFlight = _channelsLoadFuture;
    if (inFlight != null) return inFlight;
    late final Future<void> load;
    load = _loadChannelsOnce().whenComplete(() {
      if (identical(_channelsLoadFuture, load)) _channelsLoadFuture = null;
    });
    _channelsLoadFuture = load;
    return load;
  }

  Future<void> _loadChannelsOnce() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;

      if (liveTvServers.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = t.liveTv.noDvr;
        });
        return;
      }

      final allChannels = <LiveTvChannel>[];
      final seenChannels = <String>{};
      final favoriteSourceByLiveServer = <String, String>{};
      final favoriteSourceByChannel = <String, String>{};
      final favoriteStoreByLiveServer = <String, String>{};
      final favoriteStoreByChannel = <String, String>{};
      final favoriteStoreBySource = <String, String>{};
      final favoriteModeByStore = <String, FavoriteChannelPersistenceMode>{};

      appLogger.d(
        'Live TV DVRs: ${liveTvServers.map((s) => '${s.serverId}/${s.dvrKey} lineup=${s.lineup}').join(', ')}',
      );

      // Build a set of enabled channel keys per Live TV DVR from cached DVR data.
      final enabledKeysByLiveServer = <String, Set<String>>{};
      for (final serverInfo in liveTvServers) {
        final enabledKeys = _extractEnabledChannelKeysForServerInfo(serverInfo);
        if (enabledKeys != null) {
          enabledKeysByLiveServer[_liveServerScopeKey(serverInfo)] = enabledKeys;
        }
      }

      for (final serverInfo in liveTvServers) {
        try {
          final genericClient = multiServer.getClientForServer(ServerId(serverInfo.serverId));
          if (genericClient == null) continue;

          final liveTv = genericClient.liveTv;
          final source = await liveTv.buildFavoriteChannelSource(lineup: serverInfo.lineup);
          final sourceTitle = _sourceTitleForServerInfo(serverInfo);
          final storeKey = liveTv.favoriteStoreKey;
          final liveServerKey = _liveServerScopeKey(serverInfo);
          favoriteSourceByLiveServer[liveServerKey] = source;
          favoriteStoreByLiveServer[liveServerKey] = storeKey;
          favoriteStoreBySource[source] = storeKey;
          favoriteModeByStore[storeKey] = liveTv.favoritePersistenceMode;

          final channels = await genericClient.liveTv.fetchChannels(lineup: serverInfo.lineup);
          // Plex's DVR exposes a separate enabled-channel mapping; Jellyfin
          // already filters to subscribed channels server-side.
          final enabledKeys = enabledKeysByLiveServer[liveServerKey];
          appLogger.d(
            'Channels from ${serverInfo.dvrKey}: ${channels.length} channels (${enabledKeys?.length ?? 'all'} enabled)',
          );
          for (final channel in channels) {
            if (enabledKeys != null && !enabledKeys.contains(channel.key)) continue;
            final scopedChannel = channel.copyWith(
              liveDvrKey: serverInfo.dvrKey,
              liveTvSourceTitle: sourceTitle,
              favoriteSource: source,
              favoriteStoreKey: storeKey,
            );
            final dedupKey = liveTvChannelScopeKey(scopedChannel);
            if (seenChannels.add(dedupKey)) {
              final scopeKey = liveTvChannelScopeKey(scopedChannel);
              favoriteSourceByChannel[scopeKey] = source;
              favoriteStoreByChannel[scopeKey] = storeKey;
              allChannels.add(scopedChannel);
            }
          }
        } catch (e) {
          appLogger.e('Failed to load channels from server ${serverInfo.serverId}', error: e);
        }
      }

      allChannels.sort((a, b) {
        final aNum = double.tryParse(a.number ?? '') ?? 999999;
        final bNum = double.tryParse(b.number ?? '') ?? 999999;
        return aNum.compareTo(bNum);
      });

      if (!mounted) return;

      appLogger.d('Live TV: loaded ${allChannels.length} channels');

      setState(() {
        _channels = allChannels;
        _favoriteSourceByLiveServer
          ..clear()
          ..addAll(favoriteSourceByLiveServer);
        _favoriteSourceByChannel
          ..clear()
          ..addAll(favoriteSourceByChannel);
        _favoriteStoreByLiveServer
          ..clear()
          ..addAll(favoriteStoreByLiveServer);
        _favoriteStoreByChannel
          ..clear()
          ..addAll(favoriteStoreByChannel);
        _favoriteStoreBySource
          ..clear()
          ..addAll(favoriteStoreBySource);
        _favoriteModeByStore
          ..clear()
          ..addAll(favoriteModeByStore);
        _isLoading = false;
      });

      _refreshVisibleTabs(multiServer);

      // Load favorites by backend store: Plex is cloud/account-scoped, Jellyfin per server.
      final favoritesLoad = _loadFavorites(multiServer);
      _favoritesLoadFuture = favoritesLoad;
      unawaited(
        favoritesLoad.whenComplete(() {
          if (identical(_favoritesLoadFuture, favoritesLoad)) {
            _favoritesLoadFuture = null;
          }
        }),
      );

      if (allChannels.isNotEmpty && PlatformDetector.shouldUseSideNavigation(context)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusCurrentTab();
        });
      }
    } catch (e, stackTrace) {
      final message = localizedLoadErrorMessage(e, stackTrace, context: t.liveTv.title);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = message;
        });
      }
    }
  }

  Future<void> _loadFavorites(MultiServerProvider multiServer) async {
    final loadGeneration = ++_favoritesLoadGeneration;
    _favoritesLoaded = false;
    try {
      final sourceByLiveServer = Map<String, String>.of(_favoriteSourceByLiveServer);
      final storeByLiveServer = Map<String, String>.of(_favoriteStoreByLiveServer);
      final storeBySource = Map<String, String>.of(_favoriteStoreBySource);
      final modeByStore = Map<String, FavoriteChannelPersistenceMode>.of(_favoriteModeByStore);
      final merged = <FavoriteChannel>[];
      final fetchedStores = <String>{};
      final seenFavorites = <String>{};
      for (final serverInfo in multiServer.liveTvServers) {
        final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
        if (client == null) continue;
        final liveTv = client.liveTv;
        final source = await liveTv.buildFavoriteChannelSource(lineup: serverInfo.lineup);
        final storeKey = liveTv.favoriteStoreKey;
        final liveServerKey = _liveServerScopeKey(serverInfo);
        sourceByLiveServer[liveServerKey] = source;
        storeByLiveServer[liveServerKey] = storeKey;
        storeBySource[source] = storeKey;
        modeByStore[storeKey] = liveTv.favoritePersistenceMode;
        if (!fetchedStores.add(storeKey)) continue;
        final serverFavorites = await liveTv.fetchFavoriteChannels();
        for (final favorite in serverFavorites) {
          storeBySource[favorite.source] = storeKey;
          if (seenFavorites.add(favorite.stableKey)) merged.add(favorite);
        }
      }

      if (!mounted || loadGeneration != _favoritesLoadGeneration) return;
      setState(() {
        _favoriteSourceByLiveServer
          ..clear()
          ..addAll(sourceByLiveServer);
        _favoriteStoreByLiveServer
          ..clear()
          ..addAll(storeByLiveServer);
        _favoriteStoreBySource
          ..clear()
          ..addAll(storeBySource);
        _favoriteModeByStore
          ..clear()
          ..addAll(modeByStore);
        _favoriteChannels = merged;
        _refreshFavoriteKeys();
      });
      _favoritesLoaded = true;
      appLogger.d('Live TV: loaded ${merged.length} favorite channels');
    } catch (e) {
      appLogger.e('Failed to load favorite channels', error: e);
    }
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
  }

  void _toggleFavorite(LiveTvChannel channel) {
    _enqueueFavoriteMutation(() {
      final source = _sourceForChannel(channel);
      final favoriteKey = favoriteChannelKey(source, channel.key);
      final scopeKey = liveTvChannelScopeKey(channel);
      final storeKey = channel.favoriteStoreKey ?? _favoriteStoreByChannel[scopeKey];
      if (storeKey != null) _favoriteStoreBySource[source] = storeKey;

      setState(() {
        if (_favoriteKeys.contains(favoriteKey)) {
          _favoriteChannels = _favoriteChannels.where((f) => f.id != channel.key || f.source != source).toList();
        } else {
          _favoriteChannels = [..._favoriteChannels, FavoriteChannel.fromLiveTvChannel(channel, source)];
        }
        _refreshFavoriteKeys();
      });
    });
  }

  void _enqueueFavoriteMutation(VoidCallback mutation) {
    final pendingLoad = _favoritesLoadFuture;
    unawaited(
      _favoritesMutationQueue
          .run(() async {
            if (pendingLoad != null) await pendingLoad;
            if (!mounted) return;
            if (!_favoritesLoaded) {
              showErrorSnackBar(context, t.liveTv.favoritesLoadFailed);
              return;
            }
            mutation();
            await _persistFavorites();
          })
          .catchError((Object error, StackTrace stackTrace) {
            appLogger.e('Failed to mutate favorite channels', error: error, stackTrace: stackTrace);
          }),
    );
  }

  void _showReorderFavorites() {
    final channelMap = {for (final c in _channels) _favoriteKeyForChannel(c): c};

    OverlaySheetController.showAdaptive(
      context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => ReorderFavoritesSheet(
        favorites: List.from(_favoriteChannels),
        channelMap: channelMap,
        onReorder: (reordered) {
          _enqueueFavoriteMutation(() {
            setState(() {
              _favoriteChannels = reordered;
              _refreshFavoriteKeys();
            });
          });
        },
        onRemove: (removed) {
          _enqueueFavoriteMutation(() {
            setState(() {
              _favoriteChannels = _favoriteChannels.where((f) => f.stableKey != removed.stableKey).toList();
              _refreshFavoriteKeys();
            });
          });
        },
      ),
    );
  }

  Future<void> _persistFavorites() async {
    final multiServer = context.read<MultiServerProvider>();
    final byStore = <String, List<FavoriteChannel>>{};
    for (final favorite in _favoriteChannels) {
      final storeKey = _favoriteStoreBySource[favorite.source];
      if (storeKey == null) continue;
      byStore.putIfAbsent(storeKey, () => []).add(favorite);
    }
    final writtenStores = <String>{};
    final writes = <Future<void>>[];
    for (final serverInfo in multiServer.liveTvServers) {
      final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
      if (client == null) continue;
      final liveServerKey = _liveServerScopeKey(serverInfo);
      final storeKey = _favoriteStoreByLiveServer[liveServerKey];
      if (storeKey == null || !writtenStores.add(storeKey)) continue;
      final mode = _favoriteModeByStore[storeKey] ?? client.liveTv.favoritePersistenceMode;
      final source = _favoriteSourceByLiveServer[liveServerKey];
      if (source == null) continue;
      final channels = switch (mode) {
        FavoriteChannelPersistenceMode.sharedFullList => byStore[storeKey] ?? const <FavoriteChannel>[],
        FavoriteChannelPersistenceMode.serverSlice =>
          (byStore[storeKey] ?? const <FavoriteChannel>[]).where((favorite) => favorite.source == source).toList(),
      };
      writes.add(client.liveTv.setFavoriteChannels(channels));
    }
    await Future.wait(writes);
  }

  void _focusCurrentTab() {
    if (tabController.index < _visibleTabs.length) {
      switch (_visibleTabs[tabController.index]) {
        case LiveTvTab.guide:
          _guideTabKey.currentState?.focusContent();
        case LiveTvTab.whatsOn:
          _whatsOnTabKey.currentState?.focusFirstHub();
        case LiveTvTab.recordings:
          _recordingsTabKey.currentState?.focusContent();
      }
    }
    setState(() {
      suppressAutoFocus = false;
    });
  }

  @override
  void focusActiveTabIfReady() => _focusCurrentTab();

  String _getTabLabel(LiveTvTab tab) {
    return switch (tab) {
      LiveTvTab.guide => t.liveTv.guide,
      LiveTvTab.whatsOn => t.liveTv.whatsOn,
      LiveTvTab.recordings => t.liveTv.recordings,
    };
  }

  List<Widget> _buildTabChipItems() {
    return [
      for (int i = 0; i < _visibleTabs.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        buildTabChip(
          _getTabLabel(_visibleTabs[i]),
          i,
          onSelectWhenActive: _focusCurrentTab,
          onNavigateDown: _focusCurrentTab,
          onNavigateToActions: () => _actionBarKey.currentState?.requestFocusOnFirst(),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    final isRecordings = _currentTab == LiveTvTab.recordings;
    return Scaffold(
      appBar: AppBar(
        title: useSideNav ? TabChipStrip(children: _buildTabChipItems()) : Text(t.liveTv.title),
        actions: DesktopAppBarHelper.buildAdjustedActions([
          FocusableActionBar(
            key: _actionBarKey,
            onNavigateLeft: () => getTabChipFocusNode(tabCount - 1).requestFocus(),
            onNavigateDown: _focusCurrentTab,
            actions: [
              if (!isRecordings)
                FocusableAction(
                  icon: _showFavoritesOnly ? Symbols.star_rounded : Symbols.star_outline_rounded,
                  iconFill: _showFavoritesOnly ? 1.0 : 0.0,
                  tooltip: t.liveTv.favorites,
                  onPressed: _toggleFavoritesFilter,
                ),
              if (!isRecordings && _showFavoritesOnly && _favoriteChannels.length > 1)
                FocusableAction(
                  icon: Symbols.swap_vert_rounded,
                  tooltip: t.liveTv.reorderFavorites,
                  onPressed: _showReorderFavorites,
                ),
              if (isRecordings)
                FocusableAction(
                  icon: Symbols.bolt_rounded,
                  tooltip: t.liveTv.processRecordingRules,
                  onPressed: _processRecordingRules,
                ),
              FocusableAction(
                icon: Symbols.refresh_rounded,
                tooltip: isRecordings ? t.common.refresh : t.liveTv.reloadGuide,
                onPressed: _onRefresh,
              ),
            ],
          ),
        ]),
      ),
      body: _buildLiveTvBody(useSideNav),
    );
  }

  Widget _buildTabContent(LiveTvTab tab, List<LiveTvChannel> guideChannels) {
    return switch (tab) {
      LiveTvTab.guide => GuideTab(
        key: _guideTabKey,
        channels: guideChannels,
        isFavoriteChannel: _isFavoriteChannel,
        onToggleFavorite: _toggleFavorite,
        onNavigateUp: focusTabBar,
        onBack: onTabBarBack,
      ),
      LiveTvTab.whatsOn => WhatsOnTab(
        key: _whatsOnTabKey,
        channels: _channels,
        onNavigateUp: focusTabBar,
        onBack: onTabBarBack,
      ),
      LiveTvTab.recordings => RecordingsTab(key: _recordingsTabKey, onNavigateUp: focusTabBar, onBack: onTabBarBack),
    };
  }

  Widget _buildLiveTvBody(bool useSideNav) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        icon: Symbols.error_rounded,
        onRetry: _loadChannels,
        actionAutofocus: true,
        actionUseBackgroundFocus: true,
      );
    }
    if (_channels.isEmpty && !_visibleTabs.contains(LiveTvTab.recordings)) {
      return Center(child: Text(t.liveTv.noChannels));
    }

    final guideChannels = _filteredChannels;

    return Column(
      children: [
        if (!useSideNav)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: .centerLeft,
            child: TabChipStrip(children: _buildTabChipItems()),
          ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [for (final tab in _visibleTabs) _buildTabContent(tab, guideChannels)],
          ),
        ),
      ],
    );
  }
}
