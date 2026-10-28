import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../focus/focusable_text_field.dart';
import '../../sources/media_extension.dart';
import '../../sources/media_capture.dart';
import '../../sources/network_media_stream_server.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'source_widgets.dart';

// This is executable CLI syntax, so keep it unchanged across locales.
const _cliCommandExample = 'python3 tools/plezyctl search --manifest path/to/extension.json "ambient" --open';

enum _MediaToolMode { capture, share, extensions }

class MediaToolsScreen extends StatefulWidget {
  const MediaToolsScreen({super.key});

  static bool get isSupported => !PlatformDetector.isTV();

  @override
  State<MediaToolsScreen> createState() => _MediaToolsScreenState();
}

class _MediaToolsScreenState extends State<MediaToolsScreen> with WidgetsBindingObserver {
  static const _extensionsKey = 'media-search-extensions-v1';
  final _extensionQuery = TextEditingController();
  List<MediaCaptureSource> _captureSources = const [];
  List<MediaCaptureAudioSource> _captureAudioSources = const [];
  MediaCaptureSource? _captureSource;
  MediaCaptureAudioSource? _captureAudioSource;
  _MediaToolMode _mode = _MediaToolMode.extensions;
  int _frameRate = 30;
  bool _discovering = true;
  bool _busy = false;
  bool _recording = false;
  File? _recordingTarget;
  File? _recordingPartial;
  File? _recordingBackup;
  Process? _recorder;
  Future<void>? _finishingCapture;
  DateTime? _recordingStarted;
  Duration _recordingElapsed = Duration.zero;
  Timer? _ticker;
  File? _shareInput;
  String? _shareInputName;
  NetworkMediaStreamServer? _streamServer;
  String? _failure;
  String? _success;
  SourceController? _sources;
  String? _profile;
  int _generation = 0;
  List<MediaSearchExtension> _extensions = const [];
  MediaSearchExtension? _selectedExtension;
  List<MediaSearchResult> _extensionResults = const [];
  bool _loadingExtensions = true;
  bool _searchingExtensions = false;
  bool _hasSearched = false;
  bool _appInForeground = true;

  bool get _sharing => _streamServer?.isRunning == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (PlatformDetector.isDesktopOS()) {
      _mode = _MediaToolMode.capture;
      unawaited(_discoverCaptureSources());
    } else {
      _discovering = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sources = context.read<SourceController>();
      _profile = _sources!.profileId;
      _generation = _sources!.generation;
      _sources!.addListener(_onSessionChanged);
      unawaited(_loadExtensions());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sources?.removeListener(_onSessionChanged);
    _extensionQuery.dispose();
    _ticker?.cancel();
    unawaited(_stopRecording());
    unawaited(_stopSharing());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      unawaited(_stopRecording());
      unawaited(_stopSharing());
    }
  }

  void _onSessionChanged() {
    final sources = _sources;
    if (sources != null && (sources.generation != _generation || sources.profileId != _profile)) {
      unawaited(_stopRecording());
      unawaited(_stopSharing());
      _generation = sources.generation;
      _profile = sources.profileId;
      _shareInput = null;
      _shareInputName = null;
      _extensionQuery.clear();
      if (mounted) {
        setState(() {
          _extensions = const [];
          _selectedExtension = null;
          _extensionResults = const [];
          _hasSearched = false;
          _loadingExtensions = true;
        });
      }
      unawaited(_loadExtensions());
    }
  }

  Future<void> _discoverCaptureSources() async {
    try {
      final found = await Future.wait([DesktopMediaCapture.discover(), DesktopMediaCapture.discoverAudio()]);
      final video = found[0] as List<MediaCaptureSource>;
      final audio = found[1] as List<MediaCaptureAudioSource>;
      if (mounted) {
        setState(() {
          _captureSources = video;
          _captureSource = video.isEmpty ? null : video.first;
          _captureAudioSources = audio;
          _captureAudioSource = null;
          _discovering = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _discovering = false);
    }
  }

  void _requireSession({int? generation, String? profile}) {
    final sources = _sources ?? context.read<SourceController>();
    final expectedGeneration = generation ?? _generation;
    sources.requireSession(expectedGeneration == 0 ? sources.generation : expectedGeneration);
    final expectedProfile = profile ?? _profile;
    if (expectedProfile != null && sources.profileId != expectedProfile) {
      throw const SourceException(SourceFailure.cancelled);
    }
  }

  Future<void> _startRecording() async {
    final source = _captureSource;
    if (source == null || _busy || _recording) return;
    final generation = _generation;
    final profile = _profile;
    String? targetPath;
    try {
      _requireSession(generation: generation, profile: profile);
      targetPath = await FilePicker.saveFile(
        dialogTitle: t.universalMedia.captureSaveAs,
        fileName: 'capture-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.mp4',
        type: FileType.custom,
        allowedExtensions: const ['mp4'],
      );
      if (targetPath == null || !mounted) return;
      _requireSession(generation: generation, profile: profile);
      if (p.extension(targetPath).isEmpty) targetPath = '$targetPath.mp4';
      if (p.extension(targetPath).toLowerCase() != '.mp4') {
        setState(() => _failure = t.universalMedia.captureExtensionMismatch);
        return;
      }

      final target = File(targetPath).absolute;
      final exists = await target.exists();
      if (!mounted) return;
      _requireSession(generation: generation, profile: profile);
      if (exists) {
        final replace = await showConfirmDialog(
          context,
          title: t.universalMedia.replaceRecordingTitle,
          message: t.universalMedia.replaceRecordingHelp,
          confirmText: t.universalMedia.replaceRecording,
          isDestructive: true,
        );
        if (!replace || !mounted) return;
        _requireSession(generation: generation, profile: profile);
      }
      if (!await target.parent.exists()) throw const FileSystemException('Output folder unavailable');
      if (!mounted || !_appInForeground) return;
      _requireSession(generation: generation, profile: profile);
      final partial = File(
        p.join(
          target.parent.path,
          '.${p.basenameWithoutExtension(target.path)}.plezy-capture-${const Uuid().v4()}.mp4',
        ),
      );
      final arguments = <String>[
        '-hide_banner',
        '-loglevel',
        'warning',
        ...source.inputArguments(_frameRate),
        if (_captureAudioSource case final audioSource?) ...audioSource.inputArguments,
        '-map',
        '0:v:0',
        if (_captureAudioSource != null) ...['-map', '1:a:0?', '-c:a', 'aac', '-b:a', '192k'] else '-an',
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '24',
        '-pix_fmt',
        'yuv420p',
        '-movflags',
        '+faststart',
        '-progress',
        'pipe:1',
        '-nostats',
        '-y',
        partial.path,
      ];
      final process = await Process.start('ffmpeg', arguments, runInShell: false);
      if (!mounted || !_appInForeground) {
        process.kill();
        unawaited(process.stdout.drain<void>());
        unawaited(process.stderr.drain<void>());
        await process.exitCode;
        return;
      }
      try {
        _requireSession(generation: generation, profile: profile);
      } on Object {
        process.kill();
        unawaited(process.stdout.drain<void>());
        unawaited(process.stderr.drain<void>());
        await process.exitCode;
        rethrow;
      }
      _recordingTarget = target;
      _recordingPartial = partial;
      _recordingBackup = exists ? File('${target.path}.plezy-backup-${const Uuid().v4()}') : null;
      _recorder = process;
      _recordingStarted = DateTime.now();
      _recordingElapsed = Duration.zero;
      _success = null;
      _failure = null;
      _recording = true;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final started = _recordingStarted;
        if (mounted && started != null) {
          setState(() => _recordingElapsed = DateTime.now().difference(started));
        }
      });
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (!line.startsWith('out_time_ms=')) return;
        final micros = int.tryParse(line.substring('out_time_ms='.length));
        if (mounted && micros != null) setState(() => _recordingElapsed = Duration(microseconds: micros));
      }, onError: (_) {});
      unawaited(process.stderr.drain<void>());
      unawaited(process.exitCode.then(_finishRecording));
      if (mounted) setState(() {});
    } on ProcessException {
      if (mounted && generation == _generation && profile == _profile && _appInForeground) {
        setState(() => _failure = t.universalMedia.captureFfmpegMissing);
      }
    } on Object {
      if (mounted && generation == _generation && profile == _profile && _appInForeground) {
        setState(() => _failure = t.universalMedia.captureFailed);
      }
    }
  }

  Future<void> _stopRecording() async {
    final process = _recorder;
    if (process == null) return;
    try {
      process.stdin.writeln('q');
      await process.exitCode.timeout(const Duration(seconds: 6));
    } on Object {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } on Object {
        // Finalization below also restores any existing destination.
      }
    }
    final code = await process.exitCode;
    await _finishRecording(code);
  }

  Future<void> _finishRecording(int exitCode) {
    final ongoing = _finishingCapture;
    if (ongoing != null) return ongoing;
    final finish = _publishRecording(exitCode);
    _finishingCapture = finish;
    return finish.whenComplete(() => _finishingCapture = null);
  }

  Future<void> _publishRecording(int exitCode) async {
    _ticker?.cancel();
    _ticker = null;
    final target = _recordingTarget;
    final partial = _recordingPartial;
    final backup = _recordingBackup;
    var published = false;
    try {
      if (exitCode != 0 ||
          target == null ||
          partial == null ||
          !await partial.exists() ||
          await partial.length() == 0) {
        throw const FileSystemException('Capture did not produce a playable file');
      }
      if (await target.exists()) {
        final destinationBackup = backup ?? File('${target.path}.plezy-backup-${const Uuid().v4()}');
        await target.rename(destinationBackup.path);
        _recordingBackup = destinationBackup;
      }
      await partial.rename(target.path);
      published = true;
      final currentBackup = _recordingBackup;
      if (currentBackup != null && await currentBackup.exists()) await currentBackup.delete();
      if (mounted) setState(() => _success = t.universalMedia.captureSaved);
    } on Object {
      if (mounted) setState(() => _failure = t.universalMedia.captureFailed);
    } finally {
      if (!published && backup != null && await backup.exists() && target != null && !await target.exists()) {
        await backup.rename(target.path);
      }
      if (partial != null && await partial.exists()) await partial.delete();
      _recorder = null;
      _recordingTarget = null;
      _recordingPartial = null;
      _recordingBackup = null;
      _recordingStarted = null;
      _recording = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _chooseShareInput() async {
    if (_busy || _sharing) return;
    final generation = _generation;
    final profile = _profile;
    final result = await FilePicker.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.isEmpty || !mounted) return;
    _requireSession(generation: generation, profile: profile);
    final item = result.files.single;
    final kind = classifySourceFile(item.name);
    if (kind != SourceItemKind.video && kind != SourceItemKind.music && kind != SourceItemKind.audiobook) {
      setState(() => _failure = t.universalMedia.converterUnsupportedInput);
      return;
    }
    if (item.path == null) {
      setState(() => _failure = t.universalMedia.converterLocalOnly);
      return;
    }
    setState(() {
      _shareInput = File(item.path!);
      _shareInputName = item.name;
      _failure = null;
      _success = null;
    });
  }

  Future<void> _startSharing() async {
    final input = _shareInput;
    if (input == null || _busy || _sharing) return;
    final generation = _generation;
    final profile = _profile;
    try {
      _requireSession(generation: generation, profile: profile);
      setState(() {
        _busy = true;
        _failure = null;
        _success = null;
      });
      late final NetworkMediaStreamServer server;
      server = NetworkMediaStreamServer(
        onProgress: (_) {},
        onFailure: (_) {
          if (mounted) {
            setState(() {
              if (identical(_streamServer, server)) _streamServer = null;
              _failure = t.universalMedia.shareFailed;
            });
          }
        },
        onEnded: () {
          if (mounted) {
            setState(() {
              if (identical(_streamServer, server)) _streamServer = null;
              _success = t.universalMedia.shareEnded;
            });
          }
        },
      );
      _streamServer = server;
      await server.start(input);
      _requireSession(generation: generation, profile: profile);
      if (!mounted || !_appInForeground) {
        await server.stop();
        return;
      }
      setState(() {
        _success = t.universalMedia.shareActive;
      });
    } on ProcessException {
      _streamServer = null;
      if (mounted && generation == _generation && profile == _profile && _appInForeground) {
        setState(() => _failure = t.universalMedia.shareFfmpegMissing);
      }
    } on Object {
      _streamServer = null;
      if (mounted && generation == _generation && profile == _profile && _appInForeground) {
        setState(() => _failure = t.universalMedia.shareFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopSharing() async {
    final server = _streamServer;
    _streamServer = null;
    await server?.stop();
    if (mounted) setState(() => _success = t.universalMedia.shareStopped);
  }

  Future<void> _copyShareUrl(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showSnackBar(context, t.universalMedia.shareUrlCopied);
  }

  Future<void> _loadExtensions() async {
    final sources = _sources ?? context.read<SourceController>();
    try {
      await sources.ready;
      final generation = sources.generation;
      final profile = sources.profileId;
      if (profile == null) throw const SourceException(SourceFailure.unavailable);
      final value = await sources.repository.preference(profile, _extensionsKey);
      sources.requireSession(generation);
      if (sources.profileId != profile) throw const SourceException(SourceFailure.cancelled);
      final extensions = <MediaSearchExtension>[];
      final ids = <String>{};
      for (final raw in sourceList(value['items'])) {
        try {
          final extension = MediaSearchExtension.parseManifest(utf8.encode(jsonEncode(raw)));
          if (ids.add(extension.id)) extensions.add(extension);
        } on MediaExtensionException {
          // Ignore stale or manually edited profile data; valid extensions remain usable.
        }
      }
      if (mounted) {
        setState(() {
          _extensions = extensions;
          _selectedExtension = extensions.isEmpty ? null : extensions.first;
          _loadingExtensions = false;
          _profile = profile;
          _generation = generation;
        });
      }
    } on Object {
      if (mounted) setState(() => _loadingExtensions = false);
    }
  }

  Future<void> _saveExtensions(List<MediaSearchExtension> extensions) async {
    final sources = _sources ?? context.read<SourceController>();
    final profile = _profile;
    final generation = _generation;
    if (profile == null) throw const SourceException(SourceFailure.unavailable);
    sources.requireSession(generation);
    if (sources.profileId != profile) throw const SourceException(SourceFailure.cancelled);
    await sources.repository.savePreference(profile, _extensionsKey, {
      'items': extensions.map((extension) => extension.toJson()).toList(growable: false),
    });
    sources.requireSession(generation);
    if (sources.profileId != profile) throw const SourceException(SourceFailure.cancelled);
    if (mounted) {
      setState(() {
        _extensions = extensions;
        _selectedExtension = extensions.isEmpty ? null : extensions.first;
        _extensionResults = const [];
      });
    }
  }

  Future<void> _importExtension() async {
    if (_busy) return;
    final generation = _generation;
    final profile = _profile;
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
      allowMultiple: false,
    );
    if (selection == null || selection.files.isEmpty || !mounted) return;
    try {
      _requireSession(generation: generation, profile: profile);
      final picked = selection.files.single;
      if (picked.size > MediaSearchExtension.maxManifestBytes) {
        setState(() => _failure = t.universalMedia.extensionInvalidManifest);
        return;
      }
      final bytes = picked.bytes ?? (picked.path == null ? null : await File(picked.path!).readAsBytes());
      if (bytes == null) throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
      final extension = MediaSearchExtension.parseManifest(bytes);
      final replaces = _extensions.any((installed) => installed.id == extension.id);
      if (!mounted) return;
      final accepted = await showConfirmDialog(
        context,
        title: replaces ? t.universalMedia.extensionReplaceTitle : t.universalMedia.extensionInstallTitle,
        message:
            '${t.universalMedia.extensionService}: ${extension.name}\n'
            '${t.universalMedia.extensionEndpoint}: ${extension.host}\n\n'
            '${t.universalMedia.extensionConsent}',
        confirmText: replaces ? t.universalMedia.extensionReplace : t.universalMedia.extensionInstall,
      );
      if (!accepted || !mounted) return;
      _requireSession(generation: generation, profile: profile);
      setState(() {
        _busy = true;
        _failure = null;
      });
      final updated = [for (final item in _extensions.where((item) => item.id != extension.id)) item, extension];
      await _saveExtensions(updated);
    } on MediaExtensionException {
      if (mounted) setState(() => _failure = t.universalMedia.extensionInvalidManifest);
    } on Object {
      if (mounted) setState(() => _failure = t.universalMedia.extensionSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeExtension(MediaSearchExtension extension) async {
    final generation = _generation;
    final profile = _profile;
    final accepted = await showConfirmDialog(
      context,
      title: t.universalMedia.extensionRemoveTitle,
      message: t.universalMedia.extensionRemoveHelp,
      confirmText: t.universalMedia.extensionRemove,
      isDestructive: true,
    );
    if (!accepted || !mounted) return;
    try {
      _requireSession(generation: generation, profile: profile);
      setState(() {
        _busy = true;
        _failure = null;
      });
      await _saveExtensions(_extensions.where((item) => item.id != extension.id).toList(growable: false));
    } on Object {
      if (mounted) setState(() => _failure = t.universalMedia.extensionSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _searchExtension() async {
    final extension = _selectedExtension;
    final query = _extensionQuery.text.trim();
    if (extension == null || query.isEmpty || _searchingExtensions || _busy) return;
    final generation = _generation;
    final profile = _profile;
    try {
      _requireSession(generation: generation, profile: profile);
      setState(() {
        _searchingExtensions = true;
        _hasSearched = false;
        _extensionResults = const [];
        _failure = null;
      });
      final results = await MediaExtensionHost.search(extension, query);
      _requireSession(generation: generation, profile: profile);
      if (mounted) {
        setState(() {
          _extensionResults = results;
          _hasSearched = true;
        });
      }
    } on MediaExtensionException {
      if (mounted) setState(() => _failure = t.universalMedia.extensionSearchFailed);
    } on Object {
      if (mounted) setState(() => _failure = t.universalMedia.extensionSearchFailed);
    } finally {
      if (mounted) setState(() => _searchingExtensions = false);
    }
  }

  void _selectExtension(MediaSearchExtension? extension) {
    setState(() {
      _selectedExtension = extension;
      _extensionResults = const [];
      _hasSearched = false;
    });
  }

  Widget _modePicker() {
    final desktop = PlatformDetector.isDesktopOS();
    String label(_MediaToolMode value) => switch (value) {
      _MediaToolMode.capture => t.universalMedia.captureMode,
      _MediaToolMode.share => t.universalMedia.shareMode,
      _MediaToolMode.extensions => t.universalMedia.extensionsMode,
    };
    return DropdownButtonFormField<_MediaToolMode>(
      initialValue: desktop ? _mode : _MediaToolMode.extensions,
      isExpanded: true,
      decoration: InputDecoration(labelText: t.universalMedia.mediaTool),
      items: [
        if (desktop) DropdownMenuItem(value: _MediaToolMode.capture, child: Text(label(_MediaToolMode.capture))),
        if (desktop) DropdownMenuItem(value: _MediaToolMode.share, child: Text(label(_MediaToolMode.share))),
        DropdownMenuItem(value: _MediaToolMode.extensions, child: Text(label(_MediaToolMode.extensions))),
      ],
      onChanged: _recording || _sharing || _busy ? null : (value) => setState(() => _mode = value ?? _mode),
    );
  }

  Widget _capturePanel() {
    final isWayland =
        _captureSource?.inputFormat == 'x11grab' &&
        Platform.environment['XDG_SESSION_TYPE']?.toLowerCase() == 'wayland';
    String sourceLabel(MediaCaptureSource source) {
      if (source.kind != MediaCaptureKind.screen) return source.name;
      final separator = source.id.indexOf(':');
      final suffix = separator < 0 ? '' : source.id.substring(separator + 1);
      return suffix.isEmpty || source.id == 'screen:desktop'
          ? t.universalMedia.captureScreen
          : '${t.universalMedia.captureScreen} ($suffix)';
    }

    String audioLabel(MediaCaptureAudioSource source) =>
        source.id == 'audio:pulse-default' ? t.universalMedia.captureDefaultAudio : source.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.universalMedia.captureIntro),
        const SizedBox(height: 16),
        if (_discovering)
          const LinearProgressIndicator()
        else if (_captureSources.isEmpty)
          Text(t.universalMedia.captureNoDevices)
        else ...[
          DropdownButtonFormField<MediaCaptureSource>(
            initialValue: _captureSource,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.universalMedia.captureSource),
            items: [
              for (final source in _captureSources)
                DropdownMenuItem(
                  value: source,
                  child: Text(sourceLabel(source), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _recording ? null : (value) => setState(() => _captureSource = value),
          ),
          if (_captureAudioSources.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _captureAudioSource?.id ?? '',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.universalMedia.captureAudioSource,
                helperText: t.universalMedia.captureAudioHelp,
                helperMaxLines: 3,
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(t.universalMedia.captureAudioNone)),
                for (final source in _captureAudioSources)
                  DropdownMenuItem(
                    value: source.id,
                    child: Text(audioLabel(source), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _recording
                  ? null
                  : (id) => setState(() {
                      _captureAudioSource = null;
                      for (final source in _captureAudioSources) {
                        if (source.id == id) _captureAudioSource = source;
                      }
                    }),
            ),
          ],
          if (isWayland) ...[
            const SizedBox(height: 8),
            Text(t.universalMedia.captureWaylandHelp, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          Semantics(
            label: t.universalMedia.captureFrameRate,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 fps')),
                ButtonSegment(value: 30, label: Text('30 fps')),
                ButtonSegment(value: 60, label: Text('60 fps')),
              ],
              selected: {_frameRate},
              onSelectionChanged: _recording ? null : (values) => setState(() => _frameRate = values.first),
            ),
          ),
          const SizedBox(height: 12),
          Text(t.universalMedia.capturePrivacy),
          const SizedBox(height: 16),
          if (_recording) ...[
            Semantics(
              label: t.universalMedia.captureElapsedLabel,
              value: _recordingElapsed.toString().split('.').first,
              child: Text(_recordingElapsed.toString().split('.').first),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _stopRecording,
              icon: const AppIcon(Symbols.stop_circle_rounded),
              label: Text(t.universalMedia.captureStop),
            ),
          ] else
            FilledButton.icon(
              onPressed: _busy || _discovering || _captureSource == null ? null : _startRecording,
              icon: const AppIcon(Symbols.fiber_manual_record_rounded),
              label: Text(t.universalMedia.captureStart),
            ),
        ],
      ],
    );
  }

  Widget _sharePanel() {
    final server = _streamServer;
    final urls = server?.urls ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.universalMedia.shareIntro),
        const SizedBox(height: 12),
        Text(t.universalMedia.sharePrivacy),
        const SizedBox(height: 16),
        SourceTile(
          title: _shareInputName ?? t.universalMedia.shareChooseFile,
          subtitle: _shareInput == null ? t.universalMedia.shareChooseHelp : p.basename(_shareInput!.path),
          icon: Symbols.video_file_rounded,
          onTap: _busy || _sharing ? null : _chooseShareInput,
        ),
        const SizedBox(height: 16),
        if (_sharing && urls.isNotEmpty) ...[
          Center(
            child: Semantics(
              image: true,
              label: t.universalMedia.shareQrLabel,
              child: QrImageView(data: urls.first, size: 208, version: QrVersions.auto, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(t.universalMedia.shareQrHelp, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(t.universalMedia.shareHttpHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(t.universalMedia.shareOpenUrl, style: Theme.of(context).textTheme.titleMedium),
          for (final url in urls)
            Card(
              child: ListTile(
                title: SelectableText(url, textDirection: TextDirection.ltr),
                trailing: IconButton(
                  tooltip: t.universalMedia.shareCopyUrl,
                  onPressed: () => _copyShareUrl(url),
                  icon: const AppIcon(Symbols.content_copy_rounded),
                ),
              ),
            ),
          if (server?.expiresAt case final expires?) ...[
            Text(t.universalMedia.shareExpiresLabel),
            Text(
              '${MaterialLocalizations.of(context).formatCompactDate(expires)} · '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(expires))}',
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _stopSharing,
            icon: const AppIcon(Symbols.stop_circle_rounded),
            label: Text(t.universalMedia.shareStop),
          ),
        ] else if (_busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(t.universalMedia.shareStarting, textAlign: TextAlign.center),
        ] else
          FilledButton.icon(
            onPressed: _shareInput == null ? null : _startSharing,
            icon: const AppIcon(Symbols.wifi_tethering_rounded),
            label: Text(t.universalMedia.shareStart),
          ),
      ],
    );
  }

  Widget _extensionPanel() {
    final selected = _selectedExtension;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.universalMedia.extensionsIntro),
        const SizedBox(height: 8),
        Text(t.universalMedia.extensionsPrivacy, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _importExtension,
          icon: const AppIcon(Symbols.add_rounded),
          label: Text(t.universalMedia.extensionImport),
        ),
        const SizedBox(height: 16),
        if (_loadingExtensions)
          const LinearProgressIndicator()
        else if (_extensions.isEmpty)
          Text(t.universalMedia.extensionEmpty)
        else ...[
          DropdownButtonFormField<MediaSearchExtension>(
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.universalMedia.extensionChoose),
            items: [
              for (final extension in _extensions)
                DropdownMenuItem(
                  value: extension,
                  child: Text(extension.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy || _searchingExtensions ? null : _selectExtension,
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            Text(t.universalMedia.extensionSearchConsent, style: Theme.of(context).textTheme.bodySmall),
            Text(t.universalMedia.extensionEndpoint, style: Theme.of(context).textTheme.labelMedium),
            SelectableText(selected.host, textDirection: TextDirection.ltr),
            FocusableTextFormField(
              controller: _extensionQuery,
              textInputAction: TextInputAction.search,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: t.universalMedia.extensionSearchLabel,
                helperText: selected.description.isEmpty ? selected.host : selected.description,
                helperMaxLines: 3,
              ),
              onChanged: (_) => setState(() => _hasSearched = false),
              onFieldSubmitted: (_) => _searchExtension(),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _searchingExtensions || _busy || _extensionQuery.text.trim().isEmpty
                    ? null
                    : _searchExtension,
                icon: _searchingExtensions
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const AppIcon(Symbols.search_rounded),
                label: Text(
                  _searchingExtensions ? t.universalMedia.extensionSearching : t.universalMedia.extensionSearch,
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _removeExtension(selected),
              icon: const AppIcon(Symbols.delete_outline_rounded),
              label: Text(t.universalMedia.extensionRemove),
            ),
            if (_hasSearched && !_searchingExtensions && _extensionResults.isEmpty) ...[
              const SizedBox(height: 8),
              Text(t.universalMedia.extensionNoResults),
            ],
            for (final result in _extensionResults)
              SourceTile(
                key: ValueKey(result.uri),
                title: result.title,
                subtitle: result.subtitle ?? result.uri.host,
                icon: Symbols.play_arrow_rounded,
                onTap: _busy ? null : () => Navigator.pop(context, result.uri),
              ),
          ],
        ],
        const SizedBox(height: 24),
        Text(t.universalMedia.cliTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(t.universalMedia.cliHelp),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 8, end: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(child: SelectableText(_cliCommandExample, textDirection: TextDirection.ltr)),
                IconButton(
                  tooltip: t.universalMedia.cliCopyExample,
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: _cliCommandExample));
                    if (mounted) showSnackBar(context, t.universalMedia.cliCopied);
                  },
                  icon: const AppIcon(Symbols.content_copy_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.universalMedia.mediaToolsTitle),
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
                  Text(t.universalMedia.mediaToolsIntro, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text(t.universalMedia.mediaToolsAccessibility, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 20),
                  _modePicker(),
                  const SizedBox(height: 20),
                  if (_mode == _MediaToolMode.capture)
                    _capturePanel()
                  else if (_mode == _MediaToolMode.share)
                    _sharePanel()
                  else
                    _extensionPanel(),
                  if (_success != null) ...[
                    const SizedBox(height: 16),
                    Semantics(liveRegion: true, child: Text(_success!)),
                  ],
                  if (_failure != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(_failure!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                  if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
