import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/app_logger.dart';

/// The kinds of output route the system distinguishes, collapsed to the ones a
/// listener actually tells apart.
///
/// Only [airPlay] carries a decision. The rest exist so the picker can name
/// what it is currently coming out of — "AirPods", "iPhone Speaker" — rather
/// than saying "This device" over a route that is not this device at all.
enum AudioRouteKind { speaker, headphones, bluetooth, airPlay, car, wired, unknown }

/// Where the operating system is sending this app's audio right now.
@immutable
class AudioRoute {
  /// The system's own name for the destination, e.g. `Dining Room`,
  /// `iPhone Speaker`, `Jack's AirPods`. Never invented here: an empty name
  /// means the system reported none, and the UI falls back to the kind.
  final String name;

  final AudioRouteKind kind;

  const AudioRoute({required this.name, required this.kind});

  bool get isAirPlay => kind == AudioRouteKind.airPlay;

  static const AudioRoute unknown = AudioRoute(name: '', kind: AudioRouteKind.unknown);

  static AudioRouteKind parseKind(String? raw) => switch (raw) {
    'speaker' => AudioRouteKind.speaker,
    'headphones' => AudioRouteKind.headphones,
    'bluetooth' => AudioRouteKind.bluetooth,
    'airPlay' => AudioRouteKind.airPlay,
    'car' => AudioRouteKind.car,
    'wired' => AudioRouteKind.wired,
    _ => AudioRouteKind.unknown,
  };

  static AudioRoute fromMap(Map<Object?, Object?> map) =>
      AudioRoute(name: (map['name'] as String?)?.trim() ?? '', kind: parseKind(map['kind'] as String?));

  @override
  bool operator ==(Object other) => other is AudioRoute && other.name == name && other.kind == kind;

  @override
  int get hashCode => Object.hash(name, kind);

  @override
  String toString() => 'AudioRoute($name, $kind)';
}

/// Observes the system audio route.
///
/// ### Why this is not a [MusicOutput]
///
/// A Music Assistant player is something the app addresses: it has an id, it
/// can be enumerated, and a command sent to it plays audio there. An AirPlay
/// destination is none of those. iOS exposes no way to list AirPlay receivers
/// and no way to select one — the only supported control is
/// `AVRoutePickerView`, which the *system* populates and acts on. So AirPlay
/// cannot be modelled as one more entry in the output list without inventing a
/// list the app is not allowed to have.
///
/// What it is instead: a property of the local engine. When the route is
/// AirPlay the phone is still the thing playing — decoding, holding the queue,
/// spending its battery — and the audio is carried onward by the OS. That is a
/// genuinely different arrangement from Music Assistant driving a Sonos
/// directly, and the difference is exactly what the picker has to make legible.
///
/// So this service *reports* and never commands, and
/// [MusicOutputController]'s player handling is untouched.
///
/// Everywhere but iOS this reports [supported] false and the AirPlay option
/// does not appear: the route concept is Apple's, and Android's equivalent is
/// a different mechanism that this does not pretend to cover.
class AudioRouteService extends ChangeNotifier {
  AudioRouteService({MethodChannel? methodChannel, EventChannel? eventChannel, bool? supported})
    : _method = methodChannel ?? const MethodChannel(_methodChannelName),
      _events = eventChannel ?? const EventChannel(_eventChannelName),
      _supported = supported ?? _defaultSupported;

  static const String _methodChannelName = 'com.plezy/audio_route';
  static const String _eventChannelName = 'com.plezy/audio_route/events';

  /// Platform-view type vended by `AudioRoutePlugin`.
  static const String routeButtonViewType = 'com.plezy/airplay_route_button';

  static bool get _defaultSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  final MethodChannel _method;
  final EventChannel _events;
  final bool _supported;

  StreamSubscription<dynamic>? _subscription;
  AudioRoute _route = AudioRoute.unknown;
  bool _disposed = false;

  /// Whether this platform has a system route to report at all.
  bool get supported => _supported;

  AudioRoute get route => _route;

  /// True when audio leaving this app is being carried to an AirPlay receiver.
  bool get isAirPlay => _supported && _route.isAirPlay;

  /// Begin observing. Safe to call more than once.
  Future<void> start() async {
    if (_disposed || !_supported || _subscription != null) return;
    // Read once up front as well as subscribing: the event channel emits on
    // subscribe, but a failure there must still leave a usable answer rather
    // than a permanently blank route.
    await refresh();
    if (_disposed) return;
    _subscription = _events.receiveBroadcastStream().listen(
      (event) {
        if (event is Map<Object?, Object?>) _publish(AudioRoute.fromMap(event));
      },
      onError: (Object error, StackTrace stackTrace) {
        appLogger.w('Audio route stream failed', error: error, stackTrace: stackTrace);
      },
    );
  }

  /// Ask the platform for the route now.
  ///
  /// Needed on resume as well as at start: route changes that happen while the
  /// app is backgrounded do post the notification, but a stream torn down over
  /// a suspend will have missed them.
  Future<void> refresh() async {
    if (_disposed || !_supported) return;
    try {
      final map = await _method.invokeMethod<Map<Object?, Object?>>('getRoute');
      if (map != null) _publish(AudioRoute.fromMap(map));
    } on PlatformException catch (e) {
      // The plugin is missing on this build. Not an error worth surfacing:
      // the AirPlay option simply does not appear.
      appLogger.d('Audio route unavailable: ${e.message ?? e.code}');
    } on MissingPluginException {
      appLogger.d('Audio route plugin not registered on this platform');
    }
  }

  void _publish(AudioRoute route) {
    if (_disposed || route == _route) return;
    _route = route;
    appLogger.i('Audio route is now ${route.name} (${route.kind.name})');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
