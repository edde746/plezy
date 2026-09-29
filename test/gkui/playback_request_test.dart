import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/gkui/diagnostics.dart';
import 'package:plezy/gkui/plex_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlexApi api;
  const media = PlexMedia(
    ratingKey: '37',
    key: '/library/metadata/37',
    type: 'episode',
    title: 'Episode 37',
    directPartKey: '/library/parts/1/file.mp4',
    viewOffsetMs: 12000,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = await PlexApi.create(RedactingLogStore());
    api.session = const PlexSession(
      accountToken: 'account-secret',
      serverToken: 'server-secret',
      serverName: 'Test',
      serverId: 'test-id',
      baseUrl: 'https://example.test',
    );
  });

  test('direct playback keeps original part and credentials out of URL', () {
    final request = api.playback(media, transcode: false);
    expect(request.url, 'https://example.test/library/parts/1/file.mp4');
    expect(request.transcoding, isFalse);
    expect(request.headers['X-Plex-Token'], 'server-secret');
    expect(request.headers['X-Plex-Session-Identifier'], request.sessionId);
  });

  test('version preference chooses the H264 1080p copy and avoids 4K', () {
    const versions = <PlexMediaVersion>[
      PlexMediaVersion(
          index: 0,
          partKey: '/library/parts/4k.mkv',
          resolution: '4k',
          codec: 'hevc',
          height: 2160,
          bitrateKbps: 45000),
      PlexMediaVersion(
          index: 1,
          partKey: '/library/parts/1080.mp4',
          resolution: '1080',
          codec: 'h264',
          height: 1080,
          bitrateKbps: 8000),
      PlexMediaVersion(
          index: 2,
          partKey: '/library/parts/720.mp4',
          resolution: '720',
          codec: 'h264',
          height: 720,
          bitrateKbps: 4000),
    ];
    expect(PlexMediaVersion.preferredIndex(versions), 1);
    const multi = PlexMedia(
      ratingKey: '38',
      key: '/library/metadata/38',
      type: 'movie',
      title: 'Multiple versions',
      directPartKey: '/library/parts/4k.mkv',
      versions: versions,
    );
    final request = api.playback(multi, transcode: false, mediaIndex: 1);
    expect(request.url, 'https://example.test/library/parts/1080.mp4');
  });

  test('playback preferences persist on the head unit', () async {
    const settings = GkuiSettings(
      audioLanguage: 'ja',
      subtitleLanguage: 'en',
      seekBackSeconds: 15,
      seekForwardSeconds: 60,
      autoPlayNext: false,
      skipMode: SkipMode.automatic,
      playNextCountdownSeconds: 15,
      showWatchedIndicators: false,
    );
    await api.saveSettings(settings);
    final restored = api.loadSettings();
    expect(restored.audioLanguage, 'ja');
    expect(restored.subtitleLanguage, 'en');
    expect(restored.seekBackSeconds, 15);
    expect(restored.seekForwardSeconds, 60);
    expect(restored.autoPlayNext, isFalse);
    expect(restored.skipMode, SkipMode.automatic);
    expect(restored.playNextCountdownSeconds, 15);
    expect(restored.showWatchedIndicators, isFalse);
  });

  test('version and stream choices are remembered for the title', () async {
    await api.savePlaybackChoice(
      media,
      const PlaybackChoice(
        mediaIndex: 2,
        audioTrackId: '17',
        subtitleTrackId: 'off',
      ),
    );
    final restored = api.loadPlaybackChoice(media);
    expect(restored.mediaIndex, 2);
    expect(restored.audioTrackId, '17');
    expect(restored.subtitleTrackId, 'off');
  });

  for (final bitrate in <int>[3000, 1500]) {
    test('safe $bitrate requests H264 AAC stereo without stream copy', () {
      final request = api.playback(media, transcode: true, bitrate: bitrate);
      final uri = Uri.parse(request.url);
      final params = uri.queryParameters;
      expect(request.transcoding, isTrue);
      expect(uri.path, '/video/:/transcode/universal/start.m3u8');
      expect(params['directPlay'], '0');
      expect(params['directStream'], '0');
      expect(params['directStreamAudio'], '0');
      expect(params['maxAudioChannels'], '2');
      expect(params['maxVideoBitrate'], '$bitrate');
      expect(
          params['videoResolution'], bitrate == 3000 ? '1280x720' : '720x480');
      expect(params['X-Plex-Client-Profile-Extra'],
          contains('videoCodec=h264&audioCodec=aac'));
      expect(
          params['X-Plex-Client-Profile-Extra'], contains('container=mpegts'));
      expect(params['X-Plex-Client-Profile-Extra'],
          contains('name=audio.channels&value=2'));
      expect(params['X-Plex-Platform'], 'Generic');
      expect(params['session'], request.sessionId);
      expect(params['X-Plex-Session-Identifier'], request.sessionId);
      expect(request.headers['X-Plex-Platform'], 'Generic');
      expect(request.headers['X-Plex-Token'], 'server-secret');
      expect(request.url, isNot(contains('secret')));
      // The native player seeks; don't apply the resume offset a second time.
      expect(params.containsKey('offset'), isFalse);
    });
  }
}
