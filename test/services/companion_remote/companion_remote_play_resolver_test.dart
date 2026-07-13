import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/companion_remote/companion_remote_play_resolver.dart';

MediaItem _item(String id, MediaKind kind, {String? parentId, String? grandparentId, int? index}) => MediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: kind,
  title: id,
  parentId: parentId,
  grandparentId: grandparentId,
  index: index,
);

class _FakeClient implements MediaServerClient {
  _FakeClient({this.itemsById = const {}, this.onDeckByShow = const {}, this.childrenByParent = const {}});

  final Map<String, MediaItem> itemsById;
  final Map<String, MediaItem> onDeckByShow;
  final Map<String, List<MediaItem>> childrenByParent;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id) async =>
      (item: itemsById[id], onDeckEpisode: onDeckByShow[id]);

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async => childrenByParent[parentId] ?? const [];

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(String parentId, {int? start, int? size, abort}) async {
    final all = childrenByParent[parentId] ?? const <MediaItem>[];
    final limit = size ?? all.length;
    return LibraryPage(items: all.take(limit).toList(), totalCount: all.length, offset: start ?? 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('movie resolves to itself', () async {
    final movie = _item('m1', MediaKind.movie);
    final client = _FakeClient(itemsById: {'m1': movie});

    final target = await resolveCompanionRemotePlaybackTarget(client, 'm1');

    expect(target?.id, 'm1');
  });

  test('show with an on-deck episode resolves to that episode', () async {
    final show = _item('show1', MediaKind.show);
    final onDeck = _item('ep5', MediaKind.episode, grandparentId: 'show1');
    final client = _FakeClient(itemsById: {'show1': show}, onDeckByShow: {'show1': onDeck});

    final target = await resolveCompanionRemotePlaybackTarget(client, 'show1');

    expect(target?.id, 'ep5');
  });

  test('season resolves through its show to the show-level on-deck episode', () async {
    final show = _item('show1', MediaKind.show);
    final season = _item('season3', MediaKind.season, parentId: 'show1', index: 3);
    final onDeck = _item('ep2', MediaKind.episode, grandparentId: 'show1');
    final client = _FakeClient(itemsById: {'show1': show, 'season3': season}, onDeckByShow: {'show1': onDeck});

    final target = await resolveCompanionRemotePlaybackTarget(client, 'season3');

    expect(target?.id, 'ep2');
  });

  test('show without an on-deck episode falls back to the first episode of the default season', () async {
    final show = _item('show1', MediaKind.show);
    final season = _item('season1', MediaKind.season, parentId: 'show1', index: 1);
    final episode = _item('ep1', MediaKind.episode, parentId: 'season1', grandparentId: 'show1');
    final client = _FakeClient(
      itemsById: {'show1': show},
      childrenByParent: {
        'show1': [season],
        'season1': [episode],
      },
    );

    final target = await resolveCompanionRemotePlaybackTarget(client, 'show1');

    expect(target?.id, 'ep1');
  });

  test('unresolvable rating key returns null', () async {
    final client = _FakeClient();

    final target = await resolveCompanionRemotePlaybackTarget(client, 'missing');

    expect(target, isNull);
  });
}
