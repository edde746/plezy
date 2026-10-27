/// The interpolation path requested by a device-local playback preference.
///
/// Neural interpolation is presented separately and remains unavailable until
/// a runtime, model, and frame path pass platform qualification.
enum MotionProcessingMode { off, mpv, neural }

extension MotionProcessingModeSettings on MotionProcessingMode {
  bool get usesMpvInterpolation => this == MotionProcessingMode.mpv;

  bool get usesNeuralInterpolation => this == MotionProcessingMode.neural;
}

/// Neural interpolation intensity tiers. A tier is only selectable when a
/// qualified neural runtime and playback path are available.
enum NeuralInterpolationPreset { performance, balanced, quality }
