import 'package:flutter/material.dart';

import '../../utils/layout_constants.dart';

typedef MusicDetailHeaderArtworkBuilder = Widget Function(double size);
typedef MusicDetailHeaderInfoBuilder = Widget Function({required bool centered});

/// Responsive artwork, metadata, and focusable actions shared by music detail
/// screens.
class MusicDetailHeader extends StatelessWidget {
  const MusicDetailHeader({
    super.key,
    required this.artworkBuilder,
    required this.infoBuilder,
    required this.actionBar,
    required this.compactArtworkSize,
    required this.compactArtworkSpacing,
    this.compactBottomSpacing = 0,
    this.wideArtworkSize = 180,
    this.wideAlignment = CrossAxisAlignment.center,
  });

  final MusicDetailHeaderArtworkBuilder artworkBuilder;
  final MusicDetailHeaderInfoBuilder infoBuilder;
  final Widget actionBar;
  final double compactArtworkSize;
  final double compactArtworkSpacing;
  final double compactBottomSpacing;
  final double wideArtworkSize;
  final CrossAxisAlignment wideAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < ScreenBreakpoints.mobile) {
            return Column(
              children: [
                artworkBuilder(compactArtworkSize),
                SizedBox(height: compactArtworkSpacing),
                infoBuilder(centered: true),
                const SizedBox(height: 16),
                actionBar,
                if (compactBottomSpacing > 0) SizedBox(height: compactBottomSpacing),
              ],
            );
          }

          return Row(
            crossAxisAlignment: wideAlignment,
            children: [
              artworkBuilder(wideArtworkSize),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [infoBuilder(centered: false), const SizedBox(height: 16), actionBar],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
