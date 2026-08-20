import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/metadata_edit/plex_metadata_edit_adapter.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
  });

  tearDown(() => database.close());

  test('metadata preference request uses includePreferences and canonicalizes server values', () async {
    Uri? requestedUri;
    final client = testPlexClient(
      handler: (request) async {
        requestedUri = request.url;
        return _metadataResponse([
          {'id': 'episodeSort', 'value': 0},
          {'id': 'autoDeletionItemPolicyUnwatchedLibrary', 'value': 3},
          {'id': 'autoDeletionItemPolicyWatchedLibrary', 'value': 7},
          {'id': 'flattenSeasons', 'value': 1},
          {'id': 'showOrdering', 'value': 'tvdbAbsolute'},
          {'id': 'languageOverride', 'value': 'fr-FR'},
          {'id': 'useOriginalTitle', 'value': true},
          {'id': 'audioLanguage', 'value': 'ja'},
          {'id': 'subtitleLanguage', 'value': 'en'},
          {'id': 'subtitleMode', 'value': 2},
        ]);
      },
    );
    addTearDown(client.close);

    final draft = await PlexMetadataEditAdapter(client).load(_show());

    expect(requestedUri?.path, '/library/metadata/show-1');
    expect(requestedUri?.queryParameters['includePreferences'], '1');
    expect(draft.value<String>('originalTitle'), 'Original show title');
    expect(draft.value<String>('pref:episodeSort'), '0');
    expect(draft.value<String>('pref:autoDeletionItemPolicyUnwatchedLibrary'), '3');
    expect(draft.value<String>('pref:autoDeletionItemPolicyWatchedLibrary'), '7');
    expect(draft.value<String>('pref:flattenSeasons'), '1');
    expect(draft.value<String>('pref:showOrdering'), 'tvdbAbsolute');
    expect(draft.value<String>('pref:languageOverride'), 'fr-FR');
    expect(draft.value<String>('pref:useOriginalTitle'), '1');
    expect(draft.value<String>('pref:audioLanguage'), 'ja');
    expect(draft.value<String>('pref:subtitleLanguage'), 'en');
    expect(draft.value<String>('pref:subtitleMode'), '2');
  });

  test('missing preference rows remain unset instead of becoming fabricated defaults', () async {
    final client = testPlexClient(
      handler: (_) async => _metadataResponse([
        {'id': 'episodeSort', 'value': 0},
      ]),
    );
    addTearDown(client.close);

    final draft = await PlexMetadataEditAdapter(client).load(_show());

    expect(draft.value<String>('pref:episodeSort'), '0');
    expect(draft.value<String>('pref:flattenSeasons'), isNull);
    expect(draft.value<String>('pref:showOrdering'), isNull);
    expect(draft.value<String>('pref:languageOverride'), isNull);
    expect(draft.value<String>('pref:useOriginalTitle'), isNull);
    expect(draft.value<String>('pref:audioLanguage'), isNull);
    expect(draft.value<String>('pref:subtitleMode'), isNull);
  });

  test('metadata preference request failures preserve the editable basic fields', () async {
    final client = testPlexClient(handler: (_) async => http.Response('{}', 503));
    addTearDown(client.close);

    final draft = await PlexMetadataEditAdapter(client).load(_show());

    expect(draft.value<String>('title'), 'Show');
    expect(draft.value<String>('originalTitle'), 'Original show title');
    expect(draft.value<String>('pref:episodeSort'), isNull);
  });

  test('removed tags are emitted single-encoded because the transport encodes exactly once', () async {
    Uri? requestedUri;
    final client = testPlexClient(
      handler: (request) async {
        requestedUri = request.url;
        return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
      },
    );
    addTearDown(client.close);

    final ok = await client.updateMetadata(
      sectionId: 1,
      ratingKey: 'show-1',
      typeNumber: 2,
      tagChanges: {
        'genre': (current: ['Drama'], original: ['Drama', 'Science Fiction']),
      },
    );

    expect(ok, isTrue);
    expect(requestedUri, isNotNull);
    // Decoding the emitted query once must yield the original tag. The old
    // Uri.encodeComponent pre-pass double-encoded it ('Science%2520Fiction'
    // on the wire), so the server deleted a tag that doesn't exist.
    expect(requestedUri!.queryParameters['genre[].tag.tag-'], 'Science Fiction');
    expect(requestedUri!.query, contains('Science%20Fiction'));
    expect(requestedUri!.query, isNot(contains('%2520')));
  });
}

http.Response _metadataResponse(List<Object?> settings) {
  return http.Response(
    jsonEncode({
      'MediaContainer': {
        'Metadata': [
          {'ratingKey': 'show-1', 'Setting': settings},
        ],
      },
    }),
    200,
    headers: const {'content-type': 'application/json'},
  );
}

MediaItem _show() => testMediaItem(
  id: 'show-1',
  backend: MediaBackend.plex,
  kind: MediaKind.show,
  title: 'Show',
  originalTitle: 'Original show title',
  summary: 'Summary',
  libraryId: '1',
);
