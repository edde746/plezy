import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'platform_detector.dart';

/// Physical edge holding iPhone Duo's system vertical bar (status items, and
/// for native apps the tab bar and toolbars).
enum VerticalBarEdge { left, right }

enum HingeStatus { closed, partiallyOpen, fullyOpen, unknown }

/// iPhone Duo layout signals bridged from `PlezyFlutterViewController`.
/// Empty on every other device and on iOS before 27.1.
@immutable
class IphoneDuoState {
  const IphoneDuoState({this.verticalBarEdge, this.hingeStatus, this.folds = const [], this.occlusions = const []});

  static const empty = IphoneDuoState();

  /// The system's preferred bar edge. The bar is only present when the safe
  /// area on that edge is non-zero — see [IphoneDuo.verticalBarEdgeOf].
  final VerticalBarEdge? verticalBarEdge;
  final HingeStatus? hingeStatus;

  /// Active fold (division) regions, in root logical pixels.
  final List<Rect> folds;

  /// Active occlusions (status bar + camera, inner camera), in root logical pixels.
  final List<Rect> occlusions;

  factory IphoneDuoState.fromMap(Map<Object?, Object?> map) {
    List<Rect> rects(Object? value) => [
      for (final raw in (value as List<Object?>? ?? const []))
        if (raw is Map)
          Rect.fromLTWH(
            (raw['x'] as num).toDouble(),
            (raw['y'] as num).toDouble(),
            (raw['width'] as num).toDouble(),
            (raw['height'] as num).toDouble(),
          ),
    ];

    return IphoneDuoState(
      verticalBarEdge: switch (map['verticalBarEdge']) {
        'left' => VerticalBarEdge.left,
        'right' => VerticalBarEdge.right,
        _ => null,
      },
      hingeStatus: switch (map['hingeStatus']) {
        'closed' => HingeStatus.closed,
        'partiallyOpen' => HingeStatus.partiallyOpen,
        'fullyOpen' => HingeStatus.fullyOpen,
        null => null,
        _ => HingeStatus.unknown,
      },
      folds: rects(map['folds']),
      occlusions: rects(map['occlusions']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IphoneDuoState &&
      other.verticalBarEdge == verticalBarEdge &&
      other.hingeStatus == hingeStatus &&
      listEquals(other.folds, folds) &&
      listEquals(other.occlusions, occlusions);

  @override
  int get hashCode => Object.hash(verticalBarEdge, hingeStatus, Object.hashAll(folds), Object.hashAll(occlusions));
}

/// Owner of the `com.plezy/iphone_duo` channel.
class IphoneDuo {
  IphoneDuo._();

  static final IphoneDuo instance = IphoneDuo._();

  static const _channel = MethodChannel('com.plezy/iphone_duo');

  final ValueNotifier<IphoneDuoState> state = ValueNotifier(IphoneDuoState.empty);
  bool _started = false;
  final Set<Object> _verticalBarDisablers = Set.identity();

  bool get _supported => !kIsWeb && Platform.isIOS && !PlatformDetector.isTV();

  void ensureStarted() {
    if (_started || !_supported) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stateChanged' && call.arguments is Map) {
        state.value = IphoneDuoState.fromMap(call.arguments as Map<Object?, Object?>);
      }
    });
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getState');
      if (result != null) state.value = IphoneDuoState.fromMap(result);
    } on MissingPluginException {
      // Older native shell: no Duo support.
    } on PlatformException {
      // Ignore; the state stays empty.
    }
  }

  /// Ask the system to move the vertical bar back to a horizontal status bar
  /// while [owner] is on screen. Apple reserves this for full-screen video
  /// and similar UIs. Idempotent per owner.
  void disableVerticalBarFor(Object owner) {
    if (!_supported) return;
    if (_verticalBarDisablers.add(owner) && _verticalBarDisablers.length == 1) {
      unawaited(_setVerticalBarDisabled(true));
    }
  }

  void restoreVerticalBarFor(Object owner) {
    if (!_supported) return;
    if (_verticalBarDisablers.remove(owner) && _verticalBarDisablers.isEmpty) {
      unawaited(_setVerticalBarDisabled(false));
    }
  }

  Future<void> _setVerticalBarDisabled(bool disabled) async {
    try {
      await _channel.invokeMethod<void>('setVerticalBarDisabled', disabled);
    } on MissingPluginException {
      // Older native shell.
    } on PlatformException {
      // Ignore.
    }
  }

  static IphoneDuoState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_IphoneDuoInherited>()?.state ?? IphoneDuoState.empty;

  /// The edge the system vertical bar currently occupies in this context, or
  /// null when there is none (other devices, the inner display in portrait,
  /// a Split View window away from the bar, or the bar disabled).
  static VerticalBarEdge? verticalBarEdgeOf(BuildContext context) {
    final edge = of(context).verticalBarEdge;
    if (edge == null) return null;
    final padding = MediaQuery.paddingOf(context);
    return switch (edge) {
      VerticalBarEdge.left when padding.left > 0 => edge,
      VerticalBarEdge.right when padding.right > 0 => edge,
      _ => null,
    };
  }
}

class _IphoneDuoInherited extends InheritedWidget {
  const _IphoneDuoInherited({required this.state, required super.child});

  final IphoneDuoState state;

  @override
  bool updateShouldNotify(_IphoneDuoInherited oldWidget) => oldWidget.state != state;
}

/// Publishes [IphoneDuoState] below it and reports the fold as a
/// [DisplayFeature], so Flutter's dialogs, menus, pickers and modal sheets,
/// and Plezy's hosted sheets (`OverlaySheetHost`), move to one side of the
/// fold like their UIKit counterparts do.
class IphoneDuoScope extends StatefulWidget {
  const IphoneDuoScope({super.key, required this.child});

  final Widget child;

  @override
  State<IphoneDuoScope> createState() => _IphoneDuoScopeState();
}

class _IphoneDuoScopeState extends State<IphoneDuoScope> {
  @override
  void initState() {
    super.initState();
    IphoneDuo.instance.ensureStarted();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IphoneDuoState>(
      valueListenable: IphoneDuo.instance.state,
      child: widget.child,
      builder: (context, state, child) {
        Widget result = child!;
        if (state.folds.isNotEmpty) {
          final media = MediaQuery.of(context);
          result = MediaQuery(
            data: media.copyWith(
              displayFeatures: [
                ...media.displayFeatures,
                for (final fold in state.folds)
                  DisplayFeature(
                    bounds: fold,
                    type: DisplayFeatureType.fold,
                    state: DisplayFeatureState.postureHalfOpened,
                  ),
              ],
            ),
            child: result,
          );
        }
        return _IphoneDuoInherited(state: state, child: result);
      },
    );
  }
}
