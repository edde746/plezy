import 'media_display_criteria.dart';

/// Profile-aware gate shared by the playback backends. A color range alone is
/// not enough to request Dolby Vision conversion: HDR10 and HLG streams can
/// carry similar color tags without being Dolby Vision sources.
bool shouldRequestCompatibleDolbyVisionRendition({required bool requested, required MediaDisplayCriteria? source}) =>
    requested && source?.hasDolbyVision == true;
