import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_slider.dart';
import '../i18n/presentation_formats.dart';
import '../i18n/strings.g.dart';
import '../screens/sources/source_widgets.dart';
import '../sources/source_models.dart';
import '../sources/source_playback.dart';
import '../theme/mono_tokens.dart';
import '../utils/formatters.dart';
import '../widgets/app_icon.dart';
import '../mpv/mpv.dart';
import 'workspace_controller.dart';
import 'workspace_models.dart';

/// Compact surface for the existing audiobook/source-video owner.
///
/// Playback, progress and teardown stay in [SourcePlayback]. This adapter only
/// presents that same live session inside a workspace pane.
class SourcePlaybackWorkspaceSurface extends StatefulWidget {
  const SourcePlaybackWorkspaceSurface({
    super.key,
    required this.playback,
    required this.controller,
    required this.sessionId,
  });

  final SourcePlayback playback;
  final MultiviewWorkspaceController controller;
  final String sessionId;

  @override
  State<SourcePlaybackWorkspaceSurface> createState() => _SourcePlaybackWorkspaceSurfaceState();
}

class _SourcePlaybackWorkspaceSurfaceState extends State<SourcePlaybackWorkspaceSurface> {
  double? _seekValue;

  @override
  void initState() {
    super.initState();
    widget.playback.addListener(_onPlaybackChanged);
  }

  @override
  void didUpdateWidget(covariant SourcePlaybackWorkspaceSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback != widget.playback) {
      oldWidget.playback.removeListener(_onPlaybackChanged);
      widget.playback.addListener(_onPlaybackChanged);
    }
  }

  @override
  void dispose() {
    widget.playback.removeListener(_onPlaybackChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    final playback = widget.playback;
    if (!playback.active || playback.entry == null) {
      widget.controller.unregister(widget.sessionId);
      return;
    }
    final registration = widget.controller.session(widget.sessionId);
    if (registration == null) return;
    final entry = playback.entry!;
    final chapter = playback.currentChapter?.title;
    final current = registration.descriptor;
    final title = entry.displayTitle.trim().isEmpty ? t.common.unknown : entry.displayTitle;
    final subtitle = chapter ?? (entry.narrator.isNotEmpty ? entry.narrator : entry.author);
    final mediaKey = '${entry.key}:${playback.progress?.edition ?? ''}';
    final progressOwner = playback.progress?.key;
    final kind = playback.video ? MultiviewMediaKind.video : MultiviewMediaKind.audiobook;
    if (current.kind == kind &&
        current.title == title &&
        current.subtitle == subtitle &&
        current.mediaKey == mediaKey &&
        current.progressOwner == progressOwner &&
        current.hasAudio &&
        current.hasVideo == playback.video) {
      return;
    }
    widget.controller.updateDescriptor(
      current.copyWith(
        kind: kind,
        title: title,
        subtitle: subtitle,
        clearSubtitle: subtitle == null || subtitle.isEmpty,
        mediaKey: mediaKey,
        progressOwner: progressOwner,
        hasAudio: true,
        hasVideo: playback.video,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.playback,
      builder: (context, _) {
        final playback = widget.playback;
        final entry = playback.entry;
        if (!playback.active || entry == null) {
          return ColoredBox(
            color: tokens(context).bg,
            child: Center(
              child: Text(t.fileSources.empty, style: TextStyle(color: tokens(context).textMuted)),
            ),
          );
        }
        final tk = tokens(context);
        final core = playback.player;
        if (playback.video && core != null) {
          return Material(
            color: tk.bg,
            child: Column(
              children: [
                Expanded(child: Video(player: core)),
                _transport(context, playback),
              ],
            ),
          );
        }
        return Material(
          color: tk.bg,
          child: Padding(
            padding: EdgeInsets.all(tk.space * 0.75),
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tk.radiusMd),
                    child: SourceCover(entry: entry),
                  ),
                ),
                SizedBox(width: tk.space * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isolateDisplayText(entry.displayTitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: tk.text, fontWeight: FontWeight.w700),
                      ),
                      if (playback.currentChapter != null)
                        Padding(
                          padding: EdgeInsets.only(top: tk.space * 0.2),
                          child: Text(
                            isolateDisplayText(playback.currentChapter!.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                          ),
                        ),
                      const Spacer(),
                      _transport(context, playback),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _transport(BuildContext context, SourcePlayback playback) {
    final tk = tokens(context);
    final start = playback.timelineStartMs;
    final end = playback.timelineEndMs;
    final canSeek = end > start;
    final position = (_seekValue ?? playback.positionMs.toDouble()).clamp(
      start.toDouble(),
      canSeek ? end.toDouble() : start + 1.0,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tk.space * 0.5, vertical: tk.space * 0.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: FocusableSlider(
              value: position,
              min: start.toDouble(),
              max: canSeek ? end.toDouble() : start + 1.0,
              semanticLabel: t.fileSources.timePosition,
              semanticFormatterCallback: (value) => formatDurationTextual(value.round(), abbreviated: false),
              onChanged: canSeek ? (value) => setState(() => _seekValue = value) : null,
              onChangeEnd: canSeek
                  ? (value) {
                      setState(() => _seekValue = null);
                      unawaited(playback.seek(value.round()));
                    }
                  : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: t.fileSources.skipBack,
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(playback.skip(-playback.backwardSeconds)),
                icon: const AppIcon(Symbols.replay_rounded),
              ),
              IconButton(
                tooltip: t.videoControls.previousChapterButton,
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(playback.previousChapter()),
                icon: const AppIcon(Symbols.skip_previous_rounded),
              ),
              IconButton.filledTonal(
                tooltip: playback.playing ? t.common.pause : t.common.play,
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(playback.toggle()),
                icon: AppIcon(playback.playing ? Symbols.pause_rounded : Symbols.play_arrow_rounded),
              ),
              IconButton(
                tooltip: t.videoControls.nextChapterButton,
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(playback.nextChapter()),
                icon: const AppIcon(Symbols.skip_next_rounded),
              ),
              IconButton(
                tooltip: t.fileSources.skipForward,
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(playback.skip(playback.forwardSeconds)),
                icon: const AppIcon(Symbols.forward_media_rounded),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDurationTimestamp(Duration(milliseconds: playback.positionMs)),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                formatDurationTimestamp(Duration(milliseconds: playback.timelineEndMs)),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
