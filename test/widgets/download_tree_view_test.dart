import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/widgets/download_tree_view.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/theme.dart';

DownloadTreeNode _episodeNode(String globalKey) => DownloadTreeNode(
  key: globalKey,
  title: 'Episode',
  type: DownloadNodeType.episode,
  status: DownloadStatus.completed,
);

DownloadTreeNode _seasonNode({required String key, required List<DownloadTreeNode> children}) => DownloadTreeNode(
  key: key,
  title: 'Season',
  type: DownloadNodeType.season,
  status: DownloadStatus.completed,
  children: children,
);

DownloadTreeNode _showNode({required String key, required List<DownloadTreeNode> children}) => DownloadTreeNode(
  key: key,
  title: 'Show',
  type: DownloadNodeType.show,
  status: DownloadStatus.completed,
  children: children,
);

MediaItem _episodeMeta({
  required String id,
  required ServerId? serverId,
  required String? grandparentId,
  required String? parentId,
}) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Ep $id',
  serverId: serverId,
  grandparentId: grandparentId,
  parentId: parentId,
);

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('resolveDownloadContainerGlobalKey', () {
    test('show node: builds globalKey from leaf serverId + grandparentId', () {
      final ep = _episodeNode('plex1:ep100');
      final season = _seasonNode(key: 'show42:season7', children: [ep]);
      final show = _showNode(key: 'show42', children: [season]);
      final metadata = {
        'plex1:ep100': _episodeMeta(id: '100', serverId: ServerId('plex1'), grandparentId: '42', parentId: '7'),
      };

      expect(resolveDownloadContainerGlobalKey(show, metadata), 'plex1:42');
    });

    test('season node: builds globalKey from leaf serverId + parentId', () {
      final ep = _episodeNode('plex1:ep100');
      final season = _seasonNode(key: 'show42:season7', children: [ep]);
      final metadata = {
        'plex1:ep100': _episodeMeta(id: '100', serverId: ServerId('plex1'), grandparentId: '42', parentId: '7'),
      };

      expect(resolveDownloadContainerGlobalKey(season, metadata), 'plex1:7');
    });

    test('episode and movie nodes return null (not container types)', () {
      final ep = _episodeNode('plex1:ep100');
      final movie = DownloadTreeNode(
        key: 'plex1:movie5',
        title: 'M',
        type: DownloadNodeType.movie,
        status: DownloadStatus.completed,
      );
      final metadata = {
        'plex1:ep100': _episodeMeta(id: '100', serverId: ServerId('plex1'), grandparentId: '42', parentId: '7'),
      };

      expect(resolveDownloadContainerGlobalKey(ep, metadata), isNull);
      expect(resolveDownloadContainerGlobalKey(movie, metadata), isNull);
    });

    test('container with no leaves returns null', () {
      final empty = _showNode(key: 'show42', children: []);
      expect(resolveDownloadContainerGlobalKey(empty, {}), isNull);
    });

    test('leaf metadata missing in map returns null', () {
      final ep = _episodeNode('plex1:ep100');
      final show = _showNode(key: 'show42', children: [ep]);
      expect(resolveDownloadContainerGlobalKey(show, const {}), isNull);
    });

    test('leaf metadata missing serverId returns null', () {
      final ep = _episodeNode('plex1:ep100');
      final show = _showNode(key: 'show42', children: [ep]);
      final metadata = {'plex1:ep100': _episodeMeta(id: '100', serverId: null, grandparentId: '42', parentId: '7')};
      expect(resolveDownloadContainerGlobalKey(show, metadata), isNull);
    });

    test('show node with leaf missing grandparentId returns null', () {
      final ep = _episodeNode('plex1:ep100');
      final show = _showNode(key: 'show42', children: [ep]);
      final metadata = {
        'plex1:ep100': _episodeMeta(id: '100', serverId: ServerId('plex1'), grandparentId: null, parentId: '7'),
      };
      expect(resolveDownloadContainerGlobalKey(show, metadata), isNull);
    });

    test('season node with leaf missing parentId returns null', () {
      final ep = _episodeNode('plex1:ep100');
      final season = _seasonNode(key: 'show42:season7', children: [ep]);
      final metadata = {
        'plex1:ep100': _episodeMeta(id: '100', serverId: ServerId('plex1'), grandparentId: '42', parentId: null),
      };
      expect(resolveDownloadContainerGlobalKey(season, metadata), isNull);
    });

    test('walks nested season for first leaf when show has multiple seasons', () {
      final ep1 = _episodeNode('plex1:ep100');
      final ep2 = _episodeNode('plex1:ep200');
      final s1 = _seasonNode(key: 'show42:season1', children: [ep1]);
      final s2 = _seasonNode(key: 'show42:season2', children: [ep2]);
      final show = _showNode(key: 'show42', children: [s1, s2]);
      final metadata = {
        'plex1:ep100': _episodeMeta(id: '100', serverId: ServerId('plex1'), grandparentId: '42', parentId: '1'),
        'plex1:ep200': _episodeMeta(id: '200', serverId: ServerId('plex1'), grandparentId: '42', parentId: '2'),
      };

      expect(resolveDownloadContainerGlobalKey(show, metadata), 'plex1:42');
    });
  });

  group('download progress presentation', () {
    testWidgets('running transfer without a content length is indeterminate, not queued', (tester) async {
      final movie = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'plex-1',
      );
      const progress = DownloadProgress(
        globalKey: 'plex-1:movie-1',
        status: DownloadStatus.downloading,
        currentFile: 'video',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: DownloadTreeView(
                downloads: const {'plex-1:movie-1': progress},
                metadata: {'plex-1:movie-1': movie},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(t.downloads.downloadQueued), findsNothing);
      expect(find.text(t.downloads.downloadingTooltip), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
    });

    testWidgets('prepared transfer still appears queued until it starts', (tester) async {
      final movie = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'plex-1',
      );
      const progress = DownloadProgress(globalKey: 'plex-1:movie-1', status: DownloadStatus.downloading);

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: DownloadTreeView(
                downloads: const {'plex-1:movie-1': progress},
                metadata: {'plex-1:movie-1': movie},
              ),
            ),
          ),
        ),
      );

      expect(find.text(t.downloads.downloadQueued), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('collapsed parents inherit an active indeterminate transfer', (tester) async {
      final episode = _episodeMeta(
        id: 'episode-1',
        serverId: ServerId('plex-1'),
        grandparentId: 'show-1',
        parentId: 'season-1',
      );
      const progress = DownloadProgress(
        globalKey: 'plex-1:episode-1',
        status: DownloadStatus.downloading,
        currentFile: 'video',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: DownloadTreeView(
                downloads: const {'plex-1:episode-1': progress},
                metadata: {'plex-1:episode-1': episode},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(t.downloads.downloadQueued), findsNothing);
      expect(find.text(t.downloads.downloadingTooltip), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
    });

    testWidgets('parents stay queued when completed siblings leave only prepared transfers', (tester) async {
      final completed = _episodeMeta(
        id: 'episode-1',
        serverId: ServerId('plex-1'),
        grandparentId: 'show-1',
        parentId: 'season-1',
      );
      final prepared = _episodeMeta(
        id: 'episode-2',
        serverId: ServerId('plex-1'),
        grandparentId: 'show-1',
        parentId: 'season-1',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: DownloadTreeView(
                downloads: const {
                  'plex-1:episode-1': DownloadProgress(
                    globalKey: 'plex-1:episode-1',
                    status: DownloadStatus.completed,
                    progress: 100,
                  ),
                  'plex-1:episode-2': DownloadProgress(
                    globalKey: 'plex-1:episode-2',
                    status: DownloadStatus.downloading,
                  ),
                },
                metadata: {'plex-1:episode-1': completed, 'plex-1:episode-2': prepared},
              ),
            ),
          ),
        ),
      );

      // The collapsed show is queued even though its aggregate progress is
      // non-zero from the completed sibling.
      expect(find.text(t.downloads.downloadQueued), findsOneWidget);
      expect(find.text(t.downloads.downloadingTooltip), findsNothing);

      await tester.tap(find.text('Unknown Show'));
      await tester.pump();

      // The revealed season is queued for the same reason.
      expect(find.text(t.downloads.downloadQueued), findsNWidgets(2));
      expect(find.text(t.downloads.downloadingTooltip), findsNothing);
    });
  });
}
