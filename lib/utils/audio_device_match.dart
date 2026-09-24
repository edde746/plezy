import '../mpv/mpv.dart';

/// The device in [devices] a controller means by [query], or null.
///
/// Deliberately a plain case-insensitive substring test, unlike the language
/// matcher: output devices carry free-text OS names ("LG TV (NVIDIA High
/// Definition Audio)") with no codes or aliases to reconcile, so a person says
/// a fragment of what they see. [AudioDevice.description] is checked first
/// because it is the human-readable half; the raw name still matches so an
/// exact device id always works.
AudioDevice? matchAudioDevice(String query, List<AudioDevice> devices) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final device in devices) {
    if (device.description.toLowerCase().contains(normalized)) return device;
    if (device.name.toLowerCase().contains(normalized)) return device;
  }
  return null;
}
