import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/backend_badge.dart';
import 'package:plezy/widgets/media_card.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

/// A summary long enough to saturate the list row's summary maxLines at any
/// density, so the episode line trade below is observable as geometry.
const _longSummary =
    'A deliberately long synopsis that wraps across every available summary '
    'line of the list row at any density setting, so that trading one of '
    'those lines for the source line is measurable as row geometry instead '
    'of disappearing into slack space below a short text block.';

MediaItem _episode({String? libraryTitle}) => testMediaItem(
  id: 'ep-1',
  kind: MediaKind.episode,
  title: 'The Power',
  grandparentTitle: 'Regular Show',
  parentId: 'season-1',
  parentIndex: 1,
  index: 1,
  summary: _longSummary,
  serverId: 'server_1',
  serverName: 'Server',
  libraryId: '2',
  libraryTitle: libraryTitle,
);

MediaItem _movie({String? libraryTitle}) => testMediaItem(
  id: 'movie-1',
  kind: MediaKind.movie,
  title: 'Movie',
  summary: _longSummary,
  serverId: 'server_1',
  serverName: 'Server',
  libraryId: '1',
  libraryTitle: libraryTitle,
);

Future<void> _pumpListCard(WidgetTester tester, MediaItem item, {String? libraryName, bool showServerName = false}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: MediaCard(item: item, forceListMode: true, showServerName: showServerName, libraryName: libraryName),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('source line shows backend icon, server name, and library name together', (tester) async {
    await _pumpListCard(tester, _episode(libraryTitle: 'Shows'), libraryName: 'Shows', showServerName: true);

    expect(find.byType(BackendBadge), findsOneWidget);
    expect(find.text('Server • Shows'), findsOneWidget);
  });

  testWidgets('a library label alone still reveals the icon and server name', (tester) async {
    // Single-server surfaces pass showServerName: false, but a row that names
    // its library must still show whose library it is (#1970).
    await _pumpListCard(tester, _movie(libraryTitle: 'Movies'), libraryName: 'Movies');

    expect(find.byType(BackendBadge), findsOneWidget);
    expect(find.text('Server • Movies'), findsOneWidget);
  });

  testWidgets('no source line without a server request or library label', (tester) async {
    await _pumpListCard(tester, _movie());

    expect(find.byType(BackendBadge), findsNothing);
    expect(find.textContaining('Server'), findsNothing);
  });

  testWidgets('an episode row trades a summary line for the source line instead of growing', (tester) async {
    // The wide episode thumb makes the shortest list row. The source line
    // matches the summary line height it replaces (both _metadataFontSize at
    // height 1.3), so labeling an episode must not change the row height —
    // without the trade the row grows by a full text line (#1970).
    await _pumpListCard(tester, _episode());
    final bare = tester.getSize(find.byType(MediaCard)).height;

    await _pumpListCard(tester, _episode(libraryTitle: 'Shows'), libraryName: 'Shows');
    final labeled = tester.getSize(find.byType(MediaCard)).height;

    expect(labeled, bare);
  });

  testWidgets('a poster row keeps its full summary and absorbs the source line', (tester) async {
    // The 2:3 poster is taller than the text column, so the label costs a
    // poster row no height and no summary line.
    await _pumpListCard(tester, _movie());
    final bare = tester.getSize(find.byType(MediaCard)).height;

    await _pumpListCard(tester, _movie(libraryTitle: 'Movies'), libraryName: 'Movies');
    final labeled = tester.getSize(find.byType(MediaCard)).height;

    expect(labeled, bare);
  });
}
