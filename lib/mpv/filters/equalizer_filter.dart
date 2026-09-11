import '../../models/audio_equalizer.dart';

/// Only this labeled filter is replaced/removed when EQ changes.
const equalizerFilterLabel = 'plezy_eq';

String buildEqualizerFilter(EqualizerProfile profile) {
  if (profile.isFlat) return '';
  final filters = <String>[];
  if (profile.preampDb != 0) filters.add('volume=${profile.preampDb}dB');
  // Apple's bundled FFmpeg omits bass/biquad; this broad bell is supported.
  if (profile.bassDb != 0) filters.add('equalizer=f=80:t=q:w=0.5:g=${profile.bassDb}');
  for (var i = 0; i < EqualizerProfile.bandCount; i++) {
    if (profile.gains[i] != 0) {
      filters.add('equalizer=f=${AudioEqualizer.frequencies[i]}:t=q:w=1.414:g=${profile.gains[i]}');
    }
  }
  return '@$equalizerFilterLabel:lavfi=[${filters.join(',')}]';
}
