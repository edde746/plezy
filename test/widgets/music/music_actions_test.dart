import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/music/music_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  /// Phone width, where Radio is an icon with a tooltip rather than a label.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('Radio carries its name beside Play where there is room', (tester) async {
    await tester.pumpWidget(
      _wrap((context) => buildMusicActions(context: context, onPlay: () {}, onShuffle: () {}, onInstantMix: () {})),
    );

    expect(find.text(t.music.instantMix), findsOneWidget);
  });

  testWidgets('Radio renders a distinct icon and runs its callback when the server supports it', (tester) async {
    phone(tester);
    var mixes = 0;

    await tester.pumpWidget(
      _wrap(
        (context) => buildMusicActions(context: context, onPlay: () {}, onShuffle: () {}, onInstantMix: () => mixes++),
      ),
    );

    final instantMix = find.byIcon(Symbols.radio_rounded);
    expect(instantMix, findsOneWidget);
    expect(
      find.ancestor(of: instantMix, matching: find.byTooltip(t.music.instantMix)),
      findsOneWidget,
      reason: 'the icon is the only affordance on a phone, so it must carry the Radio tooltip',
    );

    // #1629: the fader glyph reads as an equalizer in a music context, and is
    // the vertical twin of the video player's settings icon.
    expect(find.byIcon(Symbols.instant_mix_rounded), findsNothing);
    expect(find.byIcon(Symbols.tune_rounded), findsNothing);
    // It must also stay distinguishable from the shuffle button beside it.
    expect(find.byIcon(Symbols.shuffle_rounded), findsOneWidget);

    await tester.tap(instantMix);
    await tester.pump();

    expect(mixes, 1);
  });

  testWidgets('Radio is absent when the server lacks the capability', (tester) async {
    await tester.pumpWidget(_wrap((context) => buildMusicActions(context: context, onPlay: () {}, onShuffle: () {})));

    expect(find.byIcon(Symbols.radio_rounded), findsNothing);
    expect(find.byTooltip(t.music.instantMix), findsNothing);
    expect(find.byIcon(Symbols.shuffle_rounded), findsOneWidget);
    expect(find.text(t.common.play), findsOneWidget);
  });
}

Widget _wrap(List<FocusableAction> Function(BuildContext context) actions) {
  return TranslationProvider(
    child: MaterialApp(
      theme: monoTheme(MonoPalette.dark),
      home: Scaffold(
        body: Center(
          child: Builder(builder: (context) => FocusableActionBar(actions: actions(context))),
        ),
      ),
    ),
  );
}
