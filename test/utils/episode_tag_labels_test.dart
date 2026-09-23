import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/episode_tag_labels.dart';

import '../test_helpers/media_items.dart';

void main() {
  final episode = testMediaItem(
    backend: MediaBackend.jellyfin,
    kind: MediaKind.episode,
    labels: const ['Fansub', 'Mixed Canon/Filler', 'Filler'],
  );

  test('off shows no tag', () {
    expect(buildEpisodeTagLabels(episode, EpisodeTagsMode.off), isEmpty);
  });

  test('canonFiller keeps only the canon/filler vocabulary, in server order', () {
    expect(buildEpisodeTagLabels(episode, EpisodeTagsMode.canonFiller), ['Mixed Canon/Filler', 'Filler']);
  });

  test('all shows every tag verbatim', () {
    expect(buildEpisodeTagLabels(episode, EpisodeTagsMode.all), ['Fansub', 'Mixed Canon/Filler', 'Filler']);
  });

  test('an untagged episode shows nothing in every mode', () {
    final untagged = testMediaItem(backend: MediaBackend.jellyfin, kind: MediaKind.episode);
    for (final mode in EpisodeTagsMode.values) {
      expect(buildEpisodeTagLabels(untagged, mode), isEmpty, reason: '$mode');
    }
  });
}
