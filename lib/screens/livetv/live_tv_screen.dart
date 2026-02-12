import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/dpad_navigator.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../mixins/tab_navigation_mixin.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_tab_chip.dart';
import 'dvr_recordings_screen.dart';
import 'tabs/guide_tab.dart';
import 'tabs/whats_on_tab.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> with SingleTickerProviderStateMixin, TabNavigationMixin {
  final _guideTabFocusNode = FocusNode(debugLabel: 'tab_chip_guide');
  final _whatsOnTabFocusNode = FocusNode(debugLabel: 'tab_chip_whats_on');
  final _guideTabKey = GlobalKey<GuideTabState>();
  final _whatsOnTabKey = GlobalKey<WhatsOnTabState>();

  // App bar action button focus
  final _refreshButtonFocusNode = FocusNode(debugLabel: 'RefreshButton');
  final _dvrButtonFocusNode = FocusNode(debugLabel: 'DvrButton');
  bool _isRefreshFocused = false;
  bool _isDvrFocused = false;

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
    _refreshButtonFocusNode.addListener(_onRefreshFocusChange);
    _dvrButtonFocusNode.addListener(_onDvrFocusChange);
    _loadChannels();
  }

  @override
  void dispose() {
    _guideTabFocusNode.dispose();
    _whatsOnTabFocusNode.dispose();
    _refreshButtonFocusNode.removeListener(_onRefreshFocusChange);
    _refreshButtonFocusNode.dispose();
    _dvrButtonFocusNode.removeListener(_onDvrFocusChange);
    _dvrButtonFocusNode.dispose();
    disposeTabNavigation();
    super.dispose();
  }

  void _onRefreshFocusChange() {
    if (mounted) setState(() => _isRefreshFocused = _refreshButtonFocusNode.hasFocus);
  }

  void _onDvrFocusChange() {
    if (mounted) setState(() => _isDvrFocused = _dvrButtonFocusNode.hasFocus);
  }

  @override
  void onTabChanged() {
    if (!tabController.indexIsChanging) {
      super.onTabChanged();
    }
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

      for (final serverInfo in liveTvServers) {
        final client = multiServer.getClientForServer(serverInfo.serverId);
        if (client == null) continue;

        final channels = await client.getEpgChannels(lineup: serverInfo.lineup);
        allChannels.addAll(channels);
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

      if (allChannels.isNotEmpty) {
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

  void _openRecordings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DvrRecordingsScreen()));
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

  // ---------------------------------------------------------------------------
  // Action button key handlers
  // ---------------------------------------------------------------------------

  KeyEventResult _handleRefreshKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isLeftKey) {
      getTabChipFocusNode(tabCount - 1).requestFocus();
      return KeyEventResult.handled;
    }
    if (key.isRightKey) {
      _dvrButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      _focusCurrentTab();
      return KeyEventResult.handled;
    }
    if (key.isUpKey) {
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      _loadChannels();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleDvrKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isLeftKey) {
      _refreshButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (key.isRightKey || key.isUpKey) {
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      _focusCurrentTab();
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      _openRecordings();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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
          : () => _refreshButtonFocusNode.requestFocus(),
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
          Focus(
            focusNode: _refreshButtonFocusNode,
            onKeyEvent: _handleRefreshKeyEvent,
            child: Container(
              decoration: BoxDecoration(
                color: _isRefreshFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const AppIcon(Symbols.refresh_rounded),
                tooltip: t.liveTv.reloadGuide,
                onPressed: _loadChannels,
              ),
            ),
          ),
          Focus(
            focusNode: _dvrButtonFocusNode,
            onKeyEvent: _handleDvrKeyEvent,
            child: Container(
              decoration: BoxDecoration(
                color: _isDvrFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const AppIcon(Symbols.fiber_dvr_rounded),
                tooltip: t.liveTv.recordings,
                onPressed: _openRecordings,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
            )
          : _channels.isEmpty
          ? Center(child: Text(t.liveTv.noChannels))
          : Column(
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
                      GuideTab(
                        key: _guideTabKey,
                        channels: _channels,
                        onNavigateUp: focusTabBar,
                        onBack: onTabBarBack,
                      ),
                      WhatsOnTab(
                        key: _whatsOnTabKey,
                        channels: _channels,
                        onNavigateUp: focusTabBar,
                        onBack: onTabBarBack,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
