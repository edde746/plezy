import 'package:flutter/material.dart';
import '../services/plex_client.dart';
import '../models/plex_library.dart';
import '../utils/provider_extensions.dart';

/// Mixin providing common functionality for library tab screens
/// Provides server-specific client resolution for multi-server support
mixin LibraryTabStateMixin<T extends StatefulWidget> on State<T> {
  /// The library being displayed
  PlexLibrary get library;

  /// Get the correct PlexClient for this library's server
  /// Throws an exception if no client is available
  PlexClient getClientForLibrary() => context.getClientForLibrary(library);
}
