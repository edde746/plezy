import '../mpv/mpv.dart';
import '../utils/subtitle_forced_semantics.dart';

/// Item-agnostic semantic subtitle intent.
///
/// [language] and [forced] are hard matching requirements — an intent only
/// resolves to a track of the same language AND the same forced-ness class,
/// otherwise resolution declines and the selection ladder falls back to the
/// server's own per-item choice (#1716/#1717). [forced] is EFFECTIVE
/// forced-ness (flag OR title-says-forced), captured once at the boundary.
final class SubtitleIntent {
  final String? language;
  final bool forced;

  /// Tiebreakers between same-class candidates, and log diagnostics.
  final String? title;
  final String? codec;
  final bool isExternal;

  const SubtitleIntent({this.language, required this.forced, this.title, this.codec, this.isExternal = false});

  /// Null when [track] is null/off or carries no semantic metadata at all —
  /// an intent that can never resolve is not worth carrying.
  static SubtitleIntent? fromTrack(SubtitleTrack? track) {
    if (track == null || track.id == SubtitleTrack.off.id) return null;
    final hasSemanticMetadata =
        (track.title?.isNotEmpty ?? false) ||
        (track.language?.isNotEmpty ?? false) ||
        (track.codec?.isNotEmpty ?? false);
    if (!hasSemanticMetadata) return null;
    return SubtitleIntent(
      language: track.language,
      forced: track.effectiveForced,
      title: track.title,
      codec: track.codec,
      isExternal: track.isExternal,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubtitleIntent &&
      other.language == language &&
      other.forced == forced &&
      other.title == title &&
      other.codec == codec &&
      other.isExternal == isExternal;

  @override
  int get hashCode => Object.hash(language, forced, title, codec, isExternal);

  @override
  String toString() => 'SubtitleIntent($language, forced: $forced, title: $title, codec: $codec)';
}

/// What the next open/selection pass should aim for, subtitle-wise.
///
/// [SubtitlePreference.track] is an identity reference (`source:` row, sidecar
/// URI, or raw native track) valid only within the current item and media
/// source. [SubtitlePreference.intent] carries semantics alone and is the only
/// form that may cross an item/source boundary — see [demoteToIntent].
sealed class SubtitlePreference {
  const SubtitlePreference();

  const factory SubtitlePreference.off() = SubtitleOffPreference;
  const factory SubtitlePreference.track(SubtitleTrack track) = SubtitleTrackPreference;
  const factory SubtitlePreference.intent(SubtitleIntent intent) = SubtitleIntentPreference;

  /// Identity-ref wrapper: null stays null, the off sentinel becomes [off].
  static SubtitlePreference? trackOrNull(SubtitleTrack? track) {
    if (track == null) return null;
    if (track.id == SubtitleTrack.off.id) return const SubtitlePreference.off();
    return SubtitlePreference.track(track);
  }

  /// Crossing an item/source boundary: identity references lose their meaning
  /// there, so every track reference becomes a semantic intent (or null when
  /// it has no semantics). Off and existing intents pass through.
  static SubtitlePreference? demoteToIntent(SubtitlePreference? preference) {
    switch (preference) {
      case null || SubtitleOffPreference() || SubtitleIntentPreference():
        return preference;
      case SubtitleTrackPreference(:final track):
        final intent = SubtitleIntent.fromTrack(track);
        return intent == null ? null : SubtitlePreference.intent(intent);
    }
  }
}

final class SubtitleOffPreference extends SubtitlePreference {
  const SubtitleOffPreference();

  @override
  bool operator ==(Object other) => other is SubtitleOffPreference;

  @override
  int get hashCode => (SubtitleOffPreference).hashCode;

  @override
  String toString() => 'SubtitlePreference.off';
}

final class SubtitleTrackPreference extends SubtitlePreference {
  final SubtitleTrack track;

  const SubtitleTrackPreference(this.track);

  @override
  bool operator ==(Object other) => other is SubtitleTrackPreference && other.track == track;

  @override
  int get hashCode => track.hashCode;

  @override
  String toString() => 'SubtitlePreference.track(${track.id})';
}

final class SubtitleIntentPreference extends SubtitlePreference {
  final SubtitleIntent intent;

  const SubtitleIntentPreference(this.intent);

  @override
  bool operator ==(Object other) => other is SubtitleIntentPreference && other.intent == intent;

  @override
  int get hashCode => intent.hashCode;

  @override
  String toString() => 'SubtitlePreference.intent($intent)';
}
