import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left column
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSection(Symbols.videocam_rounded, 'Video', [
                  _metric('Codec', _stats.videoCodec ?? 'N/A'),
                  _metric('Resolution', _stats.resolution),
                  if (_stats.hasValidVideoFps) _metric('FPS', _stats.videoFpsFormatted),
                  if (_stats.hasValidVideoBitrate) _metric('Bitrate', _stats.videoBitrateFormatted),
                  _metric('Decoder', _stats.hwdecFormatted),
                  if (_stats.aspectName != null && _stats.aspectName!.isNotEmpty) _metric('Aspect', _stats.aspectName!),
                  if (_stats.rotate != null && _stats.rotate != 0) _metric('Rotation', _stats.rotateFormatted),
                ]),
                // Color section - MPV only (ExoPlayer doesn't provide this info)
                if (isMpv) ...[
                  const SizedBox(height: 12),
                  _buildSection(Symbols.palette_rounded, 'Color', [
                    _metric('Pixel Fmt', _stats.pixelformat ?? 'N/A'),
                    if (_stats.hwPixelformat != null && _stats.hwPixelformat != _stats.pixelformat)
                      _metric('HW Fmt', _stats.hwPixelformat!),
                    _metric('Matrix', _stats.colormatrix ?? 'N/A'),
                    _metric('Primaries', _stats.primaries ?? 'N/A'),
                    _metric('Transfer', _stats.gamma ?? 'N/A'),
                  ]),
                ],
                if (_stats.hasHdrMetadata) ...[
                  const SizedBox(height: 12),
                  _buildSection(Symbols.hdr_on_rounded, 'HDR', [
                    if (_stats.maxLuma != null) _metric('Max Luma', _stats.maxLumaFormatted),
                    if (_stats.minLuma != null) _metric('Min Luma', _stats.minLumaFormatted),
                    if (_stats.maxCll != null) _metric('MaxCLL', _stats.maxCllFormatted),
                    if (_stats.maxFall != null) _metric('MaxFALL', _stats.maxFallFormatted),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSection(Symbols.volume_up_rounded, 'Audio', [
                  if (_stats.audioCodec != null) _metric('Codec', _stats.audioCodec!),
                  _metric('Sample Rate', _stats.sampleRateFormatted),
                  _metric('Channels', _stats.audioChannels ?? 'N/A'),
                  if (_stats.hasValidAudioBitrate) _metric('Bitrate', _stats.audioBitrateFormatted),
                ]),
                const SizedBox(height: 12),
                _buildSection(Symbols.speed_rounded, 'Performance', [
                  if (isMpv) _metric('Render FPS', _stats.actualFpsFormatted),
                  if (isMpv) _metric('Display FPS', _stats.displayFpsFormatted),
                  if (isMpv) _metric('A/V Sync', _stats.avsyncFormatted),
                  _metric('Dropped', _stats.droppedFramesFormatted),
                ]),
                const SizedBox(height: 12),
                _buildSection(Symbols.memory_rounded, 'Buffer', [
                  _metric('Duration', _stats.cacheDurationFormatted),
                  if (isMpv) _metric('Cache Used', _stats.cacheUsedFormatted),
                  if (isMpv) _metric('Speed', _stats.cacheSpeedFormatted),
                ]),
                const SizedBox(height: 12),
                _buildSection(Symbols.apps_rounded, 'App', [
                  _metric('Player', _stats.playerTypeFormatted),
                  _metric('Memory', _stats.appMemoryFormatted),
                  _metric('UI FPS', _stats.uiFpsFormatted),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, List<_Metric> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, fill: 1, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${metric.label}: ', style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Flexible(
            child: Text(
              metric.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
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
