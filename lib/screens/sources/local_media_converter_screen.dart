import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../sources/source_models.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';

enum _ConversionFormat { mp4, m4a, mp3 }

class LocalMediaConverterScreen extends StatefulWidget {
  const LocalMediaConverterScreen({super.key});

  @override
  State<LocalMediaConverterScreen> createState() => _LocalMediaConverterScreenState();
}

class _LocalMediaConverterScreenState extends State<LocalMediaConverterScreen> {
  File? _input;
  String? _inputName;
  _ConversionFormat _format = _ConversionFormat.mp4;
  Process? _process;
  bool _busy = false;
  bool _cancelled = false;
  double? _progress;
  int? _durationMs;
  String? _status;
  String? _failure;

  Future<void> _chooseInput() async {
    final result = await FilePicker.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.isEmpty || !mounted) return;
    final selected = result.files.single;
    final kind = classifySourceFile(selected.name);
    if (kind != SourceItemKind.video && kind != SourceItemKind.music && kind != SourceItemKind.audiobook) {
      setState(() => _failure = t.universalMedia.converterUnsupportedInput);
      return;
    }
    if (selected.path == null) {
      setState(() => _failure = t.universalMedia.converterLocalOnly);
      return;
    }
    setState(() {
      _input = File(selected.path!);
      _inputName = selected.name;
      if (kind == SourceItemKind.music || kind == SourceItemKind.audiobook) {
        _format = _ConversionFormat.m4a;
      } else {
        _format = _ConversionFormat.mp4;
      }
      _failure = null;
      _progress = null;
      _status = null;
    });
  }

  String _extension(_ConversionFormat format) => switch (format) {
    _ConversionFormat.mp4 => 'mp4',
    _ConversionFormat.m4a => 'm4a',
    _ConversionFormat.mp3 => 'mp3',
  };

  String _suggestedName() {
    final input = _inputName ?? 'media';
    return '${p.basenameWithoutExtension(input)}.${_extension(_format)}';
  }

  List<String> _arguments(String input, String output) {
    final arguments = <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      '-nostdin',
      '-y',
      '-i',
      input,
      '-map_metadata',
      '0',
      '-map',
      '0:v:0?',
      '-map',
      '0:a:0?',
    ];
    switch (_format) {
      case _ConversionFormat.mp4:
        arguments.addAll([
          '-c:v',
          'libx264',
          '-preset',
          'medium',
          '-crf',
          '22',
          '-pix_fmt',
          'yuv420p',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          '-movflags',
          '+faststart',
        ]);
      case _ConversionFormat.m4a:
        arguments.addAll(['-vn', '-c:a', 'aac', '-b:a', '192k']);
      case _ConversionFormat.mp3:
        arguments.addAll(['-vn', '-c:a', 'libmp3lame', '-q:a', '2']);
    }
    arguments.addAll(['-progress', 'pipe:1', '-nostats', output]);
    return arguments;
  }

  Future<int?> _probeDuration(String inputPath) async {
    Process? process;
    Timer? deadline;
    try {
      final child = await Process.start('ffprobe', [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        inputPath,
      ], runInShell: false);
      process = child;
      final output = child.stdout.transform(utf8.decoder).join();
      final diagnostics = child.stderr.drain<void>();
      deadline = Timer(const Duration(seconds: 8), child.kill);
      final exitCode = await child.exitCode;
      deadline.cancel();
      await diagnostics;
      if (exitCode != 0) return null;
      final seconds = double.tryParse((await output).trim());
      if (seconds == null || !seconds.isFinite || seconds <= 0) return null;
      return (seconds * 1000).round();
    } on Object {
      process?.kill();
      return null;
    } finally {
      deadline?.cancel();
    }
  }

  Future<void> _convert() async {
    final input = _input;
    if (input == null || _busy || !await input.exists()) return;
    final chosenPath = await FilePicker.saveFile(
      dialogTitle: t.universalMedia.converterSaveAs,
      fileName: _suggestedName(),
      type: FileType.custom,
      allowedExtensions: [_extension(_format)],
    );
    if (chosenPath == null || !mounted) return;
    var path = chosenPath;
    if (p.extension(path).isEmpty) path += '.${_extension(_format)}';
    if (p.extension(path).toLowerCase() != '.${_extension(_format)}') {
      setState(() => _failure = t.universalMedia.converterExtensionMismatch);
      return;
    }

    final target = File(path).absolute;
    final targetExists = await target.exists();
    if (!mounted) return;
    final replace = targetExists
        ? await showConfirmDialog(
            context,
            title: t.universalMedia.converterReplaceTitle,
            message: t.universalMedia.converterReplaceHelp,
            confirmText: t.universalMedia.replaceRecording,
            isDestructive: true,
          )
        : false;
    if (!mounted || targetExists && !replace) return;

    final partial = File(
      p.join(
        target.parent.path,
        '.${p.basenameWithoutExtension(target.path)}.plezy-convert-${const Uuid().v4()}${p.extension(target.path)}',
      ),
    );
    setState(() {
      _busy = true;
      _cancelled = false;
      _progress = null;
      _durationMs = null;
      _status = t.universalMedia.converterStarting;
      _failure = null;
    });

    File? backup;
    try {
      if (!await target.parent.exists()) throw const FileSystemException('Output folder is unavailable');
      _durationMs = await _probeDuration(input.path);
      final process = await Process.start('ffmpeg', _arguments(input.path, partial.path), runInShell: false);
      _process = process;
      final stderr = process.stderr.transform(utf8.decoder).join();
      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        if (!mounted) continue;
        if (line.startsWith('out_time_ms=')) {
          final elapsed = int.tryParse(line.substring('out_time_ms='.length));
          setState(() {
            _status = t.universalMedia.converterProgress;
            _progress = elapsed == null || _durationMs == null
                ? null
                : (elapsed / (_durationMs! * 1000)).clamp(0.0, 1.0);
          });
        }
      }
      final exitCode = await process.exitCode;
      final diagnostics = (await stderr).trim();
      _process = null;
      if (_cancelled) {
        if (mounted) setState(() => _status = t.universalMedia.converterCancelled);
        return;
      }
      if (exitCode != 0 || !await partial.exists() || await partial.length() == 0) {
        if (diagnostics.toLowerCase().contains('unknown encoder') || diagnostics.toLowerCase().contains('not found')) {
          throw const FileSystemException('FFmpeg is missing or does not include the selected encoder');
        }
        throw const FileSystemException('FFmpeg could not convert this file');
      }

      if (await target.exists()) {
        backup = File('${target.path}.plezy-backup-${const Uuid().v4()}');
        await target.rename(backup.path);
      }
      try {
        await partial.rename(target.path);
      } catch (_) {
        if (backup != null && await backup.exists() && !await target.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }
      if (backup != null && await backup.exists()) {
        try {
          await backup.delete();
        } catch (_) {
          // A completed conversion is successful even if backup cleanup is deferred.
        }
      }
      if (mounted) setState(() => _status = t.universalMedia.converterComplete);
    } on ProcessException {
      if (mounted) setState(() => _failure = t.universalMedia.converterFfmpegMissing);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _failure = error is FileSystemException && error.message.contains('FFmpeg')
              ? t.universalMedia.converterFfmpegMissing
              : t.universalMedia.converterFailed;
        });
      }
    } finally {
      _process = null;
      if (await partial.exists()) await partial.delete();
      if (backup != null && await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final process = _process;
    if (process == null) return;
    _cancelled = true;
    process.kill();
    await process.exitCode;
  }

  @override
  void dispose() {
    _process?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isDesktopOS()) {
      return FocusedScrollScaffold(
        title: Text(t.universalMedia.converterTitle),
        slivers: [
          SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(t.universalMedia.converterDesktopOnly))),
        ],
      );
    }
    return FocusedScrollScaffold(
      title: Text(t.universalMedia.converterTitle),
      focusableAppBarActions: true,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.universalMedia.converterIntro, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    Text(t.universalMedia.converterPrivacy),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _chooseInput,
                      icon: const AppIcon(Symbols.video_file_rounded),
                      label: Text(_inputName ?? t.universalMedia.converterChooseInput),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<_ConversionFormat>(
                      initialValue: _format,
                      decoration: InputDecoration(labelText: t.universalMedia.converterFormat),
                      items: [
                        DropdownMenuItem(value: _ConversionFormat.mp4, child: Text(t.universalMedia.converterMp4)),
                        DropdownMenuItem(value: _ConversionFormat.m4a, child: Text(t.universalMedia.converterM4a)),
                        DropdownMenuItem(value: _ConversionFormat.mp3, child: Text(t.universalMedia.converterMp3)),
                      ],
                      onChanged: _busy ? null : (value) => setState(() => _format = value ?? _format),
                    ),
                    const SizedBox(height: 20),
                    if (_busy) ...[
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Semantics(liveRegion: true, child: Text(_status ?? t.universalMedia.converterStarting)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _process == null ? null : _cancel,
                          icon: const AppIcon(Symbols.cancel_rounded),
                          label: Text(t.common.cancel),
                        ),
                      ),
                    ] else if (_status != null)
                      Semantics(liveRegion: true, child: Text(_status!)),
                    if (_failure != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(_failure!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: !_busy && _input != null ? _convert : null,
                      icon: const AppIcon(Symbols.swap_horiz_rounded),
                      label: Text(t.universalMedia.converterStart),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
