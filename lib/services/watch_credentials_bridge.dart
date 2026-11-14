import 'dart:async';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../media/ids.dart';
import '../models/audio_quality_preset.dart';
import '../models/transcode_quality_preset.dart';
import '../services/multi_server_manager.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/plex_url_helper.dart';

/// Answers the Apple Watch when it asks how to reach Plex.
///
/// The watch app browses and plays on its own — it has its own Plex client and
/// its own audio session, because a watch that can only mirror a phone is a
/// remote control, not a player. What it cannot do is discover a server and
/// sign in on a screen that size, so on first run it asks the phone, which is
/// already signed in.
///
/// That is the whole contract: one question, one answer, and a retraction when
/// the phone no longer has a Plex server to give. The richer
/// phone-to-watch bridge on the branch this came from also shipped queue
/// transfer and now-playing mirroring, both written against a metadata model
/// this branch no longer has. Porting them wholesale would have meant carrying
/// a second, older idea of what a track is; they can come back as their own
/// piece of work, against the model that exists.
class WatchCredentialsBridge {
  /// Private-named formal: callers pass `serverManager:`.
  WatchCredentialsBridge({required this._serverManager, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  /// Named by the watch side, which predates the rename of this app.
  static const String channelName = 'com.edde746.plezy/watch';

  /// How long the phone must stay without a Plex server before the watch is
  /// told to sign out. A profile switch removes every server and adds them back
  /// moments later, and that must not cost the watch its credentials.
  static const Duration signOutGrace = Duration(seconds: 5);

  final MultiServerManager _serverManager;
  final MethodChannel _channel;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Set once credentials have gone to native this run. A phone that has not
  /// connected yet also has no Plex client, so an empty manager only means
  /// signed out when there was something in it before.
  bool _hasPushedCredentials = false;
  Timer? _signOutTimer;

  void start() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getCredentials':
          return credentials();
        case 'resolveMusicStreamUrl':
          final args = call.arguments;
          if (args is! Map) return null;
          final ratingKey = args['ratingKey']?.toString();
          if (ratingKey == null || ratingKey.isEmpty) return null;
          return resolveMusicStreamUrl(ratingKey, machineIdentifier: args['machineIdentifier']?.toString());
        default:
          return null;
      }
    });
    _subscriptions
      ..add(_serverManager.statusStream.listen((_) => unawaited(_pushCredentialsToNative())))
      ..add(
        _serverManager.connectProgressStream.listen((event) {
          if (event.online) unawaited(_pushCredentialsToNative());
        }),
      );
    unawaited(_pushCredentialsToNative());
  }

  Future<void> _pushCredentialsToNative() async {
    final creds = credentials();
    if (creds == null) {
      if (_hasPushedCredentials) _signOutTimer ??= Timer(signOutGrace, _retractCredentials);
      return;
    }
    _signOutTimer?.cancel();
    _signOutTimer = null;
    _hasPushedCredentials = true;
    try {
      await _channel.invokeMethod('updatePlexCredentials', creds);
    } catch (e) {
      appLogger.d('Could not push Plex credentials to native watch bridge: $e');
    }
  }

  Future<void> _retractCredentials() async {
    _signOutTimer = null;
    if (credentials() != null) return;
    _hasPushedCredentials = false;
    try {
      await _channel.invokeMethod('clearPlexCredentials');
    } catch (e) {
      appLogger.d('Could not clear Plex credentials on the native watch bridge: $e');
    }
  }

  Future<void> dispose() async {
    _signOutTimer?.cancel();
    _signOutTimer = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _channel.setMethodCallHandler(null);
  }

  /// The first signed-in Plex server, or null when there is none to give.
  ///
  /// Null rather than an error: a watch asking before its owner has added a
  /// server is asking a reasonable question early, and the watch has its own
  /// manual setup screen to fall back on.
  ///
  /// The owner's own server comes before one shared with them: it is where
  /// their playlists live.
  ///
  /// `fallbackUrls` (newline-separated) are the server's remote addresses. The
  /// phone's current address is usually the LAN one, which a watch out on a
  /// run on cellular cannot reach.
  Map<String, String>? credentials() {
    final ids = _serverManager.serverIds.toList()..sort((a, b) => _owned(b) - _owned(a));
    for (final id in ids) {
      final client = _serverManager.getClient(ServerId(id));
      if (client is! PlexClient) continue;
      final token = client.config.token;
      if (token == null || token.isEmpty) continue;
      appLogger.d('Sending Plex credentials to the watch');
      final baseUrl = client.config.baseUrl;
      final fallbacks = _serverManager.plexRemoteUris(ServerId(id)).where((uri) => uri != baseUrl);
      // A Plex server's id is its machine identifier, which the watch checks
      // a LAN address against before trusting it.
      return {
        'serverUrl': baseUrl,
        'token': token,
        'machineIdentifier': id,
        if (fallbacks.isNotEmpty) 'fallbackUrls': fallbacks.join('\n'),
      };
    }
    appLogger.d('No signed-in Plex server to give the watch');
    return null;
  }

  int _owned(String id) => _serverManager.isOwnerOrAdmin(ServerId(id)) ? 1 : 0;

  /// Resolve a watch-playable music stream URL using the phone's Plex client
  /// (optimized LAN endpoint + transcode handshake).
  ///
  /// [machineIdentifier] names the server the watch got [ratingKey] from.
  /// Rating keys are numbered per server, so asking the next server along for
  /// the same one finds a different track, not the same track somewhere else.
  /// Without it (a watch that does not know yet) that is the first Plex server,
  /// the one [credentials] hands out.
  Future<Map<String, String>?> resolveMusicStreamUrl(String ratingKey, {String? machineIdentifier}) async {
    for (final id in _serverManager.serverIds) {
      if (machineIdentifier != null && id != machineIdentifier) continue;
      final client = _serverManager.getClient(ServerId(id));
      if (client is! PlexClient) continue;
      final token = client.config.token;
      if (token == null || token.isEmpty) continue;

      final sessionId = const Uuid().v4();
      final transcodeSessionId = const Uuid().v4();
      final result = await client.buildMusicTranscodeStartPath(
        ratingKey: ratingKey,
        mediaIndex: 0,
        preset: AudioQualityPreset.medium,
        sessionIdentifier: sessionId,
        transcodeSessionId: transcodeSessionId,
      );

      if (result.outcome == TranscodeDecisionOutcome.transcodeOk && result.startPath != null) {
        final url = '${client.config.baseUrl}${result.startPath}'.withPlexToken(token);
        appLogger.d('Resolved watch music stream URL for ratingKey=$ratingKey');
        return {'streamUrl': url};
      }
      break;
    }
    appLogger.d('Could not resolve watch music stream URL for ratingKey=$ratingKey');
    return null;
  }
}
