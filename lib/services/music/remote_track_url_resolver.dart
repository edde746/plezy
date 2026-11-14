import '../../database/app_database.dart';
import '../../media/ids.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../models/audio_quality_preset.dart';
import '../../models/transcode_quality_preset.dart';
import '../../utils/session_identifier.dart';
import '../multi_server_manager.dart';
import '../music_assistant_client.dart';
import '../playback_initialization_service.dart';

/// What to hand Music Assistant so it can fetch a track itself.
class RemoteTrackMedia {
  /// Either an `http(s)://…` URL or a Music Assistant `uri`.
  final String value;

  /// True when [value] is a Music Assistant uri rather than a URL, which
  /// happens only when the track came from the same Music Assistant server
  /// that owns the target player.
  final bool isNativeUri;

  const RemoteTrackMedia(this.value, {this.isNativeUri = false});
}

/// Turns a track into something a *server* can fetch.
///
/// Separate from [MusicSourceResolver] because the constraints are different
/// in one decisive way: **Music Assistant cannot send custom HTTP headers.**
/// The local engine gets a URL plus Plex identity headers and opens it itself;
/// a Sonos is handed a bare URL and nothing else, so the URL has to
/// self-authenticate. Plex's `?X-Plex-Token=` query parameter does, which is
/// why a bare Plex URL plays on a Sonos with no matching, no resolver and no
/// second index — verified on real hardware.
abstract class RemoteTrackUrlResolver {
  Future<RemoteTrackMedia> resolve(MediaItem track, {required String? targetServerId});
}

/// Production resolver.
///
/// ### Why this always asks for the original file
///
/// [ServerMusicSourceResolver] honours the user's music quality preset, which
/// is right for the phone: it is the thing with the small screen and the
/// metered connection. A speaker on the LAN is neither, and a transcode would
/// cost twice — Plex would open a transcode session that needs keep-alive
/// pings this code is in no position to send, and the speaker would get a
/// worse file than the one sitting on the NAS. Sonos plays FLAC natively.
class ServerRemoteTrackUrlResolver implements RemoteTrackUrlResolver {
  ServerRemoteTrackUrlResolver({required this.serverManager, required this.database});

  final MultiServerManager serverManager;
  final AppDatabase database;

  @override
  Future<RemoteTrackMedia> resolve(MediaItem track, {required String? targetServerId}) async {
    // A Music Assistant track playing to a player on its own server needs no
    // URL at all: the server already knows the item, and handing it the uri
    // lets it pick its own provider, its own transcode and its own gapless
    // path. Sending a stream URL back to the server that minted it would make
    // Music Assistant fetch from itself.
    final native = _nativeUri(track, targetServerId);
    if (native != null) return RemoteTrackMedia(native, isNativeUri: true);

    final serverId = serverIdOrNull(track.serverId);
    final client = serverId == null ? null : serverManager.getClient(serverId);
    if (client == null) {
      throw PlaybackException('No server for ${track.title ?? track.id}');
    }
    // Straight to the server rather than through PlaybackSourceResolver,
    // which prefers a downloaded copy at original quality: that copy is a
    // `file://` path on *this* device, which a speaker cannot open.
    final result = await PlaybackInitializationService(client: client, database: database).getPlaybackData(
      PlaybackInitializationOptions(
        metadata: track,
        selectedMediaIndex: 0,
        qualityPreset: TranscodeQualityPreset.original,
        audioQualityPreset: AudioQualityPreset.original,
        sessionIdentifier: generateSessionIdentifier(),
        transcodeSessionId: generateSessionIdentifier(),
      ),
    );

    final url = result.videoUrl;
    if (url == null) {
      throw PlaybackException('No streamable URL for ${track.title ?? track.id}');
    }
    if (url.startsWith('file:')) {
      throw PlaybackException('${track.title ?? track.id} is only available on this device');
    }
    return RemoteTrackMedia(url);
  }

  String? _nativeUri(MediaItem track, String? targetServerId) {
    if (track.backend != MediaBackend.musicAssistant) return null;
    if (targetServerId == null) return null;
    final trackServer = serverIdOrNull(track.serverId);
    if (trackServer == null || trackServer.value != targetServerId) return null;
    final client = serverManager.getClient(trackServer);
    if (client is! MusicAssistantClient) return null;
    // A Music Assistant item's `MediaItem.id` is its Music Assistant uri.
    final uri = track.id;
    return uri.isEmpty ? null : uri;
  }
}
