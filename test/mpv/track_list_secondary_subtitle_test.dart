import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// mpv marks both the `sid` and the `--secondary-sid` track as `selected` in
/// `track-list` and discriminates them with `main-selection` (0 = primary,
/// 1 = secondary). The parser used to treat every selected subtitle as the
/// primary, so whichever selected track came last in list order overwrote
/// `PlayerState.track.subtitle` — painting the secondary row with the primary
/// checkmark whenever the secondary sat later in the container.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  Future<void> withPlayer(Future<void> Function(PlayerAndroid player) body) async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/exo_player',
      eventChannelName: 'com.plezy/exo_player/events',
      testBody: () async {
        final player = PlayerAndroid();
        try {
          await body(player);
        } finally {
          await player.dispose();
        }
      },
    );
  }

  const primaryFirst = [
    {'type': 'audio', 'id': '1', 'lang': 'eng', 'selected': true},
    {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true, 'main-selection': 0},
    {'type': 'sub', 'id': '3', 'lang': 'jpn', 'selected': true, 'main-selection': 1},
  ];
  const secondaryFirst = [
    {'type': 'audio', 'id': '1', 'lang': 'eng', 'selected': true},
    {'type': 'sub', 'id': '3', 'lang': 'jpn', 'selected': true, 'main-selection': 1},
    {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true, 'main-selection': 0},
  ];

  group('parseTrackList', () {
    test('main-selection 0/1 resolves primary and secondary ids, primary listed first', () async {
      await withPlayer((player) async {
        final result = player.parseTrackList(primaryFirst);
        expect(result.selectedSubtitleId, '2');
        expect(result.selectedSecondarySubtitleId, '3');
      });
    });

    test('secondary listed first no longer overwrites the primary selection', () async {
      await withPlayer((player) async {
        final result = player.parseTrackList(secondaryFirst);
        expect(result.selectedSubtitleId, '2');
        expect(result.selectedSecondarySubtitleId, '3');
      });
    });

    test('a selected subtitle without main-selection stays the primary (ExoPlayer shape)', () async {
      await withPlayer((player) async {
        final result = player.parseTrackList(const [
          {'type': 'audio', 'id': '1', 'lang': 'eng', 'selected': true},
          {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true},
        ]);
        expect(result.selectedSubtitleId, '2');
        expect(result.selectedSecondarySubtitleId, isNull);
      });
    });
  });

  group('track-list property handler', () {
    test('drives both subtitle selections from one track-list event, in either order', () async {
      for (final trackList in [primaryFirst, secondaryFirst]) {
        await withPlayer((player) async {
          player.handlePropertyChange('track-list', trackList);
          expect(player.state.track.subtitle?.id, '2');
          expect(player.state.track.secondarySubtitle?.id, '3');
        });
      }
    });

    test('the secondary-sid observation still clears the secondary without touching the primary', () async {
      await withPlayer((player) async {
        player.handlePropertyChange('track-list', primaryFirst);
        expect(player.state.track.secondarySubtitle?.id, '3');

        player.handlePropertyChange('secondary-sid', 'no');
        expect(player.state.track.secondarySubtitle, isNull);
        expect(player.state.track.subtitle?.id, '2');
      });
    });
  });
}
