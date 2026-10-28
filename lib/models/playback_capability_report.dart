/// Runtime facts about the active video decode, processing, and presentation
/// path. Values describe the current playback session; a missing value means
/// the backend did not report it.
final class PlaybackCapabilityReport {
  final String playerType;
  final String? videoOutput;
  final String? hardwareDecoder;
  final String? pixelFormat;
  /// Coded source dimensions; presentation transforms are not applied.
  final int? sourceWidth;
  final int? sourceHeight;
  /// Tri-state source classification. Null means the backend could not report it.
  final bool? sourceIsHdr;
  /// Source Dolby Vision profile; null means no profile was reported.
  final int? dolbyVisionProfile;
  final double? sourceFps;
  final double? displayFps;
  final double? renderedFps;
  final int? droppedFrames;
  final int? decoderDroppedFrames;
  final bool? rendererInterpolationActive;
  final String? nativeInterpolationStatus;
  /// Platform thermal-pressure tier reported for this playback session.
  final String? thermalStatus;

  /// A model provider is available when its session is ready to execute.
  /// This is separate from [neuralOutputObserved], which records generated
  /// output and prevents readiness from being reported as active inference.
  final bool neuralProviderReady;
  final String? neuralProvider;
  final String? neuralProviderVendor;

  /// Provider-reported mode (for example, QNN HTP power mode). Null means
  /// the runtime did not confirm a mode or it does not apply to the provider.
  final String? neuralPowerMode;
  final bool neuralOutputObserved;
  final double? neuralInferenceP95Ms;
  final int? neuralGeneratedFrames;
  final int? neuralSourceFrames;
  final int? neuralSceneCutBypasses;
  final int? neuralDeadlineMisses;
  final String? neuralDeadlineGovernor;
  final int? neuralDeadlineBackoffs;
  final int? neuralDeadlineBypassFrames;
  final String? neuralGpuProvider;
  final bool imageEnhancementConfigured;
  final String? imageEnhancementProvider;
  final String? imageEnhancementStatus;

  const PlaybackCapabilityReport({
    required this.playerType,
    this.videoOutput,
    this.hardwareDecoder,
    this.pixelFormat,
    this.sourceWidth,
    this.sourceHeight,
    this.sourceIsHdr,
    this.dolbyVisionProfile,
    this.sourceFps,
    this.displayFps,
    this.renderedFps,
    this.droppedFrames,
    this.decoderDroppedFrames,
    this.rendererInterpolationActive,
    this.nativeInterpolationStatus,
    this.thermalStatus,
    this.neuralProviderReady = false,
    this.neuralProvider,
    this.neuralProviderVendor,
    this.neuralPowerMode,
    this.neuralOutputObserved = false,
    this.neuralInferenceP95Ms,
    this.neuralGeneratedFrames,
    this.neuralSourceFrames,
    this.neuralSceneCutBypasses,
    this.neuralDeadlineMisses,
    this.neuralDeadlineGovernor,
    this.neuralDeadlineBackoffs,
    this.neuralDeadlineBypassFrames,
    this.neuralGpuProvider,
    this.imageEnhancementConfigured = false,
    this.imageEnhancementProvider,
    this.imageEnhancementStatus,
  });

  /// True only when the report contains evidence that this session has
  /// produced neural frames, not merely loaded a model or selected a mode.
  bool get hasObservedNeuralOutput =>
      neuralOutputObserved || (neuralGeneratedFrames != null && neuralGeneratedFrames! > 0);
}
