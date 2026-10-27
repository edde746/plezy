/// User-facing motion profiles backed by mpv's temporal renderer interpolation.
///
/// These profiles improve cadence handling by filtering across time. They do
/// not estimate object motion or recover detail that was blurred into the source.
enum MotionClarityPreset {
  original,
  cinema,
  balanced,
  smooth,
  animation,
  sports,
  custom;

  bool get interpolationEnabled => this != MotionClarityPreset.original;

  MotionTemporalKernel get defaultKernel => switch (this) {
    MotionClarityPreset.original || MotionClarityPreset.cinema => MotionTemporalKernel.oversample,
    MotionClarityPreset.balanced => MotionTemporalKernel.linear,
    MotionClarityPreset.smooth || MotionClarityPreset.sports => MotionTemporalKernel.gaussian,
    MotionClarityPreset.animation => MotionTemporalKernel.mitchell,
    MotionClarityPreset.custom => MotionTemporalKernel.linear,
  };

  int get defaultThresholdPercent => 1;
}

/// mpv temporal convolution filters, ordered approximately from least to most
/// smooth. Smoother kernels blend more of neighboring frames and can look softer.
enum MotionTemporalKernel {
  oversample,
  linear,
  catmullRom,
  mitchell,
  gaussian,
  bicubic;

  String get mpvName => switch (this) {
    MotionTemporalKernel.oversample => 'oversample',
    MotionTemporalKernel.linear => 'linear',
    MotionTemporalKernel.catmullRom => 'catmull_rom',
    MotionTemporalKernel.mitchell => 'mitchell',
    MotionTemporalKernel.gaussian => 'gaussian',
    MotionTemporalKernel.bicubic => 'bicubic',
  };
}
