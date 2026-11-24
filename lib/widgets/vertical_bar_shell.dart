import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/iphone_duo.dart';

/// The vertical space a rail placed in iPhone Duo's vertical bar has to leave
/// for the status items and camera sharing the bar, which sit at the top or
/// the bottom depending on how the device is rotated.
@visibleForTesting
EdgeInsets verticalBarRailInsets({
  required Rect barStrip,
  required EdgeInsets padding,
  required List<Rect> occlusions,
}) {
  var top = padding.top;
  var bottom = padding.bottom;
  for (final occlusion in occlusions) {
    if (!occlusion.overlaps(barStrip)) continue;
    if (occlusion.center.dy < barStrip.center.dy) {
      top = math.max(top, occlusion.bottom - barStrip.top);
    } else {
      bottom = math.max(bottom, barStrip.bottom - occlusion.top);
    }
  }
  return EdgeInsets.only(top: top, bottom: bottom);
}

/// Shell for iPhone Duo while the system shows its vertical bar (outer
/// display, and the inner display in landscape). Navigation moves into the
/// bar under the status items, the way UIKit places a native tab bar there,
/// instead of a bottom bar that would spend the short display's height.
///
/// The rail occupies exactly the bar's inset, so content runs up to it and
/// nothing interactive sits underneath. The rail sees only the vertical
/// space it must avoid as its safe area.
class VerticalBarShell extends StatelessWidget {
  const VerticalBarShell({super.key, required this.edge, required this.railBuilder, required this.child});

  final VerticalBarEdge edge;

  /// Builds the navigation for a bar [barWidth] wide.
  final Widget Function(BuildContext context, double barWidth) railBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final onRight = edge == VerticalBarEdge.right;
        final barWidth = onRight ? media.padding.right : media.padding.left;
        final barStrip = onRight
            ? Rect.fromLTWH(constraints.maxWidth - barWidth, 0, barWidth, constraints.maxHeight)
            : Rect.fromLTWH(0, 0, barWidth, constraints.maxHeight);

        final rail = SizedBox(
          width: barWidth,
          child: MediaQuery(
            data: media.copyWith(
              padding: verticalBarRailInsets(
                barStrip: barStrip,
                padding: media.padding,
                occlusions: IphoneDuo.of(context).occlusions,
              ),
            ),
            child: Builder(builder: (context) => railBuilder(context, barWidth)),
          ),
        );

        final content = Expanded(
          child: MediaQuery.removePadding(context: context, removeLeft: !onRight, removeRight: onRight, child: child),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: onRight ? [content, rail] : [rail, content],
        );
      },
    );
  }
}
