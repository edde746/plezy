/// Represents an audio output device.
class MpvAudioDevice {
  /// Unique identifier for the device.
  final String name;

  /// Human-readable description of the device.
  final String description;

  const MpvAudioDevice({
    required this.name,
    this.description = '',
  });

  /// Default/auto audio device.
  static const auto = MpvAudioDevice(name: 'auto', description: 'Auto');

  @override
  String toString() => 'MpvAudioDevice($name, $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MpvAudioDevice &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
