/// Profiles for PlezyNG's optional motion-processing paths.
///
/// Motion-compensated profiles synthesize frames at the configured output
/// cadence. OLED selects the current display cadence and motion compensation
/// when available; it can reduce sample-and-hold blur, but full-rate synthesis
/// may change film motion and panel-specific behavior still varies. No engine
/// recovers detail that was blurred into the source.
enum MotionClarityPreset {
  original,
  cinema,
  balanced,
  smooth,
  animation,
  sports,
  oled,
  custom;

  bool get interpolationEnabled => this != MotionClarityPreset.original;

  MotionTemporalKernel get defaultKernel => switch (this) {
    MotionClarityPreset.original || MotionClarityPreset.cinema || MotionClarityPreset.oled => MotionTemporalKernel.oversample,
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

/// Processing backend. Motion-compensated mode uses FFmpeg's libavfilter
/// minterpolate block-motion synthesis and is experimental; it is CPU-heavy and
/// may fall back to temporal blending when the active mpv build or rate is
/// unavailable.
enum MotionClarityEngine { temporalBlend, motionCompensated }

/// Motion-search cost for FFmpeg's experimental motion-compensated engine.
/// Higher tiers perform more expensive block searches; none changes the
/// amount of interpolation or guarantees a particular visual result.
enum MotionClarityMciQuality {
  fast,
  balanced,
  high;

  String get ffmpegOptions => switch (this) {
    MotionClarityMciQuality.fast => 'mc_mode=obmc:me_mode=bilat:me=epzs:search_param=16:vsbmc=0',
    MotionClarityMciQuality.balanced => 'mc_mode=aobmc:me_mode=bidir:me=epzs:search_param=32:vsbmc=1',
    MotionClarityMciQuality.high => 'mc_mode=aobmc:me_mode=bidir:me=umh:search_param=48:vsbmc=1',
  };
}

/// Target cadence for the optional motion-compensated engine.
enum MotionClarityOutputRate {
  currentDisplay,
  fps48,
  fps50,
  fps60,
  fps72,
  fps90,
  fps100,
  fps120,
  fps144;

  double? resolve(double? displayFps) => switch (this) {
    MotionClarityOutputRate.currentDisplay => displayFps,
    MotionClarityOutputRate.fps48 => 48,
    MotionClarityOutputRate.fps50 => 50,
    MotionClarityOutputRate.fps60 => 60,
    MotionClarityOutputRate.fps72 => 72,
    MotionClarityOutputRate.fps90 => 90,
    MotionClarityOutputRate.fps100 => 100,
    MotionClarityOutputRate.fps120 => 120,
    MotionClarityOutputRate.fps144 => 144,
  };
}
