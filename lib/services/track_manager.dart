import 'dart:async';

import 'package:flutter/foundation.dart';

import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';

import '../media/media_item.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_source_info.dart';
import '../services/scoped_player_prefs.dart';
import '../services/settings_service.dart';
import '../services/subtitle_preference.dart';
import '../services/track_selection_service.dart';
import '../utils/app_logger.dart';
import '../utils/track_label_builder.dart';

/// Persists a track choice for the current part to the server.
/// Backends that persist through another path (Jellyfin uses playback progress
/// stream indexes) or lack server-side stream selection leave this null.
/// [trackType] is `'audio'` or `'subtitle'`.
typedef TrackPreferencePersister =
    Future<void> Function({required int partId, required String trackType, required int streamID});

/// Manages track (audio + subtitle) lifecycle: external subtitle loading,
/// automatic track selection, server preference sync, and cycling.
///
/// Follows the same manager pattern as [VideoFilterManager]:
/// disposed when the player screen tears down.
class TrackManager {
  final Player player;

  /// Returns false once the owning widget is unmounted or disposed.
  final bool Function() isActive;

  /// Optional hook for persisting a track choice to Plex immediately. `null`
  /// for backends with a different persistence path (Jellyfin) or no
  /// server-side track preferences.
  final TrackPreferencePersister? persistTrackPreference;

  /// Resolves the user's profile settings (may be null during loading).
  final MediaServerUserProfile? Function() getProfileSettings;

  /// Waits until profile settings are available (offline path).
  final Future<void> Function() waitForProfileSettings;

  /// Shows a transient message to the user (e.g., snackbar).
  final void Function(String message, {Duration? duration})? showMessage;

  // ── Mutable configuration (updated on episode navigation) ──────────

  MediaItem metadata;
  MediaSourceInfo? mediaInfo;
  AudioTrack? preferredAudioTrack;
  SubtitlePreference? preferredSubtitleTrack;
  SubtitlePreference? preferredSecondarySubtitleTrack;

  /// The primary subtitle is burned into the video by the server, so it needs no native track and
  /// none is ever coming. Set on a transcode whose selected row has no sidecar.
  bool primarySubtitleIsServerRendered = false;

  // ── Internal state ─────────────────────────────────────────────────

  bool waitingForExternalSubsTrackSelection = false;
  bool _externalSubtitleAddsInFlight = false;
  bool _isApplyingTrackSelection = false;
  Completer<void>? _selectionIdleCompleter;
  Future<void>? _activePlayerMutationDrain;
  List<SubtitleTrack> _lastExternalSubtitles = const [];
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  Timer? _subtitleFallbackTimer;
  Timer? _trackSelectionFallbackTimer;
  bool _disposed = false;
  int _selectionGeneration = 0;

  bool get _managerIsActive => !_disposed && isActive();

  bool _isSelectionCurrent(int generation) => _managerIsActive && generation == _selectionGeneration;

  void _trackDispatchedPlayerMutation(Future<void> mutation) {
    final drain = mutation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _activePlayerMutationDrain = drain;
    unawaited(
      drain.then((_) {
        if (identical(_activePlayerMutationDrain, drain)) {
          _activePlayerMutationDrain = null;
        }
      }),
    );
  }

  /// Cached external subtitles for re-use after backend fallback.
  @visibleForTesting
  List<SubtitleTrack> get lastExternalSubtitles => _lastExternalSubtitles;

  TrackManager({
    required this.player,
    required this.isActive,
    this.persistTrackPreference,
    required this.getProfileSettings,
    required this.waitForProfileSettings,
    required this.metadata,
    this.mediaInfo,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.preferredSecondarySubtitleTrack,
    this.primarySubtitleIsServerRendered = false,
    this.showMessage,
  });

  // ── External subtitles ─────────────────────────────────────────────

  /// Cache external subtitles for backend fallback recovery.
  void cacheExternalSubtitles(List<SubtitleTrack> externalSubtitles) {
    _lastExternalSubtitles = externalSubtitles;
  }

  /// Add external subtitle tracks to the player in metadata order.
  ///
  /// MPV assigns subtitle track IDs in completion order, so parallel sub-adds
  /// make the track list nondeterministic. Keep this ordered for the fallback
  /// paths that cannot attach sidecars through loadfile.
  Future<void> addExternalSubtitles(List<SubtitleTrack> externalSubtitles, {Future<void>? waitUntilReady}) async {
    if (externalSubtitles.isEmpty) return;

    _externalSubtitleAddsInFlight = true;
    try {
      if (waitUntilReady != null) {
        try {
          await waitUntilReady;
        } catch (e) {
          appLogger.w('Continuing external subtitle load after readiness wait failed', error: e);
        }
        if (!isActive()) return;
      }

      appLogger.d('Adding ${externalSubtitles.length} external subtitle(s) to player');

      for (final subtitleTrack in externalSubtitles.where((s) => s.uri != null)) {
        try {
          await player.addSubtitleTrack(
            uri: subtitleTrack.uri!,
            title: subtitleTrack.title,
            language: subtitleTrack.language,
            select: subtitleTrack.isDefault,
          );
          appLogger.d('Added external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}');
        } catch (e) {
          appLogger.w('Failed to add external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}', error: e);
        }
      }
    } finally {
      _externalSubtitleAddsInFlight = false;
    }
  }

  /// Resume playback after external subtitles have been loaded (or failed).
  /// Sets up a 3-second fallback in case playbackRestart doesn't fire.
  Future<void> resumeAfterSubtitleLoad() async {
    if (!isActive()) return;

    try {
      await player.play();
      final pos = player.state.position;
      try {
        await player.seek(pos.inMilliseconds > 0 ? pos : Duration.zero);
      } catch (e) {
        appLogger.w('Non-critical seek after subtitle load failed', error: e);
      }
    } catch (e) {
      // play() failed — clear the flag immediately since playbackRestart won't fire
      appLogger.w('Resume after subtitle load failed, applying track selection directly', error: e);
      waitingForExternalSubsTrackSelection = false;
      unawaited(applyTrackSelection());
      return;
    }

    // Fallback if playbackRestart doesn't fire
    _subtitleFallbackTimer?.cancel();
    _subtitleFallbackTimer = Timer(const Duration(seconds: 3), () {
      if (waitingForExternalSubsTrackSelection && isActive()) {
        waitingForExternalSubsTrackSelection = false;
        applyTrackSelection();
      }
    });
  }

  /// Invalidates every pending automatic selection before the player is
  /// reused for another media generation and returns a bounded drain for the
  /// native player mutation already in flight at invalidation time.
  ///
  /// The returned future does not wait for profile/track readiness or include
  /// mutations started by a later generation. Reload callers can await it
  /// immediately before replacement media is opened, ensuring an
  /// already-dispatched native audio, subtitle, or rate mutation cannot land
  /// on that replacement. Disposal deliberately ignores the drain so teardown
  /// is never held by a native command.
  Future<void> invalidatePendingSelection() {
    final activePlayerMutationDrain = _activePlayerMutationDrain;
    _selectionGeneration++;
    _trackLoadingSubscription?.cancel();
    _trackLoadingSubscription = null;
    _trackSelectionFallbackTimer?.cancel();
    _trackSelectionFallbackTimer = null;
    return activePlayerMutationDrain ?? Future<void>.value();
  }

  // ── Track selection ────────────────────────────────────────────────

  /// Apply track selection once tracks are available.
  ///
  /// The five-second fallback applies any ready audio/rate settings, but a
  /// source that advertises subtitles keeps listening for their late native
  /// track-list update. The listener has a separate hard deadline and every
  /// callback is scoped to the current media generation. The deadline pass
  /// resolves the subtitle from whatever has arrived rather than deferring
  /// again, so a source the native player never exposes ends as an explicit
  /// decision instead of silently leaving subtitles untouched.
  ///
  /// Callers may arm this after an `await`, so a manager disposed or
  /// deactivated in the meantime must not subscribe or start a timer: nothing
  /// would ever cancel them. The generation checks inside each callback only
  /// stop the work, not the allocation.
  void applyTrackSelectionWhenReady() {
    if (!_managerIsActive) return;
    final selectionGeneration = _selectionGeneration;
    bool selectionIsCurrent() => _isSelectionCurrent(selectionGeneration);
    final currentTracks = player.state.tracks;
    if (_tracksReadyForSelection(currentTracks)) {
      unawaited(applyTrackSelection());
      return;
    }

    _trackLoadingSubscription?.cancel();
    _trackLoadingSubscription = player.streams.tracks.listen((tracks) {
      if (!selectionIsCurrent() || !_tracksReadyForSelection(tracks)) return;

      _trackLoadingSubscription?.cancel();
      _trackLoadingSubscription = null;
      _trackSelectionFallbackTimer?.cancel();
      _trackSelectionFallbackTimer = null;
      unawaited(applyTrackSelection());
    });

    _trackSelectionFallbackTimer?.cancel();
    _trackSelectionFallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!selectionIsCurrent()) return;

      final tracks = player.state.tracks;
      final waitingForAdvertisedSubtitles =
          mediaInfo?.subtitleTracks.isNotEmpty == true && !_tracksReadyForSelection(tracks);
      if (!waitingForAdvertisedSubtitles) {
        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
        _trackSelectionFallbackTimer = null;
        unawaited(applyTrackSelection());
        return;
      }

      appLogger.w(
        'Native subtitle tracks are still pending after 5 seconds; applying ready track settings and continuing to wait',
      );
      unawaited(applyTrackSelection());
      _trackSelectionFallbackTimer = Timer(const Duration(seconds: 25), () {
        if (!selectionIsCurrent()) return;
        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
        _trackSelectionFallbackTimer = null;
        if (!_tracksReadyForSelection(player.state.tracks)) {
          appLogger.w('Advertised native subtitle selection did not resolve before the 30-second deadline');
        }
        unawaited(applyTrackSelection(waitForPendingSource: false));
      });
    });
  }

  bool _tracksReadyForSelection(Tracks tracks) {
    final realSubtitleTracks = tracks.subtitle
        .where((track) => track.id != SubtitleTrack.auto.id && track.id != SubtitleTrack.off.id)
        .toList(growable: false);
    final service = TrackSelectionService(metadata: metadata, plexMediaInfo: mediaInfo);

    // A burned-in primary is already in the picture, so no native track is ever coming for it.
    // Waiting for one holds up audio and rate setup for the five-second fallback and then logs a
    // missed deadline twenty-five seconds later, for a selection already on screen.
    //
    // Answered before the empty-list guard below: a silent video whose primary is burned and whose
    // secondary is unset legitimately exposes no tracks at all, and treating that as "not ready"
    // spent both waits plus selection's own ten seconds on a catalog that was already complete.
    //
    // A carried *secondary* is a real native track that may still be on its way, though, and only
    // one selection pass ever runs - so retiring the wait here would drop it for good. Neither is
    // audio: the source can advertise tracks the native catalog has not published yet, and answering
    // "ready" on the subtitle question alone retired the listener before they arrived, leaving the
    // preferred track unselected and playback on the engine's default.
    if (primarySubtitleIsServerRendered) {
      if (!_secondaryPreferenceResolves(service, realSubtitleTracks)) return false;
      return !_awaitingAdvertisedAudio(tracks);
    }

    final hasAnyTracks = tracks.audio.isNotEmpty || tracks.subtitle.isNotEmpty;
    if (!hasAnyTracks) return false;

    final realAudioTracks = tracks.audio
        .where((track) => track.id != AudioTrack.auto.id && track.id != AudioTrack.off.id)
        .toList(growable: false);
    final selectedAudioTrack = service.selectAudioTrack(realAudioTracks, preferredAudioTrack)?.track;

    // Selection owns the catalog-completeness decision. A null subtitle result
    // is the only state in which a requested source track can still arrive.
    return service.selectSubtitleTrack(realSubtitleTracks, preferredSubtitleTrack, selectedAudioTrack) != null;
  }

  /// Whether the carried secondary subtitle, if there is one, has a native track to land on.
  /// Vacuously true when none is wanted, or when the backend has no secondary lane at all.
  bool _secondaryPreferenceResolves(TrackSelectionService service, List<SubtitleTrack> realSubtitleTracks) {
    final preference = preferredSecondarySubtitleTrack;
    if (preference == null || preference is SubtitleOffPreference) return true;
    if (!player.supportsSecondarySubtitles) return true;
    final match = switch (preference) {
      SubtitleOffPreference() => null,
      SubtitleTrackPreference(:final track) =>
        track.id == 'no' ? null : service.findBestSubtitleMatch(realSubtitleTracks, track),
      SubtitleIntentPreference(:final intent) => findNativeTrackForIntent(intent, realSubtitleTracks),
    };
    return match != null && match.id != 'no';
  }

  /// Whether the source advertises audio the native catalog has not published yet.
  ///
  /// Only asked on the burned-subtitle shortcut, which otherwise answers the
  /// subtitle question alone and would retire the track listener while audio was
  /// still arriving - leaving the preferred track unselected. A source that
  /// advertises none (a genuinely silent video) is never waited for.
  bool _awaitingAdvertisedAudio(Tracks tracks) {
    final sourceAdvertisesAudio = mediaInfo?.audioTracks.isNotEmpty ?? false;
    if (!sourceAdvertisesAudio) return false;
    return !tracks.audio.any((track) => track.id != AudioTrack.auto.id && track.id != AudioTrack.off.id);
  }

  /// Core track selection: delegates to [TrackSelectionService]. Returns
  /// whether every player mutation completed for this still-active owner.
  ///
  /// Pass `waitForPendingSource: false` from a deadline pass so an advertised
  /// subtitle that never materialized resolves to the best available choice
  /// instead of deferring forever.
  Future<bool> applyTrackSelection({bool waitForPendingSource = true}) async {
    final selectionGeneration = _selectionGeneration;
    bool selectionIsActive() => _isSelectionCurrent(selectionGeneration);
    if (!selectionIsActive()) return false;

    if (_isApplyingTrackSelection) {
      // A later track-list event can make a same-generation selection materially
      // different (notably when subtitles arrive while the five-second audio/rate
      // fallback is still applying). Queue one pass after the current mutation
      // chain rather than dropping that event.
      final activeSelectionDone = _selectionIdleCompleter?.future;
      if (activeSelectionDone == null) return false;
      await activeSelectionDone;
      if (!selectionIsActive()) return false;
      return applyTrackSelection(waitForPendingSource: waitForPendingSource);
    }

    _isApplyingTrackSelection = true;
    final idleCompleter = Completer<void>();
    _selectionIdleCompleter = idleCompleter;
    try {
      await waitForProfileSettings();
      if (!selectionIsActive()) return false;

      final profileSettings = getProfileSettings();
      // Keeps the settings singleton live before the synchronous scoped read.
      await SettingsService.getInstance();
      if (!selectionIsActive()) return false;

      final trackService = TrackSelectionService(
        player: player,
        profileSettings: profileSettings,
        metadata: metadata,
        plexMediaInfo: mediaInfo,
      );

      return await trackService.selectAndApplyTracks(
        preferredAudioTrack: preferredAudioTrack,
        preferredSubtitleTrack: preferredSubtitleTrack,
        preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
        defaultPlaybackSpeed: ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, metadata),
        onAudioTrackChanged: onAudioTrackChanged,
        onSubtitleTrackChanged: onSubtitleTrackChanged,
        isActive: selectionIsActive,
        onPlayerMutationDispatched: _trackDispatchedPlayerMutation,
        waitForPendingSource: waitForPendingSource,
        primarySubtitleIsServerRendered: primarySubtitleIsServerRendered,
      );
    } catch (e) {
      appLogger.w('Failed to apply track selection', error: e);
      return false;
    } finally {
      _isApplyingTrackSelection = false;
      if (identical(_selectionIdleCompleter, idleCompleter)) {
        _selectionIdleCompleter = null;
        idleCompleter.complete();
      }
    }
  }

  /// Called when playbackRestart fires — checks the flag and applies selection.
  void onPlaybackRestart() {
    if (waitingForExternalSubsTrackSelection) {
      if (_externalSubtitleAddsInFlight) return;
      waitingForExternalSubsTrackSelection = false;
      applyTrackSelection();
    }
  }

  // ── Backend fallback ───────────────────────────────────────────────

  /// Handle ExoPlayer → MPV backend switch: re-add external subs and reapply selection.
  Future<void> onBackendSwitched() async {
    final pendingSelection = _selectionIdleCompleter?.future;
    final playerMutationDrain = invalidatePendingSelection();
    if (pendingSelection != null) await pendingSelection;
    await playerMutationDrain;
    if (!_managerIsActive) return;

    appLogger.i('Player backend switched from ExoPlayer to MPV (native fallback)');
    if (_lastExternalSubtitles.isNotEmpty && !player.attachesExternalSubtitlesAtOpen) {
      try {
        await addExternalSubtitles(_lastExternalSubtitles);
      } catch (e) {
        appLogger.w('Failed to re-add external subtitles after backend switch', error: e);
      }
    }

    if (!_managerIsActive) return;

    applyTrackSelectionWhenReady();
  }

  // ── Track cycling (remote/keyboard shortcuts) ──────────────────────

  /// Cycle to the next subtitle track, save the preference, and return the
  /// track now playing so the caller can record it as the committed choice.
  /// Returns null when there was nothing to cycle.
  SubtitleTrack? cycleSubtitleTrack() {
    final tracks = player.state.tracks.subtitle.where((t) => t.id != 'auto').toList();
    if (tracks.isEmpty) return null;

    final current = player.state.track.subtitle;
    final currentIndex = tracks.indexWhere((t) => t.id == current?.id);
    final nextIndex = (currentIndex + 1) % tracks.length;
    final next = tracks[nextIndex];
    player.selectSubtitleTrack(next);
    unawaited(onSubtitleTrackSelectedByUser(next));

    if (isActive()) {
      final label = next.id == 'no'
          ? t.videoControls.osdSubtitlesOff
          : t.videoControls.osdSubtitles(
              track: TrackLabelBuilder.subtitleLabel(
                title: next.title,
                language: next.language,
                codec: next.codec,
                forced: next.isForced,
                index: nextIndex,
              ).joined,
            );
      showMessage?.call(label, duration: const Duration(seconds: 1));
    }
    return next;
  }

  /// Cycle to the next audio track and save the preference.
  void cycleAudioTrack() {
    final tracks = player.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').toList();
    if (tracks.length <= 1) return;

    final current = player.state.track.audio;
    final currentIndex = tracks.indexWhere((t) => t.id == current?.id);
    final nextIndex = (currentIndex + 1) % tracks.length;
    final next = tracks[nextIndex];
    player.selectAudioTrack(next);
    unawaited(onAudioTrackSelectedByUser(next));

    if (isActive()) {
      final label = t.videoControls.osdAudio(
        track: TrackLabelBuilder.audioLabel(
          title: next.title,
          language: next.language,
          codec: next.codec,
          channels: next.channelsCount,
          index: nextIndex,
        ).joined,
      );
      showMessage?.call(label, duration: const Duration(seconds: 1));
    }
  }

  // ── Explicit user selection ────────────────────────────────────────

  /// Records an explicit user audio choice.
  ///
  /// A source that advertises subtitles keeps an automatic selection pending
  /// for up to 30 seconds (see [applyTrackSelectionWhenReady]). That late pass
  /// re-runs [TrackSelectionService] against the preferences, so it would
  /// overwrite whatever the user picked in the meantime. Retiring the pending
  /// selection first makes the explicit choice win.
  ///
  /// The caller has already told the player which track to use, and this does
  /// not re-issue that command: the generation bump closes the whole window.
  /// `TrackSelectionService` re-checks the generation in the statement right
  /// before each `select*Track` call, so no later automatic mutation can be
  /// dispatched, and one already in flight was dispatched earlier and so lands
  /// before the user's.
  Future<void> onAudioTrackSelectedByUser(AudioTrack track) async {
    await invalidatePendingSelection();
    await onAudioTrackChanged(track);
  }

  /// Records an explicit user subtitle choice, retiring any pending automatic
  /// selection for the same reason as [onAudioTrackSelectedByUser].
  Future<void> onSubtitleTrackSelectedByUser(SubtitleTrack track, {int? sourceStreamId}) async {
    await invalidatePendingSelection();
    await onSubtitleTrackChanged(track, sourceStreamId: sourceStreamId);
  }

  // ── Server preference sync ─────────────────────────────────────────

  /// Handle audio track changes — save stream selection and language preference.
  Future<void> onAudioTrackChanged(AudioTrack track) async {
    final info = mediaInfo;
    final partId = await _guardTrackChange(info);
    if (partId == null || info == null) return;

    final matchedPlex = findPlexTrackForMpvAudio(track, info.audioTracks, allMpvTracks: player.state.tracks.audio);
    final streamID = matchedPlex?.id;
    if (streamID != null) {
      appLogger.d('Matched audio to streamID $streamID');
    } else {
      appLogger.e('Could not match audio track to any Plex track');
    }

    await _saveTrackPreferences(partId: partId, trackType: 'audio', streamID: streamID);
  }

  /// Handle subtitle track changes — save stream selection and language preference.
  Future<void> onSubtitleTrackChanged(SubtitleTrack track, {int? sourceStreamId}) async {
    final info = mediaInfo;
    final partId = await _guardTrackChange(info);
    if (partId == null) return;

    int? streamID;

    if (track.id == 'no') {
      streamID = 0;
      appLogger.i('User turned subtitles off, saving preference');
    } else if (sourceStreamId != null) {
      streamID = sourceStreamId;
      appLogger.d('Using authoritative subtitle streamID $streamID');
    } else if (info != null) {
      final matchedPlex = findPlexTrackForMpvSubtitle(
        track,
        info.subtitleTracks,
        allMpvTracks: player.state.tracks.subtitle,
      );
      streamID = matchedPlex?.id;
      if (streamID != null) {
        appLogger.d('Matched subtitle to streamID $streamID');
      } else {
        appLogger.e('Could not match subtitle track to any Plex track');
      }
    }

    await _saveTrackPreferences(partId: partId, trackType: 'subtitle', streamID: streamID);
  }

  /// Handle secondary subtitle track changes — no server save needed.
  void onSecondarySubtitleTrackChanged(SubtitleTrack track) {
    // Secondary subtitle preference is carried via player.state.track.secondarySubtitle
    // which is automatically read during episode navigation. No additional state needed.
  }

  // ── Private helpers ────────────────────────────────────────────────

  /// Common guard checks for track change handlers.
  Future<int?> _guardTrackChange(MediaSourceInfo? info) async {
    final settings = await SettingsService.getInstance();
    if (!settings.read(SettingsService.rememberTrackSelections)) return null;

    if (persistTrackPreference == null) return null;

    if (info == null) {
      appLogger.w('No media info available, cannot save stream selection');
      return null;
    }

    final partId = info.partId;
    if (partId == null) {
      appLogger.w('No part ID available, cannot save stream selection');
    }
    return partId;
  }

  /// Save the stream selection for the current part to the server.
  ///
  /// A null [streamID] means no server stream could be identified for the
  /// chosen track. There is no local fallback store, so the choice is simply
  /// lost — say so instead of reporting a save that never happened.
  Future<void> _saveTrackPreferences({required int partId, required String trackType, int? streamID}) async {
    if (streamID == null) {
      appLogger.w('Not saving $trackType stream selection: no server stream matched the selected track');
      return;
    }
    try {
      if (!isActive()) return;
      final persist = persistTrackPreference;
      if (persist == null) {
        return;
      }
      await persist(partId: partId, trackType: trackType, streamID: streamID);
      appLogger.d('Successfully saved $trackType stream selection');
    } catch (e) {
      appLogger.e('Failed to save $trackType stream selection', error: e);
    }
  }

  /// Clean up subscriptions.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    invalidatePendingSelection();
    _externalSubtitleAddsInFlight = false;
    _subtitleFallbackTimer?.cancel();
    _subtitleFallbackTimer = null;
  }
}
