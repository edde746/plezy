import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Builds the artwork for one hero page. [active] is true only for the settled
/// page; [artSize] is the box the artwork is laid out in, wider than the
/// viewport by the room it drifts in, for sizing image requests.
typedef HeroBackdropBuilder = Widget Function(BuildContext context, int index, bool active, Size artSize);

/// Shared artwork layer behind the Discover hero's [PageView].
///
/// The hero's pages carry only their foreground; this layer owns the artwork,
/// so a swipe crossfades between neighbouring backdrops instead of sliding two
/// images past each other with a hard seam between them (#2660). As in the
/// Apple TV app, each backdrop drifts with the swipe while it fades: it is
/// laid out wider than the viewport and slides within that overflow, so it
/// never exposes an edge. Reduced motion keeps the crossfade and drops the
/// drift.
class HeroCarouselBackdrop extends StatelessWidget {
  const HeroCarouselBackdrop({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.itemCount,
    required this.backdropBuilder,
  });

  /// Share of the viewport width a backdrop travels on its way in or out.
  static const double _drift = 0.25;

  /// The most the drift may zoom artwork that has no spare width to slide in.
  static const double _maxDriftZoom = 1.2;

  /// Heroes show 16:9 backdrops, or square art in near-square viewports.
  /// Sizing the drift for the narrower keeps either within [_maxDriftZoom].
  static const double _narrowestArtAspectRatio = 1.0;

  /// The [PageView] controller whose position drives the crossfade.
  final PageController controller;

  /// The settled page. Its neighbours stay mounted but transparent, so their
  /// artwork is already decoded when a swipe starts.
  final int currentIndex;

  final int itemCount;

  /// Off-screen neighbours are built inactive so they do not rotate their
  /// backdrops.
  final HeroBackdropBuilder backdropBuilder;

  /// Drift for a viewport of [aspectRatio], as a fraction of its width.
  ///
  /// Cover-fit art in a narrower viewport (portrait phones) already overflows
  /// it horizontally, so widening the box spends that spare width without
  /// zooming. A viewport wider than the art has none; there the widened box
  /// may only zoom the art up to [_maxDriftZoom], which shortens the drift.
  static double _driftFor(double aspectRatio) {
    final spareWidth = math.max(_narrowestArtAspectRatio / aspectRatio, 1.0) * _maxDriftZoom;
    return math.min(_drift, (spareWidth - 1) / 2);
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();
    final lastPage = itemCount - 1;
    final current = currentIndex.clamp(0, lastPage);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final drift = reduceMotion || viewport.isEmpty ? 0.0 : _driftFor(viewport.aspectRatio);
        final artSize = Size(viewport.width * (1 + 2 * drift), viewport.height);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Ascending index order: the later page always paints over the
            // earlier one, so each fade runs over an opaque image and never
            // dips toward the scaffold background mid-swipe.
            for (var index = math.max(0, current - 1); index <= math.min(lastPage, current + 1); index++)
              _HeroBackdropLayer(
                key: ValueKey<int>(index),
                controller: controller,
                index: index,
                settledPage: current,
                drift: drift,
                child: backdropBuilder(context, index, index == current, artSize),
              ),
          ],
        );
      },
    );
  }
}

class _HeroBackdropLayer extends StatelessWidget {
  const _HeroBackdropLayer({
    super.key,
    required this.controller,
    required this.index,
    required this.settledPage,
    required this.drift,
    required this.child,
  });

  final PageController controller;
  final int index;
  final int settledPage;

  /// Fraction of the viewport width this layer travels between settled and
  /// gone; it overflows the viewport by the same amount on each side.
  final double drift;
  final Widget child;

  /// Live page position. [PageController.page] is already clamped to the
  /// scroll extents, so edge overscroll neither fades nor moves the edge
  /// backdrop past its overflow.
  double get _page => (controller.hasClients ? controller.page : null) ?? settledPage.toDouble();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: FractionallySizedBox(widthFactor: 1 + 2 * drift, child: child),
      builder: (context, child) {
        // > 0: this page is still ahead of the swipe; < 0: already passed.
        final offset = index - _page;
        final opacity = offset <= -1 || offset >= 1
            ? 0.0
            : offset <= 0
            ? 1.0
            : 1.0 - offset;
        return FractionalTranslation(
          translation: Offset(offset.clamp(-1.0, 1.0) * drift, 0.0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}
