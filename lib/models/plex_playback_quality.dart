enum PlexPlaybackQualityMode { auto, original, custom }

class PlexPlaybackQualityOption {
  final String id;
  final PlexPlaybackQualityMode mode;
  final String title;
  final String subtitle;
  final int? maxVideoBitrate;
  final int? peakBitrate;
  final int? videoBitrate;
  final int? videoQuality;
  final String? videoResolution;
  final bool autoAdjustQuality;
  final String protocol;

  const PlexPlaybackQualityOption({
    required this.id,
    required this.mode,
    required this.title,
    this.subtitle = '',
    this.maxVideoBitrate,
    this.peakBitrate,
    this.videoBitrate,
    this.videoQuality,
    this.videoResolution,
    this.autoAdjustQuality = false,
    this.protocol = 'hls',
  });

  const PlexPlaybackQualityOption.auto()
    : id = 'auto',
      mode = PlexPlaybackQualityMode.auto,
      title = 'Auto',
      subtitle = 'Adjust automatically',
      maxVideoBitrate = null,
      peakBitrate = null,
      videoBitrate = null,
      videoQuality = null,
      videoResolution = null,
      autoAdjustQuality = true,
      protocol = 'hls';

  const PlexPlaybackQualityOption.original()
    : id = 'original',
      mode = PlexPlaybackQualityMode.original,
      title = 'Original',
      subtitle = 'Play original quality',
      maxVideoBitrate = null,
      peakBitrate = null,
      videoBitrate = null,
      videoQuality = null,
      videoResolution = null,
      autoAdjustQuality = false,
      protocol = 'hls';

  bool get isAuto => mode == PlexPlaybackQualityMode.auto;
  bool get isOriginal => mode == PlexPlaybackQualityMode.original;

  String get displayLabel => subtitle.isEmpty ? title : '$title ($subtitle)';

  PlexPlaybackQualityOption copyWith({
    String? id,
    PlexPlaybackQualityMode? mode,
    String? title,
    String? subtitle,
    int? maxVideoBitrate,
    int? peakBitrate,
    int? videoBitrate,
    int? videoQuality,
    String? videoResolution,
    bool? autoAdjustQuality,
    String? protocol,
  }) {
    return PlexPlaybackQualityOption(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      maxVideoBitrate: maxVideoBitrate ?? this.maxVideoBitrate,
      peakBitrate: peakBitrate ?? this.peakBitrate,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      videoQuality: videoQuality ?? this.videoQuality,
      videoResolution: videoResolution ?? this.videoResolution,
      autoAdjustQuality: autoAdjustQuality ?? this.autoAdjustQuality,
      protocol: protocol ?? this.protocol,
    );
  }

  static List<PlexPlaybackQualityOption> fallbackOptions() {
    return const [
      PlexPlaybackQualityOption.original(),
      PlexPlaybackQualityOption(
        id: 'custom-20000-1920x1080',
        mode: PlexPlaybackQualityMode.custom,
        title: '1080p',
        subtitle: '20 Mbps',
        maxVideoBitrate: 20000,
        peakBitrate: 20000,
        videoBitrate: 20000,
        videoResolution: '1920x1080',
      ),
      PlexPlaybackQualityOption(
        id: 'custom-12000-1920x1080',
        mode: PlexPlaybackQualityMode.custom,
        title: '1080p',
        subtitle: '12 Mbps',
        maxVideoBitrate: 12000,
        peakBitrate: 12000,
        videoBitrate: 12000,
        videoResolution: '1920x1080',
      ),
      PlexPlaybackQualityOption(
        id: 'custom-8000-1920x1080',
        mode: PlexPlaybackQualityMode.custom,
        title: '1080p',
        subtitle: '8 Mbps',
        maxVideoBitrate: 8000,
        peakBitrate: 8000,
        videoBitrate: 8000,
        videoResolution: '1920x1080',
      ),
      PlexPlaybackQualityOption(
        id: 'custom-4000-1280x720',
        mode: PlexPlaybackQualityMode.custom,
        title: '720p',
        subtitle: '4 Mbps',
        maxVideoBitrate: 4000,
        peakBitrate: 4000,
        videoBitrate: 4000,
        videoResolution: '1280x720',
      ),
      PlexPlaybackQualityOption(
        id: 'custom-2000-854x480',
        mode: PlexPlaybackQualityMode.custom,
        title: '480p',
        subtitle: '2 Mbps',
        maxVideoBitrate: 2000,
        peakBitrate: 2000,
        videoBitrate: 2000,
        videoResolution: '854x480',
      ),
    ];
  }

  static List<PlexPlaybackQualityOption> fromIdentity(Map<String, dynamic>? identity) {
    final base = <PlexPlaybackQualityOption>[const PlexPlaybackQualityOption.original()];
    if (identity == null) {
      return fallbackOptions();
    }

    final bitrates = _splitCsv(identity['transcoderVideoBitrates']);
    final qualities = _splitCsv(identity['transcoderVideoQualities']);
    final resolutions = _splitCsv(identity['transcoderVideoResolutions']);
    if (bitrates.isEmpty || resolutions.isEmpty) {
      return fallbackOptions();
    }

    final options = <PlexPlaybackQualityOption>[];
    final seen = <String>{};
    final count = [bitrates.length, resolutions.length, qualities.length].reduce((a, b) => a < b ? a : b);

    for (int index = count - 1; index >= 0; index--) {
      final bitrate = int.tryParse(bitrates[index]);
      final resolution = int.tryParse(resolutions[index]);
      if (bitrate == null || resolution == null || bitrate <= 0 || resolution <= 0) {
        continue;
      }

      final videoResolution = _resolutionStringForHeight(resolution);
      final id = 'custom-$bitrate-$videoResolution';
      if (!seen.add(id)) continue;

      options.add(
        PlexPlaybackQualityOption(
          id: id,
          mode: PlexPlaybackQualityMode.custom,
          title: '${resolution}p',
          subtitle: _formatBitrate(bitrate),
          maxVideoBitrate: bitrate,
          peakBitrate: bitrate,
          videoBitrate: bitrate,
          videoQuality: index < qualities.length ? int.tryParse(qualities[index]) : null,
          videoResolution: videoResolution,
        ),
      );
    }

    if (options.isEmpty) {
      return fallbackOptions();
    }

    return [...base, ...options];
  }

  static PlexPlaybackQualityOption matchAgainst(
    List<PlexPlaybackQualityOption> options,
    PlexPlaybackQualityOption? requested,
  ) {
    if (requested == null) {
      return options.firstWhere(
        (option) => option.isOriginal,
        orElse: () => const PlexPlaybackQualityOption.original(),
      );
    }

    for (final option in options) {
      if (option.id == requested.id) return option;
    }

    if (requested.isAuto) {
      return options.firstWhere(
        (option) => option.isOriginal,
        orElse: () => const PlexPlaybackQualityOption.original(),
      );
    }

    if (requested.isOriginal) {
      return options.firstWhere(
        (option) => option.isOriginal,
        orElse: () => const PlexPlaybackQualityOption.original(),
      );
    }

    for (final option in options) {
      if (option.mode != PlexPlaybackQualityMode.custom) continue;
      if (option.maxVideoBitrate == requested.maxVideoBitrate && option.videoResolution == requested.videoResolution) {
        return option;
      }
    }

    return options.firstWhere(
      (option) => option.isOriginal,
      orElse: () => const PlexPlaybackQualityOption.original(),
    );
  }

  static List<String> _splitCsv(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty) return const [];
    return value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  static String _formatBitrate(int bitrateKbps) {
    if (bitrateKbps >= 1000) {
      final mbps = bitrateKbps / 1000;
      final decimals = bitrateKbps % 1000 == 0 ? 0 : 1;
      return '${mbps.toStringAsFixed(decimals)} Mbps';
    }
    return '$bitrateKbps kbps';
  }

  static String _resolutionStringForHeight(int height) {
    return switch (height) {
      <= 240 => '426x240',
      <= 360 => '640x360',
      <= 480 => '854x480',
      <= 576 => '1024x576',
      <= 720 => '1280x720',
      _ => '1920x1080',
    };
  }
}
