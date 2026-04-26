import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../media/media_item.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../media/media_server_user_profile.dart';
import '../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/user_profile_provider.dart';
import 'app_logger.dart';

extension ProviderExtensions on BuildContext {
  UserProfileProvider get userProfile => Provider.of<UserProfileProvider>(this, listen: false);

  HiddenLibrariesProvider get hiddenLibraries => Provider.of<HiddenLibrariesProvider>(this, listen: false);

  // Direct profile settings access (nullable)
  MediaServerUserProfile? get profileSettings => userProfile.profileSettings;

  /// Internal: resolve a [PlexClient] from a serverId or fall back to the
  /// first online server. Returns null if neither yields a Plex client.
  /// Non-Plex servers (Jellyfin) are skipped — these helpers exist for
  /// Plex-only flows that have no neutral equivalent (DVR tuning, metadata
  /// edit, match). Backend-agnostic flows use the [_resolveMediaClient]
  /// helpers below.
  PlexClient? _resolveClient(String? serverId) {
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    return _resolvePrioritized(serverId, provider.onlineServerIds, provider.getPlexClientForServer);
  }

  /// Internal: like [_resolveClient] but throws a localized exception when
  /// no client is available. The thrown message is the canonical
  /// `t.errors.noClientAvailable` so callers can surface it directly.
  PlexClient _requireClient(String? serverId, {bool fallback = true}) {
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    if (serverId != null) {
      final client = provider.getPlexClientForServer(serverId);
      if (client != null) return client;
      if (!fallback) {
        appLogger.e('No Plex client found for server $serverId');
        throw Exception(t.errors.noClientAvailable);
      }
    }
    final client = _resolveClient(null);
    if (client == null) {
      throw Exception(t.errors.noClientAvailable);
    }
    return client;
  }

  /// Get PlexClient for a specific server ID. Throws if unavailable.
  PlexClient getPlexClientForServer(String serverId) => _requireClient(serverId, fallback: false);

  /// Get PlexClient for a specific server ID, or null if unavailable.
  PlexClient? tryGetPlexClientForServer(String? serverId) {
    if (serverId == null) return null;
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    return provider.getPlexClientForServer(serverId);
  }

  /// Get PlexClient for a library, falling back to the first online server
  /// when the library has no serverId. Throws if no client is available.
  PlexClient getPlexClientForLibrary(MediaLibrary library) => _requireClient(library.serverId);

  /// Get client for a serverId, falling back to the first online server.
  /// Throws if no client is available.
  PlexClient getPlexClientWithFallback(String? serverId) => _requireClient(serverId);

  // ── Backend-neutral helpers ──────────────────────────────────────
  // These return [MediaServerClient] regardless of backend kind so callers
  // that consume only the [MediaServerClient] surface don't need to type-
  // check the result. Use [getPlexClientForServer] / [getPlexClientForLibrary]
  // when you specifically need a [PlexClient] (Plex-only flows like Live TV,
  // metadata editing, etc.).

  MediaServerClient? _resolveMediaClient(String? serverId) {
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    return _resolvePrioritized(serverId, provider.onlineServerIds, provider.getClientForServer);
  }

  /// Get a [MediaServerClient] for the given serverId, or null.
  MediaServerClient? tryGetMediaClientForServer(String? serverId) {
    if (serverId == null) return null;
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    return provider.getClientForServer(serverId);
  }

  /// Get a [MediaServerClient] for the given serverId. Throws when the
  /// server isn't registered or is offline. Mirrors the throwing variant of
  /// the Plex-typed [getPlexClientForServer] helpers.
  MediaServerClient getMediaClientForServer(String serverId) {
    final c = tryGetMediaClientForServer(serverId);
    if (c == null) throw Exception(t.errors.noClientAvailable);
    return c;
  }

  /// Get a [MediaServerClient] for [library], falling back to the first
  /// online server when the library has no serverId. Throws if none.
  MediaServerClient getMediaClientForLibrary(MediaLibrary library) {
    final c = _resolveMediaClient(library.serverId);
    if (c == null) throw Exception(t.errors.noClientAvailable);
    return c;
  }

  /// Get a [MediaServerClient] for a [MediaItem], or null in offline mode /
  /// when the server isn't online.
  MediaServerClient? getMediaClientForItemOrNull(MediaItem item, {bool isOffline = false}) {
    if (isOffline) return null;
    return tryGetMediaClientForServer(item.serverId);
  }

  /// Get a [MediaServerClient] for [serverId], falling back to the first
  /// online server when not found. Throws if no client is available.
  MediaServerClient getMediaClientWithFallback(String? serverId) {
    final c = _resolveMediaClient(serverId);
    if (c == null) throw Exception(t.errors.noClientAvailable);
    return c;
  }

  /// Like [getMediaClientWithFallback] but returns null instead of throwing
  /// when no client is registered. Use this for non-critical surfaces (image
  /// loaders, list cards) that can render a fallback when the client isn't
  /// available — throwing during `build` would crash the widget instead.
  MediaServerClient? tryGetMediaClientWithFallback(String? serverId) => _resolveMediaClient(serverId);
}

/// Try [preferred] first, then fall back through [fallbacks] in order. Returns
/// the first non-null result from [resolve], or `null` if every candidate
/// resolves to null.
T? _resolvePrioritized<T>(String? preferred, Iterable<String> fallbacks, T? Function(String) resolve) {
  if (preferred != null) {
    final c = resolve(preferred);
    if (c != null) return c;
  }
  for (final id in fallbacks) {
    final c = resolve(id);
    if (c != null) return c;
  }
  return null;
}
