import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../exceptions/media_server_exceptions.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../models/livetv_channel.dart';
import '../providers/download_provider.dart';
import '../providers/watch_state_store.dart';
import '../providers/multi_server_provider.dart';
import '../utils/global_key_utils.dart';
import '../utils/live_tv_player_navigation.dart';
import '../utils/video_player_navigation.dart';
import '../watch_together/providers/watch_together_provider.dart';
import 'agent_control_protocol.dart';
import 'driver_distraction.dart';
import 'music/music_playback_service.dart';
import 'offline_watch_sync_service.dart';
import 'playback_coordinator.dart';
import 'playback_launch_observer.dart';

/// Profile-lifetime command adapter. It retains only one launch observation,
/// never a parallel queue/player or a history of provider response objects.
class AgentPlaybackCommands {
  bool _disposed = false;
  int _serial = 0;
  String? _operationId;
  Map<String, dynamic>? _item;
  PlaybackLaunchObserver? _observer;
  Future<void>? _pending;
  bool _stopped = false;
  bool _stopFailed = false;
  bool _musicLaunch = false;

  Future<Object?> handle(String command, Map<String, dynamic> arguments, AgentCommandContext context) async {
    context.checkCurrent(requireProfile: true);
    if (_disposed) throw const AgentControlException('sessionChanged', 'The playback session changed.');
    try {
      switch (command) {
        case 'media.servers':
          final servers = context.context.read<MultiServerProvider>();
          return {
            'servers': [
              for (final id in servers.expectedServerIds)
                {
                  'serverId': id,
                  'name': servers.serverManager.serverDisplayName(ServerId(id)),
                  'visible': servers.serverIds.contains(id),
                  'online': servers.isServerOnline(ServerId(id)),
                  'authenticationRequired': servers.authErrorServerIds.contains(id),
                  if (servers.serverIds.contains(id) && servers.getClientForServer(ServerId(id)) != null)
                    'backend': servers.getClientForServer(ServerId(id))!.backend.id,
                },
            ],
          };
        case 'media.search':
        case 'media.get':
        case 'media.children':
          return await _discover(command, arguments, context);
        case 'playback.start':
          return _start(arguments, context);
        case 'playback.status':
          _checkOperation(arguments);
          return _status(context);
        case 'playback.stop':
          _checkOperation(arguments);
          return await _stop(context, scoped: arguments.containsKey('operationId'));
        default:
          throw const AgentControlException('unsupportedCommand', 'Unsupported playback command.');
      }
    } catch (error) {
      throw _safeError(error);
    }
  }

  void _checkOperation(Map<String, dynamic> arguments) {
    if (arguments.containsKey('operationId') && agentString(arguments, 'operationId') != _operationId) {
      throw const AgentControlException('operationChanged', 'The playback operation changed.');
    }
  }

  Map<String, dynamic> _status(AgentCommandContext context) {
    final coordinator = PlaybackCoordinator.instance;
    final music = context.context.read<MusicPlaybackService>();
    return {
      'operationId': _operationId,
      if (_item != null) 'item': _item,
      if (_stopped) ...const {'stage': 'stopped', 'playing': false, 'buffering': false} else if (_observer != null)
        ..._observer!.snapshot()
      else ...const {'stage': 'stopped', 'playing': false, 'buffering': false},
      'activeSession': coordinator.hasVideoSession
          ? 'video'
          : music.currentTrack != null
          ? 'music'
          : null,
      'observed': _observer != null && !_stopped,
    };
  }

  Map<String, dynamic> _start(Map<String, dynamic> arguments, AgentCommandContext context) {
    // Validate the complete public shape before accepting an operation.
    final serverId = agentString(arguments, 'serverId');
    final itemId = agentString(arguments, 'itemId');
    _targetKind(arguments);
    _boolean(arguments, 'offline');
    _initialPosition(arguments);
    if (arguments.containsKey('mediaIndex')) _integer(arguments, 'mediaIndex', max: 10000);
    if (arguments.containsKey('mediaSourceId')) agentString(arguments, 'mediaSourceId');
    _ensureIdle(context);
    final previous = _observer;
    previous?.cancel();
    final observer = PlaybackLaunchObserver(
      isCurrent: () => !_disposed && context.isCurrent() && context.context.mounted,
    );
    _observer = observer;
    _stopped = false;
    _musicLaunch = false;
    _operationId = '${context.requestId}:${++_serial}';
    _item = {'serverId': serverId, 'itemId': itemId, 'targetKind': _targetKind(arguments)};
    // A scheduled task, not the route-close Future. The caller receives the
    // accepted identity before metadata/permission/native work can complete.
    _pending = Future<void>(() async {
      try {
        await _launch(arguments, context, observer);
      } catch (error) {
        final safe = _safeError(error);
        observer.mark(
          safe.code == 'sessionChanged'
              ? 'cancelled'
              : safe.code == 'selectionRequired' || safe.code == 'unsupportedOptions' || safe.code == 'playbackActive'
              ? 'blocked'
              : 'failed',
          failure: safe.code,
          blocker:
              safe.code == 'selectionRequired' || safe.code == 'unsupportedOptions' || safe.code == 'playbackActive'
              ? safe.code
              : null,
        );
      }
    });
    return {'operationId': _operationId, 'item': _item, 'stage': 'accepted'};
  }

  void _ensureIdle(AgentCommandContext context, {bool ignorePending = false}) {
    final music = context.context.read<MusicPlaybackService>();
    final snapshot = _observer?.snapshot();
    final stage = snapshot?['stage'];
    if (_stopFailed ||
        PlaybackCoordinator.instance.hasVideoSession ||
        music.currentTrack != null ||
        snapshot?['blocker'] == 'externalHandoffPending' ||
        (!ignorePending && (stage == 'accepted' || stage == 'resolving' || stage == 'opening'))) {
      throw const AgentControlException('playbackActive', 'Stop the current playback session before starting another.');
    }
  }

  Future<void> _launch(
    Map<String, dynamic> arguments,
    AgentCommandContext context,
    PlaybackLaunchObserver observer,
  ) async {
    void check() {
      context.checkCurrent(requireProfile: true);
      if (!observer.isCurrent) throw const AgentControlException('sessionChanged', 'The playback session changed.');
    }

    check();
    observer.mark('resolving');
    final offline = _boolean(arguments, 'offline');
    final serverId = ServerId(agentString(arguments, 'serverId'));
    final itemId = agentString(arguments, 'itemId');
    final servers = context.context.read<MultiServerProvider>();
    final music = context.context.read<MusicPlaybackService>();
    final client = offline ? null : _authorizedClient(servers, serverId);
    final authentication = client?.authenticationSessionId;
    bool current() => observer.isCurrent && (offline || _clientCurrent(servers, serverId, client!, authentication!));
    void checkIdentity() {
      check();
      if (!current()) throw const AgentControlException('sessionChanged', 'The server authentication session changed.');
    }

    final watchTogether = context.context.read<WatchTogetherProvider?>();
    if (watchTogether?.isInSession == true &&
        (!watchTogether!.isHost || offline || _targetKind(arguments) == 'channel')) {
      // Host VOD selection uses the normal navigation lease. Guests and
      // non-synchronized target kinds must stay on the group's own flow.
      observer.mark('blocked', blocker: 'watchTogetherActive');
      return;
    }
    if (!automotivePlaybackAllowedNow()) {
      observer.mark('blocked', blocker: 'automotiveRestricted');
      return;
    }
    if (_targetKind(arguments) == 'channel') {
      if (offline ||
          arguments.containsKey('start') ||
          arguments.containsKey('positionMs') ||
          arguments.containsKey('mediaIndex') ||
          arguments.containsKey('mediaSourceId')) {
        throw const AgentControlException(
          'unsupportedOptions',
          'Channels do not support offline, offsets or version selection.',
        );
      }
      final channels = await _channels(servers, serverId, client!, checkIdentity);
      checkIdentity();
      final matches = channels.where((channel) => channel.key == itemId).toList(growable: false);
      if (matches.isEmpty) throw const AgentControlException('itemNotFound', 'The channel was not found.');
      if (matches.length != 1) {
        throw const AgentControlException('selectionRequired', 'The channel is ambiguous across DVR sources.');
      }
      _ensureIdle(context, ignorePending: true);
      if (!context.context.mounted) return;
      await navigateToLiveTv(
        context.context,
        multiServer: servers,
        channel: matches.single,
        channels: channels,
        launchObserver: observer,
        isLaunchCurrent: current,
      );
      return;
    }
    final downloads = context.context.read<DownloadProvider>();
    final metadata = await _resolveItem(serverId, itemId, offline, downloads, client);
    checkIdentity();
    if (!metadata.kind.isPlayable) {
      throw AgentControlException(
        metadata.kind.usesLeafWatchCounts ? 'selectionRequired' : 'unsupportedTarget',
        'Select a concrete movie, episode, clip or music track.',
        details: {'kind': metadata.kind.id, 'childrenCommand': 'media.children'},
      );
    }
    int? mediaIndex = arguments.containsKey('mediaIndex') ? _integer(arguments, 'mediaIndex', max: 10000) : null;
    String? mediaSourceId = arguments.containsKey('mediaSourceId') ? agentString(arguments, 'mediaSourceId') : null;
    final explicitVersion = mediaIndex != null || mediaSourceId != null;
    if (metadata.kind == MediaKind.track && explicitVersion) {
      throw const AgentControlException(
        'unsupportedOptions',
        'Music tracks do not support explicit version selection.',
      );
    }
    if (explicitVersion && !offline) {
      final versions = metadata.mediaVersions ?? const [];
      final byId = mediaSourceId == null ? null : versions.indexWhere((version) => version.id == mediaSourceId);
      if ((byId != null && byId < 0) ||
          (mediaIndex != null && mediaIndex >= versions.length) ||
          (byId != null && mediaIndex != null && mediaIndex != byId)) {
        throw const AgentControlException(
          'staleMediaSelection',
          'The selected media version no longer exists or its identities disagree.',
        );
      }
      mediaIndex ??= byId;
      if (mediaIndex == null || versions.isEmpty) {
        throw const AgentControlException('staleMediaSelection', 'No authoritative version matches the selection.');
      }
      mediaSourceId = versions[mediaIndex].id;
    }
    if (offline) {
      final complete = await downloads.getCompletedDownload(metadata.globalKey);
      checkIdentity();
      if (complete == null) {
        throw const AgentControlException('offlineMissing', 'This profile has no completed download for the item.');
      }
      if (explicitVersion &&
          ((mediaIndex != null && mediaIndex != complete.mediaIndex) ||
              (mediaSourceId != null && mediaSourceId != complete.mediaSourceId))) {
        throw const AgentControlException('staleMediaSelection', 'The selected version is not the completed download.');
      }
      mediaIndex = complete.mediaIndex;
      mediaSourceId = complete.mediaSourceId;
      final path = await downloads.getVideoFilePath(
        metadata.globalKey,
        mediaIndex: mediaIndex,
        mediaSourceId: mediaSourceId,
      );
      checkIdentity();
      if (path == null) {
        throw const AgentControlException('offlineMissing', 'The requested downloaded media file is unavailable.');
      }
    }
    var initialPosition = _initialPosition(arguments);
    _ensureIdle(context, ignorePending: true);
    if (!context.context.mounted) return;
    if (metadata.kind == MediaKind.track) {
      if (watchTogether?.isInSession == true) {
        observer.mark('blocked', blocker: 'watchTogetherActive');
        return;
      }
      if (initialPosition == null) {
        final fresh = context.context.readFreshWatchState(metadata);
        final local = offline
            ? await context.context.read<OfflineWatchSyncService>().getLocalViewOffset(metadata.globalKey)
            : null;
        checkIdentity();
        initialPosition = Duration(milliseconds: local ?? fresh.viewOffsetMs ?? 0);
      }
      final guarded = PlaybackLaunchObserver(isCurrent: () => current() && watchTogether?.isInSession != true);
      // The outer operation reads the native owner through the same pull seam;
      // its cancellation also fences the source/native-open awaits.
      observer.attach(guarded.snapshot, ownsPlayback: () => guarded.ownsPlayback);
      checkIdentity();
      // Resume lookup may await the offline store while ordinary UI playback
      // starts. Keep the explicit-stop policy at the owner's commit boundary.
      _ensureIdle(context, ignorePending: true);
      _musicLaunch = true;
      await music.playFromList(
        tracks: [metadata],
        startTrack: metadata,
        playContext: MusicPlayContext(title: metadata.title ?? itemId, kind: MusicPlayContextKind.tracks),
        initialPosition: initialPosition,
        offline: offline,
        launchObserver: guarded,
      );
      return;
    }
    checkIdentity();
    if (watchTogether?.isInSession == true && !watchTogether!.isHost) {
      observer.mark('blocked', blocker: 'watchTogetherActive');
      return;
    }
    // Never await the route-lifetime result here. Existing UI callers still do.
    unawaited(
      navigateToVideoPlayer(
        context.context,
        metadata: metadata,
        isOffline: offline,
        initialPosition: initialPosition,
        selectedMediaIndex: mediaIndex,
        selectedMediaSourceId: mediaSourceId,
        strictMediaSelection: explicitVersion,
        launchObserver: observer,
        isLaunchCurrent: current,
        explicitStartPolicy: arguments.containsKey('start'),
      ).then(
        (_) {
          if (observer.stage == 'resolving') observer.mark('cancelled');
        },
        onError: (Object error, StackTrace stack) {
          observer.mark('failed', failure: _safeError(error).code);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _stop(AgentCommandContext context, {required bool scoped}) async {
    if (_observer?.snapshot()['stage'] == 'externalLaunched' ||
        _observer?.snapshot()['blocker'] == 'externalHandoffPending') {
      throw const AgentControlException(
        'unsupportedTarget',
        'An external application cannot be stopped or observed by Plezy.',
      );
    }
    if (scoped) return _stopScoped(context);
    final coordinator = PlaybackCoordinator.instance;
    final music = context.context.read<MusicPlaybackService>();
    if (coordinator.hasVideoSession) {
      if (!await _awaitTeardown(coordinator.stopVideoAndExit())) {
        throw const AgentControlException(
          'confirmationRequired',
          'The current player requires its normal leave or confirmation flow.',
        );
      }
    } else {
      final routePending = _observer?.stage == 'opening';
      _observer?.cancel();
      await _pending;
      context.checkCurrent(requireProfile: true);
      // A scheduled route push may not have built its owner yet.
      if (routePending) await WidgetsBinding.instance.endOfFrame;
      context.checkCurrent(requireProfile: true);
      if (coordinator.hasVideoSession && !await _awaitTeardown(coordinator.stopVideoAndExit())) {
        throw const AgentControlException('confirmationRequired', 'The current player cannot leave its route yet.');
      }
    }
    context.checkCurrent(requireProfile: true);
    await _awaitTeardown(music.stop());
    context.checkCurrent(requireProfile: true);
    _observer?.cancel();
    _stopped = true;
    _stopFailed = false;
    return _status(context);
  }

  Future<Map<String, dynamic>> _stopScoped(AgentCommandContext context) async {
    final observer = _observer;
    if (observer == null) {
      throw const AgentControlException('operationChanged', 'The playback operation no longer owns playback.');
    }
    void check() {
      context.checkCurrent(requireProfile: true);
      if (_disposed || _observer != observer) {
        throw const AgentControlException('operationChanged', 'The playback operation changed.');
      }
    }

    check();
    final music = context.context.read<MusicPlaybackService>();
    // A pushed route attaches its owner on the next frame. Do not cancel its
    // launch fence first: that would hide the exact owner we need to stop.
    if (!observer.ownsPlayback && observer.stage == 'opening') {
      await WidgetsBinding.instance.endOfFrame;
      check();
    }
    final coordinator = PlaybackCoordinator.instance;
    if (observer.ownsPlayback) {
      if (_musicLaunch) {
        await _awaitTeardown(music.stop());
      } else if (!await _awaitTeardown(coordinator.stopVideoAndExit())) {
        throw const AgentControlException(
          'confirmationRequired',
          'The current player requires its normal leave or confirmation flow.',
        );
      }
      check();
      // Never stop music here after awaiting video teardown: ordinary UI may
      // already have started a replacement session on the newly exposed route.
    } else {
      if (coordinator.hasVideoSession || music.currentTrack != null || observer.snapshot()['stage'] == 'cancelled') {
        throw const AgentControlException('operationChanged', 'The playback operation no longer owns playback.');
      }
      observer.cancel();
      await _pending;
      check();
      // Cancellation fences pending resolution/open work, but does not grant
      // ownership of a UI session that appeared during that await.
      if (coordinator.hasVideoSession || music.currentTrack != null) {
        throw const AgentControlException('operationChanged', 'The playback operation no longer owns playback.');
      }
    }
    observer.cancel();
    _stopped = true;
    _stopFailed = false;
    return _status(context);
  }

  Future<T> _awaitTeardown<T>(Future<T> work) async {
    try {
      return await work;
    } catch (_) {
      // A native teardown failure must not permit a second core. Rejected
      // preconditions (external playback, operation mismatch, confirmation)
      // never pass through here and cannot poison a later launch.
      _stopFailed = true;
      rethrow;
    }
  }

  Future<Object?> _discover(String command, Map<String, dynamic> arguments, AgentCommandContext context) async {
    final serverId = ServerId(agentString(arguments, 'serverId'));
    final offline = _boolean(arguments, 'offline');
    final limit = arguments.containsKey('limit') ? _integer(arguments, 'limit', min: 1, max: 100) : 30;
    final offset = arguments.containsKey('offset') ? _integer(arguments, 'offset', max: 900) : 0;
    final servers = context.context.read<MultiServerProvider>();
    final downloads = context.context.read<DownloadProvider>();
    final client = offline ? null : _authorizedClient(servers, serverId);
    final authentication = client?.authenticationSessionId;
    void check() {
      context.checkCurrent(requireProfile: true);
      if (_disposed || (!offline && !_clientCurrent(servers, serverId, client!, authentication!))) {
        throw const AgentControlException('sessionChanged', 'The server session changed.');
      }
    }

    if (_targetKind(arguments) == 'channel') {
      if (offline) throw const AgentControlException('unsupportedOptions', 'Channels are not available offline.');
      final channels = await _channels(servers, serverId, client!, check);
      check();
      if (command == 'media.get') {
        final itemId = agentString(arguments, 'itemId');
        final matching = channels.where((channel) => channel.key == itemId).toList();
        if (matching.isEmpty) throw const AgentControlException('itemNotFound', 'The channel was not found.');
        if (matching.length != 1) {
          throw const AgentControlException('selectionRequired', 'The channel is ambiguous across DVR sources.');
        }
        return _channelJson(matching.single);
      }
      if (command == 'media.children') {
        throw const AgentControlException('unsupportedTarget', 'A channel has no playable children.');
      }
      final query = agentString(arguments, 'query').toLowerCase();
      final matching = channels.where((channel) => channel.displayName.toLowerCase().contains(query)).toList();
      return {
        'items': matching.skip(offset).take(limit).map(_channelJson).toList(),
        'offset': offset,
        'totalCount': matching.length,
      };
    }
    if (command == 'media.get') {
      final item = await _resolveItem(serverId, agentString(arguments, 'itemId'), offline, downloads, client);
      check();
      return await _itemJson(item, downloads, check, inspectDownload: true);
    }
    List<MediaItem> items;
    int? total;
    if (command == 'media.search') {
      final query = agentString(arguments, 'query');
      if (query.length > 512) {
        throw const AgentControlException('invalidArguments', 'query is limited to 512 characters.');
      }
      final kind = arguments.containsKey('type') ? agentString(arguments, 'type') : null;
      if (kind != null && !MediaKind.values.any((value) => value.id == kind)) {
        throw const AgentControlException('invalidArguments', 'type must be a neutral media kind.');
      }
      items = offline
          ? downloads.metadata.values
                .where(
                  (item) =>
                      item.serverId == serverId &&
                      downloads.isDownloaded(item.globalKey) &&
                      (item.title ?? '').toLowerCase().contains(query.toLowerCase()),
                )
                .toList()
          : await client!.searchItems(query, limit: offset + limit);
      check();
      items = items.where((item) => kind == null || item.kind.id == kind).toList();
      items = items.skip(offset).take(limit).toList();
    } else {
      final parent = await _resolveItem(serverId, agentString(arguments, 'itemId'), offline, downloads, client);
      check();
      if (!parent.kind.usesLeafWatchCounts) {
        throw const AgentControlException('unsupportedTarget', 'The requested item is not a container.');
      }
      if (offline) {
        items = downloads.metadata.values
            .where(
              (item) =>
                  item.serverId == serverId &&
                  (item.parentId == parent.id || item.grandparentId == parent.id) &&
                  downloads.isDownloaded(item.globalKey),
            )
            .toList();
        total = items.length;
        items = items.skip(offset).take(limit).toList();
      } else {
        final page = parent.kind == MediaKind.playlist
            ? await client!.fetchPlaylistPage(parent.id, start: offset, size: limit)
            : await client!.fetchChildrenPage(parent.id, start: offset, size: limit);
        items = page.items.take(limit).toList();
        total = page.totalCount;
      }
    }
    check();
    return {
      'items': [for (final item in items) await _itemJson(item.copyWith(serverId: serverId), downloads, check)],
      'offset': offset,
      'limit': limit,
      'totalCount': ?total,
    };
  }

  Future<MediaItem> _resolveItem(
    ServerId serverId,
    String itemId,
    bool offline,
    DownloadProvider downloads,
    MediaServerClient? client,
  ) async {
    final item = offline
        ? await downloads.lookupOfflineMetadata(serverId, itemId) ??
              downloads.getMetadata(buildGlobalKey(serverId, itemId))
        : await client!.fetchItem(itemId);
    if (item == null) {
      throw AgentControlException(
        offline ? 'offlineMissing' : 'itemNotFound',
        'The requested item metadata is unavailable.',
      );
    }
    if (offline &&
        item.kind.isPlayable &&
        await downloads.getCompletedDownload(buildGlobalKey(serverId, itemId)) == null) {
      throw const AgentControlException('offlineMissing', 'This profile has no completed download for the item.');
    }
    if (item.id != itemId || (item.serverId != null && item.serverId != serverId)) {
      throw const AgentControlException('itemNotFound', 'The server did not return the exact requested item.');
    }
    return item.copyWith(serverId: serverId);
  }

  Future<Map<String, dynamic>> _itemJson(
    MediaItem item,
    DownloadProvider downloads,
    void Function() check, {
    bool inspectDownload = false,
  }) async {
    Map<String, dynamic>? downloaded;
    if (inspectDownload && item.kind.isPlayable) {
      final row = await downloads.getCompletedDownload(item.globalKey);
      check();
      final exists =
          row != null &&
          await downloads.getVideoFilePath(
                item.globalKey,
                mediaIndex: row.mediaIndex,
                mediaSourceId: row.mediaSourceId,
              ) !=
              null;
      check();
      downloaded = {
        'available': exists,
        if (row != null) 'mediaIndex': row.mediaIndex,
        if (row?.mediaSourceId != null) 'mediaSourceId': row!.mediaSourceId,
      };
    }
    return {
      'serverId': item.serverId,
      'itemId': item.id,
      'type': item.kind.id,
      'title': item.title,
      'playable': item.kind.isPlayable,
      'selectionRequired': item.kind.usesLeafWatchCounts,
      'durationMs': item.durationMs,
      'resumePositionMs': item.viewOffsetMs,
      'downloaded': downloaded ?? {'completed': downloads.isDownloaded(item.globalKey)},
      'versions': [
        for (final entry in (item.mediaVersions ?? const []).indexed)
          {
            'mediaIndex': entry.$1,
            'mediaSourceId': entry.$2.id,
            'width': entry.$2.width,
            'height': entry.$2.height,
            'videoCodec': entry.$2.videoCodec,
            'container': entry.$2.container,
            'playable': entry.$2.isPlayable,
          },
      ],
    };
  }

  Future<List<LiveTvChannel>> _channels(
    MultiServerProvider servers,
    ServerId serverId,
    MediaServerClient client,
    void Function() check,
  ) async {
    if (!servers.liveTvServers.any((server) => server.serverId == serverId)) {
      await servers.checkLiveTvAvailability();
      check();
    }
    final sources = servers.liveTvServers.where((server) => server.serverId == serverId).toList();
    if (sources.isEmpty) {
      throw const AgentControlException('unsupportedTarget', 'Live TV is not available for this server.');
    }
    final channels = <LiveTvChannel>[];
    for (final source in sources) {
      final rows = await client.liveTv.fetchChannels(lineup: source.lineup);
      check();
      channels.addAll(rows.map((channel) => channel.copyWith(serverId: serverId, liveDvrKey: source.dvrKey)));
    }
    return channels;
  }

  Map<String, dynamic> _channelJson(LiveTvChannel channel) => {
    'serverId': channel.serverId,
    'itemId': channel.key,
    'targetKind': 'channel',
    'title': channel.displayName,
    'number': channel.number,
    'playable': channel.drm != true,
  };

  MediaServerClient _authorizedClient(MultiServerProvider servers, ServerId serverId) {
    if (!servers.expectedServerIds.contains(serverId) || !servers.serverIds.contains(serverId)) {
      throw const AgentControlException('serverUnavailable', 'The server is not visible and bound to this profile.');
    }
    if (servers.authErrorServerIds.contains(serverId)) {
      throw const AgentControlException('authenticationRequired', 'The server requires authentication.');
    }
    final client = servers.getClientForServer(serverId);
    if (client == null) {
      throw const AgentControlException('serverUnavailable', 'No authenticated client is bound to this server.');
    }
    return client;
  }

  bool _clientCurrent(
    MultiServerProvider servers,
    ServerId serverId,
    MediaServerClient client,
    Object authentication,
  ) =>
      servers.expectedServerIds.contains(serverId) &&
      servers.serverIds.contains(serverId) &&
      !servers.authErrorServerIds.contains(serverId) &&
      identical(servers.getClientForServer(serverId), client) &&
      identical(client.authenticationSessionId, authentication);

  String _targetKind(Map<String, dynamic> arguments) {
    final kind = arguments['targetKind'] ?? 'item';
    if (kind != 'item' && kind != 'channel') {
      throw const AgentControlException('invalidArguments', 'targetKind must be item or channel.');
    }
    return kind as String;
  }

  bool _boolean(Map<String, dynamic> arguments, String key) {
    if (!arguments.containsKey(key)) return false;
    final value = arguments[key];
    if (value is! bool) throw AgentControlException('invalidArguments', '$key must be a boolean.');
    return value;
  }

  int _integer(Map<String, dynamic> arguments, String key, {int min = 0, int max = 9007199254740991}) {
    final value = arguments[key];
    if (value is! int || value < min || value > max) {
      throw AgentControlException('invalidArguments', '$key must be an integer from $min to $max.');
    }
    return value;
  }

  Duration? _initialPosition(Map<String, dynamic> arguments) {
    final policy = arguments['start'] ?? 'resume';
    if (policy != 'resume' && policy != 'beginning') {
      throw const AgentControlException('invalidArguments', 'start must be beginning or resume.');
    }
    if (arguments.containsKey('positionMs')) {
      return Duration(milliseconds: _integer(arguments, 'positionMs', max: 2147483647));
    }
    return policy == 'beginning' ? Duration.zero : null;
  }

  AgentControlException _safeError(Object error) {
    if (error is AgentControlException) return error;
    if (error is MediaServerAuthException ||
        (error is MediaServerHttpException && (error.statusCode == 401 || error.statusCode == 403))) {
      return const AgentControlException('authenticationRequired', 'The server requires authentication.');
    }
    if (error is MediaServerHttpException) {
      return const AgentControlException('serverUnavailable', 'The server request failed.');
    }
    if (error is UnsupportedError) {
      return const AgentControlException('unsupportedTarget', 'The backend does not support this operation.');
    }
    return const AgentControlException('playbackFailed', 'The playback operation failed.');
  }

  void dispose() {
    _disposed = true;
    _observer?.cancel();
  }
}
