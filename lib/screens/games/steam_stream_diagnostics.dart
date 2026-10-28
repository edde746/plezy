import 'dart:async';

import 'package:flutter/material.dart';

import '../../games/steam_stream_metrics.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/dialog_action_button.dart';

/// Measurements are polled only while this dialog is visible. Nothing is sent
/// to analytics or retained in a profile. Unknown/old native modules stay usable.
class SteamStreamDiagnostics extends StatefulWidget {
  const SteamStreamDiagnostics({super.key, required this.readMetrics});
  final Future<SteamStreamMetrics?> Function() readMetrics;

  @override
  State<SteamStreamDiagnostics> createState() => _SteamStreamDiagnosticsState();
}

class _SteamStreamDiagnosticsState extends State<SteamStreamDiagnostics> {
  Timer? _timer;
  SteamStreamMetrics? _metrics;
  SteamStreamRates? _rates;
  bool _reading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_read()));
  }

  Future<void> _read() async {
    if (_reading) return;
    _reading = true;
    try {
      final next = await widget.readMetrics().timeout(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _rates = next != null && _metrics != null ? SteamStreamRates.between(_metrics!, next) : null;
        _metrics = next;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _metrics = null;
          _rates = null;
        });
      }
    } finally {
      _reading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label\n', style: Theme.of(context).textTheme.labelLarge),
          TextSpan(text: value),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final m = _metrics, r = _rates;
    final reasons = m == null
        ? <String>[]
        : [
            if ((m.hostFpsReasons & 0x07) != 0) t.games.streamLimitHost,
            if ((m.hostFpsReasons & 0x08) != 0) t.games.streamLimitNetwork,
            if ((m.hostFpsReasons & 0x10) != 0) t.games.streamLimitDecoder,
            if ((m.hostFpsReasons & 0x40) != 0) t.games.streamLimitBurst,
          ];
    return AlertDialog(
      title: Text(t.games.streamDetails),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.games.streamFeedbackHelp),
          if (m == null)
            _row(t.games.streamMeasurements, t.games.streamMeasurementsUnavailable)
          else ...[
            if (m.codec != null && m.width > 0 && m.height > 0)
              _row(t.games.streamVideo, '${m.codec} · ${m.width} × ${m.height}'),
            _row(t.games.streamDecoder, switch (m.decoderKind) {
              1 => t.games.streamHardwareDecoder,
              2 => t.games.streamSoftwareDecoder,
              3 => t.games.streamReadbackDecoder,
              4 => t.games.streamMetalDecoder,
              _ => t.games.streamMeasurementsUnavailable,
            }),
            if (m.chromaFormat != 0) _row(t.games.streamChroma, m.chromaFormat == 2 ? '4:4:4' : '4:2:0'),
            if (m.hostFps != null) _row(t.games.streamHostFps, '${m.hostFps!.toStringAsFixed(1)} fps'),
            if (m.hostMbps != null) _row(t.games.streamHostBitrate, '${m.hostMbps!.toStringAsFixed(1)} Mbps'),
            if (reasons.isNotEmpty) _row(t.games.streamLimits, reasons.join(' · ')),
            if (r != null) ...[
              _row(t.games.streamPresentedFps, '${r.presentedFps.toStringAsFixed(1)} fps'),
              _row(t.games.streamReceivedBitrate, '${r.videoMbps.toStringAsFixed(1)} Mbps'),
              if (r.completionMs != null)
                _row(t.games.streamCompletionTime, '${r.completionMs!.toStringAsFixed(1)} ms'),
            ],
            _row(t.games.streamDroppedFrames, '${m.droppedFrames}'),
            _row(t.games.streamVideoQueue, '${m.videoQueue} / 4'),
            _row(t.games.streamAudioQueue, '${m.audioQueue} / 8'),
            if (m.audioChannels > 0) _row(t.games.streamAudioChannels, '${m.audioChannels}'),
            _row(t.games.streamInputBacklog, '${m.hidPending} + ${m.hidInFlight}'),
            _row(t.games.streamReliableRetries, '${m.reliableRetries}'),
            _row(t.games.streamReliableGiveUps, '${m.reliableGiveUps}'),
            _row(t.games.streamMaxAck, '${m.maxAckLatencyMs} ms'),
            const SizedBox(height: 12),
            Text(t.games.streamMeasurementsHelp),
          ],
        ],
      ),
      actions: [DialogActionButton(label: t.common.close, onPressed: () => Navigator.pop(context))],
    );
  }
}
