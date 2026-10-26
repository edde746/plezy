import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/dolby_vision_compatibility.dart';
import 'package:plezy/media/media_display_criteria.dart';

void main() {
  test('compatibility rendition routing requires an identified DV profile and an adapter request', () {
    const dolbyVision = MediaDisplayCriteria(doviProfile: 7, doviCompatibilityId: 6);
    const hdr10 = MediaDisplayCriteria(transfer: 'smpte2084', primaries: 'bt2020');

    expect(shouldRequestCompatibleDolbyVisionRendition(requested: false, source: dolbyVision), isFalse);
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: dolbyVision), isTrue);
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: hdr10), isFalse);
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: null), isFalse);
  });
}
