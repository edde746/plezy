import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// ExoPlayer has no renderer-level subtitle visibility switch, so the player's
/// hide toggle is emulated by deselecting the track. That emulation used to be
/// per-selection: the next automatic selection — an episode advance carrying
/// the previous episode's choice — put subtitles straight back on screen while
/// the toggle still read "hidden", and un-hiding then restored a track id from
/// the episode that had already ended (#1779). mpv keeps `sub-visibility`
/// across files; this pins the same behaviour on ExoPlayer.
Future<void> _withPlayer(Future<void> Function(PlayerAndroid player, _PlayerHarness harness) body) async {
  final harness = _PlayerHarness();
  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/exo_player',
    eventChannelName: 'com.plezy/exo_player/events',
    methodHandler: harness.handle,
    testBody: () async {
      final player = PlayerAndroid();
      try {
        // What actually drives native initialize, and with it the property
        // observations the track list arrives through.
        await player.requestAudioFocus();
        await body(player, harness);
      } finally {
        await player.dispose();
      }
    },
  );
}

class _PlayerHarness {
  final Map<String, int> observations = {};
  final List<String> subtitleSelections = [];

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
        return true;
      case 'observeProperty':
        final arguments = call.arguments as Map;
        observations[arguments['name'] as String] = arguments['id'] as int;
      case 'selectSubtitleTrack':
        subtitleSelections.add((call.arguments as Map)['trackId'] as String);
    }
    return null;
  }

  Future<void> sendTrackList(List<Map<String, Object?>> tracks) async {
    final done = Completer<void>();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'com.plezy/exo_player/events',
      const StandardMethodCodec().encodeSuccessEnvelope([observations['track-list'], jsonEncode(tracks)]),
      (_) => done.complete(),
    );
    await done.future;
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('hidden subtitles stay hidden when the next episode selects its own track', () async {
    await _withPlayer((player, harness) async {
      await harness.sendTrackList([
        {'type': 'audio', 'id': '1', 'lang': 'eng', 'selected': true},
        {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true},
      ]);
      expect(player.state.track.subtitle?.id, '2');

      await player.setProperty('sub-visibility', 'no');
      expect(harness.subtitleSelections, ['no']);

      // Episode advance: a new track list, then the carried-over choice.
      await harness.sendTrackList([
        {'type': 'audio', 'id': '1', 'lang': 'eng', 'selected': true},
        {'type': 'sub', 'id': '5', 'lang': 'eng'},
      ]);
      await player.selectSubtitleTrack(const SubtitleTrack(id: '5', language: 'eng'));

      expect(harness.subtitleSelections, ['no', 'no']);
    });
  });

  test('un-hiding restores the current media selection, not the one hiding began with', () async {
    await _withPlayer((player, harness) async {
      await harness.sendTrackList([
        {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true},
      ]);
      await player.setProperty('sub-visibility', 'no');

      await harness.sendTrackList([
        {'type': 'sub', 'id': '5', 'lang': 'eng'},
      ]);
      await player.selectSubtitleTrack(const SubtitleTrack(id: '5', language: 'eng'));
      await player.setProperty('sub-visibility', 'yes');

      expect(harness.subtitleSelections.last, '5');
    });
  });

  test('an explicit off while hidden leaves nothing to restore', () async {
    await _withPlayer((player, harness) async {
      await harness.sendTrackList([
        {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true},
      ]);
      await player.setProperty('sub-visibility', 'no');
      await player.selectSubtitleTrack(SubtitleTrack.off);
      harness.subtitleSelections.clear();

      await player.setProperty('sub-visibility', 'yes');

      expect(harness.subtitleSelections, isEmpty);
    });
  });

  test('selections pass straight through while subtitles are visible', () async {
    await _withPlayer((player, harness) async {
      await harness.sendTrackList([
        {'type': 'sub', 'id': '2', 'lang': 'eng', 'selected': true},
        {'type': 'sub', 'id': '3', 'lang': 'swe'},
      ]);

      await player.selectSubtitleTrack(const SubtitleTrack(id: '3', language: 'swe'));
      await player.setProperty('sub-visibility', 'yes');

      expect(harness.subtitleSelections, ['3']);
    });
  });
}
