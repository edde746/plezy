import 'dart:async';
import '../../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../focus/key_event_utils.dart';
import '../../../i18n/strings.g.dart';
import '../../../mixins/mounted_set_state_mixin.dart';
import '../../../models/livetv_channel.dart';
import '../../../models/livetv_program.dart';
import '../../../models/media_grab_operation.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../media/media_server_client.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/formatters.dart';
import '../../../utils/live_tv_grouping.dart';
import '../../../utils/live_tv_matching.dart';
import '../../../utils/media_image_helper.dart';
import '../../../utils/live_tv_player_navigation.dart';
import '../../../utils/platform_detector.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/app_menu.dart';
import '../../../widgets/clickable_cursor.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../widgets/optimized_media_image.dart';
import '../program_details_sheet.dart';

class GuideTab extends StatefulWidget {
  final List<LiveTvChannel> channels;
  final bool Function(LiveTvChannel channel)? isFavoriteChannel;
  final void Function(LiveTvChannel)? onToggleFavorite;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const GuideTab({
    super.key,
    required this.channels,
    this.isFavoriteChannel,
    this.onToggleFavorite,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  State<GuideTab> createState() => GuideTabState();
}

enum _GuideZone { timeNav, grid }

sealed class _GuideRow {
  const _GuideRow();
}

final class _GuideSourceHeaderRow extends _GuideRow {
  final String label;

  const _GuideSourceHeaderRow({required this.label});
}

final class _GuideChannelRow extends _GuideRow {
  final LiveTvChannel channel;
  final int channelIndex;

  const _GuideChannelRow({required this.channel, required this.channelIndex});
}

class GuideTabState extends State<GuideTab> with MountedSetStateMixin, WidgetsBindingObserver {
  static const _slotWidth = 180.0;
  static const _channelColumnWidth = 132.0;
  static const _rowHeight = 64.0;
  static const _sourceHeaderRowHeight = 40.0;
  static const _timeHeaderHeight = 40.0;
  static const _minutesPerSlot = 30;
  static const _longPressDuration = Duration(milliseconds: 500);

  /// Minimum time away (backgrounded or on another section) before the
  /// viewport is realigned to the live line on return.
  static const _realignAfterAway = Duration(minutes: 30);

  List<LiveTvProgram> _programs = [];
  Set<String> _scheduledRecordingKeys = const {};
  bool _isLoading = true;

  late DateTime _gridStart;
  late DateTime _gridEnd;

  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  final ScrollController _channelVerticalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  bool _syncingScroll = false;

  Timer? _timeIndicatorTimer;
  Timer? _programSelectLongPressTimer;
  final _dayPickerKey = GlobalKey();

  // Stale-window catch-up state (#1297). The grid window is only auto
  // re-anchored when it was live-anchored and has drifted fully into the
  // past — deliberately picked day/time windows are never yanked.
  bool _isGuideVisible = true;
  DateTime? _hiddenSince;
  bool _nowWasInWindow = true;

  // Focus state
  final FocusNode _guideFocusNode = FocusNode(debugLabel: 'guide_tab');
  _GuideZone _focusZone = _GuideZone.timeNav;
  int _timeNavIndex = 1; // 0=left arrow, 1=day picker, 2=right arrow
  int _gridChannelIndex = 0;
  int _gridColumn = 0; // 0=channel, 1=program
  bool _hasFocus = false;
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier(false);
  LiveTvProgram? _focusedProgram;
  bool _pendingFocus = false;
  bool _isProgramSelectKeyDown = false;

  /// Focus into the guide content (called from tab bar navigation or initial load).
  void focusContent() {
    if (!InputModeTracker.isKeyboardMode(context)) return;
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
    WidgetsBinding.instance.addObserver(this);
    _initTimeRange();
    _loadPrograms();

    _gridHorizontalController.addListener(_syncGridToHeader);
    _headerHorizontalController.addListener(_syncHeaderToGrid);

    _startTimeIndicatorTimer();
  }

  void _startTimeIndicatorTimer() {
    _timeIndicatorTimer?.cancel();
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkWindowDrift();
      // ignore: no-empty-block - setState triggers rebuild to update time indicator
      setStateIfMounted(() {});
    });
  }

  void pauseRefresh() {
    _hiddenSince ??= DateTime.now();
    _timeIndicatorTimer?.cancel();
  }

  void resumeRefresh() {
    _startTimeIndicatorTimer();
    unawaited(_refreshScheduledRecordingKeys());
    // Post-frame: resumeRefresh is invoked during tab transitions/build and
    // the catch-up may setState (reload or scroll).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _catchUpIfStale();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribes to TickerMode, so this fires whenever the guide is shown or
    // hidden (main-screen IndexedStack section switch, opaque route push/pop).
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _isGuideVisible) return;
    _isGuideVisible = visible;
    visible ? resumeRefresh() : pauseRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _hiddenSince ??= DateTime.now();
      case AppLifecycleState.resumed:
        _catchUpIfStale();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _programSelectLongPressTimer?.cancel();
    _guideFocusNode.dispose();
    _gridVerticalController.dispose();
    _gridHorizontalController.removeListener(_syncGridToHeader);
    _headerHorizontalController.removeListener(_syncHeaderToGrid);
    _headerHorizontalController.dispose();
    _gridHorizontalController.dispose();
    _channelVerticalController.dispose();
    _timeIndicatorTimer?.cancel();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  void _handleGuideFocusChange(bool hasFocus) {
    if (_hasFocus == hasFocus) return;
    if (!hasFocus) _resetProgramSelectLongPressState();
    _hasFocus = hasFocus;
    _hasFocusNotifier.value = hasFocus;
  }

  void _resetProgramSelectLongPressState() {
    _programSelectLongPressTimer?.cancel();
    _isProgramSelectKeyDown = false;
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
    _nowWasInWindow = true;
  }

  void _shiftTimeRange(int hours) {
    setState(() {
      _gridStart = _gridStart.add(Duration(hours: hours));
      _gridEnd = _gridStart.add(const Duration(hours: 6));
      _nowWasInWindow = _nowInWindow(DateTime.now());
    });
    _loadPrograms();
  }

  void _jumpToNow() {
    _initTimeRange();
    _loadPrograms();
  }

  bool _nowInWindow(DateTime now) => !now.isBefore(_gridStart) && now.isBefore(_gridEnd);

  /// Timer path: re-anchor only when a live-anchored window drifted fully past.
  void _checkWindowDrift() {
    if (!_isGuideVisible || _isLoading) return;
    if (_nowWasInWindow && !_nowInWindow(DateTime.now())) _jumpToNow();
  }

  /// Active path (app resume / guide became visible): drift-jump, else
  /// realign the viewport to the live line after a meaningful absence (#1297).
  void _catchUpIfStale() {
    if (!_isGuideVisible) return; // still hidden — keep _hiddenSince
    final hiddenSince = _hiddenSince;
    _hiddenSince = null; // evaluated while visible — consume it
    if (_isLoading) return; // in-flight load already ends in _scrollToNow()
    final now = DateTime.now();
    if (_nowWasInWindow && !_nowInWindow(now)) {
      _jumpToNow();
    } else if (_nowInWindow(now) && hiddenSince != null && now.difference(hiddenSince) >= _realignAfterAway) {
      _scrollToNow();
    }
  }

  Future<void> _loadPrograms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;
      final allPrograms = <LiveTvProgram>[];
      final scheduledRecordingKeys = <String>{};
      final queriedServers = <String>{};

      for (final serverInfo in liveTvServers) {
        if (!queriedServers.add(serverInfo.serverId)) continue;
        try {
          final genericClient = multiServer.getClientForServer(ServerId(serverInfo.serverId));
          if (genericClient == null) continue;

          final startEpoch = _gridStart.millisecondsSinceEpoch ~/ 1000;
          final endEpoch = _gridEnd.millisecondsSinceEpoch ~/ 1000;

          final fromDt = DateTime.fromMillisecondsSinceEpoch(startEpoch * 1000, isUtc: true);
          final toDt = DateTime.fromMillisecondsSinceEpoch(endEpoch * 1000, isUtc: true);
          final programs = await genericClient.liveTv.fetchSchedule(from: fromDt, to: toDt);
          allPrograms.addAll(programs);
          await _addScheduledRecordingKeysForServer(
            client: genericClient,
            serverId: ServerId(serverInfo.serverId),
            keys: scheduledRecordingKeys,
          );
        } catch (e) {
          appLogger.e('Failed to load programs from server ${serverInfo.serverId}', error: e);
        }
      }

      if (!mounted) return;

      final shouldFocus = _pendingFocus;

      setState(() {
        _programs = allPrograms;
        _scheduledRecordingKeys = scheduledRecordingKeys;
        _isLoading = false;
        // Focus tracking compares by identity, so a reload orphans the
        // focused program — re-resolve it against the fresh list.
        if (_focusZone == _GuideZone.grid && _gridColumn == 1 && _focusedProgram != null) {
          final focused = _focusedProgram;
          if (!_programs.any((p) => identical(p, focused))) {
            _focusedProgram = _findCurrentProgram(_gridChannelIndex);
          }
        }
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

  Future<void> _refreshScheduledRecordingKeys() async {
    if (!mounted) return;
    final multiServer = context.read<MultiServerProvider>();
    final scheduledRecordingKeys = <String>{};
    final queriedServers = <String>{};

    for (final serverInfo in multiServer.liveTvServers) {
      if (!queriedServers.add(serverInfo.serverId)) continue;
      final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
      if (client == null) continue;
      await _addScheduledRecordingKeysForServer(
        client: client,
        serverId: ServerId(serverInfo.serverId),
        keys: scheduledRecordingKeys,
      );
    }

    if (!mounted) return;
    setState(() => _scheduledRecordingKeys = scheduledRecordingKeys);
  }

  Future<void> _addScheduledRecordingKeysForServer({
    required MediaServerClient client,
    required ServerId serverId,
    required Set<String> keys,
  }) async {
    if (!client.capabilities.liveTvDvr) return;
    try {
      final grabs = await client.liveTv.fetchScheduledRecordings();
      for (final grab in grabs) {
        _addRecordingKeysForGrab(grab, serverId: ServerId(serverId), keys: keys);
      }
    } catch (e) {
      appLogger.d('Failed to load scheduled recordings for $serverId', error: e);
    }

    try {
      final rules = await client.liveTv.fetchRecordingRules(includeGrabs: true, includeStorage: false);
      for (final rule in rules) {
        for (final grab in rule.grabOperations) {
          _addRecordingKeysForGrab(grab, serverId: ServerId(serverId), keys: keys);
        }
      }
    } catch (e) {
      appLogger.d('Failed to load active recording grabs for $serverId', error: e);
    }
  }

  void _addRecordingKeysForGrab(MediaGrabOperation grab, {required ServerId serverId, required Set<String> keys}) {
    if (!_isActiveScheduledGrab(grab)) return;
    final program = grab.program;
    if (program == null) return;
    keys.addAll(_recordingKeysForProgram(program, fallbackServerId: serverId));
  }

  bool _isActiveScheduledGrab(MediaGrabOperation grab) {
    final status = grab.status?.trim().toLowerCase();
    return status == null || status.isEmpty || status == 'scheduled' || status == 'grabbing' || status == 'recording';
  }

  bool _isRecordingScheduled(LiveTvProgram program) {
    final keys = _recordingKeysForProgram(program);
    return keys.any(_scheduledRecordingKeys.contains);
  }

  void _handleRecordingStateChanged(LiveTvProgram program, bool isScheduled) {
    final keys = _recordingKeysForProgram(program);
    if (keys.isNotEmpty) {
      setState(() {
        final next = {..._scheduledRecordingKeys};
        if (isScheduled) {
          next.addAll(keys);
        } else {
          next.removeAll(keys);
        }
        _scheduledRecordingKeys = next;
      });
    }
    unawaited(_refreshScheduledRecordingKeys());
  }

  Set<String> _recordingKeysForProgram(LiveTvProgram program, {String? fallbackServerId}) {
    final serverId = _nonEmpty(program.serverId) ?? _nonEmpty(fallbackServerId);
    if (serverId == null) return const <String>{};

    final keys = <String>{};
    void addMediaId(String? value) {
      final normalized = _nonEmpty(value);
      if (normalized != null) keys.add(_recordingKey(ServerId(serverId), 'media', normalized));
    }

    addMediaId(program.ratingKey);
    addMediaId(program.guid);
    addMediaId(program.key);

    final channelIdentifier = _nonEmpty(program.channelIdentifier);
    final beginsAt = program.beginsAt;
    if (channelIdentifier != null && beginsAt != null) {
      keys.add(_recordingKey(ServerId(serverId), 'slot', '$channelIdentifier|$beginsAt|${program.endsAt ?? ''}'));
    }

    return keys;
  }

  String _recordingKey(ServerId serverId, String type, String value) => '$serverId\u0000$type\u0000$value';

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<_GuideRow> get _guideRows {
    final groups = groupLiveTvChannelsBySource(widget.channels);
    if (groups.length <= 1) {
      return [
        for (var i = 0; i < widget.channels.length; i++) _GuideChannelRow(channel: widget.channels[i], channelIndex: i),
      ];
    }

    final channelIndexes = <LiveTvChannel, int>{};
    for (var i = 0; i < widget.channels.length; i++) {
      channelIndexes[widget.channels[i]] = i;
    }

    return [
      for (final group in groups) ...[
        _GuideSourceHeaderRow(label: group.label),
        for (final channel in group.channels)
          _GuideChannelRow(channel: channel, channelIndex: channelIndexes[channel] ?? 0),
      ],
    ];
  }

  double _guideRowHeight(_GuideRow row) {
    return switch (row) {
      _GuideSourceHeaderRow() => _sourceHeaderRowHeight,
      _GuideChannelRow() => _rowHeight,
    };
  }

  double _guideContentHeight(List<_GuideRow> rows) {
    var height = 0.0;
    for (final row in rows) {
      height += _guideRowHeight(row);
    }
    return height;
  }

  double _rowTopForChannelIndex(int channelIndex) {
    var top = 0.0;
    for (final row in _guideRows) {
      if (row is _GuideChannelRow && row.channelIndex == channelIndex) return top;
      top += _guideRowHeight(row);
    }
    return channelIndex * _rowHeight;
  }

  void _scrollToNow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final minutesSinceStart = now.difference(_gridStart).inMinutes;
      final offset = (minutesSinceStart / _minutesPerSlot) * _slotWidth;
      if (_gridHorizontalController.hasClients) {
        _gridHorizontalController.jumpTo(
          (offset - MediaQuery.sizeOf(context).width / 3).clamp(0, _gridHorizontalController.position.maxScrollExtent),
        );
      }
    });
  }

  List<LiveTvProgram> _getProgramsForChannel(LiveTvChannel channel) {
    return _programs.where((program) => liveTvProgramMatchesChannel(program, channel)).toList()
      ..sort((a, b) => (a.beginsAt ?? 0).compareTo(b.beginsAt ?? 0));
  }

  double _totalGridWidth() {
    final totalMinutes = _gridEnd.difference(_gridStart).inMinutes;
    return (totalMinutes / _minutesPerSlot) * _slotWidth;
  }

  Future<void> _tuneChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();
    await tuneAndNavigateToLiveTv(context, multiServer: multiServer, channel: channel, channels: widget.channels);
  }

  void _activateProgram(LiveTvChannel channel, LiveTvProgram program) {
    if (PlatformDetector.isTV() && program.isCurrentlyAiring) {
      _tuneChannel(channel);
      return;
    }

    _showProgramDetails(channel, program);
  }

  ({LiveTvChannel channel, LiveTvProgram program})? _focusedProgramTarget() {
    if (_focusZone != _GuideZone.grid || _gridColumn != 1) return null;
    final program = _focusedProgram;
    if (program == null) return null;
    if (_gridChannelIndex < 0 || _gridChannelIndex >= widget.channels.length) return null;

    return (channel: widget.channels[_gridChannelIndex], program: program);
  }

  KeyEventResult _handleFocusedProgramSelectKey(KeyEvent event) {
    if (!event.logicalKey.isSelectKey) return KeyEventResult.ignored;
    final target = _focusedProgramTarget();
    if (target == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (!_isProgramSelectKeyDown) {
        _isProgramSelectKeyDown = true;
        _programSelectLongPressTimer?.cancel();
        _programSelectLongPressTimer = Timer(_longPressDuration, () {
          if (!mounted || !_isProgramSelectKeyDown) return;
          SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
          _resetProgramSelectLongPressState();
          _showProgramDetails(target.channel, target.program);
        });
      }
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      final timerWasActive = _programSelectLongPressTimer?.isActive ?? false;
      _programSelectLongPressTimer?.cancel();
      if (timerWasActive && _isProgramSelectKeyDown) {
        _activateProgram(target.channel, target.program);
      }
      _isProgramSelectKeyDown = false;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFocusedProgramContextMenuKey(KeyEvent event) {
    if (!event.logicalKey.isContextMenuKey || !event.isActionable) return KeyEventResult.ignored;
    final target = _focusedProgramTarget();
    if (target == null) return KeyEventResult.ignored;

    _resetProgramSelectLongPressState();
    _showProgramDetails(target.channel, target.program);
    return KeyEventResult.handled;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      if (event is KeyUpEvent && key.isSelectKey) {
        _resetProgramSelectLongPressState();
      }
      return KeyEventResult.handled;
    }

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

    if (PlatformDetector.isTV()) {
      final selectResult = _handleFocusedProgramSelectKey(event);
      if (selectResult != KeyEventResult.ignored) return selectResult;
    }

    final contextMenuResult = _handleFocusedProgramContextMenuKey(event);
    if (contextMenuResult != KeyEventResult.ignored) return contextMenuResult;

    if (!event.isActionable) return KeyEventResult.ignored;

    return _focusZone == _GuideZone.timeNav ? _handleTimeNavKey(key) : _handleGridKey(key);
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
      } else {
        // Already in program column — move to next program
        _navigateToAdjacentProgram(_gridChannelIndex, forward: true);
      }
      return KeyEventResult.handled;
    }
    if (key.isLeftKey) {
      if (_gridColumn == 1) {
        // Try moving to previous program; if at first program, go back to channel column
        if (!_navigateToAdjacentProgram(_gridChannelIndex, forward: false)) {
          setState(() {
            _gridColumn = 0;
            _focusedProgram = null;
          });
        }
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
          _activateProgram(channel, _focusedProgram!);
        }
      }
      return KeyEventResult.handled;
    }
    // 'F' key toggles favorite on focused channel
    if (key == LogicalKeyboardKey.keyF && _gridColumn == 0) {
      if (_gridChannelIndex >= 0 && _gridChannelIndex < widget.channels.length) {
        widget.onToggleFavorite?.call(widget.channels[_gridChannelIndex]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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

  /// Navigate to the next or previous program on the same channel.
  /// Returns true if navigation succeeded, false if at the boundary.
  bool _navigateToAdjacentProgram(int channelIndex, {required bool forward}) {
    if (channelIndex < 0 || channelIndex >= widget.channels.length) return false;
    final channel = widget.channels[channelIndex];
    final programs = _getProgramsForChannel(channel);
    if (programs.isEmpty || _focusedProgram == null) return false;

    final currentIndex = programs.indexWhere((p) => identical(p, _focusedProgram));
    if (currentIndex < 0) return false;

    final nextIndex = forward ? currentIndex + 1 : currentIndex - 1;
    if (nextIndex < 0 || nextIndex >= programs.length) return false;

    setState(() {
      _focusedProgram = programs[nextIndex];
    });
    _scrollToProgramTime(_focusedProgram);
    return true;
  }

  void _scrollToChannel(int index) {
    if (!_gridVerticalController.hasClients) return;
    final targetTop = _rowTopForChannelIndex(index);
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
      _gridVerticalController.animateTo(clamped, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      if (_channelVerticalController.hasClients) {
        _channelVerticalController.animateTo(
          clamped.clamp(0.0, _channelVerticalController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return OverlaySheetHost(
      child: Focus(
        focusNode: _guideFocusNode,
        onFocusChange: _handleGuideFocusChange,
        onKeyEvent: _handleKeyEvent,
        child: _buildGuideGrid(theme),
      ),
    );
  }

  Widget _buildGuideGrid(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasFocusNotifier,
      builder: (context, hasFocus, child) {
        final rows = _guideRows;
        return Column(
          children: [
            _buildTimeNavigation(theme),
            Expanded(
              child: ListenableBuilder(
                listenable: _gridHorizontalController,
                builder: (context, child) {
                  return Stack(children: [child!, _buildNowIndicatorOverlay(theme)]);
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: _channelColumnWidth, height: _timeHeaderHeight),
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
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                return switch (row) {
                                  _GuideSourceHeaderRow(:final label) => _buildSourceHeaderCell(label, theme),
                                  _GuideChannelRow(:final channel, :final channelIndex) => _buildChannelCell(
                                    channel,
                                    theme,
                                    index: channelIndex,
                                  ),
                                };
                              },
                            ),
                          ),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
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
                                physics: const ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: _totalGridWidth(),
                                  child: ListView.builder(
                                    controller: _gridVerticalController,
                                    itemCount: rows.length,
                                    itemBuilder: (context, index) {
                                      final row = rows[index];
                                      return switch (row) {
                                        _GuideSourceHeaderRow(:final label) => _buildSourceHeaderGridRow(label, theme),
                                        _GuideChannelRow(:final channel, :final channelIndex) => _buildProgramRow(
                                          channel,
                                          _getProgramsForChannel(channel),
                                          theme,
                                          channelIndex: channelIndex,
                                        ),
                                      };
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNowIndicatorOverlay(ThemeData _) {
    final now = DateTime.now();
    if (now.isBefore(_gridStart) || now.isAfter(_gridEnd)) {
      return const SizedBox.shrink();
    }
    final minutesSinceStart = now.difference(_gridStart).inMinutes.toDouble();
    final nowOffset = (minutesSinceStart / _minutesPerSlot) * _slotWidth;
    final scrollOffset = _gridHorizontalController.hasClients ? _gridHorizontalController.offset : 0.0;
    final left = _channelColumnWidth + nowOffset - scrollOffset;

    // Hide when scrolled behind the channel column
    if (left < _channelColumnWidth) return const SizedBox.shrink();

    final gridHeight = _timeHeaderHeight + _guideContentHeight(_guideRows);

    return Positioned(
      left: left,
      top: 0,
      height: gridHeight,
      child: IgnorePointer(child: Container(width: 2, color: Colors.red)),
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target == today) return t.liveTv.today;

    return DateFormat('EEEE', LocaleSettings.currentLocale.languageCode).format(target);
  }

  List<(String, int)> get _timeSlots => [
    (t.liveTv.midnight, 0),
    (t.liveTv.overnight, 2),
    (t.liveTv.morning, 6),
    (t.liveTv.daytime, 12),
    (t.liveTv.evening, 18),
    (t.liveTv.lateNight, 22),
  ];

  Rect? _menuAnchorRect() {
    final renderBox = _dayPickerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    return Rect.fromLTWH(buttonPos.dx, buttonPos.dy, buttonSize.width, buttonSize.height);
  }

  Future<void> _showDayPicker() async {
    final anchorRect = _menuAnchorRect();
    if (anchorRect == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gridDay = DateTime(_gridStart.year, _gridStart.month, _gridStart.day);

    final days = <DateTime>[];
    for (var i = 0; i < 8; i++) {
      days.add(today.add(Duration(days: i)));
    }

    final value = await showAppMenu<Object>(
      context,
      anchorRect: anchorRect,
      focusFirstItem: InputModeTracker.isKeyboardMode(context),
      entries: [
        AppMenuItem<Object>(value: 'now', label: t.liveTv.now),
        ...days.map((day) {
          final isSelected = day == gridDay;
          final label = _dayLabel(day);
          return AppMenuItem<Object>(value: day, label: label, selected: isSelected);
        }),
      ],
    );
    if (!mounted) return;
    if (value == null) {
      _guideFocusNode.requestFocus();
      return;
    }
    if (value is String && value == 'now') {
      _jumpToNow();
      _guideFocusNode.requestFocus();
    } else if (value is DateTime) {
      await _showTimeSlotPicker(value);
    }
  }

  Future<void> _showTimeSlotPicker(DateTime day) async {
    final anchorRect = _menuAnchorRect();
    if (anchorRect == null) return;

    final label = _dayLabel(day).toUpperCase();

    final value = await showAppMenu<int>(
      context,
      anchorRect: anchorRect,
      focusFirstItem: InputModeTracker.isKeyboardMode(context),
      entries: [
        AppMenuItem<int>(
          value: -1,
          icon: Symbols.chevron_left_rounded,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: .bold)),
        ),
        const AppMenuDivider<int>(),
        ..._timeSlots.map((slot) {
          return AppMenuItem<int>(value: slot.$2, label: slot.$1);
        }),
      ],
    );
    if (value == null) {
      _guideFocusNode.requestFocus();
      return;
    }
    if (value == -1) {
      await _showDayPicker();
      return;
    }
    setState(() {
      _gridStart = DateTime(day.year, day.month, day.day, value);
      _gridEnd = _gridStart.add(const Duration(hours: 6));
      _nowWasInWindow = _nowInWindow(DateTime.now());
    });
    _loadPrograms();
    _guideFocusNode.requestFocus();
  }

  Widget _timeNavFocusWrap({required Widget child, required int index, required ThemeData theme}) {
    final isFocused = _hasFocus && _focusZone == _GuideZone.timeNav && _timeNavIndex == index;
    if (!isFocused) return child;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: child,
    );
  }

  Widget _buildTimeNavigation(ThemeData theme) {
    final timeLabel = formatClockTime(_gridStart, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
    final dayLabel = _dayLabel(_gridStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
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
              mainAxisAlignment: .center,
              children: [
                _timeNavFocusWrap(
                  index: 1,
                  theme: theme,
                  child: ClickableCursor(
                    child: GestureDetector(
                      key: _dayPickerKey,
                      onTap: _showDayPicker,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: .min,
                          children: [
                            Text(dayLabel, style: theme.textTheme.labelLarge),
                            const SizedBox(width: 2),
                            AppIcon(Symbols.arrow_drop_down_rounded, size: 18, color: theme.colorScheme.onSurface),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(timeLabel, style: theme.textTheme.labelLarge),
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

  Widget _buildTimeHeader(ThemeData theme) {
    final is24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final slots = <Widget>[];
    var current = _gridStart;

    while (current.isBefore(_gridEnd)) {
      final timeStr = formatClockTime(current, is24Hour: is24Hour);
      slots.add(
        SizedBox(
          width: _slotWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: .centerLeft,
              child: Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      );
      current = current.add(const Duration(minutes: _minutesPerSlot));
    }

    return Row(children: slots);
  }

  Widget _buildSourceHeaderCell(String label, ThemeData theme) {
    return Container(
      height: _sourceHeaderRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      alignment: .centerLeft,
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: .w700),
        maxLines: 2,
        overflow: .ellipsis,
      ),
    );
  }

  Widget _buildSourceHeaderGridRow(String label, ThemeData theme) {
    return Container(
      height: _sourceHeaderRowHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      child: ClipRect(
        child: ListenableBuilder(
          listenable: _gridHorizontalController,
          builder: (context, child) {
            final scrollOffset = _gridHorizontalController.hasClients ? _gridHorizontalController.offset : 0.0;
            return Transform.translate(offset: Offset(scrollOffset, 0), child: child);
          },
          child: Align(
            alignment: .centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: .w700,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCell(LiveTvChannel channel, ThemeData theme, {required int index}) {
    final multiServer = context.read<MultiServerProvider>();
    final serverId = serverIdOrNull(channel.serverId);
    final client = serverId == null ? null : multiServer.getClientForServer(serverId);

    final isFocused = _hasFocus && _focusZone == _GuideZone.grid && _gridColumn == 0 && _gridChannelIndex == index;

    return _ChannelCell(
      rowHeight: _rowHeight,
      channelColumnWidth: _channelColumnWidth,
      channelThumb: channel.thumb,
      client: client,
      channel: channel,
      theme: theme,
      onTap: () => _tuneChannel(channel),
      onLongPress: widget.onToggleFavorite != null ? () => widget.onToggleFavorite!(channel) : null,
      isFocused: isFocused,
      isFavorite: widget.isFavoriteChannel?.call(channel) ?? false,
      fallbackBuilder: () => _buildChannelNameFallback(channel, theme),
    );
  }

  Widget _buildChannelNameFallback(LiveTvChannel channel, ThemeData theme) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        if (channel.number != null)
          Text(
            channel.number!,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
          ),
        Text(
          channel.displayName,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: .w500),
          maxLines: 1,
          overflow: .ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgramRow(
    LiveTvChannel channel,
    List<LiveTvProgram> programs,
    ThemeData theme, {
    required int channelIndex,
  }) {
    if (programs.isEmpty) {
      return Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
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

    // Determine which program is focused in this row
    final focusProg =
        (_hasFocus && _focusZone == _GuideZone.grid && _gridColumn == 1 && _gridChannelIndex == channelIndex)
        ? _focusedProgram
        : null;

    for (final program in programs) {
      final progStart = (program.beginsAt ?? gridStartEpoch).clamp(gridStartEpoch, gridEndEpoch);
      final progEnd = (program.endsAt ?? gridEndEpoch).clamp(gridStartEpoch, gridEndEpoch);

      if (progEnd <= progStart) continue;

      final startOffset = progStart - gridStartEpoch;
      final duration = progEnd - progStart;
      final left = (startOffset / (_minutesPerSlot * 60)) * _slotWidth;
      final width = (duration / (_minutesPerSlot * 60)) * _slotWidth;
      final clampedWidth = width.clamp(2.0, double.infinity);

      blocks.add(
        Positioned(
          left: left,
          width: clampedWidth,
          top: 0,
          bottom: 0,
          child: _buildProgramBlock(
            channel,
            program,
            theme,
            isFirst: progStart == gridStartEpoch,
            isLast: program == programs.last && progEnd != gridEndEpoch,
            isFocused: identical(program, focusProg),
            tileLeft: left,
            tileWidth: clampedWidth,
          ),
        ),
      );
    }

    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Stack(children: blocks),
    );
  }

  Widget _buildProgramBlock(
    LiveTvChannel channel,
    LiveTvProgram program,
    ThemeData theme, {
    bool isFirst = false,
    bool isLast = false,
    bool isFocused = false,
    double tileLeft = 0,
    double tileWidth = 0,
  }) {
    final isCurrentlyAiring = program.isCurrentlyAiring;
    final isPast = program.endsAt != null && program.endsAt! < DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isRecordingScheduled = _isRecordingScheduled(program);

    Color materialColor;
    if (isFocused) {
      materialColor = theme.colorScheme.primary.withValues(alpha: 0.15);
    } else if (isCurrentlyAiring) {
      materialColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    } else {
      materialColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
    }

    Color titleColor;
    if (isFocused) {
      titleColor = theme.colorScheme.primary;
    } else if (isCurrentlyAiring) {
      titleColor = theme.colorScheme.onSurface;
    } else {
      titleColor = theme.colorScheme.onSurface;
    }

    Color subtitleColor;
    if (isFocused) {
      subtitleColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    } else if (isCurrentlyAiring) {
      subtitleColor = theme.colorScheme.onSurfaceVariant;
    } else {
      subtitleColor = theme.colorScheme.onSurfaceVariant;
    }

    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Material(
        color: isFocused ? materialColor : Colors.transparent,
        shape: RoundedRectangleBorder(
          side: isFocused ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          canRequestFocus: false,
          onTap: () => _activateProgram(channel, program),
          onLongPress: () => _showProgramDetails(channel, program),
          onSecondaryTap: () => _showProgramDetails(channel, program),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: isFirst ? BorderSide.none : BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                right: isLast ? BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)) : BorderSide.none,
              ),
            ),
            child: ListenableBuilder(
              listenable: _gridHorizontalController,
              builder: (context, _) {
                const basePadding = 6.0;
                final scrollOffset = _gridHorizontalController.hasClients ? _gridHorizontalController.offset : 0.0;
                final maxInset = (tileWidth - 2 * basePadding - 20).clamp(0.0, double.infinity);
                final leftInset = (scrollOffset - tileLeft).clamp(0.0, maxInset);
                return Container(
                  color: isFocused ? null : materialColor,
                  padding: .fromLTRB(basePadding + leftInset, 4, basePadding, 4),
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisAlignment: .center,
                    children: [
                      Row(
                        children: [
                          if (isRecordingScheduled) ...[
                            _RecordingDot(color: Colors.red, tooltip: t.liveTv.recordingScheduled),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              program.grandparentTitle ?? program.title,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600, color: titleColor),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (program.grandparentTitle != null)
                        Text(
                          '${program.parentIndex != null && program.index != null ? 'S${program.parentIndex}E${program.index} · ' : ''}${program.title}',
                          style: theme.textTheme.labelSmall?.copyWith(color: subtitleColor),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                      if (program.startTime != null)
                        Text(
                          '${formatClockTime(program.startTime!, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context))} · ${formatDurationTextual(program.durationMinutes * 60_000)}',
                          style: theme.textTheme.labelSmall?.copyWith(color: subtitleColor),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showProgramDetails(LiveTvChannel channel, LiveTvProgram program) {
    final multiServer = context.read<MultiServerProvider>();
    final serverId = serverIdOrNull(channel.serverId);
    final client = serverId == null ? null : multiServer.getClientForServer(serverId);
    String? posterUrl;
    if (program.thumb != null && client != null) {
      posterUrl = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: program.thumb,
        maxWidth: 80,
        maxHeight: 120,
        devicePixelRatio: MediaImageHelper.effectiveDevicePixelRatio(context),
        imageType: ImageType.poster,
      );
    }

    showProgramDetailsSheet(
      context,
      program: program,
      channel: channel,
      posterUrl: posterUrl,
      onTuneChannel: () => _tuneChannel(channel),
      client: client,
      onRecordingStateChanged: (isScheduled) => _handleRecordingStateChanged(program, isScheduled),
    );
  }
}

class _RecordingDot extends StatelessWidget {
  final Color color;
  final String tooltip;

  const _RecordingDot({required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ChannelCell extends StatefulWidget {
  final double rowHeight;
  final double channelColumnWidth;
  final String? channelThumb;
  final MediaServerClient? client;
  final LiveTvChannel channel;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isFocused;
  final bool isFavorite;
  final Widget Function() fallbackBuilder;

  const _ChannelCell({
    required this.rowHeight,
    required this.channelColumnWidth,
    required this.channelThumb,
    required this.client,
    required this.channel,
    required this.theme,
    required this.onTap,
    this.onLongPress,
    required this.isFocused,
    this.isFavorite = false,
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
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onSecondaryTap: widget.onLongPress,
        child: Material(
          color: widget.isFocused ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          child: InkWell(
            canRequestFocus: false,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Container(
              height: widget.rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                  right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Stack(
                alignment: .center,
                children: [
                  AnimatedOpacity(
                    opacity: showAction ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: widget.channelThumb != null && widget.client != null
                        ? OptimizedMediaImage.thumb(
                            client: widget.client!,
                            imagePath: widget.channelThumb,
                            width: widget.channelColumnWidth - 16,
                            height: widget.rowHeight - 16,
                            fit: BoxFit.contain,
                          )
                        : widget.fallbackBuilder(),
                  ),
                  if (showAction) AppIcon(Symbols.play_arrow_rounded, size: 32, color: theme.colorScheme.onSurface),
                  if (widget.isFavorite)
                    Positioned(
                      top: 2,
                      right: 0,
                      child: AppIcon(Symbols.star_rounded, size: 14, color: theme.colorScheme.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
