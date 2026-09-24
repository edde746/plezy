import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/settings_utils.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/setting_tile.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  Widget buildTile() => InputModeTracker(
    child: MaterialApp(
      home: Scaffold(
        body: SettingChecklistTile(
          uncheckedPref: SettingsService.refusedVideoCodecs,
          icon: Symbols.video_settings_rounded,
          title: t.settings.videoCodecs,
          description: t.settings.videoCodecsDescription,
          options: [
            const DialogOption(value: 'av1', title: 'AV1'),
            const DialogOption(value: 'hevc', title: 'HEVC'),
            DialogOption(value: 'h264', title: 'H.264', subtitle: t.settings.videoCodecsAlwaysAccepted),
          ],
          locked: const {'h264'},
        ),
      ),
    ),
  );

  List<String> stored() => SettingsService.instance.read(SettingsService.refusedVideoCodecs);

  bool isChecked(WidgetTester tester, String label) => tester
      .widget<CheckboxListTile>(find.ancestor(of: find.text(label), matching: find.byType(CheckboxListTile)))
      .value!;

  // The pref holds the *unchecked* values; an inverted write would refuse
  // exactly the codecs the user kept.
  testWidgets('saving stores the unchecked options; cancelling stores nothing', (tester) async {
    await tester.pumpWidget(buildTile());
    expect(find.textContaining('AV1, HEVC, H.264 · '), findsOneWidget);

    await tester.tap(find.text(t.settings.videoCodecs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HEVC'));
    await tester.tap(find.text('H.264'));
    await tester.pump();
    expect(isChecked(tester, 'HEVC'), isFalse);
    expect(isChecked(tester, 'H.264'), isTrue, reason: 'the locked option cannot be unchecked');

    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(stored(), ['hevc']);
    expect(find.textContaining('AV1, H.264 · '), findsOneWidget);

    await tester.tap(find.text(t.settings.videoCodecs));
    await tester.pumpAndSettle();
    expect(isChecked(tester, 'HEVC'), isFalse, reason: 'the dialog reopens with the stored state');
    await tester.tap(find.text('AV1'));
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(stored(), ['hevc']);
  });

  testWidgets('D-pad focuses the first editable option and toggles it with select', (tester) async {
    await tester.pumpWidget(buildTile());
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    await tester.tap(find.text(t.settings.videoCodecs));
    await tester.pumpAndSettle();

    final av1Focus = Focus.of(tester.element(find.text('AV1')));
    expect(av1Focus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(isChecked(tester, 'AV1'), isFalse);

    // Down moves to HEVC and skips the locked H.264 row on the way to Save.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('HEVC'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('H.264'))).hasFocus, isFalse);

    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(stored(), ['av1']);
  });
}
