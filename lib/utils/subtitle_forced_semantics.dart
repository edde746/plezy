import '../media/media_source_info.dart';
import '../mpv/mpv.dart';
import 'track_label_builder.dart';

/// Effective forced-ness, mirroring server behavior (#1716/#1717): a subtitle
/// stream counts as forced when its flag is set OR its title says "forced".
/// Every forced comparison must use these getters on BOTH sides — the raw
/// flags stay untouched so parsing and the file-info UI keep server truth.
///
/// Hearing-impaired status is not represented by every server/native backend.
/// Infer only from explicit title markers, so a user-selected SDH/CC track can
/// be carried to another episode without treating arbitrary descriptive titles
/// as accessibility captions.
bool titleSaysHearingImpaired(String? title) {
  if (title == null || title.isEmpty) return false;
  return RegExp(
    r'(?:^|[^a-z0-9])(?:sdh|hi|cc|closed[\s._-]*captions?|hearing[\s._-]*impaired)(?=$|[^a-z0-9])',
    caseSensitive: false,
  ).hasMatch(title);
}

extension MediaSubtitleTrackForcedSemantics on MediaSubtitleTrack {
  bool get effectiveForced => forced || titleSaysForced(title) || titleSaysForced(displayTitle);
  bool get effectiveHearingImpaired =>
      titleSaysHearingImpaired(title) || titleSaysHearingImpaired(displayTitle);
}

extension SubtitleTrackForcedSemantics on SubtitleTrack {
  bool get effectiveForced => isForced || titleSaysForced(title);
  bool get effectiveHearingImpaired => titleSaysHearingImpaired(title);
}
