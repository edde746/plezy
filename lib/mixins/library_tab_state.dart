import 'package:flutter/material.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../services/plex_client.dart';
import '../utils/provider_extensions.dart';

/// Mixin providing common functionality for library tab screens
/// Provides server-specific client resolution for multi-server support
mixin LibraryTabStateMixin<T extends StatefulWidget> on State<T> {
  /// The library being displayed
  MediaLibrary get library;

  /// Get the [PlexClient] for this library's server. Throws if unavailable.
  /// Use [getMediaClientForLibrary] in code paths that work for both Plex
  /// and Jellyfin via the [MediaServerClient] interface — this getter is
  /// for Plex-only methods (collections, metadata edit, etc.).
  PlexClient getClientForLibrary() => context.getPlexClientForLibrary(library);

  /// Get a backend-neutral [MediaServerClient] for this library's server.
  /// Throws if unavailable. Prefer this over [getClientForLibrary] for any
  /// flow that doesn't strictly need Plex-only APIs.
  MediaServerClient getMediaClientForLibrary() => context.getMediaClientForLibrary(library);
}
