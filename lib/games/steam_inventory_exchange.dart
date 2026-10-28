import 'dart:async';
import 'dart:math';

import 'game_models.dart';
import 'steam_local_inventory.dart';

/// Versioned, read-only extension carried inside the existing authenticated
/// companion connection. No new listener, credentials, remote file paths or
/// executable commands. One bounded transaction per connection at a time.
class SteamInventoryExchange {
  SteamInventoryExchange({
    required this.isHost,
    required this.canShare,
    required this.readInventory,
    required this.send,
  });
  final bool isHost;
  final bool Function() canShare;
  final Future<SteamInventoryScan> Function(bool Function() current) readInventory;
  final void Function(Map<String, dynamic>) send;
  bool _closed = false, _serving = false;
  DateTime? _lastRead;
  int _generation = 0;
  Completer<SteamInventoryScan>? _pending;
  Timer? _timer;
  String? _request;
  final _games = <SteamInstalledGame>[];
  final _ids = <int>{};
  int? _total;

  Future<SteamInventoryScan> request() {
    if (_closed || isHost || _pending != null) return Future.error(const SteamInventoryUnavailable());
    final random = Random.secure();
    _request = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final pending = _pending = Completer<SteamInventoryScan>();
    _games.clear();
    _ids.clear();
    _total = null;
    _timer = Timer(const Duration(seconds: 25), () => _fail());
    send({'version': 1, 'op': 'request', 'request': _request});
    return pending.future;
  }

  void receive(Map<String, dynamic>? message) {
    if (_closed || message == null || message['version'] != 1) return;
    final request = message['request'];
    if (request is! String || !RegExp(r'^[0-9a-f]{32}$').hasMatch(request)) return;
    if (message['op'] == 'request' && isHost) {
      unawaited(_serve(request));
      return;
    }
    if (isHost || _pending == null || request != _request) return;
    if (message['op'] == 'unavailable') {
      _fail();
      return;
    }
    if (message['op'] != 'page') return;
    final rows = message['games'], offset = message['offset'], total = message['total'];
    if (rows is! List ||
        rows.length > 50 ||
        offset != _games.length ||
        total is! int ||
        total < 0 ||
        total > 2000 ||
        (_total != null && total != _total) ||
        _games.length + rows.length > total ||
        (rows.isEmpty && total != 0)) {
      _fail();
      return;
    }
    _total = total;
    try {
      for (final row in rows) {
        final game = SteamInstalledGame.fromJson(Map<String, dynamic>.from(row as Map));
        if (!_ids.add(game.appId)) throw const FormatException('Duplicate inventory identity');
        _games.add(game);
      }
    } catch (_) {
      _fail();
      return;
    }
    if (message['last'] == true) {
      if (_games.length != total || message['complete'] is! bool) {
        _fail();
        return;
      }
      final result = SteamInventoryScan(games: List.unmodifiable(_games), complete: message['complete'] == true);
      final pending = _pending;
      _clear();
      pending?.complete(result);
    } else if (_games.length == total) {
      _fail();
    }
  }

  Future<void> _serve(String request) async {
    if (!canShare() ||
        _serving ||
        (_lastRead != null && DateTime.now().difference(_lastRead!) < const Duration(seconds: 15))) {
      send({'version': 1, 'op': 'unavailable', 'request': request});
      return;
    }
    _serving = true;
    _lastRead = DateTime.now();
    final generation = ++_generation;
    bool current() => !_closed && generation == _generation && canShare();
    try {
      final inventory = await readInventory(current).timeout(const Duration(seconds: 20));
      if (!current()) return;
      final games = inventory.games.take(2000).toList();
      for (var offset = 0; offset < max(1, games.length); offset += 50) {
        if (!current()) return;
        final end = min(offset + 50, games.length);
        send({
          'version': 1,
          'op': 'page',
          'request': request,
          'offset': offset,
          'total': games.length,
          'last': end == games.length,
          'complete': inventory.complete && inventory.games.length <= 2000,
          'games': games.sublist(offset, end).map((g) => g.toJson()).toList(),
        });
      }
    } catch (_) {
      if (!_closed) send({'version': 1, 'op': 'unavailable', 'request': request});
    } finally {
      if (generation == _generation) {
        _generation++;
        _serving = false;
      }
    }
  }

  void _clear() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _request = null;
    _games.clear();
    _ids.clear();
    _total = null;
  }

  void _fail() {
    final pending = _pending;
    _clear();
    pending?.completeError(const SteamInventoryUnavailable());
  }

  void close() {
    _closed = true;
    reset();
  }

  void reset() {
    _generation++;
    _serving = false;
    _fail();
  }
}

class SteamInventoryUnavailable implements Exception {
  const SteamInventoryUnavailable();
}
