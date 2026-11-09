import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/title_copies.dart';
import 'package:plezy/services/continue_watching_copy_resolver.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/utils/media_server_http_client.dart';

class _Client extends Fake implements MediaServerClient {
  @override
  Future<ExternalIds> fetchExternalIds(String id) async => const ExternalIds(tvdb: 777);

  @override
  Future<MediaItem?> fetchItem(String id) async =>
      MediaItem.plex(id: id, kind: MediaKind.show, title: 'Shared Show', year: 2022, guid: 'plex://show/shared');
}

const source = MediaItem.plex(
  id: 'uhd',
  kind: MediaKind.episode,
  title: 'Episode 1',
  grandparentId: 'show-uhd',
  grandparentTitle: 'Shared Show',
  parentIndex: 3,
  index: 1,
  serverId: 'server',
  libraryId: '6',
  libraryTitle: 'Series - 4K',
  durationMs: 3600000,
);

final hd = source.copyWith(id: 'hd', grandparentId: 'show-hd', libraryId: '4', libraryTitle: 'Series');
final dv = source.copyWith(id: 'dv', grandparentId: 'show-dv', libraryId: '7', libraryTitle: 'Series - 4K DolbyVision');

LibraryLookupResult result(List<MediaItem> items, {Set<String> failed = const {}}) => (
  items: items,
  succeededServerIds: const {'server'},
  failedServerIds: failed,
  cancelledServerIds: const {},
  unqueriedServerIds: const {},
);

void main() {
  late ContinueWatchingCopyResolver resolver;
  late Future<LibraryLookupResult> Function(TitleQuery query, {AbortController? abort}) find;
  late DateTime now;
  late String scope;
  var calls = 0;
  TitleQuery? query;

  setUp(() {
    now = DateTime(2026, 11, 9);
    scope = 'profile-one';
    calls = 0;
    query = null;
    find = (query, {abort}) async => result([source, hd, dv]);
    resolver = ContinueWatchingCopyResolver(
      clientFor: (_) => _Client(),
      now: () => now,
      findCopies: (value, {abort}) {
        calls++;
        query = value;
        return find(value, abort: abort);
      },
    );
  });

  Future<ContinueWatchingCopyLookup> resolve({
    MediaItem item = source,
    List<MediaItem> known = const [],
    Set<String> hidden = const {},
    AbortController? abort,
  }) => resolver.resolve(item, knownCopies: known, hiddenLibraryKeys: hidden, scopeKey: () => scope, abort: abort);

  test('one hub item expands to all three library copies of the exact episode', () async {
    final lookup = await resolve();
    expect(lookup.copies.map((copy) => copy.id).toSet(), {'uhd', 'hd', 'dv'});
    expect(lookup.isComplete, isTrue);
    expect(query!.season, 3);
    expect(query!.episode, 1);
    expect(query!.showIds.tvdb, 777);
  });

  test('a movie uses its title, year and external IDs to find library copies', () async {
    const movie = MediaItem.plex(
      id: 'movie-uhd',
      kind: MediaKind.movie,
      title: 'Shared Movie',
      year: 2020,
      guid: 'plex://movie/shared',
      serverId: 'server',
      libraryId: 'movies-uhd',
    );
    find = (_, {abort}) async => result([movie.copyWith(id: 'movie-hd', libraryId: 'movies-hd')]);
    final lookup = await resolve(item: movie);
    expect(lookup.copies.map((copy) => copy.id).toSet(), {'movie-uhd', 'movie-hd'});
    expect(query!.title, 'Shared Movie');
    expect(query!.year, 2020);
    expect(query!.ids.tvdb, 777);
    expect(query!.plexGuid, 'plex://movie/shared');
  });

  test('hidden libraries are excluded from both fetched and known choices', () async {
    final lookup = await resolve(known: [hd, dv], hidden: {'server:4', 'server:7'});
    expect(lookup.copies.map((copy) => copy.id), ['uhd']);
  });

  test('a backend returning another episode cannot add it to the discovered choices', () async {
    find = (_, {abort}) async => result([hd, dv.copyWith(index: 2)]);
    final lookup = await resolve();
    expect(lookup.copies.map((copy) => copy.id).toSet(), {'uhd', 'hd'});
  });

  test('partial server results preserve known choices and are retried on the next activation', () async {
    find = (_, {abort}) async => result([hd], failed: {'another-server'});
    final partial = await resolve(known: [dv]);
    expect(partial.copies.map((copy) => copy.id).toSet(), {'uhd', 'hd', 'dv'});
    expect(partial.isComplete, isFalse);
    await resolve();
    expect(calls, 2);
  });

  test('a failed lookup leaves the original and known copies selectable', () async {
    find = (_, {abort}) async => throw StateError('offline');
    final lookup = await resolve(known: [dv]);
    expect(lookup.copies.map((copy) => copy.id).toSet(), {'uhd', 'dv'});
    expect(lookup.isComplete, isFalse);
  });

  test('cache reuses catalogue membership but preserves fresh row progress', () async {
    await resolve();
    final fresh = await resolve(item: source.copyWith(viewOffsetMs: 60000));
    expect(calls, 1);
    expect(fresh.copies.singleWhere((copy) => copy.id == 'uhd').viewOffsetMs, 60000);
    expect(fresh.copies.singleWhere((copy) => copy.id == 'hd').viewOffsetMs, 60000);
  });

  test('resume fallback requires compatible durations and editions', () async {
    find = (_, {abort}) async =>
        result([hd.copyWith(durationMs: 1000000), (dv as PlexMediaItem).copyWith(editionTitle: 'Other cut')]);
    final lookup = await resolve(item: source.copyWith(viewOffsetMs: 60000));
    expect(lookup.copies.singleWhere((copy) => copy.id == 'hd').viewOffsetMs, isNull);
    expect(lookup.copies.singleWhere((copy) => copy.id == 'dv').viewOffsetMs, isNull);
  });

  test('changing to a discovered library copy reuses the verified membership cache', () async {
    await resolve();
    final lookup = await resolve(item: dv);
    expect(lookup.copies.map((copy) => copy.id).toSet(), {'uhd', 'hd', 'dv'});
    expect(calls, 1);
  });

  test('server/auth scope and visibility changes do not reuse the old cache', () async {
    await resolve();
    scope = 'profile-two-new-auth';
    await resolve();
    expect(calls, 2);
    await resolve(hidden: {'server:7'});
    expect(calls, 3);
  });

  test('expired and invalidated catalogue results are fetched again', () async {
    await resolve();
    now = now.add(const Duration(minutes: 2));
    await resolve();
    expect(calls, 2);
    resolver.clear();
    await resolve();
    expect(calls, 3);
  });

  test('canceling a pending lookup completes promptly and ignores its late result', () async {
    final pending = Completer<LibraryLookupResult>();
    final started = Completer<void>();
    find = (_, {abort}) {
      started.complete();
      return pending.future;
    };
    final abort = AbortController();
    final future = resolve(abort: abort);
    await started.future;
    final cancelled = expectLater(
      future,
      throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'cancelled', true)),
    );
    abort.abort();
    await cancelled;
    pending.complete(result([source, hd, dv]));
  });

  test('an authentication change during a lookup prevents publishing its result', () async {
    final pending = Completer<LibraryLookupResult>();
    final started = Completer<void>();
    find = (_, {abort}) {
      started.complete();
      return pending.future;
    };
    final future = resolve();
    await started.future;
    final rejected = expectLater(future, throwsA(isA<MediaServerHttpException>()));
    scope = 'different-profile';
    pending.complete(result([source, hd, dv]));
    await rejected;
  });

  test('a hung server cannot hold the chooser past the lookup deadline', () async {
    final pending = Completer<LibraryLookupResult>();
    resolver = ContinueWatchingCopyResolver(
      clientFor: (_) => _Client(),
      findCopies: (_, {abort}) => pending.future,
      deadline: const Duration(milliseconds: 10),
    );
    final lookup = await resolve();
    expect(lookup.isComplete, isFalse);
    expect(lookup.copies.map((copy) => copy.id), ['uhd']);
    pending.complete(result([source, hd, dv]));
  });
}
