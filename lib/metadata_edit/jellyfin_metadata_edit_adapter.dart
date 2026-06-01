import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../services/jellyfin_client.dart';
import '../utils/jellyfin_time.dart';
import 'metadata_edit_models.dart';

class JellyfinMetadataEditAdapter extends MetadataEditAdapter {
  final JellyfinClient client;

  JellyfinMetadataEditAdapter(this.client);

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  MediaServerClient get mediaClient => client;

  @override
  bool supportsKind(MediaKind kind) =>
      kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.season || kind == MediaKind.episode;

  @override
  Future<MetadataEditDraft> load(MediaItem item) async {
    final raw = await client.fetchEditableMetadataItem(item.id);
    if (raw == null) {
      throw StateError('Editable Jellyfin metadata item is unavailable');
    }
    final values = <String, Object?>{};
    _writeCommonValues(values, raw, item);
    _writeArtworkValues(values, item);
    return MetadataEditDraft(sourceItem: item, currentItem: item, values: values, extras: {'raw': raw});
  }

  @override
  List<MetadataEditSection> buildSchema(MetadataEditDraft draft) {
    final kind = draft.sourceItem.kind;
    return [
      MetadataEditSection(id: 'basic', title: t.metadataEdit.basicInfo, fields: _basicFields(kind)),
      if (_tagFields(kind).isNotEmpty)
        MetadataEditSection(id: 'tags', title: t.metadataEdit.tags, fields: _tagFields(kind)),
      MetadataEditSection(id: 'artwork', title: t.metadataEdit.artwork, fields: _artworkFields(kind)),
    ];
  }

  @override
  Future<bool> save(MetadataEditDraft draft) async {
    final raw = draft.extras['raw'];
    if (raw is! Map<String, dynamic>) return false;
    final dto = Map<String, dynamic>.from(raw);

    dto['ProviderIds'] = _stringMap(dto['ProviderIds']);
    dto['Tags'] = _stringList(dto['Tags']);
    dto['Genres'] = _stringList(dto['Genres']);
    dto['People'] = _mapList(dto['People']);
    dto['Studios'] = _mapList(dto['Studios']);
    dto['LockedFields'] = _stringList(dto['LockedFields']);
    dto['LockData'] = dto['LockData'] == true;
    dto.remove('Trickplay');

    if (draft.fieldChanged('title')) dto['Name'] = (draft.value<String>('title') ?? '').trim();
    _setChangedString(dto, draft, 'titleSort', 'ForcedSortName');
    _setChangedString(dto, draft, 'originalTitle', 'OriginalTitle');
    _setChangedString(dto, draft, 'contentRating', 'OfficialRating');
    _setChangedString(dto, draft, 'summary', 'Overview');

    if (draft.fieldChanged('originallyAvailableAt')) {
      final value = draft.value<String>('originallyAvailableAt') ?? '';
      dto['PremiereDate'] = _jellyfinDate(value, raw['PremiereDate']);
    }
    if (_fieldChanged(draft, 'studio')) {
      dto['Studios'] = _replaceNamePairs(_mapList(dto['Studios']), metadataStringList(draft.values['studio']));
    }
    if (draft.fieldChanged('tagline')) {
      final tagline = metadataEmptyToNull(draft.value<String>('tagline'));
      final existing = _stringList(dto['Taglines']);
      dto['Taglines'] = tagline == null ? <String>[] : <String>[tagline, ...existing.skip(1)];
    }
    if (_fieldChanged(draft, 'genre')) dto['Genres'] = metadataStringList(draft.values['genre']);
    if (_fieldChanged(draft, 'country')) dto['ProductionLocations'] = metadataStringList(draft.values['country']);
    if (_fieldChanged(draft, 'label')) dto['Tags'] = metadataStringList(draft.values['label']);

    var peopleChanged = false;
    var people = _mapList(dto['People']);
    if (_fieldChanged(draft, 'director')) {
      people = _replacePeopleByType(people, 'Director', metadataStringList(draft.values['director']));
      peopleChanged = true;
    }
    if (_fieldChanged(draft, 'writer')) {
      people = _replacePeopleByType(people, 'Writer', metadataStringList(draft.values['writer']));
      peopleChanged = true;
    }
    if (_fieldChanged(draft, 'producer')) {
      people = _replacePeopleByType(people, 'Producer', metadataStringList(draft.values['producer']));
      peopleChanged = true;
    }
    if (peopleChanged) dto['People'] = people;

    final success = await client.updateMetadataItem(draft.sourceItem.id, dto);
    if (success) {
      draft.extras['raw'] = dto;
      draft.acceptChanges();
    }
    return success;
  }

  @override
  Future<List<MetadataArtworkOption>> fetchArtwork(MetadataEditDraft draft, MetadataEditField field) async {
    final imageType = field.artwork?.key;
    if (imageType == null) return const [];
    final result = await client.getRemoteImages(draft.sourceItem.id, imageType: imageType);
    final images = result['Images'];
    if (images is! List) return const [];
    return images
        .whereType<Map<String, dynamic>>()
        .map((image) {
          final url = image['Url'] as String? ?? '';
          final thumb = image['ThumbnailUrl'] as String?;
          return MetadataArtworkOption(
            id: url,
            thumbnailPath: (thumb == null || thumb.isEmpty) ? url : thumb,
            sourceUrl: url,
            provider: image['ProviderName'] as String?,
            width: image['Width'] as int?,
            height: image['Height'] as int?,
          );
        })
        .where((image) => image.sourceUrl.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> applyArtworkOption(MetadataEditDraft draft, MetadataEditField field, MetadataArtworkOption option) {
    return applyArtworkFromUrl(draft, field, option.sourceUrl);
  }

  @override
  Future<bool> applyArtworkFromUrl(MetadataEditDraft draft, MetadataEditField field, String url) async {
    final imageType = field.artwork?.key;
    if (imageType == null || url.trim().isEmpty) return false;
    return client.downloadRemoteImage(draft.sourceItem.id, imageType: imageType, imageUrl: url.trim());
  }

  @override
  Future<bool> uploadArtwork(
    MetadataEditDraft draft,
    MetadataEditField field,
    List<int> bytes, {
    String? fileName,
  }) async {
    final imageType = field.artwork?.key;
    if (imageType == null || bytes.isEmpty) return false;
    return client.uploadItemImage(
      draft.sourceItem.id,
      imageType: imageType,
      bytes: bytes,
      contentType: _imageContentType(bytes, fileName),
    );
  }

  @override
  void syncReloadedItem(MetadataEditDraft draft, MediaItem item) {
    draft.currentItem = item;
    _writeArtworkValues(draft.values, item);
  }

  void _writeCommonValues(Map<String, Object?> values, Map<String, dynamic> raw, MediaItem item) {
    values['title'] = raw['Name'] as String? ?? item.title ?? '';
    values['titleSort'] = raw['ForcedSortName'] as String? ?? '';
    values['originalTitle'] = raw['OriginalTitle'] as String? ?? item.originalTitle ?? '';
    values['originallyAvailableAt'] =
        jellyfinIsoToYmd(raw['PremiereDate'] as String?) ?? item.originallyAvailableAt ?? '';
    values['contentRating'] = raw['OfficialRating'] as String? ?? item.contentRating ?? '';
    final studios = _nameList(raw['Studios']);
    values['studio'] = studios.isNotEmpty ? studios : metadataStringList(item.studio);
    values['tagline'] = metadataFirstString(raw['Taglines']).isNotEmpty
        ? metadataFirstString(raw['Taglines'])
        : item.tagline ?? '';
    values['summary'] = raw['Overview'] as String? ?? item.summary ?? '';
    values['genre'] = _stringList(raw['Genres']);
    values['director'] = _peopleByType(raw['People'], 'Director');
    values['writer'] = _peopleByType(raw['People'], 'Writer');
    values['producer'] = _peopleByType(raw['People'], 'Producer');
    values['country'] = _stringList(raw['ProductionLocations']);
    values['label'] = _stringList(raw['Tags']);
  }

  void _writeArtworkValues(Map<String, Object?> values, MediaItem item) {
    values['artwork:Primary'] = item.thumbPath;
    values['artwork:Backdrop'] = item.artPath;
    values['artwork:Logo'] = item.clearLogoPath;
  }

  List<MetadataEditField> _basicFields(MediaKind kind) {
    return [
      MetadataEditField(id: 'title', label: t.metadataEdit.title, type: MetadataEditFieldType.text),
      if (kind != MediaKind.season)
        MetadataEditField(id: 'titleSort', label: t.metadataEdit.sortTitle, type: MetadataEditFieldType.text),
      if (kind == MediaKind.movie || kind == MediaKind.show)
        MetadataEditField(id: 'originalTitle', label: t.metadataEdit.originalTitle, type: MetadataEditFieldType.text),
      if (kind != MediaKind.season)
        MetadataEditField(
          id: 'originallyAvailableAt',
          label: t.metadataEdit.releaseDate,
          type: MetadataEditFieldType.date,
        ),
      if (kind != MediaKind.season)
        MetadataEditField(id: 'contentRating', label: t.metadataEdit.contentRating, type: MetadataEditFieldType.text),
      if (kind == MediaKind.movie || kind == MediaKind.show)
        MetadataEditField(id: 'studio', label: t.metadataEdit.studio, type: MetadataEditFieldType.stringList),
      if (kind == MediaKind.movie || kind == MediaKind.show)
        MetadataEditField(id: 'tagline', label: t.metadataEdit.tagline, type: MetadataEditFieldType.text),
      MetadataEditField(id: 'summary', label: t.metadataEdit.summary, type: MetadataEditFieldType.multilineText),
    ];
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
        tag('label', t.metadataEdit.label),
      ],
      MediaKind.episode => [tag('director', t.metadataEdit.director), tag('writer', t.metadataEdit.writer)],
      _ => const [],
    };
  }

  List<MetadataEditField> _artworkFields(MediaKind kind) {
    final fields = <MetadataEditField>[
      _artworkField('Primary', t.metadataEdit.poster, t.metadataEdit.selectPoster, 40, 60, 3, 2 / 3),
    ];
    if (kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.episode) {
      fields.add(
        _artworkField('Backdrop', t.metadataEdit.background, t.metadataEdit.selectBackground, 80, 45, 2, 16 / 9),
      );
    }
    if (kind == MediaKind.movie || kind == MediaKind.show) {
      fields.add(
        _artworkField(
          'Logo',
          t.metadataEdit.logo,
          t.metadataEdit.selectLogo,
          80,
          32,
          2,
          2.5,
          fit: MetadataArtworkFit.contain,
        ),
      );
    }
    return fields;
  }

  MetadataEditField _artworkField(
    String key,
    String label,
    String title,
    double width,
    double height,
    int columns,
    double aspectRatio, {
    MetadataArtworkFit fit = MetadataArtworkFit.cover,
  }) {
    return MetadataEditField(
      id: 'artwork:$key',
      label: label,
      type: MetadataEditFieldType.artwork,
      saveMode: MetadataEditSaveMode.immediate,
      artwork: MetadataArtworkConfig(
        key: key,
        selectTitle: title,
        previewWidth: width,
        previewHeight: height,
        gridColumns: columns,
        gridAspectRatio: aspectRatio,
        fit: fit,
      ),
    );
  }

  void _setChangedString(Map<String, dynamic> dto, MetadataEditDraft draft, String fieldId, String dtoKey) {
    if (!draft.fieldChanged(fieldId)) return;
    dto[dtoKey] = metadataEmptyToNull(draft.value<String>(fieldId));
  }

  bool _fieldChanged(MetadataEditDraft draft, String fieldId) {
    for (final section in schemaFor(draft)) {
      for (final field in section.fields) {
        if (field.id == fieldId) return metadataEditFieldChanged(draft, field);
      }
    }
    return draft.fieldChanged(fieldId);
  }
}

List<String> _stringList(Object? value) => metadataStringList(value);

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return <String, String>{};
  return value.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

List<String> _nameList(Object? value) {
  return _mapList(value)
      .map((item) => item['Name'] as String?)
      .whereType<String>()
      .where((name) => name.trim().isNotEmpty)
      .map((name) => name.trim())
      .toList();
}

List<String> _peopleByType(Object? value, String type) {
  return _mapList(value)
      .where((person) => (person['Type'] as String?)?.toLowerCase() == type.toLowerCase())
      .map((person) => person['Name'] as String?)
      .whereType<String>()
      .where((name) => name.trim().isNotEmpty)
      .map((name) => name.trim())
      .toList();
}

List<Map<String, dynamic>> _replacePeopleByType(List<Map<String, dynamic>> people, String type, List<String> names) {
  final lowerType = type.toLowerCase();
  final existing = people.where((person) => (person['Type'] as String?)?.toLowerCase() == lowerType).toList();
  final used = <int>{};
  return [
    ...people.where((person) => (person['Type'] as String?)?.toLowerCase() != lowerType),
    ...names.map((name) => _preserveNamedMap(existing, used, name, type: type)),
  ];
}

List<Map<String, dynamic>> _replaceNamePairs(List<Map<String, dynamic>> existing, List<String> names) {
  final used = <int>{};
  return names.map((name) => _preserveNamedMap(existing, used, name)).toList();
}

Map<String, dynamic> _preserveNamedMap(
  List<Map<String, dynamic>> existing,
  Set<int> used,
  String name, {
  String? type,
}) {
  final trimmed = name.trim();
  final lowerName = trimmed.toLowerCase();
  for (var i = 0; i < existing.length; i++) {
    if (used.contains(i)) continue;
    final existingName = (existing[i]['Name'] as String?)?.trim().toLowerCase();
    if (existingName == lowerName) {
      used.add(i);
      final preserved = {...existing[i], 'Name': trimmed};
      if (type != null) preserved['Type'] = type;
      return preserved;
    }
  }
  final created = <String, dynamic>{'Name': trimmed};
  if (type != null) created['Type'] = type;
  return created;
}

String? _jellyfinDate(String value, Object? originalIso) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final original = originalIso as String?;
  if (original != null && original.startsWith(trimmed)) {
    final tIndex = original.indexOf('T');
    if (tIndex >= 0) return '$trimmed${original.substring(tIndex)}';
  }
  return trimmed;
}

String _imageContentType(List<int> bytes, String? fileName) {
  if (bytes.length >= 8 &&
      bytes.first == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 3 && bytes.first == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 6) {
    final header = String.fromCharCodes(bytes.take(6));
    if (header == 'GIF87a' || header == 'GIF89a') return 'image/gif';
  }
  if (bytes.length >= 12) {
    final riff = String.fromCharCodes(bytes.take(4));
    final webp = String.fromCharCodes(bytes.skip(8).take(4));
    if (riff == 'RIFF' && webp == 'WEBP') return 'image/webp';
  }
  if (bytes.length >= 2 && bytes.first == 0x42 && bytes[1] == 0x4d) return 'image/bmp';

  final lowerName = fileName?.toLowerCase() ?? '';
  if (lowerName.endsWith('.png')) return 'image/png';
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) return 'image/jpeg';
  if (lowerName.endsWith('.gif')) return 'image/gif';
  if (lowerName.endsWith('.webp')) return 'image/webp';
  if (lowerName.endsWith('.bmp')) return 'image/bmp';
  return 'image/jpeg';
}
