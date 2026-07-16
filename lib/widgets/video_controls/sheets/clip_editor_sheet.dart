import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../../mpv/player/video_rect_support.dart';
import '../../../mpv/video.dart';
import '../../../services/clip_export_service.dart';
import '../../../services/clip_preview_player_controller.dart';
import '../../../services/file_picker_service.dart';
import '../../../services/scrub_preview_source.dart';
import '../../../widgets/overlay_sheet.dart';
import '../widgets/scrub_frame_view.dart';
import 'base_video_control_sheet.dart';

part 'clip_editor/clip_preview.dart';
part 'clip_editor/clip_trim_slider.dart';

const _clipPreviewHorizontalInset = 18.0;
const _clipPreviewTopInset = 2.0;
const _clipHeaderAndDividerExtent = 41.0;
const _clipPreviewFallbackAspectRatio = 16 / 9;
const _clipEditorNonPreviewExtent = 300.0;

class ClipEditorSheet extends StatefulWidget {
  final ClipSource source;
  final ClipSelection initialSelection;
  final ClipExportService exportService;
  final ClipPreviewPlayerController previewController;
  final ScrubFrame? Function(Duration time)? thumbnailDataBuilder;

  const ClipEditorSheet({
    super.key,
    required this.source,
    required this.initialSelection,
    required this.exportService,
    required this.previewController,
    this.thumbnailDataBuilder,
  });

  @override
  State<ClipEditorSheet> createState() => _ClipEditorSheetState();
}

enum _ClipPreviewHandle { start, end }

class _ClipTrimUpdate {
  final ClipSelection selection;
  final _ClipPreviewHandle handle;

  const _ClipTrimUpdate({required this.selection, required this.handle});
}

class _ClipEditorSheetState extends State<ClipEditorSheet> {
  late ClipSelection _selection;
  late ClipSelection _trimWindow;
  late final List<ClipExportFormat> _availableFormats;
  late ClipExportFormat _format;

  final Map<int, ScrubFrame> _frameCache = <int, ScrubFrame>{};
  String? _savedPath;
  String? _errorMessage;
  bool _previewSuspended = false;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection.clampedTo(widget.source.duration);
    _availableFormats = ClipExportService.formatsForOperatingSystem(Platform.operatingSystem, source: widget.source);
    _format = _availableFormats.first;
    _trimWindow = ClipExportService.trimWindowForSelection(
      sourceDuration: widget.source.duration,
      selection: _selection,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.previewController.open(widget.source, _selection));
    });
  }

  Duration _clampToSource(Duration position) {
    if (position < Duration.zero) return Duration.zero;
    final duration = widget.source.duration;
    if (duration > Duration.zero && position > duration) return duration;
    return position;
  }

  Duration _frameBucketPosition(Duration position) {
    final clamped = _clampToSource(position);
    return Duration(seconds: (clamped.inMilliseconds / Duration.millisecondsPerSecond).round());
  }

  ScrubFrame? _frameFor(Duration position) {
    final bucket = _frameBucketPosition(position);
    final key = bucket.inMilliseconds;
    final cached = _frameCache[key];
    if (cached != null) return cached;

    final scrubFrame = widget.thumbnailDataBuilder?.call(bucket);
    if (scrubFrame == null) return null;

    _frameCache[key] = scrubFrame;
    return scrubFrame;
  }

  void _setPreviewPosition(Duration position) {
    unawaited(widget.previewController.seekToVideoTime(position));
  }

  void _handleSelectionChanged(_ClipTrimUpdate update) {
    final nextPreview = update.handle == _ClipPreviewHandle.end ? update.selection.end : update.selection.start;
    setState(() {
      _selection = update.selection;
      _savedPath = null;
      _errorMessage = null;
    });
    unawaited(widget.previewController.setSelection(update.selection));
    unawaited(widget.previewController.seekToVideoTime(nextPreview));
  }

  void _handleSelectionChangeEnd(ClipSelection selection) {
    setState(() => _selection = selection);
    unawaited(widget.previewController.setSelection(selection));
  }

  Future<void> _saveClip() async {
    setState(() {
      _errorMessage = null;
      _savedPath = null;
    });
    final usesEncoder = _format != ClipExportFormat.source;
    try {
      var previewPlayer = widget.previewController.player;
      if (usesEncoder) {
        setState(() => _previewSuspended = true);
        await widget.previewController.suspendForExport();
        previewPlayer = null;
      }
      final outputPath = await widget.exportService.exportClip(
        source: widget.source,
        selection: _selection,
        format: _format,
        player: previewPlayer,
      );
      if (!mounted) return;
      setState(() => _savedPath = outputPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (usesEncoder && mounted) {
        await widget.previewController.resumeAfterExport();
        if (mounted) {
          await WidgetsBinding.instance.endOfFrame;
        }
        if (mounted) {
          setState(() => _previewSuspended = false);
        }
      }
    }
  }

  Future<void> _cancel() async {
    if (widget.exportService.state.value.stage == ClipExportStage.running) {
      await widget.exportService.cancelActiveExport();
    }
    if (mounted) OverlaySheetController.closeAdaptive(context);
  }

  Future<void> _openSavedFolder() async {
    final savedPath = _savedPath;
    if (savedPath == null) return;
    await launchUrl(Uri.file(path.dirname(savedPath)), mode: LaunchMode.externalApplication);
  }

  Future<void> _saveAs() async {
    final savedPath = _savedPath;
    if (savedPath == null) return;
    final file = File(savedPath);
    final bytes = await file.readAsBytes();
    final extension = path.extension(savedPath).replaceFirst('.', '');
    await FilePickerService.instance.saveFile(
      dialogTitle: 'Save Clip As',
      fileName: path.basename(savedPath),
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPreviewWidth = constraints.maxWidth - (_clipPreviewHorizontalInset * 2);
        final frameAspectRatio = _frameFor(_selection.start)?.aspectRatio;
        final previewAspectRatio = frameAspectRatio != null && frameAspectRatio.isFinite && frameAspectRatio > 0
            ? frameAspectRatio
            : _clipPreviewFallbackAspectRatio;
        var previewHeight = maxPreviewWidth / previewAspectRatio;
        if (constraints.maxHeight.isFinite) {
          final availableHeight = constraints.maxHeight - _clipEditorNonPreviewExtent;
          if (availableHeight > 0 && previewHeight > availableHeight) {
            previewHeight = availableHeight;
          }
        }
        final previewWidth = previewHeight * previewAspectRatio;
        final previewLeft = (constraints.maxWidth - previewWidth) / 2;
        return CustomPaint(
          painter: _ClipEditorBackgroundPainter(
            color: surfaceColor,
            previewRect: Rect.fromLTWH(
              previewLeft,
              _clipHeaderAndDividerExtent + _clipPreviewTopInset,
              previewWidth,
              previewHeight,
            ),
          ),
          child: BaseVideoControlSheet(
            title: 'Clip',
            icon: Symbols.content_cut_rounded,
            compactHeader: true,
            shrinkWrap: true,
            child: ValueListenableBuilder<ClipExportJobState>(
              valueListenable: widget.exportService.state,
              builder: (context, exportState, _) {
                final isExporting = exportState.stage == ClipExportStage.running;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: _clipPreviewTopInset),
                    Center(
                      child: SizedBox(
                        width: previewWidth,
                        child: KeyedSubtree(
                          key: const ValueKey('clip_preview_cutout'),
                          child: _ClipPreviewPlayer(
                            controller: widget.previewController,
                            frameFor: _frameFor,
                            selection: _selection,
                            onSeek: _setPreviewPosition,
                            forcePoster: _previewSuspended,
                            height: previewHeight,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ClipTrimSlider(
                            duration: widget.source.duration,
                            trimWindow: _trimWindow,
                            selection: _selection,
                            enabled: !isExporting,
                            thumbnailDataBuilder: widget.thumbnailDataBuilder,
                            onChanged: _handleSelectionChanged,
                            onChangeEnd: _handleSelectionChangeEnd,
                          ),
                          const SizedBox(height: 2),
                          _ClipTrimBoundsHeader(selection: _selection),
                          if (_availableFormats.length > 1) ...[
                            const SizedBox(height: 10),
                            SegmentedButton<ClipExportFormat>(
                              key: const ValueKey('clip_export_format'),
                              segments: [
                                for (final format in _availableFormats)
                                  ButtonSegment(value: format, label: Text(_clipExportFormatLabel(format))),
                              ],
                              selected: {_format},
                              onSelectionChanged: isExporting
                                  ? null
                                  : (selection) {
                                      setState(() {
                                        _format = selection.first;
                                        _savedPath = null;
                                        _errorMessage = null;
                                      });
                                    },
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                          if (_savedPath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Saved to ${path.basename(_savedPath!)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => unawaited(_openSavedFolder()),
                                    icon: const Icon(Symbols.folder_open_rounded),
                                    label: const Text('Open Folder'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => unawaited(_saveAs()),
                                    icon: const Icon(Symbols.save_as_rounded),
                                    label: const Text('Save As'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => unawaited(_cancel()),
                                  child: Text(isExporting ? 'Cancel Export' : 'Cancel'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: isExporting ? null : () => unawaited(_saveClip()),
                                  icon: isExporting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Symbols.save_rounded),
                                  label: Text(isExporting ? _exportProgressLabel(exportState) : 'Save'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _exportProgressLabel(ClipExportJobState state) {
    final progress = state.progress;
    if (progress == null) return 'Saving...';
    final percent = (progress.clamp(0.0, 1.0) * 100).floor();
    return 'Saving $percent%';
  }
}

class _ClipEditorBackgroundPainter extends CustomPainter {
  final Color color;
  final Rect previewRect;

  const _ClipEditorBackgroundPainter({required this.color, required this.previewRect});

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(previewRect);
    canvas.drawPath(
      background,
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_ClipEditorBackgroundPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.previewRect != previewRect;
}

String _clipExportFormatLabel(ClipExportFormat format) => switch (format) {
  ClipExportFormat.hevcSdr => 'HEVC SDR',
  ClipExportFormat.h264Sdr => 'H.264 SDR',
  ClipExportFormat.hevcHdr => 'HEVC HDR',
  ClipExportFormat.source => 'Original',
};
