import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/universal_media_input.dart';

void main() {
  group('UniversalMediaAddress', () {
    test('accepts HTTPS and requires explicit consent for HTTP', () {
      expect(
        UniversalMediaAddress.parse('  https://media.example/movie.mkv  ', allowHttp: false),
        Uri.parse('https://media.example/movie.mkv'),
      );
      expect(
        () => UniversalMediaAddress.parse('http://radio.example/live', allowHttp: false),
        throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
      );
      expect(
        UniversalMediaAddress.parse('http://radio.example/live', allowHttp: true),
        Uri.parse('http://radio.example/live'),
      );
    });

    test('rejects credentials, fragments, control characters, and overlong input', () {
      for (final value in [
        'https://user:password@media.example/movie.mkv',
        'https://media.example/movie.mkv#fragment',
        'https://media.example/unsafe\npath',
        'https://media.example/${List.filled(UniversalMediaAddress.maxLength, 'x').join()}',
      ]) {
        expect(
          () => UniversalMediaAddress.parse(value, allowHttp: false),
          throwsA(isA<SourceException>()),
          reason: value.length > 100 ? 'long URL' : value,
        );
      }
    });

    test('allows native protocols only when the MPV capability is enabled', () {
      expect(
        () => UniversalMediaAddress.parse('rtsp://camera.example/live', allowHttp: false),
        throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
      );
      final address = UniversalMediaAddress.parse(
        'rtsp://camera.example/live',
        allowHttp: false,
        allowMpvProtocols: true,
      );
      expect(address.scheme, 'rtsp');
      expect(UniversalMediaAddress.usesMpvProtocol(address), isTrue);
    });

    test('resolves relative entries against the playlist while rejecting local and foreign schemes', () {
      final playlist = UniversalMediaPlaylistParser.parse(
        '#EXTM3U\n../music/track.flac\nfile:///etc/passwd\njavascript:alert(1)',
        fallbackTitle: 'Radio list',
        base: Uri.parse('https://media.example/lists/stations.m3u'),
        allowHttp: false,
      );

      expect(playlist.items, hasLength(1));
      expect(playlist.items.single.uri, Uri.parse('https://media.example/music/track.flac'));
      expect(playlist.items.single.title, 'media.example');
      expect(playlist.skipped, 2);
    });

    test('parses M3U metadata and keeps live duration when attributes are present', () {
      final playlist = UniversalMediaPlaylistParser.parse(
        '#EXTM3U\n#EXTINF:-1 group-title="News",Public Radio\nhttps://radio.example/live',
        fallbackTitle: 'Stations',
        allowHttp: false,
      );

      expect(playlist.items, hasLength(1));
      expect(playlist.items.single.title, 'Public Radio');
      expect(playlist.items.single.group, 'News');
      expect(playlist.items.single.durationSeconds, isNull);
      expect(playlist.live, isTrue);
    });

    test('parses PLS entries in numeric order and treats negative lengths as live', () {
      final playlist = UniversalMediaPlaylistParser.parse(
        '[playlist]\n'
        'NumberOfEntries=3\n'
        'File2=../second.m4a\nTitle2=Second\nLength2=-1\n'
        'File1=first.mp3\nTitle1=First\nLength1=120\n'
        'File3=javascript:alert(1)\n',
        fallbackTitle: 'Station set',
        base: Uri.parse('https://radio.example/playlists/list.pls'),
        allowHttp: false,
      );

      expect(playlist.title, 'Station set');
      expect(playlist.items.map((item) => item.title), ['First', 'Second']);
      expect(playlist.items.first.durationSeconds, 120);
      expect(playlist.items.last.uri, Uri.parse('https://radio.example/second.m4a'));
      expect(playlist.skipped, 1);
      expect(playlist.live, isTrue);
    });

    test('keeps HLS manifests as one item and distinguishes live, VOD, and master playlists', () {
      UniversalMediaPlaylist parse(String body) => UniversalMediaPlaylistParser.parse(
        body,
        fallbackTitle: 'Adaptive stream',
        base: Uri.parse('https://video.example/live/index.m3u8'),
        allowHttp: false,
      );

      final live = parse('#EXTM3U\n#EXT-X-TARGETDURATION:6\nsegment-1.ts');
      final vod = parse('#EXTM3U\n#EXT-X-PLAYLIST-TYPE:VOD\nsegment-1.ts');
      final master = parse('#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=800000\nlow/index.m3u8');

      expect(live.items, hasLength(1));
      expect(live.items.single.uri, Uri.parse('https://video.example/live/index.m3u8'));
      expect(live.live, isTrue);
      expect(vod.live, isFalse);
      expect(master.live, isFalse);
    });

    test('rejects empty, oversized, and overlong playlists', () {
      expect(
        () => UniversalMediaPlaylistParser.parse('', fallbackTitle: 'Empty', allowHttp: false),
        throwsA(isA<SourceException>()),
      );
      expect(
        () => UniversalMediaPlaylistParser.parse(
          List.filled(UniversalMediaPlaylistParser.maxCharacters + 1, 'x').join(),
          fallbackTitle: 'Large',
          allowHttp: false,
        ),
        throwsA(isA<SourceException>()),
      );
      expect(
        () => UniversalMediaPlaylistParser.parse(
          '#EXTM3U\nhttps://media.example/${List.filled(UniversalMediaPlaylistParser.maxLineLength, 'x').join()}',
          fallbackTitle: 'Long line',
          allowHttp: false,
        ),
        throwsA(isA<SourceException>()),
      );
      final tooManyItems = [
        '#EXTM3U',
        for (var index = 0; index <= UniversalMediaPlaylistParser.maxItems; index++) 'https://media.example/$index.mp3',
      ].join('\n');
      expect(
        () => UniversalMediaPlaylistParser.parse(tooManyItems, fallbackTitle: 'Large list', allowHttp: false),
        throwsA(isA<SourceException>()),
      );
    });

    test('only saves credential-free HTTPS and explicitly permitted HTTP favorites', () {
      expect(UniversalMediaAddress.canSaveFavorite(Uri.parse('https://radio.example/live')), isTrue);
      expect(UniversalMediaAddress.canSaveFavorite(Uri.parse('http://radio.example/live')), isTrue);
      expect(UniversalMediaAddress.canSaveFavorite(Uri.parse('https://radio.example/live?token=secret')), isFalse);
      expect(UniversalMediaAddress.canSaveFavorite(Uri.parse('https://user:secret@radio.example/live')), isFalse);
      expect(UniversalMediaAddress.canSaveFavorite(Uri.parse('rtsp://camera.example/live')), isFalse);
    });
  });

  test('maps common media extensions and derives safe display names', () {
    expect(universalMediaMimeType('episode.MKV'), 'video/x-matroska');
    expect(universalMediaMimeType('track.flac'), 'audio/flac');
    expect(universalMediaMimeType('unknown.bin'), 'application/octet-stream');
    expect(inferredMediaName(Uri.parse('https://radio.example/live?token=private')), 'radio.example');
    expect(inferredMediaName(Uri.parse('file:///music/track.mp3')), 'track.mp3');
  });
}
