import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/canonical_library.dart';
import 'package:plezy/media/canonical_video_identity.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';

void main() {
  late SourceDatabase db;
  late SourceRepository sources;
  late CanonicalLibrary library;
  setUp(() {
    db = SourceDatabase(NativeDatabase.memory());
    sources = SourceRepository(db);
    library = CanonicalLibrary(db);
  });
  tearDown(() => db.close());
  SourceEntry cloud(String id, Map<String, String> ids) => SourceEntry(
    sourceId: 'cloud',
    id: id,
    title: 'Movie',
    kind: SourceItemKind.video,
    identifiers: {'plezyMediaType': 'movie', ...ids},
  );
  MediaItem server(String id, Map<String, String> ids) => MediaItem.plex(
    id: id,
    kind: MediaKind.movie,
    title: 'Movie',
    serverId: 'plex',
    raw: {
      'Guid': [
        for (final id in ids.entries) {'id': '${id.key}://${id.value}'},
      ],
    },
  );

  test('source and server share a stable card across refreshes and profiles stay separate', () async {
    final file = cloud('one', {'imdb': 'tt1234567'});
    await sources.cacheEntries('alice', [file]);
    final before = (await library.cardForCopy('alice', CanonicalLibrary.entryKey(file)))!;
    final video = server('42', {'imdb': 'tt1234567'});
    await library.recordServerItems('alice', [video]);
    await sources.cacheEntries('alice', [file]);
    final after = (await library.cardForCopy('alice', CanonicalLibrary.serverKey(video)))!;
    expect(after.id, before.id);
    expect(after.profile, 'alice');
    expect(after.copies, hasLength(2));
    expect(after.serverItem!.id, '42');
    await sources.cacheEntries('bob', [file]);
    expect((await library.cardForCopy('bob', CanonicalLibrary.entryKey(file)))!.id, isNot(after.id));
    await sources.forgetProfile('alice');
    expect(await library.cards('alice'), isEmpty);
    expect(await library.cards('bob'), hasLength(1));
  });

  test('late alias bridges merge both sides and old card handles redirect', () async {
    final a = cloud('a', {'imdb': 'tt1234567'}), b = cloud('b', {'tmdb': '42'});
    await sources.cacheEntries('alice', [a, b]);
    final original = (await library.cardForCopy('alice', CanonicalLibrary.entryKey(b)))!;
    await library.recordServerItems('alice', [
      server('bridge', {'imdb': 'tt1234567', 'tmdb': '42'}),
    ]);
    final cards = await library.cards('alice');
    expect(cards, hasLength(1));
    expect(cards.single.copies, hasLength(3));
    expect((await library.card('alice', original.id)).id, cards.single.id);
  });

  test('contradictory identifiers are isolated with a stable quarantine card', () async {
    final a = cloud('a', {'imdb': 'tt1234567', 'tmdb': '42'});
    final b = cloud('b', {'imdb': 'tt1234567', 'tmdb': '99'});
    await sources.cacheEntries('alice', [a, b]);
    final card = (await library.cardForCopy('alice', CanonicalLibrary.entryKey(b)))!;
    await sources.cacheEntries('alice', [b]);
    expect((await library.cardForCopy('alice', CanonicalLibrary.entryKey(b)))!.id, card.id);
    expect(await library.cards('alice'), hasLength(2));
  });

  test('titles alone never merge; disconnected cloud copies become unavailable', () async {
    final a = cloud('a', {}), b = cloud('b', {});
    await sources.cacheEntries('alice', [a, b]);
    expect(await library.cards('alice'), hasLength(2));
    await sources.removeSource('alice', 'cloud');
    expect((await library.cards('alice')).every((card) => card.copies.isEmpty), isTrue);
  });
  test('episode copies require series identity and the exact episode coordinates', () async {
    final file = SourceEntry(
      sourceId: 'cloud',
      id: 'episode',
      title: 'Episode',
      kind: SourceItemKind.video,
      identifiers: {'plezyMediaType': 'show', 'imdb': 'tt1234567', 'plezySeason': '1', 'plezyEpisode': '2'},
    );
    final episode = MediaItem.plex(
      id: 'e2',
      kind: MediaKind.episode,
      title: 'Episode',
      serverId: 'plex',
      parentIndex: 1,
      index: 2,
      raw: {
        'Guid': [
          {'id': 'imdb://tt1234567'},
        ],
      },
    );
    await sources.cacheEntries('alice', [file]);
    // An episode's own IMDb ID must not be interpreted as its series ID.
    await library.recordServerItems('alice', [episode]);
    expect(await library.cards('alice'), hasLength(2));
    await library.recordServerItems(
      'alice',
      [episode],
      identities: {
        episode.globalKey: canonicalVideoIdentitiesForExternalIds(
          identifiers: {'imdb': 'tt1234567'},
          mediaType: 'show',
          season: 1,
          episode: 2,
        ),
      },
    );
    expect(await library.cards('alice'), hasLength(1));
    final next = MediaItem.plex(
      id: 'e3',
      kind: MediaKind.episode,
      title: 'Episode',
      serverId: 'plex',
      parentIndex: 1,
      index: 3,
    );
    await library.recordServerItems(
      'alice',
      [next],
      identities: {
        next.globalKey: canonicalVideoIdentitiesForExternalIds(
          identifiers: {'imdb': 'tt1234567'},
          mediaType: 'show',
          season: 1,
          episode: 3,
        ),
      },
    );
    expect(await library.cards('alice'), hasLength(2));
  });
  test('search and visibility apply before paging across the full canonical library', () async {
    final target = MediaItem.plex(id: 'needle', kind: MediaKind.movie, title: 'Needle in library', serverId: 'plex');
    await library.recordServerItems('alice', [target], libraryId: 'visible');
    await library.recordServerItems('alice', [for (var i = 0; i < 125; i++) server('$i', {})], libraryId: 'hidden');
    final results = await library.cards('alice', query: 'needle', limit: 1, serverIds: {'plex'});
    expect(results.single.serverItem!.id, 'needle');
    final visible = await library.cards('alice', limit: 1, serverIds: {'plex'}, hiddenLibraryKeys: {'plex:hidden'});
    expect(visible.single.serverItem!.id, 'needle');
    expect(await library.cards('alice', serverIds: {}), isEmpty);
    final entry = cloud('needle', {'imdb': 'tt1234567'});
    await sources.cacheEntries('alice', [entry]);
    expect((await library.cards('alice', serverIds: {})).single.entry!.id, 'needle');
  });

  test('complete scans prune missing server copies without losing cloud cards or concurrent refreshes', () async {
    final entry = cloud('one', {'imdb': 'tt1234567'});
    final missing = server('missing', {'imdb': 'tt1234567'}),
        retained = server('retained', {}),
        concurrent = server('concurrent', {});
    await sources.cacheEntries('alice', [entry]);
    await library.recordServerItems('alice', [missing, retained, concurrent], libraryId: 'movies');
    final original = (await library.cardForCopy('alice', CanonicalLibrary.entryKey(entry)))!.id;
    await db.customStatement('UPDATE canonical_copies SET updated=1');
    await library.recordServerItems('alice', [concurrent], libraryId: 'movies');
    await library.reconcileServerLibrary('alice', 'plex', 'movies', {CanonicalLibrary.serverKey(retained)}, 2);
    final card = (await library.cardForCopy('alice', CanonicalLibrary.entryKey(entry)))!;
    expect(card.id, original);
    expect(card.copies, hasLength(1));
    expect(await library.cardForCopy('alice', CanonicalLibrary.serverKey(missing)), isNull);
    expect(await library.cardForCopy('alice', CanonicalLibrary.serverKey(concurrent)), isNotNull);
    expect(await library.cardForCopy('alice', CanonicalLibrary.serverKey(retained)), isNotNull);
  });

  test('canonical card and source choices survive closing and reopening SQLite', () async {
    final directory = await Directory.systemTemp.createTemp('canonical-restart-');
    final file = File('${directory.path}/library.sqlite');
    final first = SourceDatabase(NativeDatabase(file));
    final entry = cloud('persisted', {'imdb': 'tt1234567'});
    await SourceRepository(first).cacheEntries('alice', [entry]);
    final id = (await CanonicalLibrary(first).cardForCopy('alice', CanonicalLibrary.entryKey(entry)))!.id;
    await first.close();
    final reopened = SourceDatabase(NativeDatabase(file));
    try {
      final card = (await CanonicalLibrary(reopened).cardForCopy('alice', CanonicalLibrary.entryKey(entry)))!;
      expect(card.id, id);
      expect(card.entry!.id, 'persisted');
    } finally {
      await reopened.close();
      await directory.delete(recursive: true);
    }
  });
}
