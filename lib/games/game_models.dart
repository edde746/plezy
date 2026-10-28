import 'dart:io';

enum GameProtocol { gameStream, steam }

/// An explicitly selected computer. Discovery is a hint, never authentication.
class GameHost {
  GameHost({
    required this.id,
    required this.name,
    required this.address,
    required this.protocol,
    this.port = 47989,
    this.mac,
  }) {
    validateGameAddress(address);
    if (id.isEmpty ||
        id.length > 256 ||
        name.trim().isEmpty ||
        name.length > 256 ||
        port < 1 ||
        port > 65534 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(id + name)) {
      throw const FormatException('Invalid game computer');
    }
    if (mac != null && !RegExp(r'^(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$').hasMatch(mac!)) {
      throw const FormatException('Invalid MAC address');
    }
  }

  final String id, name, address;
  final GameProtocol protocol;
  final int port;
  final String? mac;
  String get key => '${protocol.name}:${Uri.encodeComponent(id)}';

  /// Sunshine's web UI is one port above its HTTP GameStream listener.
  /// Legacy GFE/Wolf may have no web UI; this is offered only as a user action.
  Uri get sunshinePairingPage => Uri(scheme: 'https', host: address, port: port + 1, path: '/pin');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'protocol': protocol.name,
    'port': port,
    'mac': mac,
  };
  factory GameHost.fromJson(Map<String, dynamic> json) => GameHost(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    protocol: GameProtocol.values.byName(json['protocol'] as String),
    port: json['port'] as int,
    mac: json['mac'] as String?,
  );
}

/// No URLs, shell commands, passwords or tokens are accepted as addresses.
void validateGameAddress(String value) {
  if (value.isEmpty ||
      value.length > 253 ||
      value.trim() != value ||
      value.startsWith('-') ||
      RegExp(r'[\s/@?#\\\x00-\x1f]').hasMatch(value)) {
    throw const FormatException('Enter an IP address or hostname');
  }
  final ip = InternetAddress.tryParse(value);
  if (ip != null) {
    if (ip.isMulticast || ip.address == '0.0.0.0' || ip.address == '::' || ip.address == '255.255.255.255') {
      throw const FormatException('Invalid computer address');
    }
    return;
  }
  if (!value.split('.').every((part) => RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$').hasMatch(part))) {
    throw const FormatException('Enter an IP address or hostname');
  }
}

class StreamGame {
  StreamGame({required this.hostKey, required this.id, required this.name, this.hdr = false, this.steamAppId}) {
    if (hostKey.isEmpty ||
        hostKey.length > 300 ||
        id.isEmpty ||
        id.length > 256 ||
        name.trim().isEmpty ||
        name.length > 256 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(id + name) ||
        (steamAppId != null && !validSteamAppId(steamAppId!))) {
      throw const FormatException('Invalid game');
    }
  }
  final String hostKey, id, name;
  final bool hdr;

  /// Explicit source identity for a Steam game served by another transport.
  /// Never infer this from a title or a GameStream application ID.
  final int? steamAppId;
  String get key => '$hostKey/${Uri.encodeComponent(id)}';
  Map<String, dynamic> toJson() => {
    'hostKey': hostKey,
    'id': id,
    'name': name,
    'hdr': hdr,
    if (steamAppId != null) 'steamAppId': steamAppId,
  };
  factory StreamGame.fromJson(Map<String, dynamic> value) => StreamGame(
    hostKey: value['hostKey'] as String,
    id: value['id'] as String,
    name: value['name'] as String,
    hdr: value['hdr'] == true,
    steamAppId: value['steamAppId'] as int?,
  );
}

class SteamCatalogGame {
  SteamCatalogGame({required this.appId, required this.name, this.iconHash = ''}) {
    if (appId < 1 ||
        appId > 0xffffffff ||
        name.trim().isEmpty ||
        name.length > 256 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(name) ||
        iconHash.length > 64 ||
        !RegExp(r'^[0-9a-fA-F]*$').hasMatch(iconHash)) {
      throw const FormatException('Invalid Steam catalog entry');
    }
  }

  final int appId;
  final String name;
  final String iconHash;
  String get key => appId.toString();

  Map<String, dynamic> toJson() => {'appId': appId, 'name': name, 'iconHash': iconHash};

  factory SteamCatalogGame.fromJson(Map<String, dynamic> json) => SteamCatalogGame(
    appId: (json['appId'] ?? json['appid']) as int,
    name: json['name'] as String,
    iconHash: json['iconHash'] as String? ?? '',
  );
}

class GameLibrary {
  const GameLibrary({
    this.hosts = const [],
    this.games = const [],
    this.recent = const [],
    this.favorites = const {},
    this.steamAccountId,
    this.steamCatalogAvailable = false,
    this.steamCatalogStale = false,
    this.steamCatalogTruncated = false,
    this.steamCatalog = const [],
    this.preferredRoutes = const {},
  });
  final List<GameHost> hosts;
  final List<StreamGame> games;
  final List<String> recent;
  final Set<String> favorites;
  final String? steamAccountId;
  final bool steamCatalogAvailable;

  /// True when the last refresh failed but a previously visible catalog is cached.
  final bool steamCatalogStale;
  final bool steamCatalogTruncated;
  final List<SteamCatalogGame> steamCatalog;

  /// Successful route preferences, scoped to this profile. Not online state.
  final Map<String, String> preferredRoutes;

  String identityOf(StreamGame game) {
    final host = hosts.where((h) => h.key == game.hostKey).firstOrNull;
    final appId = game.steamAppId ?? (host?.protocol == GameProtocol.steam ? int.tryParse(game.id) : null);
    return appId != null && validSteamAppId(appId) ? 'steam:$appId' : game.key;
  }

  /// A projection, not a second catalog to persist or synchronize.
  List<LibraryGame> get entries {
    final result = <String, LibraryGame>{};
    for (final game in steamCatalog) {
      result['steam:${game.appId}'] = LibraryGame(
        key: 'steam:${game.appId}',
        name: game.name,
        steamAppId: game.appId,
        inAccountCatalog: true,
        routes: const [],
      );
    }
    final hostMap = {for (final host in hosts) host.key: host};
    for (final game in games) {
      final host = hostMap[game.hostKey];
      if (host == null || (host.protocol == GameProtocol.steam && game.id == '0')) continue;
      final key = identityOf(game);
      final old = result[key];
      result[key] = LibraryGame(
        key: key,
        name: old?.name ?? game.name,
        steamAppId: old?.steamAppId ?? (key.startsWith('steam:') ? int.tryParse(key.substring(6)) : null),
        inAccountCatalog: old?.inAccountCatalog ?? false,
        routes: [
          ...?old?.routes,
          GameRoute(host: host, game: game, savedShortcut: true),
        ],
      );
    }
    // Steam can launch a verified catalog AppID directly. A candidate route
    // does not claim installation, reachability, pairing or entitlement.
    return result.values
        .map(
          (entry) => LibraryGame(
            key: entry.key,
            name: entry.name,
            steamAppId: entry.steamAppId,
            inAccountCatalog: entry.inAccountCatalog,
            routes: List.unmodifiable([
              ...entry.routes,
              if (entry.steamAppId != null)
                for (final host in hosts)
                  if (host.protocol == GameProtocol.steam && !entry.routes.any((r) => r.host.key == host.key))
                    GameRoute(
                      host: host,
                      game: StreamGame(hostKey: host.key, id: '${entry.steamAppId}', name: entry.name),
                    ),
            ]),
          ),
        )
        .toList(growable: false);
  }

  String canonicalKey(String key) {
    final game = games.where((game) => game.key == key).firstOrNull;
    return game == null ? key : identityOf(game);
  }

  Set<String> get favoriteKeys => favorites.map(canonicalKey).toSet();
  List<String> get recentKeys => recent.map(canonicalKey).toSet().toList();

  GameLibrary copyWith({
    List<GameHost>? hosts,
    List<StreamGame>? games,
    List<String>? recent,
    Set<String>? favorites,
    Map<String, String>? preferredRoutes,
  }) => GameLibrary(
    hosts: hosts ?? this.hosts,
    games: games ?? this.games,
    recent: recent ?? this.recent,
    favorites: favorites ?? this.favorites,
    preferredRoutes: preferredRoutes ?? this.preferredRoutes,
    steamAccountId: steamAccountId,
    steamCatalogAvailable: steamCatalogAvailable,
    steamCatalogStale: steamCatalogStale,
    steamCatalogTruncated: steamCatalogTruncated,
    steamCatalog: steamCatalog,
  );
  Map<String, dynamic> toJson() => {
    'version': 2,
    'hosts': hosts.take(32).map((v) => v.toJson()).toList(),
    'games': games.take(2000).map((v) => v.toJson()).toList(),
    'recent': recent.take(30).toList(),
    'favorites': favorites.take(500).toList(),
    if (steamAccountId != null) 'steamAccountId': steamAccountId,
    'steamCatalogAvailable': steamCatalogAvailable,
    'steamCatalogStale': steamCatalogStale,
    'steamCatalogTruncated': steamCatalogTruncated,
    'steamCatalog': steamCatalog.take(2000).map((v) => v.toJson()).toList(),
    'preferredRoutes': Map.fromEntries(preferredRoutes.entries.take(2000)),
  };
  factory GameLibrary.fromJson(Map<String, dynamic> data) {
    if (data['version'] != 1 && data['version'] != 2) return const GameLibrary();
    final hosts = <String, GameHost>{};
    final games = <String, StreamGame>{};
    for (final row in _rows(data['hosts']).take(32)) {
      try {
        final host = GameHost.fromJson(Map<String, dynamic>.from(row as Map));
        hosts[host.key] = host;
      } catch (_) {
        /* Recover other entries. */
      }
    }
    for (final row in _rows(data['games']).take(2000)) {
      try {
        final game = StreamGame.fromJson(Map<String, dynamic>.from(row as Map));
        if (hosts.containsKey(game.hostKey)) games[game.key] = game;
      } catch (_) {
        /* Recover other entries. */
      }
    }
    final rawSteamId = data['steamAccountId'];
    final steamAccountId = rawSteamId is String && RegExp(r'^\d{17}$').hasMatch(rawSteamId) ? rawSteamId : null;
    final steamCatalog = <String, SteamCatalogGame>{};
    for (final row in _rows(data['steamCatalog']).take(2000)) {
      try {
        final game = SteamCatalogGame.fromJson(Map<String, dynamic>.from(row as Map));
        steamCatalog[game.key] = game;
      } catch (_) {
        /* Recover other entries. */
      }
    }
    final projection = GameLibrary(
      hosts: hosts.values.toList(),
      games: games.values.toList(),
      steamCatalog: steamAccountId == null ? const [] : steamCatalog.values.toList(),
    );
    final identities = {for (final game in projection.entries) game.key};
    bool validKey(String key) => games.containsKey(key) || identities.contains(key);
    final routes = <String, String>{};
    if (data['preferredRoutes'] case final Map values) {
      final entries = {for (final entry in projection.entries) entry.key: entry};
      for (final item in values.entries.take(2000)) {
        if (item.key is String &&
            item.value is String &&
            (entries[item.key]?.routes.any((r) => r.key == item.value) ?? false)) {
          routes[item.key as String] = item.value as String;
        }
      }
    }
    return GameLibrary(
      hosts: hosts.values.toList(),
      games: games.values.toList(),
      recent: _rows(data['recent']).whereType<String>().where(validKey).toSet().take(30).toList(),
      favorites: _rows(data['favorites']).whereType<String>().where(validKey).take(500).toSet(),
      preferredRoutes: routes,
      steamAccountId: steamAccountId,
      steamCatalogAvailable: steamAccountId != null && data['steamCatalogAvailable'] == true,
      steamCatalogStale:
          steamAccountId != null && data['steamCatalogAvailable'] == true && data['steamCatalogStale'] == true,
      steamCatalogTruncated:
          steamAccountId != null && data['steamCatalogAvailable'] == true && data['steamCatalogTruncated'] == true,
      steamCatalog: steamAccountId == null ? const [] : steamCatalog.values.toList(),
    );
  }
}

bool validSteamAppId(int value) => value > 0 && value <= 0xffffffff;

class GameRoute {
  const GameRoute({required this.host, required this.game, this.savedShortcut = false});
  final GameHost host;
  final StreamGame game;
  final bool savedShortcut;
  String get key => game.key;
}

class LibraryGame {
  const LibraryGame({
    required this.key,
    required this.name,
    required this.routes,
    this.steamAppId,
    this.inAccountCatalog = false,
  });
  final String key, name;
  final int? steamAppId;
  final bool inAccountCatalog;
  final List<GameRoute> routes;
  GameRoute? preferredRoute(GameLibrary library) =>
      routes.where((r) => r.key == library.preferredRoutes[key]).firstOrNull ??
      (routes.length == 1 ? routes.single : null);
}

List<dynamic> _rows(Object? value) => value is List ? value : const [];
