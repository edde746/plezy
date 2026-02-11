import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/formatters.dart';
import '../../utils/plex_url_helper.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../widgets/app_icon.dart';

/// EPG (Electronic Program Guide) screen with a time-based grid
class EpgGuideScreen extends StatefulWidget {
  const EpgGuideScreen({super.key});

  @override
  State<EpgGuideScreen> createState() => _EpgGuideScreenState();
}

class _EpgGuideScreenState extends State<EpgGuideScreen> {
  static const _slotWidth = 180.0;
  static const _channelColumnWidth = 140.0;
  static const _rowHeight = 64.0;
  static const _timeHeaderHeight = 40.0;
  static const _minutesPerSlot = 30;

  List<LiveTvChannel> _channels = [];
  List<LiveTvProgram> _programs = [];
  bool _isLoading = true;
  String? _error;

  // Time range: 6 hours centered on current time
  late DateTime _gridStart;
  late DateTime _gridEnd;

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _channelVerticalController = ScrollController();
  bool _syncingScroll = false;

  Timer? _timeIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _initTimeRange();
    _loadData();

    // Sync horizontal scroll: grid → header
    _gridHorizontalController.addListener(_syncGridToHeader);
    // Sync horizontal scroll: header → grid
    _headerHorizontalController.addListener(_syncHeaderToGrid);

    // Update time indicator every minute
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _syncGridToHeader() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_headerHorizontalController.hasClients) {
      _headerHorizontalController.jumpTo(_gridHorizontalController.offset);
    }
    _syncingScroll = false;
  }

  void _syncHeaderToGrid() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_gridHorizontalController.hasClients) {
      _gridHorizontalController.jumpTo(_headerHorizontalController.offset);
    }
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _gridHorizontalController.removeListener(_syncGridToHeader);
    _headerHorizontalController.removeListener(_syncHeaderToGrid);
    _headerHorizontalController.dispose();
    _gridHorizontalController.dispose();
    _channelVerticalController.dispose();
    _timeIndicatorTimer?.cancel();
    super.dispose();
  }

  void _initTimeRange() {
    final now = DateTime.now();
    // Start 1 hour before, rounded to nearest 30 min
    _gridStart = DateTime(now.year, now.month, now.day, now.hour);
    if (now.minute >= 30) {
      _gridStart = _gridStart.add(const Duration(minutes: 30));
    }
    _gridStart = _gridStart.subtract(const Duration(hours: 1));
    _gridEnd = _gridStart.add(const Duration(hours: 6));
  }

  Future<void> _loadData() async {
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
      final allPrograms = <LiveTvProgram>[];

      for (final serverInfo in liveTvServers) {
        final client = multiServer.getClientForServer(serverInfo.serverId);
        if (client == null) continue;

        final channels = await client.getEpgChannels(lineup: serverInfo.lineup);
        allChannels.addAll(channels);

        final startEpoch = _gridStart.millisecondsSinceEpoch ~/ 1000;
        final endEpoch = _gridEnd.millisecondsSinceEpoch ~/ 1000;

        final programs = await client.getEpgGrid(
          lineup: serverInfo.lineup,
          beginsAt: startEpoch,
          endsAt: endEpoch,
        );
        allPrograms.addAll(programs);
      }

      // Sort channels by number
      allChannels.sort((a, b) {
        final aNum = double.tryParse(a.number ?? '') ?? 999999;
        final bNum = double.tryParse(b.number ?? '') ?? 999999;
        return aNum.compareTo(bNum);
      });

      if (!mounted) return;
      setState(() {
        _channels = allChannels;
        _programs = allPrograms;
        _isLoading = false;
      });

      // Scroll to current time
      _scrollToNow();
    } catch (e) {
      appLogger.e('Failed to load EPG data', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _scrollToNow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final minutesSinceStart = now.difference(_gridStart).inMinutes;
      final offset = (minutesSinceStart / _minutesPerSlot) * _slotWidth;
      if (_gridHorizontalController.hasClients) {
        _gridHorizontalController.jumpTo(
          (offset - MediaQuery.of(context).size.width / 3).clamp(0, _gridHorizontalController.position.maxScrollExtent),
        );
      }
    });
  }

  /// Get programs for a specific channel
  List<LiveTvProgram> _getProgramsForChannel(LiveTvChannel channel) {
    final channelId = channel.identifier ?? channel.key;
    return _programs.where((p) => p.channelIdentifier == channelId).toList()
      ..sort((a, b) => (a.beginsAt ?? 0).compareTo(b.beginsAt ?? 0));
  }

  double _totalGridWidth() {
    final totalMinutes = _gridEnd.difference(_gridStart).inMinutes;
    return (totalMinutes / _minutesPerSlot) * _slotWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.liveTv.guide),
        actions: [
          IconButton(
            icon: const AppIcon(Symbols.refresh_rounded),
            tooltip: t.liveTv.reloadGuide,
            onPressed: _loadData,
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
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const AppIcon(Symbols.refresh_rounded),
                        label: Text(t.common.retry),
                      ),
                    ],
                  ),
                )
              : _channels.isEmpty
                  ? Center(child: Text(t.liveTv.noChannels))
                  : _buildGuideGrid(theme),
    );
  }

  Widget _buildGuideGrid(ThemeData theme) {
    return Column(
      children: [
        // Time header
        Row(
          children: [
            // Empty corner cell
            SizedBox(width: _channelColumnWidth, height: _timeHeaderHeight),
            // Scrollable time slots
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _totalGridWidth(),
                  height: _timeHeaderHeight,
                  child: _buildTimeHeader(theme),
                ),
              ),
            ),
          ],
        ),
        // Channel rows + program grid
        Expanded(
          child: Row(
            children: [
              // Fixed channel column
              SizedBox(
                width: _channelColumnWidth,
                child: ListView.builder(
                  controller: _channelVerticalController,
                  itemCount: _channels.length,
                  itemExtent: _rowHeight,
                  itemBuilder: (context, index) => _buildChannelCell(_channels[index], theme),
                ),
              ),
              // Scrollable program grid
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Sync vertical scroll from grid to channel column
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.axis == Axis.vertical) {
                      if (_channelVerticalController.hasClients) {
                        _channelVerticalController.jumpTo(notification.metrics.pixels);
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _gridHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _totalGridWidth(),
                      child: ListView.builder(
                        itemCount: _channels.length,
                        itemExtent: _rowHeight,
                        itemBuilder: (context, index) {
                          final channel = _channels[index];
                          final programs = _getProgramsForChannel(channel);
                          return _buildProgramRow(channel, programs, theme);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeHeader(ThemeData theme) {
    final slots = <Widget>[];
    var current = _gridStart;

    while (current.isBefore(_gridEnd)) {
      final timeStr = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
      slots.add(
        SizedBox(
          width: _slotWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
      current = current.add(const Duration(minutes: _minutesPerSlot));
    }

    return Stack(
      children: [
        Row(children: slots),
        // Current time indicator
        _buildNowIndicator(theme),
      ],
    );
  }

  Widget _buildNowIndicator(ThemeData theme) {
    final now = DateTime.now();
    if (now.isBefore(_gridStart) || now.isAfter(_gridEnd)) {
      return const SizedBox.shrink();
    }
    final minutesSinceStart = now.difference(_gridStart).inMinutes.toDouble();
    final offset = (minutesSinceStart / _minutesPerSlot) * _slotWidth;

    return Positioned(
      left: offset,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        color: Colors.red,
      ),
    );
  }

  Widget _buildChannelCell(LiveTvChannel channel, ThemeData theme) {
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(channel.serverId ?? '');

    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          if (channel.thumb != null && client != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(
                '${client.config.baseUrl}${channel.thumb}'.withPlexToken(client.config.token),
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(width: 28),
              ),
            )
          else
            const AppIcon(Symbols.live_tv_rounded, size: 28),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (channel.number != null)
                  Text(
                    channel.number!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                  ),
                Text(
                  channel.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramRow(LiveTvChannel channel, List<LiveTvProgram> programs, ThemeData theme) {
    if (programs.isEmpty) {
      return Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
        ),
        child: Center(
          child: Text(
            t.liveTv.noPrograms,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final blocks = <Widget>[];
    final gridStartEpoch = _gridStart.millisecondsSinceEpoch ~/ 1000;
    final gridEndEpoch = _gridEnd.millisecondsSinceEpoch ~/ 1000;

    for (final program in programs) {
      final progStart = (program.beginsAt ?? gridStartEpoch).clamp(gridStartEpoch, gridEndEpoch);
      final progEnd = (program.endsAt ?? gridEndEpoch).clamp(gridStartEpoch, gridEndEpoch);

      if (progEnd <= progStart) continue;

      final startOffset = progStart - gridStartEpoch;
      final duration = progEnd - progStart;
      final left = (startOffset / (_minutesPerSlot * 60)) * _slotWidth;
      final width = (duration / (_minutesPerSlot * 60)) * _slotWidth;

      blocks.add(
        Positioned(
          left: left,
          width: width.clamp(2.0, double.infinity),
          top: 2,
          bottom: 2,
          child: _buildProgramBlock(channel, program, theme),
        ),
      );
    }

    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Stack(
        children: [
          ...blocks,
          _buildNowIndicator(theme),
        ],
      ),
    );
  }

  Widget _buildProgramBlock(LiveTvChannel channel, LiveTvProgram program, ThemeData theme) {
    final isCurrentlyAiring = program.isCurrentlyAiring;

    return Material(
      color: isCurrentlyAiring
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _showProgramDetails(channel, program),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                program.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isCurrentlyAiring ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrentlyAiring
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (program.startTime != null)
                Text(
                  '${program.startTime!.hour.toString().padLeft(2, '0')}:${program.startTime!.minute.toString().padLeft(2, '0')} · ${formatDurationTextual(program.durationMinutes * 60000)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrentlyAiring
                        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgramDetails(LiveTvChannel channel, LiveTvProgram program) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      program.displayTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (program.isCurrentlyAiring)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.liveTv.live,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${channel.displayName} · ${program.startTime?.hour.toString().padLeft(2, '0')}:${program.startTime?.minute.toString().padLeft(2, '0')} - ${program.endTime?.hour.toString().padLeft(2, '0')}:${program.endTime?.minute.toString().padLeft(2, '0')} · ${formatDurationTextual(program.durationMinutes * 60000)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (program.summary != null && program.summary!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  program.summary!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (program.isCurrentlyAiring)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _tuneToChannel(channel);
                      },
                      icon: const AppIcon(Symbols.play_arrow_rounded),
                      label: Text(t.common.play),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      // TODO: Record action
                    },
                    icon: const AppIcon(Symbols.fiber_manual_record_rounded),
                    label: Text(t.liveTv.record),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tuneToChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();

    // Find the DVR server info matching this channel's serverId
    final serverInfo = multiServer.liveTvServers.where(
      (s) => s.serverId == channel.serverId,
    ).firstOrNull ?? multiServer.liveTvServers.firstOrNull;

    if (serverInfo == null) return;

    final client = multiServer.getClientForServer(serverInfo.serverId);
    if (client == null) return;

    await navigateToLiveTv(
      context,
      client: client,
      dvrKey: serverInfo.dvrKey,
      channel: channel,
      channels: _channels,
    );
  }
}
