import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  static const MethodChannel _androidChannel = MethodChannel('com.plezy/watch_next');
  static const MethodChannel _tvosChannel = MethodChannel('com.plezy/system_shelf');
  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

  static final SystemShelfService _instance = SystemShelfService._internal();
  factory SystemShelfService() => _instance;

  SystemShelfService._internal() {
    _androidChannel.setMethodCallHandler(_handleMethodCall);
    _tvosChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// Callback for warm-start launcher surface taps.
  ValueChanged<String>? onShelfItemTap;

  MethodChannel? get _channel {
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

  /// Sync Continue Watching items to the current platform's launcher shelf.
  Future<bool> syncFromContinueWatching(
    List<MediaItem> continueWatchingItems,
    MediaServerClient Function(ServerId serverId) getClientForServerId, {
    bool hideSpoilers = false,
  }) async {
    final channel = _channel;
    if (channel == null) return false;

    try {
      final items = continueWatchingItems.map((item) {
        return _convertToShelfItem(item, getClientForServerId, hideSpoilers: hideSpoilers);
      }).toList();

      final supported = await isSupported();
      if (!supported) return false;

      return await channel.invokeMethod<bool>('sync', {'items': items}) ?? false;
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
  }

  /// Clear all launcher shelf entries owned by the app.
  Future<bool> clear() async {
    final channel = _channel;
    if (channel == null) return false;
    try {
      return await channel.invokeMethod<bool>('clear') ?? false;
    } on MissingPluginException catch (e) {
      appLogger.e('Failed to clear system shelf: native channel missing', error: e);
      return false;
    } on PlatformException catch (e) {
      appLogger.e('Failed to clear system shelf: native platform error', error: e);
      return false;
    } catch (e) {
      appLogger.e('Failed to clear system shelf', error: e);
      return false;
    }
  }

  /// Remove a single launcher shelf item.
  Future<bool> removeItem(ServerId serverId, String ratingKey) async {
    final channel = _channel;
    if (channel == null) return false;
    try {
      final contentId = _buildContentId(serverId, ratingKey);
      return await channel.invokeMethod<bool>('remove', {'contentId': contentId}) ?? false;
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

    String? posterUri;
    try {
      if (item.serverId != null) {
        final client = getClientForServerId(ServerId(item.serverId!));
        String? thumbPath;
        if (hideSpoilers && item.shouldHideSpoiler) {
          thumbPath = item.spoilerSafeArt;
        }
        thumbPath ??= item.posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true);
        if (thumbPath != null) {
          posterUri = client.thumbnailUrl(thumbPath);
        }
      }
    } catch (e) {
      appLogger.w('Failed to get shelf poster URL for ${item.title}', error: e);
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
      'posterUri': posterUri,
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
