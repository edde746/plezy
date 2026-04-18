import 'dart:async';

import '../mpv/mpv.dart';

import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../services/settings_service.dart';
import '../services/track_selection_service.dart';
import '../models/plex_user_profile.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/language_codes.dart';
import '../utils/track_label_builder.dart';

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

  /// Resolves the Plex API client for the current server.
  final PlexClient Function() getClient;

  /// Resolves the user's profile settings (may be null during loading).
  final PlexUserProfile? Function() getProfileSettings;

  /// Waits until profile settings are available (offline path).
  final Future<void> Function() waitForProfileSettings;

  /// Shows a transient message to the user (e.g., snackbar).
  final void Function(String message, {Duration? duration})? showMessage;

  // ── Mutable configuration (updated on episode navigation) ──────────

  PlexMetadata metadata;
  PlexMediaInfo? mediaInfo;
  AudioTrack? preferredAudioTrack;
  SubtitleTrack? preferredSubtitleTrack;
  SubtitleTrack? preferredSecondarySubtitleTrack;

  // ── Internal state ─────────────────────────────────────────────────

  bool waitingForExternalSubsTrackSelection = false;
  bool _isApplyingTrackSelection = false;
  List<SubtitleTrack> _lastExternalSubtitles = const [];
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  Timer? _subtitleFallbackTimer;

  /// Cached external subtitles for re-use after backend fallback.
  List<SubtitleTrack> get lastExternalSubtitles => _lastExternalSubtitles;

  TrackManager({
    required this.player,
    required this.isActive,
    required this.getClient,
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

  /// Add external subtitle tracks to the player one by one.
  Future<void> addExternalSubtitles(List<SubtitleTrack> externalSubtitles) async {
    if (externalSubtitles.isEmpty) return;

    appLogger.d('Adding ${externalSubtitles.length} external subtitle(s) to player');

    for (final subtitleTrack in externalSubtitles) {
      if (subtitleTrack.uri == null) continue;

      try {
        await player.addSubtitleTrack(
          uri: subtitleTrack.uri!,
          title: subtitleTrack.title,
          language: subtitleTrack.language,
          select: false,
        );
        appLogger.d('Added external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}');
      } catch (e) {
        appLogger.w('Failed to add external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}', error: e);
      }
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
      applyTrackSelection();
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
    if (currentTracks.audio.isNotEmpty || currentTracks.subtitle.isNotEmpty) {
      applyTrackSelection();
    } else {
      _trackLoadingSubscription?.cancel();
      _trackLoadingSubscription = player.streams.tracks.listen((tracks) {
        if (tracks.audio.isEmpty && tracks.subtitle.isEmpty) return;

        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
        applyTrackSelection();
      });
    }
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
        defaultPlaybackSpeed: settingsService.getDefaultPlaybackSpeed(),
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
      waitingForExternalSubsTrackSelection = false;
      applyTrackSelection();
    }
  }

  // ── Backend fallback ───────────────────────────────────────────────

  /// Handle ExoPlayer → MPV backend switch: re-add external subs and reapply selection.
  Future<void> onBackendSwitched() async {
    appLogger.i('Player backend switched from ExoPlayer to MPV (native fallback)');

    if (_lastExternalSubtitles.isNotEmpty) {
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
          : 'Subtitles: ${TrackLabelBuilder.buildSubtitleLabel(title: next.title, language: next.language, codec: next.codec, index: nextIndex)}';
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
          'Audio: ${TrackLabelBuilder.buildAudioLabel(title: next.title, language: next.language, codec: next.codec, channelsCount: next.channelsCount, index: nextIndex)}';
      showMessage?.call(label, duration: const Duration(seconds: 1));
    }
  }

  // ── Server preference sync ─────────────────────────────────────────

  /// Handle audio track changes — save stream selection and language preference.
  Future<void> onAudioTrackChanged(AudioTrack track) async {
    final info = mediaInfo;
    final partId = await _guardTrackChange(info);
    if (partId == null || info == null) return;

    int? streamID = _matchTrackByAttributes(
      mpvLanguage: track.language,
      mpvTitle: track.title,
      plexTracks: info.audioTracks,
      getLanguageCode: (t) => t.languageCode,
      getDisplayTitle: (t) => t.displayTitle,
      getTitle: (t) => t.title,
      getId: (t) => t.id,
    );

    if (streamID != null) {
      appLogger.d('Matched audio by lang/title: streamID $streamID');
    } else {
      final matchedPlex = findPlexTrackForMpvAudio(track, info.audioTracks, allMpvTracks: player.state.tracks.audio);
      streamID = matchedPlex?.id;
      if (streamID != null) {
        appLogger.d('Matched audio by properties: streamID $streamID');
      } else {
        appLogger.e('Could not match audio track to any Plex track');
      }
    }

    await _saveTrackPreferences(partId: partId, trackType: 'audio', languageCode: track.language, streamID: streamID);
  }

  /// Handle subtitle track changes — save stream selection and language preference.
  Future<void> onSubtitleTrackChanged(SubtitleTrack track) async {
    final info = mediaInfo;
    final partId = await _guardTrackChange(info);
    if (partId == null) return;

    String? languageCode;
    int? streamID;

    if (track.id == 'no') {
      languageCode = 'none';
      streamID = 0;
      appLogger.i('User turned subtitles off, saving preference');
    } else if (info != null) {
      languageCode = track.language;

      streamID = _matchTrackByAttributes(
        mpvLanguage: track.language,
        mpvTitle: track.title,
        plexTracks: info.subtitleTracks,
        getLanguageCode: (t) => t.languageCode,
        getDisplayTitle: (t) => t.displayTitle,
        getTitle: (t) => t.title,
        getId: (t) => t.id,
      );

      if (streamID != null) {
        appLogger.d('Matched subtitle by lang/title: streamID $streamID');
      } else {
        final matchedPlex = findPlexTrackForMpvSubtitle(
          track,
          info.subtitleTracks,
          allMpvTracks: player.state.tracks.subtitle,
        );
        streamID = matchedPlex?.id;
        if (streamID != null) {
          appLogger.d('Matched subtitle by properties: streamID $streamID');
        } else {
          appLogger.e('Could not match subtitle track to any Plex track');
        }
      }
    }

    await _saveTrackPreferences(partId: partId, trackType: 'subtitle', languageCode: languageCode, streamID: streamID);
  }

  /// Handle secondary subtitle track changes — no server save needed.
  void onSecondarySubtitleTrackChanged(SubtitleTrack track) {
    // Secondary subtitle preference is carried via player.state.track.secondarySubtitle
    // which is automatically read during episode navigation. No additional state needed.
  }

  // ── Private helpers ────────────────────────────────────────────────

  /// Rating key used for series/movie level language preferences.
  String get _preferenceRatingKey {
    return metadata.isEpisode ? (metadata.grandparentRatingKey ?? metadata.ratingKey) : metadata.ratingKey;
  }

  /// Common guard checks for track change handlers.
  Future<int?> _guardTrackChange(PlexMediaInfo? info) async {
    final settings = await SettingsService.getInstance();
    if (!settings.getRememberTrackSelections()) return null;

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

  /// Save language preference and stream selection to the server.
  Future<void> _saveTrackPreferences({
    required int partId,
    required String trackType,
    String? languageCode,
    int? streamID,
  }) async {
    try {
      if (!isActive()) return;
      final client = getClient();
      final ratingKey = _preferenceRatingKey;

      final futures = <Future>[];

      if (languageCode != null && (trackType == 'subtitle' || languageCode.isNotEmpty)) {
        futures.add(
          trackType == 'audio'
              ? client.setMetadataPreferences(ratingKey, audioLanguage: languageCode)
              : client.setMetadataPreferences(ratingKey, subtitleLanguage: languageCode),
        );
      }
      if (streamID != null) {
        futures.add(
          trackType == 'audio'
              ? client.selectStreams(partId, audioStreamID: streamID, allParts: true)
              : client.selectStreams(partId, subtitleStreamID: streamID, allParts: true),
        );
      }

      await Future.wait(futures);
      appLogger.d('Successfully saved $trackType preferences (language + stream)');
    } catch (e) {
      appLogger.e('Failed to save $trackType preferences', error: e);
    }
  }

  /// Match an mpv track against Plex tracks by language and title.
  int? _matchTrackByAttributes<T>({
    required String? mpvLanguage,
    required String? mpvTitle,
    required List<T> plexTracks,
    required String? Function(T) getLanguageCode,
    required String? Function(T) getDisplayTitle,
    required String? Function(T) getTitle,
    required int Function(T) getId,
  }) {
    final normalizedLang = _iso6391ToPlex6392(mpvLanguage);

    for (final plexTrack in plexTracks) {
      final matchLang = getLanguageCode(plexTrack) == normalizedLang;
      final matchTitle = (mpvTitle == null || mpvTitle.isEmpty)
          ? true
          : (getDisplayTitle(plexTrack) == mpvTitle || getTitle(plexTrack) == mpvTitle);

      if (matchLang && matchTitle) {
        return getId(plexTrack);
      }
    }
    return null;
  }

  /// Convert ISO 639-1 code (e.g. "fr") to Plex's 639-2 code (e.g. "fre").
  static String? _iso6391ToPlex6392(String? code) {
    if (code == null || code.isEmpty) return null;
    final lang = code.split('-').first.toLowerCase();

    try {
      final variations = LanguageCodes.getVariations(lang);
      for (final variation in variations) {
        if (variation.length == 3) {
          return variation;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clean up subscriptions.
  void dispose() {
    _trackLoadingSubscription?.cancel();
    _trackLoadingSubscription = null;
    _subtitleFallbackTimer?.cancel();
    _subtitleFallbackTimer = null;
  }
}
