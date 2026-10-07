import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../utils/app_logger.dart';
import 'playback_coordinator.dart';

/// Detail-page audio without a music queue, media session, or progress reports.
///
/// Theme songs share the music player's native channel, so one controller
/// ([instance]) owns them. Detail screens [request] their theme and [release]
/// it when they stop being visible. A release waits [releaseGrace] for the next
/// screen, so moving between a show, its seasons and its episodes keeps the
/// same song playing instead of restarting it.
///
/// Themes fade in over [fadeIn] and out over [fadeOut], except when video or
/// music claims the channel: those cut the theme off so playback isn't delayed.
class ThemeSongController {
  ThemeSongController({
    Player Function()? playerFactory,
    PlaybackCoordinator? coordinator,
    this.releaseGrace = const Duration(milliseconds: 750),
    this.fadeIn = const Duration(milliseconds: 1500),
    this.fadeOut = const Duration(milliseconds: 1000),
  }) : _playerFactory = playerFactory ?? (() => Player.audio(exclusiveAudio: false)) {
    (coordinator ?? PlaybackCoordinator.instance).registerThemeSession(() => stop(fade: false));
  }

  static ThemeSongController get instance => _instance;
  static ThemeSongController _instance = ThemeSongController();

  @visibleForTesting
  static void debugSetInstance(ThemeSongController controller) => _instance = controller;

  static const _fadeStep = Duration(milliseconds: 50);

  final Player Function() _playerFactory;
  final Duration releaseGrace;
  final Duration fadeIn;
  final Duration fadeOut;

  Object? _owner;
  int _request = 0;
  Timer? _releaseTimer;

  Player? _player;
  String? _url;
  bool _started = false;
  double _volume = 30;

  /// The level last sent to [_player], which lags [_volume] during a fade.
  double _playerVolume = 0;
  int _generation = 0;
  int _hardStops = 0;
  Future<void> _operations = Future<void>.value();

  // Native work is serialized: a replacement must wait until the previous
  // player's pending open and dispose have both settled.
  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operations.then((_) => operation());
    _operations = next.catchError((Object error, StackTrace stack) {
      appLogger.d('Theme song playback failed', error: error, stackTrace: stack);
    });
    return _operations;
  }

  /// Plays [owner]'s theme, replacing any other. A theme already playing from
  /// the same URL keeps going; no theme for [owner] stops the current one.
  Future<void> request(Object owner, {required Future<String?> Function() resolveUrl, required double volume}) async {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _owner = owner;
    final request = ++_request;
    _volume = volume.clamp(0, 100).toDouble();
    String? url;
    try {
      url = await resolveUrl();
    } catch (error, stack) {
      appLogger.d('Theme song unavailable', error: error, stackTrace: stack);
    }
    if (_owner != owner || request != _request) return;
    if (url == null || url.isEmpty) return stop();
    return _playUrl(url);
  }

  Future<void> _playUrl(String url) {
    final generation = ++_generation;
    bool current() => generation == _generation;
    return _enqueue(() async {
      if (!current()) return;
      final existing = _player;
      if (existing != null && _started && _url == url) {
        // Also takes back a theme that was fading out, or whose fade-in was cut short.
        await _fadeTo(existing, () => _volume, fadeIn, current);
        return;
      }
      if (existing != null && _started) {
        await _fadeTo(existing, () => 0, fadeOut, current);
        if (!current()) return;
      }
      await _disposePlayer();
      if (!current()) return;
      final player = _playerFactory();
      _player = player;
      _url = url;
      // Set volume before opening so the first samples use the starting level.
      _playerVolume = fadeIn > Duration.zero ? 0 : _volume;
      await player.setVolume(_playerVolume);
      if (!current()) return;
      await player.open(Media(url), play: false);
      if (!current()) return;
      // No audio focus request: on Android that is a permanent gain that would
      // stop the user's other audio for good. Themes mix, like the iOS session.
      await player.play();
      _started = true;
      if (fadeIn > Duration.zero) await _fadeTo(player, () => _volume, fadeIn, current);
    });
  }

  /// Ramps [player] from its current level to [target], stopping early once
  /// [active] turns false. Each step covers an even share of what is left, so
  /// a target changed mid-fade (the volume setting) is ramped to, not jumped to.
  Future<void> _fadeTo(Player player, double Function() target, Duration duration, bool Function() active) async {
    final steps = duration.inMilliseconds ~/ _fadeStep.inMilliseconds;
    if (steps == 0) {
      _playerVolume = target();
      await player.setVolume(_playerVolume);
      return;
    }
    for (var remaining = steps; remaining > 0; remaining--) {
      await Future<void>.delayed(_fadeStep);
      if (!active()) return;
      final level = target();
      _playerVolume = remaining == 1 ? level : _playerVolume + (level - _playerVolume) / remaining;
      await player.setVolume(_playerVolume);
    }
  }

  /// [owner] no longer shows its theme. Unless [immediate], the song keeps
  /// playing for [releaseGrace] in case the next screen requests the same one.
  void release(Object owner, {bool immediate = false}) {
    if (_owner != owner) return;
    _owner = null;
    _releaseTimer?.cancel();
    _releaseTimer = null;
    if (immediate) {
      unawaited(stop());
    } else {
      _releaseTimer = Timer(releaseGrace, () => unawaited(stop()));
    }
  }

  /// Waits behind a running fade, which already follows the new level.
  Future<void> setVolume(double volume) {
    _volume = volume.clamp(0, 100).toDouble();
    return _enqueue(() async {
      final player = _player;
      if (player == null) return;
      _playerVolume = _volume;
      await player.setVolume(_volume);
    });
  }

  /// Stops the theme, fading it out first unless [fade] is false. Completes
  /// once its native core is disposed, or once a newer request takes the
  /// theme over mid-fade. A later unfaded stop cuts the fade short.
  Future<void> stop({bool fade = true}) {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _owner = null;
    final generation = ++_generation;
    if (!fade) ++_hardStops;
    final hardStops = _hardStops;
    return _enqueue(() async {
      final player = _player;
      if (fade && player != null && _started) {
        await _fadeTo(player, () => 0, fadeOut, () => generation == _generation);
        // A newer request decides the player's fate; an unfaded stop disposes it here.
        if (generation != _generation && hardStops == _hardStops) return;
      }
      await _disposePlayer();
    });
  }

  Future<void> _disposePlayer() async {
    final player = _player;
    _player = null;
    _url = null;
    _started = false;
    await player?.dispose();
  }
}
