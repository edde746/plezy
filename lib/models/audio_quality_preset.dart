/// Music streaming quality presets.
///
/// When a non-[original] preset is selected, track playback asks the active
/// backend for a bitrate-capped audio transcode (Plex
/// `/music/:/transcode/universal` with `musicBitrate`, Jellyfin `PlaybackInfo`
/// with a capped `MaxStreamingBitrate`). [original] bypasses transcoding and
/// direct-plays the source file. Deliberately separate from
/// [TranscodeQualityPreset] — its members are video-shaped
/// (resolution/videoQuality).
enum AudioQualityPreset {
  original(null),
  high(320),
  medium(192),
  low(128);

  const AudioQualityPreset(this.bitrateKbps);

  final int? bitrateKbps;

  bool get isOriginal => this == AudioQualityPreset.original;

  String get storageKey => name;

  static AudioQualityPreset fromStorage(String? stored) {
    if (stored == null) return AudioQualityPreset.original;
    for (final v in AudioQualityPreset.values) {
      if (v.name == stored) return v;
    }
    return AudioQualityPreset.original;
  }

  /// Order shared by every picker surface: [original] first, then capped
  /// presets highest-bitrate first.
  static final List<AudioQualityPreset> displayOrder = List.unmodifiable(values);
}
