import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/media_card.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Test movie');

  Widget app(Widget child) => MaterialApp(
    theme: monoTheme(dark: true),
    home: Scaffold(body: Center(child: child)),
  );

  /// Distance between the poster's bottom edge and the title's top edge.
  double posterTitleGap(WidgetTester tester) {
    final poster = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect));
    return tester.getTopLeft(find.text('Test movie')).dy - tester.getRect(poster.first).bottom;
  }

  testWidgets('grid cells grow the poster→title gap with the spacing setting', (tester) async {
    // Grid-style card: the cell (not the caller) bounds the height, so the
    // Expanded poster absorbs the gap delta.
    final card = SizedBox(width: 160, height: 264, child: MediaCard(item: movie, forceGridMode: true, isOffline: true));

    final gaps = <GridSpacing, double>{};
    for (final spacing in GridSpacing.values) {
      await SettingsService.instance.write(SettingsService.gridSpacing, spacing);
      await tester.pumpWidget(app(const SizedBox.shrink()));
      await tester.pumpWidget(app(card));
      gaps[spacing] = posterTitleGap(tester);
    }

    expect(gaps[GridSpacing.normal]! - gaps[GridSpacing.tight]!, 2);
    expect(gaps[GridSpacing.spacious]! - gaps[GridSpacing.tight]!, 4);
  });

  testWidgets('fixed-height hub-row cards keep the legacy gap across settings', (tester) async {
    // Hub-style explicit dimensions: cardWidth 200 -> posterWidth 194,
    // 2:3 poster height 291. The row's text band is fixed, so the gap must
    // not move with the setting.
    final card = MediaCard(item: movie, width: 200, height: 291, forceGridMode: true, isOffline: true);

    final gaps = <double>{};
    for (final spacing in GridSpacing.values) {
      await SettingsService.instance.write(SettingsService.gridSpacing, spacing);
      await tester.pumpWidget(app(const SizedBox.shrink()));
      await tester.pumpWidget(app(card));
      gaps.add(posterTitleGap(tester));
    }

    expect(gaps, hasLength(1));
  });
}
