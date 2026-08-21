import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

/// What the vehicle says about driver distraction right now.
enum CarUxRestrictionState {
  /// No platform answer: either not a car, or `android.car` was unavailable.
  /// Callers fall back to their previous, lifecycle-derived behaviour.
  unknown,

  /// The vehicle is parked (or this display is unrestricted): ordinary rules.
  unrestricted,

  /// Distraction optimization is required — playback must stop and stay stopped.
  restricted,
}

/// Live `CarUxRestrictionsManager` state, mirrored from the Android side.
///
/// Plezy used to derive its car playback authority from [AppLifecycleState], which cannot tell a
/// driving car apart from a parked car whose driver simply opened navigation. That made background
/// audio impossible on a head unit even while parked. This service supplies the signal the platform
/// documents for exactly that case; [CarUxRestrictionState.unknown] preserves the old behaviour
/// wherever the vehicle cannot answer.
class CarUxRestrictionsService {
  CarUxRestrictionsService._();

  static final CarUxRestrictionsService instance = CarUxRestrictionsService._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel('com.plezy/car_restrictions');

  static CarUxRestrictionState? _debugOverride;

  final ValueNotifier<CarUxRestrictionState> _state = ValueNotifier(CarUxRestrictionState.unknown);
  bool _started = false;
  bool _stalled = false;
  Completer<void> _firstAnswer = Completer<void>();
  Future<void>? _inFlight;

  /// Whether the platform says a verdict is on its way — see [_apply].
  bool _pendingVerdict = false;

  /// Current verdict. Reading it on a car starts the platform subscription, so callers never have
  /// to sequence an explicit initialization; off-car it is a constant.
  ///
  /// Synchronous, so it reads [CarUxRestrictionState.unknown] until the first platform answer
  /// lands. Anything that configures a session from this value must first await [ensureResolved].
  CarUxRestrictionState get state {
    if (_debugOverride != null) return _debugOverride!;
    if (!PlatformDetector.isAutomotive()) return CarUxRestrictionState.unknown;
    ensureStarted();
    return _state.value;
  }

  /// Notifies on every transition. Listeners are only meaningful on a car.
  ValueListenable<CarUxRestrictionState> get listenable => _state;

  /// Begins observing the vehicle. Idempotent, and a no-op off Android Automotive OS.
  void ensureStarted() {
    if (_started || !PlatformDetector.isAutomotive()) return;
    _started = true;
    channel.setMethodCallHandler(_handlePlatformCall);
    unawaited(_refresh());
  }

  /// Waits for a definitive answer, and retries once if the vehicle answered without giving one.
  ///
  /// Callers that latch behaviour on the verdict — enabling the foreground service, asking for the
  /// notification permission — must await this, or a cold start races the platform and configures
  /// the session as if the car were mute. [timeout] is the whole budget, not per attempt: a car
  /// service that never answers must not hold up playback, and the caller simply keeps the
  /// lifecycle fallback until [listenable] reports the late answer.
  Future<void> ensureResolved({Duration timeout = const Duration(seconds: 2)}) async {
    if (_debugOverride != null || !PlatformDetector.isAutomotive()) return;
    ensureStarted();
    if (_state.value != CarUxRestrictionState.unknown) return;
    // A deadline already blew on this platform — a call still in flight, or a promised push that
    // never came. Waiting again would spend the budget on every open for as long as the car service
    // stays wedged, and neither a platform call nor a push can be cancelled. Still ask, without
    // waiting: when the previous call has landed this issues a fresh `getState`, which is how the
    // platform retries a connection that came up without observing the vehicle. While one is still
    // in flight the de-duplication below makes it a no-op, and its answer reconfigures the session
    // when it arrives.
    if (_stalled) {
      unawaited(_refresh());
      return;
    }

    final budget = Stopwatch()..start();
    if (!_firstAnswer.isCompleted) {
      await _firstAnswer.future.timeout(timeout, onTimeout: () {});
      if (!_firstAnswer.isCompleted) {
        _stalled = true;
        return;
      }
      if (_state.value != CarUxRestrictionState.unknown) return;
    }

    // The answer was "no verdict"; a car service that was not ready at startup can still connect
    // later, so try once more inside what is left of the budget rather than latching mute forever.
    var remaining = timeout - budget.elapsed;
    if (remaining <= Duration.zero) return;
    try {
      await _refresh().timeout(remaining);
    } on TimeoutException {
      _stalled = true;
      return;
    }
    if (_state.value != CarUxRestrictionState.unknown) return;

    // The platform is connected to the car service but has not been handed a verdict yet, so one is
    // genuinely coming — over a push, not a return value. Waiting for it is the whole point of this
    // method: the alternative is configuring the session as if this were a phone.
    if (!_pendingVerdict) return;
    remaining = timeout - budget.elapsed;
    if (remaining <= Duration.zero) return;
    await _awaitVerdict(remaining);
    // Still nothing: stop holding every later open for a push that is not coming on any schedule.
    if (_state.value == CarUxRestrictionState.unknown) _stalled = true;
  }

  Future<void> _awaitVerdict(Duration remaining) {
    final settled = Completer<void>();
    void check() {
      if (_state.value != CarUxRestrictionState.unknown && !settled.isCompleted) settled.complete();
    }

    _state.addListener(check);
    return settled.future.timeout(remaining, onTimeout: () {}).whenComplete(() => _state.removeListener(check));
  }

  Future<void> _refresh() => _inFlight ??= _readState().whenComplete(() => _inFlight = null);

  Future<void> _readState() async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('getState');
      _apply(result);
    } on MissingPluginException {
      // Non-Android host or an engine without the channel: stay unknown.
    } catch (e, stackTrace) {
      appLogger.w('Failed to read car UX restrictions', error: e, stackTrace: stackTrace);
    } finally {
      if (!_firstAnswer.isCompleted) _firstAnswer.complete();
    }
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method != 'onChanged') return null;
    final args = call.arguments;
    if (args is Map) {
      // A push carrying `supported: false` means the car service died. Going back to unknown puts
      // callers on lifecycle gating instead of a verdict nothing is maintaining any more.
      _apply(args.cast<String, dynamic>());
    }
    return null;
  }

  void _apply(Map<String, dynamic>? result) {
    if (result == null || result['supported'] != true) {
      // `pending` means the platform holds a live car connection that has not been handed a verdict
      // yet, so one is still coming; without it there is nothing to wait for on this device.
      _pendingVerdict = result != null && result['pending'] == true;
      // Losing a verdict we had means the platform is alive and talking, so waiting out the
      // reconnect is worth one budget again.
      if (_state.value != CarUxRestrictionState.unknown) _stalled = false;
      _state.value = CarUxRestrictionState.unknown;
      return;
    }
    _pendingVerdict = false;
    _stalled = false;
    _setRestricted(result['requiresDistractionOptimization'] == true);
  }

  void _setRestricted(bool restricted) {
    final next = restricted ? CarUxRestrictionState.restricted : CarUxRestrictionState.unrestricted;
    if (_state.value == next) return;
    appLogger.d('Car UX restrictions: ${next.name}');
    _state.value = next;
  }

  @visibleForTesting
  static void debugSetOverride(CarUxRestrictionState? value) => _debugOverride = value;

  @visibleForTesting
  void debugReset() {
    _debugOverride = null;
    _started = false;
    _stalled = false;
    _pendingVerdict = false;
    _inFlight = null;
    _firstAnswer = Completer<void>();
    _state.value = CarUxRestrictionState.unknown;
    channel.setMethodCallHandler(null);
  }
}
