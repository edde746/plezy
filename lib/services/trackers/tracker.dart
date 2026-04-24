import '../../models/trackers/tracker_context.dart';
import '../settings_service.dart';
import 'tracker_constants.dart';

/// Abstract tracker contract: the coordinator calls [markWatched] once per
/// playback when progress crosses the watched threshold. Enabled/auth gating
/// lives in [TrackerBase].
abstract class Tracker {
  String get name;

  /// Stable identifier used to persist per-service settings (library filter,
  /// scrobble enabled, etc.).
  TrackerService get service;

  bool get canScrobble;

  /// True if this tracker's IDs only come from the Fribb anime mapping
  /// (MAL, AniList). Simkl returns false because it accepts Plex tvdb/imdb/
  /// tmdb directly; when Simkl is the only active tracker we skip the 5.6 MB
  /// Fribb download entirely.
  bool get needsFribb;

  Future<void> initialize();
  Future<void> setEnabled(bool enabled);

  /// Whether an item in the given library should be scrobbled. Applies the
  /// per-tracker whitelist/blacklist — callers pass the Plex library
  /// `serverId:sectionId` globalKey (null when unknown, in which case the
  /// filter is bypassed so we err on the side of syncing).
  bool shouldScrobbleForLibrary(String? libraryGlobalKey);

  Future<void> markWatched(TrackerContext ctx);
}

/// Shared enabled-state bookkeeping. Subclasses override [hasActiveClient],
/// [readEnabledSetting], and [markWatched].
abstract class TrackerBase implements Tracker {
  bool _isInitialized = false;
  bool _isEnabled = false;

  bool get hasActiveClient;

  bool readEnabledSetting(SettingsService settings);

  @override
  bool get canScrobble => _isEnabled && hasActiveClient;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _isEnabled = readEnabledSetting(await SettingsService.getInstance());
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
  }

  @override
  bool shouldScrobbleForLibrary(String? libraryGlobalKey) =>
      SettingsService.instanceOrNull?.isLibraryAllowedForTracker(service, libraryGlobalKey) ?? true;
}
