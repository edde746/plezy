import '../exceptions/media_server_exceptions.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../services/plex_client.dart';
import '../services/plex_constants.dart';
import '../utils/app_logger.dart';
import '../utils/language_codes.dart';
import 'metadata_edit_models.dart';

class PlexMetadataEditAdapter extends MetadataEditAdapter {
  final PlexClient client;

  PlexMetadataEditAdapter(this.client);

  @override
  MediaServerClient get mediaClient => client;

  @override
  bool supportsKind(MediaKind kind) =>
      kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.season || kind == MediaKind.episode;

  @override
  Future<MetadataEditDraft> load(MediaItem item) async {
    MediaItem fullItem = item;
    if (item.summary == null || item.libraryId == null) {
      fullItem = await client.fetchItem(item.id) ?? item;
    }

    late final Map<String, String> preferences;
    if (fullItem.kind == MediaKind.episode) {
      preferences = const {};
    } else {
      try {
        preferences = await client.getMetadataPrefs(fullItem.id);
      } catch (error, stackTrace) {
        if (error is MediaServerHttpException && error.isCancellation) rethrow;
        appLogger.w(
          'Failed to load Plex metadata preferences; continuing without advanced values',
          error: error,
          stackTrace: stackTrace,
        );
        preferences = const {};
      }
    }
    final values = <String, Object?>{};
    _writeCommonValues(values, fullItem);
    _writeArtworkValues(values, fullItem);
    _writeAdvancedValues(values, fullItem.kind, preferences);

    return MetadataEditDraft(sourceItem: item, currentItem: fullItem, values: values);
  }

  @override
  List<MetadataEditSection> buildSchema(MetadataEditDraft draft) {
    final kind = draft.sourceItem.kind;
    return [
      MetadataEditSection(id: 'basic', title: t.metadataEdit.basicInfo, fields: metadataBasicFields(kind)),
      if (_tagFields(kind).isNotEmpty)
        MetadataEditSection(id: 'tags', title: t.metadataEdit.tags, fields: _tagFields(kind)),
      MetadataEditSection(id: 'artwork', title: t.metadataEdit.artwork, fields: _artworkFields(kind)),
      if (kind != MediaKind.episode)
        MetadataEditSection(id: 'advanced', title: t.metadataEdit.advancedSettings, fields: _advancedFields(kind)),
    ];
  }

  @override
  Future<bool> save(MetadataEditDraft draft) async {
    final sectionId = int.tryParse(draft.currentItem.libraryId ?? draft.sourceItem.libraryId ?? '');
    if (sectionId == null) return false;

    Map<String, ({List<String> current, List<String> original})>? tagChanges;
    for (final field in _tagFields(draft.sourceItem.kind)) {
      final current = metadataStringList(draft.values[field.id]);
      final original = metadataStringList(draft.originalValues[field.id]);
      if (metadataEditFieldChanged(draft, field)) {
        tagChanges ??= {};
        tagChanges[field.id] = (current: current, original: original);
      }
    }

    final success = await client.updateMetadata(
      sectionId: sectionId,
      ratingKey: draft.sourceItem.id,
      // supportsKind restricts drafts to the four video kinds.
      typeNumber: PlexMetadataType.forKind(draft.sourceItem.kind) ?? 0,
      title: _changedString(draft, 'title'),
      titleSort: _changedString(draft, 'titleSort'),
      originalTitle: _changedString(draft, 'originalTitle'),
      originallyAvailableAt: _changedString(draft, 'originallyAvailableAt'),
      contentRating: _changedString(draft, 'contentRating'),
      studio: _changedString(draft, 'studio'),
      tagline: _changedString(draft, 'tagline'),
      summary: _changedString(draft, 'summary'),
      tagChanges: tagChanges,
    );
    if (success) draft.acceptChanges();
    return success;
  }

  @override
  Future<bool> saveImmediateField(MetadataEditDraft draft, MetadataEditField field, Object? value) async {
    final prefKey = _prefKey(field.id)!;
    final success = await client.updateMetadataPrefs(draft.sourceItem.id, {prefKey: (value as String?) ?? ''});
    if (success) {
      draft.originalValues[field.id] = value;
    }
    return success;
  }

  @override
  Future<List<MetadataArtworkOption>> fetchArtwork(MetadataEditDraft draft, MetadataEditField field) async {
    final element = field.artwork?.key;
    if (element == null) return const [];
    final artwork = await client.getAvailableArtwork(draft.sourceItem.id, element);
    return artwork
        .map((item) {
          final source = item['ratingKey'] as String? ?? item['key'] as String? ?? '';
          final thumb = item['thumb'] as String? ?? source;
          return MetadataArtworkOption(
            id: source,
            thumbnailPath: thumb,
            sourceUrl: source,
            selected: item['selected'] == true,
          );
        })
        .where((item) => item.sourceUrl.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> applyArtworkFromUrl(MetadataEditDraft draft, MetadataEditField field, String url) async {
    final element = field.artwork?.key;
    if (element == null || url.trim().isEmpty) return false;
    return client.setArtworkFromUrl(draft.sourceItem.id, element, url.trim());
  }

  @override
  Future<bool> uploadArtwork(
    MetadataEditDraft draft,
    MetadataEditField field,
    List<int> bytes, {
    String? fileName,
  }) async {
    final element = field.artwork?.key;
    if (element == null || bytes.isEmpty) return false;
    return client.uploadArtwork(draft.sourceItem.id, element, bytes);
  }

  @override
  void syncReloadedItem(MetadataEditDraft draft, MediaItem item) {
    draft.currentItem = item;
    _writeArtworkValues(draft.values, item);
  }

  void _writeCommonValues(Map<String, Object?> values, MediaItem item) {
    values['title'] = item.title ?? '';
    values['titleSort'] = item.titleSort ?? '';
    values['originalTitle'] = item.originalTitle ?? '';
    values['originallyAvailableAt'] = item.originallyAvailableAt ?? '';
    values['contentRating'] = item.contentRating ?? '';
    values['studio'] = item.studio ?? '';
    values['tagline'] = item.tagline ?? '';
    values['summary'] = item.summary ?? '';
    values['genre'] = List<String>.of(item.genres ?? const []);
    values['director'] = List<String>.of(item.directors ?? const []);
    values['writer'] = List<String>.of(item.writers ?? const []);
    values['producer'] = List<String>.of(item.producers ?? const []);
    values['country'] = List<String>.of(item.countries ?? const []);
    values['collection'] = List<String>.of(item.collections ?? const []);
    values['label'] = List<String>.of(item.labels ?? const []);
    values['style'] = List<String>.of(item.styles ?? const []);
    values['mood'] = List<String>.of(item.moods ?? const []);
  }

  void _writeArtworkValues(Map<String, Object?> values, MediaItem item) {
    values['artwork:posters'] = item.thumbPath;
    values['artwork:arts'] = item.artPath;
    values['artwork:clearLogos'] = item.clearLogoPath;
    values['artwork:squareArts'] = item.backgroundSquarePath;
  }

  void _writeAdvancedValues(Map<String, Object?> values, MediaKind kind, Map<String, String> preferences) {
    void addPreference(String key) {
      values['pref:$key'] = preferences[key];
    }

    if (kind == MediaKind.show) {
      addPreference('episodeSort');
      addPreference('autoDeletionItemPolicyUnwatchedLibrary');
      addPreference('autoDeletionItemPolicyWatchedLibrary');
      addPreference('flattenSeasons');
      addPreference('showOrdering');
    }
    if (kind == MediaKind.show || kind == MediaKind.movie) {
      addPreference('languageOverride');
      addPreference('useOriginalTitle');
    }
    if (kind == MediaKind.show || kind == MediaKind.season) {
      addPreference('audioLanguage');
      addPreference('subtitleLanguage');
      addPreference('subtitleMode');
    }
  }

  List<MetadataEditField> _tagFields(MediaKind kind) {
    MetadataEditField tag(String id, String label) =>
        MetadataEditField(id: id, label: label, type: MetadataEditFieldType.stringList);
    return switch (kind) {
      MediaKind.movie || MediaKind.show => [
        tag('genre', t.metadataEdit.genre),
        tag('director', t.metadataEdit.director),
        tag('writer', t.metadataEdit.writer),
        tag('producer', t.metadataEdit.producer),
        tag('country', t.metadataEdit.country),
        tag('collection', t.metadataEdit.collection),
        tag('label', t.metadataEdit.label),
      ],
      MediaKind.episode => [tag('director', t.metadataEdit.director), tag('writer', t.metadataEdit.writer)],
      _ => const [],
    };
  }

  List<MetadataEditField> _artworkFields(MediaKind kind) => metadataArtworkFields(
    kind,
    posterKey: 'posters',
    backdropKey: 'arts',
    logoKey: 'clearLogos',
    squareKey: 'squareArts',
    logoKinds: const {MediaKind.movie, MediaKind.show, MediaKind.collection},
  );

  List<MetadataEditField> _advancedFields(MediaKind kind) {
    final fields = <MetadataEditField>[];
    if (kind == MediaKind.show) {
      fields.addAll([
        _choice('episodeSort', t.metadataEdit.episodeSorting, [
          MetadataEditOption(value: '-1', label: t.metadataEdit.libraryDefault),
          MetadataEditOption(value: '0', label: t.metadataEdit.oldestFirst),
          MetadataEditOption(value: '1', label: t.metadataEdit.newestFirst),
        ]),
        _choice('autoDeletionItemPolicyUnwatchedLibrary', t.metadataEdit.keep, [
          MetadataEditOption(value: '0', label: t.metadataEdit.allEpisodes),
          MetadataEditOption(
            value: '5',
            label: t.metadataEdit.latestEpisodes(count: '5'),
          ),
          MetadataEditOption(
            value: '3',
            label: t.metadataEdit.latestEpisodes(count: '3'),
          ),
          MetadataEditOption(value: '1', label: t.metadataEdit.latestEpisode),
          MetadataEditOption(
            value: '-3',
            label: t.metadataEdit.episodesAddedPastDays(count: '3'),
          ),
          MetadataEditOption(
            value: '-7',
            label: t.metadataEdit.episodesAddedPastDays(count: '7'),
          ),
          MetadataEditOption(
            value: '-30',
            label: t.metadataEdit.episodesAddedPastDays(count: '30'),
          ),
        ]),
        _choice('autoDeletionItemPolicyWatchedLibrary', t.metadataEdit.deleteAfterPlaying, [
          MetadataEditOption(value: '0', label: t.metadataEdit.never),
          MetadataEditOption(value: '1', label: t.metadataEdit.afterADay),
          MetadataEditOption(value: '7', label: t.metadataEdit.afterAWeek),
          MetadataEditOption(value: '30', label: t.metadataEdit.afterAMonth),
          MetadataEditOption(value: '100', label: t.metadataEdit.onNextRefresh),
        ]),
        _choice('flattenSeasons', t.metadataEdit.seasons, [
          MetadataEditOption(value: '-1', label: t.metadataEdit.libraryDefault),
          MetadataEditOption(value: '0', label: t.metadataEdit.show),
          MetadataEditOption(value: '1', label: t.metadataEdit.hide),
        ]),
        _choice('showOrdering', t.metadataEdit.episodeOrdering, [
          MetadataEditOption(value: '', label: t.metadataEdit.libraryDefault),
          MetadataEditOption(value: 'tmdbAiring', label: t.metadataEdit.tmdbAiring),
          MetadataEditOption(value: 'tvdbAiring', label: t.metadataEdit.tvdbAiring),
          MetadataEditOption(value: 'tvdbAbsolute', label: t.metadataEdit.tvdbAbsolute),
        ]),
      ]);
      fields.addAll(_metadataLanguageFields(t.metadataEdit.libraryDefault));
      fields.addAll(_audioSubtitleFields(t.metadataEdit.accountDefault));
    } else if (kind == MediaKind.movie) {
      fields.addAll(_metadataLanguageFields(t.metadataEdit.libraryDefault));
    } else if (kind == MediaKind.season) {
      fields.addAll(_audioSubtitleFields(t.metadataEdit.seriesDefault));
    }
    return fields;
  }

  List<MetadataEditField> _metadataLanguageFields(String defaultLabel) => [
    _choice('languageOverride', t.metadataEdit.metadataLanguage, _metadataLanguageOptions(defaultLabel)),
    _choice('useOriginalTitle', t.metadataEdit.useOriginalTitle, [
      MetadataEditOption(value: '-1', label: t.metadataEdit.libraryDefault),
      MetadataEditOption(value: '0', label: t.common.no),
      MetadataEditOption(value: '1', label: t.common.yes),
    ]),
  ];

  List<MetadataEditField> _audioSubtitleFields(String defaultLabel) => [
    _choice('audioLanguage', t.metadataEdit.preferredAudioLanguage, _audioSubtitleLanguageOptions(defaultLabel)),
    _choice('subtitleLanguage', t.metadataEdit.preferredSubtitleLanguage, _audioSubtitleLanguageOptions(defaultLabel)),
    _choice('subtitleMode', t.metadataEdit.subtitleMode, [
      MetadataEditOption(value: '-1', label: defaultLabel),
      MetadataEditOption(value: '0', label: t.metadataEdit.manuallySelected),
      MetadataEditOption(value: '1', label: t.metadataEdit.shownWithForeignAudio),
      MetadataEditOption(value: '2', label: t.metadataEdit.alwaysEnabled),
    ]),
  ];

  MetadataEditField _choice(String prefKey, String label, List<MetadataEditOption> options) {
    return MetadataEditField(
      id: 'pref:$prefKey',
      label: label,
      type: MetadataEditFieldType.choice,
      saveMode: MetadataEditSaveMode.immediate,
      options: options,
    );
  }

  String? _changedString(MetadataEditDraft draft, String id) {
    if (!draft.fieldChanged(id)) return null;
    return (draft.values[id] as String?) ?? '';
  }

  String? _prefKey(String fieldId) => fieldId.startsWith('pref:') ? fieldId.substring(5) : null;
}

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

const _commonAudioSubtitleCodes = ['en', 'ja', 'fr', 'de', 'it', 'es', 'pt', 'ru', 'ar'];

List<MetadataEditOption> _buildLanguageOptions(String defaultLabel, List<String> codes) {
  return [
    MetadataEditOption(value: '', label: defaultLabel),
    ...codes.map((code) => MetadataEditOption(value: code, label: LanguageCodes.getDisplayName(code))),
  ];
}

List<MetadataEditOption> _metadataLanguageOptions(String defaultLabel) =>
    _buildLanguageOptions(defaultLabel, _plexLocaleCodes);

List<MetadataEditOption> _audioSubtitleLanguageOptions(String defaultLabel) =>
    _buildLanguageOptions(defaultLabel, [..._commonAudioSubtitleCodes, ..._plexLocaleCodes]);
