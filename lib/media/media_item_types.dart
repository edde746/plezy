import 'media_item.dart';
import 'media_kind.dart';

/// Convenience type-check getters and spoiler helpers on [MediaItem]. These
/// give consumers a Plex-style fluent API (e.g. `item.isShow`) while keeping
/// the underlying type backend-neutral.
extension MediaItemTypes on MediaItem {
  bool get isShow => kind == MediaKind.show;
  bool get isMovie => kind == MediaKind.movie;
  bool get isSeason => kind == MediaKind.season;
  bool get isEpisode => kind == MediaKind.episode;
  bool get isCollection => kind == MediaKind.collection;
  bool get isMusicContent => kind == MediaKind.artist || kind == MediaKind.album || kind == MediaKind.track;
  bool get isVideoContent =>
      kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.season || kind == MediaKind.episode;

  /// Whether this episode should have spoiler protection applied.
  /// True for any episode that has not yet been marked watched, regardless of
  /// in-progress playback position (#1397).
  bool get shouldHideSpoiler {
    if (!isEpisode) return false;
    return !isWatched;
  }

  /// Non-spoiler art path for episodes (show/season background).
  String? get spoilerSafeArt => grandparentArtPath ?? artPath;
}
