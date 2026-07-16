import 'dart:async';
import '../../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../focus/hub_vertical_navigation.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_hub.dart';
import '../../../media/media_item.dart';
import '../../../media/media_item_types.dart';
import '../../../mixins/mounted_set_state_mixin.dart';
import '../../../models/livetv_channel.dart';
import '../../../models/livetv_hub_result.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../services/settings_service.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/hub_section.dart';
import '../live_tv_actions_mixin.dart';
import '../live_tv_show_schedule_screen.dart';
import '../live_tv_refresh_lifecycle.dart';

class WhatsOnTab extends StatefulWidget {
  final List<LiveTvChannel> channels;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const WhatsOnTab({super.key, required this.channels, this.onNavigateUp, this.onBack});

  @override
  State<WhatsOnTab> createState() => WhatsOnTabState();
}

class WhatsOnTabState extends State<WhatsOnTab>
    with LiveTvActionsMixin<WhatsOnTab>, MountedSetStateMixin, WidgetsBindingObserver {
  List<_WhatsOnHub> _hubs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  final Map<String, GlobalKey<HubSectionState>> _hubKeysById = {};
  List<GlobalKey<HubSectionState>> _hubKeys = [];
  bool _refreshRequested = true;
  bool _tickerEnabled = false;
  bool _appRefreshActive = true;

  @override
  List<LiveTvChannel> get liveTvChannels => widget.channels;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHubs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled == _tickerEnabled) return;
    _tickerEnabled = enabled;
    _syncRefreshTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (liveTvRefreshTransition(state)) {
      case LiveTvRefreshLifecycleTransition.pause:
        if (!_appRefreshActive) return;
        _appRefreshActive = false;
        _syncRefreshTimer();
      case LiveTvRefreshLifecycleTransition.resume:
        if (_appRefreshActive) return;
        _appRefreshActive = true;
        _syncRefreshTimer();
      case LiveTvRefreshLifecycleTransition.ignore:
        break;
    }
  }

  void pauseRefresh() {
    _refreshRequested = false;
    _syncRefreshTimer();
  }

  void resumeRefresh() {
    _refreshRequested = true;
    _syncRefreshTimer();
  }

  void _syncRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!_refreshRequested || !_tickerEnabled || !_appRefreshActive || !mounted) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadHubs());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHubs() async {
    if (!mounted) return;
    setState(() => _isLoading = _hubs.isEmpty);

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;
      final allHubs = <_WhatsOnHub>[];
      final allHubIds = <String>[];
      final queriedServers = <String>{};

      for (final serverInfo in liveTvServers) {
        if (!queriedServers.add(serverInfo.serverId)) continue;
        try {
          // Plex-only: Live TV hubs API is Plex-specific.
          final client = multiServer.getPlexClientForServer(ServerId(serverInfo.serverId));
          if (client == null) continue;

          final hubs = await client.getLiveTvHubs();
          for (final hub in hubs) {
            allHubs.add(_WhatsOnHub.fromResult(hub));
            allHubIds.add('${serverInfo.serverId}\u0000${hub.hubKey}');
          }
        } catch (e) {
          appLogger.e('Failed to load hubs from server ${serverInfo.serverId}', error: e);
        }
      }

      if (!mounted) return;
      final hubIds = allHubIds.toSet();
      _hubKeysById.removeWhere((id, _) => !hubIds.contains(id));
      setState(() {
        _hubs = allHubs;
        _hubKeys = [for (final hubId in allHubIds) _hubKeysById.putIfAbsent(hubId, () => GlobalKey<HubSectionState>())];
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load live TV hubs', error: e);
      setStateIfMounted(() => _isLoading = false);
    }
  }

  /// Focus the first hub (called from parent when tab bar navigates down)
  void focusFirstHub() {
    if (_hubKeys.isNotEmpty) {
      _hubKeys.first.currentState?.requestFocusFromMemory();
    }
  }

  bool _handleVerticalNavigation(int hubIndex, bool isUp) {
    return navigateVerticalHubRows(
      hubCount: _hubKeys.length,
      hubIndex: hubIndex,
      isUp: isUp,
      onTopBoundary: widget.onNavigateUp,
      requestFocus: (targetIndex) {
        _hubKeys[targetIndex].currentState?.requestFocusFromMemory();
      },
    );
  }

  void _onItemTap(LiveTvHubEntry entry) {
    final channel = findChannelForProgram(entry.program);

    if (entry.program.isCurrentlyAiring && channel != null) {
      // Live → play directly
      tuneChannel(channel);
    } else if (entry.metadata.isShow && serverIdOrNull(entry.metadata.serverId) != null) {
      // Show with upcoming episodes → show full schedule
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveTvShowScheduleScreen(
            showTitle: entry.metadata.displayTitle,
            serverId: entry.metadata.serverId!,
            channels: widget.channels,
          ),
        ),
      );
    } else {
      // Individual program (episode, movie, etc.) → bottom sheet
      showProgramDetails(
        program: entry.program,
        channel: channel,
        posterThumb: entry.metadata.grandparentThumbPath ?? entry.metadata.thumbPath,
        posterServerId: entry.metadata.serverId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hubs.isEmpty) {
      return Center(child: Text(t.liveTv.noPrograms));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.none,
      itemCount: _hubs.length,
      itemBuilder: (context, index) {
        final hub = _hubs[index];
        return HubSection(
          key: _hubKeys[index],
          hub: hub.mediaHub,
          icon: Symbols.live_tv_rounded,
          cardSizing: HubCardSizing.grid,
          episodePosterModeOverride: EpisodePosterMode.seriesPoster,
          onItemTap: (item) => _onItemTap(hub.entryFor(item)),
          onItemLongPress: (item) {
            final entry = hub.entryFor(item);
            showProgramDetails(
              program: entry.program,
              channel: findChannelForProgram(entry.program),
              posterThumb: entry.metadata.grandparentThumbPath ?? entry.metadata.thumbPath,
              posterServerId: entry.metadata.serverId,
            );
          },
          onVerticalNavigation: (isUp) => _handleVerticalNavigation(index, isUp),
          onNavigateToSidebar: widget.onBack,
          onBack: widget.onBack,
        );
      },
    );
  }
}

class _WhatsOnHub {
  final MediaHub mediaHub;
  final Map<MediaItem, LiveTvHubEntry> _entriesByItem;

  const _WhatsOnHub._(this.mediaHub, this._entriesByItem);

  factory _WhatsOnHub.fromResult(LiveTvHubResult result) {
    final entriesByItem = Map<MediaItem, LiveTvHubEntry>.identity();
    for (final entry in result.entries) {
      entriesByItem[entry.metadata] = entry;
    }

    final firstMetadata = result.entries.isEmpty ? null : result.entries.first.metadata;
    return _WhatsOnHub._(
      MediaHub(
        id: result.hubKey,
        title: result.title,
        type: 'mixed',
        items: [for (final entry in result.entries) entry.metadata],
        size: result.entries.length,
        serverId: firstMetadata?.serverId,
        serverName: firstMetadata?.serverName,
      ),
      entriesByItem,
    );
  }

  LiveTvHubEntry entryFor(MediaItem item) => _entriesByItem[item]!;
}
