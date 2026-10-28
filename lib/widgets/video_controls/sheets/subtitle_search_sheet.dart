import 'dart:async';
import '../../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_button.dart';
import '../../../focus/focusable_text_field.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../i18n/strings.g.dart';
import '../../../mixins/controller_disposer_mixin.dart';
import '../../../models/subtitles/subtitle_search_result.dart';
import '../../../services/settings_service.dart';
import '../../../services/subtitle_rejection_service.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/language_codes.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../widgets/pill_input_decoration.dart';
import 'base_video_control_sheet.dart';
import '../../loading_indicator_box.dart';
import '../models/track_controls_state.dart';

@visibleForTesting
String resolveSubtitleSearchLanguageCode({String? savedLanguageCode, required Locale systemLocale}) {
  return LanguageCodes.getIso6391Code(savedLanguageCode ?? '') ??
      LanguageCodes.getIso6391Code(systemLocale.languageCode) ??
      'en';
}

class SubtitleSearchSheet extends StatefulWidget {
  final String ratingKey;
  final String serverId;
  final int mediaIndex;
  final String? mediaTitle;
  final Future<SubtitleDownloadApplyOutcome> Function({
    required String serverId,
    required String ratingKey,
    String? preferredLanguageCode,
  })?
  onSubtitleDownloaded;

  const SubtitleSearchSheet({
    super.key,
    required this.ratingKey,
    required this.serverId,
    this.mediaIndex = 0,
    this.mediaTitle,
    this.onSubtitleDownloaded,
  });

  @override
  State<SubtitleSearchSheet> createState() => _SubtitleSearchSheetState();
}

class _SubtitleSearchSheetState extends State<SubtitleSearchSheet> with ControllerDisposerMixin {
  String _languageCode = 'en';
  String _languageName = 'English';
  late final _titleController = createTextEditingController();
  final _languageFocusNode = FocusNode(debugLabel: 'SubtitleSearch_language');
  final _titleFocusNode = FocusNode(debugLabel: 'SubtitleSearch_title');
  final _firstResultFocusNode = FocusNode(debugLabel: 'SubtitleSearch_firstResult');
  Timer? _debounceTimer;

  List<SubtitleSearchResult>? _results;
  List<SubtitleSearchResult>? _allResults;
  final Set<String> _sessionRejectedRevisions = <String>{};
  int _hiddenRejectedRevisionCount = 0;
  bool _showRejectedRevisions = false;
  bool _isSearching = false;
  String? _error;
  String? _downloadingKey;
  int _searchGeneration = 0;

  bool _showLanguagePicker = false;

  @override
  void initState() {
    super.initState();
    _initDefaultLanguage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  void _initDefaultLanguage() {
    final code = resolveSubtitleSearchLanguageCode(
      savedLanguageCode: SettingsService.instanceOrNull?.read(SettingsService.subtitleSearchLanguage),
      systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
    );
    final name = LanguageCodes.getLanguageName(code);
    if (name == null) return;
    _languageCode = code;
    _languageName = name;
  }

  @override
  void dispose() {
    ++_searchGeneration;
    _debounceTimer?.cancel();
    _languageFocusNode.dispose();
    _titleFocusNode.dispose();
    _firstResultFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!mounted) return;
    final generation = ++_searchGeneration;
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final client = context.tryGetMediaClientForServer(ServerId(widget.serverId));
      if (client == null) {
        if (!mounted || generation != _searchGeneration) return;
        setState(() => _isSearching = false);
        return;
      }
      final title = _titleController.text.trim();
      final language = _languageCode;
      final results = await client.searchSubtitles(
        widget.ratingKey,
        language: language,
        title: title.isEmpty ? null : title,
        mediaIndex: widget.mediaIndex,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _allResults = results;
        final filtered = _filterRejectedResults(results);
        _results = _showRejectedRevisions ? results : filtered.visible;
        _hiddenRejectedRevisionCount = filtered.hidden;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _error = t.errors.searchFailed(error: localizedErrorReason(e));
        _isSearching = false;
      });
    }
  }


  ({List<SubtitleSearchResult> visible, int hidden}) _filterRejectedResults(
    List<SubtitleSearchResult> results,
  ) {
    final settings = SettingsService.instanceOrNull;
    final visible = <SubtitleSearchResult>[];
    var hidden = 0;
    for (final result in results) {
      final key = SubtitleRejectionService.revisionKey(
        serverId: widget.serverId,
        itemId: widget.ratingKey,
        mediaIndex: widget.mediaIndex,
        result: result,
      );
      final rejected = _sessionRejectedRevisions.contains(key) ||
          (settings != null &&
              SubtitleRejectionService.isRejected(
                settings,
                serverId: widget.serverId,
                itemId: widget.ratingKey,
                mediaIndex: widget.mediaIndex,
                result: result,
              ));
      if (rejected) {
        hidden++;
      } else {
        visible.add(result);
      }
    }
    return (visible: visible, hidden: hidden);
  }

  void _toggleRejectedRevisionVisibility() {
    final allResults = _allResults;
    if (allResults == null) return;
    final nextShowRejected = !_showRejectedRevisions;
    final filtered = _filterRejectedResults(allResults);
    setState(() {
      _showRejectedRevisions = nextShowRejected;
      _results = nextShowRejected ? allResults : filtered.visible;
      _hiddenRejectedRevisionCount = filtered.hidden;
    });
  }

  Future<void> _setRevisionRejected(SubtitleSearchResult result, {required bool rejected}) async {
    if (result.key.trim().isEmpty) return;
    final settings = SettingsService.instanceOrNull;
    final key = SubtitleRejectionService.revisionKey(
      serverId: widget.serverId,
      itemId: widget.ratingKey,
      mediaIndex: widget.mediaIndex,
      result: result,
    );
    try {
      if (settings != null) {
        if (rejected) {
          await SubtitleRejectionService.reject(
            settings,
            serverId: widget.serverId,
            itemId: widget.ratingKey,
            mediaIndex: widget.mediaIndex,
            result: result,
          );
        } else {
          await SubtitleRejectionService.restore(
            settings,
            serverId: widget.serverId,
            itemId: widget.ratingKey,
            mediaIndex: widget.mediaIndex,
            result: result,
          );
        }
      }
      if (!mounted) return;
      if (rejected) {
        _sessionRejectedRevisions.add(key);
      } else {
        _sessionRejectedRevisions.remove(key);
      }
      final allResults = _allResults ?? const <SubtitleSearchResult>[];
      final filtered = _filterRejectedResults(allResults);
      setState(() {
        _results = _showRejectedRevisions ? allResults : filtered.visible;
        _hiddenRejectedRevisionCount = filtered.hidden;
      });
      showSnackBar(
        context,
        rejected
            ? 'Subtitle revision hidden from future suggestions.'
            : 'Subtitle revision restored to search results.',
      );
    } catch (error, stackTrace) {
      appLogger.w('Could not update rejected subtitle revisions', error: error, stackTrace: stackTrace);
      if (mounted) showSnackBar(context, 'Could not save the subtitle revision choice.');
    }
  }

  void _onTitleChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _search);
  }

  void _showLanguagePickerView() {
    setState(() => _showLanguagePicker = true);
    OverlaySheetController.of(context).refocus();
  }

  void _hideLanguagePickerView() {
    setState(() => _showLanguagePicker = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _languageFocusNode.requestFocus();
    });
  }

  void _focusFirstResult() {
    if (_results != null && _results!.isNotEmpty && !_isSearching && _error == null) {
      _firstResultFocusNode.requestFocus();
    }
  }

  Future<void> _submitSearchAndFocusFirstResult() async {
    _debounceTimer?.cancel();
    await _search();
    if (!mounted || !InputModeTracker.isKeyboardMode(context, listen: false)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusFirstResult();
    });
  }

  void _onLanguageSelected(String code, String name) {
    _debounceTimer?.cancel();
    setState(() {
      _languageCode = code;
      _languageName = name;
      _showLanguagePicker = false;
    });
    final settings = SettingsService.instanceOrNull;
    if (settings != null) {
      unawaited(settings.write(SettingsService.subtitleSearchLanguage, code));
    }
    OverlaySheetController.of(context).refocus();
    _search();
  }

  Future<void> _downloadSubtitle(SubtitleSearchResult result) async {
    if (_downloadingKey != null) return;
    setState(() => _downloadingKey = result.key);

    try {
      final client = context.tryGetMediaClientForServer(ServerId(widget.serverId));
      if (client == null) {
        if (!mounted) return;
        setState(() => _downloadingKey = null);
        return;
      }
      final success = await client.downloadSubtitle(
        widget.ratingKey,
        key: result.key,
        codec: result.codec ?? 'srt',
        language: result.languageCode ?? _languageCode,
        hearingImpaired: result.hearingImpaired,
        forced: result.forced,
        providerTitle: result.providerTitle ?? '',
        mediaIndex: widget.mediaIndex,
      );

      if (!mounted) return;

      if (success) {
        final outcome =
            await widget.onSubtitleDownloaded?.call(
              serverId: widget.serverId,
              ratingKey: widget.ratingKey,
              preferredLanguageCode: result.languageCode ?? _languageCode,
            ) ??
            SubtitleDownloadApplyOutcome.unavailable;
        if (!mounted) return;
        if (outcome == SubtitleDownloadApplyOutcome.applied) {
          showSuccessSnackBar(context, t.videoControls.subtitleDownloaded);
          OverlaySheetController.of(context).close();
        } else {
          showErrorSnackBar(context, t.videoControls.subtitleDownloadedNotApplied);
          setState(() => _downloadingKey = null);
        }
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
        onBack: _hideLanguagePickerView,
      );
    }

    final fillColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final hasResults = _results != null && _results!.isNotEmpty && !_isSearching && _error == null;

    return BaseVideoControlSheet(
      title: t.videoControls.searchSubtitles,
      icon: Symbols.search_rounded,
      onBack: () => OverlaySheetController.of(context).pop(),
      // Deliberately fills the sheet's height cap instead of hugging content.
      // Overlay sheets are bottom-anchored, so a content-driven height would
      // move the search field on every state transition — spinner, results,
      // error, empty — while the user is still typing in it. A search surface
      // needs a stable frame; the results list normally fills it anyway.
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FocusableButton(
                  focusNode: _languageFocusNode,
                  onPressed: _showLanguagePickerView,
                  onNavigateRight: _titleFocusNode.requestFocus,
                  onNavigateDown: hasResults ? _focusFirstResult : null,
                  autoScroll: false,
                  child: Material(
                    color: fillColor,
                    borderRadius: pillInputRadius,
                    child: InkWell(
                      borderRadius: pillInputRadius,
                      canRequestFocus: false,
                      onTap: _showLanguagePickerView,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisSize: .min,
                          children: [
                            Text(_languageName),
                            const SizedBox(width: 2),
                            const AppIcon(Symbols.arrow_drop_down_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FocusableTextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
                    decoration: pillInputDecoration(
                      context,
                      hintText: widget.mediaTitle ?? t.metadataEdit.title,
                      prefixIcon: const AppIcon(Symbols.search_rounded, size: 20),
                    ),
                    onChanged: _onTitleChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => unawaited(_submitSearchAndFocusFirstResult()),
                    onSelect: () => unawaited(_submitSearchAndFocusFirstResult()),
                    onNavigateLeft: _languageFocusNode.requestFocus,
                    onNavigateDown: hasResults ? _focusFirstResult : null,
                  ),
                ),
              ],
            ),
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _hiddenRejectedRevisionCount > 0
                    ? 'All matching subtitle revisions are hidden.'
                    : t.videoControls.noSubtitlesFound,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (_hiddenRejectedRevisionCount > 0)
                TextButton(
                  onPressed: _toggleRejectedRevisionVisibility,
                  child: Text('Show $_hiddenRejectedRevisionCount hidden revision(s)'),
                ),
            ],
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (_hiddenRejectedRevisionCount > 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _toggleRejectedRevisionVisibility,
              child: Text(
                _showRejectedRevisions
                    ? 'Hide $_hiddenRejectedRevisionCount rejected revision(s)'
                    : 'Show $_hiddenRejectedRevisionCount rejected revision(s)',
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _results!.length,
            itemBuilder: (context, index) {
              final result = _results![index];
              final isDownloading = _downloadingKey == result.key;
              final rejectionSettings = SettingsService.instanceOrNull;
              final revisionKey = SubtitleRejectionService.revisionKey(
                serverId: widget.serverId,
                itemId: widget.ratingKey,
                mediaIndex: widget.mediaIndex,
                result: result,
              );
              final isRejected = _sessionRejectedRevisions.contains(revisionKey) ||
                  (rejectionSettings != null &&
                      SubtitleRejectionService.isRejected(
                        rejectionSettings,
                        serverId: widget.serverId,
                        itemId: widget.ratingKey,
                        mediaIndex: widget.mediaIndex,
                        result: result,
                      ));

              final trailingChildren = <Widget>[];
              if (isDownloading) {
                trailingChildren.add(const LoadingIndicatorBox(size: 20));
              } else {
                if (result.perfectMatch) {
                  trailingChildren.add(
                    const AppIcon(Symbols.star_rounded, fill: 1, color: Color(0xFFCC7B19), size: 16),
                  );
                }
                if (result.score != null) {
                  trailingChildren.add(
                    Text(
                      result.score!.toInt().toString(),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }
                if (result.key.trim().isNotEmpty) {
                  trailingChildren.add(
                    IconButton(
                      tooltip: isRejected ? 'Show this subtitle revision again' : 'Hide this subtitle revision',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => unawaited(_setRevisionRejected(result, rejected: !isRejected)),
                      icon: Icon(
                        isRejected ? Icons.undo_rounded : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                    ),
                  );
                }
              }

              return FocusableListTile(
                focusNode: index == 0 ? _firstResultFocusNode : null,
                title: Text(result.title ?? result.displayTitle ?? t.common.unknown, maxLines: 1, overflow: .ellipsis),
                subtitle: Text(
                  [
                    result.displayTitle ?? '',
                    if (isRejected) 'Ignored revision',
                  ].where((part) => part.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                trailing: trailingChildren.isEmpty
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: trailingChildren),
                onTap: isDownloading ? null : () => _downloadSubtitle(result),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LanguagePickerView extends StatefulWidget {
  final String currentCode;
  final void Function(String code, String name) onSelected;
  final VoidCallback onBack;

  const _LanguagePickerView({required this.currentCode, required this.onSelected, required this.onBack});

  @override
  State<_LanguagePickerView> createState() => _LanguagePickerViewState();
}

class _LanguagePickerViewState extends State<_LanguagePickerView> with ControllerDisposerMixin {
  late final _filterController = createTextEditingController();
  final _filterFocusNode = FocusNode(debugLabel: 'SubtitleLanguage_filter');
  final _firstLanguageFocusNode = FocusNode(debugLabel: 'SubtitleLanguage_firstResult');
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
    _filterFocusNode.dispose();
    _firstLanguageFocusNode.dispose();
    super.dispose();
  }

  void _focusFirstLanguage() {
    if (_filteredLanguages.isNotEmpty) {
      _firstLanguageFocusNode.requestFocus();
    }
  }

  void _focusFirstLanguageAfterSubmit() {
    if (!InputModeTracker.isKeyboardMode(context)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusFirstLanguage();
    });
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
      // Fills the height cap for the same reason as the search body: the filter
      // field is autofocused and refilters on every keystroke, so a
      // content-driven height would slide the field the user is typing in.
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FocusableTextField(
              controller: _filterController,
              focusNode: _filterFocusNode,
              tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
              autofocus: true,
              decoration: pillInputDecoration(
                context,
                hintText: t.videoControls.searchLanguages,
                prefixIcon: const AppIcon(Symbols.search_rounded, size: 20),
              ),
              onChanged: _onFilterChanged,
              onSubmitted: (_) => _focusFirstLanguageAfterSubmit(),
              onSelect: _focusFirstLanguageAfterSubmit,
              onNavigateDown: _filteredLanguages.isNotEmpty ? _focusFirstLanguage : null,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLanguages.length,
              itemBuilder: (context, index) {
                final lang = _filteredLanguages[index];
                final isSelected = lang.code == widget.currentCode;
                return FocusableListTile(
                  focusNode: index == 0 ? _firstLanguageFocusNode : null,
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
