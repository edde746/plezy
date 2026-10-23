import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:web_socket/testing.dart';
import 'package:web_socket/web_socket.dart';

/// An Open Watch Party relay inside the test (SPEC.md §7, §12), holding one
/// room. It answers enough of the protocol for parties to create and join
/// the room, share and clear media, play, pause, seek, change the rate,
/// report status, hand over the host, kick, lock, end and leave. The
/// readiness barrier releases as soon as every counted participant is ready,
/// at once (no start delay), and no barrier or end-of-media timer runs, so a
/// widget test has no relay timers to drain.
///
/// Pass [party] as a `WatchTogetherProvider`'s `partyFactory`. Relay time is
/// [clock]'s, so `fakeAsync` and `testWidgets` drive it.
final class FakeOwpRelay {
  FakeOwpRelay() : _stopwatch = clock.stopwatch()..start();

  final Stopwatch _stopwatch;
  int nowMs() => _stopwatch.elapsedMilliseconds;

  static const String code = 'K7MQ2X';

  /// The room's code: [code] until a join with `create` makes the room again
  /// under the code that join names (SPEC.md §7.2).
  String get roomCode => _roomCode;
  var _roomCode = code;

  /// Every client message but pings, with its sender's peer ID (null before
  /// it joined), in order.
  final List<({String? from, Map<String, Object?> message})> received = [];

  List<Map<String, Object?>> sent(String type) => [
    for (final entry in received)
      if (entry.message['type'] == type) entry.message,
  ];

  final List<_Member> _members = [];
  var _nextPeer = 1;
  var _rev = 0;
  var _epoch = 0;
  var _phase = 'idle';
  var _positionMs = 0;
  var _atMs = 0;
  double _rate = 1;
  var _control = 'host';
  var _locked = false;
  Map<String, Object?>? _media;
  List<String> _waitingOn = const [];
  var _open = true;

  /// When set, the relay refuses every join with this error code, as a full
  /// room (`room_full`) or a busy relay (`relay_full`) would.
  String? refuseJoins;

  /// While true the relay leaves joins unanswered, as a slow relay would;
  /// [releaseJoins] answers the held ones.
  bool holdJoins = false;
  final List<(_Connection, Map<String, Object?>)> _heldJoins = [];

  /// Stops holding joins and answers the held ones whose client is still
  /// connected.
  void releaseJoins() {
    holdJoins = false;
    final held = [..._heldJoins];
    _heldJoins.clear();
    for (final (conn, message) in held) {
      if (!conn.closed) _join(conn, message);
    }
  }

  /// Resumes (SDK.md §7.3) wait unanswered until [allowResumes], so a party
  /// [drop]ped stays reconnecting until the test lets it back.
  bool _resumesAllowed = false;
  final List<(_Connection, Map<String, Object?>)> _heldResumes = [];

  /// Answers the waiting resumes, and every later one, as a reachable relay
  /// does: the participant is connected again.
  void allowResumes() {
    _resumesAllowed = true;
    final held = [..._heldResumes];
    _heldResumes.clear();
    for (final (conn, message) in held) {
      if (!conn.closed) _resume(conn, message);
    }
  }

  String get phase => _phase;
  int get epoch => _epoch;
  Map<String, Object?>? get media => _media;
  List<String> get peerIds => [for (final m in _members) m.peerId];

  /// A party of `WatchTogetherProvider`'s factory shape that reaches this relay.
  owp.WatchParty<WatchCopy> party({
    required owp.Relays relays,
    required String client,
    required String name,
    required owp.Resolver<WatchCopy>? resolver,
  }) => owp.WatchParty<WatchCopy>(
    relays: owp.Relays.at('http://relay.test'),
    client: client,
    name: name,
    resolver: resolver,
    connect: connect,
    nowMs: nowMs,
  );

  Future<WebSocket> connect(Uri url) async {
    final (client, server) = fakes();
    final conn = _Connection(server);
    server.events.listen((event) {
      switch (event) {
        case TextDataReceived(:final text):
          _onText(conn, text);
        case CloseReceived():
          conn.closed = true;
          final member = _members.where((m) => identical(m.conn, conn)).firstOrNull;
          if (member != null && member.connected) {
            member.connected = false;
            _broadcast();
          }
        default:
      }
    });
    return client;
  }

  /// Drops [peerId]'s connection without a status, as a network loss would.
  void drop(String peerId) {
    final member = _member(peerId);
    if (member == null) return;
    member.conn.closed = true;
    unawaited(member.conn.socket.close());
    member.connected = false;
    _broadcast();
  }

  void _onText(_Connection conn, String text) {
    final message = (jsonDecode(text) as Map).cast<String, Object?>();
    final type = message['type'];
    if (type == 'ping') {
      Timer.run(() => conn.send({'type': 'pong', 'id': message['id'], 'serverTime': nowMs()}));
      return;
    }
    final me = _members.where((m) => identical(m.conn, conn)).firstOrNull;
    received.add((from: me?.peerId, message: message));
    switch (type) {
      case 'create':
        if (me != null || _members.isNotEmpty) return _refuse(conn, 'create', 'rate_limited');
        _add(conn, message, host: true);
      case 'join':
        if (me != null) return;
        if (holdJoins) return _heldJoins.add((conn, message));
        _join(conn, message);
      case 'resume':
        if (me != null) return;
        if (!_resumesAllowed) return _heldResumes.add((conn, message));
        _resume(conn, message);
      case 'leave':
        if (me == null) return;
        _remove(me);
        _broadcast();
      case 'status':
        if (me == null) return;
        me
          ..statusEpoch = message['epoch'] as int
          ..player = message['player'] as String
          ..match = (message['match'] as Map?)?.cast<String, Object?>()
          ..offsetMs = message['offsetMs'] as int;
        _peerEvent();
        _broadcast();
      default:
        if (me == null) return;
        _command(me, type as String?, message);
    }
  }

  void _join(_Connection conn, Map<String, Object?> message) {
    if (refuseJoins case final refusal?) return _refuse(conn, 'join', refusal);
    if (message['create'] == true && _members.isEmpty) _makeRoom(message['code']! as String);
    if (!_open || message['code'] != _roomCode) return _refuse(conn, 'join', 'room_not_found');
    if (_locked) return _refuse(conn, 'join', 'room_locked');
    _add(conn, message, host: false);
    _broadcast(except: _members.last);
  }

  /// SPEC.md §7.2, §9.3: a join with `create` makes a new room with its code.
  /// The relay holds one room, so it does that only while nobody is in it.
  void _makeRoom(String roomCode) {
    _roomCode = roomCode;
    _open = true;
    _rev = 0;
    _epoch = 0;
    _phase = 'idle';
    _positionMs = 0;
    _atMs = nowMs();
    _rate = 1;
    _control = 'host';
    _locked = false;
    _media = null;
    _waitingOn = const [];
  }

  void _resume(_Connection conn, Map<String, Object?> message) {
    final member = _member(message['peerId'] as String?);
    if (!_open || message['code'] != _roomCode || member == null || message['token'] != _token(member)) {
      return _refuse(conn, 'resume', 'resume_failed');
    }
    member
      ..conn = conn
      ..connected = true;
    _rev++;
    _sendJoined(member);
    _broadcast(except: member);
  }

  void _command(_Member me, String? type, Map<String, Object?> message) {
    final hostOnly = const {'setMedia', 'clearMedia', 'setControl', 'transferHost', 'kick', 'lock', 'end'};
    if (hostOnly.contains(type) && !me.host) return _refuse(me.conn, type!, 'forbidden');
    if (const {'play', 'pause', 'seek', 'rate'}.contains(type)) {
      if (!me.host && _control != 'everyone') return _refuse(me.conn, type!, 'forbidden');
      if (_media == null) return _refuse(me.conn, type!, 'invalid_message');
    }
    Map<String, Object?>? action(String kind) => {'kind': kind, 'by': me.peerId};
    switch (type) {
      case 'setMedia':
        _epoch++;
        _media = (message['media']! as Map).cast<String, Object?>();
        _positionMs = math.min((message['positionMs'] as int?) ?? 0, _durationMs);
        _enterWaiting(_positionMs);
        _broadcast(action: action('media'), withMedia: true);
      case 'clearMedia':
        if (_media == null) return;
        _epoch++;
        _media = null;
        _phase = 'idle';
        _positionMs = 0;
        _waitingOn = const [];
        _broadcast(action: action('media'), withMedia: true);
      case 'play':
        if (_phase != 'paused') return;
        _enterWaiting(_positionMs);
        _broadcast(action: action('play'));
      case 'pause':
        if (_phase == 'paused') return;
        final now = _position();
        final at = message['positionMs'] as int?;
        _phase = 'paused';
        _positionMs = at != null && (at - now).abs() <= 2000 ? math.min(at, _durationMs) : now;
        _waitingOn = const [];
        _broadcast(action: action('pause'));
      case 'seek':
        final target = math.min(message['positionMs']! as int, _durationMs);
        if (_phase == 'paused') {
          _positionMs = target;
        } else {
          _enterWaiting(target);
        }
        _broadcast(action: action('seek'));
      case 'rate':
        if (_phase == 'playing' && nowMs() >= _atMs) {
          _positionMs = _position();
          _atMs = nowMs();
        }
        _rate = (message['rate']! as num).toDouble();
        _broadcast(action: action('rate'));
      case 'setControl':
        _control = message['mode']! as String;
        _broadcast();
      case 'lock':
        _locked = message['locked']! as bool;
        _broadcast();
      case 'transferHost':
        final target = _member(message['peerId'] as String?);
        if (target == null) return _refuse(me.conn, 'transferHost', 'invalid_message');
        if (target.host) return;
        me.host = false;
        target.host = true;
        _broadcast(action: action('host'));
      case 'kick':
        final target = _member(message['peerId'] as String?);
        if (target == null) return _refuse(me.conn, 'kick', 'invalid_message');
        target.conn.send({'type': 'closed', 'reason': 'kicked'});
        _remove(target);
        _broadcast();
      case 'end':
        for (final member in _members) {
          member.conn.send({'type': 'closed', 'reason': 'ended'});
        }
        _members.clear();
        _open = false;
    }
  }

  int get _durationMs => (_media?['durationMs'] as int?) ?? 0;

  int _position() {
    if (_phase != 'playing') return _positionMs;
    final elapsed = math.max(0, nowMs() - _atMs);
    return math.min(_durationMs, (_positionMs + elapsed * _rate).floor());
  }

  void _add(_Connection conn, Map<String, Object?> message, {required bool host}) {
    final member = _Member(conn, 'p${_nextPeer++}', message['name']! as String, message['client']! as String)
      ..host = host || !_members.any((m) => m.host);
    _members.add(member);
    _rev++;
    _sendJoined(member);
  }

  String _token(_Member member) => 'token-${member.peerId}'.padRight(43, 'x');

  void _sendJoined(_Member member) => member.conn.send({
    'type': 'joined',
    'code': _roomCode,
    'you': {'peerId': member.peerId, 'token': _token(member)},
    'room': _snapshot(),
    'media': _media,
    'serverTime': nowMs(),
  });

  void _remove(_Member member) {
    _members.remove(member);
    if (member.host && _members.isNotEmpty) _members.first.host = true;
    if (_members.isEmpty) _open = false;
    _peerEvent();
  }

  void _enterWaiting(int positionMs) {
    _phase = 'waiting';
    _positionMs = positionMs;
    _recomputeWaiting();
  }

  /// SDK.md §12.3: a participant's player is `loading` until it reports on
  /// the room's epoch.
  String _effective(_Member m) => m.statusEpoch == _epoch ? m.player : 'loading';

  void _recomputeWaiting() {
    _waitingOn = [
      for (final m in _members)
        if (m.connected &&
            _effective(m) != 'idle' &&
            !(m.statusEpoch == _epoch && m.match?['state'] == 'unavailable') &&
            !(m.statusEpoch == _epoch && m.player == 'ready'))
          m.peerId,
    ];
    if (_waitingOn.isEmpty) {
      _phase = 'playing';
      _atMs = nowMs();
    }
  }

  /// SDK.md §12.5, without the stall grace.
  void _peerEvent() {
    if ((_phase == 'playing' || _phase == 'waiting') && !_members.any((m) => m.connected && _effective(m) != 'idle')) {
      _positionMs = _position();
      _phase = 'paused';
      _waitingOn = const [];
      return;
    }
    if (_phase == 'waiting') _recomputeWaiting();
  }

  void _refuse(_Connection conn, String re, String code) =>
      conn.send({'type': 'error', 'code': code, 'message': code, 're': re});

  _Member? _member(String? peerId) => _members.where((m) => m.peerId == peerId).firstOrNull;

  Map<String, Object?> _snapshot() => {
    'rev': _rev,
    'code': _roomCode,
    'epoch': _epoch,
    'phase': _phase,
    'positionMs': _positionMs,
    'atMs': _atMs,
    'rate': _rate,
    'control': _control,
    'locked': _locked,
    'waitingOn': _waitingOn,
    'participants': [
      for (final m in _members)
        {
          'peerId': m.peerId,
          'name': m.name,
          'client': m.client,
          'host': m.host,
          'connected': m.connected,
          'player': m.player,
          'match': m.match,
          'offsetMs': m.offsetMs,
        },
    ],
  };

  void _broadcast({Map<String, Object?>? action, bool withMedia = false, _Member? except}) {
    _rev++;
    final message = {'type': 'room', ..._snapshot(), 'action': ?action, if (withMedia) 'media': _media};
    for (final member in _members) {
      if (!identical(member, except) && member.connected) member.conn.send(message);
    }
  }
}

final class _Connection {
  _Connection(this.socket);

  final WebSocket socket;
  var closed = false;

  void send(Map<String, Object?> message) {
    if (closed) return;
    try {
      socket.sendText(jsonEncode(message));
    } on WebSocketConnectionClosed {
      // The client closed its end; its close event is still on the way.
      closed = true;
    }
  }
}

final class _Member {
  _Member(this.conn, this.peerId, this.name, this.client);

  _Connection conn;
  final String peerId;
  final String name;
  final String client;
  var host = false;
  var connected = true;
  var player = 'idle';
  Map<String, Object?>? match;
  var offsetMs = 0;
  var statusEpoch = -1;
}
