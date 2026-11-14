import '../music_assistant/music_assistant_players.dart';

/// Where audio comes out.
///
/// The app has never had this concept: it registered a builtin player with
/// Music Assistant and addressed nothing else, so "where" was always "the
/// phone". A [MusicOutput] is either that phone or one of the players a Music
/// Assistant server is willing to drive — a Sonos room, a Sonos group, another
/// device's builtin player.
class MusicOutput {
  /// Stable id, unique across servers.
  ///
  /// [thisDeviceId] for the local player; otherwise `<serverId>|<playerId>`,
  /// because a Music Assistant `player_id` is only meaningful inside the
  /// server that minted it and two paired servers can both hold a `RINCON_…`.
  final String id;

  final String name;

  /// Null for [thisDevice]; the Music Assistant server that owns the player
  /// otherwise.
  final String? serverId;

  /// Null for [thisDevice]; doubles as the queue id for every
  /// `player_queues/*` call.
  final String? playerId;

  /// Whether this output can be played to right now.
  final bool available;

  /// Why not, when [available] is false — shown to the user rather than
  /// swallowed. "The Sonos room is busy" is a designed-for failure mode, and a
  /// room that silently disappears from the list reads as a bug.
  final String? unavailableReason;

  final bool supportsVolume;
  final bool supportsSeek;
  final bool supportsNextPrevious;

  /// 0–100 as the server last reported it; null for [thisDevice], whose volume
  /// the local session owns.
  final int? volume;

  /// True when this is a Sonos (or other) group rather than a single room.
  final bool isGroup;

  const MusicOutput({
    required this.id,
    required this.name,
    required this.available,
    this.serverId,
    this.playerId,
    this.unavailableReason,
    this.supportsVolume = true,
    this.supportsSeek = true,
    this.supportsNextPrevious = true,
    this.volume,
    this.isGroup = false,
  });

  /// Sentinel id for the phone/tablet the app is running on.
  static const String thisDeviceId = 'this-device';

  /// The local player — today's behaviour, unchanged.
  static const MusicOutput thisDevice = MusicOutput(id: thisDeviceId, name: 'This device', available: true);

  bool get isThisDevice => id == thisDeviceId;

  /// True when playback happens on a server rather than in this process.
  bool get isRemote => !isThisDevice;

  /// Build from a Music Assistant player.
  ///
  /// [serverId] is threaded in rather than read off the player because the
  /// wire object does not carry it — the server is implied by which socket
  /// answered.
  factory MusicOutput.fromPlayer(MaPlayer player, {required String serverId}) {
    final busySource = player.hasForeignSource ? player.activeSource : null;
    // Availability is the server's word, and a foreign source is a *reason*
    // rather than a second verdict: a Sonos playing Spotify still reports
    // available on 2.6.3, and taking it over is a legitimate thing to do
    // deliberately. What is not legitimate is doing it without saying so.
    return MusicOutput(
      id: '$serverId|${player.playerId}',
      name: player.name,
      serverId: serverId,
      playerId: player.playerId,
      available: player.available,
      unavailableReason: !player.available
          ? (busySource != null ? 'In use by $busySource' : 'Unavailable')
          : (busySource != null ? 'Playing $busySource' : null),
      supportsVolume: player.supportsVolume,
      supportsSeek: player.supportsSeek,
      supportsNextPrevious: player.supportsNextPrevious,
      volume: player.volumeLevel,
      isGroup: player.isGroup,
    );
  }

  MusicOutput copyWith({bool? available, String? unavailableReason, int? volume}) => MusicOutput(
    id: id,
    name: name,
    serverId: serverId,
    playerId: playerId,
    available: available ?? this.available,
    unavailableReason: unavailableReason ?? this.unavailableReason,
    supportsVolume: supportsVolume,
    supportsSeek: supportsSeek,
    supportsNextPrevious: supportsNextPrevious,
    volume: volume ?? this.volume,
    isGroup: isGroup,
  );

  @override
  bool operator ==(Object other) => other is MusicOutput && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MusicOutput($id, $name, available: $available)';
}
