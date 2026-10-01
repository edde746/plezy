import 'package:flutter/material.dart';

import '../../../services/scrub_preview_source.dart';

class ScrubFrameView extends StatelessWidget {
  final ScrubFrame frame;
  final BoxFit fit;

  const ScrubFrameView({super.key, required this.frame, this.fit = BoxFit.cover});

  int? _cacheDimension(double logicalSize, double devicePixelRatio) {
    if (!logicalSize.isFinite || logicalSize <= 0) return null;
    return (logicalSize * devicePixelRatio).round().clamp(1, 8192).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final f = frame;
    switch (f) {
      case BytesScrubFrame():
        return LayoutBuilder(
          builder: (context, constraints) {
            final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
            return Image.memory(
              f.bytes,
              fit: fit,
              gaplessPlayback: true,
              cacheWidth: _cacheDimension(constraints.maxWidth, devicePixelRatio),
              cacheHeight: _cacheDimension(constraints.maxHeight, devicePixelRatio),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            );
          },
        );
      case SheetScrubFrame():
        return LayoutBuilder(
          builder: (context, constraints) {
            final tileW = constraints.maxWidth;
            final tileH = constraints.maxHeight;
            final sheetW = tileW * f.sheetColumns;
            final sheetH = tileH * f.sheetRows;
            final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
            final sheet = ResizeImage.resizeIfNeeded(
              _cacheDimension(sheetW, devicePixelRatio),
              _cacheDimension(sheetH, devicePixelRatio),
              f.sheet,
            );
            return ClipRect(
              child: OverflowBox(
                maxWidth: sheetW,
                maxHeight: sheetH,
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: Offset(-f.tileColumn * tileW, -f.tileRow * tileH),
                  child: Image(
                    image: sheet,
                    width: sheetW,
                    height: sheetH,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}
