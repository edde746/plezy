import 'dart:convert';

import 'watch_session.dart';

/// Types of sync messages sent over the WebRTC data channel
enum SyncMessageType {
  /// Start playback
  play,

  /// Pause playback
  pause,

  /// Seek to position
  seek,

  /// Buffering state changed
  buffering,

  /// Periodic position update (for drift correction)
  positionSync,

  /// Playback rate changed
  rate,

  /// Participant joined the session
  join,

  /// Participant left the session
  leave,

  /// Session configuration (sent by host on join)
  sessionConfig,

  /// Ping for latency measurement
  ping,

  /// Pong response
  pong,

  /// Media switch (host changed content)
  mediaSwitch,

  /// Host exited the video player
  hostExitedPlayer,

  /// Player is ready (attached and loaded)
  playerReady,
}

/// A message sent over the WebRTC data channel for synchronization
class SyncMessage {
  /// Type of this message
  final SyncMessageType type;

  /// Timestamp when this message was created (Unix ms)
  final int timestamp;

  /// Position in milliseconds (for seek, positionSync)
  final int? positionMs;

  /// Buffering state (for buffering message)
  final bool? bufferingState;

  /// Playback rate (for rate message)
  final double? rate;

  /// Peer ID of the sender
  final String? peerId;

  /// Display name of the sender (for join message)
  final String? displayName;

  /// Whether the sender is the host (for join message)
  final bool? isHost;

  /// Control mode (for sessionConfig message)
  final ControlMode? controlMode;

  /// Ping ID for matching pong responses
  final int? pingId;

  /// Rating key of the media (for mediaSwitch message)
  final String? ratingKey;

  /// Server ID of the media (for mediaSwitch message)
  final String? serverId;

  /// Title of the media (for mediaSwitch message)
  final String? mediaTitle;

  /// Whether playback is currently playing (for positionSync heartbeat)
  final bool? isPlaying;

  const SyncMessage({
    required this.type,
    required this.timestamp,
    this.positionMs,
    this.bufferingState,
    this.rate,
    this.peerId,
    this.displayName,
    this.isHost,
    this.controlMode,
    this.pingId,
    this.ratingKey,
    this.serverId,
    this.mediaTitle,
    this.isPlaying,
  });

  /// Create a PLAY message
  factory SyncMessage.play({String? peerId, Duration? position}) {
    return SyncMessage(
      type: SyncMessageType.play,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      positionMs: position?.inMilliseconds,
    );
  }

  /// Create a PAUSE message
  factory SyncMessage.pause({String? peerId}) {
    return SyncMessage(type: SyncMessageType.pause, timestamp: DateTime.now().millisecondsSinceEpoch, peerId: peerId);
  }

  /// Create a SEEK message
  factory SyncMessage.seek(Duration position, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.seek,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      positionMs: position.inMilliseconds,
      peerId: peerId,
    );
  }

  /// Create a BUFFERING message
  factory SyncMessage.buffering(bool isBuffering, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.buffering,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      bufferingState: isBuffering,
      peerId: peerId,
    );
  }

  /// Create a POSITION_SYNC message (heartbeat with optional play/pause state)
  factory SyncMessage.positionSync(Duration position, {String? peerId, bool? isPlaying}) {
    return SyncMessage(
      type: SyncMessageType.positionSync,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      positionMs: position.inMilliseconds,
      peerId: peerId,
      isPlaying: isPlaying,
    );
  }

  /// Create a RATE message
  factory SyncMessage.rate(double playbackRate, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.rate,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      rate: playbackRate,
      peerId: peerId,
    );
  }

  /// Create a JOIN message
  factory SyncMessage.join({required String peerId, required String displayName, required bool isHost}) {
    return SyncMessage(
      type: SyncMessageType.join,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      displayName: displayName,
      isHost: isHost,
    );
  }

  /// Create a LEAVE message
  factory SyncMessage.leave({required String peerId}) {
    return SyncMessage(type: SyncMessageType.leave, timestamp: DateTime.now().millisecondsSinceEpoch, peerId: peerId);
  }

  /// Create a SESSION_CONFIG message (sent by host to new guests)
  factory SyncMessage.sessionConfig({
    required ControlMode controlMode,
    required Duration currentPosition,
    required bool isPlaying,
    required double playbackRate,
    String? peerId,
  }) {
    return SyncMessage(
      type: SyncMessageType.sessionConfig,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      controlMode: controlMode,
      positionMs: currentPosition.inMilliseconds,
      bufferingState: !isPlaying, // Reuse field: false = playing, true = paused
      rate: playbackRate,
      peerId: peerId,
    );
  }

  /// Create a PING message
  factory SyncMessage.ping(int pingId, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.ping,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pingId: pingId,
      peerId: peerId,
    );
  }

  /// Create a PONG message
  factory SyncMessage.pong(int pingId, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.pong,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pingId: pingId,
      peerId: peerId,
    );
  }

  /// Create a MEDIA_SWITCH message (sent by host when changing content)
  factory SyncMessage.mediaSwitch({
    required String ratingKey,
    required String serverId,
    required String mediaTitle,
    String? peerId,
  }) {
    return SyncMessage(
      type: SyncMessageType.mediaSwitch,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ratingKey: ratingKey,
      serverId: serverId,
      mediaTitle: mediaTitle,
      peerId: peerId,
    );
  }

  /// Create a HOST_EXITED_PLAYER message (sent by host when exiting video player)
  factory SyncMessage.hostExitedPlayer({String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.hostExitedPlayer,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
    );
  }

  /// Create a PLAYER_READY message (sent when player is attached and ready)
  factory SyncMessage.playerReady({required String peerId, required bool ready}) {
    return SyncMessage(
      type: SyncMessageType.playerReady,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      bufferingState: ready, // Reuse bufferingState field for ready status
    );
  }

  /// Position as Duration (convenience getter)
  Duration? get position => positionMs != null ? Duration(milliseconds: positionMs!) : null;

  /// Serialize to JSON string for sending over data channel
  String toJson() {
    final map = <String, dynamic>{'t': type.name, 'ts': timestamp};

    if (positionMs != null) map['pos'] = positionMs;
    if (bufferingState != null) map['buf'] = bufferingState;
    if (rate != null) map['r'] = rate;
    if (peerId != null) map['pid'] = peerId;
    if (displayName != null) map['name'] = displayName;
    if (isHost != null) map['host'] = isHost;
    if (controlMode != null) map['ctrl'] = controlMode!.index;
    if (pingId != null) map['ping'] = pingId;
    if (ratingKey != null) map['rk'] = ratingKey;
    if (serverId != null) map['sid'] = serverId;
    if (mediaTitle != null) map['title'] = mediaTitle;
    if (isPlaying != null) map['pl'] = isPlaying;

    return jsonEncode(map);
  }

  /// Parse from JSON string received from data channel
  factory SyncMessage.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    final typeString = map['t'] as String;
    final type = SyncMessageType.values.firstWhere(
      (t) => t.name == typeString,
      orElse: () => throw FormatException('Unknown message type: $typeString'),
    );

    return SyncMessage(
      type: type,
      timestamp: map['ts'] as int,
      positionMs: map['pos'] as int?,
      bufferingState: map['buf'] as bool?,
      rate: (map['r'] as num?)?.toDouble(),
      peerId: map['pid'] as String?,
      displayName: map['name'] as String?,
      isHost: map['host'] as bool?,
      controlMode: map['ctrl'] != null ? ControlMode.values[map['ctrl'] as int] : null,
      pingId: map['ping'] as int?,
      ratingKey: map['rk'] as String?,
      serverId: map['sid'] as String?,
      mediaTitle: map['title'] as String?,
      isPlaying: map['pl'] as bool?,
    );
  }

  @override
  String toString() {
    return 'SyncMessage(type: $type, timestamp: $timestamp, positionMs: $positionMs, '
        'bufferingState: $bufferingState, rate: $rate, peerId: $peerId)';
  }
}
