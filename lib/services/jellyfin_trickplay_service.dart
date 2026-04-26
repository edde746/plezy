import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart' show ImageConfiguration, ImageProvider, ImageStreamListener;

import '../media/media_source_info.dart';
import 'image_cache_service.dart';
import 'jellyfin_client.dart';
import 'scrub_preview_source.dart';

/// Builds the [ImageProvider] for a sprite-sheet URL. Production uses
/// [CachedNetworkImageProvider] backed by [PlexImageCacheManager]; tests
/// inject a stub to avoid touching path_provider / platform channels.
typedef TrickplaySheetImageBuilder = ImageProvider Function(String url);

ImageProvider _defaultSheetImageBuilder(String url) =>
    CachedNetworkImageProvider(url, cacheManager: PlexImageCacheManager.instance);

/// Jellyfin sprite-sheet scrub thumbnails. Picks the best width from the
/// per-source manifest at construction, then computes
/// `(thumbnailIndex → sheetIndex, tileX, tileY)` on each [getFrame] call.
///
/// Sheets are loaded lazily via [PlexImageCacheManager], so the second hover
/// over the same sheet hits the cache. Adjacent sheets are pre-fetched in
/// the direction of motion to keep fast scrubs smooth.
class JellyfinTrickplayService implements ScrubPreviewSource {
  final JellyfinClient _client;
  final String _itemId;
  final String? _mediaSourceId;
  final TrickplayInfo _info;
  final TrickplaySheetImageBuilder _sheetImageBuilder;

  int? _lastSheetIndex;
  bool _disposed = false;

  /// Provider cache by sheet index: scrubbing typically dwells on one sheet
  /// for many hover events, so we reuse the same wrapper rather than
  /// reallocating each frame. cached_network_image's own cache is keyed by
  /// URL, but the wrapper object itself isn't free.
  final Map<int, ImageProvider> _providerCache = {};

  JellyfinTrickplayService._({
    required JellyfinClient client,
    required String itemId,
    required String? mediaSourceId,
    required TrickplayInfo info,
    required TrickplaySheetImageBuilder sheetImageBuilder,
  }) : _client = client,
       _itemId = itemId,
       _mediaSourceId = mediaSourceId,
       _info = info,
       _sheetImageBuilder = sheetImageBuilder;

  /// Picks the best width from [manifest] (smallest >= [targetTooltipWidth],
  /// largest available otherwise). Returns `null` when [manifest] is empty.
  ///
  /// [sheetImageBuilder] defaults to [CachedNetworkImageProvider] +
  /// [PlexImageCacheManager]; tests can inject a stub to avoid touching
  /// the platform image-cache plumbing.
  static JellyfinTrickplayService? create({
    required JellyfinClient client,
    required String itemId,
    required String? mediaSourceId,
    required Map<int, TrickplayInfo> manifest,
    int targetTooltipWidth = 160,
    TrickplaySheetImageBuilder? sheetImageBuilder,
  }) {
    if (manifest.isEmpty) return null;
    final widths = manifest.keys.toList()..sort();
    final preferred = widths.firstWhere((w) => w >= targetTooltipWidth, orElse: () => widths.last);
    final info = manifest[preferred];
    if (info == null) return null;
    return JellyfinTrickplayService._(
      client: client,
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      info: info,
      sheetImageBuilder: sheetImageBuilder ?? _defaultSheetImageBuilder,
    );
  }

  /// Pure math helper exposed for unit tests: maps a timestamp to the
  /// sheet index, tile coordinates within the sheet, and the sheet's
  /// (possibly partial) row/column count. Returns `null` only when the
  /// manifest is degenerate.
  TrickplayTileLocation? tileLocationFor(Duration time) {
    if (_disposed) return null;
    final info = _info;
    if (info.thumbnailCount <= 0 || info.interval <= 0) return null;

    final rawIndex = time.inMilliseconds ~/ info.interval;
    final thumbnailIndex = rawIndex.clamp(0, info.thumbnailCount - 1);
    final tilesPerSheet = info.tileWidth * info.tileHeight;
    if (tilesPerSheet <= 0) return null;
    final sheetIndex = thumbnailIndex ~/ tilesPerSheet;
    final tileInSheet = thumbnailIndex - sheetIndex * tilesPerSheet;
    final tileColumn = tileInSheet % info.tileWidth;
    final tileRow = tileInSheet ~/ info.tileWidth;

    final firstThumbInSheet = sheetIndex * tilesPerSheet;
    final thumbsInSheet = math.min(tilesPerSheet, info.thumbnailCount - firstThumbInSheet);
    final sheetColumns = thumbsInSheet >= info.tileWidth ? info.tileWidth : thumbsInSheet;
    final sheetRows = (thumbsInSheet + info.tileWidth - 1) ~/ info.tileWidth;

    return TrickplayTileLocation(
      sheetIndex: sheetIndex,
      tileColumn: tileColumn,
      tileRow: tileRow,
      sheetColumns: sheetColumns,
      sheetRows: sheetRows,
      sourceTileSize: Size(info.width.toDouble(), info.height.toDouble()),
    );
  }

  /// Sheet URL for [sheetIndex] using the chosen width and source id.
  /// Exposed for tests; production callers use [getFrame].
  String sheetUrlFor(int sheetIndex) =>
      _client.buildTrickplayTileUrl(_itemId, _info.width, sheetIndex, mediaSourceId: _mediaSourceId);

  @override
  bool get isAvailable => !_disposed && _info.thumbnailCount > 0;

  @override
  ScrubFrame? getFrame(Duration time) {
    final loc = tileLocationFor(time);
    if (loc == null) return null;
    final sheet = _providerFor(loc.sheetIndex);
    _maybePrefetchAdjacent(loc.sheetIndex);
    return SheetScrubFrame(
      sheet: sheet,
      tileColumn: loc.tileColumn,
      tileRow: loc.tileRow,
      sheetColumns: loc.sheetColumns,
      sheetRows: loc.sheetRows,
      sourceTileSize: loc.sourceTileSize,
    );
  }

  ImageProvider _providerFor(int sheetIndex) =>
      _providerCache.putIfAbsent(sheetIndex, () => _sheetImageBuilder(sheetUrlFor(sheetIndex)));

  void _maybePrefetchAdjacent(int currentSheet) {
    final last = _lastSheetIndex;
    if (currentSheet == last) return;
    _lastSheetIndex = currentSheet;
    final tilesPerSheet = _info.tileWidth * _info.tileHeight;
    if (tilesPerSheet <= 0) return;
    final lastSheetIndex = (_info.thumbnailCount - 1) ~/ tilesPerSheet;

    final int? candidate;
    if (last == null || currentSheet > last) {
      candidate = currentSheet + 1 <= lastSheetIndex ? currentSheet + 1 : null;
    } else {
      candidate = currentSheet - 1 >= 0 ? currentSheet - 1 : null;
    }
    if (candidate != null) _kickOff(_providerFor(candidate));
  }

  /// Trigger a network fetch without holding a `BuildContext`. The cache
  /// manager picks up the response, so the next [getFrame] for the same
  /// sheet renders without a round-trip. Errors are absorbed via the
  /// listener's `onError` so a failed prefetch doesn't propagate.
  void _kickOff(ImageProvider provider) {
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronous) => stream.removeListener(listener),
      onError: (_, _) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _disposed = true;
    _lastSheetIndex = null;
    _providerCache.clear();
  }
}

/// Pure data: which sheet to fetch, which tile within it to display, the
/// sheet's (possibly partial) row/column count, and the source tile's
/// pixel dimensions for aspect-correct scaling at render time. Returned
/// by [JellyfinTrickplayService.tileLocationFor] for unit tests.
class TrickplayTileLocation {
  final int sheetIndex;
  final int tileColumn;
  final int tileRow;
  final int sheetColumns;
  final int sheetRows;
  final Size sourceTileSize;
  const TrickplayTileLocation({
    required this.sheetIndex,
    required this.tileColumn,
    required this.tileRow,
    required this.sheetColumns,
    required this.sheetRows,
    required this.sourceTileSize,
  });
}
