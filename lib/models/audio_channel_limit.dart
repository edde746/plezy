/// The most channels decoded audio may reach the audio output with.
///
/// For outputs that cannot carry the source layout: stereo speakers and
/// headphones ([stereo]), or HDMI chains whose multichannel PCM stops at 5.1
/// ([surround51]) — Samsung eARC documents a 5.1 PCM maximum, and Fire TV
/// sticks drop 7.1 PCM to stereo (#2442). Nothing downstream of the TV is
/// visible to the platform APIs, so the viewer picks the limit.
///
/// [surround51] only shapes decoded PCM: a bitstream keeps its own layout, so
/// passthrough stays available. [stereo] decodes every track, so passthrough
/// is off while it is selected.
enum AudioChannelLimit {
  original,
  surround51,
  stereo;

  /// ExoPlayer only has the stereo downmix, and the backend is being removed,
  /// so [surround51] plays as [original] there.
  AudioChannelLimit get onExoPlayer => this == surround51 ? original : this;

  /// The limits the active backend honours.
  static List<AudioChannelLimit> available({required bool exoPlayer}) => exoPlayer ? const [original, stereo] : values;
}
