import 'package:flutter/material.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../utils/provider_extensions.dart';

/// Mixin providing common functionality for library tab screens
/// Provides server-specific client resolution for multi-server support
mixin LibraryTabStateMixin<T extends StatefulWidget> on State<T> {
  MediaLibrary get library;

  /// Get a backend-neutral [MediaServerClient] for this library's server.
  /// Throws if unavailable.
  MediaServerClient getMediaClientForLibrary() => context.getMediaClientForLibrary(library);
}
