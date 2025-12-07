import 'package:flutter/material.dart';
import '../services/plex_client.dart';
import '../services/play_queue_launcher.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';

/// Helper function to play a collection or playlist.
///
/// This is a convenience wrapper around [PlayQueueLauncher.launchFromCollectionOrPlaylist].
Future<void> playCollectionOrPlaylist({
  required BuildContext context,
  required PlexClient client,
  required dynamic item, // PlexMetadata (collection) or PlexPlaylist
  required bool shuffle,
}) async {
  final launcher = PlayQueueLauncher(
    context: context,
    client: client,
    serverId: item is PlexMetadata
        ? item.serverId
        : (item as PlexPlaylist).serverId,
    serverName: item is PlexMetadata
        ? item.serverName
        : (item as PlexPlaylist).serverName,
  );

  await launcher.launchFromCollectionOrPlaylist(
    item: item,
    shuffle: shuffle,
    showLoadingIndicator: false, // Caller typically handles loading UI
  );
}
