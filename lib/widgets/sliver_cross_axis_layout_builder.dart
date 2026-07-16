import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A [SliverLayoutBuilder] variant whose builder only depends on the sliver's
/// cross-axis extent.
///
/// [SliverConstraints] include the scroll offset, so a plain
/// [SliverLayoutBuilder] re-invokes its builder on EVERY scroll tick — each
/// tick rebuilds the returned sliver widget, which marks every realized grid
/// child dirty for build AND layout (a 100-200ms frame on low-end TV boxes
/// with ~30 cards realized). Grid geometry (column count, cell size) only
/// depends on the cross-axis extent, so this widget keys the rebuild decision
/// on [SliverConstraints.crossAxisExtent] alone: the builder re-runs when the
/// width changes (resize, sidebar layout change) or when this widget itself
/// is rebuilt (normal data/settings updates), never from scrolling.
///
/// The framework's [AbstractLayoutBuilder] contract handles the caching: the
/// builder is skipped when [RenderAbstractLayoutBuilderMixin.layoutInfo]
/// compares equal to its value from the previous layout pass.
class SliverCrossAxisLayoutBuilder extends AbstractLayoutBuilder<double> {
  const SliverCrossAxisLayoutBuilder({super.key, required this.builder});

  /// Called at layout time with the sliver's cross-axis extent. Must return
  /// a sliver.
  @override
  final Widget Function(BuildContext context, double crossAxisExtent) builder;

  @override
  RenderAbstractLayoutBuilderMixin<double, RenderSliver> createRenderObject(BuildContext context) =>
      _RenderSliverCrossAxisLayoutBuilder();
}

/// Pass-through render sliver — geometry, paint, and hit-testing mirror
/// the framework's `_RenderSliverLayoutBuilder`; only [layoutInfo] differs.
class _RenderSliverCrossAxisLayoutBuilder extends RenderSliver
    with
        RenderObjectWithChildMixin<RenderSliver>,
        RenderObjectWithLayoutCallbackMixin,
        RenderAbstractLayoutBuilderMixin<double, RenderSliver> {
  @override
  double get layoutInfo => constraints.crossAxisExtent;

  @override
  double childMainAxisPosition(RenderObject child) {
    assert(child == this.child);
    return 0;
  }

  @override
  void performLayout() {
    runLayoutCallback();
    child?.layout(constraints, parentUsesSize: true);
    geometry = child?.geometry ?? SliverGeometry.zero;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    // The child's offset is always (0, 0); no transform needed.
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child?.geometry?.visible ?? false) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return child != null &&
        child!.geometry!.hitTestExtent > 0 &&
        child!.hitTest(result, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
  }
}
