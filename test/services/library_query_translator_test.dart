import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/library_query_translator.dart';

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

    test('includeWatched=false sets unwatched=1', () {
      final params = translator.toQueryParameters(const LibraryQuery(includeWatched: false));
      expect(params['unwatched'], '1');
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
      expect(params['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(params['ImageTypeLimit'], '1');
    });

    test('movie kind maps to IncludeItemTypes=Movie', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.movie));
      expect(params['IncludeItemTypes'], 'Movie');
    });

    test('show kind maps to IncludeItemTypes=Series', () {
      final params = translator.toQueryParameters(const LibraryQuery(kind: MediaKind.show));
      expect(params['IncludeItemTypes'], 'Series');
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

    test('genres joined with pipe separator', () {
      final params = translator.toQueryParameters(const LibraryQuery(genres: ['Action', 'Drama']));
      expect(params['Genres'], 'Action|Drama');
    });

    test('years joined with comma separator', () {
      final params = translator.toQueryParameters(const LibraryQuery(years: [2020, 2021]));
      expect(params['Years'], '2020,2021');
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

    test('includeWatched=false sets Filters=IsUnplayed', () {
      final params = translator.toQueryParameters(const LibraryQuery(includeWatched: false));
      expect(params['Filters'], 'IsUnplayed');
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

  // The library browse tab still keeps `_selectedFilters` as a Plex-shaped
  // map (the FiltersBottomSheet emits that shape) but routes it through
  // `libraryQueryFromPlexMap` at the `fetchLibraryPagedContent` boundary.
  // The Plex client then translates the resulting `LibraryQuery` back to a
  // map via `PlexLibraryQueryTranslator`. Round-tripping must be loss-free
  // (modulo the `includeCollections=1` always-on case the client adds back
  // explicitly) so user-saved filters from prior versions don't silently
  // drop on first reload.
  group('libraryQueryFromPlexMap round-trip with PlexLibraryQueryTranslator', () {
    const translator = PlexLibraryQueryTranslator();

    Map<String, String> roundTrip(Map<String, String> input, {MediaKind? libraryKind}) {
      final query = libraryQueryFromPlexMap(map: input, libraryKind: libraryKind);
      return translator.toQueryParameters(query);
    }

    test('genre + sort round-trips into the same map', () {
      final input = {'genre': 'Comedy', 'sort': 'addedAt:desc'};
      expect(roundTrip(input), {'genre': 'Comedy', 'sort': 'addedAt:desc'});
    });

    test('multi-value year filter round-trips', () {
      final input = {'year': '2010,2011,2012'};
      expect(roundTrip(input)['year'], '2010,2011,2012');
    });

    test('contentRating + tag + alphaPrefix round-trip together', () {
      final input = {'contentRating': 'PG-13', 'tag': 'Christmas', 'alphaPrefix': 'A'};
      expect(roundTrip(input), {'contentRating': 'PG-13', 'tag': 'Christmas', 'alphaPrefix': 'A'});
    });

    test('unwatched=1 round-trips (LibraryQuery.includeWatched=false → unwatched=1)', () {
      final input = {'unwatched': '1'};
      expect(roundTrip(input), {'unwatched': '1'});
    });

    test('unwatched absent round-trips to absent (default includeWatched=true)', () {
      expect(roundTrip(const {}), isEmpty);
    });

    test('unknown Plex filter keys (director) survive as generic LibraryFilter entries', () {
      final input = {'director': '12345'};
      expect(roundTrip(input)['director'], '12345');
    });

    test('libraryKind argument overrides any type entry in the map', () {
      // The browse tab always passes the library's actual kind; map's `type`
      // is dropped if the explicit arg is present.
      final query = libraryQueryFromPlexMap(map: {'type': '1'}, libraryKind: MediaKind.show);
      expect(query.kind, MediaKind.show);
    });

    test('multi-value type stays in the generic filters bucket (Plex passes it verbatim)', () {
      // Plex shared libraries use `type=1,4` to mean movies+episodes — no
      // single MediaKind covers that, so it has to round-trip via filters.
      final input = {'type': '1,4'};
      expect(roundTrip(input)['type'], '1,4');
    });

    test('numeric type maps to MediaKind when libraryKind is absent', () {
      final query = libraryQueryFromPlexMap(map: {'type': '1'});
      expect(query.kind, MediaKind.movie);
    });

    test('full realistic browse-tab map round-trips byte-for-byte', () {
      final input = {
        'genre': 'Comedy',
        'year': '2024',
        'contentRating': 'PG-13',
        'tag': 'Christmas',
        'unwatched': '1',
        'sort': 'rating:desc',
        'alphaPrefix': 'B',
      };
      // includeCollections is added by PlexClient.fetchLibraryPagedContent
      // *after* the translator, so the round-trip-only output skips it. The
      // production path still emits it.
      expect(roundTrip(input), input);
    });
  });
}
