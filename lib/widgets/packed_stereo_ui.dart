import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../media/packed_stereo_layout.dart';
import '../utils/app_logger.dart';

/// Paints one live Flutter UI into both eye regions of a packed 3D frame.
///
/// The player video is a native surface behind Flutter, so only Plezy's UI is
/// captured. Using an [OffsetLayer] keeps this compatible with both Skia and
/// Impeller; NVIDIA devices intentionally run Plezy with Skia.
class PackedStereoUi extends SingleChildRenderObjectWidget {
  PackedStereoUi({super.key, required this.layout, required this.enabled, required super.child})
    : assert(layout.isPacked);

  final PackedStereoLayout layout;
  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPackedStereoUi(layout, enabled, MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderPackedStereoUi)
      ..stereoLayout = layout
      ..enabled = enabled
      ..pixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class _RenderPackedStereoUi extends RenderProxyBox {
  _RenderPackedStereoUi(this._layout, this._enabled, this._pixelRatio);

  PackedStereoLayout _layout;
  bool _enabled;
  double _pixelRatio;
  bool _snapshotFailureLogged = false;

  set stereoLayout(PackedStereoLayout value) {
    if (_layout == value) return;
    _layout = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  set pixelRatio(double value) {
    if (_pixelRatio == value) return;
    _pixelRatio = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_enabled || child == null || size.isEmpty) {
      super.paint(context, offset);
      return;
    }

    final image = _snapshotChild();
    if (image == null) {
      super.paint(context, offset);
      return;
    }

    try {
      final source = Offset.zero & (size * _pixelRatio);
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (_layout.isSideBySide) {
        final eyeWidth = size.width / 2;
        context.canvas.drawImageRect(image, source, Rect.fromLTWH(offset.dx, offset.dy, eyeWidth, size.height), paint);
        context.canvas.drawImageRect(
          image,
          source,
          Rect.fromLTWH(offset.dx + eyeWidth, offset.dy, eyeWidth, size.height),
          paint,
        );
      } else {
        final eyeHeight = size.height / 2;
        context.canvas.drawImageRect(image, source, Rect.fromLTWH(offset.dx, offset.dy, size.width, eyeHeight), paint);
        context.canvas.drawImageRect(
          image,
          source,
          Rect.fromLTWH(offset.dx, offset.dy + eyeHeight, size.width, eyeHeight),
          paint,
        );
      }
    } finally {
      image.dispose();
    }
  }

  ui.Image? _snapshotChild() {
    final layer = OffsetLayer();
    try {
      final childContext = PaintingContext(layer, Offset.zero & size);
      super.paint(childContext, Offset.zero);
      // ignore: invalid_use_of_protected_member - mirrors Flutter's SnapshotWidget implementation.
      childContext.stopRecordingIfNeeded();
      return layer.toImageSync(Offset.zero & size, pixelRatio: _pixelRatio);
    } catch (error, stackTrace) {
      if (!_snapshotFailureLogged) {
        _snapshotFailureLogged = true;
        appLogger.w('Could not duplicate packed stereo UI', error: error, stackTrace: stackTrace);
      }
      return null;
    } finally {
      layer.dispose();
    }
  }

  Matrix4 _eyeTransformFor(Offset position) {
    if (_layout.isSideBySide) {
      final rightEye = position.dx >= size.width / 2;
      return Matrix4.translationValues(rightEye ? size.width / 2 : 0, 0, 0)..scaleByDouble(0.5, 1, 1, 1);
    }
    final bottomEye = position.dy >= size.height / 2;
    return Matrix4.translationValues(0, bottomEye ? size.height / 2 : 0, 0)..scaleByDouble(1, 0.5, 1, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!_enabled) return super.hitTestChildren(result, position: position);
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _eyeTransformFor(position),
      position: position,
      hitTest: (result, transformed) => child.hitTest(result, position: transformed),
    );
  }
}
