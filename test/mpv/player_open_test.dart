import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('player open', () {
    test('ExoPlayer clears stale Dart track state before opening new media', () async {
      await _withMockChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        testBody: () async {
          final player = PlayerAndroid();
          try {
            _seedTracks(player);
            expect(player.state.tracks.audio, isNotEmpty);
            expect(player.state.track.audio, isNotNull);

            await player.open(Media('https://example.test/next.mkv'));

            expect(player.state.tracks.audio, isEmpty);
            expect(player.state.tracks.subtitle, isEmpty);
            expect(player.state.track.audio, isNull);
            expect(player.state.track.subtitle, isNull);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer applies DV conversion mode changed during in-flight initialization', () async {
      final initialize = Completer<bool>();
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return initialize.future;
            case 'requestAudioFocus':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            final focusFuture = player.requestAudioFocus();
            await Future<void>.delayed(Duration.zero);

            final modeFuture = player.setProperty('dv-conversion-mode', 'hevc_strip');
            await Future<void>.delayed(Duration.zero);

            final initCall = calls.singleWhere((call) => call.method == 'initialize');
            final initArgs = Map<Object?, Object?>.from(initCall.arguments as Map);
            expect(initArgs['dvConversionMode'], 'auto');
            expect(calls.where((call) => call.method == 'setDvConversionMode'), isEmpty);

            initialize.complete(true);
            await modeFuture;
            await focusFuture;

            final dvCall = calls.singleWhere((call) => call.method == 'setDvConversionMode');
            final dvArgs = Map<Object?, Object?>.from(dvCall.arguments as Map);
            expect(dvArgs['mode'], 'hevc_strip');
          } finally {
            if (!initialize.isCompleted) initialize.complete(true);
            await player.dispose();
          }
        },
      );
    });

    test('MPV clears stale Dart track state before opening new media', () async {
      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            _seedTracks(player);
            expect(player.state.tracks.audio, isNotEmpty);
            expect(player.state.track.audio, isNotNull);

            await player.open(Media('https://example.test/next.mkv'));

            expect(player.state.tracks.audio, isEmpty);
            expect(player.state.tracks.subtitle, isEmpty);
            expect(player.state.track.audio, isNull);
            expect(player.state.track.subtitle, isNull);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV maps server-offset streams to absolute timeline positions', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            await player.open(
              Media('https://example.test/transcode.mkv'),
              timelineOffset: const Duration(seconds: 10),
              timelineDuration: const Duration(seconds: 100),
            );

            expect(player.state.position, const Duration(seconds: 10));
            expect(player.state.duration, const Duration(seconds: 100));

            player.handlePropertyChange('duration', 90.0);
            expect(player.state.duration, const Duration(seconds: 100));

            await player.seek(const Duration(seconds: 25));

            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '15.0', 'absolute']);
            expect(player.state.position, const Duration(seconds: 25));
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV refresh seek preserves timeline offset position', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            const timelineStart = Duration(milliseconds: 143894);
            await player.open(
              Media('https://example.test/transcode.mkv'),
              timelineOffset: timelineStart,
              timelineDuration: const Duration(seconds: 1502),
            );

            expect(player.state.position, timelineStart);

            await player.seek(timelineStart);

            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '0.0', 'absolute']);
            expect(player.state.position, timelineStart);
          } finally {
            await player.dispose();
          }
        },
      );
    });
  });
}

Future<void> _withMockChannels({
  required String methodChannelName,
  required String eventChannelName,
  Future<Object?> Function(MethodCall call)? methodHandler,
  required Future<void> Function() testBody,
}) async {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final methodChannel = MethodChannel(methodChannelName);
  final eventChannel = MethodChannel(eventChannelName);

  messenger.setMockMethodCallHandler(
    methodChannel,
    methodHandler ??
        (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'observeProperty':
            case 'setVisible':
            case 'setProperty':
            case 'command':
            case 'open':
            case 'dispose':
              return null;
            default:
              return null;
          }
        },
  );
  messenger.setMockMethodCallHandler(eventChannel, (call) async => null);

  try {
    await testBody();
  } finally {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventChannel, null);
  }
}

void _seedTracks(dynamic player) {
  player.handlePropertyChange('track-list', const [
    {'type': 'audio', 'id': '2_0', 'title': 'English', 'lang': 'eng', 'selected': true},
    {'type': 'sub', 'id': '3_0', 'title': 'English', 'lang': 'eng', 'selected': true},
  ]);
}
