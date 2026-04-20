import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_dvr.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/tab_navigation_mixin.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/overlay_sheet.dart';
import 'reorder_favorites_sheet.dart';
import 'tabs/guide_tab.dart';
import 'tabs/whats_on_tab.dart';

enum LiveTvTab { guide, whatsOn }

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
  final _guideTabKey = GlobalKey<GuideTabState>();
  final _whatsOnTabKey = GlobalKey<WhatsOnTabState>();

  // App bar action bar
  final _actionBarKey = GlobalKey<FocusableActionBarState>();

  List<LiveTvChannel> _channels = [];
  bool _isLoading = true;
  String? _error;

  // Favorites
  bool _showFavoritesOnly = false;
  Set<String> _favoriteChannelIds = {};
  List<FavoriteChannel> _favoriteChannels = [];

  /// Source URI per server, built from machineIdentifier + EPG provider identifier.
  final Map<String, String> _favoriteSourceByServer = {};

  List<LiveTvChannel> get _filteredChannels {
    if (!_showFavoritesOnly || _favoriteChannelIds.isEmpty) return _channels;
    final channelMap = {for (final c in _channels) c.key: c};
    return [
      for (final fav in _favoriteChannels)
        if (channelMap.containsKey(fav.id)) channelMap[fav.id]!,
    ];
  }

  @override
  List<FocusNode> get tabChipFocusNodes => [_guideTabFocusNode, _whatsOnTabFocusNode];

  @override
  void initState() {
    super.initState();
    suppressAutoFocus = true;
    _showFavoritesOnly = context.read<SettingsProvider>().liveTvDefaultFavorites;
    initTabNavigation();
    _loadChannels();
  }

  @override
  void dispose() {
    _guideTabFocusNode.dispose();
    _whatsOnTabFocusNode.dispose();
    disposeTabNavigation();
    super.dispose();
  }

  @override
  void onTabChanged() {
    if (!tabController.indexIsChanging) {
      super.onTabChanged();
      // Pause/resume timers based on active tab
      switch (LiveTvTab.values[tabController.index]) {
        case LiveTvTab.guide:
          _whatsOnTabKey.currentState?.pauseRefresh();
          _guideTabKey.currentState?.resumeRefresh();
        case LiveTvTab.whatsOn:
          _guideTabKey.currentState?.pauseRefresh();
          _whatsOnTabKey.currentState?.resumeRefresh();
      }
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

  Future<void> _loadChannels() async {
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

      appLogger.d(
        'Live TV DVRs: ${liveTvServers.map((s) => '${s.serverId}/${s.dvrKey} lineup=${s.lineup}').join(', ')}',
      );

      // Build a set of enabled channel keys per server from cached DVR data
      final enabledKeysByServer = <String, Set<String>>{};
      final processedServers = <String>{};
      for (final serverInfo in liveTvServers) {
        if (!processedServers.add(serverInfo.serverId)) continue;
        final enabledKeys = _extractEnabledChannelKeys(serverInfo.dvrs);
        if (enabledKeys != null) {
          enabledKeysByServer[serverInfo.serverId] = enabledKeys;
        }
      }

      for (final serverInfo in liveTvServers) {
        try {
          final client = multiServer.getClientForServer(serverInfo.serverId);
          if (client == null) continue;

          final channels = await client.getEpgChannels(lineup: serverInfo.lineup);
          final enabledKeys = enabledKeysByServer[serverInfo.serverId];
          appLogger.d(
            'Channels from DVR ${serverInfo.dvrKey}: ${channels.length} channels (${enabledKeys?.length ?? 'all'} enabled)',
          );
          for (final channel in channels) {
            // Skip disabled channels if DVR has mapping data
            if (enabledKeys != null && !enabledKeys.contains(channel.key)) continue;
            final dedupKey = '${serverInfo.serverId}:${channel.key}';
            if (seenChannels.add(dedupKey)) {
              allChannels.add(channel);
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
        _isLoading = false;
      });

      // Load favorites from the first available server (favorites are cloud-synced)
      _loadFavorites(multiServer);

      if (allChannels.isNotEmpty && PlatformDetector.shouldUseSideNavigation(context)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusCurrentTab();
        });
      }
    } catch (e) {
      appLogger.e('Failed to load Live TV channels', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadFavorites(MultiServerProvider multiServer) async {
    try {
      // Use the first available server's client to fetch favorites
      for (final serverInfo in multiServer.liveTvServers) {
        final client = multiServer.getClientForServer(serverInfo.serverId);
        if (client == null) continue;

        // Build and cache the source URI for this server
        final source = await client.buildFavoriteChannelSource();
        _favoriteSourceByServer[serverInfo.serverId] = source;

        final favorites = await client.getFavoriteChannels();
        if (!mounted) return;

        setState(() {
          _favoriteChannels = favorites;
          _favoriteChannelIds = favorites.map((f) => f.id).toSet();
        });
        appLogger.d('Live TV: loaded ${favorites.length} favorite channels');
        break; // Favorites are cloud-synced, only need to fetch once
      }
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
    final source = _favoriteSourceByServer[channel.serverId] ?? '';

    setState(() {
      if (_favoriteChannelIds.contains(channel.key)) {
        _favoriteChannelIds = Set.from(_favoriteChannelIds)..remove(channel.key);
        _favoriteChannels = _favoriteChannels.where((f) => f.id != channel.key).toList();
      } else {
        _favoriteChannelIds = Set.from(_favoriteChannelIds)..add(channel.key);
        _favoriteChannels = [..._favoriteChannels, FavoriteChannel.fromLiveTvChannel(channel, source)];
      }
    });

    _persistFavorites();
  }

  void _showReorderFavorites() {
    final channelMap = {for (final c in _channels) c.key: c};

    OverlaySheetController.showAdaptive(
      context,
      builder: (sheetContext) => ReorderFavoritesSheet(
        favorites: List.from(_favoriteChannels),
        channelMap: channelMap,
        onReorder: (reordered) {
          setState(() {
            _favoriteChannels = reordered;
            _favoriteChannelIds = reordered.map((f) => f.id).toSet();
          });
          _persistFavorites();
        },
        onRemove: (removed) {
          setState(() {
            _favoriteChannels = _favoriteChannels.where((f) => f.id != removed.id).toList();
            _favoriteChannelIds = Set.from(_favoriteChannelIds)..remove(removed.id);
          });
          _persistFavorites();
        },
      ),
    );
  }

  void _persistFavorites() {
    final multiServer = context.read<MultiServerProvider>();
    for (final serverInfo in multiServer.liveTvServers) {
      final client = multiServer.getClientForServer(serverInfo.serverId);
      if (client != null) {
        client.setFavoriteChannels(_favoriteChannels);
        break;
      }
    }
  }

  void _focusCurrentTab() {
    switch (LiveTvTab.values[tabController.index]) {
      case LiveTvTab.guide:
        _guideTabKey.currentState?.focusContent();
      case LiveTvTab.whatsOn:
        _whatsOnTabKey.currentState?.focusFirstHub();
    }
    setState(() {
      suppressAutoFocus = false;
    });
  }

  @override
  void focusActiveTabIfReady() => _focusCurrentTab();

  // ---------------------------------------------------------------------------
  // Tab chips
  // ---------------------------------------------------------------------------

  String _getTabLabel(LiveTvTab tab) {
    return switch (tab) {
      LiveTvTab.guide => t.liveTv.guide,
      LiveTvTab.whatsOn => t.liveTv.whatsOn,
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  List<Widget> _buildTabChipItems() {
    return [
      for (int i = 0; i < LiveTvTab.values.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        buildTabChip(
          _getTabLabel(LiveTvTab.values[i]),
          i,
          onSelectWhenActive: _focusCurrentTab,
          onNavigateDown: _focusCurrentTab,
          onNavigateRightFromLast: () => _actionBarKey.currentState?.requestFocusOnFirst(),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    return Scaffold(
      appBar: AppBar(
        title: useSideNav ? Row(children: _buildTabChipItems()) : Text(t.liveTv.title),
        actions: DesktopAppBarHelper.buildAdjustedActions([
          FocusableActionBar(
            key: _actionBarKey,
            onNavigateLeft: () => getTabChipFocusNode(tabCount - 1).requestFocus(),
            onNavigateDown: _focusCurrentTab,
            actions: [
              FocusableAction(
                icon: _showFavoritesOnly ? Symbols.star_rounded : Symbols.star_outline_rounded,
                iconFill: _showFavoritesOnly ? 1.0 : 0.0,
                tooltip: t.liveTv.favorites,
                onPressed: _toggleFavoritesFilter,
              ),
              if (_showFavoritesOnly && _favoriteChannels.length > 1)
                FocusableAction(
                  icon: Symbols.swap_vert_rounded,
                  tooltip: t.liveTv.reorderFavorites,
                  onPressed: _showReorderFavorites,
                ),
              FocusableAction(icon: Symbols.refresh_rounded, tooltip: t.liveTv.reloadGuide, onPressed: _loadChannels),
            ],
          ),
        ]),
      ),
      body: _buildLiveTvBody(theme, useSideNav),
    );
  }

  Widget _buildLiveTvBody(ThemeData theme, bool useSideNav) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(Symbols.error_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadChannels,
              icon: const AppIcon(Symbols.refresh_rounded),
              label: Text(t.common.retry),
            ),
          ],
        ),
      );
    }
    if (_channels.isEmpty) {
      return Center(child: Text(t.liveTv.noChannels));
    }

    final guideChannels = _filteredChannels;

    return Column(
      children: [
        if (!useSideNav)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildTabChipItems()),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              GuideTab(
                key: _guideTabKey,
                channels: guideChannels,
                favoriteChannelIds: _favoriteChannelIds,
                onToggleFavorite: _toggleFavorite,
                onNavigateUp: focusTabBar,
                onBack: onTabBarBack,
              ),
              WhatsOnTab(key: _whatsOnTabKey, channels: _channels, onNavigateUp: focusTabBar, onBack: onTabBarBack),
            ],
          ),
        ),
      ],
    );
  }
}
