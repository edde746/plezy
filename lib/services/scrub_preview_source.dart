import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// One frame of scrub-bar preview imagery, produced by a
/// [ScrubPreviewSource] for a given timestamp.
///
/// Plex's BIF returns standalone JPEG bytes per timestamp.
/// Jellyfin's Trickplay returns a sprite-sheet URL plus the row/column of
/// the right tile. The tooltip sizes itself to [aspectRatio] so the frame
/// renders without letterboxing or cropping.
sealed class ScrubFrame {
  const ScrubFrame();

  /// Source frame aspect ratio (width / height). The tooltip uses this to
  /// pick its own height; the renderer assumes the box already matches.
  double get aspectRatio;
}

/// Plex BIF: standalone JPEG bytes ready for [Image.memory]. Plex doesn't
/// expose per-BIF dimensions out-of-band; servers virtually always use
/// 16:9, which matches the default tooltip box.
class BytesScrubFrame extends ScrubFrame {
  final Uint8List bytes;
  @override
  final double aspectRatio;
  const BytesScrubFrame(this.bytes, {this.aspectRatio = 16 / 9});
}

/// Jellyfin Trickplay: a single sprite sheet plus the position of the tile
/// to display within it. Aspect comes from [sourceTileSize]; the tooltip
/// adopts that aspect so each source tile fills the box exactly.
class SheetScrubFrame extends ScrubFrame {
  final ImageProvider sheet;
  final int tileColumn;
  final int tileRow;
  final int sheetColumns;
  final int sheetRows;
  final Size sourceTileSize;
  const SheetScrubFrame({
    required this.sheet,
    required this.tileColumn,
    required this.tileRow,
    required this.sheetColumns,
    required this.sheetRows,
    required this.sourceTileSize,
  });

  @override
  double get aspectRatio => sourceTileSize.width / sourceTileSize.height;
}

/// Backend-neutral source of [ScrubFrame]s for the timeline tooltip.
/// Plex implements via BIF bytes; Jellyfin via Trickplay sheet crops.
abstract class ScrubPreviewSource {
  bool get isAvailable;
  ScrubFrame? getFrame(Duration time);
  void dispose();
}
