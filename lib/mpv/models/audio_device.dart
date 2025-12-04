/// Represents an audio output device.
class AudioDevice {
  /// Unique identifier for the device.
  final String name;

  /// Human-readable description of the device.
  final String description;

  const AudioDevice({required this.name, this.description = ''});

  /// Default/auto audio device.
  static const auto = AudioDevice(name: 'auto', description: 'Auto');

  @override
  String toString() => 'AudioDevice($name, $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioDevice &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
