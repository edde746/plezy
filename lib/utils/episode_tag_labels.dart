import '../media/media_item.dart';
import '../services/settings_service.dart';

/// The classification Jellyfin's Ronin plugin writes onto each anime episode
/// as an ordinary item tag (one of these per episode), matched verbatim.
const _canonFillerTags = {'Manga Canon', 'Anime Canon', 'Mixed Canon/Filler', 'Filler'};

/// The server tags an episode row shows for [mode], verbatim and in server
/// order. Tags come straight off the item ([MediaItem.labels]): Jellyfin
/// `Tags`, Emby `TagItems`, Plex labels.
List<String> buildEpisodeTagLabels(MediaItem item, EpisodeTagsMode mode) {
  final labels = item.labels ?? const <String>[];
  return switch (mode) {
    EpisodeTagsMode.off => const [],
    EpisodeTagsMode.canonFiller => [
      for (final label in labels)
        if (_canonFillerTags.contains(label)) label,
    ],
    EpisodeTagsMode.all => labels,
  };
}
