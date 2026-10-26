import 'dart:async';

import 'package:flutter/services.dart';
import '../i18n/strings.g.dart';

import 'game_models.dart';

enum GameClientFailure { unavailable, pairingRequired, timedOut, cancelled }

class GameClientException implements Exception {
  const GameClientException(this.failure);
  final GameClientFailure failure;
}

class GameClientCapabilities {
  const GameClientCapabilities({required this.available, this.inlinePairing = false, this.library = false});
  final bool available, inlinePairing, library;
}

/// Native engines run inside PlezyNG. Missing engines never launch another app.
abstract class GameStreamingClient {
  Future<GameClientCapabilities> capabilities(GameHost host);
  Future<void> pair(GameHost host, String pin);
  Future<List<StreamGame>> games(GameHost host);
  Future<void> open(GameHost host, {required StreamGame game, bool touchControls = true, bool pyrowave = false});
  void cancel();
}

class NativeGameStreamingClient implements GameStreamingClient {
  static const channel = MethodChannel('com.plezy/games');
  int _generation = 0;

  Map<String, Object?> _host(GameHost host) => {
    'protocol': host.protocol.name,
    'hostId': host.id,
    'hostName': host.name,
    'address': host.address,
    'port': host.port,
  };

  @override
  Future<GameClientCapabilities> capabilities(GameHost host) async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('capabilities', _host(host));
      return GameClientCapabilities(
        available: result?['available'] == true,
        inlinePairing: result?['inlinePairing'] == true,
        library: result?['library'] == true,
      );
    } on PlatformException {
      return const GameClientCapabilities(available: false);
    } on MissingPluginException {
      return const GameClientCapabilities(available: false);
    }
  }

  Future<T?> _invoke<T>(String method, Map<String, Object?> arguments, Duration timeout) async {
    final generation = _generation;
    try {
      final value = await channel.invokeMethod<T>(method, arguments).timeout(timeout);
      if (generation != _generation) throw const GameClientException(GameClientFailure.cancelled);
      return value;
    } on TimeoutException {
      cancel();
      throw const GameClientException(GameClientFailure.timedOut);
    } on MissingPluginException {
      throw const GameClientException(GameClientFailure.unavailable);
    } on PlatformException catch (error) {
      throw GameClientException(switch (error.code) {
        'PAIRING_REQUIRED' => GameClientFailure.pairingRequired,
        'CANCELLED' => GameClientFailure.cancelled,
        _ => GameClientFailure.unavailable,
      });
    }
  }

  @override
  Future<void> pair(GameHost host, String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) throw const GameClientException(GameClientFailure.unavailable);
    await _invoke<bool>('pair', {..._host(host), 'pin': pin}, const Duration(seconds: 90));
  }

  @override
  Future<List<StreamGame>> games(GameHost host) async {
    final rows = await _invoke<List<dynamic>>('games', _host(host), const Duration(seconds: 30));
    final games = (rows ?? [])
        .take(2000)
        .map(
          (row) => StreamGame(
            hostKey: host.key,
            id: (row as Map)['id'].toString(),
            name: row['name'] as String,
            hdr: row['hdr'] == true,
          ),
        )
        .toList();
    if (host.protocol == GameProtocol.steam) {
      games.insert(0, StreamGame(hostKey: host.key, id: '0', name: t.games.steamLibrary));
    }
    return games;
  }

  @override
  Future<void> open(GameHost host, {required StreamGame game, bool touchControls = true, bool pyrowave = false}) async {
    if (game.hostKey != host.key) throw const GameClientException(GameClientFailure.unavailable);
    final ok = await _invoke<bool>('open', {
      ..._host(host),
      'appId': game.id,
      'appName': game.name,
      'touchControls': touchControls,
      'pyrowave': pyrowave,
      'hdr': game.hdr,
      'connecting': t.games.connecting,
      'error': t.games.unavailable,
      'disconnect': t.games.disconnect,
      'menu': t.games.streamControls,
      'touchLabel': t.games.touchControls,
      'touchDescription': t.games.touchDescription,
      'ok': t.common.ok,
      'cancel': t.common.cancel,
    }, const Duration(seconds: 10));
    if (ok != true) throw const GameClientException(GameClientFailure.unavailable);
  }

  @override
  void cancel() {
    _generation++;
    unawaited(channel.invokeMethod<void>('cancel').catchError((Object _) {}));
  }
}
