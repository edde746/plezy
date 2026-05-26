import '../plex_client.dart';
import '../../media/media_item.dart';

/// Optional capability a [Tracker] can implement to resolve its synthetic stub
/// IDs to real Plex metadata and to manage the stub→Plex bridge map.
///
/// Implement this alongside [TrackerWatchStateProvider] when the tracker
/// produces "Continue Watching" stubs (e.g. Trakt). Scrobble-only trackers
/// (MAL, AniList, Simkl) do not implement this.
abstract class TrackerStubResolver {
  /// True when [stubId] was synthesized by this tracker.
  bool ownsStub(String stubId) => false;

  /// Resolve a stub episode to the real Plex episode [MediaItem].
  /// Returns [stub] unchanged when resolution fails.
  Future<MediaItem> resolveEpisodeStub(MediaItem stub, PlexClient client) async => stub;

  /// Resolve a stub movie to the real Plex movie [MediaItem].
  /// Returns null when the movie was not found in any Plex library.
  Future<MediaItem?> resolveMovieStub(MediaItem stub, PlexClient client) async => stub;

  /// Build a navigation-ready show [MediaItem] from a stub episode.
  /// Returns null when the show cannot be resolved.
  Future<MediaItem?> resolveStubShowForNavigation(MediaItem stub, PlexClient client) async => null;

  /// Build a navigation-ready movie [MediaItem] from a stub.
  /// Returns null when the movie cannot be resolved.
  Future<MediaItem?> resolveStubMovieForNavigation(MediaItem stub, PlexClient client) async => null;

  /// Enrich unresolved stubs by searching Plex servers and populating the bridge
  /// map. Safe to call fire-and-forget; concurrent callers wait for the in-progress
  /// run rather than starting a second one.
  Future<void> enrichStubs(String? preferredServerId, Map<String, PlexClient> clientMap) async {}

  /// Eagerly resolve episode display positions for Continue Watching cards so
  /// the correct S/E is shown before the user taps anything.
  Future<void> resolveEpisodeDisplayPositions(
      Map<String, PlexClient> clients, String? fallbackServerId) async {}
}
