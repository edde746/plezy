import 'package:flutter/foundation.dart';

import '../sources/source_database.dart';
import 'game_discovery.dart';
import 'game_artwork.dart';
import 'game_models.dart';
import 'game_streaming_client.dart';

/// All persistent state is scoped to the active PlezyNG profile. Retired work
/// cannot publish state, launch an app, or resurrect a deleted profile.
class GameLibraryController extends ChangeNotifier {
  GameLibraryController({
    required this.repository,
    required this.profileId,
    required this.sessionCurrent,
    required this.client,
  });
  static const preferenceKey = 'games.library.v1';
  final SourceRepository repository;
  final String profileId;
  final bool Function() sessionCurrent;
  final GameStreamingClient client;
  final GameDiscovery discovery = GameDiscovery();
  final GameArtworkLoader artwork = GameArtworkLoader();
  GameLibrary library = const GameLibrary();
  List<GameHost> nearby = const [];
  bool busy = false, scanning = false;
  bool _disposed = false;
  Future<void> _writes = Future.value();
  bool get current => !_disposed && sessionCurrent();

  void requireCurrent() {
    if (!current) throw const GameClientException(GameClientFailure.cancelled);
  }

  void _notify() {
    if (current) notifyListeners();
  }

  Future<void> load() async {
    final data = await repository.preference(profileId, preferenceKey);
    requireCurrent();
    library = GameLibrary.fromJson(data);
    _notify();
  }

  Future<void> scan() async {
    if (scanning) return;
    requireCurrent();
    scanning = true;
    _notify();
    try {
      final result = await discovery.scan();
      requireCurrent();
      nearby = result;
    } finally {
      scanning = false;
      _notify();
    }
  }

  void stopScan() {
    discovery.stop();
    scanning = false;
  }

  Future<T> action<T>(Future<T> Function() work) async {
    requireCurrent();
    if (busy) throw const GameClientException(GameClientFailure.unavailable);
    busy = true;
    _notify();
    try {
      return await work();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _change(GameLibrary Function(GameLibrary) transform) {
    final next = _writes.then((_) async {
      requireCurrent();
      final value = transform(library);
      await repository.savePreference(profileId, preferenceKey, value.toJson());
      requireCurrent();
      library = value;
      _notify();
    });
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> saveHost(GameHost host) => _change((state) {
    final hosts = {for (final h in state.hosts) h.key: h};
    if (!hosts.containsKey(host.key) && hosts.length >= 32) {
      throw const GameClientException(GameClientFailure.unavailable);
    }
    hosts[host.key] = host;
    return GameLibrary(
      hosts: hosts.values.toList(),
      games: state.games,
      recent: state.recent,
      favorites: state.favorites,
      steamAccountId: state.steamAccountId,
      steamCatalogAvailable: state.steamCatalogAvailable,
      steamCatalogStale: state.steamCatalogStale,
      steamCatalogTruncated: state.steamCatalogTruncated,
      steamCatalog: state.steamCatalog,
    );
  });
  Future<void> removeHost(GameHost host) => _change(
    (state) => GameLibrary.fromJson(
      GameLibrary(
        hosts: state.hosts.where((v) => v.key != host.key).toList(),
        games: state.games,
        recent: state.recent,
        favorites: state.favorites,
        steamAccountId: state.steamAccountId,
        steamCatalogAvailable: state.steamCatalogAvailable,
        steamCatalogStale: state.steamCatalogStale,
        steamCatalogTruncated: state.steamCatalogTruncated,
        steamCatalog: state.steamCatalog,
      ).toJson(),
    ),
  );

  Future<void> refreshGames(GameHost host) async {
    requireCurrent();
    final games = await client.games(host);
    requireCurrent();
    await _change(
      (state) => GameLibrary.fromJson(
        GameLibrary(
          hosts: state.hosts,
          // Device pairing cannot enumerate a private Steam account. Keep its
          // explicit shortcuts while refreshing the embedded library entry.
          games: [
            ...state.games.where(
              (v) =>
                  v.hostKey != host.key || (host.protocol == GameProtocol.steam && !games.any((g) => g.key == v.key)),
            ),
            ...games,
          ],
          recent: state.recent,
          favorites: state.favorites,
          steamAccountId: state.steamAccountId,
          steamCatalogAvailable: state.steamCatalogAvailable,
          steamCatalogStale: state.steamCatalogStale,
          steamCatalogTruncated: state.steamCatalogTruncated,
          steamCatalog: state.steamCatalog,
        ).toJson(),
      ),
    );
  }

  Future<void> saveGame(StreamGame game) => _change(
    (state) => GameLibrary.fromJson(
      GameLibrary(
        hosts: state.hosts,
        games: [...state.games.where((v) => v.key != game.key), game],
        recent: state.recent,
        favorites: state.favorites,
        steamAccountId: state.steamAccountId,
        steamCatalogAvailable: state.steamCatalogAvailable,
        steamCatalogStale: state.steamCatalogStale,
        steamCatalogTruncated: state.steamCatalogTruncated,
        steamCatalog: state.steamCatalog,
      ).toJson(),
    ),
  );
  Future<void> toggleFavorite(StreamGame game) => _change((state) {
    final favorites = {...state.favorites};
    if (!favorites.remove(game.key)) favorites.add(game.key);
    return GameLibrary(
      hosts: state.hosts,
      games: state.games,
      recent: state.recent,
      favorites: favorites,
      steamAccountId: state.steamAccountId,
      steamCatalogAvailable: state.steamCatalogAvailable,
      steamCatalogStale: state.steamCatalogStale,
      steamCatalogTruncated: state.steamCatalogTruncated,
      steamCatalog: state.steamCatalog,
    );
  });
  Future<void> opened(StreamGame game) => _change(
    (state) => GameLibrary(
      hosts: state.hosts,
      games: state.games,
      recent: [game.key, ...state.recent.where((v) => v != game.key)].take(30).toList(),
      favorites: state.favorites,
      steamAccountId: state.steamAccountId,
      steamCatalogAvailable: state.steamCatalogAvailable,
      steamCatalogStale: state.steamCatalogStale,
      steamCatalogTruncated: state.steamCatalogTruncated,
      steamCatalog: state.steamCatalog,
    ),
  );

  Future<void> saveSteamCatalog({
    required String steamId,
    required List<SteamCatalogGame> games,
    required bool catalogAvailable,
    required bool catalogTruncated,
  }) => _change((state) {
    if (!RegExp(r'^\d{17}$').hasMatch(steamId)) {
      throw const GameClientException(GameClientFailure.unavailable);
    }
    final sameAccount = state.steamAccountId == steamId;
    return GameLibrary(
      hosts: state.hosts,
      games: state.games,
      recent: state.recent,
      favorites: state.favorites,
      steamAccountId: steamId,
      steamCatalogAvailable: catalogAvailable || (sameAccount && state.steamCatalogAvailable),
      steamCatalogStale: !catalogAvailable && sameAccount && state.steamCatalogAvailable,
      steamCatalogTruncated: catalogAvailable
          ? catalogTruncated
          : sameAccount && state.steamCatalogAvailable && state.steamCatalogTruncated,
      steamCatalog: catalogAvailable
          ? games.take(2000).toList()
          : sameAccount
          ? state.steamCatalog
          : const [],
    );
  });

  Future<void> unlinkSteamAccount() => _change(
    (state) => GameLibrary(
      hosts: state.hosts,
      games: state.games,
      recent: state.recent,
      favorites: state.favorites,
    ),
  );

  @override
  void dispose() {
    _disposed = true;
    discovery.stop();
    artwork.dispose();
    client.cancel();
    super.dispose();
  }
}
