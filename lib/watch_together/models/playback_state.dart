import 'package:collection/collection.dart';

import 'watch_session.dart';

/// Playback lifecycle phase broadcast by the host.
///
/// Serialized as the enum index — append new values only.
enum PlaybackPhase { loading, waitingForPeers, paused, playing }

/// What caused a state transition (drives participant toasts).
///
/// Serialized as the enum index — append new values only.
enum PlaybackActionHint { play, pause, seek, rate, mediaSwitch }

/// Authoritative playback state, broadcast by the host on every transition
/// and as the periodic heartbeat. Receivers keep the highest [seq] seen and
/// drop anything older, so missed or reordered messages self-heal on the
/// next broadcast.
///
/// A `phase == playing` state whose [anchorHostTimeMs] lies in the future is
/// a scheduled group start: [targetPositionMs] clamps elapsed time to >= 0,
/// so peers hold at [anchorPositionMs] until the start moment and then
/// extrapolate from a shared origin.
class PlaybackState {
  final int seq;
  final String ratingKey;
  final String serverId;
  final String? mediaTitle;
  final PlaybackPhase phase;

  /// Timeline-adjusted position at [anchorHostTimeMs].
  final int anchorPositionMs;

  /// Host wall-clock time (Unix ms) the anchor was captured — or, when in
  /// the future with `phase == playing`, the scheduled group-start moment.
  final int anchorHostTimeMs;

  final double rate;
  final ControlMode controlMode;

  /// Peers the room is currently waiting on (readiness or buffering).
  final List<String> waitingOn;

  /// Peer that caused this transition (host's own id for local actions).
  final String? actorPeerId;
  final PlaybackActionHint? actionHint;

  const PlaybackState({
    required this.seq,
    required this.ratingKey,
    required this.serverId,
    required this.phase,
    required this.anchorPositionMs,
    required this.anchorHostTimeMs,
    required this.rate,
    required this.controlMode,
    this.mediaTitle,
    this.waitingOn = const [],
    this.actorPeerId,
    this.actionHint,
  });

  String get mediaKey => mediaKeyFor(ratingKey: ratingKey, serverId: serverId);

  static String mediaKeyFor({required String ratingKey, required String serverId}) => '$serverId:$ratingKey';

  /// Where the room should be at [nowHostMs] (host clock).
  int targetPositionMs(int nowHostMs) {
    if (phase != PlaybackPhase.playing) return anchorPositionMs;
    final elapsed = nowHostMs - anchorHostTimeMs;
    if (elapsed <= 0) return anchorPositionMs;
    return anchorPositionMs + (elapsed * rate).round();
  }

  PlaybackState copyWith({
    int? seq,
    String? ratingKey,
    String? serverId,
    String? mediaTitle,
    PlaybackPhase? phase,
    int? anchorPositionMs,
    int? anchorHostTimeMs,
    double? rate,
    ControlMode? controlMode,
    List<String>? waitingOn,
    String? actorPeerId,
    PlaybackActionHint? actionHint,
  }) {
    return PlaybackState(
      seq: seq ?? this.seq,
      ratingKey: ratingKey ?? this.ratingKey,
      serverId: serverId ?? this.serverId,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      phase: phase ?? this.phase,
      anchorPositionMs: anchorPositionMs ?? this.anchorPositionMs,
      anchorHostTimeMs: anchorHostTimeMs ?? this.anchorHostTimeMs,
      rate: rate ?? this.rate,
      controlMode: controlMode ?? this.controlMode,
      waitingOn: waitingOn ?? this.waitingOn,
      actorPeerId: actorPeerId ?? this.actorPeerId,
      actionHint: actionHint ?? this.actionHint,
    );
  }

  Map<String, dynamic> toMap() => {
    'q': seq,
    'rk': ratingKey,
    'sid': serverId,
    if (mediaTitle != null) 'ti': mediaTitle,
    'ph': phase.index,
    'ap': anchorPositionMs,
    'at': anchorHostTimeMs,
    'r': rate,
    'cm': controlMode.index,
    if (waitingOn.isNotEmpty) 'w': waitingOn,
    if (actorPeerId != null) 'ab': actorPeerId,
    if (actionHint != null) 'ah': actionHint!.index,
  };

  factory PlaybackState.fromMap(Map<String, dynamic> map) {
    return PlaybackState(
      seq: map['q'] as int,
      ratingKey: map['rk'] as String,
      serverId: map['sid'] as String,
      mediaTitle: map['ti'] as String?,
      phase: _enumFromIndex(PlaybackPhase.values, map['ph'] as int) ?? PlaybackPhase.paused,
      anchorPositionMs: map['ap'] as int,
      anchorHostTimeMs: map['at'] as int,
      rate: (map['r'] as num).toDouble(),
      controlMode: _enumFromIndex(ControlMode.values, map['cm'] as int) ?? ControlMode.hostOnly,
      waitingOn: (map['w'] as List?)?.cast<String>() ?? const [],
      actorPeerId: map['ab'] as String?,
      actionHint: map['ah'] != null ? _enumFromIndex(PlaybackActionHint.values, map['ah'] as int) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlaybackState &&
      other.seq == seq &&
      other.ratingKey == ratingKey &&
      other.serverId == serverId &&
      other.mediaTitle == mediaTitle &&
      other.phase == phase &&
      other.anchorPositionMs == anchorPositionMs &&
      other.anchorHostTimeMs == anchorHostTimeMs &&
      other.rate == rate &&
      other.controlMode == controlMode &&
      const ListEquality<String>().equals(other.waitingOn, waitingOn) &&
      other.actorPeerId == actorPeerId &&
      other.actionHint == actionHint;

  @override
  int get hashCode => Object.hash(
    seq,
    ratingKey,
    serverId,
    mediaTitle,
    phase,
    anchorPositionMs,
    anchorHostTimeMs,
    rate,
    controlMode,
    Object.hashAll(waitingOn),
    actorPeerId,
    actionHint,
  );

  @override
  String toString() =>
      'PlaybackState(seq: $seq, media: $mediaKey, phase: ${phase.name}, '
      'anchor: ${anchorPositionMs}ms@$anchorHostTimeMs, rate: $rate, waitingOn: $waitingOn)';
}

/// A peer's report of its own player to the host.
class PeerStatus {
  /// The media this peer currently has loaded or is loading.
  final String mediaKey;

  /// File loaded and first frame rendered (plus startup gates cleared).
  final bool ready;
  final bool buffering;
  final int positionMs;

  /// The peer's measured min RTT to the host (sizes scheduled-start delays).
  final int? rttMs;

  const PeerStatus({
    required this.mediaKey,
    required this.ready,
    required this.buffering,
    required this.positionMs,
    this.rttMs,
  });

  Map<String, dynamic> toMap() => {
    'mk': mediaKey,
    'rdy': ready,
    'buf': buffering,
    'pos': positionMs,
    if (rttMs != null) 'rtt': rttMs,
  };

  factory PeerStatus.fromMap(Map<String, dynamic> map) => PeerStatus(
    mediaKey: map['mk'] as String,
    ready: map['rdy'] as bool,
    buffering: map['buf'] as bool,
    positionMs: map['pos'] as int,
    rttMs: map['rtt'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is PeerStatus &&
      other.mediaKey == mediaKey &&
      other.ready == ready &&
      other.buffering == buffering &&
      other.positionMs == positionMs &&
      other.rttMs == rttMs;

  @override
  int get hashCode => Object.hash(mediaKey, ready, buffering, positionMs, rttMs);

  @override
  String toString() => 'PeerStatus($mediaKey, ready: $ready, buffering: $buffering, pos: ${positionMs}ms)';
}

/// Serialized as the enum index — append new values only.
enum ControlRequestKind { play, pause, seek, rate }

/// A guest's request for the host to apply a playback action (anyone mode).
class ControlRequest {
  final ControlRequestKind kind;
  final int? positionMs;
  final double? rate;

  const ControlRequest({required this.kind, this.positionMs, this.rate});

  Map<String, dynamic> toMap() => {
    'k': kind.index,
    if (positionMs != null) 'pos': positionMs,
    if (rate != null) 'r': rate,
  };

  factory ControlRequest.fromMap(Map<String, dynamic> map) => ControlRequest(
    kind: _enumFromIndex(ControlRequestKind.values, map['k'] as int) ?? ControlRequestKind.pause,
    positionMs: map['pos'] as int?,
    rate: (map['r'] as num?)?.toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is ControlRequest && other.kind == kind && other.positionMs == positionMs && other.rate == rate;

  @override
  int get hashCode => Object.hash(kind, positionMs, rate);

  @override
  String toString() => 'ControlRequest(${kind.name}, pos: $positionMs, rate: $rate)';
}

/// Index-safe enum decode: out-of-range values (from a newer protocol
/// version) return null instead of throwing.
T? _enumFromIndex<T extends Enum>(List<T> values, int index) =>
    index >= 0 && index < values.length ? values[index] : null;
