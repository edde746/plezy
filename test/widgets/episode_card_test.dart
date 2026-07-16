import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/collapsible_text.dart';
import 'package:plezy/widgets/episode_card.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

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
}
