import 'dart:async';

import '../connection/connection.dart';
import '../exceptions/media_server_exceptions.dart';
import '../i18n/strings.g.dart';
import '../media/download_resolution.dart';
import '../models/transcode_quality_preset.dart';
import '../media/media_person.dart';
import '../media/library_genre.dart';
import '../media/artist_discography.dart';
import '../media/ids.dart';
import '../media/library_change_event.dart';
import '../media/library_filter_result.dart';
import '../media/library_first_character.dart';
import '../media/library_query.dart';
import '../media/live_tv_support.dart';
import '../media/lyrics.dart';
import '../media/media_backend.dart';
import '../media/media_file_info.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../media/media_sort.dart';
import '../media/media_source_info.dart';
import '../media/playback_report_metadata.dart';
import '../media/server_capabilities.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/media_server_http_client.dart' show AbortController;
import 'api_cache.dart';
import 'music_assistant/music_assistant_api.dart';
import 'music_assistant/music_assistant_library.dart';
import 'music_assistant/music_assistant_models.dart';
import 'music_assistant_api_cache.dart';
import 'music_assistant_mappers.dart';
import 'playback_initialization_types.dart';
import 'scrub_preview_source.dart';

part 'music_assistant_client/parts/browse.dart';
part 'music_assistant_client/parts/discovery.dart';
part 'music_assistant_client/parts/playback.dart';
part 'music_assistant_client/parts/playlists.dart';
part 'music_assistant_client/parts/unsupported.dart';

/// Id of the one synthetic library a Music Assistant server exposes.
///
/// The server has no library concept — it holds a single flat music collection
/// — but the whole app is organised around libraries, so exactly one is
/// synthesised. The literal value is arbitrary and only has to be stable:
/// library rows are addressed by `serverId:libraryId`.
const String musicAssistantLibraryId = 'music';

/// Canonical declarations of the [MusicAssistantClient] internals the `part`
/// mixins call into, mirroring `_JellyfinClientInternals`.
mixin _MusicAssistantClientInternals on MediaServerCacheMixin {
  MusicAssistantConnection get connection;
  MusicAssistantApi get api;
  MusicAssistantLibrary get music;
  MusicAssistantImageResolver get images;

  /// Runs [body], translating Music Assistant's socket failures into the
  /// transport exception the rest of the app already understands.
  Future<T> guard<T>(Future<T> Function() body);

  MediaItem? mapItem(MaItem item);
  List<MediaItem> mapItems(Iterable<MaItem> items);

  /// Resolves [id] (a Music Assistant uri) to the wire item, or `null` when the
  /// server says it does not exist.
  Future<MaItem?> rawItem(String id);
}

/// [MediaServerClient] over a Music Assistant server.
///
/// Music-only by nature: Music Assistant indexes artists, albums, tracks and
/// playlists and has no notion of video, live TV, collections, watch state or
/// metadata editing. Every member of the neutral interface covering those is
/// implemented as an explicit refusal rather than a plausible-looking empty
/// answer — see `parts/unsupported.dart` for the full list and the reasoning.
///
/// Three protocol facts shape most of what follows, all verified against a live
/// 2.6.3 server and written up in `docs/music_assistant_protocol.md`:
///
/// - A `library_items` request without an explicit `limit` is silently truncated
///   at 500 rows, so every list here pages explicitly with totals from
///   `music/<type>/count`.
/// - The server orders by `sort_name`, which disagrees with `name` for about one
///   item in nine. Pages are never re-sorted client-side.
/// - `order_by` is not validated: a wrong value returns 200 with the default
///   ordering. Only [MaOrder]'s verified vocabulary is sent.
class MusicAssistantClient
    with
        MediaServerCacheMixin,
        _MusicAssistantClientInternals,
        _MusicAssistantBrowseMethods,
        _MusicAssistantDiscoveryMethods,
        _MusicAssistantPlaylistMethods,
        _MusicAssistantPlaybackMethods,
        _MusicAssistantUnsupportedMethods
    implements MediaServerClient, GracefullyCloseable {
  MusicAssistantClient({required MusicAssistantConnection connection, MusicAssistantApi? api})
    : this._(connection, api ?? MusicAssistantApi());

  MusicAssistantClient._(this._connection, this.api) : music = MusicAssistantLibrary(api);

  /// Build a client and open its socket.
  ///
  /// Unlike the HTTP backends this cannot stay lazy: every command rides one
  /// WebSocket, so nothing works until the handshake completes. A failed
  /// connect still arms [MusicAssistantApi]'s background retry, so the caller
  /// gets a usable client that reconnects rather than a dead one.
  static Future<MusicAssistantClient> create(MusicAssistantConnection connection, {MusicAssistantApi? api}) async {
    // Before anything can be logged about this server, exactly as
    // [PlexClient] and [JellyfinClient] do. Logging is not compiled out in
    // release — `ProductionFilter` passes `Level.info` into a 5 MB ring buffer
    // the user can upload — so an unregistered host is a host that ships. The
    // generic IPv4 pattern masks `10.0.2.107` on its own, but a hostname
    // (`music.home.lan`, a `*.ts.net` name) is emitted verbatim until it is
    // registered here.
    LogRedactionManager.registerServer(connection.baseUrl, connection.accessToken);
    final client = MusicAssistantClient(connection: connection, api: api);
    try {
      final info = await client.api.connect(Uri.parse(connection.baseUrl), accessToken: connection.accessToken);
      client._connection = connection.copyWith(serverId: info.serverId, serverVersion: info.serverVersion);
    } on MaException catch (e) {
      appLogger.w('MusicAssistantClient.create could not reach the server', error: e);
    }
    return client;
  }

  MusicAssistantConnection _connection;

  @override
  final MusicAssistantApi api;

  @override
  final MusicAssistantLibrary music;

  bool _offlineMode = false;

  @override
  MusicAssistantConnection get connection => _connection;

  /// The greeting's `server_id` is the stable identity across URL changes, but
  /// it only arrives after a successful handshake — before that the connection
  /// row's own id is the only thing available, and it must not be empty because
  /// [ServerId] rejects blanks and every cache key is built from it.
  ///
  /// **In-memory use only.** The fallback branch answers a placeholder that
  /// stops being true the moment the transport's own retry succeeds, silently
  /// and with no signal to anyone holding it. Anything writing an id somewhere
  /// durable — a connection row, a pairing, a database key — must take
  /// [settledServerId] and handle its null instead.
  @override
  ServerId get serverId => ServerId(api.serverInfo?.serverId ?? connection.serverId ?? connection.id);

  /// Whether a greeting has landed, so [serverId] has stopped falling back and
  /// will not change out from under whoever registered this client.
  ///
  /// Registries key on [serverId]. Before the handshake it answers a
  /// placeholder, and the flip to the real `server_id` happens whenever the
  /// transport's own retry eventually succeeds — asynchronously, with no signal
  /// to anyone holding the old key.
  bool get hasSettledIdentity => api.serverInfo != null;

  /// The server's own id, or null while it has never answered.
  ///
  /// The accessor for every durable write. It exists so that "is this id real
  /// yet?" cannot be forgotten: [serverId] always answers something, and the
  /// something it answers before the first greeting is the *connection row's*
  /// id, which no server will ever announce. A row keyed on that names a
  /// server that will never be found again, and the mistake is invisible
  /// because a placeholder id looks exactly like a real one.
  ///
  /// Note for the pairing flow (`music_pairing_store` / `music_pairing_screen`,
  /// owned elsewhere): a pairing is durable, so it must be written from this
  /// and refused while it is null, not from [serverId].
  ServerId? get settledServerId {
    final id = api.serverInfo?.serverId ?? connection.serverId;
    // Both sources are written *by* a greeting, so a non-empty value from
    // either is the server's own. `connection.serverId` matters after a
    // restart: it was persisted from a previous handshake and is durable even
    // before this process has completed one.
    return id == null || id.isEmpty ? null : ServerId(id);
  }

  /// Never the raw connection display name.
  ///
  /// This string is the title of the synthesised library, the `libraryTitle` on
  /// every mapped item and the `serverName` on every hub — i.e. it is what the
  /// user sees as the name of their music. A bare host or `host:port` is not a
  /// name, so [MusicAssistantMappers.serverDisplayName] substitutes the product
  /// name for connections whose display name is really an address.
  ///
  /// Declared `String?` only because the neutral interface is; it never answers
  /// null. Callers inside this client should still not add a `?? …` fallback —
  /// there is nothing better to fall back *to*, and the raw connection name is
  /// exactly what this exists to keep off the screen.
  @override
  String? get serverName => MusicAssistantMappers.serverDisplayName(connection.displayName);

  @override
  MediaBackend get backend => MediaBackend.musicAssistant;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.musicAssistant;

  @override
  ApiCache get cache => MusicAssistantApiCache.instance;

  @override
  MusicAssistantImageResolver get images => MusicAssistantImageResolver(api.httpBaseUrl);

  @override
  bool get isOfflineMode => _offlineMode;

  @override
  void setOfflineMode(bool offline) {
    _offlineMode = offline;
  }

  /// One per client: a connection's token never changes under a live client,
  /// since a new token means a new connection and so a new client.
  @override
  final Object authenticationSessionId = Object();

  /// Music Assistant pushes library changes over its socket, but nothing here
  /// browses its library any more, so there is nothing to refresh.
  @override
  LibraryEventChannel? createLibraryEventChannel() => null;

  /// Synchronous teardown, as [MediaServerClient] declares it.
  ///
  /// It can only *start* the ordering [closeGracefully] guarantees, which is
  /// why this class implements [GracefullyCloseable] and why callers with a
  /// future to await must prefer that. Before it did, [MultiServerManager]
  /// took its non-graceful branch and this `unawaited` was the whole teardown
  /// — reintroducing the exact race the comment below exists to prevent.
  @override
  void close() {
    unawaited(closeGracefully());
  }

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) => api.dispose();

  /// Health is the socket's own state, not a probe.
  ///
  /// The transport is a single long-lived WebSocket that reconnects on its own,
  /// so "is it connected" is already known continuously; a round-trip would only
  /// re-measure it. A count command is still sent when the socket reports
  /// connected, because a half-open socket looks connected until something is
  /// asked of it.
  ///
  /// A server that wants a sign-in still greets and still holds the socket
  /// open, so this probe is the first thing that can tell: the count is refused
  /// with an auth code, which is [HealthStatus.authError]. Any other failure is
  /// an outage, and must not be misrouted to "Sign in again".
  ///
  /// How long "is this server alive?" may take to answer.
  ///
  /// Deliberately far below the request timeout. A wedged Music Assistant
  /// keeps its socket open and its greeting already happened, so nothing about
  /// the connection says anything is wrong — the only symptom is that commands
  /// stop coming back. Inheriting the 30s request budget meant every surface
  /// that asks about health waited half a minute to be told what a single
  /// unanswered probe already implied, and the app looked hung rather than
  /// degraded.
  static const Duration healthProbeTimeout = Duration(seconds: 5);

  @override
  Future<HealthStatus> checkHealth() async {
    if (!api.isConnected) return HealthStatus.offline;
    try {
      await music.getCount(MaLibraryType.artists).timeout(healthProbeTimeout);
      return HealthStatus.online;
    } on TimeoutException {
      return HealthStatus.offline;
    } on MaRequestException catch (e) {
      return e.isAuthFailure ? HealthStatus.authError : HealthStatus.offline;
    } on MaException {
      return HealthStatus.offline;
    }
  }

  Future<bool> isHealthy() async => (await checkHealth()) == HealthStatus.online;

  @override
  Future<String?> getMachineIdentifier() async => api.serverInfo?.serverId ?? connection.serverId;

  /// Music Assistant does not serve media over HTTP with per-request auth: the
  /// image proxy and the builtin-player flow stream are both open on the LAN,
  /// and a configured token would ride the WebSocket handshake rather than these
  /// URLs. Returning headers the server ignores would be misleading.
  @override
  Map<String, String> get streamHeaders => const {};

  /// Artwork URLs are produced already-absolute by the mapper (they need the
  /// item's image `provider`, which is not recoverable from the path alone), so
  /// this only has to narrow the `size` the proxy re-encodes to.
  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    if (path == null || path.isEmpty) return '';
    final requested = [?width, ?height];
    if (requested.isEmpty) return path;
    return MusicAssistantImageResolver.resized(path, requested.reduce((a, b) => a > b ? a : b));
  }

  /// Returned unchanged: `/imageproxy` keys on an image's `provider` as well as
  /// its path, and an arbitrary external URL has no provider to give it.
  @override
  String externalImageUrl(String url, {int? width, int? height, bool cover = true}) => url;

  /// The neutral `MediaItem` is turned back into the wire handle here; the
  /// command itself lives in [MusicAssistantLibrary.setFavorite] with the rest
  /// of the `music/*` vocabulary.
  @override
  Future<void> setFavorite(MediaItem item, bool isFavorite) async =>
      guard(() => music.setFavorite(item.guid ?? item.id, favorite: isFavorite));

  @override
  Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on MaException catch (e) {
      throw _asTransportException(e);
    }
  }

  /// Music Assistant's error codes, mapped onto the transport exception the
  /// cache mixin, abort handling and pagination retry already branch on.
  ///
  /// `error_code: 2` is "not found", which the neutral interface expresses as
  /// HTTP 404 — [fetchItem]'s contract turns exactly that into `null`.
  static MediaServerHttpException _asTransportException(MaException error) {
    return switch (error) {
      MaTimeoutException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.receiveTimeout,
        message: message,
      ),
      // Before the general connection branch: a disposed client is our own
      // teardown, not the server failing, and must not be reported as one.
      MaDisposedException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.cancelled,
        message: message,
      ),
      MaConnectionException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: message,
      ),
      MaRequestException(:final message, :final errorCode) => MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        message: message,
        statusCode: errorCode == _notFoundErrorCode ? 404 : null,
      ),
      // A shape fault is deliberately *not* mapped to 404: 404 is the one code
      // [fetchItem] turns into a silent null, which is exactly the "looks like
      // nothing is there" outcome [MaProtocolException] exists to prevent.
      MaProtocolException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        message: message,
      ),
    };
  }

  static const int _notFoundErrorCode = 2;

  @override
  MediaItem? mapItem(MaItem item) => MusicAssistantMappers.mediaItem(
    item,
    serverId: serverId,
    serverName: serverName,
    images: images,
    libraryId: musicAssistantLibraryId,
    libraryTitle: serverName,
  );

  @override
  List<MediaItem> mapItems(Iterable<MaItem> items) => MusicAssistantMappers.mediaItems(
    items,
    serverId: serverId,
    serverName: serverName,
    images: images,
    libraryId: musicAssistantLibraryId,
    libraryTitle: serverName,
  );
}
