import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../models/subtitles/subtitle_search_result.dart';
import '../../services/open_subtitles_client.dart';
import '../../services/settings_service.dart';
import '../../services/subtitle_rejection_service.dart';
import '../../services/subtitle_retimer.dart';
import '../../utils/formatters.dart';
import '../../utils/track_label_builder.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import 'source_widgets.dart';

class StandaloneSubtitleSearchSheet extends StatefulWidget {
  const StandaloneSubtitleSearchSheet({
    super.key,
    required this.client,
    required this.title,
    this.imdbId,
    this.tmdbId,
    this.year,
    this.movieHash,
    required this.onApply,
  });

  final OpenSubtitlesClient client;
  final String title;
  final String? imdbId;
  final String? tmdbId;
  final int? year;
  final String? movieHash;
  final Future<void> Function(OpenSubtitleDownload download) onApply;

  @override
  State<StandaloneSubtitleSearchSheet> createState() => _StandaloneSubtitleSearchSheetState();
}

class _StandaloneSubtitleSearchSheetState extends State<StandaloneSubtitleSearchSheet> {
  // Service codes from OpenSubtitles' published language list. Regional
  // Chinese and Portuguese choices must remain distinct on the wire.
  static const _languageCodes = <String>{
    'ar',
    'az',
    'bg',
    'bn',
    'cs',
    'da',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'he',
    'hi',
    'hu',
    'id',
    'it',
    'ja',
    'kk',
    'ko',
    'ms',
    'no',
    'nl',
    'pl',
    'pt-br',
    'pt-pt',
    'ru',
    'sv',
    'th',
    'tr',
    'uk',
    'uz',
    'vi',
    'zh-cn',
    'zh-tw',
  };

  late final TextEditingController _query = TextEditingController(text: widget.title);
  String _language = 'en';
  bool _languageInitialized = false;
  List<SubtitleSearchResult> _results = const [];
  List<SubtitleSearchResult> _allResults = const [];
  final Set<String> _sessionRejectedRevisions = <String>{};
  int _hiddenRejectedRevisionCount = 0;
  bool _showRejectedRevisions = false;
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;
  String? _downloading;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_languageInitialized) {
      _languageInitialized = true;
      final code = OpenSubtitlesClient.languageCodeFor(Localizations.localeOf(context).toLanguageTag());
      if (_languageCodes.contains(code)) _language = code;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _generation++;
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (!mounted || query.isEmpty) return;
    final generation = ++_generation;
    setState(() {
      _searching = true;
      _hasSearched = true;
      _results = const [];
      _error = null;
    });
    try {
      final results = await widget.client.search(
        query: query,
        languageCode: _language,
        imdbId: widget.imdbId,
        tmdbId: widget.tmdbId,
        year: widget.year,
        movieHash: widget.movieHash,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _allResults = results;
        final filtered = _filterRejectedResults(results);
        _results = _showRejectedRevisions ? results : filtered.visible;
        _hiddenRejectedRevisionCount = filtered.hidden;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = t.sourceSetup.subtitleSearchFailed;
        _searching = false;
        _hasSearched = true;
      });
    }
  }


  String get _rejectionItemId => [
    widget.movieHash?.trim() ?? '',
    widget.imdbId?.trim() ?? '',
    widget.tmdbId?.trim() ?? '',
    widget.year?.toString() ?? '',
    widget.title.trim().toLowerCase(),
  ].join('|');

  String _revisionKey(SubtitleSearchResult result) => SubtitleRejectionService.revisionKey(
    serverId: 'standalone-opensubtitles',
    itemId: _rejectionItemId,
    mediaIndex: 0,
    result: result,
  );

  bool _isRejected(SubtitleSearchResult result) {
    if (_sessionRejectedRevisions.contains(_revisionKey(result))) return true;
    final settings = SettingsService.instanceOrNull;
    return settings != null &&
        SubtitleRejectionService.isRejected(
          settings,
          serverId: 'standalone-opensubtitles',
          itemId: _rejectionItemId,
          mediaIndex: 0,
          result: result,
        );
  }

  ({List<SubtitleSearchResult> visible, int hidden}) _filterRejectedResults(
    List<SubtitleSearchResult> results,
  ) {
    final visible = <SubtitleSearchResult>[];
    var hidden = 0;
    for (final result in results) {
      if (_isRejected(result)) {
        hidden++;
      } else {
        visible.add(result);
      }
    }
    return (visible: visible, hidden: hidden);
  }

  void _toggleRejectedRevisionVisibility() {
    final nextShowRejected = !_showRejectedRevisions;
    final filtered = _filterRejectedResults(_allResults);
    setState(() {
      _showRejectedRevisions = nextShowRejected;
      _results = nextShowRejected ? _allResults : filtered.visible;
      _hiddenRejectedRevisionCount = filtered.hidden;
    });
  }

  Future<void> _setRevisionRejected(SubtitleSearchResult result, {required bool rejected}) async {
    if (result.key.trim().isEmpty) return;
    final settings = SettingsService.instanceOrNull;
    try {
      if (settings != null) {
        if (rejected) {
          await SubtitleRejectionService.reject(
            settings,
            serverId: 'standalone-opensubtitles',
            itemId: _rejectionItemId,
            mediaIndex: 0,
            result: result,
          );
        } else {
          await SubtitleRejectionService.restore(
            settings,
            serverId: 'standalone-opensubtitles',
            itemId: _rejectionItemId,
            mediaIndex: 0,
            result: result,
          );
        }
      }
      if (!mounted) return;
      if (rejected) {
        _sessionRejectedRevisions.add(_revisionKey(result));
      } else {
        _sessionRejectedRevisions.remove(_revisionKey(result));
      }
      final filtered = _filterRejectedResults(_allResults);
      setState(() {
        _results = _showRejectedRevisions ? _allResults : filtered.visible;
        _hiddenRejectedRevisionCount = filtered.hidden;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the subtitle revision choice.');
    }
  }

  Future<void> _download(SubtitleSearchResult result) async {
    if (_downloading != null) return;
    setState(() {
      _downloading = result.key;
      _error = null;
    });
    try {
      final file = await widget.client.download(result);
      if (!mounted) return;
      final shouldApply = await _previewSubtitle(result, file);
      if (!mounted) return;
      if (!shouldApply) {
        setState(() => _downloading = null);
        return;
      }
      await widget.onApply(file);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = null;
          _error = t.sourceSetup.subtitleApplyFailed;
        });
      }
    }
  }

  Future<bool> _previewSubtitle(SubtitleSearchResult result, OpenSubtitleDownload file) async {
    final extension = p.extension(file.fileName).toLowerCase();
    if (!const {'.srt', '.vtt', '.ass', '.ssa'}.contains(extension)) {
      // Bitmap subtitles have no text lines to show in a preview.
      return true;
    }
    final cues = SubtitleRetimer.parseCues(sourceBytes: file.bytes, extension: extension);
    if (!mounted) return false;
    final previewCues = cues.take(12).toList(growable: false);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(result.displayTitle ?? result.title ?? t.common.unknown),
        content: SizedBox(
          width: 560,
          height: 420,
          child: ListView.builder(
            itemCount: previewCues.length,
            itemBuilder: (context, index) {
              final cue = previewCues[index];
              final previewText = cue.text
                  .replaceAll(RegExp(r'\{[^}]*\}'), '')
                  .replaceAll(RegExp(r'\\[Nnh]', caseSensitive: false), ' ')
                  .replaceAll(RegExp(r'<[^>]*>'), '')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
              return ListTile(
                dense: true,
                leading: Text(sourceTime(cue.startMs)),
                title: Text(previewText, maxLines: 2, overflow: TextOverflow.ellipsis),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.common.confirm),
          ),
        ],
      ),
    );
    return accepted == true;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom;
    final safeTop = math.max(media.padding.top, media.viewPadding.top);
    final availableHeight = (media.size.height - safeTop - media.padding.bottom - bottom - 32)
        .clamp(0.0, media.size.height)
        .toDouble();
    final sheetHeight = math.min(media.size.height * .78, availableHeight).toDouble();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(t.sourceSetup.subtitleSearch, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const SizedBox(height: 4),
                      Text(t.sourceSetup.subtitleSearchPrivacy),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FocusableTextField(
                              controller: _query,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _search(),
                              decoration: InputDecoration(
                                labelText: t.sourceSetup.movieOrShow,
                                hintText: t.sourceSetup.subtitleTitleHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FocusableButton(
                            onPressed: _searching ? null : _search,
                            child: IconButton.filled(
                              tooltip: t.common.search,
                              onPressed: _searching ? null : _search,
                              icon: const AppIcon(Symbols.search_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _language,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t.sourceSetup.subtitleLanguage),
                        items: [
                          for (final code in _languageCodes)
                            DropdownMenuItem(
                              value: code,
                              child: Text(LanguageCodes.getDisplayName(code), overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _language = value);
                          unawaited(_search());
                        },
                      ),
                      if (_searching)
                        Semantics(
                          label: t.sourceSetup.subtitleSearching,
                          liveRegion: true,
                          child: LinearProgressIndicator(),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SourceErrorMessage(message: _error!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    if (_hiddenRejectedRevisionCount > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _toggleRejectedRevisionVisibility,
                          child: Text(
                            _showRejectedRevisions
                                ? 'Hide $_hiddenRejectedRevisionCount ignored revision(s)'
                                : 'Show $_hiddenRejectedRevisionCount ignored revision(s)',
                          ),
                        ),
                      ),
                    Expanded(
                      child: _hasSearched && _results.isEmpty && !_searching && _error == null
                          ? Semantics(
                              liveRegion: true,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _hiddenRejectedRevisionCount > 0
                                          ? 'All matching subtitle revisions are hidden.'
                                          : t.sourceSetup.subtitleNoMatches,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_hiddenRejectedRevisionCount > 0)
                                      TextButton(
                                        onPressed: _toggleRejectedRevisionVisibility,
                                        child: Text('Show $_hiddenRejectedRevisionCount hidden revision(s)'),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                final title = result.displayTitle?.trim().isNotEmpty == true
                                    ? result.displayTitle!.trim()
                                    : result.title ?? t.sourceSetup.subtitle;
                                final ignored = _isRejected(result);
                                final languageDisplay = resolveTrackLanguageDisplay(
                                  language: result.language,
                                  languageCode: result.languageCode,
                                );
                                final tags = <String>[
                                  if (languageDisplay != null) languageDisplay,
                                  if (result.codec?.isNotEmpty == true) 'Format ${result.codec!.toUpperCase()}',
                                  if (result.providerTitle?.trim().isNotEmpty == true)
                                    'Provider ${result.providerTitle!.trim()}',
                                  if (result.hearingImpaired) t.fileInfo.flagHearingImpaired,
                                  if (result.forced) t.fileInfo.flagForced,
                                  if (result.score != null)
                                    t.sourceSetup.subtitleRating(rating: formatDecimal(result.score!, maximumDecimals: 1)),
                                  if (ignored) 'Ignored revision',
                                ];
                                final active = _downloading == result.key;
                                return FocusableListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  title: Text(isolateDisplayText(title), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: tags.isEmpty ? null : Text(tags.join(' · ')),
                                  trailing: active
                                      ? Semantics(
                                          label: t.sourceSetup.subtitleDownloading(title: isolateDisplayText(title)),
                                          liveRegion: true,
                                          child: const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (result.key.trim().isNotEmpty)
                                              IconButton(
                                                tooltip: ignored
                                                    ? 'Show this subtitle revision again'
                                                    : 'Hide this subtitle revision',
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                onPressed: () => unawaited(
                                                  _setRevisionRejected(result, rejected: !ignored),
                                                ),
                                                icon: Icon(
                                                  ignored ? Icons.undo_rounded : Icons.visibility_off_outlined,
                                                  size: 18,
                                                ),
                                              ),
                                            AppIcon(Symbols.download_rounded, semanticLabel: t.sourceSetup.downloadSubtitle),
                                          ],
                                        ),
                                  onTap: _downloading == null ? () => _download(result) : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
