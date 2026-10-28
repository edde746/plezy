import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'game_models.dart';

/// Small, profile-owned cache. Cover requests never share the pairing queue.
class GameArtworkLoader {
  GameArtworkLoader({Future<Uint8List?> Function(GameHost, StreamGame)? fetch}) : _fetch = fetch ?? _native;
  final Future<Uint8List?> Function(GameHost, StreamGame) _fetch;
  final _cache = <String, Future<Uint8List?>>{};
  final _pending = <String, Future<Uint8List?>>{};
  final _queue = Queue<_CoverRequest>();
  int _active = 0, _generation = 0;
  bool _disposed = false;

  Future<Uint8List?> load(GameHost host, StreamGame game) {
    if (_disposed || game.hostKey != host.key) return Future.value();
    final key = '${game.key}@${host.address}:${host.port}';
    return _load(key, () => _fetch(host, game));
  }

  /// Only a numeric AppID can select a public Steam cover; no caller URLs,
  /// credentials, redirects, disk cache or unbounded response buffers.
  Future<Uint8List?> loadSteam(int appId) {
    if (!validSteamAppId(appId)) return Future.value();
    return _load('steam:$appId', () => _steamCover(appId));
  }

  Future<Uint8List?> _load(String key, Future<Uint8List?> Function() fetch) {
    if (_disposed) return Future.value();
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }
    if (_pending.containsKey(key)) return _pending[key]!;
    if (_queue.length >= 62) return Future.value();
    final request = _CoverRequest(fetch, key, _generation);
    _pending[key] = request.result.future;
    _queue.add(request);
    _pump();
    return request.result.future;
  }

  void _pump() {
    while (!_disposed && _active < 2 && _queue.isNotEmpty) {
      final request = _queue.removeFirst();
      _active++;
      unawaited(_complete(request));
    }
  }

  Future<void> _complete(_CoverRequest request) async {
    Uint8List? result;
    try {
      final bytes = await request.fetch().timeout(const Duration(seconds: 12));
      if (!_disposed && request.generation == _generation && bytes != null && bytes.length <= 512 * 1024) {
        result = bytes;
      }
    } catch (_) {
      /* A missing cover is not a failed stream. */
    }
    request.result.complete(result);
    unawaited(_pending.remove(request.key));
    if (!_disposed && request.generation == _generation) {
      _cache[request.key] = request.result.future;
      while (_cache.length > 32) {
        unawaited(_cache.remove(_cache.keys.first));
      }
    }
    _active--;
    _pump();
  }

  static Future<Uint8List?> _native(GameHost host, StreamGame game) =>
      const MethodChannel('com.plezy/games').invokeMethod<Uint8List>('artwork', {
        'protocol': host.protocol.name,
        'hostId': host.id,
        'address': host.address,
        'port': host.port,
        'appId': game.id,
      });

  static Future<Uint8List?> _steamCover(int appId) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    Future<Uint8List?> fetch() async {
      final uri = Uri.https('cdn.akamai.steamstatic.com', '/steam/apps/$appId/library_600x900.jpg');
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok ||
          response.contentLength > 512 * 1024 ||
          !{'image/jpeg', 'image/png', 'image/webp'}.contains(response.headers.contentType?.mimeType)) {
        return null;
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 512 * 1024) return null;
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    }

    try {
      return await fetch().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    for (final request in _queue) {
      request.result.complete(null);
    }
    _queue.clear();
    _pending.clear();
    _cache.clear();
  }
}

class _CoverRequest {
  _CoverRequest(this.fetch, this.key, this.generation);
  final Future<Uint8List?> Function() fetch;
  final String key;
  final int generation;
  final result = Completer<Uint8List?>();
}
