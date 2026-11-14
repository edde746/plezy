part of '../../music_assistant_client.dart';

/// Everything the neutral interface requires that Music Assistant has no
/// concept of.
///
/// The rule applied throughout: a member throws [UnsupportedError] when calling
/// it means the caller believed a feature existed, and returns empty/null when
/// "nothing here" is a truthful answer the caller already handles. Nothing in
/// this file fabricates a plausible-looking result — a silent empty list where
/// the caller expected data reads as an empty library rather than as a missing
/// feature, and that is precisely the failure mode this backend was added to
/// fix.
mixin _MusicAssistantUnsupportedMethods on _MusicAssistantClientInternals {
  Never _noVideo(String feature) =>
      throw UnsupportedError('Music Assistant is a music-only backend and has no $feature');

  // --- Video hierarchy -------------------------------------------------------

  /// No series exist, so there is no client-side episode queue to build. Null is
  /// the interface's "this backend cannot supply one".
  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async => null;

  /// Trailers, featurettes and behind-the-scenes clips are video extras.
  @override
  Future<List<MediaItem>> fetchExtras(String id) async => const [];

  @override
  Future<LibraryPage<MediaItem>> fetchPersonMediaPage(
    String personId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => const LibraryPage(items: [], totalCount: 0);

  /// No recommendation engine and no similar-item endpoint.
  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];

  // Library features upstream added for video and Plex music. Music Assistant
  // is only a way to the speakers here, so none of them is reached.

  @override
  Future<List<LibraryGenre>> fetchLibraryGenres(String libraryId, {required MediaKind libraryKind}) async => const [];

  @override
  Future<void> scanLibrary(String libraryId) async =>
      throw UnsupportedError('Music Assistant libraries are scanned from its own settings');

  @override
  Future<List<ArtistDiscographyGroup>> fetchArtistDiscography(MediaItem artist) async => const [];

  @override
  Future<List<MediaPerson>> searchPeople(
    String query, {
    int limit = defaultPeopleSearchLimit,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async => const [];

  @override
  Future<MediaPersonDetails> fetchPersonDetails(String personId, {AbortController? abort}) async =>
      throw UnsupportedError('Music Assistant has no people');

  @override
  Future<List<CollectionMembership>> fetchCollectionMemberships(Set<String> itemIds, {AbortController? abort}) async =>
      const [];

  @override
  Future<MediaItem> stampLibrary(MediaItem item) async => item;

  @override
  Future<ExternalPlaybackTarget?> resolveExternalPlayback(
    MediaItem item, {
    int mediaIndex = 0,
    String? mediaSourceId,
    Duration? position,
  }) async => null;

  /// Gated by `ServerCapabilities.instantMix`, which is false here. Radio is a
  /// server-side queue mode on this backend, not a "give me tracks from this
  /// seed" call, so there is no track list to return.
  @override
  Future<List<MediaItem>> fetchInstantMix(
    String itemId, {
    int limit = 100,
    bool Function(List<MediaItem> more)? onMore,
  }) async =>
      throw UnsupportedError('Music Assistant has no instant-mix track list; radio is a server-side queue mode');

  /// The server does carry `metadata.lyrics` / `metadata.lrc_lyrics` per track,
  /// but neither is parsed into the wire model yet. Null is the interface's
  /// per-track "no lyrics", which is also what an unparsed field means today.
  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async => null;

  // --- Folder browsing -------------------------------------------------------

  /// `ServerCapabilities.folderGrouping` is false: the collection is indexed by
  /// artist/album/track and has no directory hierarchy to walk.
  @override
  Future<List<MediaItem>> fetchLibraryFolders(String libraryId, {void Function(List<MediaItem>)? onPage}) async =>
      _noVideo('folder hierarchy');

  @override
  Future<List<MediaItem>> fetchFolderChildren(
    MediaItem folder, {
    String? libraryId,
    String? libraryTitle,
    void Function(List<MediaItem>)? onPage,
  }) async => _noVideo('folder hierarchy');

  // --- Watch state and ratings ----------------------------------------------

  /// No played flag exists on the wire. Silently succeeding would leave the UI
  /// showing a watched tick that no server ever recorded.
  @override
  Future<void> markWatched(MediaItem item) async => _noVideo('watched state');

  @override
  Future<void> markUnwatched(MediaItem item) async => _noVideo('watched state');

  @override
  Future<void> removeFromContinueWatching(MediaItem item) async => _noVideo('Continue Watching list');

  /// `ServerCapabilities.numericUserRating` is false. Favourites
  /// (`setFavorite`) are the only per-item write this backend supports.
  @override
  Future<void> rate(MediaItem item, double rating) async => _noVideo('user ratings');

  // --- Playlist and collection writes ---------------------------------------

  /// Playlist writes exist in the Music Assistant API but have not been
  /// verified against a live server, and an unverified write is worse than a
  /// missing one — it can reorder or drop rows in a playlist the user cares
  /// about. Refused until exercised.
  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) async =>
      throw UnsupportedError('Music Assistant playlist writes are not implemented');

  @override
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items}) async =>
      throw UnsupportedError('Music Assistant playlist writes are not implemented');

  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) async =>
      throw UnsupportedError('Music Assistant playlist writes are not implemented');

  @override
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  }) async => throw UnsupportedError('Music Assistant playlist writes are not implemented');

  @override
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item}) async =>
      throw UnsupportedError('Music Assistant playlist writes are not implemented');

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionsPage(
    String libraryId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => const LibraryPage(items: [], totalCount: 0);

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) async => _noVideo('collections');

  @override
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  }) async => _noVideo('collections');

  @override
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items}) async =>
      _noVideo('collections');

  @override
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item}) async =>
      _noVideo('collections');

  @override
  Future<bool> deleteCollection(MediaItem collection) async => _noVideo('collections');

  /// Deleting media is a library-management operation Music Assistant delegates
  /// to whichever provider owns the file; this app has no safe path to it.
  @override
  Future<bool> deleteMediaItem(MediaItem item) async =>
      throw UnsupportedError('Music Assistant cannot delete media; the backing provider owns the files');

  /// `ServerCapabilities.richMetadataEdit` is false, and a library rescan is a
  /// provider-level operation that has not been verified.
  @override
  Future<void> refreshLibraryMetadata(String libraryId) async =>
      throw UnsupportedError('Music Assistant library rescan is not implemented');

  // --- Media details, downloads, playback extras -----------------------------

  /// Codec/bitrate live under `provider_mappings[].audio_format` on the wire but
  /// are not parsed, and [MediaFileInfo] is shaped around video files. Null is
  /// the interface's "nothing to show".
  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async => null;

  /// IMDb/TMDB/TVDB have no meaning for music. Music Assistant carries
  /// MusicBrainz ids instead, which [ExternalIds] cannot express.
  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => const ExternalIds();

  @override
  Future<List<MediaItem>> findByExternalIds(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async => const [];

  /// Chapters and intro/credits markers are video concepts.
  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async => PlaybackExtras(chapters: const [], markers: const []);

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async => null;

  /// The offline playback path has nothing to recover here: playback is a single
  /// server-side flow stream with no track list of its own.
  @override
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(
    String itemId, {
    int mediaIndex = 0,
    String? mediaSourceId,
    String? preferredVersionSignature,
  }) async => null;

  /// `ServerCapabilities.scrubThumbnails` is false — there is no video to scrub.
  @override
  Future<ScrubPreviewSource?> createScrubPreviewSource({
    required MediaItem item,
    required MediaSourceInfo mediaSource,
  }) async => null;

  /// Downloads would need a stable per-track file URL. Playback goes through a
  /// single continuous queue stream instead, which cannot be saved as a track.
  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async =>
      throw UnsupportedError('Music Assistant has no per-track file URL to download');

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) => const [];

  // --- Live TV ---------------------------------------------------------------

  /// Always the refusing adapter. The getter is non-nullable with no null
  /// object, so a wrapper has to exist even where the whole feature does not;
  /// [LiveTvSupport.isAvailable] answering `false` is the supported way for
  /// callers to find that out before touching anything else.
  @override
  LiveTvSupport get liveTv => const _MusicAssistantLiveTv();
}

/// Refusing [LiveTvSupport]. Every method beyond [isAvailable] throws, because
/// reaching one means a caller skipped the availability check.
class _MusicAssistantLiveTv implements LiveTvSupport {
  const _MusicAssistantLiveTv();

  Never _unsupported() => throw UnsupportedError('Music Assistant has no Live TV');

  @override
  LiveTvDvrSupport? get dvr => null;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) async => _unsupported();

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) async => _unsupported();

  @override
  Future<LiveTvPlaybackSession?> startPlayback(
    String channelKey, {
    String? dvrKey,
    TranscodeQualityPreset quality = TranscodeQualityPreset.original,
  }) async => _unsupported();

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async => _unsupported();

  @override
  String get favoriteStoreKey => _unsupported();

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => _unsupported();

  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels({bool migrate = true, void Function()? checkCurrent}) async =>
      _unsupported();

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels, {void Function()? checkCurrent}) async =>
      _unsupported();
}
