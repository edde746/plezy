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
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_tab_chip.dart';
import 'tabs/guide_tab.dart';
import 'tabs/whats_on_tab.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen>
    with SingleTickerProviderStateMixin, TabNavigationMixin
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

  @override
  List<FocusNode> get tabChipFocusNodes => [_guideTabFocusNode, _whatsOnTabFocusNode];

  @override
  void initState() {
    super.initState();
    suppressAutoFocus = true;
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
      if (tabController.index == 0) {
        _whatsOnTabKey.currentState?.pauseRefresh();
        _guideTabKey.currentState?.resumeRefresh();
      } else {
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

      // Build a set of enabled channel keys per server from DVR mappings
      final enabledKeysByServer = <String, Set<String>>{};
      final queriedServers = <String>{};
      for (final serverInfo in liveTvServers) {
        if (!queriedServers.add(serverInfo.serverId)) continue;
        try {
          final client = multiServer.getClientForServer(serverInfo.serverId);
          if (client == null) continue;
          final dvrs = await client.getDvrs();
          final enabledKeys = _extractEnabledChannelKeys(dvrs);
          if (enabledKeys != null) {
            enabledKeysByServer[serverInfo.serverId] = enabledKeys;
          }
        } catch (e) {
          appLogger.e('Failed to load DVR mappings for server ${serverInfo.serverId}', error: e);
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

  void _focusCurrentTab() {
    if (tabController.index == 0) {
      _guideTabKey.currentState?.focusContent();
    } else if (tabController.index == 1) {
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

  Widget _buildTabChip(String label, int index) {
    final isSelected = tabController.index == index;

    return FocusableTabChip(
      label: label,
      isSelected: isSelected,
      focusNode: getTabChipFocusNode(index),
      onSelect: () {
        if (isSelected) {
          _focusCurrentTab();
        } else {
          setState(() {
            tabController.index = index;
          });
        }
      },
      onNavigateLeft: index > 0
          ? () {
              final newIndex = index - 1;
              setState(() {
                suppressAutoFocus = true;
                tabController.index = newIndex;
              });
              getTabChipFocusNode(newIndex).requestFocus();
            }
          : onTabBarBack,
      onNavigateRight: index < tabCount - 1
          ? () {
              final newIndex = index + 1;
              setState(() {
                suppressAutoFocus = true;
                tabController.index = newIndex;
              });
              getTabChipFocusNode(newIndex).requestFocus();
            }
          : () => _actionBarKey.currentState?.getFocusNode(0).requestFocus(),
      onNavigateDown: _focusCurrentTab,
      onBack: onTabBarBack,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    return Scaffold(
      appBar: AppBar(
        title: useSideNav
            ? Row(
                children: [
                  _buildTabChip(t.liveTv.guide, 0),
                  const SizedBox(width: 8),
                  _buildTabChip(t.liveTv.whatsOn, 1),
                ],
              )
            : Text(t.liveTv.title),
        actions: [
          FocusableActionBar(
            key: _actionBarKey,
            onNavigateLeft: () => getTabChipFocusNode(tabCount - 1).requestFocus(),
            onNavigateDown: _focusCurrentTab,
            actions: [
              FocusableAction(
                icon: Symbols.refresh_rounded,
                tooltip: t.liveTv.reloadGuide,
                onPressed: _loadChannels,
              ),
            ],
          ),
        ],
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
    return Column(
      children: [
        if (!useSideNav)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip(t.liveTv.guide, 0),
                  const SizedBox(width: 8),
                  _buildTabChip(t.liveTv.whatsOn, 1),
                ],
              ),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              GuideTab(key: _guideTabKey, channels: _channels, onNavigateUp: focusTabBar, onBack: onTabBarBack),
              WhatsOnTab(key: _whatsOnTabKey, channels: _channels, onNavigateUp: focusTabBar, onBack: onTabBarBack),
            ],
          ),
        ),
      ],
    );
  }
}
