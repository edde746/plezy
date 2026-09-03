import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'jellyfin_client.dart';
import 'plex_client.dart';
import 'settings_service.dart' show EpisodePosterMode;

/// Syncs Continue Watching content to platform launcher surfaces.
///
/// Android uses the Watch Next row. tvOS uses the app's Top Shelf extension.
class SystemShelfService {
  static const int schemaVersion = 3;
  static const MethodChannel _androidChannel = MethodChannel('com.plezy/watch_next');
  static const MethodChannel _tvosChannel = MethodChannel('com.plezy/system_shelf');
  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

  static final SystemShelfService _instance = SystemShelfService._internal();
  static SystemShelfService? _testingInstance;
  factory SystemShelfService() => _testingInstance ?? _instance;

  SystemShelfService._internal() : _channelOverride = null, _supportOverride = null, _tvosTargetOverride = null {
    _androidChannel.setMethodCallHandler(_handleMethodCall);
    _tvosChannel.setMethodCallHandler(_handleMethodCall);
  }

  @visibleForTesting
  SystemShelfService.forTesting({
    required MethodChannel channel,
    Future<bool> Function()? isSupported,
    bool Function()? isTvosTarget,
  }) : _channelOverride = channel,
       _supportOverride = isSupported,
       _tvosTargetOverride = isTvosTarget;

  @visibleForTesting
  static void debugOverrideInstance(SystemShelfService? service) {
    _testingInstance = service;
  }

  final MethodChannel? _channelOverride;
  final Future<bool> Function()? _supportOverride;
  final bool Function()? _tvosTargetOverride;

  String? _activeOwner;
  int _generation = 0;
  Future<void> _mutationTail = Future<void>.value();

  @visibleForTesting
  String? get debugActiveOwner => _activeOwner;

  @visibleForTesting
  int get debugGeneration => _generation;

  /// Forgets the owner and drops the mutation queue. Deliberately does not
  /// await the old tail: a widget test's FakeAsync zone ends without
  /// flushing the microtasks that settle a chained future, so the previous
  /// test's final clear would leave a tail that never completes and hang the
  /// next test's setUp. Tests own their channel fakes, so nothing native is
  /// lost by abandoning the chain.
  @visibleForTesting
  void debugReset() {
    _activeOwner = null;
    _generation = 0;
    _mutationTail = Future<void>.value();
  }

  /// Callback for warm-start launcher surface taps.
  ValueChanged<String>? onShelfItemTap;

  /// Whether this process targets the tvOS Top Shelf (as opposed to the
  /// Android Watch Next row). Decides artwork geometry and which native
  /// surface receives server sources.
  bool get _isTvosTarget {
    final override = _tvosTargetOverride;
    if (override != null) return override();
    return Platform.isIOS && (_tvosBuild || PlatformDetector.isAppleTV());
  }

  MethodChannel? get _channel {
    final override = _channelOverride;
    if (override != null) return override;
    if (Platform.isAndroid) return _androidChannel;
    if (_isTvosTarget) return _tvosChannel;
    return null;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onWatchNextTap' && call.method != 'onShelfItemTap') {
      return null;
    }
    final args = call.arguments;
    final contentId = args is Map ? args['contentId'] as String? : null;
    final callback = onShelfItemTap;
    if (contentId == null || callback == null) return false;
    callback(contentId);
    return true;
  }

  @visibleForTesting
  Future<dynamic> handleMethodCallForTesting(MethodCall call) => _handleMethodCall(call);

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
      await _invokeGuarded<bool>(
        channel,
        'clear',
        arguments: _envelope(profileId, generation),
        label: 'Failed to clear system shelf',
        severe: true,
      );
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

  /// Owner-scoped envelope every mutating native call carries.
  static Map<String, dynamic> _envelope(String profileId, int generation, [Map<String, dynamic>? extra]) {
    return {'schemaVersion': schemaVersion, 'ownerId': profileId, 'generation': generation, ...?extra};
  }

  /// Invokes [method] on [channel], logging channel failures under [label] (at
  /// error level when [severe]) and returning null instead of throwing.
  /// Errors that are not channel failures log [failureLabel] when given.
  Future<T?> _invokeGuarded<T>(
    MethodChannel channel,
    String method, {
    Map<String, dynamic>? arguments,
    required String label,
    String? failureLabel,
    bool severe = false,
  }) async {
    final log = severe ? appLogger.e : appLogger.w;
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException catch (e) {
      log('$label: native channel missing', error: e);
    } on PlatformException catch (e) {
      log('$label: native platform error', error: e);
    } catch (e) {
      log(failureLabel ?? label, error: e);
    }
    return null;
  }

  /// Get a pending deep link from cold start (consumed on first call).
  Future<String?> getInitialDeepLink() async {
    final channel = _channel;
    if (channel == null) return null;
    return _invokeGuarded<String>(
      channel,
      'getInitialDeepLink',
      label: 'System shelf initial deep link failed',
      failureLabel: 'Failed to get system shelf initial deep link',
    );
  }

  /// Check whether the current platform has a launcher shelf integration.
  Future<bool> isSupported() async {
    final override = _supportOverride;
    if (override != null) return override();
    final channel = _channel;
    if (channel == null) return false;
    return await _invokeGuarded<bool>(
          channel,
          'isSupported',
          label: 'System shelf unsupported',
          failureLabel: 'System shelf unsupported: native support check failed',
        ) ??
        false;
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
      return await _invokeGuarded<bool>(
            channel,
            'sync',
            arguments: _envelope(profileId, generation, {'items': items, 'sectionTitle': t.discover.continueWatching}),
            label: 'Failed to sync system shelf',
            severe: true,
          ) ??
          false;
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
      return await _invokeGuarded<bool>(
            channel,
            'remove',
            arguments: _envelope(profileId, generation, {'contentId': _buildContentId(serverId, ratingKey)}),
            label: 'Failed to remove system shelf item',
            severe: true,
          ) ??
          false;
    });
    return result ?? false;
  }

  /// Publish live server connection sources to the tvOS Top Shelf extension so
  /// it can fetch Continue Watching itself. tvOS-only: Android's Watch Next
  /// row is refreshed by the app process instead, so this is a no-op there.
  Future<bool> syncServerSources(String profileId, List<MediaServerClient> clients) async {
    if (!_isTvosTarget) return false;
    final channel = _channel;
    if (channel == null || _activeOwner != profileId) return false;
    final generation = _generation;

    final servers = clients.map(_describeServerSource).nonNulls.toList(growable: false);
    final result = await _enqueueMutation<bool>(() async {
      if (!_owns(profileId, generation)) return false;
      return await _invokeGuarded<bool>(
            channel,
            'updateSources',
            arguments: _envelope(profileId, generation, {
              'servers': servers,
              'maxItems': 20,
              'sectionTitle': t.discover.continueWatching,
            }),
            label: 'Failed to update system shelf sources',
            severe: true,
          ) ??
          false;
    });
    return result ?? false;
  }

  /// Backend-specific escape hatch: the Top Shelf extension talks to servers
  /// directly, which needs the raw connection credentials the neutral
  /// [MediaServerClient] interface deliberately hides. Unknown client types
  /// and clients without a usable base URL or token are skipped.
  static Map<String, dynamic>? _describeServerSource(MediaServerClient client) {
    final String kind;
    final String baseUrl;
    final String? token;
    String? userId;
    if (client is PlexClient) {
      kind = 'plex';
      baseUrl = client.config.baseUrl;
      token = client.config.token;
    } else if (client is JellyfinClient) {
      final connection = client.connection;
      kind = connection.dialect.name;
      baseUrl = connection.baseUrl;
      token = connection.accessToken;
      userId = connection.userId;
    } else {
      return null;
    }
    if (baseUrl.isEmpty || token == null || token.isEmpty) return null;
    return {
      'serverId': client.serverId,
      'kind': kind,
      'name': client.serverName ?? '',
      'baseUrl': baseUrl,
      'token': token,
      'userId': ?userId,
    };
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
        if (_isTvosTarget) {
          // The Top Shelf renders 2:3 posters via the season -> series -> own
          // thumb chain. Posters cannot spoil, so the spoiler-safe override
          // does not apply here.
          thumbPath = item.posterThumb(mode: EpisodePosterMode.seasonPoster);
          if (thumbPath != null) {
            posterSourceUri = client.thumbnailUrl(thumbPath, width: 600, height: 900);
          }
        } else {
          if (hideSpoilers && item.shouldHideSpoiler) {
            thumbPath = item.spoilerSafeArt;
          }
          thumbPath ??= item.posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true);
          if (thumbPath != null) {
            posterSourceUri = client.thumbnailUrl(thumbPath, width: 640, height: 360);
          }
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
