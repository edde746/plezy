import 'package:flutter/widgets.dart';

import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../utils/global_key_utils.dart';
import '../utils/provider_extensions.dart';

/// Shared helpers for screens bound to a single [PlexMetadata] item/server.
mixin ServerBoundMediaMixin<T extends StatefulWidget> on State<T> {
  PlexMetadata get serverBoundMetadata;

  bool get isServerBoundOffline => false;

  String? get serverBoundServerId => serverBoundMetadata.serverId;

  String toServerBoundGlobalKey(String ratingKey, {String? serverId}) =>
      buildGlobalKey(serverId ?? serverBoundServerId ?? '', ratingKey);

  PlexClient? getServerBoundClient(BuildContext context) =>
      context.getClientForMetadataOrNull(serverBoundMetadata, isOffline: isServerBoundOffline);
}
