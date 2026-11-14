import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/music/audio_route_service.dart';

/// Apple's own AirPlay route button, embedded in the Flutter tree.
///
/// ### Why a platform view and not a Flutter button
///
/// There is no API to present the AirPlay picker, and none to enumerate or
/// select a receiver. `AVRoutePickerView` is the whole of the public surface:
/// the system draws the glyph, owns its active-route animation, and presents
/// the picker itself when it is tapped. A Flutter button calling into native
/// code could only reach the same picker by synthesising a tap on a hidden
/// instance of this very view — so the honest thing is to show the real one.
///
/// It is the first platform view in this app. Kept deliberately small and
/// square, and never placed where it would be clipped by an animating parent:
/// a `UiKitView` is a real UIView composited into the Flutter surface, and it
/// does not follow a transform its parent applies mid-animation.
class AirPlayRouteButton extends StatelessWidget {
  const AirPlayRouteButton({super.key, this.size = 40, this.tint, this.activeTint});

  final double size;

  /// Colour of the glyph while no AirPlay route is engaged.
  final Color? tint;

  /// Colour while one is. Defaults to the tint when unset — the system's own
  /// default is a blue that disappears against this app's surfaces.
  final Color? activeTint;

  @override
  Widget build(BuildContext context) {
    final resolvedTint = tint ?? Theme.of(context).colorScheme.onSurface;
    final resolvedActive = activeTint ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: UiKitView(
        viewType: AudioRouteService.routeButtonViewType,
        creationParams: <String, Object?>{'tint': _argb(resolvedTint), 'activeTint': _argb(resolvedActive)},
        creationParamsCodec: const StandardMessageCodec(),
        // The picker must open on the first tap. Without claiming the vertical
        // drag recogniser the enclosing scrollable wins the arena and the tap
        // is only delivered after the gesture resolves, which reads as a dead
        // button in a list that can scroll.
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
      ),
    );
  }

  static int _argb(Color color) => color.toARGB32();
}
