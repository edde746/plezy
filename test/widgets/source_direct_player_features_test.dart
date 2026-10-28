import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/presentation_formats.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/source_edition_menu_button.dart';
import 'package:plezy/widgets/source_file_info_sheet.dart';

import '../services/music/music_playback_service_test.dart' show FakePlayer;

class _PropertyPlayer extends FakePlayer {
  _PropertyPlayer({Map<String, String> properties = const {}}) : properties = Map.of(properties);

  final Map<String, String> properties;
  final writes = <(String, String)>[];
  Object? writeFailure;

  @override
  Future<String?> getProperty(String name) async => properties[name];

  @override
  Future<void> setProperty(String name, String value) async {
    writes.add((name, value));
    final failure = writeFailure;
    if (failure != null) throw failure;
    properties[name] = value;
  }
}

Widget _app(Widget child) => MaterialApp(
  theme: monoTheme(MonoPalette.dark),
  home: Scaffold(body: child),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('direct File Info shows useful metadata without exposing URL credentials or path', (tester) async {
    final player = _PropertyPlayer(
      properties: {
        'file-format': 'matroska,webm',
        'file-size': '734003200',
        'duration': '245.5',
        'video-params/w': '1920',
        'video-params/h': '1080',
        'video-params/aspect': '1.777777',
        'video-codec': 'h264',
        'video-profile': 'High',
        'container-fps': '23.976',
        'audio-codec-name': 'aac',
        'audio-params/samplerate': '48000',
        'audio-params/channels': '2',
        'audio-params/hr-channels': 'stereo',
      },
    );
    addTearDown(player.closeControllers);

    await tester.pumpWidget(
      _app(
        SourceFileInfoSheet(
          player: player,
          title: 'https://user:private-pass@media.example/private/Movie.mkv?token=secret-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(isolateDisplayText('Movie.mkv')), findsOneWidget);
    expect(find.textContaining('1920x1080'), findsWidgets);
    expect(find.textContaining('H264'), findsWidgets);
    expect(find.textContaining('private-pass'), findsNothing);
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.textContaining('/private/'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edition control stays hidden for one choice and refreshes when a new file loads', (tester) async {
    final player = _PropertyPlayer(properties: {'edition-list/count': '1', 'edition-list/0/title': 'Only edition'});
    addTearDown(player.closeControllers);
    await tester.pumpWidget(_app(SourceEditionMenuButton(player: player, sourceIdentity: 'item:0')));
    await tester.pumpAndSettle();
    expect(find.byTooltip(t.universalMedia.editionOrTitle), findsNothing);

    player.properties['edition-list/count'] = '2';
    player.properties['edition-list/0/title'] = 'Theatrical';
    player.properties['edition-list/1/title'] = 'Extended edition';
    player.properties['current-edition'] = '0';
    player.fileLoadedCtrl.add(null);
    await tester.pumpAndSettle();

    final button = find.byTooltip(t.universalMedia.editionOrTitle);
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text(isolateDisplayText('Theatrical')), findsOneWidget);
    expect(find.text(isolateDisplayText('Extended edition')), findsOneWidget);

    await tester.tap(find.text(isolateDisplayText('Extended edition')));
    await tester.pumpAndSettle();
    expect(player.writes, [('edition', '1')]);
    expect(tester.takeException(), isNull);
  });
}
