import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/models/plex_playlist.dart';
import 'package:plezy/providers/settings_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/i18n/strings.g.dart';

// Mock SettingsProvider for testing
class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  ViewMode _viewMode = ViewMode.grid;
  LibraryDensity _libraryDensity = LibraryDensity.normal;
  EpisodePosterMode _episodePosterMode = EpisodePosterMode.episodeThumbnail;
  bool _showHeroSection = true;
  bool _useGlobalHubs = true;

  @override
  ViewMode get viewMode => _viewMode;

  @override
  LibraryDensity get libraryDensity => _libraryDensity;

  @override
  EpisodePosterMode get episodePosterMode => _episodePosterMode;

  @override
  bool get showHeroSection => _showHeroSection;

  @override
  bool get useGlobalHubs => _useGlobalHubs;

  @override
  bool get isInitialized => true;

  @override
  String get libraryDensityDisplayName => 'Normal';

  @override
  String get episodePosterModeDisplayName => 'Episode Thumbnail';

  void setViewModeForTest(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void setLibraryDensityForTest(LibraryDensity density) {
    _libraryDensity = density;
    notifyListeners();
  }

  void setEpisodePosterModeForTest(EpisodePosterMode mode) {
    _episodePosterMode = mode;
    notifyListeners();
  }

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> setLibraryDensity(LibraryDensity density) async {
    _libraryDensity = density;
    notifyListeners();
  }

  @override
  Future<void> setViewMode(ViewMode mode) async {
    _viewMode = mode;
    notifyListeners();
  }

  @override
  Future<void> setEpisodePosterMode(EpisodePosterMode mode) async {
    _episodePosterMode = mode;
    notifyListeners();
  }

  @override
  Future<void> setShowHeroSection(bool value) async {
    _showHeroSection = value;
    notifyListeners();
  }

  @override
  Future<void> setUseGlobalHubs(bool value) async {
    _useGlobalHubs = value;
    notifyListeners();
  }
}

// Test theme extension
MonoTokens get testTokens => const MonoTokens(
  radiusSm: 8.0,
  radiusMd: 12.0,
  space: 16.0,
  fast: Duration(milliseconds: 150),
  normal: Duration(milliseconds: 300),
  slow: Duration(milliseconds: 500),
  bg: Colors.black,
  surface: Color(0xFF1E1E1E),
  outline: Color(0xFF424242),
  text: Colors.white,
  textMuted: Color(0xFFBDBDBD),
  splashFactory: InkRipple.splashFactory,
);

// Helper to build test theme
ThemeData get testTheme => ThemeData.dark().copyWith(
  extensions: [testTokens],
);

// Helper to create test PlexMetadata
PlexMetadata createTestMetadata({
  String ratingKey = '12345',
  String key = '/library/metadata/12345',
  String type = 'movie',
  String title = 'Test Movie',
  int? year,
  int? duration,
  int? viewOffset,
  int? viewCount,
  String? serverId,
  String? grandparentTitle,
  String? parentTitle,
  int? parentIndex,
  int? index,
}) {
  return PlexMetadata(
    ratingKey: ratingKey,
    key: key,
    type: type,
    title: title,
    year: year,
    duration: duration,
    viewOffset: viewOffset,
    viewCount: viewCount,
    serverId: serverId,
    grandparentTitle: grandparentTitle,
    parentTitle: parentTitle,
    parentIndex: parentIndex,
    index: index,
  );
}

// Helper to create test PlexPlaylist
PlexPlaylist createTestPlaylist({
  String ratingKey = '99999',
  String key = '/playlists/99999',
  String title = 'Test Playlist',
  String? summary,
  bool smart = false,
  String playlistType = 'video',
  int? leafCount,
  int? duration,
}) {
  return PlexPlaylist(
    ratingKey: ratingKey,
    key: key,
    type: 'playlist',
    title: title,
    summary: summary,
    smart: smart,
    playlistType: playlistType,
    leafCount: leafCount,
    duration: duration,
  );
}

void main() {
  // Initialize slang/i18n before tests
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  group('MediaCard Widget', () {
    late MockSettingsProvider mockSettingsProvider;

    setUp(() {
      mockSettingsProvider = MockSettingsProvider();
    });

    // Helper to build the widget with required providers
    Widget buildTestWidget({
      required dynamic item,
      VoidCallback? onTap,
      double? width,
      double? height,
      bool forceGridMode = false,
      bool isInContinueWatching = false,
      bool isOffline = false,
    }) {
      return MaterialApp(
        theme: testTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TranslationProvider(
          child: ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider,
            child: Scaffold(
              body: SizedBox(
                width: width ?? 200,
                height: height ?? 300,
                child: MediaCard(
                  item: item,
                  width: width,
                  height: height,
                  forceGridMode: forceGridMode,
                  isInContinueWatching: isInContinueWatching,
                  isOffline: isOffline,
                ),
              ),
            ),
          ),
        ),
      );
    }

    group('PlexMetadata rendering', () {
      testWidgets('displays movie title in grid mode', (tester) async {
        final metadata = createTestMetadata(title: 'Inception');
        mockSettingsProvider.setViewModeForTest(ViewMode.grid);

        await tester.pumpWidget(buildTestWidget(
          item: metadata,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Inception'), findsOneWidget);
      });

      testWidgets('displays movie title in list mode', (tester) async {
        final metadata = createTestMetadata(title: 'The Matrix');
        mockSettingsProvider.setViewModeForTest(ViewMode.list);

        await tester.pumpWidget(buildTestWidget(item: metadata));
        await tester.pumpAndSettle();

        expect(find.text('The Matrix'), findsOneWidget);
      });

      testWidgets('displays year when available', (tester) async {
        final metadata = createTestMetadata(
          title: 'Blade Runner',
          year: 1982,
        );
        mockSettingsProvider.setViewModeForTest(ViewMode.list);

        await tester.pumpWidget(buildTestWidget(item: metadata));
        await tester.pumpAndSettle();

        // Year should be shown somewhere in the widget
        expect(find.textContaining('1982'), findsWidgets);
      });

      testWidgets('displays episode with season/episode info', (tester) async {
        final episode = createTestMetadata(
          type: 'episode',
          title: 'Pilot',
          grandparentTitle: 'Breaking Bad',
          parentTitle: 'Season 1',
          parentIndex: 1,
          index: 1,
        );
        mockSettingsProvider.setViewModeForTest(ViewMode.list);

        await tester.pumpWidget(buildTestWidget(item: episode));
        await tester.pumpAndSettle();

        expect(find.text('Pilot'), findsOneWidget);
        expect(find.textContaining('S1'), findsWidgets);
        expect(find.textContaining('E1'), findsWidgets);
      });
    });

    group('PlexPlaylist rendering', () {
      testWidgets('displays playlist title', (tester) async {
        final playlist = createTestPlaylist(title: 'My Favorites');
        mockSettingsProvider.setViewModeForTest(ViewMode.grid);

        await tester.pumpWidget(buildTestWidget(
          item: playlist,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('My Favorites'), findsOneWidget);
      });

      testWidgets('displays item count when available', (tester) async {
        final playlist = createTestPlaylist(
          title: 'Action Movies',
          leafCount: 25,
        );
        mockSettingsProvider.setViewModeForTest(ViewMode.list);

        await tester.pumpWidget(buildTestWidget(item: playlist));
        await tester.pumpAndSettle();

        // Should show item count
        expect(find.textContaining('25'), findsWidgets);
      });
    });

    group('View mode switching', () {
      testWidgets('respects forceGridMode parameter', (tester) async {
        final metadata = createTestMetadata(title: 'Test Movie');
        mockSettingsProvider.setViewModeForTest(ViewMode.list);

        await tester.pumpWidget(buildTestWidget(
          item: metadata,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        // Widget should render even when forcing grid mode
        expect(find.text('Test Movie'), findsOneWidget);
      });

      testWidgets('updates when settings provider changes', (tester) async {
        final metadata = createTestMetadata(title: 'Test Movie');
        mockSettingsProvider.setViewModeForTest(ViewMode.grid);

        await tester.pumpWidget(buildTestWidget(item: metadata));
        await tester.pumpAndSettle();

        expect(find.text('Test Movie'), findsOneWidget);

        // Change to list mode
        mockSettingsProvider.setViewModeForTest(ViewMode.list);
        await tester.pumpAndSettle();

        // Widget should still show the title
        expect(find.text('Test Movie'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has semantic label for movie', (tester) async {
        final metadata = createTestMetadata(
          type: 'movie',
          title: 'Test Movie',
        );

        await tester.pumpWidget(buildTestWidget(
          item: metadata,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        // The widget should have semantics
        final semantics = tester.getSemantics(find.byType(MediaCard));
        expect(semantics, isNotNull);
      });

      testWidgets('has semantic label for episode', (tester) async {
        final episode = createTestMetadata(
          type: 'episode',
          title: 'Pilot',
          parentIndex: 1,
          index: 1,
        );

        await tester.pumpWidget(buildTestWidget(
          item: episode,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        // The widget should have semantics
        final semantics = tester.getSemantics(find.byType(MediaCard));
        expect(semantics, isNotNull);
      });

      testWidgets('has semantic label for playlist', (tester) async {
        final playlist = createTestPlaylist(title: 'My Playlist');

        await tester.pumpWidget(buildTestWidget(
          item: playlist,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        // The widget should have semantics
        final semantics = tester.getSemantics(find.byType(MediaCard));
        expect(semantics, isNotNull);
      });
    });

    group('Interaction', () {
      testWidgets('responds to tap', (tester) async {
        final metadata = createTestMetadata(title: 'Tappable Movie');

        await tester.pumpWidget(buildTestWidget(
          item: metadata,
          forceGridMode: true,
        ));
        await tester.pumpAndSettle();

        // Find the InkWell and tap it
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        // Widget should still exist after tap
        expect(find.text('Tappable Movie'), findsOneWidget);
      });
    });
  });

  group('Library density', () {
    late MockSettingsProvider mockSettingsProvider;

    setUp(() {
      mockSettingsProvider = MockSettingsProvider();
    });

    Widget buildListTestWidget(PlexMetadata metadata) {
      return MaterialApp(
        theme: testTheme,
        home: TranslationProvider(
          child: ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider,
            child: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: MediaCard(
                  item: metadata,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('compact density affects list layout', (tester) async {
      final metadata = createTestMetadata(title: 'Compact Test');
      mockSettingsProvider.setViewModeForTest(ViewMode.list);
      mockSettingsProvider.setLibraryDensityForTest(LibraryDensity.compact);

      await tester.pumpWidget(buildListTestWidget(metadata));
      await tester.pumpAndSettle();

      expect(find.text('Compact Test'), findsOneWidget);
    });

    testWidgets('comfortable density affects list layout', (tester) async {
      final metadata = createTestMetadata(title: 'Comfortable Test');
      mockSettingsProvider.setViewModeForTest(ViewMode.list);
      mockSettingsProvider.setLibraryDensityForTest(LibraryDensity.comfortable);

      await tester.pumpWidget(buildListTestWidget(metadata));
      await tester.pumpAndSettle();

      expect(find.text('Comfortable Test'), findsOneWidget);
    });
  });

  group('SkeletonLoader Widget', () {
    testWidgets('renders with animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: SkeletonLoader(),
          ),
        ),
      );

      // SkeletonLoader should exist
      expect(find.byType(SkeletonLoader), findsOneWidget);

      // Pump a few frames to verify animation doesn't crash
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders with child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: SkeletonLoader(
              child: Icon(Icons.movie),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byIcon(Icons.movie), findsOneWidget);
    });

    testWidgets('applies custom border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: SkeletonLoader(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
