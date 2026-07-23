import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'settings_service.dart' show EpisodePosterMode;

/// Syncs Continue Watching content to platform launcher surfaces.
///
/// Android uses the Watch Next row. tvOS uses the app's Top Shelf extension.
class SystemShelfService {
  static const int schemaVersion = 2;
  static const MethodChannel _androidChannel = MethodChannel('com.plezy/watch_next');
  static const MethodChannel _tvosChannel = MethodChannel('com.plezy/system_shelf');
  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

  static final SystemShelfService _instance = SystemShelfService._internal();
  static SystemShelfService? _testingInstance;
  factory SystemShelfService() => _testingInstance ?? _instance;

  SystemShelfService._internal() : _channelOverride = null, _supportOverride = null {
    _androidChannel.setMethodCallHandler(_handleMethodCall);
    _tvosChannel.setMethodCallHandler(_handleMethodCall);
  }

  @visibleForTesting
  SystemShelfService.forTesting({required MethodChannel channel, Future<bool> Function()? isSupported})
    : _channelOverride = channel,
      _supportOverride = isSupported;

  @visibleForTesting
  static void debugOverrideInstance(SystemShelfService? service) {
    _testingInstance = service;
  }

  final MethodChannel? _channelOverride;
  final Future<bool> Function()? _supportOverride;

  String? _activeOwner;
  int _generation = 0;
  Future<void> _mutationTail = Future<void>.value();

  @visibleForTesting
  String? get debugActiveOwner => _activeOwner;

  @visibleForTesting
  int get debugGeneration => _generation;

  @visibleForTesting
  Future<void> debugReset() async {
    await _mutationTail;
    _activeOwner = null;
    _generation = 0;
    _mutationTail = Future<void>.value();
  }

  /// Callback for warm-start launcher surface taps.
  ValueChanged<String>? onShelfItemTap;

  MethodChannel? get _channel {
    final override = _channelOverride;
    if (override != null) return override;
    if (Platform.isAndroid) return _androidChannel;
    if (Platform.isIOS && (_tvosBuild || PlatformDetector.isAppleTV())) return _tvosChannel;
    return null;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onWatchNextTap' || call.method == 'onShelfItemTap') {
      final args = call.arguments;
      final contentId = args is Map ? args['contentId'] as String? : null;
      if (contentId != null) {
        onShelfItemTap?.call(contentId);
      }
    }
  }

  /// Establishes the only owner allowed to publish launcher shelf state.
  ///
  /// Ownership changes are synchronous. Native mutations remain serialized
  /// behind any clear already queued for the previous owner.
  void beginProfileSession(String profileId) {
    if (profileId.isEmpty) {
      throw ArgumentError.value(profileId, 'profileId', 'must not be empty');
    }
    if (_activeOwner == profileId) return;
    _activeOwner = profileId;
    _generation++;
  }

  /// Invalidates [profileId] synchronously, then clears its native shelf after
  /// every already-dispatched mutation has settled.
  Future<void> endProfileSession(String profileId) async {
    if (_activeOwner != profileId) return;
    _activeOwner = null;
    final generation = ++_generation;
    await _enqueueMutation<void>(() async {
      final channel = _channel;
      if (channel == null) return;
      try {
        await channel.invokeMethod<bool>('clear', {
          'schemaVersion': schemaVersion,
          'ownerId': profileId,
          'generation': generation,
        });
      } on MissingPluginException catch (e) {
        appLogger.e('Failed to clear system shelf: native channel missing', error: e);
      } on PlatformException catch (e) {
        appLogger.e('Failed to clear system shelf: native platform error', error: e);
      } catch (e) {
        appLogger.e('Failed to clear system shelf', error: e);
      }
    });
  }

  bool _owns(String profileId, int generation) {
    return _activeOwner == profileId && _generation == generation;
  }

  Future<T?> _enqueueMutation<T>(Future<T> Function() mutation) {
    final completer = Completer<T?>();
    _mutationTail = _mutationTail
        .then((_) async {
          try {
            completer.complete(await mutation());
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          appLogger.w('System shelf mutation failed', error: error, stackTrace: stackTrace);
        });
    return completer.future;
  }

  /// Get a pending deep link from cold start (consumed on first call).
  Future<String?> getInitialDeepLink() async {
    final channel = _channel;
    if (channel == null) return null;
    try {
      return await channel.invokeMethod<String>('getInitialDeepLink');
    } on MissingPluginException catch (e) {
      appLogger.w('System shelf initial deep link failed: native channel missing', error: e);
      return null;
    } catch (e) {
      appLogger.w('Failed to get system shelf initial deep link', error: e);
      return null;
    }
  }

  /// Check whether the current platform has a launcher shelf integration.
  Future<bool> isSupported() async {
    final override = _supportOverride;
    if (override != null) return override();
    final channel = _channel;
    if (channel == null) return false;
    try {
      return await channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException catch (e) {
      appLogger.w('System shelf unsupported: native channel missing', error: e);
      return false;
    } on PlatformException catch (e) {
      appLogger.w('System shelf unsupported: native platform error', error: e);
      return false;
    } catch (e) {
      appLogger.w('System shelf unsupported: native support check failed', error: e);
      return false;
    }
  }

  /// Sync Continue Watching items for the currently active [profileId].
  Future<bool> syncFromContinueWatching(
    String profileId,
    List<MediaItem> continueWatchingItems,
    MediaServerClient Function(ServerId serverId) getClientForServerId, {
    bool hideSpoilers = false,
  }) async {
    final channel = _channel;
    if (channel == null || _activeOwner != profileId) return false;
    final generation = _generation;

    final items = continueWatchingItems
        .map((item) {
          return _convertToShelfItem(item, getClientForServerId, hideSpoilers: hideSpoilers);
        })
        .toList(growable: false);
    if (!_owns(profileId, generation)) return false;

    final supported = await isSupported();
    if (!_owns(profileId, generation) || !supported) return false;

    final result = await _enqueueMutation<bool>(() async {
      if (!_owns(profileId, generation)) return false;
      try {
        if (!_owns(profileId, generation)) return false;
        return await channel.invokeMethod<bool>('sync', {
              'schemaVersion': schemaVersion,
              'ownerId': profileId,
              'generation': generation,
              'items': items,
            }) ??
            false;
      } on MissingPluginException catch (e) {
        appLogger.e('Failed to sync system shelf: native channel missing', error: e);
        return false;
      } on PlatformException catch (e) {
        appLogger.e('Failed to sync system shelf: native platform error', error: e);
        return false;
      } catch (e) {
        appLogger.e('Failed to sync system shelf', error: e);
        return false;
      }
    });
    return result ?? false;
  }

  /// Remove a single launcher shelf item for the current profile owner.
  Future<bool> removeItem(String profileId, ServerId serverId, String ratingKey) async {
    final channel = _channel;
    if (channel == null || _activeOwner != profileId) return false;
    final generation = _generation;
    final result = await _enqueueMutation<bool>(() async {
      if (!_owns(profileId, generation)) return false;
      try {
        return await channel.invokeMethod<bool>('remove', {
              'schemaVersion': schemaVersion,
              'ownerId': profileId,
              'generation': generation,
              'contentId': _buildContentId(serverId, ratingKey),
            }) ??
            false;
      } on MissingPluginException catch (e) {
        appLogger.e('Failed to remove system shelf item: native channel missing', error: e);
        return false;
      } on PlatformException catch (e) {
        appLogger.e('Failed to remove system shelf item: native platform error', error: e);
        return false;
      } catch (e) {
        appLogger.e('Failed to remove system shelf item', error: e);
        return false;
      }
    });
    return result ?? false;
  }

  /// Build a content ID. Format: plezy_{serverId}_{ratingKey}
  static String _buildContentId(ServerId? serverId, String ratingKey) {
    return 'plezy_${serverId ?? 'unknown'}_$ratingKey';
  }

  /// Parse a content ID back to (serverId, ratingKey), or null if invalid.
  static (ServerId serverId, String ratingKey)? parseContentId(String contentId) {
    if (!contentId.startsWith('plezy_')) return null;
    final parts = contentId.substring(6).split('_');
    if (parts.length < 2) return null;
    return (ServerId(parts.first), parts.sublist(1).join('_'));
  }

  Map<String, dynamic> _convertToShelfItem(
    MediaItem item,
    MediaServerClient Function(ServerId serverId) getClientForServerId, {
    bool hideSpoilers = false,
  }) {
    final contentId = _buildContentId(serverIdOrNull(item.serverId), item.id);

    String? posterSourceUri;
    try {
      if (item.serverId != null) {
        final client = getClientForServerId(ServerId(item.serverId!));
        String? thumbPath;
        if (hideSpoilers && item.shouldHideSpoiler) {
          thumbPath = item.spoilerSafeArt;
        }
        thumbPath ??= item.posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true);
        if (thumbPath != null) {
          posterSourceUri = client.thumbnailUrl(thumbPath, width: 640, height: 360);
        }
      }
    } catch (_) {
      appLogger.w('Failed to prepare system shelf artwork');
    }

    final String title;
    final String? episodeTitle;
    if (item.kind == MediaKind.episode && item.grandparentTitle != null) {
      title = item.grandparentTitle!;
      episodeTitle = item.title;
    } else {
      title = item.title ?? '';
      episodeTitle = null;
    }

    final lastEngagementTime = item.lastViewedAt != null
        ? item.lastViewedAt! * 1000
        : DateTime.now().millisecondsSinceEpoch;

    return {
      'contentId': contentId,
      'title': title,
      'episodeTitle': episodeTitle,
      'description': item.summary,
      'posterSourceUri': posterSourceUri,
      'type': item.kind.name,
      'duration': item.durationMs ?? 0,
      'lastPlaybackPosition': item.viewOffsetMs ?? 0,
      'lastEngagementTime': lastEngagementTime,
      'seriesTitle': item.grandparentTitle,
      'seasonNumber': item.parentIndex,
      'episodeNumber': item.index,
    };
  }
}
