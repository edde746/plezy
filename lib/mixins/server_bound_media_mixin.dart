import 'package:flutter/widgets.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../services/plex_client.dart';
import '../utils/global_key_utils.dart';
import '../utils/provider_extensions.dart';

/// Shared helpers for screens bound to a single [MediaItem]/server.
mixin ServerBoundMediaMixin<T extends StatefulWidget> on State<T> {
  MediaItem get serverBoundMetadata;

  bool get isServerBoundOffline => false;

  String? get serverBoundServerId => serverBoundMetadata.serverId;

  String toServerBoundGlobalKey(String ratingKey, {String? serverId}) =>
      buildGlobalKey(serverId ?? serverBoundServerId ?? '', ratingKey);

  /// Returns the [PlexClient] for the bound server, or null when offline /
  /// the server is Jellyfin / not registered. Use [getServerBoundMediaClient]
  /// for backend-neutral flows.
  PlexClient? getServerBoundPlexClient(BuildContext context) {
    if (isServerBoundOffline) return null;
    return context.tryGetPlexClientForServer(serverBoundMetadata.serverId);
  }

  /// Returns a backend-neutral [MediaServerClient] for the bound server, or
  /// null when offline / not registered.
  MediaServerClient? getServerBoundMediaClient(BuildContext context) =>
      context.getMediaClientForItemOrNull(serverBoundMetadata, isOffline: isServerBoundOffline);
}
