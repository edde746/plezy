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
import '../../utils/plex_image_helper.dart';
import '../../utils/plex_url_helper.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../widgets/app_icon.dart';
import 'dvr_recordings_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  static const _slotWidth = 180.0;
  static const _channelColumnWidth = 140.0;
  static const _rowHeight = 64.0;
  static const _timeHeaderHeight = 40.0;
  static const _minutesPerSlot = 30;

  List<LiveTvChannel> _channels = [];
  List<LiveTvProgram> _programs = [];
  bool _isLoading = true;
  String? _error;

  late DateTime _gridStart;
  late DateTime _gridEnd;

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _channelVerticalController = ScrollController();
  bool _syncingScroll = false;

  Timer? _timeIndicatorTimer;
  final _dayPickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initTimeRange();
    _loadData();

    _gridHorizontalController.addListener(_syncGridToHeader);
    _headerHorizontalController.addListener(_syncHeaderToGrid);

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
    _gridStart = DateTime(now.year, now.month, now.day, now.hour);
    if (now.minute >= 30) {
      _gridStart = _gridStart.add(const Duration(minutes: 30));
    }
    _gridStart = _gridStart.subtract(const Duration(hours: 1));
    _gridEnd = _gridStart.add(const Duration(hours: 6));
  }

  void _shiftTimeRange(int hours) {
    setState(() {
      _gridStart = _gridStart.add(Duration(hours: hours));
      _gridEnd = _gridStart.add(const Duration(hours: 6));
    });
    _loadData();
  }

  void _jumpToNow() {
    _initTimeRange();
    _loadData();
  }

  void _jumpToDay(DateTime day) {
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    if (isToday) {
      _jumpToNow();
      return;
    }

    setState(() {
      // Start at midnight for non-today days
      _gridStart = DateTime(day.year, day.month, day.day);
      _gridEnd = _gridStart.add(const Duration(hours: 6));
    });
    _loadData();
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

      allChannels.sort((a, b) {
        final aNum = double.tryParse(a.number ?? '') ?? 999999;
        final bNum = double.tryParse(b.number ?? '') ?? 999999;
        return aNum.compareTo(bNum);
      });

      if (!mounted) return;

      appLogger.d('EPG loaded: ${allChannels.length} channels, ${allPrograms.length} programs');
      if (allChannels.isNotEmpty) {
        final ch = allChannels.first;
        appLogger.d('Sample channel: key=${ch.key}, identifier=${ch.identifier}');
      }
      if (allPrograms.isNotEmpty) {
        final p = allPrograms.first;
        appLogger.d('Sample program: channelIdentifier=${p.channelIdentifier}, title=${p.title}');
      }

      setState(() {
        _channels = allChannels;
        _programs = allPrograms;
        _isLoading = false;
      });

      _scrollToNow();
    } catch (e) {
      appLogger.e('Failed to load Live TV data', error: e);
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
          (offset - MediaQuery.of(context).size.width / 3)
              .clamp(0, _gridHorizontalController.position.maxScrollExtent),
        );
      }
    });
  }

  List<LiveTvProgram> _getProgramsForChannel(LiveTvChannel channel) {
    final channelId = channel.identifier ?? channel.key;
    return _programs.where((p) => p.channelIdentifier == channelId).toList()
      ..sort((a, b) => (a.beginsAt ?? 0).compareTo(b.beginsAt ?? 0));
  }

  double _totalGridWidth() {
    final totalMinutes = _gridEnd.difference(_gridStart).inMinutes;
    return (totalMinutes / _minutesPerSlot) * _slotWidth;
  }

  Future<void> _tuneChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();

    final serverInfo = multiServer.liveTvServers
            .where((s) => s.serverId == channel.serverId)
            .firstOrNull ??
        multiServer.liveTvServers.firstOrNull;

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

  void _openRecordings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DvrRecordingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.liveTv.title),
        actions: [
          IconButton(
            icon: const AppIcon(Symbols.refresh_rounded),
            tooltip: t.liveTv.reloadGuide,
            onPressed: _loadData,
          ),
          IconButton(
            icon: const AppIcon(Symbols.fiber_dvr_rounded),
            tooltip: t.liveTv.recordings,
            onPressed: _openRecordings,
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
                      AppIcon(Symbols.error_rounded,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
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
        // Time navigation bar
        _buildTimeNavigation(theme),
        // Time header
        Row(
          children: [
            SizedBox(width: _channelColumnWidth, height: _timeHeaderHeight),
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
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
              SizedBox(
                width: _channelColumnWidth,
                child: ListView.builder(
                  controller: _channelVerticalController,
                  itemCount: _channels.length,
                  itemExtent: _rowHeight,
                  itemBuilder: (context, index) =>
                      _buildChannelCell(_channels[index], theme),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.axis == Axis.vertical) {
                      if (_channelVerticalController.hasClients) {
                        _channelVerticalController
                            .jumpTo(notification.metrics.pixels);
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _gridHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
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

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target == today) return t.liveTv.today;

    final format = MaterialLocalizations.of(context);
    // formatFullDate gives "Monday, January 1, 2026" — extract weekday name
    final full = format.formatFullDate(target);
    return full.split(',').first;
  }

  List<(String, int)> get _timeSlots => [
    (t.liveTv.midnight, 0),
    (t.liveTv.overnight, 2),
    (t.liveTv.morning, 6),
    (t.liveTv.daytime, 12),
    (t.liveTv.evening, 18),
    (t.liveTv.lateNight, 22),
  ];

  RelativeRect _menuPosition() {
    final renderBox =
        _dayPickerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return RelativeRect.fill;

    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    return RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonPos.dx,
        buttonPos.dy + buttonSize.height,
        buttonSize.width,
        0,
      ),
      Offset.zero & overlay.size,
    );
  }

  void _showDayPicker() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gridDay = DateTime(_gridStart.year, _gridStart.month, _gridStart.day);
    final theme = Theme.of(context);

    final days = <DateTime>[];
    for (var i = 0; i < 8; i++) {
      days.add(today.add(Duration(days: i)));
    }

    showMenu<Object>(
      context: context,
      position: _menuPosition(),
      items: [
        PopupMenuItem<String>(
          value: 'now',
          child: Text(t.liveTv.now, style: theme.textTheme.bodyMedium),
        ),
        ...days.map((day) {
          final isSelected = day == gridDay;
          final label = _dayLabel(day);
          return PopupMenuItem<DateTime>(
            value: day,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  AppIcon(Symbols.check_rounded,
                      size: 18, color: theme.colorScheme.primary),
              ],
            ),
          );
        }),
      ],
    ).then((value) {
      if (value == null) return;
      if (value is String && value == 'now') {
        _jumpToNow();
      } else if (value is DateTime) {
        _showTimeSlotPicker(value);
      }
    });
  }

  void _showTimeSlotPicker(DateTime day) {
    final theme = Theme.of(context);
    final label = _dayLabel(day).toUpperCase();

    showMenu<int>(
      context: context,
      position: _menuPosition(),
      items: [
        PopupMenuItem<int>(
          value: -1,
          child: Row(
            children: [
              AppIcon(Symbols.chevron_left_rounded,
                  size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ..._timeSlots.map((slot) {
          return PopupMenuItem<int>(
            value: slot.$2,
            child: Text(slot.$1, style: theme.textTheme.bodyMedium),
          );
        }),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == -1) {
        // Back to day picker
        _showDayPicker();
        return;
      }
      setState(() {
        _gridStart = DateTime(day.year, day.month, day.day, value);
        _gridEnd = _gridStart.add(const Duration(hours: 6));
      });
      _loadData();
    });
  }

  Widget _buildTimeNavigation(ThemeData theme) {
    final format = MaterialLocalizations.of(context);
    final timeLabel =
        format.formatTimeOfDay(TimeOfDay.fromDateTime(_gridStart));
    final dayLabel = _dayLabel(_gridStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const AppIcon(Symbols.chevron_left_rounded),
            onPressed: () => _shiftTimeRange(-2),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  key: _dayPickerKey,
                  onTap: _showDayPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayLabel,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 2),
                      AppIcon(Symbols.arrow_drop_down_rounded,
                          size: 18, color: theme.colorScheme.onSurface),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeLabel,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const AppIcon(Symbols.chevron_right_rounded),
            onPressed: () => _shiftTimeRange(2),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeHeader(ThemeData theme) {
    final slots = <Widget>[];
    var current = _gridStart;

    while (current.isBefore(_gridEnd)) {
      final timeStr =
          '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
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
      child: Container(width: 2, color: Colors.red),
    );
  }

  Widget _buildChannelCell(LiveTvChannel channel, ThemeData theme) {
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(channel.serverId ?? '');

    String? imageUrl;
    if (channel.thumb != null && client != null) {
      imageUrl = PlexImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: channel.thumb,
        maxWidth: _channelColumnWidth - 16,
        maxHeight: _rowHeight - 16,
        devicePixelRatio: PlexImageHelper.effectiveDevicePixelRatio(context),
        imageType: ImageType.logo,
      );
    }

    return _ChannelCell(
      rowHeight: _rowHeight,
      channelColumnWidth: _channelColumnWidth,
      imageUrl: imageUrl,
      channel: channel,
      theme: theme,
      onTap: () => _tuneChannel(channel),
      fallbackBuilder: () => _buildChannelNameFallback(channel, theme),
    );
  }

  Widget _buildChannelNameFallback(LiveTvChannel channel, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgramRow(
      LiveTvChannel channel, List<LiveTvProgram> programs, ThemeData theme) {
    if (programs.isEmpty) {
      return Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
        ),
        child: Center(
          child: Text(
            t.liveTv.noPrograms,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final blocks = <Widget>[];
    final gridStartEpoch = _gridStart.millisecondsSinceEpoch ~/ 1000;
    final gridEndEpoch = _gridEnd.millisecondsSinceEpoch ~/ 1000;

    for (final program in programs) {
      final progStart =
          (program.beginsAt ?? gridStartEpoch).clamp(gridStartEpoch, gridEndEpoch);
      final progEnd =
          (program.endsAt ?? gridEndEpoch).clamp(gridStartEpoch, gridEndEpoch);

      if (progEnd <= progStart) continue;

      final startOffset = progStart - gridStartEpoch;
      final duration = progEnd - progStart;
      final left = (startOffset / (_minutesPerSlot * 60)) * _slotWidth;
      final width = (duration / (_minutesPerSlot * 60)) * _slotWidth;

      blocks.add(
        Positioned(
          left: left,
          width: width.clamp(2.0, double.infinity),
          top: 0,
          bottom: 0,
          child: _buildProgramBlock(channel, program, theme, isLast: program == programs.last),
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

  Widget _buildProgramBlock(
      LiveTvChannel channel, LiveTvProgram program, ThemeData theme, {bool isLast = false}) {
    final isCurrentlyAiring = program.isCurrentlyAiring;
    final isPast = program.endsAt != null &&
        program.endsAt! < DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Material(
      color: isCurrentlyAiring
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _showProgramDetails(channel, program),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
              right: isLast ? BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)) : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                program.grandparentTitle ?? program.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                      isCurrentlyAiring ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrentlyAiring
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (program.grandparentTitle != null)
                Text(
                  '${program.parentIndex != null && program.index != null ? 'S${program.parentIndex}E${program.index} · ' : ''}${program.title}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrentlyAiring
                        ? theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (program.startTime != null)
                Text(
                  '${program.startTime!.hour.toString().padLeft(2, '0')}:${program.startTime!.minute.toString().padLeft(2, '0')} · ${formatDurationTextual(program.durationMinutes * 60000)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrentlyAiring
                        ? theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showProgramDetails(LiveTvChannel channel, LiveTvProgram program) {
    final theme = Theme.of(context);

    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(channel.serverId ?? '');
    String? posterUrl;
    if (program.thumb != null && client != null) {
      posterUrl = PlexImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: program.thumb,
        maxWidth: 80,
        maxHeight: 120,
        devicePixelRatio: PlexImageHelper.effectiveDevicePixelRatio(context),
        imageType: ImageType.poster,
      );
    }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (posterUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        posterUrl,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.liveTv.live,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${channel.displayName} · ${program.startTime?.hour.toString().padLeft(2, '0')}:${program.startTime?.minute.toString().padLeft(2, '0')} - ${program.endTime?.hour.toString().padLeft(2, '0')}:${program.endTime?.minute.toString().padLeft(2, '0')} · ${formatDurationTextual(program.durationMinutes * 60000)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (program.summary != null &&
                            program.summary!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            program.summary!,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (program.isCurrentlyAiring)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _tuneChannel(channel);
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
}

class _ChannelCell extends StatefulWidget {
  final double rowHeight;
  final double channelColumnWidth;
  final String? imageUrl;
  final LiveTvChannel channel;
  final ThemeData theme;
  final VoidCallback onTap;
  final Widget Function() fallbackBuilder;

  const _ChannelCell({
    required this.rowHeight,
    required this.channelColumnWidth,
    required this.imageUrl,
    required this.channel,
    required this.theme,
    required this.onTap,
    required this.fallbackBuilder,
  });

  @override
  State<_ChannelCell> createState() => _ChannelCellState();
}

class _ChannelCellState extends State<_ChannelCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            height: widget.rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3)),
                right: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _hovered ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.imageUrl!,
                          width: widget.channelColumnWidth - 16,
                          height: widget.rowHeight - 16,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              widget.fallbackBuilder(),
                        )
                      : widget.fallbackBuilder(),
                ),
                if (_hovered)
                  AppIcon(
                    Symbols.play_arrow_rounded,
                    size: 32,
                    color: theme.colorScheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
