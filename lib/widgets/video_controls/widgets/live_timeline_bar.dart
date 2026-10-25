import 'package:flutter/material.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/live_tv_timeline.dart';
import '../../../mpv/mpv.dart';
import '../../../utils/formatters.dart';
import 'timeline_slider.dart';

/// A backend-neutral epoch timeline. Program bounds describe the whole track;
/// only the intersection with the backend's playable grid accepts scrubbing.
class LiveTimelineBar extends StatefulWidget {
  final Player player;
  final LiveTvTimeline Function(Duration position) timelineForPosition;
  final ValueChanged<double>? onSeekEnd;
  final ValueChanged<int>? onSeekBy;
  final bool horizontalLayout;
  final FocusNode? focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  final bool enabled;

  const LiveTimelineBar({
    super.key,
    required this.player,
    required this.timelineForPosition,
    this.onSeekEnd,
    this.onSeekBy,
    this.horizontalLayout = true,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.enabled = true,
  });

  @override
  State<LiveTimelineBar> createState() => _LiveTimelineBarState();
}

class _LiveTimelineBarState extends State<LiveTimelineBar> {
  double? _dragRangeStart;
  double? _dragRangeEnd;
  Object? _dragProgramIdentity;
  late Stream<int> _positionSecondsStream;

  @override
  void initState() {
    super.initState();
    _bindPositionStream();
  }

  @override
  void didUpdateWidget(LiveTimelineBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player)) {
      _clearDragRange();
      _bindPositionStream();
    }
    if (!widget.enabled) _clearDragRange();
  }

  void _bindPositionStream() {
    _positionSecondsStream = widget.player.streams.position.map((position) => position.inSeconds).distinct();
  }

  LiveTvTimeline get _timeline => widget.timelineForPosition(widget.player.state.position);

  String _clock(double epoch, {bool includeSeconds = false}) => formatClockTime(
    DateTime.fromMillisecondsSinceEpoch((epoch * 1000).round()),
    is24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
    includeSeconds: includeSeconds,
  );

  String _positionValue(LiveTvTimeline timeline) {
    final preview = timeline.programPreviewEpoch;
    if (preview != null) return '${t.liveTv.timelinePending}: ${_clock(preview, includeSeconds: true)}';
    if (timeline.isAtLive) return t.liveTv.live;
    final confirmed = timeline.confirmedPlayheadEpoch;
    if (confirmed != null) return _clock(confirmed);
    final estimate = timeline.estimatedPlayheadEpoch;
    if (estimate != null) return '${t.liveTv.timelineEstimated}: ${_clock(estimate)}';
    return t.liveTv.timelineUnavailable;
  }

  bool _canScrub(LiveTvTimeline timeline) =>
      widget.enabled &&
      widget.onSeekEnd != null &&
      timeline.hasRange &&
      timeline.scrubTarget(timeline.startEpoch!) != null;

  double? _relativeTarget(LiveTvTimeline timeline, int delta) {
    if (!widget.enabled || widget.onSeekBy == null) return null;
    final current = timeline.pendingSeekEpoch ?? (timeline.playback.active ? timeline.playback.epoch : null);
    if (current == null) return null;
    final target = timeline.seekable?.target(current + delta);
    return target == current ? null : target;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: _positionSecondsStream,
    initialData: widget.player.state.position.inSeconds,
    builder: (context, snapshot) {
      final timeline = widget.timelineForPosition(Duration(seconds: snapshot.requireData));
      return Padding(
        padding: widget.horizontalLayout ? EdgeInsets.zero : const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSlider(timeline),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeline.startEpoch == null ? '—' : _clock(timeline.startEpoch!), style: _timeStyle),
                Text(timeline.endEpoch == null ? '—' : _clock(timeline.endEpoch!), style: _timeStyle),
              ],
            ),
          ],
        ),
      );
    },
  );

  static const _timeStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  Duration _offset(LiveTvTimeline timeline, double epoch) =>
      Duration(milliseconds: ((epoch - timeline.startEpoch!) * 1000).round());

  Widget _buildSlider(LiveTvTimeline timeline) {
    final increase = _relativeTarget(timeline, 10);
    final decrease = _relativeTarget(timeline, -10);
    final pending = timeline.pendingSeekEpoch;
    final destination = timeline.programPreviewEpoch ?? pending;
    final position = destination != null && timeline.contains(destination)
        ? destination
        : timeline.confirmedPlayheadEpoch ?? timeline.estimatedPlayheadEpoch;
    return Semantics(
      label: t.videoControls.timelineSlider,
      slider: true,
      value: _positionValue(timeline),
      // Keep uncertainty accessible without adding status text to the bar.
      hint: [
        if (timeline.mode == LiveTvTimelineMode.buffer) t.liveTv.timelineBuffer,
        if (timeline.mode == LiveTvTimelineMode.liveProgramFallback) t.liveTv.timelineLiveProgram,
        if (timeline.programDataStale) t.liveTv.timelineStale,
        if (timeline.programPreviewEpoch == null && timeline.playbackOutOfWindow) t.liveTv.unknownProgram,
        if (pending != null) t.liveTv.timelinePending,
        if (timeline.seekStatus == LiveTvSeekStatus.failed) t.liveTv.liveStreamFailed,
      ].join(' · '),
      increasedValue: increase == null ? null : _clock(increase),
      decreasedValue: decrease == null ? null : _clock(decrease),
      enabled: _canScrub(timeline) || increase != null || decrease != null,
      onIncrease: increase == null ? null : () => widget.onSeekBy?.call(10),
      onDecrease: decrease == null ? null : () => widget.onSeekBy?.call(-10),
      child: ExcludeSemantics(
        child: TimelineSlider(
          key: ObjectKey(widget.player),
          position: position == null ? Duration.zero : _offset(timeline, position),
          duration: timeline.hasRange ? _offset(timeline, timeline.endEpoch!) : Duration.zero,
          bufferRanges: [
            if (timeline.visibleSeekStart != null && timeline.visibleSeekEnd != null)
              BufferRange(
                start: _offset(timeline, timeline.visibleSeekStart!),
                end: _offset(timeline, timeline.visibleSeekEnd!),
              ),
          ],
          chapters: const [],
          chaptersLoaded: false,
          showPosition: position != null,
          showProgress: false,
          bufferedProgressColor: Colors.red,
          positionLabelBuilder: (offset) => timeline.startEpoch == null
              ? t.liveTv.timelineUnavailable
              : _clock(timeline.startEpoch! + offset.inMilliseconds / 1000, includeSeconds: true),
          resolveScrubPosition: (offset) {
            final current = _timeline;
            if (!_canScrub(current) || !_sameDragRange(current)) return null;
            final target = current.scrubTarget(current.startEpoch! + offset.inMilliseconds / 1000);
            return target == null ? null : _offset(current, target);
          },
          onScrubStart: () {
            final current = _timeline;
            _dragRangeStart = current.startEpoch;
            _dragRangeEnd = current.endEpoch;
            _dragProgramIdentity = _programIdentity(current);
          },
          onScrubEnd: _clearDragRange,
          onSeek: (_) {},
          onSeekEnd: (offset) {
            final current = _timeline;
            if (!_canScrub(current) || !_sameDragRange(current)) return;
            final target = current.scrubTarget(current.startEpoch! + offset.inMilliseconds / 1000);
            if (target != null) widget.onSeekEnd?.call(target);
          },
          // Keyboard navigation can use the full buffer even when the shown
          // program cannot be scrubbed. The resolver gates pointer targets.
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          onKeyEvent: widget.onKeyEvent,
          onFocusChange: widget.onFocusChange,
        ),
      ),
    );
  }

  void _clearDragRange() {
    _dragRangeStart = null;
    _dragRangeEnd = null;
    _dragProgramIdentity = null;
  }

  // Guide refreshes reconstruct program objects. Compare the airing's stable
  // identity within its channel/source, while checking schedule bounds below.
  Object? _programIdentity(LiveTvTimeline timeline) {
    final program = timeline.program;
    return program == null
        ? null
        : (
            program.serverId,
            program.liveDvrKey,
            program.providerIdentifier,
            program.channelIdentifier,
            program.ratingKey ?? program.key ?? program.guid ?? program.title,
          );
  }

  bool _sameDragRange(LiveTvTimeline timeline) =>
      timeline.startEpoch == _dragRangeStart &&
      timeline.endEpoch == _dragRangeEnd &&
      _programIdentity(timeline) == _dragProgramIdentity;
}
