import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../mpv/models.dart';
import '../../mpv/player/player.dart';
import '../../utils/app_logger.dart';

/// Single shared native player reused across every hover-preview card,
/// instead of spinning up a new native player instance per hover — mirrors
/// the existing single-instance discipline already used for the audio
/// player elsewhere in this codebase.
///
/// Muted by default: Netflix's own hover previews are silent, and muting
/// sidesteps any native-audio contention with a background music session
/// (the real video player screen and the music engine already arbitrate
/// that through [PlaybackCoordinator]; this controller intentionally stays
/// out of that entirely by never producing audio in the first place). Users
/// can opt into sound via [toggleMuted] — a [ChangeNotifier] so a speaker
/// icon in the UI can reflect and drive the current state.
class HoverPreviewPlayerController extends ChangeNotifier {
  Player? _player;
  bool _muted = true;

  /// Whether the most recent [play] request failed to actually produce
  /// video — a bad/expired stream URL, a codec the native backend can't
  /// handle, etc. Some titles resolve a trailer/scene-clip URL successfully
  /// but the URL itself doesn't actually play, which otherwise showed up as
  /// a dead blank video surface instead of the same graceful static-backdrop
  /// fallback already used when no preview source resolves at all.
  bool _playbackFailed = false;
  bool get playbackFailed => _playbackFailed;
  StreamSubscription<PlayerError>? _errorSub;

  /// Whether the most recent [play] request reached the end of its clip on
  /// its own (not stopped externally). Callers that show video in place of a
  /// static image (hover-preview cards, the hero banner) should revert to
  /// that image once this flips true rather than freezing on the last frame.
  bool _playbackCompleted = false;
  bool get playbackCompleted => _playbackCompleted;
  StreamSubscription<bool>? _completedSub;

  /// The collapse callback of whichever card currently has its overlay
  /// expanded, if any. Only one card in a row should ever be expanded at
  /// once — without this, hovering across several cards in quick succession
  /// left multiple overlays alive simultaneously, all fighting over this
  /// same shared player and never cleanly tearing each other down.
  VoidCallback? _activeCollapse;

  /// Called by a card the moment it genuinely engages hover (not after the
  /// show-debounce — as soon as the pointer enters), so switching to a new
  /// card collapses whatever was previously expanded immediately instead of
  /// waiting out that card's own exit grace period.
  void collapseActive() {
    _activeCollapse?.call();
    _activeCollapse = null;
  }

  /// Called by a card once its own overlay is actually showing, so a later
  /// [collapseActive] call (from the next card to engage) knows what to
  /// collapse.
  void registerActive(VoidCallback collapseSelf) {
    _activeCollapse = collapseSelf;
  }

  /// Called by a card when its own overlay is going away on its own (e.g.
  /// its exit grace period elapsed) — only clears the slot if it's still
  /// the one that registered it, so it can't accidentally clear a different
  /// card's more recent registration.
  void unregisterActive(VoidCallback collapseSelf) {
    if (_activeCollapse == collapseSelf) {
      _activeCollapse = null;
    }
  }

  /// Monotonically-increasing token so a slow [open] that resolves after
  /// the user has already moved to a different card does not clobber it —
  /// only the request matching the current token is allowed to act.
  int _requestToken = 0;

  /// The underlying player, for widgets (e.g. [Video]) that render its
  /// output directly. Null until the first [play] call.
  Player? get player => _player;

  bool get isMuted => _muted;

  /// Starts playing [streamUrl] at the current mute setting, seeking to
  /// [startAt] first if given. Safe to call again with a different URL
  /// while a preview is already playing — reuses the same native player
  /// rather than disposing and recreating it.
  Future<void> play(String streamUrl, {Duration? startAt}) async {
    final token = ++_requestToken;
    final isNewPlayer = _player == null;
    _player ??= Player();
    final player = _player!;

    // Tunneled playback hands the decoder a dedicated hardware overlay plane
    // — built for one exclusive, stable, fullscreen consumer (the real video
    // player), which is why it defaults on there. This shared preview player
    // is the opposite of that: small-scale, transient, frequently opened and
    // torn down. On Android TV that mismatch showed up as audio playing with
    // no visible video — logcat showed the tunnel resource being allocated
    // and released again within ~150ms of every single preview open()
    // ("Alloc tunnel playback_0 resources" / "release tunnel playback_0
    // resources"), i.e. the hardware overlay never actually held still long
    // enough to paint a frame. Only needs setting once per native player
    // instance, before its first initialize().
    if (isNewPlayer && Platform.isAndroid) {
      await player.setProperty('tunneled-playback', 'no');
    }

    _playbackFailed = false;
    _playbackCompleted = false;
    notifyListeners();

    unawaited(_errorSub?.cancel());
    _errorSub = player.streams.error.listen((error) {
      if (token != _requestToken) return; // stale error from an abandoned hover
      appLogger.w('[hover-preview] player error event (marking playbackFailed): $error');
      _playbackFailed = true;
      notifyListeners();
    });

    unawaited(_completedSub?.cancel());
    _completedSub = player.streams.completed.listen((completed) {
      if (token != _requestToken || !completed) return;
      _playbackCompleted = true;
      notifyListeners();
    });

    try {
      await player.open(
        Media(streamUrl, start: (startAt != null && startAt > Duration.zero) ? startAt : null),
        play: true,
      );
      appLogger.i('[hover-preview] player.open() succeeded for $streamUrl');
    } catch (e) {
      appLogger.w('[hover-preview] player.open() threw (marking playbackFailed): $e');
      if (token == _requestToken) {
        _playbackFailed = true;
        notifyListeners();
      }
      return;
    }
    if (token != _requestToken) return; // superseded by a newer hover
    // Set volume AFTER open(), not before — loading a new source resets the
    // backend's internal volume/audio-track state, which was silently
    // undoing a pre-open setVolume call (the main video player screen
    // applies its own saved volume after opening for the same reason).
    await player.setVolume(_muted ? 0 : 100);
  }

  /// Flips mute on/off and applies it immediately to whatever is currently
  /// playing. Persists across hovers (shared controller, not per-card
  /// state) — matches the expected feel of "I turned the sound on, it
  /// should stay on as I move between previews," not resetting every hover.
  Future<void> toggleMuted() async {
    _muted = !_muted;
    final player = _player;
    if (player != null && !player.disposed) {
      // Called via `unawaited(...)` from the mute button's onTap — same
      // reasoning as stop() below: nothing downstream can catch a thrown
      // Future here, so a transient native hiccup must not become an
      // unhandled exception.
      try {
        await player.setVolume(_muted ? 0 : 100);
      } catch (e) {
        debugPrint('[hover-preview] player.setVolume() failed (non-fatal): $e');
      }
    }
    notifyListeners();
  }

  /// Stops playback without disposing the native player, so the next hover
  /// can reuse it immediately.
  ///
  /// Called via `unawaited(...)` from the card that's collapsing — nothing
  /// downstream can catch a thrown Future here, so a failure must be
  /// swallowed locally rather than propagate as an unhandled exception.
  /// This is a real, observed failure mode: stopping one card's playback
  /// right as the next card's `open()` is racing to (re)initialize the same
  /// shared native player can throw "Failed to initialize player" from the
  /// native layer. That's a transient native-layer hiccup, not something a
  /// hover preview should ever crash over — the next hover's own `play()`
  /// gets a fresh attempt at initializing regardless.
  Future<void> stop() async {
    _requestToken++; // invalidate any in-flight open()/seek()
    unawaited(_errorSub?.cancel());
    _errorSub = null;
    unawaited(_completedSub?.cancel());
    _completedSub = null;
    final player = _player;
    if (player == null || player.disposed) return;
    try {
      await player.stop();
    } catch (e) {
      debugPrint('[hover-preview] player.stop() failed (non-fatal): $e');
    }
  }

  /// Like [stop], but fully releases the native player instead of leaving it
  /// alive for reuse. Call this — not [stop] — right before handing off to
  /// real full-screen playback.
  ///
  /// Android's plugin (ExoPlayerPlugin.kt) is a single app-wide native
  /// instance: `handleInitialize()` early-returns without reinitializing (and
  /// without advancing its own session-generation counter) whenever a
  /// `playerCore` object already exists, regardless of which Dart `Player()`
  /// created it. A plain [stop] leaves that native core alive, so the real
  /// player's own subsequent `Player()` silently inherits a stale session and
  /// its `open()` can hang indefinitely waiting on events tagged with a
  /// generation it never advanced to. Disposing here forces the native side
  /// through its real teardown path (`teardownSession()`), which nulls the
  /// core and bumps the generation — the next [play] call on this
  /// controller builds a fresh [Player] from scratch, and the real player's
  /// own initialize() gets a genuinely clean native core.
  Future<void> stopForHandoff() async {
    _requestToken++;
    unawaited(_errorSub?.cancel());
    _errorSub = null;
    unawaited(_completedSub?.cancel());
    _completedSub = null;
    final player = _player;
    _player = null;
    if (player == null || player.disposed) return;
    try {
      await player.dispose();
    } catch (e) {
      debugPrint('[hover-preview] player.dispose() (handoff) failed (non-fatal): $e');
    }
  }

  /// Fully releases the native player. Call when the surface hosting hover
  /// previews (e.g. the whole row/grid) is leaving the tree, not per-card.
  ///
  /// `ChangeNotifier.dispose()` is synchronous, so the actual async native
  /// player teardown can't happen inside this override — it's fired and
  /// left to complete on its own rather than awaited, which is fine here
  /// since nothing needs to observe its completion once the controller
  /// itself is going away.
  @override
  void dispose() {
    _requestToken++;
    unawaited(_errorSub?.cancel());
    unawaited(_completedSub?.cancel());
    final player = _player;
    _player = null;
    if (player != null && !player.disposed) {
      unawaited(player.dispose());
    }
    super.dispose();
  }
}
