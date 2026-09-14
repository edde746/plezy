/// The system's resolved audio rendering mode on Apple platforms, as reported
/// by `AVAudioSession.renderingMode` (tvOS/iOS 17.2+).
///
/// Dolby's application guide requires players to badge playback from this
/// value. Apple documents it as populated for CarPlay and AirPlay routes, so a
/// direct HDMI route is expected to report `notApplicable`; that means
/// "unknown", not "not Dolby", and [isConclusive] encodes the difference.
class AudioRenderingMode {
  const AudioRenderingMode({
    required this.name,
    required this.rawValue,
    required this.route,
    required this.outputChannels,
    required this.maxOutputChannels,
  });

  final String name;
  final int rawValue;
  final String route;
  final int outputChannels;
  final int maxOutputChannels;

  static const int notApplicable = 0;
  static const int monoStereo = 1;
  static const int surround = 2;
  static const int spatialAudio = 3;
  static const int dolbyAudio = 4;
  static const int dolbyAtmos = 5;

  bool get isConclusive => rawValue != notApplicable && name != 'unavailable';
  bool get isDolbyAtmos => rawValue == dolbyAtmos;
  bool get isDolbyAudio => rawValue == dolbyAudio;
}
