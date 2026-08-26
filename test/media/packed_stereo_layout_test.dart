import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/packed_stereo_layout.dart';

void main() {
  test('maps mpv packed stereo metadata without losing eye order', () {
    expect(PackedStereoLayout.fromMpvStereoInput('sbs2l'), PackedStereoLayout.sideBySideLeftFirst);
    expect(PackedStereoLayout.fromMpvStereoInput('sbs2r'), PackedStereoLayout.sideBySideRightFirst);
    expect(PackedStereoLayout.fromMpvStereoInput('ab2l'), PackedStereoLayout.topBottomLeftFirst);
    expect(PackedStereoLayout.fromMpvStereoInput('ab2r'), PackedStereoLayout.topBottomRightFirst);
    expect(PackedStereoLayout.fromMpvStereoInput('mono'), PackedStereoLayout.mono);
    expect(PackedStereoLayout.fromMpvStereoInput(null), PackedStereoLayout.unknown);
  });
}
