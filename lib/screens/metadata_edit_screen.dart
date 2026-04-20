import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../utils/dialogs.dart';
import '../utils/language_codes.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/artwork_picker_dialog.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/plex_optimized_image.dart';
import '../widgets/tag_edit_dialog.dart';

class MetadataEditScreen extends StatefulWidget {
  final PlexMetadata metadata;

  const MetadataEditScreen({super.key, required this.metadata});

  @override
  State<MetadataEditScreen> createState() => _MetadataEditScreenState();
}

class _MetadataEditScreenState extends State<MetadataEditScreen> {
  late PlexClient _client;
  PlexMetadata? _fullMetadata;
  bool _isLoading = true;
  bool _isSaving = false;

  // Text field values
  String? _title;
  String? _titleSort;
  String? _originalTitle;
  String? _originallyAvailableAt;
  String? _contentRating;
  String? _studio;
  String? _tagline;
  String? _summary;

  // Original values for change detection
  String? _origTitle;
  String? _origTitleSort;
  String? _origOriginalTitle;
  String? _origOriginallyAvailableAt;
  String? _origContentRating;
  String? _origStudio;
  String? _origTagline;
  String? _origSummary;

  // Tag field values
  final Map<String, List<String>> _tags = {};
  final Map<String, List<String>> _origTags = {};

  // Advanced prefs (loaded from metadata JSON)
  final Map<String, String> _currentPrefs = {};

  static bool _tagsEqual(List<String> a, List<String> b) => a.length == b.length && a.every((e) => b.contains(e));

  bool get _hasTagChanges => _tags.keys.any((k) => !_tagsEqual(_tags[k] ?? [], _origTags[k] ?? []));

  bool get _hasChanges =>
      _title != _origTitle ||
      _titleSort != _origTitleSort ||
      _originalTitle != _origOriginalTitle ||
      _originallyAvailableAt != _origOriginallyAvailableAt ||
      _contentRating != _origContentRating ||
      _studio != _origStudio ||
      _tagline != _origTagline ||
      _summary != _origSummary ||
      _hasTagChanges;

  PlexMediaType get _mediaType => widget.metadata.mediaType;

  @override
  void initState() {
    super.initState();
    _client = context.getClientWithFallback(widget.metadata.serverId);
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      // If the passed metadata already has full fields (e.g., from detail screen),
      // use it directly instead of re-fetching. We check both summary and
      // librarySectionID since the edit screen needs both for display and save.
      if (widget.metadata.summary != null && widget.metadata.librarySectionID != null) {
        _fullMetadata = widget.metadata;
        _initFieldsFromMetadata(widget.metadata);
        setState(() => _isLoading = false);
        return;
      }

      final meta = await _client.getMetadataWithImages(widget.metadata.ratingKey);
      if (!mounted) return;
      if (meta != null) {
        _fullMetadata = meta;
        _initFieldsFromMetadata(meta);
      } else {
        _initFieldsFromMetadata(widget.metadata);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _initFieldsFromMetadata(widget.metadata);
      setState(() => _isLoading = false);
    }
  }

  void _initFieldsFromMetadata(PlexMetadata meta) {
    _title = meta.title;
    _titleSort = meta.titleSort ?? '';
    _originalTitle = meta.originalTitle ?? '';
    _originallyAvailableAt = meta.originallyAvailableAt ?? '';
    _contentRating = meta.contentRating ?? '';
    _studio = meta.studio ?? '';
    _tagline = meta.tagline ?? '';
    _summary = meta.summary ?? '';

    _origTitle = _title;
    _origTitleSort = _titleSort;
    _origOriginalTitle = _originalTitle;
    _origOriginallyAvailableAt = _originallyAvailableAt;
    _origContentRating = _contentRating;
    _origStudio = _studio;
    _origTagline = _tagline;
    _origSummary = _summary;

    void initTag(String key, List<String>? values) {
      _tags[key] = List.of(values ?? []);
      _origTags[key] = List.of(values ?? []);
    }

    initTag('genre', meta.genre);
    initTag('director', meta.director);
    initTag('writer', meta.writer);
    initTag('producer', meta.producer);
    initTag('country', meta.country);
    initTag('collection', meta.collection);
    initTag('label', meta.label);
    initTag('style', meta.style);
    initTag('mood', meta.mood);
  }

  Future<void> _save() async {
    if (!_hasChanges || _isSaving) return;

    final sectionId = _fullMetadata?.librarySectionID ?? widget.metadata.librarySectionID;
    if (sectionId == null) {
      if (mounted) showErrorSnackBar(context, t.metadataEdit.metadataUpdateFailed);
      return;
    }

    setState(() => _isSaving = true);

    Map<String, ({List<String> current, List<String> original})>? tagChanges;
    for (final key in _tags.keys) {
      final current = _tags[key] ?? [];
      final original = _origTags[key] ?? [];
      if (!_tagsEqual(current, original)) {
        tagChanges ??= {};
        tagChanges[key] = (current: current, original: original);
      }
    }

    final success = await _client.updateMetadata(
      sectionId: sectionId,
      ratingKey: widget.metadata.ratingKey,
      typeNumber: _mediaType.typeNumber,
      title: _title != _origTitle ? _title : null,
      titleSort: _titleSort != _origTitleSort ? _titleSort : null,
      originalTitle: _originalTitle != _origOriginalTitle ? _originalTitle : null,
      originallyAvailableAt: _originallyAvailableAt != _origOriginallyAvailableAt ? _originallyAvailableAt : null,
      contentRating: _contentRating != _origContentRating ? _contentRating : null,
      studio: _studio != _origStudio ? _studio : null,
      tagline: _tagline != _origTagline ? _tagline : null,
      summary: _summary != _origSummary ? _summary : null,
      tagChanges: tagChanges,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      showSuccessSnackBar(context, t.metadataEdit.metadataUpdated);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.metadataEdit.metadataUpdateFailed);
    }
  }

  Future<void> _editTextField({
    required String title,
    required String label,
    required String? currentValue,
    required ValueChanged<String> onChanged,
    bool multiline = false,
  }) async {
    final String? result;
    if (multiline) {
      result = await showMultilineTextInputDialog(context, title: title, labelText: label, initialValue: currentValue);
    } else {
      result = await showTextInputDialog(
        context,
        title: title,
        labelText: label,
        hintText: '',
        initialValue: currentValue,
      );
    }

    if (result != null && mounted) {
      final value = result;
      setState(() => onChanged(value));
    }
  }

  Future<void> _editDate() async {
    DateTime initial = DateTime.now();
    if (_originallyAvailableAt != null && _originallyAvailableAt!.isNotEmpty) {
      final parsed = DateTime.tryParse(_originallyAvailableAt!);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime(2200),
    );

    if (picked != null && mounted) {
      setState(() {
        _originallyAvailableAt =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _openArtworkPicker(String element) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ArtworkPickerDialog(client: _client, ratingKey: widget.metadata.ratingKey, element: element),
    );

    if (result == true && mounted) {
      // Re-fetch metadata to get updated artwork paths without resetting
      // any text field edits the user may have made.
      await _reloadArtwork();
    }
  }

  Future<void> _reloadArtwork() async {
    try {
      final meta = await _client.getMetadataWithImages(widget.metadata.ratingKey);
      if (!mounted) return;
      if (meta != null) {
        setState(() => _fullMetadata = meta);
      }
    } catch (_) {
      // Artwork was already saved by the picker; display will refresh next
      // time the editor is opened.
    }
  }

  Future<void> _showAdvancedSettingDialog({
    required String title,
    required String prefKey,
    required List<({String value, String label})> options,
  }) async {
    // Determine current value from metadata or default
    final currentValue = _currentPrefs[prefKey] ?? _getMetadataPrefValue(prefKey);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? selected = currentValue;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: RadioGroup<String>(
                  groupValue: selected,
                  onChanged: (val) {
                    setDialogState(() => selected = val);
                    Navigator.pop(dialogContext, val);
                  },
                  child: ListView(
                    shrinkWrap: true,
                    children: options.map((option) {
                      return FocusableRadioListTile<String>(title: Text(option.label), value: option.value);
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                FocusableButton(
                  autofocus: true,
                  onPressed: () => Navigator.pop(dialogContext),
                  child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _currentPrefs[prefKey] = result);
      await _client.updateMetadataPrefs(widget.metadata.ratingKey, {prefKey: result});
    }
  }

  String _getMetadataPrefValue(String key) {
    // These prefs appear as keys on the raw metadata JSON when non-default.
    // Since we use typed models, we check known fields.
    final meta = _fullMetadata ?? widget.metadata;
    switch (key) {
      case 'audioLanguage':
        return meta.audioLanguage ?? '';
      case 'subtitleLanguage':
        return meta.subtitleLanguage ?? '';
      case 'subtitleMode':
        return meta.subtitleMode?.toString() ?? '-1';
      default:
        return '';
    }
  }

  String _getDisplayValueForPref(String prefKey, List<({String value, String label})> options) {
    final val = _currentPrefs[prefKey] ?? _getMetadataPrefValue(prefKey);
    for (final option in options) {
      if (option.value == val) return option.label;
    }
    return options.first.label;
  }

  // ===== Field visibility =====

  bool get _showSortTitle => _mediaType != PlexMediaType.season;
  bool get _showOriginalTitle => _mediaType == PlexMediaType.movie || _mediaType == PlexMediaType.show;
  bool get _showReleaseDate => _mediaType != PlexMediaType.season;
  bool get _showContentRating => _mediaType != PlexMediaType.season;
  bool get _showStudio => _mediaType == PlexMediaType.movie || _mediaType == PlexMediaType.show;
  bool get _showTagline => _mediaType == PlexMediaType.movie || _mediaType == PlexMediaType.show;
  bool get _showBackground =>
      _mediaType == PlexMediaType.movie || _mediaType == PlexMediaType.show || _mediaType == PlexMediaType.episode;
  bool get _showExtendedArtwork =>
      _mediaType == PlexMediaType.movie || _mediaType == PlexMediaType.show || _mediaType == PlexMediaType.collection;
  bool get _showAdvanced => _mediaType != PlexMediaType.episode;

  List<({String key, String label})> get _tagFields {
    switch (_mediaType) {
      case PlexMediaType.movie:
      case PlexMediaType.show:
        return [
          (key: 'genre', label: t.metadataEdit.genre),
          (key: 'director', label: t.metadataEdit.director),
          (key: 'writer', label: t.metadataEdit.writer),
          (key: 'producer', label: t.metadataEdit.producer),
          (key: 'country', label: t.metadataEdit.country),
          (key: 'collection', label: t.metadataEdit.collection),
          (key: 'label', label: t.metadataEdit.label),
        ];
      case PlexMediaType.episode:
        return [(key: 'director', label: t.metadataEdit.director), (key: 'writer', label: t.metadataEdit.writer)];
      case PlexMediaType.artist:
        return [
          (key: 'genre', label: t.metadataEdit.genre),
          (key: 'style', label: t.metadataEdit.style),
          (key: 'mood', label: t.metadataEdit.mood),
          (key: 'country', label: t.metadataEdit.country),
          (key: 'collection', label: t.metadataEdit.collection),
        ];
      case PlexMediaType.album:
        return [
          (key: 'genre', label: t.metadataEdit.genre),
          (key: 'style', label: t.metadataEdit.style),
          (key: 'mood', label: t.metadataEdit.mood),
          (key: 'collection', label: t.metadataEdit.collection),
        ];
      default:
        return [];
    }
  }

  Future<void> _editTag(String key, String label) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TagEditDialog(title: label, initialTags: _tags[key] ?? []),
    );
    if (result != null && mounted) {
      setState(() => _tags[key] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FocusedScrollScaffold(
        title: Text(t.metadataEdit.screenTitle),
        slivers: [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

    return FocusedScrollScaffold(
      title: Text(t.metadataEdit.screenTitle),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          IconButton(onPressed: _hasChanges ? _save : null, icon: const AppIcon(Symbols.check_rounded, fill: 1)),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildBasicInfoCard(),
              if (_tagFields.isNotEmpty) ...[const SizedBox(height: 16), _buildTagsCard()],
              const SizedBox(height: 16),
              _buildArtworkCard(),
              if (_showAdvanced) ...[const SizedBox(height: 16), _buildAdvancedSettingsCard()],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.metadataEdit.basicInfo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildFieldTile(
            label: t.metadataEdit.title,
            value: _title,
            onTap: () => _editTextField(
              title: t.metadataEdit.title,
              label: t.metadataEdit.title,
              currentValue: _title,
              onChanged: (v) => _title = v,
            ),
          ),
          if (_showSortTitle)
            _buildFieldTile(
              label: t.metadataEdit.sortTitle,
              value: _titleSort,
              onTap: () => _editTextField(
                title: t.metadataEdit.sortTitle,
                label: t.metadataEdit.sortTitle,
                currentValue: _titleSort,
                onChanged: (v) => _titleSort = v,
              ),
            ),
          if (_showOriginalTitle)
            _buildFieldTile(
              label: t.metadataEdit.originalTitle,
              value: _originalTitle,
              onTap: () => _editTextField(
                title: t.metadataEdit.originalTitle,
                label: t.metadataEdit.originalTitle,
                currentValue: _originalTitle,
                onChanged: (v) => _originalTitle = v,
              ),
            ),
          if (_showReleaseDate)
            _buildFieldTile(label: t.metadataEdit.releaseDate, value: _originallyAvailableAt, onTap: _editDate),
          if (_showContentRating)
            _buildFieldTile(
              label: t.metadataEdit.contentRating,
              value: _contentRating,
              onTap: () => _editTextField(
                title: t.metadataEdit.contentRating,
                label: t.metadataEdit.contentRating,
                currentValue: _contentRating,
                onChanged: (v) => _contentRating = v,
              ),
            ),
          if (_showStudio)
            _buildFieldTile(
              label: t.metadataEdit.studio,
              value: _studio,
              onTap: () => _editTextField(
                title: t.metadataEdit.studio,
                label: t.metadataEdit.studio,
                currentValue: _studio,
                onChanged: (v) => _studio = v,
              ),
            ),
          if (_showTagline)
            _buildFieldTile(
              label: t.metadataEdit.tagline,
              value: _tagline,
              onTap: () => _editTextField(
                title: t.metadataEdit.tagline,
                label: t.metadataEdit.tagline,
                currentValue: _tagline,
                onChanged: (v) => _tagline = v,
              ),
            ),
          _buildFieldTile(
            label: t.metadataEdit.summary,
            value: _summary,
            onTap: () => _editTextField(
              title: t.metadataEdit.summary,
              label: t.metadataEdit.summary,
              currentValue: _summary,
              onChanged: (v) => _summary = v,
              multiline: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTile({required String label, String? value, required VoidCallback onTap}) {
    final displayValue = (value == null || value.isEmpty) ? t.metadataEdit.notSet : value;
    final isNotSet = value == null || value.isEmpty;

    return ListTile(
      title: Text(label),
      subtitle: Text(
        displayValue,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: isNotSet
            ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))
            : null,
      ),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildTagsCard() {
    final fields = _tagFields;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.metadataEdit.tags,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (final field in fields)
            _buildFieldTile(
              label: field.label,
              value: (_tags[field.key] ?? []).isEmpty ? null : (_tags[field.key]!).join(', '),
              onTap: () => _editTag(field.key, field.label),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkTile({
    required double width,
    required double height,
    required String? imagePath,
    required String label,
    required String element,
    BoxFit fit = BoxFit.cover,
  }) {
    return ListTile(
      leading: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: PlexOptimizedImage(client: _client, imagePath: imagePath, width: width, height: height, fit: fit),
        ),
      ),
      title: Text(label),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: () => _openArtworkPicker(element),
    );
  }

  Widget _buildArtworkCard() {
    final meta = _fullMetadata ?? widget.metadata;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.metadataEdit.artwork,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildArtworkTile(
            width: 40,
            height: 60,
            imagePath: meta.thumb,
            label: t.metadataEdit.poster,
            element: 'posters',
          ),
          if (_showBackground)
            _buildArtworkTile(
              width: 80,
              height: 45,
              imagePath: meta.art,
              label: t.metadataEdit.background,
              element: 'arts',
            ),
          if (_showExtendedArtwork)
            _buildArtworkTile(
              width: 80,
              height: 32,
              imagePath: meta.clearLogo,
              label: t.metadataEdit.logo,
              element: 'clearLogos',
              fit: BoxFit.contain,
            ),
          if (_showExtendedArtwork)
            _buildArtworkTile(
              width: 50,
              height: 50,
              imagePath: meta.backgroundSquare,
              label: t.metadataEdit.squareArt,
              element: 'squareArts',
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.metadataEdit.advancedSettings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (_mediaType == PlexMediaType.show) ..._buildShowAdvancedSettings(),
          if (_mediaType == PlexMediaType.movie) ..._buildMovieAdvancedSettings(),
          if (_mediaType == PlexMediaType.season) ..._buildSeasonAdvancedSettings(),
        ],
      ),
    );
  }

  List<Widget> _buildShowAdvancedSettings() {
    return [
      _buildAdvancedTile(
        title: t.metadataEdit.episodeSorting,
        prefKey: 'episodeSort',
        options: [
          (value: '-1', label: t.metadataEdit.libraryDefault),
          (value: '0', label: t.metadataEdit.oldestFirst),
          (value: '1', label: t.metadataEdit.newestFirst),
        ],
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.keep,
        prefKey: 'autoDeletionItemPolicyUnwatchedLibrary',
        options: [
          (value: '0', label: t.metadataEdit.allEpisodes),
          (value: '5', label: t.metadataEdit.latestEpisodes(count: '5')),
          (value: '3', label: t.metadataEdit.latestEpisodes(count: '3')),
          (value: '1', label: t.metadataEdit.latestEpisode),
          (value: '-3', label: t.metadataEdit.episodesAddedPastDays(count: '3')),
          (value: '-7', label: t.metadataEdit.episodesAddedPastDays(count: '7')),
          (value: '-30', label: t.metadataEdit.episodesAddedPastDays(count: '30')),
        ],
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.deleteAfterPlaying,
        prefKey: 'autoDeletionItemPolicyWatchedLibrary',
        options: [
          (value: '0', label: t.metadataEdit.never),
          (value: '1', label: t.metadataEdit.afterADay),
          (value: '7', label: t.metadataEdit.afterAWeek),
          (value: '30', label: t.metadataEdit.afterAMonth),
          (value: '100', label: t.metadataEdit.onNextRefresh),
        ],
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.seasons,
        prefKey: 'flattenSeasons',
        options: [
          (value: '-1', label: t.metadataEdit.libraryDefault),
          (value: '0', label: t.metadataEdit.show),
          (value: '1', label: t.metadataEdit.hide),
        ],
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.episodeOrdering,
        prefKey: 'showOrdering',
        options: [
          (value: '', label: t.metadataEdit.libraryDefault),
          (value: 'tmdbAiring', label: t.metadataEdit.tmdbAiring),
          (value: 'tvdbAiring', label: t.metadataEdit.tvdbAiring),
          (value: 'tvdbAbsolute', label: t.metadataEdit.tvdbAbsolute),
        ],
      ),
      ..._buildMetadataLanguageTiles(),
      ..._buildAudioSubtitleTiles(t.metadataEdit.accountDefault),
    ];
  }

  List<Widget> _buildMovieAdvancedSettings() {
    return _buildMetadataLanguageTiles();
  }

  List<Widget> _buildSeasonAdvancedSettings() {
    return _buildAudioSubtitleTiles(t.metadataEdit.seriesDefault);
  }

  List<Widget> _buildMetadataLanguageTiles() {
    return [
      _buildAdvancedTile(
        title: t.metadataEdit.metadataLanguage,
        prefKey: 'languageOverride',
        options: _metadataLanguageOptions(t.metadataEdit.libraryDefault),
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.useOriginalTitle,
        prefKey: 'useOriginalTitle',
        options: [
          (value: '-1', label: t.metadataEdit.libraryDefault),
          (value: '0', label: t.common.no),
          (value: '1', label: t.common.yes),
        ],
      ),
    ];
  }

  List<Widget> _buildAudioSubtitleTiles(String defaultLabel) {
    return [
      _buildAdvancedTile(
        title: t.metadataEdit.preferredAudioLanguage,
        prefKey: 'audioLanguage',
        options: _audioSubtitleLanguageOptions(defaultLabel),
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.preferredSubtitleLanguage,
        prefKey: 'subtitleLanguage',
        options: _audioSubtitleLanguageOptions(defaultLabel),
      ),
      _buildAdvancedTile(
        title: t.metadataEdit.subtitleMode,
        prefKey: 'subtitleMode',
        options: [
          (value: '-1', label: defaultLabel),
          (value: '0', label: t.metadataEdit.manuallySelected),
          (value: '1', label: t.metadataEdit.shownWithForeignAudio),
          (value: '2', label: t.metadataEdit.alwaysEnabled),
        ],
      ),
    ];
  }

  Widget _buildAdvancedTile({
    required String title,
    required String prefKey,
    required List<({String value, String label})> options,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(_getDisplayValueForPref(prefKey, options)),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: () => _showAdvancedSettingDialog(title: title, prefKey: prefKey, options: options),
    );
  }
}

// ===== Language option lists =====

// Plex locale codes for metadata agent language.
const _plexLocaleCodes = [
  'ar-SA',
  'bg-BG',
  'ca-ES',
  'zh-CN',
  'zh-HK',
  'zh-TW',
  'hr-HR',
  'cs-CZ',
  'da-DK',
  'nl-NL',
  'en-US',
  'en-AU',
  'en-CA',
  'en-GB',
  'et-EE',
  'fi-FI',
  'fr-FR',
  'fr-CA',
  'de-DE',
  'el-GR',
  'he-IL',
  'hi-IN',
  'hu-HU',
  'is-IS',
  'id-ID',
  'it-IT',
  'ja-JP',
  'ko-KR',
  'lv-LV',
  'lt-LT',
  'nb-NO',
  'fa-IR',
  'pl-PL',
  'pt-BR',
  'pt-PT',
  'ro-RO',
  'ru-RU',
  'sk-SK',
  'es-ES',
  'es-MX',
  'sv-SE',
  'th-TH',
  'tr-TR',
  'uk-UA',
  'vi-VN',
];

// Common 2-letter codes shown at the top of audio/subtitle pickers.
const _commonAudioSubtitleCodes = ['en', 'ja', 'fr', 'de', 'it', 'es', 'pt', 'ru', 'ar'];

List<({String value, String label})> _buildLanguageOptions(String defaultLabel, List<String> codes) {
  return [(value: '', label: defaultLabel), ...codes.map((c) => (value: c, label: LanguageCodes.getDisplayName(c)))];
}

List<({String value, String label})> _metadataLanguageOptions(String defaultLabel) =>
    _buildLanguageOptions(defaultLabel, _plexLocaleCodes);

List<({String value, String label})> _audioSubtitleLanguageOptions(String defaultLabel) =>
    _buildLanguageOptions(defaultLabel, [..._commonAudioSubtitleCodes, ..._plexLocaleCodes]);
