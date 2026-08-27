import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/utils/music_navigation.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/stub_music_playback_service.dart';

/// Instant Mix must never be a silent no-op (#2141): the tap-site seam
/// ([playInstantMix]) owns the snackbar for a failed or empty mix, because
/// the now-playing screen — the `errors`-stream listener — is not mounted at
/// tap time. Mid-playback errors keep flowing through that stream instead.
class _OutcomeMusicService extends StubMusicPlaybackService {
  _OutcomeMusicService({this.outcome, this.error});

  final InstantMixOutcome? outcome;
  final Object? error;

  @override
  Future<InstantMixOutcome> playInstantMix(MediaItem seed) async {
    if (error != null) throw error!;
    return outcome!;
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<BuildContext> pumpWithService(WidgetTester tester, MusicPlaybackService service) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      ChangeNotifierProvider<MusicPlaybackService>.value(
        value: service,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    return capturedContext;
  }

  final seed = testMediaItem(id: 'track-1', backend: MediaBackend.plex, kind: MediaKind.track);

  testWidgets('a thrown fetch failure surfaces the generic instant mix snackbar', (tester) async {
    final context = await pumpWithService(tester, _OutcomeMusicService(error: StateError('boom')));

    await playInstantMix(context, seed);
    await tester.pump();

    expect(find.text(t.music.instantMixFailed), findsOneWidget);
  });

  testWidgets('a PlaybackException surfaces its own localized message', (tester) async {
    final context = await pumpWithService(
      tester,
      _OutcomeMusicService(error: PlaybackException(t.music.instantMixNoServer)),
    );

    await playInstantMix(context, seed);
    await tester.pump();

    expect(find.text(t.music.instantMixNoServer), findsOneWidget);
  });

  testWidgets('an empty mix surfaces the no-tracks snackbar', (tester) async {
    final context = await pumpWithService(tester, _OutcomeMusicService(outcome: InstantMixOutcome.empty));

    await playInstantMix(context, seed);
    await tester.pump();

    expect(find.text(t.music.instantMixEmpty), findsOneWidget);
  });

  testWidgets('a started mix shows no snackbar', (tester) async {
    final context = await pumpWithService(tester, _OutcomeMusicService(outcome: InstantMixOutcome.started));

    await playInstantMix(context, seed);
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a superseded mix stays silent', (tester) async {
    final context = await pumpWithService(tester, _OutcomeMusicService(outcome: InstantMixOutcome.superseded));

    await playInstantMix(context, seed);
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
