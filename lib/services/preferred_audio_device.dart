import '../mpv/mpv.dart';
import '../mpv/player/mpv_node_decoder.dart';
import '../utils/app_logger.dart';

/// Puts a freshly created mpv core on [preferred], the audio output last picked
/// in the player (#2744), when that output is present.
///
/// Only an output this core lists is applied. Where the core leaves `ao` unset
/// (Linux, Windows), mpv treats a set `audio-device` as forced: when that device
/// cannot be opened it skips automatic selection and goes straight to the null
/// output (`ao_init_best`), so a stale pick - an unplugged DAC, a receiver that
/// is off - would play silence until audio recovery gives up and ends playback.
/// An absent output leaves the core on `auto` and the preference in place for
/// when the device returns.
///
/// Best-effort: an unreadable list or a refused write is logged and the core
/// stays on `auto`, which is what it would have used without the preference.
Future<void> applyPreferredAudioDevice(Player player, String preferred) async {
  if (preferred.isEmpty || preferred == AudioDevice.auto.name) return;
  try {
    final devices = MpvNodeDecoder.decodeList(await player.getProperty('audio-device-list'));
    final present = devices?.any((entry) => entry is Map && entry['name'] == preferred) ?? false;
    if (!present) {
      appLogger.i('Audio output "$preferred" is not available; using automatic selection');
      return;
    }
    await player.setAudioDevice(AudioDevice(name: preferred));
  } catch (error, stackTrace) {
    appLogger.w(
      'Audio output "$preferred" not applied; using automatic selection',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
