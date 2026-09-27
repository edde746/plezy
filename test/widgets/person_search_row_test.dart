import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart' show CardShape;
import 'package:plezy/media/media_person.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/media_card_list_layout.dart';
import 'package:plezy/widgets/person_search_row.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('a photo still loading keeps the avatar slot inside an unbounded list', (tester) async {
    // Search rows sit in a SliverList, which leaves the row's height
    // unbounded. While the network photo loads, the loading placeholder
    // fills whatever box it is given; an unsized avatar slot handed it an
    // infinite one, and the failed layout blanked the whole search screen.
    await _pumpRow(tester);

    expect(tester.takeException(), isNull);
    final avatar = tester.getSize(find.byType(ClipOval));
    expect(avatar.width.isFinite, isTrue);
    expect(avatar.height, avatar.width);
  });

  testWidgets('a person row is shorter than a media row and lines its name up with titles', (tester) async {
    await _pumpRow(tester);

    final density = SettingsService.instance.read(SettingsService.libraryDensity);
    final squareMediaRowHeight = MediaCardListLayout.estimatedRowHeight(density: density, shape: CardShape.square);
    final mediaTitleStart = MediaCardListLayout.padding + MediaCardListLayout.basePosterWidth(density) + 12;
    expect(tester.getSize(find.byType(PersonSearchRow)).height, lessThan(squareMediaRowHeight));
    expect(tester.getTopLeft(find.text('Christoph Waltz')).dx, mediaTitleStart);
  });
}

Future<void> _pumpRow(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(
        body: ListView(
          children: [
            PersonSearchRow(
              person: MediaPerson(
                id: '38797',
                name: 'Christoph Waltz',
                thumbPath: 'https://example.invalid/christoph-waltz.jpg',
                credit: PersonCredit.actor,
                backend: MediaBackend.plex,
                serverId: ServerId('plex-1'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
