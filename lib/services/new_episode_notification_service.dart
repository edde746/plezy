import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import 'settings_service.dart';

/// Delivers local alerts for new TV episodes while the app is in the
/// foreground. Each profile/server/library keeps its own baseline so turning
/// the feature on does not generate a burst of notifications for old media.
class NewEpisodeNotificationService {
  NewEpisodeNotificationService._();

  static final instance = NewEpisodeNotificationService._();

  static const _channelId = 'plezy_new_episodes';
  static const _pollInterval = Duration(minutes: 30);
  static const _latestEpisodeLimit = 100;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  String? _profileId;
  MultiServerProvider? _servers;
  bool _foreground = true;
  bool _initialized = false;
  bool _permissionRequested = false;
  bool _polling = false;

  bool _isEnabledFor(String profileId) {
    final settings = SettingsService.instanceOrNull;
    return _foreground &&
        _profileId == profileId &&
        settings != null &&
        settings.read(SettingsService.notifyNewEpisodesForProfile(profileId));
  }

  void bind({required String? profileId, required MultiServerProvider servers}) {
    _profileId = profileId;
    _servers = servers;
    _refreshSchedule();
  }

  void unbind() {
    _timer?.cancel();
    _timer = null;
    _profileId = null;
    _servers = null;
    _foreground = false;
  }

  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    _refreshSchedule();
  }

  /// Called after a user changes the profile-scoped switch. The next visible
  /// foreground pass requests OS permission if needed and establishes a
  /// baseline without announcing episodes that were already present.
  void preferencesChanged() => _refreshSchedule();

  void _refreshSchedule() {
    final service = SettingsService.instanceOrNull;
    final profileId = _profileId;
    final enabled =
        service != null && profileId != null && service.read(SettingsService.notifyNewEpisodesForProfile(profileId));
    if (!enabled || !_foreground || _servers == null) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(_pollInterval, (_) => unawaited(refreshNow()));
    unawaited(refreshNow());
  }

  Future<void> refreshNow() async {
    if (_polling || !_foreground) return;
    final profileId = _profileId;
    final servers = _servers;
    final settings = SettingsService.instanceOrNull;
    if (profileId == null || servers == null || settings == null) return;
    if (!settings.read(SettingsService.notifyNewEpisodesForProfile(profileId))) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    _polling = true;
    try {
      if (!await _ensureNotifications() || !_isEnabledFor(profileId)) return;
      for (final serverId in servers.onlineServerIds) {
        if (!_isEnabledFor(profileId)) break;
        final client = servers.getClientForServer(ServerId(serverId));
        if (client == null) continue;
        List<MediaLibrary> libraries;
        try {
          libraries = await client.fetchLibraries();
        } catch (error, stackTrace) {
          appLogger.w(
            'New-episode scan could not list libraries for server $serverId',
            error: error,
            stackTrace: stackTrace,
          );
          continue;
        }

        for (final library in libraries) {
          if (!_isEnabledFor(profileId)) break;
          final mayContainEpisodes =
              library.kind == MediaKind.show ||
              library.kind == MediaKind.unknown ||
              library.defaultBrowseKinds.contains(MediaKind.episode) ||
              library.defaultBrowseKinds.contains(MediaKind.show);
          if (!mayContainEpisodes) continue;
          await _scanLibrary(profileId: profileId, serverId: serverId, library: library, client: client);
        }
      }
    } catch (error, stackTrace) {
      appLogger.w('New-episode scan failed', error: error, stackTrace: stackTrace);
    } finally {
      _polling = false;
      if (_foreground && _profileId != profileId) unawaited(refreshNow());
    }
  }

  Future<bool> _ensureNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      if (!_initialized) {
        await _notifications.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
        _initialized = true;
      }
      if (!_permissionRequested) {
        _permissionRequested = true;
        if (Platform.isAndroid) {
          await _notifications
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
        } else {
          await _notifications
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: false, sound: true);
        }
      }
      if (Platform.isAndroid) {
        return await _notifications
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.areNotificationsEnabled() ??
            false;
      }
      final permissions = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    } catch (error, stackTrace) {
      appLogger.w('Local episode notifications are unavailable', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _scanLibrary({
    required String profileId,
    required String serverId,
    required MediaLibrary library,
    required MediaServerClient client,
  }) async {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return;
    final snapshotPref = SettingsService.newEpisodeSnapshotForProfile(profileId, serverId, library.id);
    final previousSnapshot = _decodeSnapshot(settings.read(snapshotPref));

    List<MediaItem> episodes;
    try {
      final hubs = await client.fetchLibraryHubs(
        library.id,
        libraryName: library.title,
        limit: _latestEpisodeLimit,
        includePlaybackHubs: false,
        libraryKind: library.kind,
      );
      episodes = [for (final hub in hubs) ...hub.items.where((item) => item.kind == MediaKind.episode)];
    } catch (error, stackTrace) {
      appLogger.w(
        'New-episode scan could not read ${library.title} on server $serverId',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    if (!_isEnabledFor(profileId)) return;

    final currentEpisodeIds = episodes.map((episode) => episode.id).toSet();
    final currentShowIds = episodes.map((episode) => episode.grandparentId).whereType<String>().toSet();
    final previousEpisodeIds = previousSnapshot?.episodeIds ?? const <String>{};
    final knownShowIds = previousSnapshot?.showIds ?? const <String>{};
    if (previousSnapshot != null) {
      final candidates = <String, List<MediaItem>>{};
      for (final episode in episodes) {
        final showId = episode.grandparentId;
        if (showId == null || !knownShowIds.contains(showId) || previousEpisodeIds.contains(episode.id)) continue;
        candidates.putIfAbsent(showId, () => []).add(episode);
      }

      var safeToAdvanceSnapshot = true;
      for (final entry in candidates.entries) {
        try {
          final allEpisodes = (await client.fetchPlayableDescendants(
            entry.key,
          )).where((item) => item.kind == MediaKind.episode).toList();
          if (!_isEnabledFor(profileId)) return;
          if (allEpisodes.isEmpty) continue;
          allEpisodes.sort(_episodeOrder);
          final candidateIds = entry.value.map((item) => item.id).toSet();
          MediaItem? nextEpisode;
          for (final episode in allEpisodes) {
            if (candidateIds.contains(episode.id) && !episode.isWatched) {
              nextEpisode = episode;
              break;
            }
          }
          final episodeToNotify = nextEpisode;
          if (episodeToNotify == null) continue;
          final nextIndex = allEpisodes.indexWhere((episode) => episode.id == episodeToNotify.id);
          if (allEpisodes.take(nextIndex).any((episode) => !episode.isWatched)) continue;
          if (!_isEnabledFor(profileId)) return;
          await _showEpisodeNotification(serverId: serverId, showId: entry.key, episode: episodeToNotify);
        } catch (error, stackTrace) {
          safeToAdvanceSnapshot = false;
          appLogger.w(
            'New-episode scan could not confirm watch history for ${entry.key}',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      if (!safeToAdvanceSnapshot) return;
    }

    if (!_isEnabledFor(profileId)) return;
    await settings.write(
      snapshotPref,
      jsonEncode({'episodeIds': currentEpisodeIds.toList(), 'showIds': currentShowIds.toList()}),
    );
  }

  int _episodeOrder(MediaItem a, MediaItem b) {
    final seasonOrder = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
    if (seasonOrder != 0) return seasonOrder;
    final episodeOrder = (a.index ?? 0).compareTo(b.index ?? 0);
    if (episodeOrder != 0) return episodeOrder;
    return (a.addedAt ?? 0).compareTo(b.addedAt ?? 0);
  }

  Future<void> _showEpisodeNotification({
    required String serverId,
    required String showId,
    required MediaItem episode,
  }) async {
    final showTitle = episode.grandparentTitle?.trim();
    final episodeTitle = episode.title?.trim();
    if (showTitle == null || showTitle.isEmpty || episodeTitle == null || episodeTitle.isEmpty) return;
    final hash = sha256.convert(utf8.encode('$serverId/$showId')).bytes;
    final id = ((hash[0] << 24) | (hash[1] << 16) | (hash[2] << 8) | hash[3]) & 0x7fffffff;
    await _notifications.show(
      id: id,
      title: t.notifications.newEpisodeTitle,
      body: t.notifications.newEpisodeBody(show: showTitle, episode: episodeTitle),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'New episodes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  _EpisodeSnapshot? _decodeSnapshot(String encoded) {
    if (encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      return _EpisodeSnapshot(
        episodeIds: (decoded['episodeIds'] as List? ?? const []).whereType<String>().toSet(),
        showIds: (decoded['showIds'] as List? ?? const []).whereType<String>().toSet(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _EpisodeSnapshot {
  const _EpisodeSnapshot({required this.episodeIds, required this.showIds});

  final Set<String> episodeIds;
  final Set<String> showIds;
}
