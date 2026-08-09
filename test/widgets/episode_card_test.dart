import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_stream.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/collapsible_text.dart';
import 'package:plezy/widgets/episode_card.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/download_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(false);
    LocaleSettings.setLocaleSync(AppLocale.en);
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('overflowing summary stays in card semantics without an Expand label', (tester) async {
    final semantics = tester.ensureSemantics();
    const summary =
        'The expedition follows a careful team through an unfamiliar landscape while each discovery changes their plans.';
    final episode = testMediaItem(
      id: 'semantic_episode',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'A Difficult Crossing',
      index: 3,
      summary: summary,
      durationMs: 42 * 60 * 1000,
    );

    await _pumpEpisodeCard(tester, episode);

    final summaryText = tester.widget<Text>(
      find.descendant(of: find.byType(CollapsibleText), matching: find.byType(Text)).first,
    );
    expect(summaryText.textSpan, isNotNull);
    expect(summaryText.textSpan!.toPlainText(), isNot(summary));

    final semanticNodes = <SemanticsNode>[];
    void collectSemantics(SemanticsNode node) {
      semanticNodes.add(node);
      node.visitChildren((child) {
        collectSemantics(child);
        return true;
      });
    }

    collectSemantics(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
    final cardSemantics = semanticNodes.singleWhere((node) => node.label.contains('A Difficult Crossing'));
    expect(cardSemantics.label, contains('The expedition follows a careful team'));
    expect(cardSemantics.label, isNot(contains('Expand')));
    expect(cardSemantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('shows file size alongside media quality labels', (tester) async {
    final episode = testMediaItem(
      id: 'sized_episode',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'A Large Episode',
      index: 4,
      durationMs: 52 * 60 * 1000,
      mediaVersions: const [
        MediaVersion(
          id: 'source',
          videoResolution: '1080',
          parts: [
            MediaPart(
              id: 'part-1',
              sizeBytes: 1536 * 1024 * 1024,
              streams: [
                MediaStream(id: 'audio', kind: MediaStreamKind.audio, codec: 'eac3', channels: 6, selected: true),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpEpisodeCard(tester, episode);

    final metadataWrap = find.ancestor(of: find.text('1.50 GB'), matching: find.byType(Wrap));
    expect(metadataWrap, findsOneWidget);
    expect(find.descendant(of: metadataWrap, matching: find.text('EAC3 5.1')), findsOneWidget);
  });

  testWidgets('shows a completed Plex transcode quality and local size instead of its source metadata', (tester) async {
    final directory = Directory.systemTemp.createTempSync('plezy_episode_card_');
    final video = File('${directory.path}/episode.mkv');
    video.writeAsBytesSync(List<int>.filled(4096, 0));
    final previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(directory);
    addTearDown(() {
      PathProviderPlatform.instance = previousPathProvider;
      directory.deleteSync(recursive: true);
    });

    final episode = testMediaItem(
      id: 'transcoded_episode',
      serverId: 'srv',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'A Smaller Episode',
      index: 5,
      durationMs: 22 * 60 * 1000,
      mediaVersions: const [
        MediaVersion(
          id: 'source',
          videoResolution: '1080',
          parts: [
            MediaPart(
              id: 'part-1',
              sizeBytes: 1536 * 1024 * 1024,
              streams: [
                MediaStream(id: 'audio', kind: MediaStreamKind.audio, codec: 'eac3', channels: 6, selected: true),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpEpisodeCard(
      tester,
      episode,
      seedDatabase: (db) async {
        await db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: episode.id,
          globalKey: episode.globalKey,
          type: 'episode',
          status: DownloadStatus.completed.index,
          downloadQualityPreset: TranscodeQualityPreset.p240_320.storageKey,
        );
        await db.updateVideoFilePath(episode.globalKey, video.path);
      },
      seedProvider: (provider) => provider.debugSeedState(
        downloads: {
          episode.globalKey: DownloadProgress(globalKey: episode.globalKey, status: DownloadStatus.completed),
        },
        ownedDownloadKeys: {episode.globalKey},
      ),
    );
    for (var attempt = 0; attempt < 20 && find.text('240p').evaluate().isEmpty; attempt++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('240p'), findsOneWidget);
    expect(find.text('AAC'), findsOneWidget);
    expect(find.text('4.00 KB'), findsOneWidget);
    expect(find.text('1080p'), findsNothing);
    expect(find.text('EAC3 5.1'), findsNothing);
    expect(find.text('1.50 GB'), findsNothing);
  });
}

Future<void> _pumpEpisodeCard(
  WidgetTester tester,
  MediaItem episode, {
  Future<void> Function(AppDatabase database)? seedDatabase,
  void Function(DownloadProvider provider)? seedProvider,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);
  final downloadManager = DownloadManagerService(
    database: db,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
  await downloadProvider.ensureInitialized();
  await seedDatabase?.call(db);
  seedProvider?.call(downloadProvider);
  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<DownloadProvider>.value(
        value: downloadProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: EpisodeCard(episode: episode, isOffline: true, onTap: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
