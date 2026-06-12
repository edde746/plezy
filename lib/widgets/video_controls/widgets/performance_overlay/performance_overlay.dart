import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../mpv/mpv.dart';
import '../../../../widgets/app_icon.dart';
import 'performance_stats.dart';
import 'performance_stats_service.dart';

/// A toggleable overlay displaying real-time video player performance statistics.
///
/// Shows a single card with two columns of metrics organized by section.
/// Positioned in the top-left corner of the video player.
class PlayerPerformanceOverlay extends StatefulWidget {
  final Player player;

  const PlayerPerformanceOverlay({super.key, required this.player});

  @override
  State<PlayerPerformanceOverlay> createState() => _PlayerPerformanceOverlayState();
}

class _PlayerPerformanceOverlayState extends State<PlayerPerformanceOverlay> {
  late final PerformanceStatsService _statsService;
  PerformanceStats _stats = const PerformanceStats.empty();

  @override
  void initState() {
    super.initState();
    _statsService = PerformanceStatsService(widget.player);
    _statsService.statsStream.listen((stats) {
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    });
    _statsService.startPolling();
  }

  @override
  void dispose() {
    _statsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMpv = _stats.playerType == 'mpv';

    final sections = <Widget>[
      _buildSection(Symbols.videocam_rounded, t.fileInfo.video, [
        _metric(t.fileInfo.codec, _stats.videoCodec ?? 'N/A'),
        _metric(t.fileInfo.resolution, _stats.resolution),
        if (_stats.hasValidVideoFps) _metric('FPS', _stats.videoFpsFormatted),
        if (_stats.hasValidVideoBitrate) _metric(t.fileInfo.bitrate, _stats.videoBitrateFormatted),
        _metric(t.performanceOverlay.decoder, _stats.hwdecFormatted),
        if (!isMpv && _stats.videoDecoderName != null) _metric(t.performanceOverlay.rawDecoder, _stats.videoDecoderRaw),
        if (!isMpv) _metric(t.performanceOverlay.tunneling, _stats.tunneledPlaybackFormatted),
        if (_stats.aspectName != null && _stats.aspectName!.isNotEmpty)
          _metric(t.performanceOverlay.aspect, _stats.aspectName!),
        if (_stats.rotate != null && _stats.rotate != 0) _metric(t.performanceOverlay.rotation, _stats.rotateFormatted),
        if (_stats.dvSourceProfile != null) _metric(t.performanceOverlay.dvSource, _stats.dvSourceProfileFormatted),
        if (_stats.dvPlaybackPath != null) _metric(t.performanceOverlay.dvPath, _stats.dvPlaybackPathFormatted),
        if (_stats.dvConversionActive) _metric(t.performanceOverlay.p7Conversion, _stats.dvConversionFormatted),
      ]),
      _buildSection(Symbols.volume_up_rounded, t.fileInfo.audio, [
        if (_stats.audioCodec != null) _metric(t.fileInfo.codec, _stats.audioCodec!),
        _metric(t.performanceOverlay.sampleRate, _stats.sampleRateFormatted),
        _metric(t.fileInfo.channels, _stats.audioChannels ?? 'N/A'),
        if (_stats.hasValidAudioBitrate) _metric(t.fileInfo.bitrate, _stats.audioBitrateFormatted),
        if (!isMpv && _stats.audioDecoderName != null)
          _metric(t.performanceOverlay.decoder, _stats.audioDecoderFormatted),
      ]),
      if (isMpv)
        _buildSection(Symbols.palette_rounded, t.performanceOverlay.color, [
          _metric(t.performanceOverlay.pixelFormat, _stats.pixelformat ?? 'N/A'),
          if (_stats.hwPixelformat != null && _stats.hwPixelformat != _stats.pixelformat)
            _metric(t.performanceOverlay.hwFormat, _stats.hwPixelformat!),
          _metric(t.performanceOverlay.matrix, _stats.colormatrix ?? 'N/A'),
          _metric(t.performanceOverlay.primaries, _stats.primaries ?? 'N/A'),
          _metric(t.performanceOverlay.transfer, _stats.gamma ?? 'N/A'),
        ]),
      _buildSection(Symbols.speed_rounded, t.performanceOverlay.performance, [
        if (isMpv) _metric(t.performanceOverlay.renderFps, _stats.actualFpsFormatted),
        if (isMpv) _metric(t.performanceOverlay.displayFps, _stats.displayFpsFormatted),
        if (isMpv) _metric(t.performanceOverlay.avSync, _stats.avsyncFormatted),
        _metric(t.performanceOverlay.dropped, _stats.droppedFramesFormatted),
        if (_stats.dvConversionActive) _metric(t.performanceOverlay.dvRpus, _stats.dvRpuCountFormatted),
        if (_stats.dvConversionActive) _metric(t.performanceOverlay.dvRpuAverage, _stats.dvAvgRpuConversionFormatted),
        if (_stats.dvConversionActive)
          _metric(t.performanceOverlay.dvSampleAverage, _stats.dvAvgSampleProcessingFormatted),
      ]),
      if (_stats.hasHdrMetadata)
        _buildSection(Symbols.hdr_on_rounded, 'HDR', [
          if (_stats.maxLuma != null) _metric(t.performanceOverlay.maxLuma, _stats.maxLumaFormatted),
          if (_stats.minLuma != null) _metric(t.performanceOverlay.minLuma, _stats.minLumaFormatted),
          if (_stats.maxCll != null) _metric(t.performanceOverlay.maxCll, _stats.maxCllFormatted),
          if (_stats.maxFall != null) _metric(t.performanceOverlay.maxFall, _stats.maxFallFormatted),
        ]),
      _buildSection(Symbols.memory_rounded, t.performanceOverlay.buffer, [
        _metric(t.fileInfo.duration, _stats.cacheDurationFormatted),
        if (isMpv) _metric(t.performanceOverlay.cacheUsed, _stats.cacheUsedFormatted),
        if (isMpv) _metric(t.performanceOverlay.speed, _stats.cacheSpeedFormatted),
      ]),
      _buildSection(Symbols.apps_rounded, t.performanceOverlay.app, [
        _metric(t.performanceOverlay.player, _stats.playerTypeFormatted),
        _metric(t.performanceOverlay.memory, _stats.appMemoryFormatted),
        _metric(t.performanceOverlay.uiFps, _stats.uiFpsFormatted),
      ]),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
      ),
      child: Wrap(spacing: 24, runSpacing: 12, children: sections),
    );
  }

  Widget _buildSection(IconData icon, String title, List<_Metric> metrics) {
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Row(
          mainAxisSize: .min,
          children: [
            AppIcon(icon, fill: 1, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: .w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...metrics.map(_buildMetricRow),
      ],
    );
  }

  Widget _buildMetricRow(_Metric metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: .min,
        children: [
          Text('${metric.label}: ', style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Flexible(
            child: Text(
              metric.value,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: .w500, fontFamily: 'monospace'),
              overflow: .ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _Metric _metric(String label, String value) => _Metric(label, value);
}

class _Metric {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
}
