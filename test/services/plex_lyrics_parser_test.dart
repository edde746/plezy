import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_lyrics_parser.dart';

void main() {
  test('parses timed Plex XML and joins inline spans', () {
    final lyrics = parsePlexLyricsResponse('''
<?xml version="1.0" encoding="UTF-8"?>
<MediaContainer size="1">
  <Lyrics provider="com.plexapp.agents.localmedia" timed="1">
    <Line startOffset="500">
      <Span text="First line" />
    </Line>
    <Line startOffset="4000">
      <Span text="Second " />
      <Span text="line" />
    </Line>
  </Lyrics>
</MediaContainer>
''');

    expect(lyrics, isNotNull);
    expect(lyrics!.synced, isTrue);
    expect(lyrics.lines.map((line) => line.text), ['First line', 'Second line']);
    expect(lyrics.lines.map((line) => line.startMs), [500, 4000]);
  });

  test('explicitly untimed Plex lyrics discard synthetic offsets', () {
    final lyrics = parsePlexLyricsResponse({
      'MediaContainer': {
        'Lyrics': {
          'timed': '0',
          'Line': [
            {
              'startOffset': 0,
              'Span': {'text': 'Plain first line'},
            },
            {
              'startOffset': 1000,
              'Span': {'text': 'Plain second line'},
            },
          ],
        },
      },
    });

    expect(lyrics, isNotNull);
    expect(lyrics!.synced, isFalse);
    expect(lyrics.lines.map((line) => line.text), ['Plain first line', 'Plain second line']);
    expect(lyrics.lines.map((line) => line.startMs), everyElement(isNull));
  });

  test('retains raw LRC and text compatibility', () {
    final synced = parsePlexLyricsResponse('[00:01.00]Timed line');
    final plain = parsePlexLyricsResponse('Plain first line\nPlain second line');

    expect(synced, isNotNull);
    expect(synced!.synced, isTrue);
    expect(synced.lines.single.startMs, 1000);
    expect(plain, isNotNull);
    expect(plain!.synced, isFalse);
    expect(plain.lines.map((line) => line.text), ['Plain first line', 'Plain second line']);
  });

  test('returns null for XML with unclosed tags', () {
    final lyrics = parsePlexLyricsResponse('<MediaContainer><Lyrics><Line><Span text="Truncated">');

    expect(lyrics, isNull);
  });
}
