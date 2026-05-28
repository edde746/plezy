import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../media/media_item.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart';
import '../utils/media_server_timeouts.dart';
import 'plex_mappers.dart';

/// Account-level service for the Plex Watchlist.
///
/// The Watchlist is stored on Plex's cloud "discover" provider keyed to a
/// plex.tv **account** token — not on any Plex Media Server. This service is
/// therefore standalone (not a [PlexClient] part, which is bound to one server
/// + a server token). It reuses [MediaServerHttpClient] for transport and
/// [PlexMappers] for metadata → [MediaItem] conversion.
///
/// Read-only: fetches the list only. Image paths returned by the discover
/// provider are server-relative to `metadata.provider.plex.tv`, so this
/// service rewrites them into absolute, token-authenticated URLs that render
/// without a server client (see [_absolutizeImage]).
class PlexWatchlistService {
  static const String _discoverBase = 'https://discover.provider.plex.tv';
  static const String _metadataHost = 'https://metadata.provider.plex.tv';
  static const String _appName = 'Plezy';

  final MediaServerHttpClient _http;
  final String _accountToken;
  final String _clientIdentifier;

  PlexWatchlistService({required String accountToken, required String clientIdentifier})
    : _accountToken = accountToken,
      _clientIdentifier = clientIdentifier,
      _http = MediaServerHttpClient(
        baseUrl: _discoverBase,
        connectTimeout: MediaServerTimeouts.plexTvConnect,
        receiveTimeout: MediaServerTimeouts.plexTvReceive,
      );

  /// Build a service for the active Plex account, or null if no Plex account
  /// is connected. Centralizes the account-token lookup so callers (detail
  /// screen, context menu, watchlist screen) don't each duplicate it.
  static Future<PlexWatchlistService?> forActiveAccount(ConnectionRegistry registry) async {
    final accounts = await registry.listPlexAccounts();
    PlexAccountConnection? account;
    for (final a in accounts) {
      if (a.accountToken.isNotEmpty) {
        account = a;
        break;
      }
    }
    if (account == null) return null;
    return PlexWatchlistService(accountToken: account.accountToken, clientIdentifier: account.clientIdentifier);
  }

  /// Extract the cloud ratingKey from a Plex `guid` (`plex://movie/<id>` →
  /// `<id>`). Returns null for non-plex or malformed guids. Watchlist add/remove
  /// endpoints key off this cloud ratingKey, which is also a watchlist item's
  /// own `id`.
  static String? cloudRatingKeyFromGuid(String? guid) {
    if (guid == null || !guid.startsWith('plex://')) return null;
    final id = guid.split('/').last.trim();
    return id.isEmpty ? null : id;
  }

  /// Close the underlying HTTP client. Call when the service is no longer
  /// needed (e.g. screen disposed) to avoid leaking sockets.
  void dispose() => _http.close();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'X-Plex-Product': _appName,
    'X-Plex-Client-Identifier': _clientIdentifier,
    'X-Plex-Token': _accountToken,
  };

  /// Fetch the account watchlist as neutral [MediaItem]s.
  ///
  /// [start]/[size] map to Plex's container paging headers. Returns items in
  /// the order the provider returns them (default: recently added first).
  Future<List<MediaItem>> getWatchlist({int start = 0, int size = 100}) async {
    final response = await _http.get(
      '/library/sections/watchlist/all',
      queryParameters: {
        'X-Plex-Container-Start': '$start',
        'X-Plex-Container-Size': '$size',
        // Ask the provider to include the fields the grid needs.
        'includeFields': 'title,type,thumb,art,year,guid,ratingKey',
        'includeUserState': '1',
      },
      headers: _headers,
      timeout: MediaServerTimeouts.plexTvReceive,
    );

    throwIfHttpError(response);

    final data = response.data;
    final container = data is Map ? data['MediaContainer'] : null;
    final rawItems = container is Map ? container['Metadata'] : null;
    if (rawItems is! List) return const [];

    final items = <MediaItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      try {
        final json = Map<String, dynamic>.from(raw);
        final dto = PlexMetadataDto.fromJsonWithImages(json);
        final mapped = PlexMappers.mediaItem(dto);
        // Rewrite cloud-relative image paths into absolute token-authenticated
        // URLs so they render with `client: null` on the watchlist screen.
        items.add(
          mapped.copyWith(thumbPath: _absolutizeImage(mapped.thumbPath), artPath: _absolutizeImage(mapped.artPath)),
        );
      } catch (e) {
        appLogger.w('PlexWatchlistService: skipped unparseable watchlist item', error: e);
      }
    }
    return items;
  }

  /// Add an item to the account watchlist by its cloud [ratingKey].
  Future<void> addToWatchlist(String ratingKey) async {
    final response = await _http.put(
      '/actions/addToWatchlist',
      queryParameters: {'ratingKey': ratingKey},
      headers: _headers,
      timeout: MediaServerTimeouts.plexTvReceive,
    );
    throwIfHttpError(response);
  }

  /// Remove an item from the account watchlist by its cloud [ratingKey].
  Future<void> removeFromWatchlist(String ratingKey) async {
    final response = await _http.put(
      '/actions/removeFromWatchlist',
      queryParameters: {'ratingKey': ratingKey},
      headers: _headers,
      timeout: MediaServerTimeouts.plexTvReceive,
    );
    throwIfHttpError(response);
  }

  /// Convert a discover-provider image path into an absolute URL on
  /// `metadata.provider.plex.tv` carrying the account token. Absolute URLs and
  /// empty paths are returned unchanged.
  String? _absolutizeImage(String? path) {
    if (path == null || path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final sep = path.startsWith('/') ? '' : '/';
    final tokenSep = path.contains('?') ? '&' : '?';
    return '$_metadataHost$sep$path${tokenSep}X-Plex-Token=$_accountToken';
  }
}
