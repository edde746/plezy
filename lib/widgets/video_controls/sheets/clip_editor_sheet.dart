import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../../i18n/strings.g.dart';
import '../../../mpv/player/video_rect_support.dart';
import '../../../mpv/video.dart';
import '../../../services/clip_export_service.dart';
import '../../../services/clip_preview_player_controller.dart';
import '../../../services/file_picker_service.dart';
import '../../../services/scrub_preview_source.dart';
import '../../../utils/formatters.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/app_menu.dart';
import '../../../widgets/expressive_button_group.dart';
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
  late bool _subtitlesEnabled;
  GifExportResolution _gifResolution = GifExportResolution.automatic;

  final Map<int, ScrubFrame> _frameCache = <int, ScrubFrame>{};
  String? _savedPath;
  int? _savedFileBytes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection.clampedTo(widget.source.duration);
    _availableFormats = ClipExportService.formatsForOperatingSystem(Platform.operatingSystem, source: widget.source);
    _format = _availableFormats.first;
    _subtitlesEnabled = widget.source.initialSubtitlesEnabled;
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

  void _clearExportResult() {
    _savedPath = null;
    _savedFileBytes = null;
    _errorMessage = null;
  }

  void _setPreviewPosition(Duration position) {
    unawaited(widget.previewController.seekToVideoTime(position));
  }

  void _togglePreviewSubtitles() {
    final player = widget.previewController.player;
    if (player == null) return;
    setState(() {
      _subtitlesEnabled = !_subtitlesEnabled;
      _clearExportResult();
    });
    player.setProperty('sub-visibility', _subtitlesEnabled ? 'yes' : 'no');
  }

  void _handleSelectionChanged(_ClipTrimUpdate update) {
    final nextPreview = update.handle == _ClipPreviewHandle.end ? update.selection.end : update.selection.start;
    setState(() {
      _selection = update.selection;
      _clearExportResult();
    });
    unawaited(widget.previewController.setSelection(update.selection));
    unawaited(widget.previewController.seekToVideoTime(nextPreview));
  }

  void _handleSelectionChangeEnd(ClipSelection selection) {
    setState(() => _selection = selection);
    unawaited(widget.previewController.setSelection(selection));
  }

  Future<void> _saveClip() async {
    setState(_clearExportResult);
    try {
      final outputPath = await widget.exportService.exportClip(
        source: widget.source,
        selection: _selection,
        format: _format,
        gifResolution: _gifResolution,
        subtitlesEnabled: _subtitlesEnabled,
        player: widget.previewController.player,
      );
      final savedFileBytes = _format == ClipExportFormat.gif ? await File(outputPath).length() : null;
      if (!mounted) return;
      setState(() {
        _savedPath = outputPath;
        _savedFileBytes = savedFileBytes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
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
      dialogTitle: t.videoControls.clip.saveAsDialog,
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
            title: t.videoControls.clip.title,
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
                            subtitlesEnabled: _subtitlesEnabled,
                            onToggleSubtitles: _togglePreviewSubtitles,
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
                            ExpressiveButtonGroup<ClipExportFormat>(
                              key: const ValueKey('clip_export_format'),
                              segments: [
                                for (final format in _availableFormats)
                                  ButtonSegment(
                                    value: format,
                                    label: format == ClipExportFormat.gif && _format == ClipExportFormat.gif
                                        ? _ClipGifFormatSelector(
                                            resolution: _gifResolution,
                                            enabled: !isExporting,
                                            onChanged: (resolution) {
                                              setState(() {
                                                _gifResolution = resolution;
                                                _clearExportResult();
                                              });
                                            },
                                          )
                                        : Text(_clipExportFormatLabel(format)),
                                  ),
                              ],
                              selected: _format,
                              enabled: !isExporting,
                              onChanged: (format) {
                                setState(() {
                                  _format = format;
                                  _clearExportResult();
                                });
                              },
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                          if (_savedPath != null)
                            Padding(
                              key: const ValueKey('clip_saved_result'),
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _savedFileBytes == null
                                        ? t.videoControls.clip.savedTo(fileName: path.basename(_savedPath!))
                                        : '${t.videoControls.clip.savedTo(fileName: path.basename(_savedPath!))} · '
                                              '${ByteFormatter.formatBytes(_savedFileBytes!, decimals: 2)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => unawaited(_openSavedFolder()),
                                          icon: const AppIcon(Symbols.folder_open_rounded),
                                          label: Text(t.videoControls.clip.openFolder),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => unawaited(_saveAs()),
                                          icon: const AppIcon(Symbols.save_as_rounded),
                                          label: Text(t.videoControls.clip.saveAs),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            key: const ValueKey('clip_editor_actions'),
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => unawaited(_cancel()),
                                  child: Text(isExporting ? t.videoControls.clip.cancelExport : t.common.cancel),
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
                                      : const AppIcon(Symbols.save_rounded),
                                  label: Text(isExporting ? _exportProgressLabel(exportState) : t.common.save),
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
    if (progress == null) return t.videoControls.clip.saving;
    final percent = (progress.clamp(0.0, 1.0) * 100).floor();
    return t.videoControls.clip.savingProgress(percent: percent);
  }
}

class _ClipGifFormatSelector extends StatelessWidget {
  final GifExportResolution resolution;
  final bool enabled;
  final ValueChanged<GifExportResolution> onChanged;

  const _ClipGifFormatSelector({required this.resolution, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppMenuButton<GifExportResolution>(
      key: const ValueKey('clip_gif_resolution'),
      enabled: enabled,
      tooltip: t.fileInfo.resolution,
      anchorAlignment: AppMenuAnchorAlignment.end,
      onSelected: onChanged,
      entriesBuilder: (_) => [
        for (final value in GifExportResolution.values)
          AppMenuItem(value: value, label: _gifResolutionLabel(value), selected: value == resolution),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_clipExportFormatLabel(ClipExportFormat.gif)} - ${_gifResolutionLabel(resolution)}'),
              const SizedBox(width: 4),
              Icon(Symbols.expand_more_rounded, size: 18, color: DefaultTextStyle.of(context).style.color),
            ],
          ),
        ),
      ),
    );
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
  ClipExportFormat.hevcSdr => t.videoControls.clip.formatHevcSdr,
  ClipExportFormat.h264Sdr => t.videoControls.clip.formatH264Sdr,
  ClipExportFormat.hevcHdr => t.videoControls.clip.formatHevcHdr,
  ClipExportFormat.gif => 'GIF',
  ClipExportFormat.source => t.videoControls.qualityOriginal,
};

String _gifResolutionLabel(GifExportResolution resolution) => switch (resolution) {
  GifExportResolution.automatic => t.settings.visualEffectsAuto,
  GifExportResolution.p480 => '480p',
  GifExportResolution.p720 => '720p',
  GifExportResolution.p1080 => '1080p',
};
