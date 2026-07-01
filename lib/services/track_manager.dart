import 'dart:async';

import '../mpv/mpv.dart';

import '../media/media_item.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_source_info.dart';
import '../services/settings_service.dart';
import '../services/track_selection_service.dart';
import '../utils/app_logger.dart';
import '../utils/track_label_builder.dart';

/// Persists a track choice for the current part to the server.
/// Backends that persist through another path (Jellyfin uses playback progress
/// stream indexes) or lack server-side stream selection leave this null.
/// [trackType] is `'audio'` or `'subtitle'`.
typedef TrackPreferencePersister =
    Future<void> Function({required int partId, required String trackType, int? streamID});

/// Manages track (audio + subtitle) lifecycle: external subtitle loading,
/// automatic track selection, server preference sync, and cycling.
///
/// Follows the same manager pattern as [VideoFilterManager]:
/// constructed with a [Player] + callbacks, mutated via public setters,
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
  SubtitleTrack? preferredSubtitleTrack;
  SubtitleTrack? preferredSecondarySubtitleTrack;

  // ── Internal state ─────────────────────────────────────────────────

  bool waitingForExternalSubsTrackSelection = false;
  bool _externalSubtitleAddsInFlight = false;
  bool _isApplyingTrackSelection = false;
  List<SubtitleTrack> _lastExternalSubtitles = const [];
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  Timer? _subtitleFallbackTimer;
  Timer? _trackSelectionFallbackTimer;

  /// Cached external subtitles for re-use after backend fallback.
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

  // ── Track selection ────────────────────────────────────────────────

  /// Apply track selection once tracks are available.
  /// If tracks are not yet loaded, subscribes to the stream.
  void applyTrackSelectionWhenReady() {
    final currentTracks = player.state.tracks;
    if (_tracksReadyForSelection(currentTracks)) {
      applyTrackSelection();
    } else {
      _trackLoadingSubscription?.cancel();
      _trackLoadingSubscription = player.streams.tracks.listen((tracks) {
        if (!_tracksReadyForSelection(tracks)) return;

        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
        _trackSelectionFallbackTimer?.cancel();
        _trackSelectionFallbackTimer = null;
        applyTrackSelection();
      });

      _trackSelectionFallbackTimer?.cancel();
      _trackSelectionFallbackTimer = Timer(const Duration(seconds: 5), () {
        if (!isActive()) return;
        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
        applyTrackSelection();
      });
    }
  }

  bool _tracksReadyForSelection(Tracks tracks) {
    final hasAnyTracks = tracks.audio.isNotEmpty || tracks.subtitle.isNotEmpty;
    if (!hasAnyTracks) return false;

    final info = mediaInfo;
    if (info == null || tracks.subtitle.isNotEmpty) return true;

    // Plex can legitimately report subtitles without selecting one. During an
    // in-place item reload Android clears the old track list before the new
    // demuxed subtitles arrive; applying selection at the first audio-only
    // update would treat that temporary empty subtitle list as an explicit
    // server "off" decision and leave the next episode without selectable subs.
    return info.subtitleTracks.isEmpty;
  }

  /// Core track selection: delegates to [TrackSelectionService].
  Future<void> applyTrackSelection() async {
    if (!isActive() || _isApplyingTrackSelection) return;

    _isApplyingTrackSelection = true;
    try {
      await waitForProfileSettings();
      if (!isActive()) return;

      final profileSettings = getProfileSettings();
      final settingsService = await SettingsService.getInstance();
      if (!isActive()) return;

      final trackService = TrackSelectionService(
        player: player,
        profileSettings: profileSettings,
        metadata: metadata,
        plexMediaInfo: mediaInfo,
      );

      await trackService.selectAndApplyTracks(
        preferredAudioTrack: preferredAudioTrack,
        preferredSubtitleTrack: preferredSubtitleTrack,
        preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
        defaultPlaybackSpeed: settingsService.read(SettingsService.defaultPlaybackSpeed),
        onAudioTrackChanged: onAudioTrackChanged,
        onSubtitleTrackChanged: onSubtitleTrackChanged,
      );
    } catch (e) {
      appLogger.w('Failed to apply track selection', error: e);
    } finally {
      _isApplyingTrackSelection = false;
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
    appLogger.i('Player backend switched from ExoPlayer to MPV (native fallback)');

    if (_lastExternalSubtitles.isNotEmpty && !player.attachesExternalSubtitlesAtOpen) {
      try {
        await addExternalSubtitles(_lastExternalSubtitles);
      } catch (e) {
        appLogger.w('Failed to re-add external subtitles after backend switch', error: e);
      }
    }

    if (!isActive()) return;

    applyTrackSelectionWhenReady();
  }

  // ── Track cycling (remote/keyboard shortcuts) ──────────────────────

  /// Cycle to the next subtitle track and save the preference.
  void cycleSubtitleTrack() {
    final tracks = player.state.tracks.subtitle.where((t) => t.id != 'auto').toList();
    if (tracks.isEmpty) return;

    final current = player.state.track.subtitle;
    final currentIndex = tracks.indexWhere((t) => t.id == current?.id);
    final nextIndex = (currentIndex + 1) % tracks.length;
    final next = tracks[nextIndex];
    player.selectSubtitleTrack(next);
    onSubtitleTrackChanged(next);

    if (isActive()) {
      final label = next.id == 'no'
          ? 'Subtitles: Off'
          : 'Subtitles: ${TrackLabelBuilder.subtitleLabel(title: next.title, language: next.language, codec: next.codec, forced: next.isForced, index: nextIndex).joined}';
      showMessage?.call(label, duration: const Duration(seconds: 1));
    }
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
    onAudioTrackChanged(next);

    if (isActive()) {
      final label =
          'Audio: ${TrackLabelBuilder.audioLabel(title: next.title, language: next.language, codec: next.codec, channels: next.channelsCount, index: nextIndex).joined}';
      showMessage?.call(label, duration: const Duration(seconds: 1));
    }
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
  Future<void> onSubtitleTrackChanged(SubtitleTrack track) async {
    final info = mediaInfo;
    final partId = await _guardTrackChange(info);
    if (partId == null) return;

    int? streamID;

    if (track.id == 'no') {
      streamID = 0;
      appLogger.i('User turned subtitles off, saving preference');
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

    final partId = info.getPartId();
    if (partId == null) {
      appLogger.w('No part ID available, cannot save stream selection');
    }
    return partId;
  }

  /// Save the stream selection for the current part to the server.
  Future<void> _saveTrackPreferences({required int partId, required String trackType, int? streamID}) async {
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
    _externalSubtitleAddsInFlight = false;
    _trackLoadingSubscription?.cancel();
    _trackLoadingSubscription = null;
    _subtitleFallbackTimer?.cancel();
    _subtitleFallbackTimer = null;
    _trackSelectionFallbackTimer?.cancel();
    _trackSelectionFallbackTimer = null;
  }
}
