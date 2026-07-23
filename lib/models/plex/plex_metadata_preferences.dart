import '../../utils/json_utils.dart';

/// Preference rows embedded in a Plex metadata response when
/// `includePreferences=1` is requested.
class PlexMetadataPreferences {
  final Map<String, String> values;

  const PlexMetadataPreferences._(this.values);

  static const empty = PlexMetadataPreferences._(<String, String>{});

  factory PlexMetadataPreferences.fromMediaContainer(Map<String, dynamic>? container) {
    final metadata = firstFlexibleMap(container?['Metadata']);
    if (metadata == null) return empty;

    final preferences = firstFlexibleMap(metadata['Preferences']);
    final settings = flexibleList(preferences?['Setting']) ?? flexibleList(metadata['Setting']) ?? const <dynamic>[];
    final values = <String, String>{};
    for (final setting in settings) {
      if (setting is! Map<String, dynamic>) continue;

      final rawId = setting['id'];
      final id = rawId is String ? rawId.trim() : null;
      final value = _preferenceValue(setting['value']);
      if (id == null || id.isEmpty || value == null) continue;

      values[id] = value;
    }

    return values.isEmpty ? empty : PlexMetadataPreferences._(Map.unmodifiable(values));
  }
}

String? _preferenceValue(Object? value) => switch (value) {
  final String value => value,
  final num value => value.toString(),
  final bool value => value ? '1' : '0',
  _ => null,
};
