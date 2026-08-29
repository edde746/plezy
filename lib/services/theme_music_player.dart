import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mpv/models.dart';
import '../mpv/player/player.dart';
import 'playback_coordinator.dart';
import '../utils/app_logger.dart';

/// Profile-scoped owner of the single native audio core used for theme music.
///
/// Screens supply an opaque owner when requesting playback. A stale screen
/// cannot pause or stop a theme selected by a newer screen, and music/video
/// claim the core through [PlaybackCoordinator] before creating their player.
class ThemeMusicService extends ChangeNotifier {
  ThemeMusicService({Player Function()? playerFactory, PlaybackCoordinator? coordinator})
    : _playerFactory = playerFactory ?? Player.audio,
      _coordinator = coordinator ?? PlaybackCoordinator.instance {
    _stopAndDisposeCallback = _stopAndDisposeForClaim;
    _coordinator.registerThemeSession(stopAndDispose: _stopAndDisposeCallback);
  }

  static const _fadeInDuration = Duration(milliseconds: 1200);
  static const _fadeOutDuration = Duration(milliseconds: 400);
  static const _fadeStep = Duration(milliseconds: 40);
  static const _repeatDelay = Duration(seconds: 5);
  static const targetVolume = 35.0;

  final Player Function() _playerFactory;
  final PlaybackCoordinator _coordinator;
  late final Future<void> Function() _stopAndDisposeCallback;
  Player? _player;
  Timer? _fadeTimer;
  Timer? _repeatTimer;
  Completer<void>? _fadeCompleter;
  StreamSubscription<bool>? _completedSubscription;
  Future<void> _command = Future.value();
  Object? _owner;
  String? _requestedUrl;
  bool _paused = false;
  bool _disposed = false;

  /// Selects [url] for [owner]. A later owner always supersedes an earlier
  /// request, including work still waiting in the command queue.
  Future<void> play(Object owner, String url) {
    if (_disposed || url.isEmpty) return Future.value();
    if (identical(_owner, owner) && _requestedUrl == url && !_paused) return Future.value();
    _repeatTimer?.cancel();
    _owner = owner;
    _requestedUrl = url;
    _paused = false;

    return _enqueue(() async {
      if (!_isCurrent(owner, url)) return;
      await _coordinator.claimTheme();
      if (!_isCurrent(owner, url)) return;
      await _start(url);
    });
  }

  bool _isCurrent(Object owner, String url) => !_disposed && identical(_owner, owner) && _requestedUrl == url;

  Future<void> _start(String url) async {
    if (_disposed || _requestedUrl != url) return;
    final player = _player ??= _createPlayer();
    try {
      await player.setVolume(0);
      if (_disposed || _requestedUrl != url) return;
      await player.setProperty('loop-file', 'no');
      await player.open(Media(url), play: true);
      unawaited(_fadeVolume(player, from: 0, to: targetVolume, duration: _fadeInDuration));
    } catch (e, st) {
      appLogger.d('ThemeMusicService: failed to start theme music', error: e, stackTrace: st);
    }
  }

  Player _createPlayer() {
    final player = _playerFactory();
    _completedSubscription = player.streams.completed.listen(_onPlayerCompleted);
    return player;
  }

  void _onPlayerCompleted(bool completed) {
    if (!completed || _disposed || _paused) return;
    final owner = _owner;
    final url = _requestedUrl;
    if (owner == null || url == null) return;

    _repeatTimer?.cancel();
    _repeatTimer = Timer(_repeatDelay, () {
      _repeatTimer = null;
      unawaited(_enqueue(() async {
        if (!_isCurrent(owner, url) || _paused) return;
        await _start(url);
      }));
    });
  }

  /// Fades out and pauses in place (position retained), e.g. while the app is
  /// backgrounded or the hero carousel is manually paused. Pair with
  /// [resume]. Safe to call when nothing is playing or already paused.
  Future<void> pause(Object owner) {
    if (!identical(_owner, owner)) return Future.value();
    _repeatTimer?.cancel();
    _paused = true;
    return _enqueue(() async {
      if (!identical(_owner, owner)) return;
      final player = _player;
      if (player == null || _requestedUrl == null) return;
      try {
        await _fadeVolume(player, from: targetVolume, to: 0, duration: _fadeOutDuration);
        await player.pause();
      } catch (e, st) {
        appLogger.d('ThemeMusicService: failed to pause theme music', error: e, stackTrace: st);
      }
    });
  }

  /// Resumes the current theme when requested by its owner.
  Future<void> resume(Object owner) {
    if (!identical(_owner, owner) || !_paused) return Future.value();
    _paused = false;
    return _enqueue(() async {
      if (!identical(_owner, owner) || _paused) return;
      final player = _player;
      if (player == null || _requestedUrl == null) return;
      try {
        await player.play();
        await _fadeVolume(player, from: 0, to: targetVolume, duration: _fadeInDuration);
      } catch (e, st) {
        appLogger.d('ThemeMusicService: failed to resume theme music', error: e, stackTrace: st);
      }
    });
  }

  /// Stops the active theme only when [owner] still owns it.
  Future<void> stop(Object owner) {
    if (!identical(_owner, owner)) return Future.value();
    _repeatTimer?.cancel();
    _owner = null;
    _requestedUrl = null;
    _paused = false;
    return _enqueue(_stopCurrent);
  }

  Future<void> _stopAndDisposeForClaim() {
    _repeatTimer?.cancel();
    _owner = null;
    _requestedUrl = null;
    _paused = false;
    return _enqueue(() async {
      _fadeTimer?.cancel();
      _fadeCompleter?.complete();
      _fadeCompleter = null;
      await _completedSubscription?.cancel();
      _completedSubscription = null;
      final player = _player;
      _player = null;
      if (player == null) return;
      try {
        await player.stop();
      } catch (e, st) {
        appLogger.d('ThemeMusicService: failed to stop theme music', error: e, stackTrace: st);
      }
      try {
        await player.dispose();
      } catch (e, st) {
        appLogger.d('ThemeMusicService: failed to dispose audio player', error: e, stackTrace: st);
      }
    });
  }

  Future<void> _stopCurrent() async {
    final player = _player;
    if (player == null) return;
    try {
      await _fadeVolume(player, from: targetVolume, to: 0, duration: _fadeOutDuration);
      await player.stop();
    } catch (e, st) {
      appLogger.d('ThemeMusicService: failed to stop theme music', error: e, stackTrace: st);
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _command = _command.then((_) => operation(), onError: (_, _) => operation());
    return _command;
  }

  Future<void> _fadeVolume(Player player, {required double from, required double to, required Duration duration}) {
    _fadeTimer?.cancel();
    _fadeCompleter?.complete();
    final steps = (duration.inMilliseconds / _fadeStep.inMilliseconds).round().clamp(1, 1000);
    final completer = Completer<void>();
    _fadeCompleter = completer;
    var step = 0;
    _fadeTimer = Timer.periodic(_fadeStep, (timer) async {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      try {
        await player.setVolume(from + (to - from) * t);
      } catch (_) {
        // Player may have been disposed mid-fade; the timer cancels below.
      }
      if (step >= steps) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        if (identical(_fadeCompleter, completer)) _fadeCompleter = null;
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _repeatTimer?.cancel();
    _coordinator.unregisterThemeSession(_stopAndDisposeCallback);
    unawaited(_stopAndDisposeForClaim());
    super.dispose();
  }
}
