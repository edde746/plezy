import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/mal/mal_anime.dart';
import 'package:plezy/services/trackers/mal/mal_page.dart';

void main() {
  group('MalPage.fromJson', () {
    test('extracts nodes and reads hasMore from paging.next', () {
      final page = MalPage.fromJson({
        'data': [
          {
            'node': {'id': 1, 'title': 'Cowboy Bebop'},
          },
          {
            'node': {'id': 5, 'title': 'Cowboy Bebop: Tengoku no Tobira'},
            'ranking': {'rank': 2},
          },
        ],
        'paging': {'next': 'https://api.myanimelist.net/v2/anime/ranking?offset=2'},
      }, MalAnime.fromJson);

      expect(page.items, hasLength(2));
      expect(page.items.first.id, 1);
      expect(page.hasMore, isTrue);
    });

    test('tolerates malformed entries and missing paging', () {
      final page = MalPage.fromJson({
        'data': [
          'garbage',
          {'no_node': true},
          {
            'node': {'id': 30, 'title': 'Neon Genesis Evangelion'},
          },
        ],
      }, MalAnime.fromJson);

      expect(page.items.single.id, 30);
      expect(page.hasMore, isFalse);

      expect(MalPage.fromJson(null, MalAnime.fromJson).items, isEmpty);
      expect(MalPage.fromJson([], MalAnime.fromJson).items, isEmpty);
    });
  });

  group('MalAnime', () {
    test('parses the catalog fields and derives display values', () {
      final anime = MalAnime.fromJson({
        'id': 5114,
        'title': 'Hagane no Renkinjutsushi: Fullmetal Alchemist',
        'main_picture': {'medium': 'https://cdn.myanimelist.net/images/anime/1223/96541.jpg'},
        'alternative_titles': {
          'en': 'Fullmetal Alchemist: Brotherhood',
          'ja': '鋼の錬金術師',
          'synonyms': ['FMA'],
        },
        'start_date': '2009-04-05',
        'synopsis': 'After a horrific alchemy experiment...',
        'mean': 9.1,
        'genres': [
          {'id': 1, 'name': 'Action'},
          {'id': 10, 'name': 'Fantasy'},
        ],
        'media_type': 'tv',
        'rating': 'r',
        'num_episodes': 64,
        'average_episode_duration': 1460,
        'start_season': {'year': 2009, 'season': 'spring'},
        'status': 'finished_airing',
        'num_scoring_users': 2326268,
        'studios': [
          {'id': 4, 'name': 'Bones'},
        ],
      });

      expect(anime.displayTitle, 'Fullmetal Alchemist: Brotherhood');
      expect(anime.isMovie, isFalse);
      expect(anime.year, 2009);
      expect(anime.runtimeMinutes, 24);
      expect(anime.certification, 'R');
      expect(anime.genreNames, ['Action', 'Fantasy']);
      expect(anime.mainPicture?.primary, 'https://cdn.myanimelist.net/images/anime/1223/96541.jpg');
      expect(anime.mean, 9.1);
      expect(anime.status, 'finished_airing');
      expect(anime.numScoringUsers, 2326268);
      expect(anime.primaryStudio, 'Bones');
    });

    test('falls back to the romaji title and the start_date year', () {
      final anime = MalAnime.fromJson({
        'id': 1,
        'title': 'Cowboy Bebop',
        'alternative_titles': {'en': ''},
        'start_date': '1998-04-03',
        'media_type': 'movie',
        'rating': 'pg_13',
      });

      expect(anime.displayTitle, 'Cowboy Bebop');
      expect(anime.isMovie, isTrue);
      expect(anime.year, 1998);
      expect(anime.certification, 'PG-13');
      expect(anime.runtimeMinutes, isNull);
      expect(anime.genreNames, isNull);
    });
  });
}
