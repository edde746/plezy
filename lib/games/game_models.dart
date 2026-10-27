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
  StreamGame({required this.hostKey, required this.id, required this.name, this.hdr = false}) {
    if (hostKey.isEmpty ||
        hostKey.length > 300 ||
        id.isEmpty ||
        id.length > 256 ||
        name.trim().isEmpty ||
        name.length > 256 ||
        RegExp(r'[\x00-\x1f]').hasMatch(name)) {
      throw const FormatException('Invalid game');
    }
  }
  final String hostKey, id, name;
  final bool hdr;
  String get key => '$hostKey/${Uri.encodeComponent(id)}';
  Map<String, dynamic> toJson() => {'hostKey': hostKey, 'id': id, 'name': name, 'hdr': hdr};
  factory StreamGame.fromJson(Map<String, dynamic> value) => StreamGame(
    hostKey: value['hostKey'] as String,
    id: value['id'] as String,
    name: value['name'] as String,
    hdr: value['hdr'] == true,
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
    return GameLibrary(
      hosts: hosts.values.toList(),
      games: games.values.toList(),
      recent: _rows(data['recent']).whereType<String>().where(games.containsKey).toSet().take(30).toList(),
      favorites: _rows(data['favorites']).whereType<String>().where(games.containsKey).take(500).toSet(),
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

List<dynamic> _rows(Object? value) => value is List ? value : const [];
