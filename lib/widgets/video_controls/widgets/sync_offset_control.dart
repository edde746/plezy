import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_slider.dart';
import '../../../i18n/strings.g.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../mpv/mpv.dart';
import '../../../services/player_sync_offsets.dart';
import '../../../services/scoped_player_prefs.dart';
import '../../../services/subtitle_sync_calibration.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/latest_async_write.dart';

/// Reusable widget for adjusting sync offsets (audio or subtitle)
class SyncOffsetControl extends StatefulWidget {
  final Player player;
  final String propertyName; // 'audio-delay' or 'sub-delay'
  final String? contentIdentity;
  final int initialOffset;
  final double initialSubtitleRate;
  final Future<void> Function(double rate)? onSubtitleRateChanged;
  final Future<void> Function(int offset) onOffsetChanged;

  /// Focus node for the reset button. When provided from the parent, allows
  /// the close button's left-press to focus the reset button.
  final FocusNode? resetFocusNode;

  /// Focus node for the close button. When provided, pressing select/enter
  /// on the slider moves focus here.
  final FocusNode? closeFocusNode;

  /// Focus node for the slider. When provided, allows the parent to
  /// auto-focus the slider when the bar opens.
  final FocusNode? sliderFocusNode;

  const SyncOffsetControl({
    super.key,
    required this.player,
    required this.propertyName,
    this.contentIdentity,
    required this.initialOffset,
    this.initialSubtitleRate = 1.0,
    this.onSubtitleRateChanged,
    required this.onOffsetChanged,
    this.resetFocusNode,
    this.closeFocusNode,
    this.sliderFocusNode,
  });

  @override
  State<SyncOffsetControl> createState() => _SyncOffsetControlState();
}

final Expando<LatestAsyncWrite<String>> _syncOffsetWrites = Expando<LatestAsyncWrite<String>>();

class _SyncOffsetControlState extends State<SyncOffsetControl> {
  // Range constants
  static const double _sliderMin = -10_000; // ±10s slider range for fine control
  static const double _sliderMax = 10_000;
  static const double _absoluteMin = ScopedPlayerPrefs.minimumSyncOffsetMs * 1.0;
  static const double _absoluteMax = ScopedPlayerPrefs.maximumSyncOffsetMs * 1.0;
  // Audio gets 10ms steps, the lip-sync granularity other players offer
  // (#2620); subtitle corrections run to seconds, so they keep 50ms. The
  // slider step is also the D-pad step on TV, where the slider holds focus
  // and owns left/right; long-press keeps a 1s stride for large corrections.
  static const double _longPressStep = 1000;

  double get _step => widget.propertyName == PlayerSyncOffsets.audioProperty ? 10 : 50;
  int get _sliderDivisions => (_sliderMax - _sliderMin) ~/ _step;

  late double _currentOffset;
  late double _confirmedOffset;
  late double _currentSubtitleRate;
  late double _confirmedSubtitleRate;
  SubtitleSyncCalibration? _undoSubtitleCalibration;
  int _writeGeneration = 0;
  int _bindingGeneration = 0;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _currentOffset = widget.initialOffset.toDouble();
    _confirmedOffset = _currentOffset;
    _currentSubtitleRate = widget.initialSubtitleRate;
    _confirmedSubtitleRate = _currentSubtitleRate;
  }

  @override
  void didUpdateWidget(SyncOffsetControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bindingChanged =
        widget.player != oldWidget.player ||
        widget.propertyName != oldWidget.propertyName ||
        widget.contentIdentity != oldWidget.contentIdentity;
    final valuesChanged =
        widget.initialOffset != oldWidget.initialOffset ||
        widget.initialSubtitleRate != oldWidget.initialSubtitleRate;
    if (bindingChanged || valuesChanged) {
      final offsetMatchesCurrentIntent = widget.initialOffset == _currentOffset.round();
      final offsetIsUnchanged = widget.initialOffset == oldWidget.initialOffset;
      final rateMatchesCurrentIntent = (widget.initialSubtitleRate - _currentSubtitleRate).abs() <= 0.001;
      final rateIsUnchanged = widget.initialSubtitleRate == oldWidget.initialSubtitleRate;
      final valuesMatchCurrentIntent =
          (offsetMatchesCurrentIntent || offsetIsUnchanged) &&
          (rateMatchesCurrentIntent || rateIsUnchanged);
      ++_writeGeneration;
      ++_bindingGeneration;
      _currentOffset = widget.initialOffset.toDouble();
      _confirmedOffset = _currentOffset;
      _currentSubtitleRate = widget.initialSubtitleRate;
      _confirmedSubtitleRate = _currentSubtitleRate;
      if (bindingChanged || !valuesMatchCurrentIntent) {
        _undoSubtitleCalibration = null;
      }
    }
  }

  @override
  void dispose() {
    ++_writeGeneration;
    ++_bindingGeneration;
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _applyOffset(double offsetMs) {
    final targetPlayer = widget.player;
    final propertyName = widget.propertyName;
    final persistOffset = widget.onOffsetChanged;
    final coordinator = _syncOffsetWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin(propertyName);
    final generation = ++_writeGeneration;
    final bindingGeneration = _bindingGeneration;
    unawaited(() async {
      try {
        final committed = await coordinator.commitIfLatest(propertyName, writeToken, () async {
          // Convert milliseconds to seconds for mpv. Keep the native write and
          // persistence on the same per-player/property queue so an older
          // native write can never complete after a newer one.
          final offsetSeconds = offsetMs / 1000.0;
          await targetPlayer.setProperty(propertyName, offsetSeconds.toString());
          PlayerSyncOffsets.of(targetPlayer).recordApplied(propertyName, offsetMs.round());
          await persistOffset(offsetMs.round());
          if (mounted &&
              bindingGeneration == _bindingGeneration &&
              targetPlayer == widget.player &&
              propertyName == widget.propertyName) {
            // A write may finish successfully after a newer intent was queued.
            // Keep it as the rollback baseline without replacing the newer
            // optimistic value currently shown by the control.
            setState(() {
              _confirmedOffset = offsetMs;
              if (propertyName == PlayerSyncOffsets.subtitleProperty) {
                _undoSubtitleCalibration = null;
              }
            });
          }
        });
        if (!committed ||
            !mounted ||
            generation != _writeGeneration ||
            targetPlayer != widget.player ||
            propertyName != widget.propertyName) {
          return;
        }
      } catch (error, stackTrace) {
        appLogger.w('Failed to update playback sync offset', error: error, stackTrace: stackTrace);
        if (!mounted ||
            generation != _writeGeneration ||
            targetPlayer != widget.player ||
            propertyName != widget.propertyName) {
          return;
        }
        setState(() {
          _currentOffset = _confirmedOffset;
        });
      }
    }());
  }

  Future<void> _stepSubtitleToNow({required bool previous}) async {
    final targetPlayer = widget.player;
    final propertyName = widget.propertyName;
    if (!targetPlayer.supportsSubtitleStepSync ||
        (propertyName != PlayerSyncOffsets.subtitleProperty &&
            propertyName != PlayerSyncOffsets.secondarySubtitleProperty)) {
      return;
    }

    final persistOffset = widget.onOffsetChanged;
    final coordinator = _syncOffsetWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin(propertyName);
    final generation = ++_writeGeneration;
    final bindingGeneration = _bindingGeneration;
    var rollbackOffset = _confirmedOffset.round();

    unawaited(() async {
      try {
        final committed = await coordinator.commitIfLatest(propertyName, writeToken, () async {
          rollbackOffset = _confirmedOffset.round();
          try {
            final skip = previous ? '-1' : '1';
            final track = propertyName == PlayerSyncOffsets.secondarySubtitleProperty ? 'secondary' : 'primary';
            await targetPlayer.command(['sub-step', skip, track]);

            final rawDelay = await targetPlayer.getProperty(propertyName);
            final seconds = double.tryParse(rawDelay ?? '');
            if (seconds == null || !seconds.isFinite) {
              throw StateError('The player did not return a subtitle delay after stepping the cue.');
            }
            final offsetMs = (seconds * 1000).round();
            if (offsetMs < _absoluteMin || offsetMs > _absoluteMax) {
              throw RangeError.range(offsetMs, _absoluteMin, _absoluteMax, 'subtitleOffsetMs');
            }

            PlayerSyncOffsets.of(targetPlayer).recordApplied(propertyName, offsetMs);
            await persistOffset(offsetMs);
            _confirmedOffset = offsetMs.toDouble();
            if (propertyName == PlayerSyncOffsets.subtitleProperty) {
              _undoSubtitleCalibration = null;
            }
          } catch (_) {
            try {
              await targetPlayer.setProperty(propertyName, (rollbackOffset / 1000.0).toString());
              PlayerSyncOffsets.of(targetPlayer).recordApplied(propertyName, rollbackOffset);
            } catch (rollbackError, rollbackStackTrace) {
              appLogger.w(
                'Could not restore subtitle timing after sync failed',
                error: rollbackError,
                stackTrace: rollbackStackTrace,
              );
            }
            rethrow;
          }
        });
        if (!committed ||
            !mounted ||
            generation != _writeGeneration ||
            bindingGeneration != _bindingGeneration ||
            targetPlayer != widget.player ||
            propertyName != widget.propertyName) {
          return;
        }
        setState(() => _currentOffset = _confirmedOffset);
      } catch (error, stackTrace) {
        appLogger.w('Could not sync subtitle to the current playback time', error: error, stackTrace: stackTrace);
        if (!mounted ||
            generation != _writeGeneration ||
            bindingGeneration != _bindingGeneration ||
            targetPlayer != widget.player ||
            propertyName != widget.propertyName) {
          return;
        }
        setState(() => _currentOffset = _confirmedOffset);
      }
    }());
  }


  String _subtitleDriftText(String key) => t['videoSettings.$key'] as String;

  bool get _canUseSubtitleDriftCorrection =>
      widget.player.supportsSubtitleStepSync &&
      widget.propertyName == PlayerSyncOffsets.subtitleProperty &&
      widget.onSubtitleRateChanged != null;

  bool get _supportsSubtitleDriftCalibration {
    if (!_canUseSubtitleDriftCorrection) return false;
    final subtitle = widget.player.state.track.subtitle;
    if (subtitle == null || subtitle.id == SubtitleTrack.off.id) return false;
    final codec = subtitle.codec?.toLowerCase() ?? '';
    final imageSubtitle =
        codec.contains('pgs') ||
        codec.contains('dvd_subtitle') ||
        codec.contains('vobsub') ||
        codec.contains('dvb_subtitle') ||
        codec.contains('dvb_teletext') ||
        codec == 'xsub';
    return !imageSubtitle;
  }

  Future<void> _openSubtitleDriftCalibration() async {
    if (!_supportsSubtitleDriftCalibration) return;

    final subtitleTime1 = TextEditingController();
    final playbackTime1 = TextEditingController();
    final subtitleTime2 = TextEditingController();
    final playbackTime2 = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? failureMessage;
    var previewing = false;
    var previewApplied = false;
    var rollbackStarted = false;

    Future<void> rollbackPreviewOnce() async {
      if (!previewApplied || rollbackStarted) return;
      rollbackStarted = true;
      previewApplied = false;
      await _rollbackSubtitlePreview();
    }

    TextFormField numberField(TextEditingController controller, String labelKey, void Function(void Function()) update) {
      return TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: _subtitleDriftText(labelKey), suffixText: 's'),
        validator: (value) {
          final parsed = double.tryParse(value?.trim() ?? '');
          if (parsed == null || !parsed.isFinite || parsed < 0) return t.validationErrorEnterNumber;
          return null;
        },
        onChanged: (_) {
          if (failureMessage != null) update(() => failureMessage = null);
        },
      );
    }

    void capturePlaybackTime(TextEditingController controller) {
      final seconds = widget.player.state.position.inMicroseconds / Duration.microsecondsPerSecond;
      controller.text = formatDecimal(seconds, maximumDecimals: 3);
    }

    SubtitleSyncCalibration? readCalibration(void Function(void Function()) update) {
      if (!(formKey.currentState?.validate() ?? false)) return null;
      try {
        return SubtitleSyncCalibration.fromAnchors(
          subtitleTime1Seconds: double.parse(subtitleTime1.text.trim()),
          playbackTime1Seconds: double.parse(playbackTime1.text.trim()),
          subtitleTime2Seconds: double.parse(subtitleTime2.text.trim()),
          playbackTime2Seconds: double.parse(playbackTime2.text.trim()),
        );
      } catch (_) {
        update(() => failureMessage = _subtitleDriftText('subtitleDriftInvalidAnchors'));
        return null;
      }
    }

    final calibration = await showDialog<SubtitleSyncCalibration>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) {
          Future<void> preview() async {
            final candidate = readCalibration(updateDialog);
            if (candidate == null) return;
            updateDialog(() {
              previewing = true;
              failureMessage = null;
            });
            final succeeded = await _previewSubtitleCalibration(candidate);
            previewApplied = succeeded;
            if (!dialogContext.mounted) {
              await rollbackPreviewOnce();
              return;
            }
            updateDialog(() {
              previewing = false;
              if (!succeeded) {
                failureMessage = _subtitleDriftText('subtitleDriftPreviewFailed');
              }
            });
          }

          void submit() {
            final result = readCalibration(updateDialog);
            if (result != null) Navigator.of(dialogContext).pop(result);
          }

          return AlertDialog(
            title: Text(_subtitleDriftText('subtitleDriftCalibration')),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_subtitleDriftText('subtitleDriftCalibrationHelp')),
                    const SizedBox(height: 12),
                    numberField(subtitleTime1, 'subtitleCueTimeAnchor1', updateDialog),
                    numberField(playbackTime1, 'subtitlePlaybackTimeAnchor1', updateDialog),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: previewing ? null : () => capturePlaybackTime(playbackTime1),
                        icon: const Icon(Symbols.my_location_rounded),
                        label: Text(_subtitleDriftText('subtitleUsePlaybackTime')),
                      ),
                    ),
                    const Divider(),
                    numberField(subtitleTime2, 'subtitleCueTimeAnchor2', updateDialog),
                    numberField(playbackTime2, 'subtitlePlaybackTimeAnchor2', updateDialog),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: previewing ? null : () => capturePlaybackTime(playbackTime2),
                        icon: const Icon(Symbols.my_location_rounded),
                        label: Text(_subtitleDriftText('subtitleUsePlaybackTime')),
                      ),
                    ),
                    if (previewApplied) ...[
                      const SizedBox(height: 8),
                      Text(_subtitleDriftText('subtitleDriftPreviewActive')),
                    ],
                    if (failureMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        failureMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: previewing ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(t.common.cancel),
              ),
              TextButton(
                onPressed: previewing ? null : preview,
                child: Text(_subtitleDriftText('subtitleDriftPreview')),
              ),
              TextButton(
                onPressed: previewing ? null : submit,
                child: Text(t.common.save),
              ),
            ],
          );
        },
      ),
    );

    subtitleTime1.dispose();
    playbackTime1.dispose();
    subtitleTime2.dispose();
    playbackTime2.dispose();
    if (!mounted) return;
    if (calibration == null) {
      await rollbackPreviewOnce();
      return;
    }

    setState(() {
      _currentOffset = calibration.delayMs.toDouble();
      _currentSubtitleRate = calibration.timestampMultiplier;
    });
    await _saveSubtitleCalibrationWithUndo(calibration);
  }

  Future<void> _saveSubtitleCalibrationWithUndo(SubtitleSyncCalibration calibration) async {
    final previous = SubtitleSyncCalibration(
      timestampMultiplier: _confirmedSubtitleRate,
      delayMs: _confirmedOffset.round(),
    );
    final changed =
        previous.delayMs != calibration.delayMs ||
        (previous.timestampMultiplier - calibration.timestampMultiplier).abs() > 0.001;
    await _applySubtitleCalibration(calibration);
    if (!mounted) return;
    final applied =
        _confirmedOffset.round() == calibration.delayMs &&
        (_confirmedSubtitleRate - calibration.timestampMultiplier).abs() <= 0.001;
    setState(() => _undoSubtitleCalibration = changed && applied ? previous : null);
  }

  Future<void> _undoLastSubtitleCalibration() async {
    final previous = _undoSubtitleCalibration;
    if (previous == null) return;
    setState(() {
      _currentOffset = previous.delayMs.toDouble();
      _currentSubtitleRate = previous.timestampMultiplier;
    });
    await _applySubtitleCalibration(previous);
    if (!mounted) return;
    final restored =
        _confirmedOffset.round() == previous.delayMs &&
        (_confirmedSubtitleRate - previous.timestampMultiplier).abs() <= 0.001;
    if (restored) setState(() => _undoSubtitleCalibration = null);
  }

  Future<bool> _previewSubtitleCalibration(SubtitleSyncCalibration calibration) async {
    if (!_canUseSubtitleDriftCorrection) return false;

    final targetPlayer = widget.player;
    final propertyName = widget.propertyName;
    final coordinator = _syncOffsetWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin(propertyName);
    final generation = ++_writeGeneration;
    final bindingGeneration = _bindingGeneration;
    var rollbackOffset = _confirmedOffset.round();
    var rollbackRate = _confirmedSubtitleRate;

    try {
      final committed = await coordinator.commitIfLatest(propertyName, writeToken, () async {
        rollbackOffset = _confirmedOffset.round();
        rollbackRate = _confirmedSubtitleRate;
        final offsets = PlayerSyncOffsets.of(targetPlayer);
        try {
          await targetPlayer.setProperty(
            PlayerSyncOffsets.subtitleRateProperty,
            calibration.timestampMultiplier.toStringAsFixed(6),
          );
          await targetPlayer.setProperty(propertyName, (calibration.delayMs / 1000.0).toString());

          final appliedRate = double.tryParse(
            await targetPlayer.getProperty(PlayerSyncOffsets.subtitleRateProperty) ?? '',
          );
          final appliedDelay = double.tryParse(await targetPlayer.getProperty(propertyName) ?? '');
          if (appliedRate == null ||
              !appliedRate.isFinite ||
              appliedDelay == null ||
              !appliedDelay.isFinite ||
              (appliedRate - calibration.timestampMultiplier).abs() > 0.001 ||
              (appliedDelay * 1000 - calibration.delayMs).abs() > 2) {
            throw StateError('The player did not apply the subtitle preview.');
          }

          offsets.recordSubtitleRate(appliedRate);
          offsets.recordApplied(propertyName, (appliedDelay * 1000).round());
        } catch (_) {
          try {
            await targetPlayer.setProperty(
              PlayerSyncOffsets.subtitleRateProperty,
              rollbackRate.toStringAsFixed(6),
            );
            await targetPlayer.setProperty(propertyName, (rollbackOffset / 1000.0).toString());
            offsets.recordSubtitleRate(rollbackRate);
            offsets.recordApplied(propertyName, rollbackOffset);
          } catch (rollbackError, rollbackStackTrace) {
            appLogger.w(
              'Could not restore subtitle timing after drift preview failed',
              error: rollbackError,
              stackTrace: rollbackStackTrace,
            );
          }
          rethrow;
        }
      });
      if (!committed ||
          !mounted ||
          generation != _writeGeneration ||
          bindingGeneration != _bindingGeneration ||
          targetPlayer != widget.player ||
          propertyName != widget.propertyName) {
        return false;
      }
      setState(() {
        _currentOffset = calibration.delayMs.toDouble();
        _currentSubtitleRate = calibration.timestampMultiplier;
      });
      return true;
    } catch (error, stackTrace) {
      appLogger.w('Failed to preview subtitle drift correction', error: error, stackTrace: stackTrace);
      if (mounted &&
          generation == _writeGeneration &&
          bindingGeneration == _bindingGeneration &&
          targetPlayer == widget.player &&
          propertyName == widget.propertyName) {
        setState(() {
          _currentOffset = _confirmedOffset;
          _currentSubtitleRate = _confirmedSubtitleRate;
        });
      }
      return false;
    }
  }

  Future<void> _rollbackSubtitlePreview() async {
    if (!_canUseSubtitleDriftCorrection) return;

    final targetPlayer = widget.player;
    final propertyName = widget.propertyName;
    final coordinator = _syncOffsetWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin(propertyName);
    final generation = ++_writeGeneration;
    final bindingGeneration = _bindingGeneration;
    final offset = _confirmedOffset.round();
    final rate = _confirmedSubtitleRate;

    try {
      final committed = await coordinator.commitIfLatest(propertyName, writeToken, () async {
        await targetPlayer.setProperty(PlayerSyncOffsets.subtitleRateProperty, rate.toStringAsFixed(6));
        await targetPlayer.setProperty(propertyName, (offset / 1000.0).toString());
        final offsets = PlayerSyncOffsets.of(targetPlayer);
        offsets.recordSubtitleRate(rate);
        offsets.recordApplied(propertyName, offset);
      });
      if (!committed ||
          !mounted ||
          generation != _writeGeneration ||
          bindingGeneration != _bindingGeneration ||
          targetPlayer != widget.player ||
          propertyName != widget.propertyName) {
        return;
      }
      setState(() {
        _currentOffset = offset.toDouble();
        _currentSubtitleRate = rate;
      });
    } catch (error, stackTrace) {
      appLogger.w('Failed to undo subtitle drift preview', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _applySubtitleCalibration(SubtitleSyncCalibration calibration) async {
    if (!_canUseSubtitleDriftCorrection) return;

    final targetPlayer = widget.player;
    final propertyName = widget.propertyName;
    final persistOffset = widget.onOffsetChanged;
    final persistRate = widget.onSubtitleRateChanged!;
    final coordinator = _syncOffsetWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin(propertyName);
    final generation = ++_writeGeneration;
    final bindingGeneration = _bindingGeneration;
    var rollbackOffset = _confirmedOffset.round();
    var rollbackRate = _confirmedSubtitleRate;

    try {
      final committed = await coordinator.commitIfLatest(propertyName, writeToken, () async {
        rollbackOffset = _confirmedOffset.round();
        rollbackRate = _confirmedSubtitleRate;
        final offsets = PlayerSyncOffsets.of(targetPlayer);
        try {
          await targetPlayer.setProperty(
            PlayerSyncOffsets.subtitleRateProperty,
            calibration.timestampMultiplier.toStringAsFixed(6),
          );
          await targetPlayer.setProperty(propertyName, (calibration.delayMs / 1000.0).toString());

          final appliedRate = double.tryParse(
            await targetPlayer.getProperty(PlayerSyncOffsets.subtitleRateProperty) ?? '',
          );
          final appliedDelay = double.tryParse(await targetPlayer.getProperty(propertyName) ?? '');
          if (appliedRate == null ||
              !appliedRate.isFinite ||
              appliedDelay == null ||
              !appliedDelay.isFinite ||
              (appliedRate - calibration.timestampMultiplier).abs() > 0.001 ||
              (appliedDelay * 1000 - calibration.delayMs).abs() > 2) {
            throw StateError('The player did not apply the subtitle drift correction.');
          }

          final appliedOffsetMs = (appliedDelay * 1000).round();
          offsets.recordSubtitleRate(appliedRate);
          offsets.recordApplied(propertyName, appliedOffsetMs);
          await persistRate(appliedRate);
          await persistOffset(appliedOffsetMs);
          _confirmedOffset = appliedOffsetMs.toDouble();
          _confirmedSubtitleRate = appliedRate;
        } catch (_) {
          try {
            await targetPlayer.setProperty(
              PlayerSyncOffsets.subtitleRateProperty,
              rollbackRate.toStringAsFixed(6),
            );
            await targetPlayer.setProperty(propertyName, (rollbackOffset / 1000.0).toString());
            offsets.recordSubtitleRate(rollbackRate);
            offsets.recordApplied(propertyName, rollbackOffset);
          } catch (rollbackError, rollbackStackTrace) {
            appLogger.w(
              'Could not restore subtitle timing after drift calibration failed',
              error: rollbackError,
              stackTrace: rollbackStackTrace,
            );
          }
          try {
            await persistRate(rollbackRate);
            await persistOffset(rollbackOffset);
          } catch (rollbackError, rollbackStackTrace) {
            appLogger.w(
              'Could not restore saved subtitle timing after drift calibration failed',
              error: rollbackError,
              stackTrace: rollbackStackTrace,
            );
          }
          rethrow;
        }
      });

      if (!committed ||
          !mounted ||
          generation != _writeGeneration ||
          bindingGeneration != _bindingGeneration ||
          targetPlayer != widget.player ||
          propertyName != widget.propertyName) {
        return;
      }
      setState(() {
        _currentOffset = _confirmedOffset;
        _currentSubtitleRate = _confirmedSubtitleRate;
      });
    } catch (error, stackTrace) {
      appLogger.w('Could not calibrate subtitle drift', error: error, stackTrace: stackTrace);
      if (!mounted ||
          generation != _writeGeneration ||
          bindingGeneration != _bindingGeneration ||
          targetPlayer != widget.player ||
          propertyName != widget.propertyName) {
        return;
      }
      setState(() {
        _currentOffset = _confirmedOffset;
        _currentSubtitleRate = _confirmedSubtitleRate;
      });
    }
  }

  Widget _buildSubtitleDriftButton() {
    final label = _subtitleDriftText('subtitleDriftCalibration');
    final value = formatPercent(_currentSubtitleRate);
    return FocusableWrapper(
      onSelect: _openSubtitleDriftCalibration,
      borderRadius: 8,
      autoScroll: false,
      useBackgroundFocus: true,
      child: Tooltip(
        message: '$label · $value',
        child: Semantics(
          button: true,
          label: label,
          value: value,
          child: GestureDetector(
            onTap: _openSubtitleDriftCalibration,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: AppIcon(Symbols.speed_rounded, color: tokens(context).text, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoSubtitleDriftButton() {
    final label = _subtitleDriftText('subtitleDriftUndo');
    return FocusableWrapper(
      onSelect: _undoLastSubtitleCalibration,
      borderRadius: 8,
      autoScroll: false,
      useBackgroundFocus: true,
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: _undoLastSubtitleCalibration,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: AppIcon(Symbols.undo_rounded, color: tokens(context).text, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleStepButton({required bool previous}) {
    final label = previous ? t.shortcuts.subtitleDelayIncrease : t.shortcuts.subtitleDelayDecrease;
    return FocusableWrapper(
      onSelect: () => _stepSubtitleToNow(previous: previous),
      borderRadius: 18,
      autoScroll: false,
      useBackgroundFocus: true,
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: () => _stepSubtitleToNow(previous: previous),
            child: Container(
              width: 148,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    previous ? Symbols.keyboard_arrow_left_rounded : Symbols.keyboard_arrow_right_rounded,
                    color: tokens(context).text,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resetOffset() {
    if (_canUseSubtitleDriftCorrection) {
      final reset = const SubtitleSyncCalibration(timestampMultiplier: 1.0, delayMs: 0);
      setState(() {
        _currentOffset = 0;
        _currentSubtitleRate = 1.0;
      });
      unawaited(_saveSubtitleCalibrationWithUndo(reset));
      return;
    }
    setState(() {
      _currentOffset = 0;
    });
    _applyOffset(0);
  }

  void _incrementOffset() {
    final newOffset = (_currentOffset + _step).clamp(_absoluteMin, _absoluteMax);
    setState(() {
      _currentOffset = newOffset;
    });
    _applyOffset(newOffset);
  }

  void _decrementOffset() {
    final newOffset = (_currentOffset - _step).clamp(_absoluteMin, _absoluteMax);
    setState(() {
      _currentOffset = newOffset;
    });
    _applyOffset(newOffset);
  }

  void _startLongPressIncrement() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final newOffset = (_currentOffset + _longPressStep).clamp(_absoluteMin, _absoluteMax);
      setState(() {
        _currentOffset = newOffset;
      });
      _applyOffset(newOffset);
    });
  }

  void _startLongPressDecrement() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final newOffset = (_currentOffset - _longPressStep).clamp(_absoluteMin, _absoluteMax);
      setState(() {
        _currentOffset = newOffset;
      });
      _applyOffset(newOffset);
    });
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  String get _syncTitle => widget.propertyName == PlayerSyncOffsets.subtitleProperty
      ? t.videoSettings.subtitleSync
      : t.videoSettings.audioSync;

  Future<void> _editExactOffset() async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: _currentOffset.round().toString());
    final offset = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          if (!(formKey.currentState?.validate() ?? false)) return;
          Navigator.of(dialogContext).pop(int.parse(controller.text.trim()));
        }

        return AlertDialog(
          title: Text(_syncTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: _syncTitle,
                hintText: formatSyncOffset(_currentOffset),
                helperText: t.validationErrorDuration(
                  min: ScopedPlayerPrefs.minimumSyncOffsetMs,
                  max: ScopedPlayerPrefs.maximumSyncOffsetMs,
                  unit: 'ms',
                ),
                suffixText: 'ms',
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null) return t.validationErrorEnterNumber;
                if (parsed < ScopedPlayerPrefs.minimumSyncOffsetMs ||
                    parsed > ScopedPlayerPrefs.maximumSyncOffsetMs) {
                  return t.validationErrorDuration(
                    min: ScopedPlayerPrefs.minimumSyncOffsetMs,
                    max: ScopedPlayerPrefs.maximumSyncOffsetMs,
                    unit: 'ms',
                  );
                }
                return null;
              },
              onFieldSubmitted: (_) => submit(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.common.cancel),
            ),
            TextButton(onPressed: submit, child: Text(t.common.save)),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || offset == null) return;
    setState(() => _currentOffset = offset.toDouble());
    _applyOffset(offset.toDouble());
  }

  Widget _buildExactOffsetButton() {
    return FocusableWrapper(
      onSelect: _editExactOffset,
      borderRadius: 8,
      autoScroll: false,
      useBackgroundFocus: true,
      child: Semantics(
        button: true,
        label: _syncTitle,
        value: formatSyncOffset(_currentOffset),
        child: GestureDetector(
          onTap: _editExactOffset,
          child: Container(
            width: 80,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              formatSyncOffset(_currentOffset),
              style: TextStyle(
                fontSize: 16,
                fontWeight: .bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
  }) {
    return FocusableWrapper(
      onSelect: onTap,
      borderRadius: 18,
      autoScroll: false,
      useBackgroundFocus: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => _stopLongPress(),
        onLongPressCancel: _stopLongPress,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: AppIcon(icon, color: tokens(context).text, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = _currentOffset.clamp(_sliderMin, _sliderMax);
    final supportsCueSync =
        widget.player.supportsSubtitleStepSync &&
        (widget.propertyName == PlayerSyncOffsets.subtitleProperty ||
            widget.propertyName == PlayerSyncOffsets.secondarySubtitleProperty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildStepButton(
                icon: Symbols.remove_rounded,
                onTap: _decrementOffset,
                onLongPressStart: _startLongPressDecrement,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(tickMarkShape: SliderTickMarkShape.noTickMark),
                  child: FocusableSlider(
                    focusNode: widget.sliderFocusNode,
                    value: sliderValue,
                    min: _sliderMin,
                    max: _sliderMax,
                    divisions: _sliderDivisions,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.outlineVariant,
                    onSelect: widget.closeFocusNode?.requestFocus,
                    onChanged: (value) => setState(() => _currentOffset = value),
                    onChangeEnd: _applyOffset,
                  ),
                ),
              ),
              _buildStepButton(
                icon: Symbols.add_rounded,
                onTap: _incrementOffset,
                onLongPressStart: _startLongPressIncrement,
              ),
              const SizedBox(width: 12),
              _buildExactOffsetButton(),
              const SizedBox(width: 8),
              FocusableWrapper(
                focusNode: widget.resetFocusNode,
                onSelect: _currentOffset != 0 ? _resetOffset : null,
                borderRadius: 18,
                autoScroll: false,
                useBackgroundFocus: true,
                child: GestureDetector(
                  onTap: _currentOffset != 0 ? _resetOffset : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: .center,
                    child: AppIcon(
                      Symbols.restart_alt_rounded,
                      fill: 1,
                      color: _currentOffset != 0 ? tokens(context).text : tokens(context).textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (supportsCueSync)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildSubtitleStepButton(previous: true),
                  _buildSubtitleStepButton(previous: false),
                  if (_supportsSubtitleDriftCalibration) _buildSubtitleDriftButton(),
                  if (_undoSubtitleCalibration != null) _buildUndoSubtitleDriftButton(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
