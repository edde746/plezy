import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/widgets/download_tree_view.dart';
import '../test_helpers/media_items.dart';

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

  group('determineDownloadAggregateStatus', () {
    test('all-cancelled children aggregate to cancelled, not completed', () {
      expect(determineDownloadAggregateStatus([DownloadStatus.cancelled]), DownloadStatus.cancelled);
      expect(
        determineDownloadAggregateStatus([DownloadStatus.cancelled, DownloadStatus.cancelled]),
        DownloadStatus.cancelled,
      );
    });

    test('completed mixed with cancelled aggregates to partial', () {
      expect(
        determineDownloadAggregateStatus([DownloadStatus.completed, DownloadStatus.cancelled]),
        DownloadStatus.partial,
      );
    });

    test('a partial child keeps the container partial', () {
      expect(determineDownloadAggregateStatus([DownloadStatus.partial]), DownloadStatus.partial);
      expect(
        determineDownloadAggregateStatus([DownloadStatus.completed, DownloadStatus.partial]),
        DownloadStatus.partial,
      );
    });

    test('active, paused, and failed precedence is unchanged', () {
      expect(
        determineDownloadAggregateStatus([
          DownloadStatus.completed,
          DownloadStatus.downloading,
          DownloadStatus.cancelled,
        ]),
        DownloadStatus.downloading,
      );
      expect(
        determineDownloadAggregateStatus([DownloadStatus.cancelled, DownloadStatus.queued]),
        DownloadStatus.queued,
      );
      expect(
        determineDownloadAggregateStatus([DownloadStatus.completed, DownloadStatus.paused]),
        DownloadStatus.paused,
      );
      expect(
        determineDownloadAggregateStatus([DownloadStatus.failed, DownloadStatus.completed]),
        DownloadStatus.failed,
      );
      expect(determineDownloadAggregateStatus([DownloadStatus.completed]), DownloadStatus.completed);
      expect(determineDownloadAggregateStatus(const []), DownloadStatus.queued);
    });
  });

  group('container Retry all', () {
    // Inserted out of order so the tree's own season/episode order shows.
    final episodes = {
      'srv:s2e1': _seasonEpisode(id: 's2e1', season: 2, episode: 1),
      'srv:s1e2': _seasonEpisode(id: 's1e2', season: 1, episode: 2),
      'srv:s1e1': _seasonEpisode(id: 's1e1', season: 1, episode: 1),
    };

    Map<String, DownloadProgress> statuses(Map<String, DownloadStatus> byKey) => {
      for (final entry in byKey.entries) entry.key: DownloadProgress(globalKey: entry.key, status: entry.value),
    };

    Future<ValueNotifier<Map<String, DownloadProgress>>> pumpTree(
      WidgetTester tester,
      Map<String, DownloadStatus> initial, {
      void Function(List<String> globalKeys)? onRetryAll,
    }) async {
      final downloads = ValueNotifier(statuses(initial));
      addTearDown(downloads.dispose);
      await tester.pumpWidget(
        InputModeTracker(
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<Map<String, DownloadProgress>>(
                valueListenable: downloads,
                builder: (context, value, _) => DownloadTreeView(
                  downloads: value,
                  metadata: episodes,
                  onPause: (_) {},
                  onRetry: (_) {},
                  onRetryAll: onRetryAll,
                  onDelete: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return downloads;
    }

    testWidgets('retries a show\'s failed episodes in episode order while another still downloads', (tester) async {
      final retried = <List<String>>[];
      await pumpTree(tester, {
        'srv:s2e1': DownloadStatus.failed,
        'srv:s1e2': DownloadStatus.failed,
        'srv:s1e1': DownloadStatus.downloading,
      }, onRetryAll: retried.add);

      await tester.tap(find.byTooltip('Retry all'));
      await tester.pump();

      expect(retried, [
        ['srv:s1e2', 'srv:s2e1'],
      ]);
    });

    testWidgets('is offered only while an episode has failed', (tester) async {
      final downloads = await pumpTree(tester, {
        'srv:s2e1': DownloadStatus.completed,
        'srv:s1e2': DownloadStatus.queued,
        'srv:s1e1': DownloadStatus.downloading,
      }, onRetryAll: (_) {});
      expect(find.byTooltip('Retry all'), findsNothing);

      downloads.value = statuses({
        'srv:s2e1': DownloadStatus.failed,
        'srv:s1e2': DownloadStatus.completed,
        'srv:s1e1': DownloadStatus.completed,
      });
      await tester.pumpAndSettle();
      expect(find.byTooltip('Retry all'), findsOneWidget);
    });
  });
}

MediaItem _seasonEpisode({required String id, required int season, required int episode}) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $id',
  serverId: ServerId('srv'),
  grandparentId: 'show',
  grandparentTitle: 'Show',
  parentId: 'season-$season',
  parentTitle: 'Season $season',
  parentIndex: season,
  index: episode,
);
