import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/tizen_playback_profile.dart';

void main() {
  test('Samsung profile advertises only conservative native-media formats', () {
    final profile = tizenPlaybackProfile(audio: false, burnSubtitles: false);
    final transcode = (profile['TranscodingProfiles'] as List).single as Map;
    expect(transcode['Protocol'], 'hls');
    expect(transcode['VideoCodec'], 'h264');
    expect(transcode['MaxAudioChannels'], '2');
    expect(profile['SubtitleProfiles'], [
      {'Format': 'srt', 'Method': 'External'},
      {'Format': 'vtt', 'Method': 'External'},
    ]);
    expect(profile.toString(), isNot(contains('hevc')));
    expect(profile.toString(), isNot(contains('av1')));
  });
  test('burn-in does not simultaneously advertise external subtitle delivery', () {
    expect(tizenPlaybackProfile(audio: true, burnSubtitles: true)['SubtitleProfiles'], isEmpty);
  });
  test('resolution cap preserves a smaller requested preset', () {
    expect(tizenVideoResolution(null), '1920x1080');
    expect(tizenVideoResolution('3840x2160'), '1920x1080');
    expect(tizenVideoResolution('1280x720'), '1280x720');
    expect(tizenVideoResolution('invalid'), '1920x1080');
    expect(tizenVideoResolution('0x0'), '1920x1080');
  });
}
