/// The interpolation path requested by a device-local playback preference.
enum MotionProcessingMode { off, mpv, neural }

extension MotionProcessingModeSettings on MotionProcessingMode {
  bool get usesMpvInterpolation => this == MotionProcessingMode.mpv;

  bool get usesNeuralInterpolation => this == MotionProcessingMode.neural;
}

/// Neural interpolation intensity tiers, applied by a neural provider when
/// one is available on the active playback path.
enum NeuralInterpolationPreset { performance, balanced, quality }

/// The provider the active playback path can actually use for a request.
enum MotionProcessingProvider { off, mpv, neural }

/// Why the requested provider resolved to a different processing path.
enum MotionProcessingFallback {
  neuralUnavailable,
  rendererUnavailable,
  livePlayback,
  unsupportedStream,
  powerLimited,
  thermalLimited,
}

/// Result of resolving a user's motion-processing request against live
/// playback capabilities.
final class MotionProcessingResolution {
  final MotionProcessingMode requested;
  final NeuralInterpolationPreset? requestedPreset;
  final MotionProcessingProvider provider;
  final MotionProcessingFallback? fallback;

  const MotionProcessingResolution({
    required this.requested,
    required this.provider,
    this.requestedPreset,
    this.fallback,
  });

  MotionProcessingMode get effectiveMode => switch (provider) {
    MotionProcessingProvider.off => MotionProcessingMode.off,
    MotionProcessingProvider.mpv => MotionProcessingMode.mpv,
    MotionProcessingProvider.neural => MotionProcessingMode.neural,
  };

  bool get usesMpvInterpolation => provider == MotionProcessingProvider.mpv;
}

/// Resolves a requested mode to a provider available on the active output.
/// Neural uses a connected native/model provider, then MPV resampling where
/// available; unsupported paths resolve to Off.
MotionProcessingResolution resolveMotionProcessing({
  required MotionProcessingMode requested,
  required bool mpvRendererAvailable,
  bool neuralProviderAvailable = false,
  bool isLive = false,
  bool streamSupported = true,
  bool neuralPowerLimited = false,
  bool neuralThermalLimited = false,
  NeuralInterpolationPreset neuralPreset = NeuralInterpolationPreset.balanced,
}) {
  if (isLive && requested != MotionProcessingMode.off) {
    return MotionProcessingResolution(
      requested: requested,
      requestedPreset: requested == MotionProcessingMode.neural ? neuralPreset : null,
      provider: MotionProcessingProvider.off,
      fallback: MotionProcessingFallback.livePlayback,
    );
  }

  if (requested != MotionProcessingMode.off && !streamSupported) {
    return MotionProcessingResolution(
      requested: requested,
      requestedPreset: requested == MotionProcessingMode.neural ? neuralPreset : null,
      provider: MotionProcessingProvider.off,
      fallback: MotionProcessingFallback.unsupportedStream,
    );
  }

  if (requested == MotionProcessingMode.neural && neuralPowerLimited) {
    return MotionProcessingResolution(
      requested: requested,
      requestedPreset: neuralPreset,
      provider: mpvRendererAvailable ? MotionProcessingProvider.mpv : MotionProcessingProvider.off,
      fallback: MotionProcessingFallback.powerLimited,
    );
  }

  if (requested == MotionProcessingMode.neural && neuralThermalLimited) {
    return MotionProcessingResolution(
      requested: requested,
      requestedPreset: neuralPreset,
      provider: mpvRendererAvailable ? MotionProcessingProvider.mpv : MotionProcessingProvider.off,
      fallback: MotionProcessingFallback.thermalLimited,
    );
  }

  switch (requested) {
    case MotionProcessingMode.off:
      return MotionProcessingResolution(requested: requested, provider: MotionProcessingProvider.off);
    case MotionProcessingMode.mpv:
      return mpvRendererAvailable
          ? MotionProcessingResolution(requested: requested, provider: MotionProcessingProvider.mpv)
          : MotionProcessingResolution(
              requested: requested,
              provider: MotionProcessingProvider.off,
              fallback: MotionProcessingFallback.rendererUnavailable,
            );
    case MotionProcessingMode.neural:
      if (neuralProviderAvailable) {
        return MotionProcessingResolution(
          requested: requested,
          requestedPreset: neuralPreset,
          provider: MotionProcessingProvider.neural,
        );
      }
      return mpvRendererAvailable
          ? MotionProcessingResolution(
              requested: requested,
              requestedPreset: neuralPreset,
              provider: MotionProcessingProvider.mpv,
              fallback: MotionProcessingFallback.neuralUnavailable,
            )
          : MotionProcessingResolution(
              requested: requested,
              requestedPreset: neuralPreset,
              provider: MotionProcessingProvider.off,
              fallback: MotionProcessingFallback.rendererUnavailable,
            );
  }
}
