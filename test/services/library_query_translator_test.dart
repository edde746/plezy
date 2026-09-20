import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/library_query_translator.dart';
import 'package:plezy/utils/url_utils.dart';

void main() {
  group('PlexLibraryQueryTranslator', () {
    const translator = PlexLibraryQueryTranslator();

    test('empty query produces empty filter map', () {
      expect(translator.toQueryParameters(const LibraryQuery()), isEmpty);
    });

    test('movie kind maps to type=1', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.movie));
      expect(params['type'], '1');
    });

    test('show kind maps to type=2', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.show));
      expect(params['type'], '2');
    });

    test('multiple kinds map to a comma-delimited type filter', () {
      final params = translator.toQueryParameters(const LibraryQuery(includeKinds: [MediaKind.movie, MediaKind.show]));
      expect(params['type'], '1,2');
    });

    test('collection kind has no Plex type number (filtered separately)', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.collection));
      expect(params, isNot(contains('type')));
    });

    test('ascending sort appends :asc suffix', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          sort: LibrarySort(field: 'titleSort', direction: LibrarySortDirection.ascending),
        ),
      );
      expect(params['sort'], 'titleSort:asc');
    });

    test('parseSortParam strips explicit ascending suffix', () {
      final sort = LibraryQueryTranslator.parseSortParam('titleSort:asc');
      expect(sort?.field, 'titleSort');
      expect(sort?.direction, LibrarySortDirection.ascending);
      expect(translator.toQueryParameters(LibraryQuery(sort: sort))['sort'], 'titleSort:asc');
    });

    test('descending sort appends :desc suffix (default direction)', () {
      final params = translator.toQueryParameters(const LibraryQuery(sort: LibrarySort(field: 'addedAt')));
      expect(params['sort'], 'addedAt:desc');
    });

    test('search puts text in title field', () {
      final params = translator.toQueryParameters(const LibraryQuery(search: 'star wars'));
      expect(params['title'], 'star wars');
    });

    test('arbitrary filter clauses pass through verbatim', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', values: ['Action', 'Drama']),
          ],
        ),
      );
      expect(params['genre'], 'Action,Drama');
    });

    test('the operator rides in the query key, keeping its trailing = as the separator', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', op: LibraryFilterOperator.isNot, values: ['Comedy']),
            LibraryFilter(field: 'year', op: LibraryFilterOperator.atLeast, values: ['2015']),
            LibraryFilter(field: 'year', op: LibraryFilterOperator.atMost, values: ['2018']),
            LibraryFilter(field: 'title', op: LibraryFilterOperator.matches, values: ['Wicked']),
            LibraryFilter(field: 'title', op: LibraryFilterOperator.beginsWith, values: ['Wick']),
          ],
        ),
      );
      expect(params['genre!'], 'Comedy');
      expect(params['year>>'], '2015');
      expect(params['year<<'], '2018');
      expect(params['title='], 'Wicked');
      expect(params['title<'], 'Wick');
    });

    test('two clauses on one field with the same operator repeat the key so Plex ANDs them', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', values: ['Comedy']),
            LibraryFilter(field: 'genre', values: ['Drama']),
          ],
        ),
      );
      expect(params['genre'], ['Comedy', 'Drama']);
      expect(encodeQueryParameters(params), 'genre=Comedy&genre=Drama');
    });

    // Percent-encoding the operator and the value separator is safe: PMS
    // decodes query keys, so `genre!=a%2Cb` and `genre!=a,b` select the same
    // rows. What it must never see is an encoded separator (`genre%21%3D=a`),
    // which is why the operator's trailing `=` is not part of the key.
    test('a negated clause encodes to a query Plex parses as one clause', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', op: LibraryFilterOperator.isNot, values: ['Comedy', 'Horror']),
          ],
        ),
      );
      expect(encodeQueryParameters(params), 'genre!=Comedy%2CHorror');
    });

    test('empty clauses and values are dropped rather than sent as bare keys', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', values: ['']),
            LibraryFilter(field: '', values: ['x']),
            LibraryFilter(field: 'tag', values: []),
          ],
        ),
      );
      expect(params, isEmpty);
    });
  });

  group('JellyfinLibraryQueryTranslator', () {
    const translator = JellyfinLibraryQueryTranslator(userId: 'user-1', parentId: 'lib-1', fields: 'UserData');

    test('always sets userId, ParentId, Recursive, IncludeItemTypes', () {
      final params = translator.toQueryParameters(const LibraryQuery());
      expect(params['userId'], 'user-1');
      expect(params['ParentId'], 'lib-1');
      expect(params['Recursive'], 'true');
      expect(params['Fields'], 'UserData');
      expect(params['IncludeItemTypes'], isNotEmpty);
      expect(params['EnableTotalRecordCount'], 'true');
      expect(params['EnableImageTypes'], 'Primary,Backdrop,Logo');
      expect(params['ImageTypeLimit'], '3');
    });

    test('movie kind maps to IncludeItemTypes=Movie', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.movie));
      expect(params['IncludeItemTypes'], 'Movie');
    });

    test('show kind maps to IncludeItemTypes=Series', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.show));
      expect(params['IncludeItemTypes'], 'Series');
    });

    test('multiple kinds map to combined IncludeItemTypes', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(kind: MediaKind.episode, includeKinds: [MediaKind.movie, MediaKind.show]),
      );
      expect(params['IncludeItemTypes'], 'Movie,Series');
    });

    test('collection kind maps to IncludeItemTypes=BoxSet', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.collection));
      expect(params['IncludeItemTypes'], 'BoxSet');
    });

    test('clip and photo kinds map to Jellyfin item types', () {
      expect(
        translator.toQueryParameters(const LibraryQuery(kind: MediaKind.clip))['IncludeItemTypes'],
        'Video,MusicVideo',
      );
      expect(translator.toQueryParameters(const LibraryQuery(kind: MediaKind.photo))['IncludeItemTypes'], 'Photo');
    });

    test('null kind falls back to multi-type include', () {
      final params = translator.toQueryParameters(const LibraryQuery());
      expect(params['IncludeItemTypes'], 'Movie,Series,Episode,Audio');
    });

    test('genre clause values join with the pipe separator Jellyfin ORs', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', values: ['Action', 'Drama']),
          ],
        ),
      );
      expect(params['Genres'], 'Action|Drama');
    });

    test('year clause values join with a comma', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'year', values: ['2020', '2021']),
          ],
        ),
      );
      expect(params['Years'], '2020,2021');
    });

    test('fields MediaBrowser cannot filter on are dropped instead of sent raw', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'director', values: ['12345']),
            LibraryFilter(field: 'file', values: ['1080p']),
          ],
        ),
      );
      expect(params, isNot(contains('director')));
      expect(params, isNot(contains('file')));
      expect(params, isNot(contains('Filters')));
    });

    test('a second clause on one field is dropped: /Items cannot AND them', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'genre', values: ['Action']),
            LibraryFilter(field: 'genre', values: ['Drama']),
          ],
        ),
      );
      expect(params['Genres'], 'Action');
    });

    test('sort field "title" maps to SortName, "addedAt" to DateCreated', () {
      final titleSort = translator.toQueryParameters(
        const LibraryQuery(
          sort: LibrarySort(field: 'title', direction: LibrarySortDirection.ascending),
        ),
      );
      expect(titleSort['SortBy'], 'SortName');
      expect(titleSort['SortOrder'], 'Ascending');

      final addedSort = translator.toQueryParameters(const LibraryQuery(sort: LibrarySort(field: 'addedAt')));
      expect(addedSort['SortBy'], 'DateCreated');
      expect(addedSort['SortOrder'], 'Descending');
    });

    test('Streamyfin broad sort keys map to Jellyfin ItemSortBy values', () {
      const cases = {
        'criticRating': 'CriticRating',
        'viewCount': 'PlayCount',
        'productionYear': 'ProductionYear',
        'runtime': 'Runtime',
        'officialRating': 'OfficialRating',
        'startDate': 'StartDate',
        'airTime': 'AirTime',
        'studio': 'Studio',
        'episode.addedAt': 'DateLastContentAdded,SortName',
      };

      for (final entry in cases.entries) {
        final params = translator.toQueryParameters(LibraryQuery(sort: LibrarySort(field: entry.key)));
        expect(params['SortBy'], entry.value, reason: entry.key);
      }
    });

    test('show date played sort maps to Jellyfin series-specific sort field', () {
      final showSort = translator.toQueryParameters(
        const LibraryQuery(
          kind: MediaKind.show,
          sort: LibrarySort(field: 'lastViewedAt'),
        ),
      );
      expect(showSort['SortBy'], 'SeriesDatePlayed');

      final movieSort = translator.toQueryParameters(
        const LibraryQuery(
          kind: MediaKind.movie,
          sort: LibrarySort(field: 'lastViewedAt'),
        ),
      );
      expect(movieSort['SortBy'], 'DatePlayed');
    });

    test('episode added sort maps to Jellyfin series content added sort', () {
      final descending = translator.toQueryParameters(
        const LibraryQuery(
          kind: MediaKind.show,
          sort: LibrarySort(field: 'episode.addedAt'),
        ),
      );
      expect(descending['SortBy'], 'DateLastContentAdded,SortName');
      expect(descending['SortOrder'], 'Descending');

      final ascending = translator.toQueryParameters(
        const LibraryQuery(
          kind: MediaKind.show,
          sort: LibrarySort(field: 'episode.addedAt', direction: LibrarySortDirection.ascending),
        ),
      );
      expect(ascending['SortBy'], 'DateLastContentAdded,SortName');
      expect(ascending['SortOrder'], 'Ascending');
    });

    test('nameStartsWith="#" maps to NameLessThan=A', () {
      final params = translator.toQueryParameters(const LibraryQuery(nameStartsWith: '#'));
      expect(params['NameLessThan'], 'A');
      expect(params, isNot(contains('NameStartsWith')));
    });

    test('nameStartsWith=letter maps to NameStartsWith', () {
      final params = translator.toQueryParameters(const LibraryQuery(nameStartsWith: 'B'));
      expect(params['NameStartsWith'], 'B');
      expect(params, isNot(contains('NameLessThan')));
    });

    test('unwatched clause sets Filters=IsUnplayed', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'unwatched', values: ['1']),
          ],
        ),
      );
      expect(params['Filters'], 'IsUnplayed');
    });

    test('a negated unwatched clause asks for played items instead', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'unwatched', op: LibraryFilterOperator.isNot, values: ['1']),
          ],
        ),
      );
      expect(params['Filters'], 'IsPlayed');
    });

    test('favorite clause sets Filters=IsFavorite, its negation sets isFavorite=false', () {
      final favorite = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'favorite', values: ['1']),
          ],
        ),
      );
      expect(favorite['Filters'], 'IsFavorite');
      final notFavorite = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'favorite', op: LibraryFilterOperator.isNot, values: ['1']),
          ],
        ),
      );
      expect(notFavorite['isFavorite'], 'false');
      expect(notFavorite, isNot(contains('Filters')));
    });

    test('unwatched + favorites combine into a comma-separated Filters list', () {
      final params = translator.toQueryParameters(
        const LibraryQuery(
          filters: [
            LibraryFilter(field: 'unwatched', values: ['1']),
            LibraryFilter(field: 'favorite', values: ['1']),
          ],
        ),
      );
      expect(params['Filters'], 'IsUnplayed,IsFavorite');
    });

    test('search puts text in SearchTerm', () {
      final params = translator.toQueryParameters(const LibraryQuery(search: 'matrix'));
      expect(params['SearchTerm'], 'matrix');
    });

    test('offset/limit pass through as StartIndex/Limit strings', () {
      final params = translator.toQueryParameters(const LibraryQuery(offset: 50, limit: 25));
      expect(params['StartIndex'], '50');
      expect(params['Limit'], '25');
    });
  });

  group('LibraryQueryTranslator.parseSortParam', () {
    test('returns null for null/empty input', () {
      expect(LibraryQueryTranslator.parseSortParam(null), isNull);
      expect(LibraryQueryTranslator.parseSortParam(''), isNull);
    });

    test('parses bare field as ascending', () {
      final sort = LibraryQueryTranslator.parseSortParam('addedAt');
      expect(sort, isNotNull);
      expect(sort!.field, 'addedAt');
      expect(sort.direction, LibrarySortDirection.ascending);
    });

    test('parses field:desc as descending', () {
      final sort = LibraryQueryTranslator.parseSortParam('rating:desc');
      expect(sort, isNotNull);
      expect(sort!.field, 'rating');
      expect(sort.direction, LibrarySortDirection.descending);
    });

    test('handles dotted Plex sort keys without losing the field', () {
      final sort = LibraryQueryTranslator.parseSortParam('episode.originallyAvailableAt:desc');
      expect(sort!.field, 'episode.originallyAvailableAt');
      expect(sort.direction, LibrarySortDirection.descending);
    });

    test('returns null when only the suffix is present', () {
      expect(LibraryQueryTranslator.parseSortParam(':desc'), isNull);
    });
  });

  // The browse tab holds the user's selection as clauses and assembles the
  // neutral query at the fetch boundary; the Plex client lowers it back to
  // wire params. Selections saved by prior versions (and by the sheet) must
  // survive that trip, so the assembly is pinned here.
  group('libraryQueryFromSelection', () {
    const translator = PlexLibraryQueryTranslator();

    Map<String, dynamic> wire({
      List<LibraryFilter> clauses = const [],
      MediaKind? libraryKind,
      String? typeParam,
      String? sortParam,
      String? alphaPrefix,
    }) => translator.toQueryParameters(
      libraryQueryFromSelection(
        clauses: clauses,
        libraryKind: libraryKind,
        typeParam: typeParam,
        sortParam: sortParam,
        alphaPrefix: alphaPrefix,
      ),
    );

    test('clauses, sort and alpha prefix reach the wire together', () {
      expect(
        wire(
          clauses: const [
            LibraryFilter(field: 'genre', values: ['Comedy']),
            LibraryFilter(field: 'unwatched', values: ['1']),
          ],
          sortParam: 'addedAt:desc',
          alphaPrefix: 'B',
        ),
        {'genre': 'Comedy', 'unwatched': '1', 'sort': 'addedAt:desc', 'alphaPrefix': 'B'},
      );
    });

    test('libraryKind overrides any grouping type parameter', () {
      final query = libraryQueryFromSelection(clauses: const [], typeParam: '1', libraryKind: MediaKind.show);
      expect(query.kind, MediaKind.show);
    });

    test('numeric grouping type maps to a kind when no libraryKind is given', () {
      final query = libraryQueryFromSelection(clauses: const [], typeParam: '1');
      expect(query.kind, MediaKind.movie);
    });

    test('multi-value type stays a clause so Plex still receives it verbatim', () {
      // Plex shared libraries use `type=1,4` for movies+episodes — no single
      // MediaKind covers that.
      expect(wire(typeParam: '1,4')['type'], '1,4');
    });

    test('an empty selection produces an empty query', () {
      expect(wire(), isEmpty);
    });
  });
}
