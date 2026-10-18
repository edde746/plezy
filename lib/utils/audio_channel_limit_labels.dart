import '../i18n/strings.g.dart';
import '../models/audio_channel_limit.dart';

/// User-facing name of an [AudioChannelLimit].
String audioChannelLimitLabel(AudioChannelLimit limit) => switch (limit) {
  AudioChannelLimit.original => t.settings.audioChannelLimitOriginal,
  AudioChannelLimit.surround51 => t.settings.audioChannelLimitSurround51,
  AudioChannelLimit.stereo => t.settings.audioChannelLimitStereo,
};

/// What choosing [limit] does, for the option lists.
String audioChannelLimitDescription(AudioChannelLimit limit) => switch (limit) {
  AudioChannelLimit.original => t.settings.audioChannelLimitOriginalDescription,
  AudioChannelLimit.surround51 => t.settings.audioChannelLimitSurround51Description,
  AudioChannelLimit.stereo => t.settings.audioChannelLimitStereoDescription,
};
