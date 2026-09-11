import 'dart:async';
import 'package:plezy/models/audio_equalizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';
import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
  });
  test('live EQ edits replace only own filter; switching off preserves loudness', () async {
    final calls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        return call.method == 'initialize' ? true : null;
      },
      testBody: () async {
        final player = PlayerNative();
        final settings = SettingsService.instance;
        try {
          await player.setAudioNormalization(true);
          player.handlePropertyChange('track-list', [
            {'type': 'audio', 'id': 1, 'codec': 'eac3', 'demux-channel-count': 6, 'selected': true},
          ]);
          await settings.write(
            SettingsService.audioEqualizer,
            EqualizerSettings({
              EqualizerAudioType.global: EqualizerProfile(gains: <double>[2, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            }),
          );
          await settings.write(SettingsService.audioEqualizerEnabled, true);
          await player.refreshEqualizer();
          expect(
            calls.where((c) => c.method == 'command' && c.arguments.toString().contains('@plezy_eq:')),
            isNotEmpty,
          );
          calls.clear();
          await settings.write(
            SettingsService.audioEqualizer,
            EqualizerSettings({
              EqualizerAudioType.global: EqualizerProfile(gains: <double>[4, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            }),
          );
          await player.refreshEqualizer();
          expect(calls.any((c) => c.method == 'command' && c.arguments.toString().contains('g=4.0')), isTrue);
          calls.clear();
          await settings.write(SettingsService.audioEqualizerEnabled, false);
          await player.refreshEqualizer();
          expect(
            calls.any((c) => c.method == 'command' && c.arguments.toString().contains('remove, @plezy_eq')),
            isTrue,
          );
          expect(calls.where((c) => c.method == 'setProperty' && c.arguments['name'] == 'af'), isEmpty);
          expect(settings.read(SettingsService.audioEqualizer).resolve(EqualizerAudioType.global).gains.first, 4);
        } finally {
          await player.dispose();
        }
      },
    );
  });
  test('native rejection is visible and retryable with unchanged preferences', () async {
    var reject = true;
    var writes = 0;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'command' && call.arguments.toString().contains('@plezy_eq:')) {
          writes++;
          if (reject) throw PlatformException(code: 'COMMAND_FAILED');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          final settings = SettingsService.instance;
          await settings.write(
            SettingsService.audioEqualizer,
            EqualizerSettings({EqualizerAudioType.global: EqualizerProfile(preampDb: 2)}),
          );
          await settings.write(SettingsService.audioEqualizerEnabled, true);
          await player.refreshEqualizer();
          expect(player.state.equalizerFailed, isTrue);
          reject = false;
          await player.refreshEqualizer();
          expect(player.state.equalizerFailed, isFalse);
          expect(writes, 2);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('normalization waits for an in-flight EQ write then retains its filter', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final operations = <String>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'command' && call.arguments.toString().contains('@plezy_eq:')) {
          operations.add('eq');
          if (!started.isCompleted) {
            started.complete();
            await release.future;
          }
        }
        if (call.method == 'setProperty' && call.arguments['name'] == 'af') operations.add('normalization');
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          final eq = player.setAudioEqualizer(EqualizerProfile(preampDb: 1));
          await started.future;
          final normalize = player.setAudioNormalization(true);
          release.complete();
          await Future.wait([eq, normalize]);
          expect(operations, ['eq', 'normalization', 'eq']);
        } finally {
          await player.dispose();
        }
      },
    );
  });
}
