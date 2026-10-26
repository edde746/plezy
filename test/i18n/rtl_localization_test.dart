import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_slider.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/i18n/app_locale_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/libraries/library_alpha_bar_strategy.dart';

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('Arabic supplies RTL direction and mirrors reading-order focus callbacks', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    final node = FocusNode();
    addTearDown(node.dispose);
    final events = <String>[];
    await tester.pumpWidget(MaterialApp(
      locale: AppLocale.ar.localizationsLocale,
      supportedLocales: supportedLocalizationsLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: FocusableWrapper(
        focusNode: node,
        onNavigateLeft: () => events.add('previous'),
        onNavigateRight: () => events.add('next'),
        child: Text(t.common.settings),
      )),
    ));
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.text(t.common.settings))), TextDirection.rtl);
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(events, ['previous', 'next']);
    expect(tester.takeException(), isNull);
  });


  testWidgets('RTL sliders increase in the same direction as their visual track', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    double? changed;
    await tester.pumpWidget(MaterialApp(home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: FocusableSlider(focusNode: node, value: 0.5, divisions: 10,
        onChanged: (value) => changed = value)),
    )));
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(changed, closeTo(0.6, 0.0001));
  });

  test('Arabic cardinal forms cover zero, one, two, few, many and other', () async {
    final ar = await AppLocale.ar.build();
    expect(ar.explore.episodeCount(n: 1), 'حلقة واحدة');
    expect(ar.explore.episodeCount(n: 2), 'حلقتان');
    expect(ar.explore.episodeCount(n: 3), '3 حلقات');
    expect(ar.explore.episodeCount(n: 11), '11 حلقة');
    expect(ar.explore.episodeCount(n: 100), '100 حلقة');
    expect(ar.explore.episodeCount(n: 0), isNotEmpty);
  });

  test('prefix navigation uses Arabic letters and leaves CJK titles to Unicode search', () async {
    const strategy = MediaBrowserAlphaBarStrategy();
    await LocaleSettings.setLocale(AppLocale.ar);
    final arabic = await strategy.loadCharacters(filters: {}, typeId: null, descending: false);
    expect(arabic.helper.letters, contains('ع'));
    expect(arabic.helper.letters, isNot(contains('A')));
    await LocaleSettings.setLocale(AppLocale.ja);
    final japanese = await strategy.loadCharacters(filters: {}, typeId: null, descending: false);
    expect(japanese.chars, isEmpty);
    expect(strategy.shouldShow(totalItemCount: 1000, loadedCharacterCount: 0,
      sortKey: 'titleSort', isFolderGrouping: false, mediaBrowserAlphaPrefix: null, isPhone: false), isFalse);
  });
}
