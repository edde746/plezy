import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/navigation/main_screen_scope.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/state_messages.dart';
import 'package:plezy/screens/libraries/tabs/library_browse_tab.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_filter_chip.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/backend_client_fixtures.dart';
import '../../test_helpers/prefs.dart';

final _musicLibrary = MediaLibrary(
  id: 'music-library',
  backend: MediaBackend.jellyfin,
  title: 'Music',
  kind: MediaKind.artist,
  serverId: ServerId('music-server'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    await StorageService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('TV full-card preference keeps music browse captions visible', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await SettingsService.instance.write(SettingsService.tvFullCardLayout, true);
    final harness = _MusicBrowseHarness();
    addTearDown(harness.dispose);

    await _pumpBrowseTab(tester, harness);

    expect(harness.browseRequestCount, 1);
    final card = tester.widget<MediaCard>(find.byType(MediaCard).first);
    expect(card.fullBleedImage, isFalse);
    expect(find.text('Artist One'), findsOneWidget);
    expect(find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipOval)), findsOneWidget);
  });

  testWidgets('D-pad down focuses Retry and select reloads music browse', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final harness = _MusicBrowseHarness(failFirstBrowse: true);
    addTearDown(harness.dispose);

    await _pumpBrowseTab(tester, harness);

    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(harness.browseRequestCount, 1);

    final groupingChip = tester.widget<FocusableFilterChip>(find.byType(FocusableFilterChip).first);
    groupingChip.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final retryFinder = find.descendant(of: find.byType(ErrorStateWidget), matching: find.byType(FocusableButton));
    final retry = tester.widget<FocusableButton>(retryFinder);
    expect(retry.focusNode, isNotNull);
    expect(retry.focusNode!.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpRequestFrames(tester);

    expect(harness.browseRequestCount, 2);
    expect(find.byType(ErrorStateWidget), findsNothing);
    expect(find.text('Artist One'), findsOneWidget);
  });
}

Future<void> _pumpBrowseTab(WidgetTester tester, _MusicBrowseHarness harness) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider<MultiServerProvider>.value(
      value: harness.provider,
      child: InputModeTracker(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: MainScreenFocusScope(
            focusSidebar: () {},
            focusContent: () {},
            isSidebarFocused: false,
            sideNavigationWidth: 0,
            child: Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: const SliverToBoxAdapter(child: SizedBox(height: 1)),
                  ),
                ],
                body: LibraryBrowseTab(
                  library: _musicLibrary,
                  canGroupByFolders: true,
                  suppressAutoFocus: true,
                  onBack: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _pumpRequestFrames(tester);
}

Future<void> _pumpRequestFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

class _MusicBrowseHarness {
  final bool failFirstBrowse;
  var browseRequestCount = 0;
  late final JellyfinClient client;
  late final MultiServerManager manager;
  late final MultiServerProvider provider;

  _MusicBrowseHarness({this.failFirstBrowse = false}) {
    client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(machineId: 'music-server'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/Items/Filters') {
          return http.Response(
            jsonEncode({'Genres': const [], 'OfficialRatings': const [], 'Tags': const [], 'Years': const []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/Artists/AlbumArtists') {
          browseRequestCount++;
          if (failFirstBrowse && browseRequestCount == 1) {
            return http.Response('gateway timeout', 504);
          }
          return http.Response(
            jsonEncode({
              'Items': const [
                {'Id': 'artist-1', 'Name': 'Artist One', 'Type': 'MusicArtist'},
              ],
              'TotalRecordCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      }),
    );
    manager = MultiServerManager()..debugRegisterClientForTesting(client);
    provider = MultiServerProvider(manager, DataAggregationService(manager));
  }

  void dispose() {
    provider.dispose();
    manager.dispose();
  }
}
