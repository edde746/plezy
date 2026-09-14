import '../media/media_source_info.dart';
import '../mpv/mpv.dart';
import 'track_label_builder.dart';

/// Effective forced-ness, mirroring server behavior (#1716/#1717): a subtitle
/// stream counts as forced when its flag is set OR its title says "forced".
/// Every forced comparison must use these getters on BOTH sides — the raw
/// flags stay untouched so parsing and the file-info UI keep server truth.

extension MediaSubtitleTrackForcedSemantics on MediaSubtitleTrack {
  bool get effectiveForced => forced || titleSaysForced(title) || titleSaysForced(displayTitle);
}

extension SubtitleTrackForcedSemantics on SubtitleTrack {
  bool get effectiveForced => isForced || titleSaysForced(title);
}
