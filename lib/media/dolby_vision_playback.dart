/// Evidence about the enhancement layer, independent of the decoder name and
/// the display's HDR/Dolby Vision badge. A P7 decoder advertisement proves none
/// of these: some native decoders consume only BL + RPU.
enum DolbyVisionLayerUse { unknown, discarded }

/// Normalizes the existing native reports without turning a requested route
/// into a claim about rendered pixels. No platform is assumed FEL-capable.
class DolbyVisionPlayback {
  final int? profile;
  final DolbyVisionLayerUse enhancement;

  const DolbyVisionPlayback({this.profile, this.enhancement = DolbyVisionLayerUse.unknown});

  factory DolbyVisionPlayback.fromStats(Map<String, dynamic> stats) {
    final rawProfile = stats['dvSourceProfile'];
    final profile = rawProfile is int ? rawProfile : int.tryParse(rawProfile?.toString() ?? '');
    final route = stats['dvRoute'] as String?;
    final converting = stats['dvConversionActive'] == true;
    final mode = stats['dvConversionMode'];
    // These are known destructive routes in the bundled Android backends.
    // gpu-next/"reshaped" alone is insufficient: the old engine reshapes BL
    // while the experimental engine can also compose EL.
    final discarded =
        profile == 7 &&
        (route == 'dv-decoder-p81' ||
            route == 'base-layer' ||
            (converting && (mode == 'DV81' || mode == 'HEVC_STRIP')));
    return DolbyVisionPlayback(
      profile: profile,
      enhancement: discarded ? DolbyVisionLayerUse.discarded : DolbyVisionLayerUse.unknown,
    );
  }

  /// Technical notation appended to the existing playback-path row. No
  /// positive reconstruction label is synthesized from a native decoder,
  /// software renderer, profile conversion, or source metadata.
  String get layerNotation => profile != 7
      ? ''
      : switch (enhancement) {
          DolbyVisionLayerUse.discarded => 'BL / EL−',
          DolbyVisionLayerUse.unknown => 'BL / EL?',
        };
}
