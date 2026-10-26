import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_slider.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../utils/formatters.dart';
import '../../mpv/mpv.dart';
import '../../services/open_subtitles_client.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../sources/listening_tools.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/overlay_sheet.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/music/mini_player.dart';
import 'add_source_screen.dart';
import 'source_notes_screen.dart';
import 'standalone_subtitle_search_sheet.dart';
import 'source_widgets.dart';

class SourcePlayerScreen extends StatefulWidget {
  const SourcePlayerScreen({super.key});
  @override
  State<SourcePlayerScreen> createState() => _SourcePlayerScreenState();
}

class _SourcePlayerScreenState extends State<SourcePlayerScreen> {
  SourcePlayback? _session;
  bool _full = false;
  double? _dragPosition;
  final _fullscreen = FullscreenStateManager();
  @override
  void initState() {
    super.initState();
    _fullscreen.beginScope();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session ??= context.read<SourcePlayback>();
    _session!.fullPlayerVisible = true;
  }

  @override
  void dispose() {
    final s = _session;
    if (s != null) {
      s.fullPlayerVisible = false;
      if (s.video) unawaited(s.stop());
    }
    if (_full) unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    if (_fullscreen.scopeOwnsFullscreen) unawaited(_fullscreen.exitFullscreen());
    _fullscreen.endScope();
    super.dispose();
  }

  Future<void> _searchStandaloneSubtitles(SourcePlayback s) async {
    final entry = s.entry;
    if (entry == null) return;
    FileSource? source;
    for (final candidate in s.sources.sources) {
      if (candidate.id == entry.sourceId) {
        source = candidate;
        break;
      }
    }
    if (source == null) throw const SourceException(SourceFailure.authentication);
    final epoch = s.sources.generation;
    final credentials = await s.sources.repository.credentials(source);
    if (!s.sources.current(epoch)) throw const SourceException(SourceFailure.cancelled);
    final key = credentials['openSubtitlesApiKey']?.trim() ?? '';
    if (key.isEmpty) {
      if (!mounted) return;
      final editSource = await showScopedDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.sourceSetup.subtitleKeyRequired),
          content: Text(t.sourceSetup.subtitleKeyHelp),
          actions: [
            DialogActionButton(onPressed: () => Navigator.pop(dialogContext, false), label: t.common.cancel),
            DialogActionButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              label: '${t.common.edit} ${t.fileSources.source}',
              isPrimary: true,
              icon: const AppIcon(Symbols.edit_rounded),
            ),
          ],
        ),
      );
      if (editSource == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => AddSourceScreen(existing: source)));
      }
      return;
    }
    final client = OpenSubtitlesClient(
      apiKey: key,
      username: credentials['openSubtitlesUsername'],
      password: credentials['openSubtitlesPassword'],
    );
    try {
      if (!mounted) return;
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => StandaloneSubtitleSearchSheet(
          client: client,
          title: entry.displayTitle,
          imdbId: entry.identifiers['imdb'],
          tmdbId: entry.identifiers['tmdb'],
          year: entry.releaseYear,
          onApply: (download) => s.applyExternalSubtitle(name: download.fileName, bytes: download.bytes),
        ),
      );
    } finally {
      client.close();
    }
  }

  Widget controls(SourcePlayback s) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (s.opening) const LinearProgressIndicator(),
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusableSlider(
          value: (_dragPosition ?? s.positionMs.toDouble()).clamp(
            s.timelineStartMs.toDouble(),
            s.timelineEndMs > s.timelineStartMs ? s.timelineEndMs.toDouble() : s.timelineStartMs + 1.0,
          ),
          min: s.timelineStartMs.toDouble(),
          max: s.timelineEndMs > s.timelineStartMs ? s.timelineEndMs.toDouble() : s.timelineStartMs + 1.0,
          semanticLabel: t.fileSources.timePosition,
          semanticFormatterCallback: (v) => formatDurationTextual(v.round(), abbreviated: false),
          onChanged: s.timelineEndMs > s.timelineStartMs ? (v) => setState(() => _dragPosition = v) : null,
          onChangeEnd: s.timelineEndMs > s.timelineStartMs
              ? (v) {
                  setState(() => _dragPosition = null);
                  unawaited(sourceAction(context, () => s.seek(v.round())));
                }
              : null,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            textDirection: TextDirection.ltr,
            alignment: WrapAlignment.spaceBetween,
            spacing: 24,
            runSpacing: 8,
            children: [
              Text(sourceTime(s.positionMs - s.timelineStartMs)),
              if (s.chapterRemainingMs != null)
                Text(t.audiobook.chapterRemaining(time: sourceTime(s.chapterRemainingMs!))),
              if (s.bookRemainingMs != null)
                Text(
                  s.entry?.kind == SourceItemKind.audiobook
                      ? t.audiobook.bookRemaining(time: sourceTime(s.bookRemainingMs!))
                      : t.fileSources.remaining(time: sourceTime(s.bookRemainingMs!)),
                )
              else
                Text(t.audiobook.unknownRemaining),
            ],
          ),
        ),
      ),
      if (!s.video && s.chapters.isNotEmpty)
        TextButton(
          onPressed: () => sourceAction(context, () async {
            s.chapterTimeline = !s.chapterTimeline;
            await s.savePreferences();
          }),
          child: Text(s.chapterTimeline ? t.audiobook.chapterTimeline : t.audiobook.bookTimeline),
        ),
      if (s.sleepDeadline != null)
        Text(t.audiobook.sleepRemaining(time: sourceTime(s.sleepDeadline!.difference(DateTime.now()).inMilliseconds))),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          IconButton(
            tooltip: t.videoControls.previousChapterButton,
            onPressed: () => sourceAction(context, s.previousChapter),
            icon: const AppIcon(Symbols.skip_previous_rounded),
          ),
          IconButton(
            tooltip: t.fileSources.skipBack,
            onPressed: () => sourceAction(context, () => s.skip(-s.backwardSeconds)),
            icon: const AppIcon(Symbols.replay_rounded),
          ),
          IconButton.filled(
            iconSize: 38,
            tooltip: s.playing ? t.fileSources.pause : t.fileSources.play,
            onPressed: () => sourceAction(context, s.toggle),
            icon: AppIcon(s.playing ? Symbols.pause_rounded : Symbols.play_arrow_rounded, fill: 1),
          ),
          IconButton(
            tooltip: t.fileSources.skipForward,
            onPressed: () => sourceAction(context, () => s.skip(s.forwardSeconds)),
            icon: const AppIcon(Symbols.forward_media_rounded),
          ),
          IconButton(
            tooltip: t.videoControls.nextChapterButton,
            onPressed: () => sourceAction(context, s.nextChapter),
            icon: const AppIcon(Symbols.skip_next_rounded),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          AppMenuButton<double>(
            tooltip: t.fileSources.speed,
            adaptiveSheet: true,
            entriesBuilder: (_) => [
              AppMenuItem(value: -1, label: t.audiobook.customSpeed),
              for (final rate in [.5, .75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0])
                AppMenuItem(value: rate, label: formatPlaybackRate(rate), selected: rate == s.speed),
            ],
            onSelected: (rate) => sourceAction(context, () async {
              if (rate != -1) {
                await s.setSpeed(rate);
                return;
              }
              final value = await _entryDialog(
                title: t.audiobook.customSpeed,
                help: t.audiobook.speedHelp,
                initial: '${s.speed}',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                valid: (v) {
                  final speed = _parseSpeed(v);
                  return speed != null && speed.isFinite && speed >= .25 && speed <= 4;
                },
              );
              if (value != null) await s.setSpeed(_parseSpeed(value)!);
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(formatPlaybackRate(s.speed), style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
          AppMenuButton<int>(
            icon: AppIcon(s.sleepEnabled ? Symbols.bedtime_rounded : Symbols.bedtime_off_rounded),
            tooltip: t.fileSources.sleep,
            adaptiveSheet: true,
            entriesBuilder: (_) => [
              AppMenuItem(value: 0, label: t.fileSources.sleepOff),
              AppMenuItem(value: -1, label: t.fileSources.endChapter),
              for (final count in [2, 3, 5])
                AppMenuItem(
                  value: -count,
                  label: t.audiobook.sleepChapters(count: count),
                ),
              AppMenuItem(value: -10, label: t.audiobook.customSleep),
              if (s.sleepDeadline != null) AppMenuItem(value: -11, label: t.audiobook.extendSleep),
              for (final n in [5, 15, 30, 45, 60, 90])
                AppMenuItem(
                  value: n,
                  label: t.fileSources.minutes(count: n),
                ),
            ],
            onSelected: (n) async {
              if (n == -10) {
                final value = await _entryDialog(
                  title: t.audiobook.customSleep,
                  help: t.audiobook.sleepMinutes,
                  initial: '20',
                  keyboardType: TextInputType.number,
                  valid: (v) => int.tryParse(v) != null && int.parse(v) >= 1 && int.parse(v) <= 1440,
                );
                if (value != null) s.sleepFor(Duration(minutes: int.parse(value)));
              } else if (n == -11) {
                s.extendSleep(const Duration(minutes: 5));
              } else if (n == 0) {
                s.clearSleep();
              } else if (n < 0) {
                s.sleepAfterChapter(count: -n);
              } else {
                s.sleepFor(Duration(minutes: n));
              }
            },
          ),
          IconButton(
            tooltip: t.audiobook.undoSeek,
            onPressed: s.canUndoSeek ? () => sourceAction(context, s.undoSeek) : null,
            icon: const AppIcon(Symbols.undo_rounded),
          ),
          IconButton(
            tooltip: t.audiobook.goToTime,
            icon: const AppIcon(Symbols.schedule_rounded),
            onPressed: () => sourceAction(context, () async {
              final value = await _entryDialog(
                title: t.audiobook.goToTime,
                help: t.audiobook.timeHelp,
                initial: sourceTime(s.positionMs - (s.hasCompleteTimeline ? 0 : s.timelineStartMs)),
                valid: (v) => parseListeningTime(v) != null,
              );
              if (value != null) {
                await s.seek(parseListeningTime(value)! + (s.hasCompleteTimeline ? 0 : s.timelineStartMs));
              }
            }),
          ),
          IconButton(
            tooltip: t.fileSources.bookmark,
            onPressed: () => sourceAction(context, () async {
              final note = await editSourceNote(context);
              if (note != null) await s.bookmark(note: note);
            }),
            icon: const AppIcon(Symbols.bookmark_add_rounded),
          ),
          IconButton(
            tooltip: t.fileSources.bookmarks,
            onPressed: () => sourceAction(context, () async {
              final note = await Navigator.push<BookAnnotation>(
                context,
                MaterialPageRoute(
                  builder: (_) => SourceNotesScreen(entry: s.entry!, edition: s.progress?.edition, mode: s.mode),
                ),
              );
              if (note != null) await s.seekBookmark(note);
            }),
            icon: const AppIcon(Symbols.bookmarks_rounded),
          ),
          IconButton(
            tooltip: t.fileSources.playbackOptions,
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceListeningSettings())),
            icon: const AppIcon(Symbols.tune_rounded),
          ),
          if (s.video)
            IconButton(
              tooltip: t.videoControls.searchSubtitles,
              onPressed: () => sourceAction(context, () => _searchStandaloneSubtitles(s)),
              icon: const AppIcon(Symbols.subtitles_rounded),
            ),
          if (s.video)
            IconButton(
              tooltip: t.fileSources.fullscreen,
              onPressed: () async {
                setState(() => _full = !_full);
                if (PlatformDetector.isDesktopOS()) {
                  if (_full) {
                    await _fullscreen.enterFullscreen();
                  } else if (_fullscreen.scopeOwnsFullscreen) {
                    await _fullscreen.exitFullscreen();
                  }
                }
                await SystemChrome.setEnabledSystemUIMode(
                  _full ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
                );
              },
              icon: const AppIcon(Symbols.fullscreen_rounded),
            ),
        ],
      ),
      if (s.failure != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: SourceErrorMessage(message: sourceFailureText(SourceException(s.failure!))),
        ),
    ],
  );
  Future<String?> _entryDialog({
    required String title,
    required String help,
    required String initial,
    required bool Function(String) valid,
    TextInputType? keyboardType,
  }) async {
    final input = TextEditingController(text: initial);
    final form = GlobalKey<FormState>();
    try {
      return await showScopedDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Form(
            key: form,
            child: FocusableTextFormField(
              controller: input,
              keyboardType: keyboardType,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(helperText: help, helperMaxLines: 3),
              validator: (v) => valid(v?.trim() ?? '') ? null : help,
              onFieldSubmitted: (_) {
                if (form.currentState!.validate()) Navigator.pop(dialogContext, input.text.trim());
              },
            ),
          ),
          actions: [
            DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel),
            DialogActionButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(dialogContext, input.text.trim());
              },
              label: t.audiobook.apply,
              isPrimary: true,
            ),
          ],
        ),
      );
    } finally {
      input.dispose();
    }
  }

  double? _parseSpeed(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SourcePlayback>();
    if (!s.active) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(t.fileSources.empty)),
      );
    }
    final core = s.player;
    final video = s.video && core != null
        ? AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(player: core),
          )
        : null;
    return Focus(
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.space) {
          unawaited(sourceAction(context, s.toggle));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _full && video != null
          ? Scaffold(
              body: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(child: Video(player: core!)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: .9),
                        child: controls(s),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : FocusedScrollScaffold(
              title: Text(s.entry!.title),
              focusableAppBarActions: true,
              actions: [
                IconButton(
                  tooltip: t.fileSources.stop,
                  onPressed: () => sourceAction(context, () async {
                    await s.stop();
                    if (context.mounted) Navigator.pop(context);
                  }),
                  icon: const AppIcon(Symbols.stop_rounded),
                ),
              ],
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        children: [
                          if (video != null)
                            video
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(32, 36, 32, 24),
                              child: Column(
                                children: [
                                  Container(
                                    width: 160,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: tokens(context).surface,
                                      borderRadius: BorderRadius.circular(tokens(context).radiusLg),
                                    ),
                                    child: SourceCover(entry: s.entry!),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    s.entry!.displayTitle,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (s.entry!.author.isNotEmpty) Text(s.entry!.author),
                                  if (s.currentChapter != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(s.currentChapter!.title),
                                    ),
                                ],
                              ),
                            ),
                          controls(s),
                          const SizedBox(height: 24),
                          if (s.video && core != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 16,
                                children: [
                                  AppMenuButton<String>(
                                    icon: const AppIcon(Symbols.audiotrack_rounded),
                                    tooltip: t.fileSources.audioTrack,
                                    adaptiveSheet: true,
                                    entriesBuilder: (_) => [
                                      for (final track in core.state.tracks.audio)
                                        AppMenuItem(value: track.id, label: track.title ?? track.language ?? track.id),
                                    ],
                                    onSelected: (id) =>
                                        sourceAction(context, () => core.selectAudioTrack(AudioTrack(id: id))),
                                  ),
                                  AppMenuButton<String>(
                                    icon: const AppIcon(Symbols.subtitles_rounded),
                                    tooltip: t.fileSources.subtitleTrack,
                                    adaptiveSheet: true,
                                    entriesBuilder: (_) => [
                                      AppMenuItem(value: 'no', label: t.fileSources.none),
                                      for (final track in core.state.tracks.subtitle)
                                        AppMenuItem(value: track.id, label: track.title ?? track.language ?? track.id),
                                    ],
                                    onSelected: (id) =>
                                        sourceAction(context, () => core.selectSubtitleTrack(SubtitleTrack(id: id))),
                                  ),
                                ],
                              ),
                            ),
                          if (s.chapters.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.fileSources.chapters, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < s.chapters.length; i++)
                                    SourceTile(
                                      title: s.chapters[i].title,
                                      subtitle: sourceTime(s.chapters[i].startMs),
                                      icon: Symbols.format_list_numbered_rounded,
                                      index: i,
                                      count: s.chapters.length,
                                      onTap: () => sourceAction(context, () => s.seekChapter(i)),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class SourceListeningSettings extends StatelessWidget {
  const SourceListeningSettings({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SourcePlayback>();
    return FocusedScrollScaffold(
      title: Text(t.fileSources.playbackOptions),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(t.fileSources.smartRewind),
                  value: s.smartRewind,
                  onChanged: (v) {
                    s.smartRewind = v;
                    unawaited(s.savePreferences());
                  },
                ),
                TextButton(
                  onPressed: () => sourceAction(context, () => s.savePreferences(asDefault: true)),
                  child: Text(t.audiobook.useDefaults),
                ),
                for (final forward in [false, true])
                  ListTile(
                    title: Text(forward ? t.fileSources.skipForward : t.fileSources.skipBack),
                    trailing: DropdownButton<int>(
                      value: forward ? s.forwardSeconds : s.backwardSeconds,
                      items: [
                        for (final n in [5, 10, 15, 30, 45, 60, 120]) DropdownMenuItem(value: n, child: Text('${n}s')),
                      ],
                      onChanged: (n) {
                        if (n == null) return;
                        if (forward) {
                          s.forwardSeconds = n;
                        } else {
                          s.backwardSeconds = n;
                        }
                        unawaited(s.savePreferences());
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SourceMiniPlayer extends StatelessWidget {
  const SourceMiniPlayer({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SourcePlayback?>();
    final inset = context.watch<MiniPlayerInsetController?>();
    final suppression = context.read<MusicUiRouteObserver?>()?.suppress;
    return ListenableBuilder(
      listenable: Listenable.merge([?suppression, OverlaySheetController.openSheetCount]),
      builder: (context, _) {
        final active =
            s != null &&
            s.active &&
            !s.video &&
            !s.fullPlayerVisible &&
            !PlatformDetector.isTV() &&
            !(suppression?.value ?? false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) inset?.setSourceOverlayHeight(active ? 112 : 0);
        });
        if (!active || OverlaySheetController.openSheetCount.value > 0) return const SizedBox.shrink();
        return _card(context, s, inset);
      },
    );
  }

  Widget _card(BuildContext context, SourcePlayback s, MiniPlayerInsetController? inset) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB((inset?.startInset ?? 0) + 16, 0, 16, (inset?.bottomInset ?? 0) + 16),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(tokens(context).radiusLg),
              color: tokens(context).surface,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const AppIcon(Symbols.headphones_rounded),
                          title: Text(s.entry!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            s.currentChapter?.title ?? s.entry!.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: onOpen,
                        ),
                      ),
                      IconButton(
                        tooltip: s.playing ? t.fileSources.pause : t.fileSources.play,
                        onPressed: () => sourceAction(context, s.toggle),
                        icon: AppIcon(s.playing ? Symbols.pause_rounded : Symbols.play_arrow_rounded, fill: 1),
                      ),
                      IconButton(
                        tooltip: t.fileSources.stop,
                        onPressed: () => sourceAction(context, s.stop),
                        icon: const AppIcon(Symbols.close_rounded),
                      ),
                    ],
                  ),
                  LinearProgressIndicator(
                    value: s.durationMs > 0 ? (s.positionMs / s.durationMs).clamp(0, 1) : 0,
                    minHeight: 2,
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
