import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../../mpv/mpv.dart';
import '../../../mpv/player/platform/player_android.dart';
import '../../../services/file_picker_service.dart';
import '../../../services/subtitle_ai_service.dart';
import '../../../services/subtitle_retimer.dart';
import '../../../services/subtitle_sync_service.dart';
import '../../../services/subtitle_translation_service.dart';
import '../../../services/subtitle_playback_transcription_service.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';

/// Reviewable local subtitle operations. The source file is never modified;
/// every generated, translated, or synchronized result is written to a new
/// temporary SRT and attached as a separate external track.
class SubtitleAiSheet extends StatefulWidget {
  const SubtitleAiSheet({super.key, required this.player});

  final Player player;

  @override
  State<SubtitleAiSheet> createState() => _SubtitleAiSheetState();
}

class _SubtitleAiSheetState extends State<SubtitleAiSheet> {
  bool _busy = false;
  bool _translateSpeechToEnglish = false;
  bool _translationSupported = false;
  bool _allowMobileData = false;
  bool _requestTranslationCuda = false;
  bool _bilingualTranslation = false;
  final TextEditingController _glossaryController = TextEditingController();
  bool _playbackCaptureSupported = false;
  String? _status;
  String? _error;
  SubtitleInferenceProvider _provider = SubtitleInferenceProvider.cpu;
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.spanish;

  @override
  void dispose() {
    _glossaryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_refreshCapabilityState());
  }

  Future<void> _refreshCapabilityState() async {
    var translationSupported = false;
    final androidPlayer = widget.player is PlayerAndroid ? widget.player as PlayerAndroid : null;
    final playbackCaptureSupported = androidPlayer != null && !androidPlayer.usingMpvFallback && !androidPlayer.isLivePlayback;
    try {
      translationSupported = SubtitleTranslationService.desktopPlatformSupported ||
          await SubtitleTranslationService.isSupportedOnCurrentDevice();
    } catch (_) {
      translationSupported = false;
    }
    if (!mounted) return;
    setState(() {
      _translationSupported = translationSupported;
      _playbackCaptureSupported = playbackCaptureSupported;
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });
    try {
      await operation();
    } catch (error) {
      if (mounted) setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ensureSpeechModel() async {
    if (_provider == SubtitleInferenceProvider.cpu || _provider == SubtitleInferenceProvider.desktopGpu) return;
    if (await SubtitleAiService.instance.isModelInstalled()) return;
    if (mounted) setState(() => _status = 'Downloading the English speech model and speech detector…');
    await SubtitleAiService.instance.downloadModel(
      onProgress: (phase, received, total) {
        if (!mounted) return;
        final percent = total == 0 ? '' : ' (${(received * 100 / total).round()}%)';
        setState(() => _status = '$phase$percent');
      },
    );
  }

  Future<String?> _pickWav() async {
    final result = await FilePickerService.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav'],
    );
    if (!mounted || result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (p.extension(file.name).toLowerCase() != '.wav') {
      throw const FormatException('Choose a WAV file exported from the same title and audio track.');
    }
    if (file.path != null) return file.path!;
    final bytes = file.bytes;
    if (bytes == null || bytes.lengthInBytes < 44 || bytes.lengthInBytes > 256 * 1024 * 1024) {
      throw const FormatException('This platform did not provide a bounded local WAV file.');
    }
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, 'subtitle_audio_${DateTime.now().microsecondsSinceEpoch}.wav');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<(List<SubtitleCue>, String)?> _pickSubtitleCues() async {
    final result = await FilePickerService.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ass', 'srt', 'ssa', 'vtt'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final extension = p.extension(file.name).toLowerCase();
    if (!const {'.ass', '.srt', '.ssa', '.vtt'}.contains(extension)) {
      throw const FormatException('Choose an SRT, VTT, ASS, or SSA text subtitle.');
    }
    if (file.size <= 0 || file.size > SubtitleRetimer.maximumInputBytes) {
      throw const FormatException('Subtitle input must be between 1 byte and 5 MiB.');
    }
    Uint8List bytes;
    if (file.bytes != null) {
      bytes = Uint8List.fromList(file.bytes!);
    } else if (file.path != null) {
      final source = File(file.path!);
      if (await source.length() != file.size) {
        throw const FormatException('Subtitle file changed while it was being selected.');
      }
      bytes = await source.readAsBytes();
    } else {
      throw const FormatException('This platform did not provide subtitle file bytes.');
    }
    if (bytes.isEmpty || bytes.lengthInBytes > SubtitleRetimer.maximumInputBytes) {
      throw const FormatException('Subtitle input must be between 1 byte and 5 MiB.');
    }
    return (SubtitleRetimer.parseCues(sourceBytes: bytes, extension: extension), file.name);
  }

  Future<void> _transcribe() => _run(() async {
    final wavPath = await _pickWav();
    if (wavPath == null || !mounted) return;
    await _ensureSpeechModel();
    final translateToEnglish = _translateSpeechToEnglish &&
        (_provider == SubtitleInferenceProvider.cpu || _provider == SubtitleInferenceProvider.desktopGpu);
    setState(() => _status = translateToEnglish
        ? 'Transcribing and translating speech to English locally…'
        : 'Transcribing speech locally on this device…');
    final result = await SubtitleAiService.instance.transcribeWav(
      wavPath,
      provider: _provider,
      translateToEnglish: translateToEnglish,
      onProgress: (phase, received, total) {
        if (!mounted) return;
        final percent = total == 0 ? '' : ' (${(received * 100 / total).round()}%)';
        setState(() => _status = '$phase$percent');
      },
    );
    await _writeAndApply(result.cues);
    if (!mounted) return;
    final providerLabel = result.fellBackToCpu
        ? '${result.requestedProvider.displayName} request unavailable; CPU fallback'
        : result.runtimeProvider.toUpperCase();
    setState(() {
      _status = 'Generated ${result.cues.length} cues from ${(result.durationMs / 60000).ceil()} minutes of audio. '
          '${result.translatedToEnglish ? 'Speech translated to English' : 'Detected language: ${result.detectedLanguage}'}. '
          'Requested/initialized backend: $providerLabel. Original audio remains unchanged.';
    });
    await _showApplied();
  });

  Future<void> _synchronize({required bool repairCuts}) => _run(() async {
    final wavPath = await _pickWav();
    if (wavPath == null || !mounted) return;
    final selected = await _pickSubtitleCues();
    if (selected == null || !mounted) return;
    await _ensureSpeechModel();
    setState(() => _status = 'Transcribing audio and aligning subtitle text…');
    final transcription = await SubtitleAiService.instance.transcribeWav(
      wavPath,
      provider: _provider,
      onProgress: (phase, received, total) {
        if (!mounted) return;
        final percent = total == 0 ? '' : ' (${(received * 100 / total).round()}%)';
        setState(() => _status = '$phase$percent');
      },
    );
    final aligned = SubtitleSyncService.synchronize(
      subtitleCues: selected.$1,
      speechCues: transcription.cues,
      mediaDurationMs: transcription.durationMs,
      repairCuts: repairCuts,
    );
    await _writeAndApply(aligned.cues);
    if (!mounted) return;
    final percent = (aligned.meanMatchConfidence * 100).round();
    setState(() {
      _status = '${repairCuts ? 'Cut repair' : 'Automatic sync'} applied to ${aligned.matchedCueCount} '
          'of ${aligned.totalCueCount} cues ($percent% match confidence). '
          '${aligned.discontinuityCount} timing discontinuities detected; '
          'rate ${aligned.appliedRate.toStringAsFixed(4)}×, base offset ${aligned.globalOffsetMs} ms. '
          'Original: ${selected.$2}.';
    });
    await _showApplied();
  });

  Future<void> _captureLivePlayback() => _run(() async {
    final player = widget.player;
    if (player is! PlayerAndroid) {
      throw UnsupportedError('Live subtitle capture is available only through Android ExoPlayer.');
    }
    final service = SubtitlePlaybackTranscriptionService.instance;
    if (service.isRunning || service.hasActiveSession) {
      await service.stop();
      if (!mounted) return;
      setState(() => _status = service.status);
      return;
    }
    await service.start(
      player,
      onProgress: (phase, received, total) {
        if (!mounted) return;
        final percent = total == 0 ? '' : ' (' + (received * 100 / total).round().toString() + '%)';
        setState(() => _status = phase + percent);
      },
    );
    if (!mounted) return;
    setState(() => _status = service.status);
  });

  Future<void> _synchronizeCapturedPlayback({required bool repairCuts}) => _run(() async {
    final transcript = SubtitlePlaybackTranscriptionService.instance.recentTranscript;
    if (transcript == null || transcript.cues.length < 3) {
      throw const FormatException('Capture at least three speech cues before synchronizing.');
    }
    final selected = await _pickSubtitleCues();
    if (selected == null || !mounted) return;
    final playerDuration = widget.player.state.duration.inMilliseconds;
    final durationMs = playerDuration > 0 ? playerDuration : transcript.durationMs;
    setState(() => _status = 'Matching the captured speech against subtitle text…');
    final aligned = SubtitleSyncService.synchronize(
      subtitleCues: selected.$1,
      speechCues: transcript.cues,
      mediaDurationMs: durationMs,
      repairCuts: repairCuts,
      preserveUnmatchedOutsideEvidence: repairCuts,
    );
    await _writeAndApply(aligned.cues);
    if (!mounted) return;
    final percent = (aligned.meanMatchConfidence * 100).round();
    setState(() {
      _status = 'Captured-playback ' + (repairCuts ? 'cut repair' : 'sync') +
          ' applied to ' + aligned.matchedCueCount.toString() + ' of ' + aligned.totalCueCount.toString() +
          ' cues (' + percent.toString() + '% match confidence). ' +
          aligned.discontinuityCount.toString() + ' timing discontinuities detected. ' +
          (repairCuts ? 'Cues outside captured evidence kept their original timing. ' : '') +
          'Original: ' + selected.$2 + '.';
    });
    await _showApplied();
  });

  Map<String, String> _parseGlossary() {
    final source = _glossaryController.text.trim();
    if (source.isEmpty) return const {};
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Glossary must be a JSON object mapping source terms to translated terms.');
    }
    final glossary = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Every glossary key and value must be a string.');
      }
      glossary[entry.key as String] = entry.value as String;
    }
    return glossary;
  }

  Future<void> _translate() => _run(() async {
    if (!await SubtitleTranslationService.isSupportedOnCurrentDevice()) {
      throw UnsupportedError(
        SubtitleTranslationService.desktopPlatformSupported
            ? 'Install Argos Translate in Python and the selected language pair to translate locally on desktop.'
            : 'On-device translation is available on supported phones and tablets only.',
      );
    }
    final selected = await _pickSubtitleCues();
    if (selected == null || !mounted) return;
    setState(() => _status = SubtitleTranslationService.desktopPlatformSupported
        ? 'Starting local translation…'
        : 'Preparing on-device language models…');
    final result = await SubtitleTranslationService.translateCues(
      cues: selected.$1,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      allowMobileData: _allowMobileData,
      requestDesktopCuda: _requestTranslationCuda,
      bilingual: _bilingualTranslation,
      glossary: _parseGlossary(),
      onProgress: (completed, total) {
        if (mounted) setState(() => _status = 'Translating cue $completed of $total on this device…');
      },
    );
    await _writeAndApply(result.cues);
    if (!mounted) return;
    setState(() {
      _status = 'Translated ${result.cues.length} cues from '
          '${SubtitleTranslationService.languageLabel(_sourceLanguage)} to '
          '${SubtitleTranslationService.languageLabel(_targetLanguage)}. '
          'Timing and original subtitle file were preserved. ${result.backendLabel}.';
    });
    await _showApplied();
  });

  Future<void> _writeAndApply(List<SubtitleCue> cues) async {
    final bytes = SubtitleSyncService.writeSrt(cues);
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, 'plezyng_subtitle_${DateTime.now().microsecondsSinceEpoch}.srt');
    await File(path).writeAsBytes(bytes, flush: true);
    await widget.player.command(['sub-add', path, 'select']);
  }

  Future<void> _showApplied() async {
    if (!mounted) return;
    // Keep the result attached to the current session. The path is app-managed
    // temporary storage and will be removed by the OS when its cache is cleared.
    OverlaySheetController.of(context).refocus();
  }

  String _readableError(Object error) {
    if (error is UnsupportedError || error is FormatException || error is ArgumentError || error is StateError) {
      return error.toString().replaceFirst(RegExp(r'^(Unsupported operation|FormatException|Invalid argument|Bad state):\s*'), '');
    }
    return 'Subtitle operation failed: $error';
  }

  Widget _languageSelector({
    required String label,
    required TranslateLanguage value,
    required ValueChanged<TranslateLanguage?> onChanged,
  }) {
    return Expanded(
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TranslateLanguage>(
            value: value,
            isExpanded: true,
            items: SubtitleTranslationService.languages
                .map((language) => DropdownMenuItem(
                      value: language,
                      child: Text(SubtitleTranslationService.languageLabel(language), overflow: TextOverflow.ellipsis),
                    ))
                .toList(growable: false),
            onChanged: _busy ? null : onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = SubtitleAiService.availableProviderRequests;
    if (!providers.contains(_provider)) _provider = SubtitleInferenceProvider.cpu;
    return BaseVideoControlSheet(
      title: 'AI subtitles',
      icon: Symbols.auto_awesome_rounded,
      onBack: () => OverlaySheetController.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Text(
            'WAV transcription and sync use a 16-bit PCM WAV from the same title and audio track. Android ExoPlayer also supports an opt-in, local CPU caption tap while watching VOD; it covers only the portion played. MPV fallback and other players do not expose decoded audio.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Inference backend', border: OutlineInputBorder()),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SubtitleInferenceProvider>(
                value: _provider,
                isExpanded: true,
                items: providers
                    .map((provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider.displayName, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(growable: false),
                onChanged: _busy || providers.length < 2
                    ? null
                    : (value) => setState(() {
                        _provider = value ?? SubtitleInferenceProvider.cpu;
                        if (_provider != SubtitleInferenceProvider.cpu &&
                            _provider != SubtitleInferenceProvider.desktopGpu) {
                          _translateSpeechToEnglish = false;
                        }
                      }),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _provider == SubtitleInferenceProvider.desktopGpu
                ? 'Desktop GPU uses CUDA or Vulkan only when compiled into the native Whisper runtime. Device discovery and execution can vary by packaged build; failures restart on CPU.'
                : 'CPU is the baseline. Core ML/QNN/RKNN are provider requests for the installed native runtime; unsupported requests retry on CPU, and per-operation hardware placement is not reported.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_playbackCaptureSupported) ...[
            const Divider(height: 24),
            Text('Live captions from playback', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Android ExoPlayer copies a bounded PCM window after decoding. The local Whisper model runs on CPU. Audio is not saved; captions arrive with a short delay and may be unavailable during tunneling, audio offload, or unsupported output formats.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: SubtitlePlaybackTranscriptionService.instance,
              builder: (context, _) {
                final service = SubtitlePlaybackTranscriptionService.instance;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (service.status != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(service.status!, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    FocusableListTile(
                      leading: AppIcon(
                        service.isStarting
                            ? Symbols.sync_rounded
                            : (service.isRunning || service.hasActiveSession)
                                ? Symbols.stop_circle_rounded
                                : Symbols.closed_caption_rounded,
                      ),
                      title: Text(
                        service.isStarting
                            ? 'Preparing live captions…'
                            : (service.isRunning || service.hasActiveSession)
                                ? 'Stop live capture'
                                : 'Start live captions',
                      ),
                      subtitle: Text(
                        service.isStarting
                            ? 'Loading the local Whisper model'
                            : (service.isRunning || service.hasActiveSession)
                                ? 'Stop capture and retain the transcript for sync'
                                : 'VOD on Android ExoPlayer; downloads the local Whisper model on first use',
                      ),
                      onTap: (_busy || service.isStarting) ? null : () => unawaited(_captureLivePlayback()),
                    ),
                    if (service.hasRecentTranscript && !service.isRunning) ...[
                      FocusableListTile(
                        leading: const AppIcon(Symbols.sync_rounded),
                        title: const Text('Sync from captured playback'),
                        subtitle: const Text('Aligns the watched portion against an existing subtitle'),
                        onTap: _busy ? null : () => unawaited(_synchronizeCapturedPlayback(repairCuts: false)),
                      ),
                      FocusableListTile(
                        leading: const AppIcon(Symbols.content_cut_rounded),
                        title: const Text('Repair cuts from captured playback'),
                        subtitle: const Text('Preserves cue timing outside speech-matched evidence'),
                        onTap: _busy ? null : () => unawaited(_synchronizeCapturedPlayback(repairCuts: true)),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
          const Divider(height: 24),
          if (_provider == SubtitleInferenceProvider.cpu || _provider == SubtitleInferenceProvider.desktopGpu)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Translate detected speech to English'),
              subtitle: const Text('Used only for generation; sync always transcribes the source language. Whisper translates audio instead of transcribing it.'),
              value: _translateSpeechToEnglish,
              onChanged: _busy ? null : (value) => setState(() => _translateSpeechToEnglish = value),
            ),
          FocusableListTile(
            leading: const AppIcon(Symbols.graphic_eq_rounded),
            title: Text(_translateSpeechToEnglish ? 'Translate speech to English from WAV' : 'Generate subtitles from WAV'),
            subtitle: Text(_provider == SubtitleInferenceProvider.cpu || _provider == SubtitleInferenceProvider.desktopGpu
                ? 'Downloads a verified multilingual Whisper model on first use'
                : 'Downloads a verified English model on first use'),
            onTap: _busy ? null : () => unawaited(_transcribe()),
          ),
          FocusableListTile(
            leading: const AppIcon(Symbols.sync_rounded),
            title: const Text('Automatically sync an existing subtitle'),
            subtitle: const Text('Aligns SRT, VTT, ASS, or SSA text against local speech recognition'),
            onTap: _busy ? null : () => unawaited(_synchronize(repairCuts: false)),
          ),
          FocusableListTile(
            leading: const AppIcon(Symbols.content_cut_rounded),
            title: const Text('Repair cuts and sync'),
            subtitle: const Text('Uses piecewise timing where subtitle/audio text anchors suggest a cut offset change'),
            onTap: _busy ? null : () => unawaited(_synchronize(repairCuts: true)),
          ),
          if (_translationSupported) ...[
            const Divider(height: 24),
            Text('Local subtitle translation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              SubtitleTranslationService.desktopPlatformSupported
                  ? 'Desktop uses optional local Argos Translate. Install its Python package and the source-to-target language model; set PLEZY_ARGOS_PYTHON if python/python3 is not on PATH.'
                  : 'Mobile translation uses on-device ML Kit models.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _languageSelector(
                  label: 'Source',
                  value: _sourceLanguage,
                  onChanged: (value) => setState(() => _sourceLanguage = value ?? _sourceLanguage),
                ),
                const SizedBox(width: 8),
                _languageSelector(
                  label: 'Target',
                  value: _targetLanguage,
                  onChanged: (value) => setState(() => _targetLanguage = value ?? _targetLanguage),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bilingual subtitle output'),
              subtitle: const Text('Show the original line followed by its translation in each cue'),
              value: _bilingualTranslation,
              onChanged: _busy ? null : (value) => setState(() => _bilingualTranslation = value),
            ),
            TextField(
              controller: _glossaryController,
              minLines: 2,
              maxLines: 4,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Translation glossary (JSON)',
                hintText: '{"TARDIS":"TARDIS","The Doctor":"El Doctor"}',
                helperText: 'Protects up to 200 whole terms. Source subtitle text is never changed.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (SubtitleTranslationService.mobilePlatformSupported)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow language-model downloads over mobile data'),
                value: _allowMobileData,
                onChanged: _busy ? null : (value) => setState(() => _allowMobileData = value),
              ),
            if (SubtitleTranslationService.desktopPlatformSupported &&
                (Platform.isWindows || Platform.isLinux))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Request Argos CUDA'),
                subtitle: const Text(
                  'Requires a CUDA-enabled Argos/CTranslate2 install and an NVIDIA driver. If the request fails, translation retries on CPU; actual per-operation placement is not reported.',
                ),
                value: _requestTranslationCuda,
                onChanged: _busy ? null : (value) => setState(() => _requestTranslationCuda = value),
              ),
            Text(
              SubtitleTranslationService.desktopPlatformSupported
                  ? 'Subtitle text stays local. Argos does not report per-cue hardware placement; GPU requests are best-effort.'
                  : 'Translation runs locally through ML Kit. Its CPU/GPU choice is not exposed by the provider.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            FocusableListTile(
              leading: const AppIcon(Symbols.translate_rounded),
              title: const Text('Translate an existing subtitle'),
              subtitle: const Text('Timing and source file remain unchanged'),
              onTap: _busy ? null : () => unawaited(_translate()),
            ),
          ],
        ],
      ),
    );
  }
}
