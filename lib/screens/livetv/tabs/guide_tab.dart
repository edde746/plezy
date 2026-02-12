import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../focus/key_event_utils.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/livetv_channel.dart';
import '../../../models/livetv_program.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../services/plex_client.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/formatters.dart';
import '../../../utils/plex_image_helper.dart';
import '../../../utils/live_tv_player_navigation.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/plex_optimized_image.dart';
import '../program_details_sheet.dart';

class GuideTab extends StatefulWidget {
  final List<LiveTvChannel> channels;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const GuideTab({super.key, required this.channels, this.onNavigateUp, this.onBack});

  @override
  State<GuideTab> createState() => GuideTabState();
}

enum _GuideZone { timeNav, grid }

class GuideTabState extends State<GuideTab> {
  static const _slotWidth = 180.0;
  static const _channelColumnWidth = 140.0;
  static const _rowHeight = 64.0;
  static const _timeHeaderHeight = 40.0;
  static const _minutesPerSlot = 30;

  List<LiveTvProgram> _programs = [];
  bool _isLoading = true;

  late DateTime _gridStart;
  late DateTime _gridEnd;

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _channelVerticalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  bool _syncingScroll = false;

  Timer? _timeIndicatorTimer;
  final _dayPickerKey = GlobalKey();

  // Focus state
  final FocusNode _guideFocusNode = FocusNode(debugLabel: 'guide_tab');
  _GuideZone _focusZone = _GuideZone.timeNav;
  int _timeNavIndex = 1; // 0=left arrow, 1=day picker, 2=right arrow
  int _gridChannelIndex = 0;
  int _gridColumn = 0; // 0=channel, 1=program
  bool _hasFocus = false;
  LiveTvProgram? _focusedProgram;
  bool _pendingFocus = false;

  /// Focus into the guide content (called from tab bar navigation or initial load).
  void focusContent() {
    // If still loading programs, defer until the Focus widget is in the tree.
    if (_isLoading) {
      _pendingFocus = true;
      return;
    }
    _pendingFocus = false;
    _guideFocusNode.requestFocus();
    setState(() {
      if (widget.channels.isNotEmpty) {
        _focusZone = _GuideZone.grid;
        _gridColumn = 0;
        _gridChannelIndex = 0;
        _focusedProgram = null;
      } else {
        _focusZone = _GuideZone.timeNav;
        _timeNavIndex = 1;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initTimeRange();
    _loadPrograms();

    _gridHorizontalController.addListener(_syncGridToHeader);
    _headerHorizontalController.addListener(_syncHeaderToGrid);

    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void pauseRefresh() => _timeIndicatorTimer?.cancel();

  void resumeRefresh() {
    _timeIndicatorTimer?.cancel();
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(GuideTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channels.isNotEmpty && _gridChannelIndex >= widget.channels.length) {
      _gridChannelIndex = widget.channels.length - 1;
    }
  }

  @override
  void dispose() {
    _guideFocusNode.dispose();
    _gridVerticalController.dispose();
    _gridHorizontalController.removeListener(_syncGridToHeader);
    _headerHorizontalController.removeListener(_syncHeaderToGrid);
    _headerHorizontalController.dispose();
    _gridHorizontalController.dispose();
    _channelVerticalController.dispose();
    _timeIndicatorTimer?.cancel();
    super.dispose();
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
    _loadPrograms();
  }

  void _jumpToNow() {
    _initTimeRange();
    _loadPrograms();
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
      _gridStart = DateTime(day.year, day.month, day.day);
      _gridEnd = _gridStart.add(const Duration(hours: 6));
    });
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;
      final allPrograms = <LiveTvProgram>[];

      for (final serverInfo in liveTvServers) {
        try {
          final client = multiServer.getClientForServer(serverInfo.serverId);
          if (client == null) continue;

          final startEpoch = _gridStart.millisecondsSinceEpoch ~/ 1000;
          final endEpoch = _gridEnd.millisecondsSinceEpoch ~/ 1000;

          final programs = await client.getEpgGrid(
            lineup: serverInfo.lineup,
            beginsAt: startEpoch,
            endsAt: endEpoch,
          );
          allPrograms.addAll(programs);
        } catch (e) {
          appLogger.e('Failed to load programs from server ${serverInfo.serverId}', error: e);
        }
      }

      if (!mounted) return;

      final shouldFocus = _pendingFocus;

      setState(() {
        _programs = allPrograms;
        _isLoading = false;
      });

      _scrollToNow();

      if (shouldFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) focusContent();
        });
      }
    } catch (e) {
      appLogger.e('Failed to load guide programs', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
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
      channels: widget.channels,
    );
  }

  // ---------------------------------------------------------------------------
  // Focus key handling
  // ---------------------------------------------------------------------------

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // Back key
    if (key.isBackKey) {
      if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
        return KeyEventResult.handled;
      }
      if (_focusZone == _GuideZone.grid) {
        if (event is KeyUpEvent) {
          setState(() {
            _focusZone = _GuideZone.timeNav;
            _timeNavIndex = 1;
          });
        }
        return KeyEventResult.handled;
      }
      return handleBackKeyAction(event, () => widget.onBack?.call());
    }

    if (!event.isActionable) return KeyEventResult.ignored;

    if (_focusZone == _GuideZone.timeNav) {
      return _handleTimeNavKey(key);
    } else {
      return _handleGridKey(key);
    }
  }

  KeyEventResult _handleTimeNavKey(LogicalKeyboardKey key) {
    if (key.isLeftKey) {
      if (_timeNavIndex > 0) {
        setState(() => _timeNavIndex--);
      } else {
        widget.onBack?.call();
      }
      return KeyEventResult.handled;
    }
    if (key.isRightKey) {
      if (_timeNavIndex < 2) setState(() => _timeNavIndex++);
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      if (widget.channels.isNotEmpty) {
        setState(() {
          _focusZone = _GuideZone.grid;
          _gridColumn = 0;
          _focusedProgram = null;
        });
        _scrollToChannel(_gridChannelIndex);
      }
      return KeyEventResult.handled;
    }
    if (key.isUpKey) {
      widget.onNavigateUp?.call();
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      switch (_timeNavIndex) {
        case 0:
          _shiftTimeRange(-2);
        case 1:
          _showDayPicker();
        case 2:
          _shiftTimeRange(2);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleGridKey(LogicalKeyboardKey key) {
    if (key.isUpKey) {
      if (_gridChannelIndex > 0) {
        setState(() {
          _gridChannelIndex--;
          if (_gridColumn == 1) _focusedProgram = _findCurrentProgram(_gridChannelIndex);
        });
        _scrollToChannel(_gridChannelIndex);
      } else {
        setState(() {
          _focusZone = _GuideZone.timeNav;
          _timeNavIndex = 1;
        });
      }
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      if (_gridChannelIndex < widget.channels.length - 1) {
        setState(() {
          _gridChannelIndex++;
          if (_gridColumn == 1) _focusedProgram = _findCurrentProgram(_gridChannelIndex);
        });
        _scrollToChannel(_gridChannelIndex);
      }
      return KeyEventResult.handled;
    }
    if (key.isRightKey) {
      if (_gridColumn == 0) {
        final program = _findCurrentProgram(_gridChannelIndex);
        if (program != null) {
          setState(() {
            _gridColumn = 1;
            _focusedProgram = program;
          });
          _scrollToProgramTime(program);
        }
      }
      return KeyEventResult.handled;
    }
    if (key.isLeftKey) {
      if (_gridColumn == 1) {
        setState(() {
          _gridColumn = 0;
          _focusedProgram = null;
        });
      } else {
        widget.onBack?.call();
      }
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      if (_gridChannelIndex >= 0 && _gridChannelIndex < widget.channels.length) {
        final channel = widget.channels[_gridChannelIndex];
        if (_gridColumn == 0) {
          _tuneChannel(channel);
        } else if (_focusedProgram != null) {
          _showProgramDetails(channel, _focusedProgram!);
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------------------
  // Focus helpers
  // ---------------------------------------------------------------------------

  LiveTvProgram? _findCurrentProgram(int channelIndex) {
    if (channelIndex < 0 || channelIndex >= widget.channels.length) return null;
    final channel = widget.channels[channelIndex];
    final programs = _getProgramsForChannel(channel);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Currently airing
    for (final p in programs) {
      if ((p.beginsAt ?? 0) <= now && (p.endsAt ?? 0) > now) return p;
    }
    // First future program
    for (final p in programs) {
      if ((p.endsAt ?? 0) > now) return p;
    }
    return programs.firstOrNull;
  }

  void _scrollToChannel(int index) {
    if (!_gridVerticalController.hasClients) return;
    final targetTop = index * _rowHeight;
    final targetBottom = targetTop + _rowHeight;
    final viewportTop = _gridVerticalController.offset;
    final viewportBottom = viewportTop + _gridVerticalController.position.viewportDimension;

    double? newOffset;
    if (targetTop < viewportTop) {
      newOffset = targetTop;
    } else if (targetBottom > viewportBottom) {
      newOffset = targetBottom - _gridVerticalController.position.viewportDimension;
    }

    if (newOffset != null) {
      final clamped = newOffset.clamp(0.0, _gridVerticalController.position.maxScrollExtent);
      _gridVerticalController.jumpTo(clamped);
      if (_channelVerticalController.hasClients) {
        _channelVerticalController.jumpTo(
          clamped.clamp(0.0, _channelVerticalController.position.maxScrollExtent),
        );
      }
    }
  }

  void _scrollToProgramTime(LiveTvProgram? program) {
    if (program == null || !_gridHorizontalController.hasClients) return;

    final gridStartEpoch = _gridStart.millisecondsSinceEpoch ~/ 1000;
    final gridEndEpoch = _gridEnd.millisecondsSinceEpoch ~/ 1000;
    final progStart = (program.beginsAt ?? gridStartEpoch).clamp(gridStartEpoch, gridEndEpoch);
    final startOffset = progStart - gridStartEpoch;
    final left = (startOffset / (_minutesPerSlot * 60)) * _slotWidth;

    final viewportWidth = _gridHorizontalController.position.viewportDimension;
    final currentOffset = _gridHorizontalController.offset;

    if (left < currentOffset || left > currentOffset + viewportWidth - 100) {
      final maxScroll = _gridHorizontalController.position.maxScrollExtent;
      _gridHorizontalController.jumpTo((left - 50).clamp(0.0, maxScroll));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Focus(
      focusNode: _guideFocusNode,
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: _buildGuideGrid(theme),
    );
  }

  Widget _buildGuideGrid(ThemeData theme) {
    return Column(
      children: [
        _buildTimeNavigation(theme),
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
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: _channelColumnWidth,
                child: ListView.builder(
                  controller: _channelVerticalController,
                  itemCount: widget.channels.length,
                  itemExtent: _rowHeight,
                  itemBuilder: (context, index) =>
                      _buildChannelCell(widget.channels[index], theme, index: index),
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
                        controller: _gridVerticalController,
                        itemCount: widget.channels.length,
                        itemExtent: _rowHeight,
                        itemBuilder: (context, index) {
                          final channel = widget.channels[index];
                          final programs = _getProgramsForChannel(channel);
                          return _buildProgramRow(channel, programs, theme, channelIndex: index);
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
      if (value == null) {
        _guideFocusNode.requestFocus();
        return;
      }
      if (value is String && value == 'now') {
        _jumpToNow();
        _guideFocusNode.requestFocus();
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
      if (value == null) {
        _guideFocusNode.requestFocus();
        return;
      }
      if (value == -1) {
        _showDayPicker();
        return;
      }
      setState(() {
        _gridStart = DateTime(day.year, day.month, day.day, value);
        _gridEnd = _gridStart.add(const Duration(hours: 6));
      });
      _loadPrograms();
      _guideFocusNode.requestFocus();
    });
  }

  // ---------------------------------------------------------------------------
  // Time navigation bar
  // ---------------------------------------------------------------------------

  Widget _timeNavFocusWrap({required Widget child, required int index, required ThemeData theme}) {
    final isFocused = _hasFocus && _focusZone == _GuideZone.timeNav && _timeNavIndex == index;
    if (!isFocused) return child;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
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
          _timeNavFocusWrap(
            index: 0,
            theme: theme,
            child: IconButton(
              icon: const AppIcon(Symbols.chevron_left_rounded),
              onPressed: () => _shiftTimeRange(-2),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeNavFocusWrap(
                  index: 1,
                  theme: theme,
                  child: GestureDetector(
                    key: _dayPickerKey,
                    onTap: _showDayPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          _timeNavFocusWrap(
            index: 2,
            theme: theme,
            child: IconButton(
              icon: const AppIcon(Symbols.chevron_right_rounded),
              onPressed: () => _shiftTimeRange(2),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Time header & now indicator
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Channel column
  // ---------------------------------------------------------------------------

  Widget _buildChannelCell(LiveTvChannel channel, ThemeData theme, {required int index}) {
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(channel.serverId ?? '');

    final isFocused = _hasFocus && _focusZone == _GuideZone.grid && _gridColumn == 0 && _gridChannelIndex == index;

    return _ChannelCell(
      rowHeight: _rowHeight,
      channelColumnWidth: _channelColumnWidth,
      channelThumb: channel.thumb,
      client: client,
      channel: channel,
      theme: theme,
      onTap: () => _tuneChannel(channel),
      isFocused: isFocused,
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

  // ---------------------------------------------------------------------------
  // Program grid
  // ---------------------------------------------------------------------------

  Widget _buildProgramRow(
      LiveTvChannel channel, List<LiveTvProgram> programs, ThemeData theme,
      {required int channelIndex}) {
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

    // Determine which program is focused in this row
    final focusProg = (_hasFocus &&
            _focusZone == _GuideZone.grid &&
            _gridColumn == 1 &&
            _gridChannelIndex == channelIndex)
        ? _focusedProgram
        : null;

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
          child: _buildProgramBlock(
            channel, program, theme,
            isLast: program == programs.last,
            isFocused: identical(program, focusProg),
          ),
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
      LiveTvChannel channel, LiveTvProgram program, ThemeData theme,
      {bool isLast = false, bool isFocused = false}) {
    final isCurrentlyAiring = program.isCurrentlyAiring;
    final isPast = program.endsAt != null &&
        program.endsAt! < DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Material(
        color: isFocused
            ? theme.colorScheme.primary.withValues(alpha: 0.25)
            : isCurrentlyAiring
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: isFocused
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          canRequestFocus: false,
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
                    color: isFocused
                        ? theme.colorScheme.primary
                        : isCurrentlyAiring
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
                      color: isFocused
                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                          : isCurrentlyAiring
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
                      color: isFocused
                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                          : isCurrentlyAiring
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

    showProgramDetailsSheet(
      context,
      program: program,
      channel: channel,
      posterUrl: posterUrl,
      onTuneChannel: () => _tuneChannel(channel),
    );
  }
}

class _ChannelCell extends StatefulWidget {
  final double rowHeight;
  final double channelColumnWidth;
  final String? channelThumb;
  final PlexClient? client;
  final LiveTvChannel channel;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool isFocused;
  final Widget Function() fallbackBuilder;

  const _ChannelCell({
    required this.rowHeight,
    required this.channelColumnWidth,
    required this.channelThumb,
    required this.client,
    required this.channel,
    required this.theme,
    required this.onTap,
    required this.isFocused,
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
    final showAction = _hovered || widget.isFocused;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.isFocused
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        child: InkWell(
          canRequestFocus: false,
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
                  opacity: showAction ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: widget.channelThumb != null && widget.client != null
                      ? PlexOptimizedImage.thumb(
                          client: widget.client!,
                          imagePath: widget.channelThumb,
                          width: widget.channelColumnWidth - 16,
                          height: widget.rowHeight - 16,
                          fit: BoxFit.contain,
                        )
                      : widget.fallbackBuilder(),
                ),
                if (showAction)
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
