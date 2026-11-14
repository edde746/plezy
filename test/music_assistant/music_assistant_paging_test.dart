import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_kind.dart';

import 'fake_ma_server.dart';

/// Paging costs and boundaries, as opposed to paging *results* — those live in
/// `music_assistant_client_test.dart`. Everything here is about how many times
/// the client asks, and where it decides one region of a list ends.
void main() {
  group('child lists are read once, not once per page', () {
    /// A playlist of [size] tracks, answering `playlist_tracks` in full every
    /// time — which is what the command does: it takes no limit or offset.
    FakeMaServer playlistServer({int size = 500}) {
      final tracks = [for (var i = 0; i < size; i++) maTrack('$i')];
      return FakeMaServer(
        responder: (command, args) {
          if (command.endsWith('/playlist_tracks')) return tracks;
          if (command.endsWith('/album_tracks')) return tracks;
          if (command.endsWith('/count')) return size;
          return const <dynamic>[];
        },
      );
    }

    test('paging a playlist does not re-download the playlist per page', () async {
      final server = playlistServer();
      final client = await connectedClient(server);
      addTearDown(client.close);

      // What a scroll through a long playlist looks like from here.
      for (var start = 0; start < 500; start += 100) {
        final page = await client.fetchPlaylistPage('library://playlist/4', start: start, size: 100);
        expect(page.items, hasLength(100));
        expect(page.totalCount, 500);
      }

      expect(
        server.countOf('music/playlists/playlist_tracks'),
        1,
        reason: 'five pages of a 500-track playlist must not be five full reads of it',
      );
    });

    test('concurrent pages of the same list collapse into one read', () async {
      final server = playlistServer();
      final client = await connectedClient(server);
      addTearDown(client.close);

      // A fast scroll issues overlapping requests; memoising the value rather
      // than the future would let every one of them miss.
      await Future.wait([
        client.fetchPlaylistPage('library://playlist/4', start: 0, size: 100),
        client.fetchPlaylistPage('library://playlist/4', start: 100, size: 100),
        client.fetchPlaylistPage('library://playlist/4', start: 200, size: 100),
      ]);

      expect(server.countOf('music/playlists/playlist_tracks'), 1);
    });

    test('album children share the same memo as their pages', () async {
      final server = playlistServer(size: 12);
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchChildren('library://album/7058');
      await client.fetchChildrenPage('library://album/7058', start: 0, size: 5);
      await client.fetchChildrenPage('library://album/7058', start: 5, size: 5);

      expect(server.countOf('music/albums/album_tracks'), 1);
    });

    test('a failed read is not served from the memo for the rest of its life', () async {
      var attempts = 0;
      final server = FakeMaServer(
        responder: (command, args) {
          if (!command.endsWith('/playlist_tracks')) return const <dynamic>[];
          attempts++;
          if (attempts == 1) return const MaErrorReply(999, 'no such column');
          return [maTrack('1')];
        },
      );
      final client = await connectedClient(server);
      addTearDown(client.close);

      await expectLater(client.fetchPlaylistPage('library://playlist/4', start: 0, size: 10), throwsA(anything));
      final page = await client.fetchPlaylistPage('library://playlist/4', start: 0, size: 10);

      expect(page.items, hasLength(1));
    });
  });

  group('the # block is measured, not guessed at', () {
    /// Rows whose `sort_name` is punctuation only, which is what collates to
    /// the empty key and lands at offset 0.
    List<Map<String, dynamic>> junk(int count, {int from = 0}) => [
      for (var i = 0; i < count; i++) maAlbum('j${from + i}', name: '!' * (i + 1)),
    ];

    List<Map<String, dynamic>> real(int count, {int from = 0}) => [
      for (var i = 0; i < count; i++) maAlbum('r${from + i}', name: 'Album ${from + i}'),
    ];

    FakeMaServer withHead(List<Map<String, dynamic>> firstPage, {int total = 1000}) {
      return FakeMaServer(
        responder: (command, args) {
          if (command.endsWith('/count')) return total;
          if (!command.endsWith('/library_items')) return const <dynamic>[];
          final offset = args['offset'] as int? ?? 0;
          final limit = args['limit'] as int? ?? 500;
          return firstPage.skip(offset).take(limit).toList();
        },
      );
    }

    Future<List<String?>> firstTitles(FakeMaServer server, {int limit = 6}) async {
      final client = await connectedClient(server);
      addTearDown(client.close);
      final page = await client.fetchLibraryPagedContent(
        'music',
        query: LibraryQuery(kind: MediaKind.album, limit: limit),
      );
      return page.items.map((item) => item.title).toList();
    }

    test('a letter-bearing row inside the block travels with it', () async {
      // The reference library has a Cherokee-script track sorting *among* the
      // symbols — it collates nowhere, which is what the # bucket means, and
      // splitting the block around it would leave junk at offset 0.
      final page = [...junk(3), maAlbum('cherokee', name: 'ᎡᎯᏍᏛ'), ...junk(2, from: 3), ...real(100)];
      final titles = await firstTitles(withHead(page));

      expect(titles.first, 'Album 0', reason: 'the rotated list must open on a real title');
      expect(titles, isNot(contains('ᎡᎯᏍᏛ')));
    });

    test('one symbol-only title deep in the page does not rotate the page behind it', () async {
      // Unbounded, taking the index after the *last* unsortable row would move
      // 200 correctly-sorted albums to the end of the list because of one.
      final page = [...real(200), maAlbum('stray', name: '???'), ...real(200, from: 200)];
      final titles = await firstTitles(withHead(page));

      expect(titles.first, 'Album 0');
    });

    test('a first page that is entirely unsortable abandons the rotation', () async {
      final titles = await firstTitles(withHead(junk(200)), limit: 3);

      expect(titles.first, '!');
    });
  });
}
