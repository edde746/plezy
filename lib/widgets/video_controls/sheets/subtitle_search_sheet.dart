import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/plex_subtitle_search_result.dart';
import '../../../utils/language_codes.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';

class SubtitleSearchSheet extends StatefulWidget {
  final String ratingKey;
  final String serverId;
  final String? mediaTitle;
  final Future<void> Function()? onSubtitleDownloaded;

  const SubtitleSearchSheet({
    super.key,
    required this.ratingKey,
    required this.serverId,
    this.mediaTitle,
    this.onSubtitleDownloaded,
  });

  @override
  State<SubtitleSearchSheet> createState() => _SubtitleSearchSheetState();
}

class _SubtitleSearchSheetState extends State<SubtitleSearchSheet> {
  String _languageCode = 'en';
  String _languageName = 'English';
  final _titleController = TextEditingController();
  Timer? _debounceTimer;

  List<PlexSubtitleSearchResult>? _results;
  bool _isSearching = false;
  String? _error;
  String? _downloadingKey;

  // Internal view switching instead of push/pop
  bool _showLanguagePicker = false;

  @override
  void initState() {
    super.initState();
    _initDefaultLanguage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  void _initDefaultLanguage() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final code = locale.languageCode;
    final name = LanguageCodes.getLanguageName(code);
    if (name != null) {
      _languageCode = code;
      _languageName = name;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final client = context.getClientForServer(widget.serverId);
      final title = _titleController.text.trim();
      final results = await client.searchSubtitles(
        widget.ratingKey,
        language: _languageCode,
        title: title.isEmpty ? null : title,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  void _onTitleChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _search);
  }

  void _onLanguageSelected(String code, String name) {
    setState(() {
      _languageCode = code;
      _languageName = name;
      _showLanguagePicker = false;
    });
    _search();
  }

  Future<void> _downloadSubtitle(PlexSubtitleSearchResult result) async {
    if (_downloadingKey != null) return;
    setState(() => _downloadingKey = result.key);

    try {
      final client = context.getClientForServer(widget.serverId);
      final success = await client.downloadSubtitle(
        widget.ratingKey,
        key: result.key,
        codec: result.codec ?? 'srt',
        language: result.languageCode ?? _languageCode,
        hearingImpaired: result.hearingImpaired,
        forced: result.forced,
        providerTitle: result.providerTitle ?? '',
      );

      if (!mounted) return;

      if (success) {
        await widget.onSubtitleDownloaded?.call();
        if (!mounted) return;
        showSuccessSnackBar(context, t.videoControls.subtitleDownloaded);
        OverlaySheetController.of(context).close();
      } else {
        showErrorSnackBar(context, t.videoControls.subtitleDownloadFailed);
        setState(() => _downloadingKey = null);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, t.videoControls.subtitleDownloadFailed);
      setState(() => _downloadingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showLanguagePicker) {
      return _LanguagePickerView(
        currentCode: _languageCode,
        onSelected: _onLanguageSelected,
        onBack: () => setState(() => _showLanguagePicker = false),
      );
    }

    return BaseVideoControlSheet(
      title: t.videoControls.searchSubtitles,
      icon: Symbols.search_rounded,
      onBack: () => OverlaySheetController.of(context).pop(),
      child: Column(
        children: [
          FocusableListTile(
            leading: const AppIcon(Symbols.language_rounded),
            title: Text(t.videoControls.language),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _languageName,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                const AppIcon(Symbols.arrow_drop_down_rounded),
              ],
            ),
            onTap: () => setState(() => _showLanguagePicker = true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: widget.mediaTitle ?? 'Title',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: _onTitleChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }

    if (_results == null) {
      return const SizedBox.shrink();
    }

    if (_results!.isEmpty) {
      return Center(
        child: Text(
          t.videoControls.noSubtitlesFound,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        final isDownloading = _downloadingKey == result.key;
        final colorScheme = Theme.of(context).colorScheme;

        Widget? trailing;
        if (isDownloading) {
          trailing = const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else {
          final trailingChildren = <Widget>[];
          if (result.perfectMatch) {
            trailingChildren.add(
              const AppIcon(Symbols.star_rounded, fill: 1, color: Color(0xFFCC7B19), size: 16),
            );
          }
          if (result.score != null) {
            trailingChildren.add(Text(
              result.score!.toInt().toString(),
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ));
          }
          if (trailingChildren.isNotEmpty) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: trailingChildren,
            );
          }
        }

        return FocusableListTile(
          title: Text(
            result.title ?? result.displayTitle ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            result.displayTitle ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          trailing: trailing,
          onTap: isDownloading ? null : () => _downloadSubtitle(result),
        );
      },
    );
  }
}

/// Language picker rendered as an internal view, not a pushed page.
class _LanguagePickerView extends StatefulWidget {
  final String currentCode;
  final void Function(String code, String name) onSelected;
  final VoidCallback onBack;

  const _LanguagePickerView({
    required this.currentCode,
    required this.onSelected,
    required this.onBack,
  });

  @override
  State<_LanguagePickerView> createState() => _LanguagePickerViewState();
}

class _LanguagePickerViewState extends State<_LanguagePickerView> {
  final _filterController = TextEditingController();
  late List<({String code, String name})> _allLanguages;
  List<({String code, String name})> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _allLanguages = LanguageCodes.getAllLanguages();
    _filteredLanguages = _allLanguages;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String query) {
    final lower = query.toLowerCase();
    setState(() {
      if (lower.isEmpty) {
        _filteredLanguages = _allLanguages;
      } else {
        _filteredLanguages = _allLanguages.where((l) {
          return l.name.toLowerCase().contains(lower) || l.code.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseVideoControlSheet(
      title: t.videoControls.language,
      icon: Symbols.language_rounded,
      onBack: widget.onBack,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _filterController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: t.videoControls.searchLanguages,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Symbols.search_rounded, size: 20),
              ),
              onChanged: _onFilterChanged,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLanguages.length,
              itemBuilder: (context, index) {
                final lang = _filteredLanguages[index];
                final isSelected = lang.code == widget.currentCode;
                return FocusableListTile(
                  title: Text(
                    lang.name,
                    style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : null),
                  ),
                  trailing: isSelected
                      ? AppIcon(Symbols.check_rounded, fill: 1, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => widget.onSelected(lang.code, lang.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
