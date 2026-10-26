import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/subtitles/subtitle_search_result.dart';
import '../../services/open_subtitles_client.dart';

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
  static const _languages = <String, String>{
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
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
      final code = Localizations.localeOf(context).languageCode;
      if (_languages.containsKey(code)) _language = code;
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
        _error = 'Subtitle search failed. Check the API key, connection, and service access.';
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
          _error = 'Could not download or apply this subtitle. Check your connection and try another result.';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('Search OpenSubtitles', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 4),
              const Text(
                'Search uses the title and available IMDb/TMDB IDs. The video file stays on its source. Check language, forced or hearing-impaired flags, and rating before choosing.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Movie or show',
                        hintText: 'Enter a title to refine results',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Search',
                    onPressed: _searching ? null : _search,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(labelText: 'Subtitle language', border: OutlineInputBorder()),
                items: [
                  for (final item in _languages.entries)
                    DropdownMenuItem(value: item.key, child: Text(item.value)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _language = value);
                  unawaited(_search());
                },
              ),
              if (_searching)
                const Semantics(
                  label: 'Searching OpenSubtitles',
                  liveRegion: true,
                  child: LinearProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _hasSearched && _results.isEmpty && !_searching && _error == null
                    ? const Semantics(
                        liveRegion: true,
                        child: Center(child: Text('No matching subtitles found. Try a different title or language.')),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          final title = result.displayTitle?.trim().isNotEmpty == true
                              ? result.displayTitle!.trim()
                              : result.title ?? 'Subtitle';
                          final tags = <String>[
                            if (result.language?.isNotEmpty == true) result.language!,
                            if (result.codec?.isNotEmpty == true) result.codec!.toUpperCase(),
                            if (result.hearingImpaired) 'Hearing impaired',
                            if (result.forced) 'Forced',
                            if (result.score != null) 'Rating ${result.score!.toStringAsFixed(1)}',
                          ];
                          final active = _downloading == result.key;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: tags.isEmpty ? null : Text(tags.join(' · ')),
                            trailing: active
                                ? Semantics(
                                    label: 'Downloading subtitle: $title',
                                    liveRegion: true,
                                    child: const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, semanticLabel: 'Download subtitle'),
                            onTap: _downloading == null ? () => _download(result) : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
