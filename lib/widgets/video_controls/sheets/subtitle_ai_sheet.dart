import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../../mpv/mpv.dart';
import '../../../media/ids.dart';
import '../../../profiles/active_profile_provider.dart';
import '../../../mpv/player/platform/player_android.dart';
import '../../../services/file_picker_service.dart';
import '../../../services/subtitle_ai_service.dart';
import '../../../services/subtitle_retimer.dart';
import '../../../services/subtitle_sync_service.dart';
import '../../../services/subtitle_translation_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/subtitle_playback_transcription_service.dart';
import '../../../utils/provider_extensions.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';

/// Reviewable local subtitle operations. The source file is never modified;
/// every generated, translated, or synchronized result is written to a new
/// temporary SRT and attached as a separate external track.
enum _SubtitleReviewChoice { discard, player, serverAndPlayer }

class SubtitleAiSheet extends StatefulWidget {
  const SubtitleAiSheet({
    super.key,
    required this.player,
    this.serverId,
    this.ratingKey,
    this.mediaIndex = 0,
    this.seriesKey,
    this.selectedSubtitleBurnedIn = false,
  });

  final Player player;
  final String? serverId;
  final String? ratingKey;
  final int mediaIndex;
  final String? seriesKey;
  final bool selectedSubtitleBurnedIn;

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
  bool _useSeriesGlossary = false;
  final TextEditingController _glossaryController = TextEditingController();
  final Map<String, String> _glossaryDrafts = <String, String>{};
  bool _playbackCaptureSupported = false;
  bool _lastResultUploadedToServer = false;
  String? _status;
  String? _error;
  SubtitleInferenceProvider _provider = SubtitleInferenceProvider.cpu;
  String _speechLanguageCode = 'auto';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadGlossaryForCurrentPair());
      if (mounted) unawaited(_loadSpeechLanguageForProfile());
    });
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
      languageCode: _speechLanguageCode == 'auto' ? null : _speechLanguageCode,
      onProgress: (phase, received, total) {
        if (!mounted) return;
        final percent = total == 0 ? '' : ' (${(received * 100 / total).round()}%)';
        setState(() => _status = '$phase$percent');
      },
    );
    if (!await _writeAndApply(result.cues, operationLabel: 'Generated subtitles', operationLanguageCode: result.translatedToEnglish ? 'en' : result.detectedLanguage)) return;
    if (!mounted) return;
    final providerLabel = result.fellBackToCpu
        ? '${result.requestedProvider.displayName} request unavailable; CPU fallback'
        : result.runtimeProvider.toUpperCase();
    setState(() {
      _status = 'Generated ${result.cues.length} cues from ${(result.durationMs / 60000).ceil()} minutes of audio. '
          '${result.translatedToEnglish ? 'Speech translated to English' : 'Detected language: ${result.detectedLanguage}'}. '
          'Requested/initialized backend: $providerLabel. Original audio remains unchanged.'
          '${_lastResultUploadedToServer ? ' Uploaded to the server library.' : ''}';
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
      languageCode: _speechLanguageCode == 'auto' ? null : _speechLanguageCode,
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
    if (!await _writeAndApply(
      aligned.cues,
      operationLabel: repairCuts ? 'Cut repair' : 'Automatic sync',
      operationLanguageCode: transcription.detectedLanguage,
    )) return;
    if (!mounted) return;
    final percent = (aligned.meanMatchConfidence * 100).round();
    setState(() {
      _status = '${repairCuts ? 'Cut repair' : 'Automatic sync'} applied to ${aligned.matchedCueCount} '
          'of ${aligned.totalCueCount} cues ($percent% match confidence). '
          '${aligned.discontinuityCount} timing discontinuities detected; '
          'rate ${aligned.appliedRate.toStringAsFixed(4)}×, base offset ${aligned.globalOffsetMs} ms. '
          'Original: ${selected.$2}.'
          '${_lastResultUploadedToServer ? ' Uploaded to the server library.' : ''}';
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
      languageCode: _speechLanguageCode == 'auto' ? null : _speechLanguageCode,
      onProgress: (phase, received, total) {
        if (!mounted) return;
        final percent = total == 0 ? '' : ' (' + (received * 100 / total).round().toString() + '%)';
        setState(() => _status = phase + percent);
      },
    );
    if (!mounted) return;
    setState(() => _status = service.status);
  });

  Future<void> _synchronizeToReference({required bool repairCuts}) => _run(() async {
    setState(() => _status = 'Choose the subtitle that needs synchronization…');
    final target = await _pickSubtitleCues();
    if (target == null || !mounted) return;
    setState(() => _status = 'Choose an already synchronized subtitle in the same language…');
    final reference = await _pickSubtitleCues();
    if (reference == null || !mounted) return;
    if (target.$1.length == reference.$1.length &&
        List.generate(target.$1.length, (index) => index).every((index) {
          final left = target.$1[index];
          final right = reference.$1[index];
          return left.startMs == right.startMs && left.endMs == right.endMs && left.text == right.text;
        })) {
      throw const FormatException('Choose a different reference subtitle; the two files contain identical cues.');
    }
    final durationMs = widget.player.state.duration.inMilliseconds;
    if (durationMs <= 0) {
      throw const StateError('The player must expose media duration for subtitle-to-subtitle synchronization.');
    }
    setState(() => _status = 'Matching both subtitles and aligning timing…');
    final aligned = SubtitleSyncService.synchronizeAgainstReference(
      subtitleCues: target.$1,
      referenceCues: reference.$1,
      mediaDurationMs: durationMs,
      repairCuts: repairCuts,
    );
    if (!await _writeAndApply(
      aligned.cues,
      operationLabel: repairCuts ? 'Reference cut repair' : 'Subtitle-reference sync',
    )) return;
    if (!mounted) return;
    final percent = (aligned.meanMatchConfidence * 100).round();
    setState(() {
      _status = '${repairCuts ? 'Cut repair' : 'Subtitle-reference sync'} applied to '
          '${aligned.matchedCueCount} of ${aligned.totalCueCount} cues ($percent% match confidence). '
          '${aligned.discontinuityCount} timing discontinuities detected. '
          'Reference: ${reference.$2}. Original: ${target.$2}.'
          '${_lastResultUploadedToServer ? ' Uploaded to the server library.' : ''}';
    });
    await _showApplied();
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
    if (!await _writeAndApply(
      aligned.cues,
      operationLabel: repairCuts ? 'Captured-playback cut repair' : 'Captured-playback sync',
      operationLanguageCode: transcript.detectedLanguage,
    )) return;
    if (!mounted) return;
    final percent = (aligned.meanMatchConfidence * 100).round();
    setState(() {
      _status = 'Captured-playback ' + (repairCuts ? 'cut repair' : 'sync') +
          ' applied to ' + aligned.matchedCueCount.toString() + ' of ' + aligned.totalCueCount.toString() +
          ' cues (' + percent.toString() + '% match confidence). ' +
          aligned.discontinuityCount.toString() + ' timing discontinuities detected. ' +
          (repairCuts ? 'Cues outside captured evidence kept their original timing. ' : '') +
          'Original: ' + selected.$2 + '.' + (_lastResultUploadedToServer ? ' Uploaded to the server library.' : '');
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

  String? get _activeProfileId {
    try {
      return context.read<ActiveProfileProvider>().activeId;
      return context.read<ActiveProfileProvider>().activeId;
    } catch (_) {
      return null;
    }
  }

  String _currentGlossaryPairKey() {
    String code(TranslateLanguage language) => language.bcpCode.toLowerCase().split('-').first;
    return '${code(_sourceLanguage)}>${code(_targetLanguage)}';
  }

  String _currentGlossaryDraftKey() =>
      '${_useSeriesGlossary ? 'series:${widget.seriesKey}' : 'profile'}|${_currentGlossaryPairKey()}';

  Future<void> _loadSpeechLanguageForProfile() async {
    final profileId = _activeProfileId;
    if (profileId == null) return;
    try {
      final code = SettingsService.instance.read(SettingsService.subtitleSpeechLanguageForProfile(profileId));
      if (!mounted) return;
      if (code == 'auto' || _whisperLanguagesByCode().containsKey(code)) {
        setState(() => _speechLanguageCode = code);
      }
    } catch (_) {
      // A corrupt or stale preference should not block subtitle generation.
    }
  }

  Future<void> _saveSpeechLanguageForProfile(String code) async {
    final profileId = _activeProfileId;
    if (profileId == null) return;
    try {
      await SettingsService.instance.write(SettingsService.subtitleSpeechLanguageForProfile(profileId), code);
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not save the speech language preference for this profile.');
    }
  }

  Future<void> _loadGlossaryForCurrentPair() async {
    final pairKey = _currentGlossaryPairKey();
    final draft = _glossaryDrafts[_currentGlossaryDraftKey()];
    final profileId = _activeProfileId;
    Map<String, String> saved = const {};
    if (draft == null && profileId != null) {
      try {
        saved = SubtitleTranslationService.loadGlossaryForProfile(
          profileId: profileId,
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
          seriesId: _useSeriesGlossary ? widget.seriesKey : null,
        );
      } catch (_) {
        saved = const {};
      }
    }
    if (!mounted) return;
    _glossaryController.text = draft ?? (saved.isEmpty ? '' : const JsonEncoder.withIndent('  ').convert(saved));
  }

  void _changeTranslationLanguage({required bool source, required TranslateLanguage? value}) {
    if (value == null || (source ? value == _sourceLanguage : value == _targetLanguage)) return;
    _glossaryDrafts[_currentGlossaryDraftKey()] = _glossaryController.text;
    if (_glossaryDrafts.length > 16) _glossaryDrafts.remove(_glossaryDrafts.keys.first);
    setState(() {
      if (source) {
        _sourceLanguage = value;
      } else {
        _targetLanguage = value;
      }
    });
    unawaited(_loadGlossaryForCurrentPair());
  }

  Future<void> _saveGlossary() async {
    final profileId = _activeProfileId;
    if (profileId == null) {
      throw StateError('An active profile is required to save a translation glossary.');
    }
    final glossary = _parseGlossary();
    await SubtitleTranslationService.saveGlossaryForProfile(
      profileId: profileId,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      seriesId: _useSeriesGlossary ? widget.seriesKey : null,
      glossary: glossary,
    );
    _glossaryDrafts[_currentGlossaryDraftKey()] = _glossaryController.text;
    if (mounted) setState(() => _status = _useSeriesGlossary ? 'Saved glossary override for this series and language pair.' : 'Saved glossary for this profile and language pair.');
  }

  Future<void> _prepareTranslationModels() => _run(() async {
    await SubtitleTranslationService.prepareMobileModels(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      allowMobileData: _allowMobileData,
      onStatus: (status) {
        if (mounted) setState(() => _status = status);
      },
    );
    if (mounted) setState(() => _status = 'Selected language models are ready for offline translation.');
  });

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
    final glossary = _parseGlossary();
    final profileId = _activeProfileId;
    if (profileId != null) {
      await SubtitleTranslationService.saveGlossaryForProfile(
        profileId: profileId,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      seriesId: _useSeriesGlossary ? widget.seriesKey : null,
        glossary: glossary,
      );
      _glossaryDrafts[_currentGlossaryDraftKey()] = _glossaryController.text;
    }
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
      glossary: glossary,
      onProgress: (completed, total) {
        if (mounted) setState(() => _status = 'Translating cue $completed of $total on this device…');
      },
    );
    if (result.cues.length != selected.$1.length) {
      throw StateError('Translation changed the cue count. No output was attached.');
    }
    for (var index = 0; index < result.cues.length; index++) {
      final sourceCue = selected.$1[index];
      final translatedCue = result.cues[index];
      if (translatedCue.startMs != sourceCue.startMs || translatedCue.endMs != sourceCue.endMs) {
        throw StateError('Translation changed cue timing at cue ${sourceCue.index}. No output was attached.');
      }
    }
    if (!await _writeAndApply(
      result.cues,
      operationLabel: 'Translated subtitles',
      operationLanguageCode: _targetLanguage.bcpCode,
      sourceCues: selected.$1,
      reviewWarnings: result.qualityWarnings,
    )) return;
    if (!mounted) return;
    setState(() {
      _status = 'Translated ${result.cues.length} cues from '
          '${SubtitleTranslationService.languageLabel(_sourceLanguage)} to '
          '${SubtitleTranslationService.languageLabel(_targetLanguage)}. '
          'Timing and original subtitle file were preserved. ${result.backendLabel}.'
          '${_lastResultUploadedToServer ? ' Uploaded to the server library.' : ''}';
    });
    await _showApplied();
  });

  Future<SubtitleCue?> _editCueForReview(BuildContext dialogContext, SubtitleCue cue) async {
    final textController = TextEditingController(text: cue.text);
    final startController = TextEditingController(text: cue.startMs.toString());
    final endController = TextEditingController(text: cue.endMs.toString());
    SubtitleCue? edited;
    String? validationError;
    try {
      await showDialog<bool>(
        context: dialogContext,
        builder: (editorContext) => StatefulBuilder(
          builder: (context, setEditorState) => AlertDialog(
            title: const Text('Edit subtitle cue'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: textController,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Cue text',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Start (ms)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'End (ms)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 8),
                      Text(validationError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(editorContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final startMs = int.tryParse(startController.text.trim());
                  final endMs = int.tryParse(endController.text.trim());
                  final text = textController.text.trimRight();
                  if (startMs == null ||
                      endMs == null ||
                      startMs < 0 ||
                      endMs <= startMs ||
                      endMs > SubtitleRetimer.maximumTimeMs ||
                      text.trim().isEmpty ||
                      text.length > 4000) {
                    setEditorState(() {
                      validationError = 'Use non-empty text up to 4000 characters and valid millisecond times.';
                    });
                    return;
                  }
                  edited = SubtitleCue(index: cue.index, startMs: startMs, endMs: endMs, text: text);
                  Navigator.of(editorContext).pop(true);
                },
                child: const Text('Save cue'),
              ),
            ],
          ),
        ),
      );
      return edited;
    } finally {
      textController.dispose();
      startController.dispose();
      endController.dispose();
    }
  }

  void _rememberCueEdit(List<(int, SubtitleCue)> undoHistory, int index, SubtitleCue cue) {
    if (undoHistory.length == 100) undoHistory.removeAt(0);
    undoHistory.add((index, cue));
  }

  Future<void> _showFullCueEditor(
    BuildContext dialogContext,
    List<SubtitleCue> cues, {
    List<SubtitleCue>? sourceCues,
    required List<(int, SubtitleCue)> undoHistory,
    VoidCallback? onChanged,
  }) async {
    final searchController = TextEditingController();
    var query = '';
    try {
      await showDialog<void>(
        context: dialogContext,
        builder: (editorContext) => StatefulBuilder(
          builder: (context, setEditorState) {
            final normalizedQuery = query.trim().toLowerCase();
            final visibleIndexes = List<int>.generate(cues.length, (index) => index).where((index) {
              if (normalizedQuery.isEmpty) return true;
              final output = cues[index].text.toLowerCase();
              final original = sourceCues != null && index < sourceCues.length
                  ? sourceCues[index].text.toLowerCase()
                  : '';
              return output.contains(normalizedQuery) || original.contains(normalizedQuery);
            }).toList(growable: false);
            return AlertDialog(
              title: Text('Edit all ${cues.length} cues'),
              content: SizedBox(
                width: 720,
                height: (MediaQuery.sizeOf(editorContext).height - 220).clamp(280.0, 560.0).toDouble(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Review or edit any output cue. Changes stay in this result until you attach it.'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      maxLength: 128,
                      decoration: const InputDecoration(
                        labelText: 'Find in source or output cues',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: (value) => setEditorState(() => query = value),
                    ),
                    const SizedBox(height: 4),
                    Text('Showing ${visibleIndexes.length} of ${cues.length} cues.'),
                    const SizedBox(height: 6),
                    Expanded(
                      child: visibleIndexes.isEmpty
                          ? const Center(child: Text('No cues match this search.'))
                          : ListView.builder(
                              itemCount: visibleIndexes.length,
                              itemBuilder: (context, visibleIndex) {
                                final cueIndex = visibleIndexes[visibleIndex];
                                final cue = cues[cueIndex];
                                final original = sourceCues != null && cueIndex < sourceCues.length
                                    ? sourceCues[cueIndex].text
                                    : null;
                                Future<void> editCue() async {
                                  final edited = await _editCueForReview(editorContext, cue);
                                  if (edited != null && mounted) {
                                    _rememberCueEdit(undoHistory, cueIndex, cue);
                                    setEditorState(() => cues[cueIndex] = edited);
                                    onChanged?.call();
                                  }
                                }
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Cue ${cue.index} · ${_formatCueTime(cue.startMs)} – ${_formatCueTime(cue.endMs)}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (original != null) ...[
                                        Text('Original', style: Theme.of(context).textTheme.labelSmall),
                                        SelectableText(original),
                                        const SizedBox(height: 4),
                                      ],
                                      Text('Output', style: Theme.of(context).textTheme.labelSmall),
                                      SelectableText(cue.text),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Edit cue',
                                    onPressed: editCue,
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  onTap: editCue,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (undoHistory.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      final previous = undoHistory.removeLast();
                      setEditorState(() => cues[previous.$1] = previous.$2);
                      onChanged?.call();
                    },
                    icon: const Icon(Icons.undo),
                    label: Text('Undo (${undoHistory.length})'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(editorContext).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      searchController.dispose();
    }
  }

  String? _normalizedUploadLanguage(String? languageCode) {
    final code = languageCode?.trim().toLowerCase().split(RegExp(r'[-_]')).first ?? '';
    return RegExp(r'^[a-z]{2,3}$').hasMatch(code) ? code : null;
  }


  Future<void> _uploadSubtitleToServer(Uint8List bytes, String languageCode) async {
    final serverId = widget.serverId;
    final ratingKey = widget.ratingKey;
    if (serverId == null || serverId.isEmpty || ratingKey == null || ratingKey.isEmpty) {
      throw StateError('This playback item is not linked to a server library entry.');
    }
    final client = context.tryGetMediaClientForServer(ServerId(serverId));
    if (client == null) throw StateError('The media server is offline or unavailable.');
    final uploaded = await client.attachSubtitle(
      ratingKey,
      bytes: bytes,
      fileName: 'PlezyNG.$languageCode.srt',
      format: 'srt',
      language: languageCode,
      mediaIndex: widget.mediaIndex,
    );
    if (!uploaded) {
      throw UnsupportedError('The server refused this subtitle upload or does not support library attachment.');
    }
  }

  Future<bool> _writeAndApply(
    List<SubtitleCue> cues, {
    required String operationLabel,
    String? operationLanguageCode,
    List<SubtitleCue>? sourceCues,
    List<String> reviewWarnings = const [],
  }) async {
    if (cues.isEmpty || cues.length > SubtitleRetimer.maximumCueCount) {
      throw const FormatException('Subtitle result has no cues or exceeds the 50000 cue processing bound.');
    }
    if (sourceCues != null && sourceCues.length != cues.length) {
      throw StateError('Source and output cue counts do not match; no subtitle was attached.');
    }
    final reviewedCues = List<SubtitleCue>.from(cues);
    final undoHistory = <(int, SubtitleCue)>[];
    _lastResultUploadedToServer = false;
    final uploadLanguage = _normalizedUploadLanguage(operationLanguageCode);
    final canUploadToServer =
        uploadLanguage != null && widget.serverId?.isNotEmpty == true && widget.ratingKey?.isNotEmpty == true;
    final List<int> previewIndexes;
    if (cues.length <= 12) {
      previewIndexes = List<int>.generate(cues.length, (index) => index);
    } else {
      final sample = <int>{
        ...List<int>.generate(8, (index) => index),
        cues.length ~/ 2,
        ...List<int>.generate(3, (index) => cues.length - 3 + index),
      };
      previewIndexes = sample.toList()..sort();
    }
    final choice = await showDialog<_SubtitleReviewChoice>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Review $operationLabel'),
          content: SizedBox(
            width: 560,
            height: (MediaQuery.sizeOf(dialogContext).height - 220).clamp(240.0, 420.0).toDouble(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${cues.length} cues are ready. Review this sample before attaching the generated SRT.'),
                if (reviewWarnings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Glossary check found ${reviewWarnings.length} possible mismatch${reviewWarnings.length == 1 ? '' : 'es'}. Review these cues before attaching.',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        ...reviewWarnings.take(3).map(
                              (warning) => Tooltip(
                                message: warning,
                                child: Text(
                                  warning,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        if (reviewWarnings.length > 3)
                          Text(
                            'And ${reviewWarnings.length - 3} more.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => unawaited(
                    _showFullCueEditor(
                      dialogContext,
                      reviewedCues,
                      sourceCues: sourceCues,
                      undoHistory: undoHistory,
                      onChanged: () => setDialogState(() {}),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit all cues'),
                ),
                if (widget.selectedSubtitleBurnedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'The currently selected captions are burned into this video image. Attaching generated subtitles adds a separate track and cannot erase those pixels.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (canUploadToServer)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Upload + attach stores this SRT on the active library item when the server allows it.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      uploadLanguage == null
                          ? 'Server upload is unavailable because this result has no known subtitle language. You can still attach it to the current player.'
                          : 'Server upload is unavailable because this is not an active server library item. You can still attach it to the current player.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: previewIndexes.length,
                    itemBuilder: (context, index) {
                      final cueIndex = previewIndexes[index];
                      final cue = reviewedCues[cueIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatCueTime(cue.startMs)} – ${_formatCueTime(cue.endMs)}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 2),
                            if (sourceCues != null && cueIndex < sourceCues.length) ...[
                              Text('Original', style: Theme.of(context).textTheme.labelSmall),
                              SelectableText(sourceCues[cueIndex].text),
                              const SizedBox(height: 2),
                            ],
                            SelectableText(cue.text),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final edited = await _editCueForReview(dialogContext, cue);
                                  if (edited != null && mounted) {
                                    setDialogState(() {
                                      _rememberCueEdit(undoHistory, cueIndex, cue);
                                      reviewedCues[cueIndex] = edited;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit sample cue'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (undoHistory.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  final previous = undoHistory.removeLast();
                  setDialogState(() => reviewedCues[previous.$1] = previous.$2);
                },
                icon: const Icon(Icons.undo),
                label: Text('Undo (${undoHistory.length})'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_SubtitleReviewChoice.discard),
              child: const Text('Discard'),
            ),
            if (canUploadToServer)
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(_SubtitleReviewChoice.serverAndPlayer),
                child: const Text('Upload + attach'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(_SubtitleReviewChoice.player),
              child: const Text('Attach to player'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null || choice == _SubtitleReviewChoice.discard) {
      if (mounted) {
        setState(() => _status = 'Subtitle result discarded; the current track and source file are unchanged.');
      }
      return false;
    }
    final bytes = SubtitleSyncService.writeSrt(reviewedCues);
    if (choice == _SubtitleReviewChoice.serverAndPlayer) {
      final languageCode = uploadLanguage;
      if (languageCode == null) throw StateError('The result language could not be identified for server upload.');
      await _uploadSubtitleToServer(bytes, languageCode);
      _lastResultUploadedToServer = true;
    }
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, 'plezyng_subtitle_${DateTime.now().microsecondsSinceEpoch}.srt');
    try {
      await File(path).writeAsBytes(bytes, flush: true);
      await widget.player.command(['sub-add', path, 'select']);
    } catch (error) {
      if (_lastResultUploadedToServer) {
        throw StateError('Uploaded to the server library, but could not attach the local copy: $error');
      }
      rethrow;
    }
    return true;
  }

  String _formatCueTime(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = milliseconds ~/ 60000 % 60;
    final seconds = milliseconds ~/ 1000 % 60;
    final millis = milliseconds % 1000;
    String pad(int value, int width) => value.toString().padLeft(width, '0');
    return '${pad(hours, 2)}:${pad(minutes, 2)}:${pad(seconds, 2)},${pad(millis, 3)}';
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
  Map<String, TranslateLanguage> _whisperLanguagesByCode() {
    final languages = <String, TranslateLanguage>{};
    for (final language in SubtitleTranslationService.languages) {
      final code = language.bcpCode.toLowerCase().split(RegExp(r'[-_]')).first;
      if (RegExp(r'^[a-z]{2,3}$').hasMatch(code)) languages.putIfAbsent(code, () => language);
    }
    return languages;
  }

  Widget _speechLanguageSelector() {
    final supportsOverride =
        _provider == SubtitleInferenceProvider.cpu || _provider == SubtitleInferenceProvider.desktopGpu;
    final languages = _whisperLanguagesByCode();
    final selected = languages.containsKey(_speechLanguageCode) ? _speechLanguageCode : 'auto';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Speech language', border: OutlineInputBorder()),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: 'auto', child: Text('Auto-detect')),
                ...languages.entries.map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      '${SubtitleTranslationService.languageLabel(entry.value)} (${entry.key.toUpperCase()})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: _busy || !supportsOverride
                  ? null
                  : (value) {
                      final code = value ?? 'auto';
                      setState(() => _speechLanguageCode = code);
                      unawaited(_saveSpeechLanguageForProfile(code));
                    },
            ),
          ),
        ),
        if (!supportsOverride)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'The selected accelerator uses an English-only model. Choose Whisper CPU or desktop GPU to override language.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

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
            'WAV transcription and audio sync use a 16-bit PCM WAV from the same title and audio track; subtitle sync can also use an already synchronized same-language reference. Android ExoPlayer supports an opt-in local CPU caption tap for watched VOD sections. MPV fallback and other players do not expose decoded audio.',
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
                           _speechLanguageCode = 'auto';
                           unawaited(_saveSpeechLanguageForProfile('auto'));
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
          _speechLanguageSelector(),
          const SizedBox(height: 10),
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
          FocusableListTile(
            leading: const AppIcon(Symbols.closed_caption_rounded),
            title: const Text('Sync to another subtitle'),
            subtitle: const Text('Use a same-language SRT, VTT, ASS, or SSA subtitle as the timing reference'),
            onTap: _busy ? null : () => unawaited(_synchronizeToReference(repairCuts: false)),
          ),
          FocusableListTile(
            leading: const AppIcon(Symbols.content_cut_rounded),
            title: const Text('Repair cuts using another subtitle'),
            subtitle: const Text('Apply piecewise offsets where dialogue anchors show a timing discontinuity'),
            onTap: _busy ? null : () => unawaited(_synchronizeToReference(repairCuts: true)),
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
                  onChanged: (value) => _changeTranslationLanguage(source: true, value: value),
                ),
                const SizedBox(width: 8),
                _languageSelector(
                  label: 'Target',
                  value: _targetLanguage,
                  onChanged: (value) => _changeTranslationLanguage(source: false, value: value),
                ),
              ],
            ),
            if (widget.seriesKey?.isNotEmpty == true)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use a series-specific glossary'),
                subtitle: const Text('Starts with the profile glossary; saved edits apply only to this series.'),
                value: _useSeriesGlossary,
                onChanged: _busy
                    ? null
                    : (value) {
                        _glossaryDrafts[_currentGlossaryDraftKey()] = _glossaryController.text;
                        setState(() => _useSeriesGlossary = value);
                        unawaited(_loadGlossaryForCurrentPair());
                      },
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
                helperText: widget.seriesKey == null ? 'Protects up to 200 whole terms. Saved for this profile and language pair.' : 'Protects up to 200 terms. Choose profile or series scope above.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _glossaryDrafts[_currentGlossaryDraftKey()] = value,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy ? null : () => unawaited(_run(_saveGlossary)),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save glossary'),
              ),
            ),
            const SizedBox(height: 8),
            if (SubtitleTranslationService.mobilePlatformSupported) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow language-model downloads over mobile data'),
                value: _allowMobileData,
                onChanged: _busy ? null : (value) => setState(() => _allowMobileData = value),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => unawaited(_prepareTranslationModels()),
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('Prepare offline language models'),
                ),
              ),
            ],
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
