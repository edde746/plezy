import 'dart:async';
import 'dart:math';

enum GameSessionAction { list, mute, listen, fullscreen, disconnect }

enum GameSessionControlStatus { ok, submitted, denied, unavailable }

class RemoteGameSession {
  const RemoteGameSession({required this.id, required this.title, required this.audible});
  final String id, title;
  final bool audible;
}

class GameSessionControlReply {
  const GameSessionControlReply(this.status, [this.sessions = const []]);
  final GameSessionControlStatus status;
  final List<RemoteGameSession> sessions;
}

/// A live registration, not a saved game or host route. Its identity changes
/// when the session is replaced, even if the game ID stays the same.
class GameSessionControlTarget {
  const GameSessionControlTarget({
    required this.owner,
    required this.title,
    required this.audible,
    required this.execute,
  });
  final Object owner;
  final String title;
  final bool audible;
  final FutureOr<bool> Function(GameSessionAction) execute;
}

/// Low-rate controls inside the existing authenticated companion channel.
/// Per-peer random handles expose no host IDs, addresses or stream credentials.
/// No raw controller events, host quit command, arbitrary URL or keyboard text.
class GameSessionExchange {
  GameSessionExchange({required this.isHost, required this.allowed, required this.targets, required this.send}) {
    _clock.start();
  }
  final bool isHost;
  final bool Function() allowed;
  final List<GameSessionControlTarget> Function() targets;
  final void Function(Map<String, dynamic>) send;
  final Stopwatch _clock = Stopwatch();
  final Map<String, Object> _handles = {};
  final Set<String> _seen = {};
  static final _idPattern = RegExp(r'^[0-9a-f]{32}$');
  bool _closed = false, _serving = false;
  int _generation = 0;
  Duration? _lastList, _lastAction;
  Completer<GameSessionControlReply>? _pending;
  String? _request;
  GameSessionAction? _requestedAction;
  Timer? _timeout;

  String _id() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<GameSessionControlReply> request(GameSessionAction action, {String? target}) {
    if ((action == GameSessionAction.list && target != null) ||
        (action != GameSessionAction.list && (target == null || !_idPattern.hasMatch(target)))) {
      return Future.value(const GameSessionControlReply(GameSessionControlStatus.denied));
    }
    if (_closed || isHost || _pending != null) {
      return Future.value(const GameSessionControlReply(GameSessionControlStatus.unavailable));
    }
    final pending = _pending = Completer<GameSessionControlReply>();
    _request = _id();
    _requestedAction = action;
    _timeout = Timer(
      const Duration(seconds: 10),
      () => _finish(const GameSessionControlReply(GameSessionControlStatus.unavailable)),
    );
    try {
      send({'version': 1, 'op': 'request', 'request': _request, 'action': action.name, 'target': ?target});
    } catch (_) {
      _finish(const GameSessionControlReply(GameSessionControlStatus.unavailable));
    }
    return pending.future;
  }

  void receive(Map<String, dynamic>? message) {
    if (_closed || message == null || message['version'] != 1) return;
    final id = message['request'];
    if (id is! String || !_idPattern.hasMatch(id)) return;
    if (isHost && message['op'] == 'request') {
      unawaited(_serve(id, message));
    } else if (!isHost && message['op'] == 'result' && id == _request) {
      final status = GameSessionControlStatus.values.where((v) => v.name == message['status']).firstOrNull;
      final raw = message['sessions'];
      final sessions = <RemoteGameSession>[];
      var valid = status != null && message.keys.every({'version', 'op', 'request', 'status', 'sessions'}.contains);
      valid =
          valid &&
          (_requestedAction == GameSessionAction.list
              ? status != GameSessionControlStatus.submitted
              : status != GameSessionControlStatus.ok);
      if (raw != null) {
        if (_requestedAction != GameSessionAction.list ||
            status != GameSessionControlStatus.ok ||
            raw is! List ||
            raw.length > 8) {
          valid = false;
        } else {
          final ids = <String>{};
          for (final item in raw) {
            if (item is! Map ||
                item.keys.any((key) => !{'id', 'title', 'audible'}.contains(key)) ||
                item['id'] is! String ||
                !_idPattern.hasMatch(item['id'] as String) ||
                !ids.add(item['id'] as String) ||
                item['title'] is! String ||
                (item['title'] as String).isEmpty ||
                (item['title'] as String).length > 160 ||
                item['audible'] is! bool) {
              valid = false;
              break;
            }
            sessions.add(
              RemoteGameSession(
                id: item['id'] as String,
                title: _title(item['title'] as String),
                audible: item['audible'] as bool,
              ),
            );
          }
        }
      } else if (status == GameSessionControlStatus.ok && _requestedAction == GameSessionAction.list) {
        valid = false;
      }
      _finish(
        GameSessionControlReply(
          valid ? status! : GameSessionControlStatus.unavailable,
          valid ? List.unmodifiable(sessions) : const [],
        ),
      );
    }
  }

  static String _title(String raw) {
    final clean = raw.replaceAll(RegExp(r'[\u0000-\u001f\u007f\u200b-\u200f\u202a-\u202e\u2060-\u206f]'), '').trim();
    return clean.isEmpty ? 'Game' : String.fromCharCodes(clean.runes.take(80));
  }

  Future<void> _serve(String id, Map<String, dynamic> message) async {
    if (_seen.contains(id)) return;
    if (_seen.length >= 256) {
      _reply(id, GameSessionControlStatus.denied);
      return;
    }
    _seen.add(id);
    final action = GameSessionAction.values.where((a) => a.name == message['action']).firstOrNull;
    final target = message['target'];
    if (action == null ||
        message.keys.any((k) => !{'version', 'op', 'request', 'action', 'target'}.contains(k)) ||
        (action == GameSessionAction.list ? target != null : target is! String || !_idPattern.hasMatch(target)) ||
        !allowed()) {
      _reply(id, GameSessionControlStatus.denied);
      return;
    }
    final last = action == GameSessionAction.list ? _lastList : _lastAction;
    if (_serving || (last != null && _clock.elapsed - last < const Duration(milliseconds: 250))) {
      _reply(id, GameSessionControlStatus.unavailable);
      return;
    }
    if (action == GameSessionAction.list) {
      _lastList = _clock.elapsed;
    } else {
      _lastAction = _clock.elapsed;
    }
    _serving = true;
    final generation = _generation;
    bool current() => !_closed && _generation == generation && allowed();
    try {
      final live = targets().take(8).toList();
      if (!current()) return;
      if (action == GameSessionAction.list) {
        _handles.removeWhere((_, owner) => !live.any((item) => identical(item.owner, owner)));
        final rows = <Map<String, Object>>[];
        for (final item in live) {
          var handle = _handles.entries.where((e) => identical(e.value, item.owner)).firstOrNull?.key;
          if (handle == null) {
            do {
              handle = _id();
            } while (_handles.containsKey(handle));
            _handles[handle] = item.owner;
          }
          rows.add({'id': handle, 'title': _title(item.title), 'audible': item.audible});
        }
        _reply(id, GameSessionControlStatus.ok, rows);
      } else {
        final owner = _handles[target];
        final item = live.where((item) => identical(item.owner, owner)).firstOrNull;
        if (owner == null || item == null) {
          _reply(id, GameSessionControlStatus.unavailable);
          return;
        }
        if (!current()) return;
        final submitted = await Future.sync(() => item.execute(action)).timeout(const Duration(seconds: 5));
        if (current()) {
          _reply(id, submitted ? GameSessionControlStatus.submitted : GameSessionControlStatus.unavailable);
        }
      }
    } catch (_) {
      if (current()) _reply(id, GameSessionControlStatus.unavailable);
    } finally {
      if (_generation == generation) _serving = false;
    }
  }

  void _reply(String id, GameSessionControlStatus status, [List<Map<String, Object>>? sessions]) {
    if (_closed) return;
    try {
      send({'version': 1, 'op': 'result', 'request': id, 'status': status.name, 'sessions': ?sessions});
    } catch (_) {
      /* A retired transport must not escape its async handler. */
    }
  }

  void _finish(GameSessionControlReply reply) {
    final pending = _pending;
    _pending = null;
    _request = null;
    _requestedAction = null;
    _timeout?.cancel();
    _timeout = null;
    pending?.complete(reply);
  }

  void reset() {
    _generation++;
    _serving = false;
    _lastList = null;
    _lastAction = null;
    _handles.clear();
    _seen.clear();
    _finish(const GameSessionControlReply(GameSessionControlStatus.unavailable));
  }

  void close() {
    _closed = true;
    reset();
  }
}
