import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_slider.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../mpv/mpv.dart';
import '../../mpv/player/audio_spectrum.dart';
import '../../models/media_bookmark.dart';
import '../../multiview/source_playback_workspace_surface.dart';
import '../../multiview/workspace_controller.dart';
import '../../multiview/workspace_models.dart';
import '../../utils/formatters.dart';
import '../../utils/app_logger.dart';
import '../../services/open_subtitles_client.dart';
import '../../services/player_sync_offsets.dart';
import '../../services/subtitle_retimer.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../sources/listening_tools.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/overlay_sheet.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../services/media_bookmark_service.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/music/mini_player.dart';
import '../../widgets/music/music_visualizer.dart';
import '../../widgets/source_edition_menu_button.dart';
import '../../widgets/source_file_info_sheet.dart';
import 'add_source_screen.dart';
import 'source_notes_screen.dart';
import 'standalone_subtitle_search_sheet.dart';
import 'source_queue_sheet.dart';
import 'source_widgets.dart';
import '../../widgets/video_controls/sheets/picture_adjustments_sheet.dart';
import '../../widgets/video_controls/widgets/sync_offset_control.dart';

class SourcePlayerScreen extends StatefulWidget {
  const SourcePlayerScreen({super.key});
  @override
  State<SourcePlayerScreen> createState() => _SourcePlayerScreenState();
}

class _SourcePlayerScreenState extends State<SourcePlayerScreen> {
  SourcePlayback? _session;
  MultiviewWorkspaceController? _workspace;
  MultiviewWorkspaceController? _observedWorkspace;
  String? _workspaceSessionId;
  bool _workspaceDetached = false;
  bool _autoJoinScheduled = false;
  bool _full = false;
  String? _sourceLoopFileIdentity;
  int? _sourceLoopStartMs;
  int? _sourceLoopEndMs;
  bool _bookmarkBusy = false;
  bool _sourceVisualizerVisible = false;
  MusicVisualizerPreset _sourceVisualizerPreset = MusicVisualizerPreset.bloom;
  double? _dragPosition;
  final _fullscreen = FullscreenStateManager();

  Future<void> _toggleStreamRecording(SourcePlayback playback) async {
    if (playback.isRecordingStream) {
      final file = await playback.stopStreamRecording();
      if (mounted && file != null) showSnackBar(context, t.universalMedia.recordingSaved);
      return;
    }

    final extension = playback.video ? 'mkv' : 'mka';
    var path = await FilePicker.saveFile(
      dialogTitle: t.universalMedia.recordStream,
      fileName: 'stream-recording.$extension',
      type: FileType.custom,
      allowedExtensions: playback.video ? const ['mkv', 'ts'] : const ['mka', 'mkv'],
    );
    if (path == null || !mounted) return;
    if (p.extension(path).isEmpty) path  = '.$extension';
    if (!playback.video && !const {'.mka', '.mkv'}.contains(p.extension(path).toLowerCase()) ||
        playback.video && !const {'.mkv', '.ts'}.contains(p.extension(path).toLowerCase())) {
      showErrorSnackBar(context, t.universalMedia.recordingFormatHelp);
      return;
    }

    final target = File(path);
    final targetExists = await target.exists();
    if (!mounted) return;
    final replace = targetExists
        ? await showConfirmDialog(
            context,
            title: t.universalMedia.replaceRecordingTitle,
            message: t.universalMedia.replaceRecordingHelp,
            confirmText: t.universalMedia.replaceRecording,
            isDestructive: true,
          )
        : false;
    if (!mounted || targetExists && !replace) return;
    await sourceAction(context, () => playback.startStreamRecording(target, replaceExisting: replace));
    if (mounted && playback.isRecordingStream) showSnackBar(context, t.universalMedia.recordingStarted);
  }

  Future<void> _saveLocalPlaylist(SourcePlayback playback) async {
    final List<LocalPlaylistExportItem>? items;
    try {
      items = await playback.localPlaylistExportItems();
    } on Object {
      if (mounted) showErrorSnackBar(context, t.universalMedia.queuePlaylistUnavailable);
      return;
    }
    final exportItems = items;
    if (exportItems == null || exportItems.length < 2 || !mounted) {
      if (mounted && playback.canExportLocalPlaylist && exportItems == null) {
        showErrorSnackBar(context, t.universalMedia.queuePlaylistUnavailable);
      }
      return;
    }

    final parent = p.dirname(exportItems.first.uri.toFilePath());
    final safeName = (playback.entry?.displayTitle ?? exportItems.first.title)
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '-')
        .trim();
    String? selectedPath;
    try {
      selectedPath = await FilePicker.saveFile(
        dialogTitle: t.universalMedia.saveQueuePlaylist,
        fileName: '${safeName.isEmpty ? 'playlist' : safeName}.m3u',
        initialDirectory: parent,
        type: FileType.custom,
        allowedExtensions: const ['m3u'],
      );
    } on Object catch (error, stackTrace) {
      appLogger.w('Could not open the local playlist save dialog', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.universalMedia.queuePlaylistUnavailable);
      return;
    }
    if (selectedPath == null || !mounted) return;
    final path = p.extension(selectedPath).isEmpty ? '$selectedPath.m3u' : selectedPath;
    if (p.extension(path).toLowerCase() != '.m3u') {
      showErrorSnackBar(context, t.universalMedia.queuePlaylistUnavailable);
      return;
    }

    String normalized(String value) {
      final absolute = p.normalize(p.absolute(value));
      return Platform.isWindows ? absolute.toLowerCase() : absolute;
    }

    late final String selectedDirectory;
    try {
      selectedDirectory = await Directory(p.dirname(path)).resolveSymbolicLinks();
    } on FileSystemException {
      if (mounted) showErrorSnackBar(context, t.universalMedia.queuePlaylistFolderRequired);
      return;
    }
    if (!mounted) return;
    if (normalized(selectedDirectory) != normalized(parent)) {
      showErrorSnackBar(context, t.universalMedia.queuePlaylistFolderRequired);
      return;
    }
    final destination = File(path);
    await sourceAction(context, () async {
      final rows = <String>['#EXTM3U'];
      for (final item in exportItems) {
        final title = item.title.replaceAll(RegExp(r'[\x00-\x1f]'), ' ').trim();
        rows
          ..add('#EXTINF:0,${title.isEmpty ? p.basename(item.uri.toFilePath()) : title}')
          ..add(p.basename(item.uri.toFilePath()));
      }
      final suffix = const Uuid().v4();
      final temporary = File(p.join(parent, '.${p.basename(path)}.plezy-$suffix'));
      final backup = File('${destination.path}.plezy-backup-$suffix');
      var backedUp = false;
      try {
        await temporary.writeAsString('${rows.join('\n')}\n', flush: true);
        if (await destination.exists()) {
          await destination.rename(backup.path);
          backedUp = true;
        }
        await temporary.rename(destination.path);
      } catch (_) {
        if (backedUp && await backup.exists() && !await destination.exists()) {
          await backup.rename(destination.path);
        }
        if (await temporary.exists()) await temporary.delete();
        rethrow;
      }
      if (backedUp) {
        try {
          await backup.delete();
        } on Object catch (error, stackTrace) {
          appLogger.w('Saved playlist backup cleanup failed', error: error, stackTrace: stackTrace);
        }
      }
      if (mounted) showSnackBar(context, t.universalMedia.queuePlaylistSaved);
    });
  }

  String _sourceVideoTrackLabel(VideoTrack track) {
    final title = track.title?.trim();
    final dimensions = track.width != null && track.height != null ? '${track.width} × ${track.height}' : null;
    final codec = track.codec?.trim();
    final language = track.language?.trim();
    final details = [
      if (title case final title? when title.isNotEmpty) title,
      ?dimensions,
      if (language case final language? when language.isNotEmpty && language != 'und') language.toUpperCase(),
      if (codec case final codec? when codec.isNotEmpty) codec.toUpperCase(),
    ].join(' · ');
    return isolateDisplayText(details.isEmpty ? t.videoSettings.videoTrackNumber(id: track.id) : details);
  }

  @override
  void initState() {
    super.initState();
    _fullscreen.beginScope();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playback = context.read<SourcePlayback>();
    if (_session != playback) {
      _session?.removeListener(_onPlaybackChanged);
      _session = playback;
      playback.addListener(_onPlaybackChanged);
    }
    playback.fullPlayerVisible = true;

    final workspace = context.read<MultiviewWorkspaceController>();
    if (_observedWorkspace != workspace) {
      _observedWorkspace?.removeListener(_scheduleWorkspaceAutoJoin);
      _observedWorkspace = workspace;
      workspace.addListener(_scheduleWorkspaceAutoJoin);
    }
    _attachToExistingWorkspaceSession(playback, workspace);
    _scheduleWorkspaceAutoJoin();
  }

  String? _stableWorkspaceSessionId(SourcePlayback playback) {
    final progress = playback.progress;
    if (progress == null) return null;
    return "source:${sourceDigest('${progress.key}:${playback.mode.name}')}";
  }

  void _attachToExistingWorkspaceSession(SourcePlayback playback, MultiviewWorkspaceController workspace) {
    final id = _stableWorkspaceSessionId(playback);
    if (id == null || _workspaceSessionId != null || workspace.session(id) == null) return;
    _workspace = workspace;
    _workspaceSessionId = id;
    _workspaceDetached = workspace.visibleSessions.any((item) => item.descriptor.id == id);
    playback.fullPlayerVisible = true;
  }

  void _scheduleWorkspaceAutoJoin() {
    final workspace = _observedWorkspace;
    final playback = _session;
    if (!mounted ||
        _autoJoinScheduled ||
        playback == null ||
        !playback.active ||
        _workspaceSessionId != null ||
        workspace == null ||
        workspace.sessionCount == 0) {
      return;
    }
    _autoJoinScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoJoinScheduled = false;
      if (mounted &&
          _session?.active == true &&
          _workspaceSessionId == null &&
          (_observedWorkspace?.sessionCount ?? 0) > 0) {
        _toggleSourceWorkspace();
      }
    });
  }

  void _onPlaybackChanged() {
    final playback = _session;
    if (!mounted || playback == null) return;
    var workspaceChanged = false;
    final fileIdentity = playback.fileIndex >= 0 && playback.fileIndex < playback.files.length
        ? '${identityHashCode(playback.player)}:${playback.progress?.key ?? playback.entry?.key}:${playback.files[playback.fileIndex].id}'
        : null;
    var loopChanged = false;
    if (_sourceLoopFileIdentity != fileIdentity) {
      _sourceLoopFileIdentity = fileIdentity;
      if (_sourceLoopStartMs != null || _sourceLoopEndMs != null) {
        _sourceLoopStartMs = null;
        _sourceLoopEndMs = null;
        loopChanged = true;
      }
    }
    if (!playback.active && _workspaceSessionId != null) {
      final id = _workspaceSessionId!;
      _workspace?.unregister(id);
      _workspaceSessionId = null;
      _workspace = null;
      _workspaceDetached = false;
      playback.fullPlayerVisible = false;
      workspaceChanged = true;
    }
    _scheduleWorkspaceAutoJoin();
    if ((workspaceChanged || loopChanged) && mounted) setState(() {});
  }

  void _toggleSourceWorkspace() {
    final playback = _session;
    if (playback == null || !playback.active) return;
    final controller = _workspace ?? context.read<MultiviewWorkspaceController>();
    final existingId = _workspaceSessionId;
    if (existingId != null) {
      if (_workspaceDetached) {
        if (controller.isRestored(existingId)) {
          controller.showSessionInWorkspace(existingId);
          setState(() => _workspaceDetached = true);
        } else {
          controller.restore(existingId);
        }
      } else if (controller.showSessionInWorkspace(existingId)) {
        setState(() => _workspaceDetached = true);
      }
      return;
    }

    final id = _stableWorkspaceSessionId(playback);
    if (id == null) return;
    final navigator = Navigator.of(context);
    final sourceRoute = ModalRoute.of(context);
    final entry = playback.entry;
    if (entry == null) return;
    final registration = WorkspaceSurfaceRegistration(
      descriptor: WorkspaceSessionDescriptor(
        id: id,
        kind: playback.video ? MultiviewMediaKind.video : MultiviewMediaKind.audiobook,
        title: entry.displayTitle.trim().isEmpty ? t.common.unknown : entry.displayTitle,
        subtitle: playback.currentChapter?.title ?? (entry.narrator.isNotEmpty ? entry.narrator : entry.author),
        mediaKey: playback.progress?.key,
        progressOwner: playback.progress?.key,
        hasAudio: true,
        hasVideo: playback.video,
        openedAt: DateTime.now(),
      ),
      videoPlayerSlot: playback.videoPlayerSlot,
      buildSurface: (_) => SourcePlaybackWorkspaceSurface(playback: playback, controller: controller, sessionId: id),
      onRestore: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _workspaceSessionId != id) return;
          setState(() => _workspaceDetached = false);
          final route = sourceRoute;
          if (navigator.mounted && route?.isActive == true) {
            navigator.popUntil((candidate) => identical(candidate, route));
          }
        });
      },
      onClose: () {
        unawaited(() async {
          try {
            await playback.stop();
          } catch (error, stackTrace) {
            debugPrint('Source workspace close failed: $error\n$stackTrace');
          } finally {
            playback.fullPlayerVisible = false;
            final route = sourceRoute;
            if (navigator.mounted && route?.isActive == true) {
              if (route!.isCurrent) {
                navigator.pop();
              } else {
                navigator.removeRoute(route);
              }
            }
          }
        }());
      },
      onAudioOwnershipChanged: playback.setWorkspaceAudioEnabled,
    );

    _workspace = controller;
    _workspaceSessionId = id;
    _workspaceDetached = true;
    playback.fullPlayerVisible = true;
    if (!controller.register(registration)) {
      _workspace = null;
      _workspaceSessionId = null;
      _workspaceDetached = false;
      playback.fullPlayerVisible = false;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.videoControls.pipFailed)));
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _session?.removeListener(_onPlaybackChanged);
    _observedWorkspace?.removeListener(_scheduleWorkspaceAutoJoin);
    final playback = _session;
    final id = _workspaceSessionId;
    if (id != null) _workspace?.unregister(id);
    if (playback != null) {
      playback.fullPlayerVisible = false;
      if (playback.video) {
        unawaited(() async {
          try {
            await playback.stop();
          } catch (error, stackTrace) {
            debugPrint('Source player route close failed: $error\n$stackTrace');
          }
        }());
      }
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
      final fingerprint = await s.currentOpenSubtitlesFingerprint();
      if (!mounted || s.entry?.key != entry.key) return;
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
          movieHash: fingerprint?.movieHash,
          onApply: (download) => s.applyExternalSubtitle(
            name: download.fileName,
            bytes: download.bytes,
            languageCode: download.languageCode,
            forced: download.forced,
            hearingImpaired: download.hearingImpaired,
          ),
        ),
      );
    } finally {
      client.close();
    }
  }

  Future<void> _openExternalSubtitleSync(SourcePlayback playback) async {
    final targetPlayer = playback.player;
    if (targetPlayer == null || !playback.hasSelectedPersistentExternalSubtitle) return;
    final initial = await playback.activeExternalSubtitleSync();
    if (!mounted || playback.player != targetPlayer || initial == null) return;
    final identity = playback.activeExternalSubtitleIdentity;
    if (identity == null) return;
    var replayPrerollMs = 500;
    Future<List<SubtitleCue>>? cueCache;
    Future<List<SubtitleCue>> loadSubtitleCues() {
      return cueCache ??= (() async {
        final file = playback.activePersistentExternalSubtitleFile;
        if (file == null || playback.activeExternalSubtitleIdentity != identity) {
          return const <SubtitleCue>[];
        }
        final size = await file.length();
        if (size == 0 || size > SubtitleRetimer.maximumInputBytes) {
          throw const FormatException('Subtitle is empty or exceeds the cue-inspection size limit.');
        }
        final bytes = await file.readAsBytes();
        if (bytes.length > SubtitleRetimer.maximumInputBytes) {
          throw const FormatException('Subtitle exceeds the cue-inspection size limit.');
        }
        if (!mounted || playback.player != targetPlayer || playback.activeExternalSubtitleIdentity != identity) {
          return const <SubtitleCue>[];
        }
        final cues = SubtitleRetimer.parseCues(
          sourceBytes: bytes,
          extension: p.extension(file.path).toLowerCase(),
        )..sort((a, b) => a.startMs.compareTo(b.startMs));
        return cues;
      })();
    }
    var closeScheduled = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: playback,
        builder: (context, _) {
          if (playback.activeExternalSubtitleIdentity != identity && !closeScheduled) {
            closeScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (sheetContext.mounted) Navigator.of(sheetContext).maybePop();
            });
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.videoSettings.subtitleSync,
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: t.common.close,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const AppIcon(Symbols.close_rounded),
                      ),
                    ],
                  ),
                  SyncOffsetControl(
                    player: targetPlayer,
                    propertyName: PlayerSyncOffsets.subtitleProperty,
                    contentIdentity: identity,
                    initialOffset: initial.delayMs,
                    initialSubtitleRate: initial.rate,
                    onOffsetChanged: (offset) {
                      if (playback.activeExternalSubtitleIdentity != identity) {
                        throw const SourceException(SourceFailure.cancelled);
                      }
                      return playback.persistExternalSubtitleSync(delayMs: offset);
                    },
                    onSubtitleRateChanged: (rate) {
                      if (playback.activeExternalSubtitleIdentity != identity) {
                        throw const SourceException(SourceFailure.cancelled);
                      }
                      return playback.persistExternalSubtitleSync(rate: rate);
                    },
                  ),
                  if (playback.canExportActiveExternalSubtitle)
                    TextButton.icon(
                      onPressed: () => sourceAction(
                        context,
                        () => _alignExternalSubtitleCueNow(
                          playback,
                          targetPlayer,
                          identity,
                          sheetContext,
                        ),
                      ),
                      icon: const AppIcon(Symbols.vertical_align_bottom_rounded),
                      label: Text(t.videoSettings.subtitleUsePlaybackTime),
                    ),

                  if (playback.canExportActiveExternalSubtitle)
                    StatefulBuilder(
                      builder: (context, setCueToolState) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              t['videoSettings.subtitleCueTools'] as String,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(t['videoSettings.subtitleReplayPreroll'] as String),
                              ),
                              Text('$replayPrerollMs ms'),
                            ],
                          ),
                          Slider(
                            value: replayPrerollMs.toDouble(),
                            min: 0,
                            max: 2500,
                            divisions: 10,
                            label: '$replayPrerollMs ms',
                            onChanged: (value) {
                              setCueToolState(() => replayPrerollMs = value.round());
                            },
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              IconButton(
                                tooltip: t['videoSettings.subtitlePreviousCue'] as String,
                                onPressed: targetPlayer.state.seekable
                                    ? () => sourceAction(context, () async {
                                        final cues = await loadSubtitleCues();
                                        final sync = await playback.activeExternalSubtitleSync();
                                        if (!mounted ||
                                            playback.player != targetPlayer ||
                                            playback.activeExternalSubtitleIdentity != identity ||
                                            sync == null) {
                                          return;
                                        }
                                        final now = playback.currentFilePositionMs;
                                        SubtitleCue? target;
                                        for (final cue in cues) {
                                          final visibleStartMs = (cue.startMs * sync.rate).round() + sync.delayMs;
                                          if (visibleStartMs < now - 100) {
                                            target = cue;
                                          } else {
                                            break;
                                          }
                                        }
                                        if (target == null) {
                                          showSnackBar(context, t['videoSettings.subtitleCueUnavailable'] as String);
                                          return;
                                        }
                                        await _seekExternalSubtitleCue(
                                          playback,
                                          targetPlayer,
                                          identity,
                                          target,
                                          sync.delayMs,
                                          sync.rate,
                                        );
                                      })
                                    : null,
                                icon: const AppIcon(Symbols.skip_previous_rounded),
                              ),
                              IconButton(
                                tooltip: t['videoSettings.subtitleCopyCue'] as String,
                                onPressed: () => sourceAction(context, () async {
                                  final cues = await loadSubtitleCues();
                                  final sync = await playback.activeExternalSubtitleSync();
                                  if (!mounted ||
                                      playback.player != targetPlayer ||
                                      playback.activeExternalSubtitleIdentity != identity ||
                                      sync == null) {
                                    return;
                                  }
                                  final now = playback.currentFilePositionMs;
                                  final active = cues.where((cue) {
                                    final start = (cue.startMs * sync.rate).round() + sync.delayMs;
                                    final end = (cue.endMs * sync.rate).round() + sync.delayMs;
                                    return start <= now && now < end;
                                  });
                                  final text = active
                                      .map((cue) => _plainSubtitleCueText(cue.text))
                                      .where((value) => value.isNotEmpty)
                                      .join('\n');
                                  if (text.isEmpty) {
                                    showSnackBar(context, t['videoSettings.subtitleCueUnavailable'] as String);
                                    return;
                                  }
                                  await Clipboard.setData(ClipboardData(text: text));
                                  if (mounted && playback.activeExternalSubtitleIdentity == identity) {
                                    showSnackBar(
                                      context,
                                      t['videoSettings.subtitleCueCopied'] as String,
                                      type: SnackBarType.success,
                                    );
                                  }
                                }),
                                icon: const AppIcon(Symbols.content_copy_rounded),
                              ),
                              IconButton(
                                tooltip: t['videoSettings.subtitleNextCue'] as String,
                                onPressed: targetPlayer.state.seekable
                                    ? () => sourceAction(context, () async {
                                        final cues = await loadSubtitleCues();
                                        final sync = await playback.activeExternalSubtitleSync();
                                        if (!mounted ||
                                            playback.player != targetPlayer ||
                                            playback.activeExternalSubtitleIdentity != identity ||
                                            sync == null) {
                                          return;
                                        }
                                        final now = playback.currentFilePositionMs;
                                        SubtitleCue? target;
                                        for (final cue in cues) {
                                          final visibleStartMs = (cue.startMs * sync.rate).round() + sync.delayMs;
                                          if (visibleStartMs > now + 100) {
                                            target = cue;
                                            break;
                                          }
                                        }
                                        if (target == null) {
                                          showSnackBar(context, t['videoSettings.subtitleCueUnavailable'] as String);
                                          return;
                                        }
                                        await _seekExternalSubtitleCue(
                                          playback,
                                          targetPlayer,
                                          identity,
                                          target,
                                          sync.delayMs,
                                          sync.rate,
                                        );
                                      })
                                    : null,
                                icon: const AppIcon(Symbols.skip_next_rounded),
                              ),
                              IconButton(
                                tooltip: t['videoSettings.subtitleReplayCue'] as String,
                                onPressed: targetPlayer.state.seekable
                                    ? () => sourceAction(context, () async {
                                        final cues = await loadSubtitleCues();
                                        final sync = await playback.activeExternalSubtitleSync();
                                        if (!mounted ||
                                            playback.player != targetPlayer ||
                                            playback.activeExternalSubtitleIdentity != identity ||
                                            sync == null ||
                                            cues.isEmpty) {
                                          return;
                                        }
                                        final now = playback.currentFilePositionMs;
                                        SubtitleCue? target;
                                        for (final cue in cues) {
                                          final visibleStartMs = (cue.startMs * sync.rate).round() + sync.delayMs;
                                          if (visibleStartMs <= now) {
                                            target = cue;
                                          } else {
                                            break;
                                          }
                                        }
                                        target ??= cues.first;
                                        await _seekExternalSubtitleCue(
                                          playback,
                                          targetPlayer,
                                          identity,
                                          target,
                                          sync.delayMs,
                                          sync.rate,
                                          prerollMs: replayPrerollMs,
                                        );
                                      })
                                    : null,
                                icon: const AppIcon(Symbols.replay_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Future<void> _seekExternalSubtitleCue(
    SourcePlayback playback,
    Player targetPlayer,
    String identity,
    SubtitleCue cue,
    int delayMs,
    double rate, {
    int prerollMs = 0,
  }) async {
    if (!mounted || playback.player != targetPlayer || playback.activeExternalSubtitleIdentity != identity) return;
    try {
      final sought = await playback.seekExternalSubtitleCue(
        expectedIdentity: identity,
        cueStartMs: cue.startMs,
        delayMs: delayMs,
        rate: rate,
        prerollMs: prerollMs,
      );
      if (!sought && mounted && playback.activeExternalSubtitleIdentity == identity) {
        showSnackBar(context, t['videoSettings.subtitleCueSeekUnavailable'] as String);
      }
    } on Object catch (error, stackTrace) {
      appLogger.w('Could not seek to a subtitle cue', error: error, stackTrace: stackTrace);
      if (mounted && playback.activeExternalSubtitleIdentity == identity) {
        showErrorSnackBar(context, t.common.error);
      }
    }
  }

  Future<void> _alignExternalSubtitleCueNow(
    SourcePlayback playback,
    Player targetPlayer,
    String identity,
    BuildContext syncSheetContext,
  ) async {
    final file = playback.activePersistentExternalSubtitleFile;
    if (file == null || !playback.canExportActiveExternalSubtitle) return;

    try {
      final size = await file.length();
      if (size == 0 || size > SubtitleRetimer.maximumInputBytes) {
        throw const FormatException('Subtitle is empty or exceeds the cue-inspection size limit.');
      }
      final bytes = await file.readAsBytes();
      final extension = p.extension(file.path).toLowerCase();
      final cues = SubtitleRetimer.parseCues(sourceBytes: bytes, extension: extension);
      final initialSync = await playback.activeExternalSubtitleSync();
      if (!mounted ||
          playback.player != targetPlayer ||
          playback.activeExternalSubtitleIdentity != identity ||
          initialSync == null) {
        return;
      }

      final selection = await showModalBottomSheet<({SubtitleCue cue, int playbackPositionMs})>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _SubtitleCuePickerSheet(
          cues: cues,
          playback: playback,
          initialPlaybackPositionMs: playback.currentFilePositionMs,
          initialDelayMs: initialSync.delayMs,
          initialRate: initialSync.rate,
        ),
      );
      if (selection == null ||
          !mounted ||
          playback.player != targetPlayer ||
          playback.activeExternalSubtitleIdentity != identity) {
        return;
      }

      await playback.alignExternalSubtitleCueNow(
        expectedIdentity: identity,
        cueStartMs: selection.cue.startMs,
        playbackPositionMs: selection.playbackPositionMs,
      );
      if (syncSheetContext.mounted) Navigator.of(syncSheetContext).pop();
    } on Object catch (error, stackTrace) {
      appLogger.w('Could not align subtitle cue to playback', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.common.error);
    }
  }

  Future<void> _exportSynchronizedSubtitle(SourcePlayback playback) async {
    final sourceFile = playback.activePersistentExternalSubtitleFile;
    final targetPlayer = playback.player;
    if (sourceFile == null || targetPlayer == null || !playback.canExportActiveExternalSubtitle) return;
    final extension = p.extension(sourceFile.path).toLowerCase();
    final identity = playback.activeExternalSubtitleIdentity;
    if (identity == null) return;

    try {
      final sync = await playback.activeExternalSubtitleSync();
      if (!mounted ||
          playback.player != targetPlayer ||
          playback.activeExternalSubtitleIdentity != identity ||
          sync == null) {
        return;
      }
      final sourceBytes = await sourceFile.readAsBytes();
      final result = SubtitleRetimer.retime(
        sourceBytes: sourceBytes,
        extension: extension,
        delayMs: sync.delayMs,
        rate: sync.rate,
      );
      if (!mounted || playback.activeExternalSubtitleIdentity != identity) return;

      if (result.clippedCueCount > 0) {
        final proceed = await showConfirmDialog(
          context,
          title: t['videoSettings.subtitleExport'] as String,
          message: t['videoSettings.subtitleExportClipped'] as String,
        );
        if (!proceed || !mounted || playback.activeExternalSubtitleIdentity != identity) return;
      }

      final rawTitle = playback.entry?.displayTitle ?? '';
      var baseName = rawTitle
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      while (baseName.endsWith('.')) {
        baseName = baseName.substring(0, baseName.length - 1);
      }
      if (baseName.isEmpty) baseName = 'subtitle';
      baseName = baseName.substring(0, math.min(120, baseName.length));
      var path = await FilePicker.saveFile(
        dialogTitle: t['videoSettings.subtitleExport'] as String,
        fileName: baseName   '.synced'   extension,
        type: FileType.custom,
        allowedExtensions: [extension.substring(1)],
      );
      if (path == null || !mounted) return;
      if (p.extension(path).isEmpty) path  = extension;
      if (p.extension(path).toLowerCase() != extension ||
          p.equals(p.normalize(p.absolute(path)), p.normalize(sourceFile.absolute.path))) {
        showErrorSnackBar(context, t['videoSettings.subtitleExportFailed'] as String);
        return;
      }

      final target = File(path);
      if (await target.exists()) {
        if (!mounted) return;
        final replace = await showConfirmDialog(
          context,
          title: t['videoSettings.subtitleExport'] as String,
          message: t['videoSettings.subtitleExportReplace'] as String,
        );
        if (!replace || !mounted) return;
      }
      if (playback.activeExternalSubtitleIdentity != identity) return;
      await _writeSubtitleExport(target, result.bytes);
      if (mounted) showSnackBar(context, t['videoSettings.subtitleExportSuccess'] as String);
    } on Object {
      if (mounted) showErrorSnackBar(context, t['videoSettings.subtitleExportFailed'] as String);
    }
  }

  Future<void> _writeSubtitleExport(File target, List<int> bytes) async {
    final nonce = DateTime.now().microsecondsSinceEpoch.toString();
    final staged = File(target.path   '.plezyng.'   nonce   '.pending');
    final backup = File(target.path   '.plezyng.'   nonce   '.backup');
    var backedUp = false;
    try {
      await staged.writeAsBytes(bytes, flush: true);
      if (await target.exists()) {
        await target.rename(backup.path);
        backedUp = true;
      }
      try {
        await staged.rename(target.path);
      } catch (_) {
        if (backedUp && await backup.exists()) await backup.rename(target.path);
        rethrow;
      }
      if (backedUp && await backup.exists()) {
        try {
          await backup.delete();
        } on Object {
          // The new export is committed; a stale backup is safe to remove later.
        }
      }
    } finally {
      if (await staged.exists()) await staged.delete();
    }
  }

  Future<void> _addTransientMediaBookmark(SourcePlayback s) async {
    final mediaKey = s.localMediaBookmarkKey;
    if (mediaKey == null || _bookmarkBusy) return;
    final current = MediaBookmarkService.forMedia(mediaKey);
    final label = await showTextInputDialog(
      context,
      title: t.videoControls.addBookmark,
      labelText: t.videoControls.bookmarkName,
      hintText: t.videoControls.bookmarkNameHint,
      initialValue: t.videoControls.bookmarkDefaultName(n: current.length   1),
      validator: (value) => value.trim().isEmpty ? t.videoControls.bookmarkNameRequired : null,
    );
    if (!mounted || label == null || s.localMediaBookmarkKey != mediaKey) return;
    setState(() => _bookmarkBusy = true);
    try {
      await MediaBookmarkService.add(mediaKey, label, s.currentFilePositionMs);
      if (!mounted) return;
      setState(() {});
      showSnackBar(context, t.videoControls.bookmarkSaved, type: SnackBarType.success);
    } on MediaBookmarkLimitException {
      if (mounted) showSnackBar(context, t.videoControls.bookmarkLimitReached);
    } on Object {
      if (mounted) showErrorSnackBar(context, t.videoControls.bookmarkUnavailable);
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _removeTransientMediaBookmark(String mediaKey, MediaBookmark bookmark) async {
    if (_bookmarkBusy) return;
    setState(() => _bookmarkBusy = true);
    try {
      await MediaBookmarkService.remove(mediaKey, bookmark.id);
      if (mounted) {
        setState(() {});
        showSnackBar(context, t.videoControls.bookmarkDeleted);
      }
    } on Object {
      if (mounted) showErrorSnackBar(context, t.videoControls.bookmarkUnavailable);
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _seekTransientMediaBookmark(SourcePlayback playback, String mediaKey, MediaBookmark bookmark) async {
    if (playback.localMediaBookmarkKey != mediaKey) return;
    final offset = playback.positionMs - playback.currentFilePositionMs;
    await playback.seek(offset   bookmark.positionMs);
  }

  Future<void> _setSourceSegmentLoop(SourcePlayback playback, int action) async {
    final player = playback.player;
    if (player == null || player.playerType != 'mpv' || playback.isLiveInput || !player.state.seekable) return;
    try {
      if (action == 0) {
        await player.setProperty('ab-loop-b', 'no');
        await player.setProperty('ab-loop-a', (playback.currentFilePositionMs / 1000).toStringAsFixed(3));
        if (!mounted) return;
        setState(() {
          _sourceLoopStartMs = playback.currentFilePositionMs;
          _sourceLoopEndMs = null;
        });
        showSnackBar(
          context,
          t.videoControls.loopPointSet(point: 'A', time: sourceTime(playback.currentFilePositionMs)),
        );
        return;
      }
      if (action == 1) {
        final start = double.tryParse(await player.getProperty('ab-loop-a') ?? '');
        if (!mounted) return;
        if (start == null || !start.isFinite || start < 0) {
          showSnackBar(context, t.videoControls.setLoopStartFirst);
          return;
        }
        final position = playback.currentFilePositionMs;
        if (position <= (start * 1000).round()) {
          showSnackBar(context, t.videoControls.loopEndAfterStart);
          return;
        }
        await player.setProperty('ab-loop-b', (position / 1000).toStringAsFixed(3));
        if (!mounted) return;
        setState(() => _sourceLoopEndMs = position);
        showSnackBar(context, t.videoControls.loopPointSet(point: 'B', time: sourceTime(position)));
        return;
      }
      await player.setProperty('ab-loop-a', 'no');
      await player.setProperty('ab-loop-b', 'no');
      if (!mounted) return;
      setState(() {
        _sourceLoopStartMs = null;
        _sourceLoopEndMs = null;
      });
    } on Object {
      if (mounted) showErrorSnackBar(context, t.videoControls.segmentLoopUnavailable);
    }
  }

  Widget controls(SourcePlayback s) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (s.isTransientInput)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Card(
            child: ListTile(
              leading: AppIcon(s.isLiveInput ? Symbols.live_tv_rounded : Symbols.schedule_rounded),
              title: Text(s.isLiveInput ? t.universalMedia.liveSession : t.universalMedia.sessionOnly),
              subtitle: Text(s.isLiveInput ? t.universalMedia.liveCueHelp : t.universalMedia.sessionOnlyHelp),
            ),
          ),
        ),
      if (s.opening) const LinearProgressIndicator(),
      if (s.isLiveInput)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Semantics(liveRegion: true, child: Text(t.universalMedia.liveCue)),
        )
      else ...[
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusableSlider(
            value: (_dragPosition ?? s.positionMs.toDouble()).clamp(
              s.timelineStartMs.toDouble(),
              s.timelineEndMs > s.timelineStartMs ? s.timelineEndMs.toDouble() : s.timelineStartMs   1.0,
            ),
            min: s.timelineStartMs.toDouble(),
            max: s.timelineEndMs > s.timelineStartMs ? s.timelineEndMs.toDouble() : s.timelineStartMs   1.0,
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
      ],
      if (!s.video && !s.isLiveInput && s.chapters.isNotEmpty)
        TextButton(
          onPressed: () => sourceAction(context, () async {
            s.chapterTimeline = !s.chapterTimeline;
            await s.savePreferences();
          }),
          child: Text(s.chapterTimeline ? t.audiobook.chapterTimeline : t.audiobook.bookTimeline),
        ),
      if (s.sleepDeadline != null)
        Text(t.audiobook.sleepRemaining(time: sourceTime(s.sleepDeadline!.difference(DateTime.now()).inMilliseconds))),
      if (s.isCapturePreview)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon(Symbols.videocam_rounded, size: 18),
                const SizedBox(width: 6),
                Text(t.universalMedia.capturePreviewActive),
              ],
            ),
          ),
        ),
      if (s.isRecordingStream)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Semantics(liveRegion: true, child: Text(t.universalMedia.recordingActive)),
        ),
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
          if (!s.isLiveInput)
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
          if (!s.isLiveInput)
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
          if (!s.isLiveInput)
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
          if (s.video &&
              !s.isLiveInput &&
              s.player?.state.seekable == true &&
              s.currentFileDurationMs > 0 &&
              s.player?.playerType == 'mpv')
            AppMenuButton<int>(
              icon: AppIcon(
                Symbols.repeat_one_rounded,
                fill: _sourceLoopStartMs == null ? 0 : 1,
                color: _sourceLoopStartMs == null ? null : Theme.of(context).colorScheme.primary,
              ),
              tooltip: t.videoControls.segmentLoop,
              adaptiveSheet: true,
              entriesBuilder: (_) => [
                AppMenuItem(
                  value: 0,
                  label: t.videoControls.setLoopStart,
                  subtitle: _sourceLoopStartMs == null ? null : sourceTime(_sourceLoopStartMs!),
                ),
                AppMenuItem(
                  value: 1,
                  label: t.videoControls.setLoopEnd,
                  subtitle: _sourceLoopEndMs == null ? null : sourceTime(_sourceLoopEndMs!),
                ),
                AppMenuItem(value: 2, label: t.videoControls.clearSegmentLoop),
              ],
              onSelected: (action) => unawaited(_setSourceSegmentLoop(s, action)),
            ),
          if (!s.isLiveInput)
            IconButton(
              tooltip: t.audiobook.undoSeek,
              onPressed: s.canUndoSeek ? () => sourceAction(context, s.undoSeek) : null,
              icon: const AppIcon(Symbols.undo_rounded),
            ),
          if (!s.isLiveInput)
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
                  await s.seek(parseListeningTime(value)!   (s.hasCompleteTimeline ? 0 : s.timelineStartMs));
                }
              }),
            ),
          if (!s.isTransientInput)
            IconButton(
              tooltip: t.fileSources.bookmark,
              onPressed: () => sourceAction(context, () async {
                final note = await editSourceNote(context);
                if (note != null) await s.bookmark(note: note);
              }),
              icon: const AppIcon(Symbols.bookmark_add_rounded),
            ),
          if (!s.isTransientInput)
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
          if (s.video && s.canExportActiveExternalSubtitle)
            IconButton(
              tooltip: t['videoSettings.subtitleExport'] as String,
              onPressed: () => sourceAction(context, () => _exportSynchronizedSubtitle(s)),
              icon: const AppIcon(Symbols.download_rounded),
            ),
          if (s.video && s.hasSelectedPersistentExternalSubtitle)
            IconButton(
              tooltip: t.videoSettings.subtitleSync,
              onPressed: () => sourceAction(context, () => _openExternalSubtitleSync(s)),
              icon: const AppIcon(Symbols.sync_rounded),
            ),
          if (s.isTransientInput && s.player?.playerType == 'mpv')
            IconButton(
              tooltip: t.fileInfo.title,
              onPressed: () => OverlaySheetController.showAdaptive<void>(
                context,
                isScrollControlled: true,
                builder: (_) => SourceFileInfoSheet(player: s.player!, title: s.entry?.displayTitle ?? ''),
              ),
              icon: const AppIcon(Symbols.info_rounded),
            ),
          if (s.isTransientInput && s.video && s.player?.playerType == 'mpv')
            SourceEditionMenuButton(player: s.player!, sourceIdentity: '${s.entry?.id ?? ''}:${s.fileIndex}'),
          if (s.video && !s.isTransientInput)
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
          if (s.video && s.player?.playerType == 'mpv')
            IconButton(
              tooltip: t.universalMedia.pictureAdjustments,
              onPressed: () =>
                  showPictureAdjustmentsSheet(context, s.player!, onChanged: s.markPictureAdjustmentChanged),
              icon: const AppIcon(Symbols.tune_rounded),
            ),
          if (PlatformDetector.isDesktopOS() && s.isTransientInput && s.isLiveInput && s.player?.playerType == 'mpv')
            IconButton(
              tooltip: s.isRecordingStream ? t.universalMedia.stopRecording : t.universalMedia.recordStream,
              onPressed: () => sourceAction(context, () => _toggleStreamRecording(s)),
              icon: AppIcon(s.isRecordingStream ? Symbols.stop_circle_rounded : Symbols.radio_button_checked_rounded),
            ),
          if (s.video && _full)
            FocusableButton(
              autoScroll: false,
              onPressed: _toggleSourceWorkspace,
              child: IconButton(
                tooltip: _workspaceDetached ? t.videoControls.returnToFullPlayer : t.videoControls.openMiniPlayer,
                onPressed: _toggleSourceWorkspace,
                icon: const AppIcon(Symbols.picture_in_picture_alt_rounded),
              ),
            ),
        ],
      ),
      if (s.failure != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SourceErrorMessage(message: sourceFailureText(SourceException(s.failure!))),
              if (s.canRetry) ...[
                const SizedBox(height: 8),
                FocusableButton(
                  onPressed: () => unawaited(sourceAction(context, s.retry)),
                  child: Text(t.common.retry),
                ),
              ],
            ],
          ),
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
    final localMediaBookmarkKey = s.localMediaBookmarkKey;
    final localMediaBookmarks = localMediaBookmarkKey == null
        ? const <MediaBookmark>[]
        : MediaBookmarkService.forMedia(localMediaBookmarkKey);
    final video = s.video && core != null
        ? _workspaceDetached
              ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(Symbols.picture_in_picture_alt_rounded, size: 36, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(t.videoControls.pipButton, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                )
              : AspectRatio(
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
              title: Text(isolateDisplayText(s.entry!.displayTitle), maxLines: 1, overflow: TextOverflow.ellipsis),
              focusableAppBarActions: true,
              actions: [
                if (!s.video && core is AudioSpectrumAnalyzer)
                  FocusableButton(
                    autoScroll: false,
                    onPressed: () => setState(() => _sourceVisualizerVisible = !_sourceVisualizerVisible),
                    child: IconButton(
                      tooltip: t.music.visualizer,
                      isSelected: _sourceVisualizerVisible,
                      onPressed: () => setState(() => _sourceVisualizerVisible = !_sourceVisualizerVisible),
                      selectedIcon: const AppIcon(Symbols.graphic_eq_rounded, fill: 1),
                      icon: const AppIcon(Symbols.graphic_eq_rounded),
                    ),
                  ),
                if (s.canUseDirectQueueControls)
                  IconButton(
                    tooltip: t.music.queue,
                    onPressed: () => unawaited(showSourceQueueSheet(context, s)),
                    icon: const AppIcon(Symbols.queue_music_rounded),
                  ),
                if (s.canExportLocalPlaylist)
                  IconButton(
                    tooltip: t.universalMedia.saveQueuePlaylist,
                    onPressed: () => unawaited(_saveLocalPlaylist(s)),
                    icon: const AppIcon(Symbols.playlist_add_check_rounded),
                  ),
                FocusableButton(
                  autoScroll: false,
                  onPressed: _toggleSourceWorkspace,
                  child: IconButton(
                    tooltip: _workspaceDetached
                        ? (s.video ? t.videoControls.returnToFullPlayer : t.common.returnToFullView)
                        : t.videoControls.openMiniPlayer,
                    onPressed: _toggleSourceWorkspace,
                    icon: const AppIcon(Symbols.picture_in_picture_alt_rounded),
                  ),
                ),
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
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: _sourceVisualizerVisible && core is AudioSpectrumAnalyzer
                                        ? LayoutBuilder(
                                            key: const ValueKey('source-audio-visualizer'),
                                            builder: (context, constraints) => SizedBox(
                                              width: constraints.maxWidth.clamp(180, 520).toDouble(),
                                              height: 220,
                                              child: MusicVisualizer.forSource(
                                                playback: s,
                                                preset: _sourceVisualizerPreset,
                                                onPresetChanged: (preset) =>
                                                    setState(() => _sourceVisualizerPreset = preset),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            key: const ValueKey('source-cover'),
                                            width: 160,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: tokens(context).surface,
                                              borderRadius: BorderRadius.circular(tokens(context).radiusLg),
                                            ),
                                            child: SourceCover(entry: s.entry!),
                                          ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    isolateDisplayText(s.entry!.displayTitle),
                                    style: Theme.of(context).textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (s.entry!.author.isNotEmpty)
                                    Text(
                                      isolateDisplayText(s.entry!.author),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (s.currentChapter != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        isolateDisplayText(s.currentChapter!.title),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                  if (core.playerType == 'mpv' && core.state.tracks.video.length > 1)
                                    AppMenuButton<String>(
                                      icon: const AppIcon(Symbols.video_library_rounded),
                                      tooltip: t.videoSettings.videoTrack,
                                      adaptiveSheet: true,
                                      entriesBuilder: (_) => [
                                        for (final track in core.state.tracks.video)
                                          AppMenuItem(
                                            value: track.id,
                                            label: _sourceVideoTrackLabel(track),
                                            selected: track.isSelected,
                                          ),
                                      ],
                                      onSelected: (id) => sourceAction(context, () => core.setProperty('vid', id)),
                                    ),
                                  AppMenuButton<String>(
                                    icon: const AppIcon(Symbols.audiotrack_rounded),
                                    tooltip: t.fileSources.audioTrack,
                                    adaptiveSheet: true,
                                    entriesBuilder: (_) => [
                                      for (final track in core.state.tracks.audio)
                                        AppMenuItem(
                                          value: track.id,
                                          label: isolateDisplayText(track.title ?? track.language ?? track.id),
                                        ),
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
                                        AppMenuItem(
                                          value: track.id,
                                          label: isolateDisplayText(track.title ?? track.language ?? track.id),
                                        ),
                                    ],
                                    onSelected: (id) =>
                                        sourceAction(context, () => core.selectSubtitleTrack(SubtitleTrack(id: id))),
                                  ),
                                ],
                              ),
                            ),
                          if (s.chapters.isNotEmpty || localMediaBookmarkKey != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localMediaBookmarkKey == null
                                        ? t.fileSources.chapters
                                        : t.videoControls.chaptersAndBookmarks,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < s.chapters.length; i  )
                                    SourceTile(
                                      title: isolateDisplayText(s.chapters[i].title),
                                      subtitle: sourceTime(s.chapters[i].startMs),
                                      icon: Symbols.format_list_numbered_rounded,
                                      index: i,
                                      count:
                                          s.chapters.length  
                                          localMediaBookmarks.length  
                                          (localMediaBookmarkKey == null ? 0 : 1),
                                      onTap: () => sourceAction(context, () => s.seekChapter(i)),
                                    ),
                                  if (localMediaBookmarkKey != null)
                                    SourceTile(
                                      title: t.videoControls.addBookmark,
                                      icon: Symbols.bookmark_add_rounded,
                                      index: s.chapters.length,
                                      count: s.chapters.length   localMediaBookmarks.length   1,
                                      onTap: _bookmarkBusy ? null : () => unawaited(_addTransientMediaBookmark(s)),
                                    ),
                                  if (localMediaBookmarkKey != null && localMediaBookmarks.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(t.videoControls.bookmarksHelp),
                                    )
                                  else if (localMediaBookmarkKey != null)
                                    for (var i = 0; i < localMediaBookmarks.length; i  )
                                      SourceTile(
                                        key: ValueKey('local-media-bookmark-${localMediaBookmarks[i].id}'),
                                        title: localMediaBookmarks[i].label,
                                        subtitle: sourceTime(localMediaBookmarks[i].positionMs),
                                        icon: Symbols.bookmark_rounded,
                                        index: s.chapters.length   i   1,
                                        count: s.chapters.length   localMediaBookmarks.length   1,
                                        onTap: () => sourceAction(
                                          context,
                                          () => _seekTransientMediaBookmark(
                                            s,
                                            localMediaBookmarkKey,
                                            localMediaBookmarks[i],
                                          ),
                                        ),
                                        trailing: IconButton(
                                          tooltip: t.videoControls.deleteBookmark,
                                          onPressed: _bookmarkBusy
                                              ? null
                                              : () => unawaited(
                                                  _removeTransientMediaBookmark(
                                                    localMediaBookmarkKey,
                                                    localMediaBookmarks[i],
                                                  ),
                                                ),
                                          icon: const AppIcon(Symbols.delete_outline_rounded),
                                        ),
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
        padding: EdgeInsetsDirectional.fromSTEB((inset?.startInset ?? 0)   16, 0, 16, (inset?.bottomInset ?? 0)   16),
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
                          title: Text(
                            isolateDisplayText(s.entry!.displayTitle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            isolateDisplayText(s.currentChapter?.title ?? s.entry!.author),
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



String _plainSubtitleCueText(String value) => value
    .replaceAll(RegExp(r'\{[^}]*\}'), '')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll(RegExp(r'\\[Nn]'), '\n')
    .replaceAll(RegExp(r'\\h'), ' ')
    .replaceAll('&nbsp;', ' ')
    .trim();

class _SubtitleCuePickerSheet extends StatefulWidget {
  const _SubtitleCuePickerSheet({
    required this.cues,
    required this.playback,
    required this.initialPlaybackPositionMs,
    required this.initialDelayMs,
    required this.initialRate,
  });

  final List<SubtitleCue> cues;
  final SourcePlayback playback;
  final int initialPlaybackPositionMs;
  final int initialDelayMs;
  final double initialRate;

  @override
  State<_SubtitleCuePickerSheet> createState() => _SubtitleCuePickerSheetState();
}

class _SubtitleCuePickerSheetState extends State<_SubtitleCuePickerSheet> {
  late final ScrollController _scrollController;

  int _closestCueIndex() {
    var nearestIndex = 0;
    var nearestDistance = 1 << 62;
    for (var index = 0; index < widget.cues.length; index  ) {
      final cue = widget.cues[index];
      final visibleStartMs = (cue.startMs * widget.initialRate).round()   widget.initialDelayMs;
      final distance = (visibleStartMs - widget.initialPlaybackPositionMs).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }
    return nearestIndex;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final nearestIndex = _closestCueIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo((nearestIndex * 76.0).clamp(0.0, _scrollController.position.maxScrollExtent).toDouble());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.videoSettings.subtitleCueTimeAnchor1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: t.common.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AppIcon(Symbols.close_rounded),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: widget.playback,
                builder: (context, _) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12, bottom: 8),
                    child: Text(
                      '${t.videoSettings.subtitleUsePlaybackTime}: ${sourceTime(widget.playback.currentFilePositionMs)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.cues.length,
                  itemExtent: 76,
                  itemBuilder: (context, index) {
                    final cue = widget.cues[index];
                    final plainText = cue.text
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .replaceAll(RegExp(r'\s '), ' ')
                        .trim();
                    return ListTile(
                      leading: SizedBox(
                        width: 72,
                        child: Text(
                          sourceTime(cue.startMs),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      title: Text(plainText, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(context).pop(
                        (
                          cue: cue,
                          playbackPositionMs: widget.playback.currentFilePositionMs,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
