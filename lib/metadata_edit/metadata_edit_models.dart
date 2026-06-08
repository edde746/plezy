import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';

enum MetadataEditFieldType { text, multilineText, date, stringList, choice, artwork }

enum MetadataEditSaveMode { draft, immediate }

enum MetadataArtworkFit { cover, contain }

class MetadataEditOption {
  final String value;
  final String label;

  const MetadataEditOption({required this.value, required this.label});
}

class MetadataArtworkConfig {
  final String key;
  final String selectTitle;
  final double previewWidth;
  final double previewHeight;
  final int gridColumns;
  final double gridAspectRatio;
  final MetadataArtworkFit fit;

  const MetadataArtworkConfig({
    required this.key,
    required this.selectTitle,
    required this.previewWidth,
    required this.previewHeight,
    required this.gridColumns,
    required this.gridAspectRatio,
    this.fit = MetadataArtworkFit.cover,
  });
}

class MetadataEditField {
  final String id;
  final String label;
  final MetadataEditFieldType type;
  final MetadataEditSaveMode saveMode;
  final List<MetadataEditOption> options;
  final MetadataArtworkConfig? artwork;

  const MetadataEditField({
    required this.id,
    required this.label,
    required this.type,
    this.saveMode = MetadataEditSaveMode.draft,
    this.options = const [],
    this.artwork,
  });
}

class MetadataEditSection {
  final String id;
  final String title;
  final List<MetadataEditField> fields;

  const MetadataEditSection({required this.id, required this.title, required this.fields});
}

class MetadataArtworkOption {
  final String id;
  final String thumbnailPath;
  final String sourceUrl;
  final bool selected;
  final String? provider;
  final int? width;
  final int? height;

  const MetadataArtworkOption({
    required this.id,
    required this.thumbnailPath,
    required this.sourceUrl,
    this.selected = false,
    this.provider,
    this.width,
    this.height,
  });
}

class MetadataEditDraft {
  final MediaItem sourceItem;
  MediaItem currentItem;
  final Map<String, Object?> values;
  final Map<String, Object?> originalValues;
  final Map<String, Object?> extras;
  List<MetadataEditSection>? cachedSchema;

  MetadataEditDraft({
    required this.sourceItem,
    required this.currentItem,
    required this.values,
    Map<String, Object?>? originalValues,
    Map<String, Object?>? extras,
  }) : originalValues = originalValues ?? Map<String, Object?>.from(values),
       extras = extras ?? <String, Object?>{};

  T? value<T>(String id) => values[id] as T?;

  void setValue(String id, Object? value) {
    values[id] = value;
  }

  bool fieldChanged(String id) => !metadataEditValueEquals(values[id], originalValues[id]);

  void acceptChanges() {
    originalValues
      ..clear()
      ..addAll(Map<String, Object?>.from(values));
  }
}

abstract class MetadataEditAdapter {
  MediaBackend get backend;
  MediaServerClient get mediaClient;

  bool supportsKind(MediaKind kind);

  Future<MetadataEditDraft> load(MediaItem item);

  List<MetadataEditSection> buildSchema(MetadataEditDraft draft);

  List<MetadataEditSection> schemaFor(MetadataEditDraft draft) => draft.cachedSchema ??= buildSchema(draft);

  bool hasChanges(MetadataEditDraft draft) {
    final draftFields = schemaFor(
      draft,
    ).expand((section) => section.fields).where((field) => field.saveMode == MetadataEditSaveMode.draft);
    return draftFields.any((field) => metadataEditFieldChanged(draft, field));
  }

  Future<bool> save(MetadataEditDraft draft);

  Future<bool> saveImmediateField(MetadataEditDraft draft, MetadataEditField field, Object? value) async {
    draft.setValue(field.id, value);
    final success = await save(draft);
    if (success) draft.acceptChanges();
    return success;
  }

  Future<List<MetadataArtworkOption>> fetchArtwork(MetadataEditDraft draft, MetadataEditField field);

  Future<bool> applyArtworkOption(MetadataEditDraft draft, MetadataEditField field, MetadataArtworkOption option);

  Future<bool> applyArtworkFromUrl(MetadataEditDraft draft, MetadataEditField field, String url);

  Future<bool> uploadArtwork(MetadataEditDraft draft, MetadataEditField field, List<int> bytes, {String? fileName});

  Future<MediaItem?> reloadItem(MetadataEditDraft draft) => mediaClient.fetchItem(draft.sourceItem.id);

  void syncReloadedItem(MetadataEditDraft draft, MediaItem item) {
    draft.currentItem = item;
  }
}

bool metadataEditValueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!metadataEditValueEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !metadataEditValueEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}

bool metadataEditFieldChanged(MetadataEditDraft draft, MetadataEditField field) {
  final current = draft.values[field.id];
  final original = draft.originalValues[field.id];
  return field.type == MetadataEditFieldType.stringList
      ? !metadataEditStringListEquals(current, original)
      : !metadataEditValueEquals(current, original);
}

bool metadataEditStringListEquals(Object? a, Object? b) {
  final left = metadataStringList(a).toSet();
  final right = metadataStringList(b).toSet();
  if (left.length != right.length) return false;
  return left.every(right.contains);
}

List<String> metadataStringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().where((v) => v.trim().isNotEmpty).map((v) => v.trim()).toList();
  }
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return <String>[];
}

String metadataFirstString(Object? value) {
  final list = metadataStringList(value);
  return list.isEmpty ? '' : list.first;
}

String? metadataEmptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
