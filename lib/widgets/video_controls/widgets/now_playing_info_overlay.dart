import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_item.dart';
import '../../../media/media_item_types.dart';
import '../../../media/media_source_info.dart';
import '../../../mpv/mpv.dart';
import '../../../services/settings_service.dart';
import '../../../utils/content_utils.dart';
import '../../../utils/formatters.dart';
import '../../../utils/media_quality_labels.dart';
import '../../app_icon.dart';
import '../../system_clock.dart';
import 'finish_time_builder.dart';

/// Toggleable "Now Playing Info" card raised by the TV remote's Info key.
///
/// Shows what is playing — series/episode or movie title, year/air date,
/// content rating, stream quality badges, current chapter, plot synopsis,
/// finish clock time, and a live progress bar with elapsed and remaining
/// time — without bringing up the interactive transport buttons.
class NowPlayingInfoOverlay extends StatefulWidget {
  final Player player;
  final MediaItem metadata;
  final List<MediaChapter> chapters;
  final bool isLive;
  final String? liveChannelName;
  final bool? isTranscoding;

  const NowPlayingInfoOverlay({
    super.key,
    required this.player,
    required this.metadata,
    this.chapters = const [],
    this.isLive = false,
    this.liveChannelName,
    this.isTranscoding,
  });

  @override
  State<NowPlayingInfoOverlay> createState() => _NowPlayingInfoOverlayState();
}

class _NowPlayingInfoOverlayState extends State<NowPlayingInfoOverlay> {
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  late Duration _position;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _syncFromPlayer();
    _subscribe();
  }

  @override
  void didUpdateWidget(NowPlayingInfoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _unsubscribe();
      _syncFromPlayer();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _syncFromPlayer() {
    _position = widget.player.state.position;
    _duration = widget.player.state.duration;
  }

  void _subscribe() {
    _positionSubscription = widget.player.streams.position.listen((position) {
      if (mounted && position.inSeconds != _position.inSeconds) {
        setState(() => _position = position);
      }
    });
    _durationSubscription = widget.player.streams.duration.listen((duration) {
      if (mounted && duration != _duration) {
        setState(() => _duration = duration);
      }
    });
  }

  void _unsubscribe() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    _positionSubscription = null;
    _durationSubscription = null;
  }

  String? _currentChapterLabel() {
    if (widget.chapters.isEmpty) return null;
    final posMs = _position.inMilliseconds;
    for (var i = widget.chapters.length - 1; i >= 0; i--) {
      final chapter = widget.chapters[i];
      final start = chapter.startTimeOffset ?? 0;
      final end = chapter.endTimeOffset;
      if (posMs >= start && (end == null || posMs < end)) {
        return chapter.label;
      }
    }
    return null;
  }

  String? _resolvedSummary() {
    final raw = widget.metadata.summary?.trim();
    if (raw == null || raw.isEmpty) return null;
    final hideSpoilers = SettingsService.instanceOrNull?.read(SettingsService.hideSpoilers) ?? false;
    if (hideSpoilers && widget.metadata.shouldHideSpoiler) return null;
    return raw;
  }

  List<String> _metadataBadges() {
    final item = widget.metadata;
    final badges = <String>[];

    if (item.isEpisode && item.originallyAvailableAt != null) {
      badges.add(formatAbbreviatedDate(item.originallyAvailableAt!));
    } else if (item.year != null) {
      badges.add(item.year.toString());
    }

    if (item.durationMs != null && item.durationMs! > 0) {
      badges.add(formatDurationTextual(item.durationMs!));
    }

    badges.addAll(buildMediaQualityLabels(item));

    if (widget.isTranscoding case final transcoding?) {
      badges.add(transcoding ? t.fileInfo.transcoding : t.fileInfo.directPlay);
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.metadata;
    final seriesTitle = item.grandparentTitle?.trim();
    final hasSeriesTitle = seriesTitle != null && seriesTitle.isNotEmpty;
    final episodeLabel = formatSeasonEpisodeLabel(item.parentIndex, item.index);
    final rawTitle = (widget.isLive ? widget.liveChannelName : null) ?? item.title ?? t.common.unknown;
    final primaryTitle = hasSeriesTitle && episodeLabel != null ? '$episodeLabel — $rawTitle' : rawTitle;
    final contentRating = formatContentRating(item.contentRating);
    final badges = _metadataBadges();
    final chapterLabel = _currentChapterLabel();
    final summary = _resolvedSummary();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : (item.durationMs != null && item.durationMs! > 0 ? Duration(milliseconds: item.durationMs!) : Duration.zero);
    final hasDuration = !widget.isLive && effectiveDuration.inMilliseconds > 0;
    final clampedPos = hasDuration
        ? Duration(milliseconds: _position.inMilliseconds.clamp(0, effectiveDuration.inMilliseconds))
        : _position;
    final remaining = hasDuration ? effectiveDuration - clampedPos : Duration.zero;
    final progress = hasDuration ? (clampedPos.inMilliseconds / effectiveDuration.inMilliseconds).clamp(0.0, 1.0) : 0.0;

    return MediaQuery.withNoTextScaling(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.86),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        children: [
                          if (hasSeriesTitle) ...[
                            Text(
                              seriesTitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13.5,
                                fontWeight: .w600,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            primaryTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: .w700, height: 1.2),
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .end,
                      children: [
                        const SystemClock(
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: .w600),
                        ),
                        if (!widget.isLive)
                          FinishTimeBuilder(
                            player: widget.player,
                            builder: (context, finishTime) {
                              if (finishTime == null) return const SizedBox.shrink();
                              final text = t.videoControls.endsAt(
                                time: formatClockTime(
                                  finishTime,
                                  is24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
                                ),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  text,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: .w500),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                if (contentRating.isNotEmpty || badges.isNotEmpty || chapterLabel != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (contentRating.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                          ),
                          child: Text(
                            contentRating,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: .w600),
                          ),
                        ),
                      if (badges.isNotEmpty)
                        Text(
                          toBulletedString(badges),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: .w500),
                        ),
                      if (chapterLabel != null)
                        Row(
                          mainAxisSize: .min,
                          children: [
                            const AppIcon(Symbols.bookmark_rounded, fill: 1, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              chapterLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: .w600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                if (summary != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: .ellipsis,
                  ),
                ],
                if (hasDuration) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text(
                        formatDurationTimestamp(clampedPos),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: .w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '-${formatDurationTimestamp(remaining)} / ${formatDurationTimestamp(effectiveDuration)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: .w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
