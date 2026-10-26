import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_text_field.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../models/subtitles/subtitle_search_result.dart';
import '../../services/open_subtitles_client.dart';
import '../../utils/language_codes.dart';
import 'source_widgets.dart';

class StandaloneSubtitleSearchSheet extends StatefulWidget {
  const StandaloneSubtitleSearchSheet({
    super.key,
    required this.client,
    required this.title,
    this.imdbId,
    this.tmdbId,
    this.year,
    required this.onApply,
  });

  final OpenSubtitlesClient client;
  final String title;
  final String? imdbId;
  final String? tmdbId;
  final int? year;
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
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
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

  Future<void> _download(SubtitleSearchResult result) async {
    if (_downloading != null) return;
    setState(() {
      _downloading = result.key;
      _error = null;
    });
    try {
      final file = await widget.client.download(result);
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: t.common.search,
                      onPressed: _searching ? null : _search,
                      icon: const AppIcon(Symbols.search_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t.sourceSetup.subtitleLanguage, border: OutlineInputBorder()),
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
                  Semantics(label: t.sourceSetup.subtitleSearching, liveRegion: true, child: LinearProgressIndicator()),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SourceErrorMessage(message: _error!),
                  ),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) => _hasSearched && _results.isEmpty && !_searching && _error == null
                      ? Semantics(liveRegion: true, child: Center(child: Text(t.sourceSetup.subtitleNoMatches)))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            final title = result.displayTitle?.trim().isNotEmpty == true
                                ? result.displayTitle!.trim()
                                : result.title ?? t.sourceSetup.subtitle;
                            final tags = <String>[
                              if (result.language?.isNotEmpty == true) LanguageCodes.getDisplayName(result.language!),
                              if (result.codec?.isNotEmpty == true) result.codec!.toUpperCase(),
                              if (result.hearingImpaired) t.fileInfo.flagHearingImpaired,
                              if (result.forced) t.fileInfo.flagForced,
                              if (result.score != null)
                                t.sourceSetup.subtitleRating(rating: formatDecimal(result.score!, maximumDecimals: 1)),
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
                                  : AppIcon(
                                      Symbols.download_rounded,
                                      semanticLabel: t.sourceSetup.downloadSubtitle,
                                    ),
                              onTap: _downloading == null ? () => _download(result) : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
