import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';

/// What a hover-preview card should show once the debounce fires, in
/// descending order of quality.
sealed class HoverPreviewSource {
  const HoverPreviewSource();
}

/// A trailer clip exists — play it from the start.
class TrailerPreviewSource extends HoverPreviewSource {
  const TrailerPreviewSource(this.streamUrl);
  final String streamUrl;
}

/// No trailer, but the owned movie/show file itself can be played — seek
/// past the likely opening logos/credits and play a short clip from there.
class SceneClipPreviewSource extends HoverPreviewSource {
  const SceneClipPreviewSource(this.streamUrl, this.startOffset);
  final String streamUrl;
  final Duration startOffset;
}

/// Neither worked (or the item has no resolvable duration) — the card
/// expands to show metadata over static art, no video.
class NoPreviewSource extends HoverPreviewSource {
  const NoPreviewSource();
}

/// Resolves what a hover-preview card should play for a given item.
///
/// Priority: (1) a Plex-scraped trailer, (2) a clip from the owned media
/// file itself (the user owns this content — playing a clip of it is not
/// the same question as pulling a clip from somewhere else), (3) no video,
/// metadata-only. Never throws — a failed lookup at any stage just falls
/// through to the next one; a hover preview has nothing worth surfacing
/// an error for.
class HoverPreviewSourceResolver {
  /// Plex's `extraType` values distinguish trailers from other extras
  /// (deleted scenes, featurettes, behind-the-scenes) — 1 is trailer,
  /// confirmed against a real library item via the Plex API directly.
  // Plex numeric extraType 1 == subtype 'trailer'; this branch's PlexMediaItem
  // consolidated onto the String subtype field (see media_item.dart), so
  // match on that instead of the old numeric extraType this was ported from.
  static const _trailerSubtype = 'trailer';

  /// Skip this fraction of runtime before starting a scene-clip fallback,
  /// clearing most studio logos/opening credits without needing per-title
  /// chapter data.
  static const _sceneStartFraction = 0.12;

  Future<HoverPreviewSource> resolve(MediaServerClient client, MediaItem item, {bool preferResumePosition = false}) async {
    // TEMP DIAGNOSTIC (remove once the per-hub blank-video bug is found):
    // the same title reportedly resolves in one hub's row and not another —
    // logging id/kind/duration here to see what actually differs between a
    // working and a failing call for the same movie.
    debugPrint('[hover-preview] resolve id=${item.id} kind=${item.kind} title=${item.displayTitle} durationMs=${item.durationMs} serverId=${item.serverId}');

    final playableItem = await _resolvePlayableItem(client, item);

    // Continue Watching cards want to pick up where the user left off, not
    // a trailer or the usual 12%-in scene clip — checked first and, when it
    // resolves, skips the rest of this method entirely.
    if (preferResumePosition && playableItem.hasActiveProgress) {
      final resumeClip = await _resolveResumeClip(client, playableItem);
      if (resumeClip != null) {
        debugPrint('[hover-preview] resumeClip OK id=${item.id} url=${resumeClip.streamUrl}');
        return resumeClip;
      }
    }

    final trailerUrl = await _resolveTrailerUrl(client, playableItem);
    if (trailerUrl != null) {
      debugPrint('[hover-preview] trailer OK id=${item.id} url=$trailerUrl');
      return TrailerPreviewSource(trailerUrl);
    }

    final sceneClip = await _resolveSceneClip(client, playableItem);
    if (sceneClip != null) {
      debugPrint('[hover-preview] sceneClip OK id=${item.id} url=${sceneClip.streamUrl}');
      return sceneClip;
    }

    debugPrint('[hover-preview] NO PREVIEW id=${item.id} title=${item.displayTitle}');
    return const NoPreviewSource();
  }

  /// A show's own card represents the whole series, not a single playable
  /// file — resolving extras or a scene clip against its own id either
  /// returns nothing or fails outright, since there's no video Part on a
  /// show itself. Substitutes the actual on-deck episode (Plex's own
  /// lookup, which already knows to pick up where the user left off, or the
  /// first episode for a never-started show) so the rest of this resolver
  /// has something genuinely playable to work with. Movies pass through
  /// unchanged — they're already the playable item.
  Future<MediaItem> _resolvePlayableItem(MediaServerClient client, MediaItem item) async {
    if (item.kind != MediaKind.show) return item;
    try {
      final result = await client.fetchItemWithOnDeck(item.id);
      return result.onDeckEpisode ?? item;
    } catch (_) {
      return item;
    }
  }

  Future<SceneClipPreviewSource?> _resolveResumeClip(MediaServerClient client, MediaItem item) async {
    final offsetMs = item.viewOffsetMs;
    if (offsetMs == null || offsetMs <= 0) return null;
    try {
      final url = await client.resolveExternalPlaybackUrl(item);
      if (url == null) return null;
      return SceneClipPreviewSource(url, Duration(milliseconds: offsetMs));
    } catch (e) {
      debugPrint('[hover-preview] resumeClip FAILED id=${item.id}: $e');
      return null;
    }
  }

  Future<String?> _resolveTrailerUrl(MediaServerClient client, MediaItem item) async {
    try {
      final extras = await client.fetchExtras(item.id);
      final trailer = extras.firstWhereOrNull(
        (extra) => extra is PlexMediaItem && extra.subtype == _trailerSubtype,
      );
      if (trailer == null) return null;
      return await client.resolveExternalPlaybackUrl(trailer);
    } catch (e) {
      debugPrint('[hover-preview] trailer FAILED id=${item.id}: $e');
      return null;
    }
  }

  Future<SceneClipPreviewSource?> _resolveSceneClip(MediaServerClient client, MediaItem item) async {
    final durationMs = item.durationMs;
    if (durationMs == null || durationMs <= 0) {
      debugPrint('[hover-preview] sceneClip SKIPPED (no durationMs) id=${item.id} durationMs=$durationMs');
      return null;
    }
    try {
      final url = await client.resolveExternalPlaybackUrl(item);
      if (url == null) {
        debugPrint('[hover-preview] sceneClip FAILED (null url) id=${item.id}');
        return null;
      }
      final offsetMs = (durationMs * _sceneStartFraction).round();
      return SceneClipPreviewSource(url, Duration(milliseconds: offsetMs));
    } catch (e) {
      debugPrint('[hover-preview] sceneClip FAILED (exception) id=${item.id}: $e');
      return null;
    }
  }
}
