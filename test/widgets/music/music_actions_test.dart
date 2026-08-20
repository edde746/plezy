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

  testWidgets('Instant Mix renders a distinct icon and runs its callback when the server supports it', (tester) async {
    var mixes = 0;

    await tester.pumpWidget(_wrap(buildMusicActions(onPlay: () {}, onShuffle: () {}, onInstantMix: () => mixes++)));

    final instantMix = find.byIcon(Symbols.wand_stars_rounded);
    expect(instantMix, findsOneWidget);
    expect(
      find.ancestor(of: instantMix, matching: find.byTooltip(t.music.instantMix)),
      findsOneWidget,
      reason: 'the icon is the only affordance on TV, so it must carry the Instant Mix tooltip',
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

  testWidgets('Instant Mix is absent when the server lacks the capability', (tester) async {
    await tester.pumpWidget(_wrap(buildMusicActions(onPlay: () {}, onShuffle: () {})));

    expect(find.byIcon(Symbols.wand_stars_rounded), findsNothing);
    expect(find.byTooltip(t.music.instantMix), findsNothing);
    expect(find.byIcon(Symbols.shuffle_rounded), findsOneWidget);
    expect(find.text(t.common.play), findsOneWidget);
  });
}

Widget _wrap(List<FocusableAction> actions) {
  return TranslationProvider(
    child: MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(
        body: Center(child: FocusableActionBar(actions: actions)),
      ),
    ),
  );
}
