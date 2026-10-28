import 'dart:async';
import 'dart:math';

enum SteamHostAction { launch, install, library, downloads }

enum SteamHostActionResult { submitted, denied, unavailable }

Uri steamHostActionUri(SteamHostAction action, int? appId) {
  if (action == SteamHostAction.launch || action == SteamHostAction.install) {
    if (appId == null || appId < 1 || appId > 0xffffffff) throw const FormatException('Invalid Steam AppID');
    return Uri.parse('steam://${action == SteamHostAction.launch ? 'rungameid' : 'install'}/$appId');
  }
  if (appId != null) throw const FormatException('Unexpected Steam AppID');
  return Uri.parse(action == SteamHostAction.library ? 'steam://open/games' : 'steam://open/downloads');
}

/// Runs only inside an authenticated companion connection. Commands never
/// contain a URL, executable, path, launch argument, SteamID or account token.
class SteamHostActionExchange {
  SteamHostActionExchange({required this.isHost, required this.allowed, required this.execute, required this.send});
  final bool isHost;
  final bool Function(SteamHostAction) allowed;
  final Future<bool> Function(SteamHostAction, int?, bool Function()) execute;
  final void Function(Map<String, dynamic>) send;
  final Set<String> _seen = {};
  Completer<SteamHostActionResult>? _pending;
  String? _request;
  Timer? _timer;
  bool _closed = false, _serving = false;
  int _generation = 0;
  final Stopwatch _clock = Stopwatch()..start();
  Duration? _lastAction;

  Future<SteamHostActionResult> request(SteamHostAction action, {int? appId}) {
    steamHostActionUri(action, appId);
    if (_closed || isHost || _pending != null) return Future.value(SteamHostActionResult.unavailable);
    final random = Random.secure();
    _request = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final pending = _pending = Completer<SteamHostActionResult>();
    _timer = Timer(const Duration(seconds: 25), () => _finish(SteamHostActionResult.unavailable));
    send({'version': 1, 'op': 'request', 'request': _request, 'action': action.name, 'appId': ?appId});
    return pending.future;
  }

  void receive(Map<String, dynamic>? message) {
    if (_closed || message == null || message['version'] != 1) return;
    final id = message['request'];
    if (id is! String || !RegExp(r'^[0-9a-f]{32}$').hasMatch(id)) return;
    if (isHost && message['op'] == 'request') {
      unawaited(_serve(id, message));
      return;
    }
    if (!isHost && id == _request && message['op'] == 'result') {
      _finish(
        SteamHostActionResult.values.where((v) => v.name == message['result']).firstOrNull ??
            SteamHostActionResult.unavailable,
      );
    }
  }

  Future<void> _serve(String id, Map<String, dynamic> message) async {
    // A duplicate never repeats an action, including after the first response.
    if (_seen.contains(id)) return;
    if (_seen.length >= 256) {
      _reply(id, SteamHostActionResult.denied);
      return;
    }
    _seen.add(id);
    final action = SteamHostAction.values.where((v) => v.name == message['action']).firstOrNull;
    final appId = message['appId'];
    if (action == null ||
        (appId != null && appId is! int) ||
        message.keys.any((k) => !{'version', 'op', 'request', 'action', 'appId'}.contains(k))) {
      _reply(id, SteamHostActionResult.denied);
      return;
    }
    try {
      steamHostActionUri(action, appId as int?);
    } catch (_) {
      _reply(id, SteamHostActionResult.denied);
      return;
    }
    if (!allowed(action)) {
      _reply(id, SteamHostActionResult.denied);
      return;
    }
    if (_serving || (_lastAction != null && _clock.elapsed - _lastAction! < const Duration(seconds: 2))) {
      _reply(id, SteamHostActionResult.unavailable);
      return;
    }
    _serving = true;
    _lastAction = _clock.elapsed;
    final generation = _generation;
    final deadline = _clock.elapsed + const Duration(seconds: 20);
    var active = true;
    bool current() => active && !_closed && generation == _generation && allowed(action) && _clock.elapsed < deadline;
    try {
      final submitted = await execute(action, appId, current).timeout(const Duration(seconds: 20));
      if (current()) _reply(id, submitted ? SteamHostActionResult.submitted : SteamHostActionResult.unavailable);
    } catch (_) {
      if (!_closed && generation == _generation) _reply(id, SteamHostActionResult.unavailable);
    } finally {
      active = false; // A timed-out asynchronous scan cannot launch later.
      if (generation == _generation) _serving = false;
    }
  }

  void _reply(String id, SteamHostActionResult result) =>
      send({'version': 1, 'op': 'result', 'request': id, 'result': result.name});
  void _finish(SteamHostActionResult result) {
    final pending = _pending;
    _pending = null;
    _request = null;
    _timer?.cancel();
    _timer = null;
    pending?.complete(result);
  }

  void reset() {
    _generation++;
    _serving = false;
    _seen.clear();
    _finish(SteamHostActionResult.unavailable);
  }

  void close() {
    _closed = true;
    reset();
  }
}
