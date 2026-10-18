import 'dart:convert';

import 'settings_service.dart';

/// Recently applied metadata tag values, stored per profile, server, and
/// editor field id (`label`, `genre`, …). Powers the suggestion chips in
/// [TagEditDialog] and the quick-tag context-menu action.
///
/// Storage is one JSON map per profile:
/// `{serverId: {fieldId: [tag, …]}}` with each list most-recent-first and
/// capped at [_maxTagsPerField]. Server keying keeps one server's tags from
/// suggesting onto another; field keying keeps genres out of tag suggestions.
class RecentTagsService {
  static const int _maxTagsPerField = 20;

  static List<String> getRecentTags({required String profileId, required String serverId, required String fieldId}) {
    final fieldMap = _load(profileId)[serverId];
    final tags = fieldMap?[fieldId];
    return tags == null ? const [] : List<String>.unmodifiable(tags);
  }

  /// Records [tags] as just-applied for [fieldId] on [serverId], newest first.
  /// Re-applied tags move to the front; matching is case-insensitive so a
  /// casing variant cannot duplicate an entry.
  static Future<void> addRecentTags(
    Iterable<String> tags, {
    required String profileId,
    required String serverId,
    required String fieldId,
  }) async {
    final cleaned = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    if (cleaned.isEmpty) return;

    final data = _load(profileId);
    final fieldMap = data.putIfAbsent(serverId, () => <String, List<String>>{});
    final list = fieldMap.putIfAbsent(fieldId, () => <String>[]);
    for (final tag in cleaned.toList().reversed) {
      list.removeWhere((existing) => existing.toLowerCase() == tag.toLowerCase());
      list.insert(0, tag);
    }
    if (list.length > _maxTagsPerField) {
      list.removeRange(_maxTagsPerField, list.length);
    }
    await _save(profileId, data);
  }

  /// Merges [recent] ahead of [serverTags], deduplicating case-insensitively
  /// and dropping entries already in [existing] (the item's current values).
  static List<String> mergeSuggestions({
    required List<String> recent,
    required List<String> serverTags,
    required List<String> existing,
  }) {
    final seen = <String>{for (final tag in existing) tag.toLowerCase()};
    final merged = <String>[];
    for (final tag in [...recent, ...serverTags]) {
      if (seen.add(tag.toLowerCase())) merged.add(tag);
    }
    return merged;
  }

  static Map<String, Map<String, List<String>>> _load(String profileId) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return {};
    final json = settings.read(SettingsService.recentMetadataTagsForProfile(profileId));
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return {};
      return {
        for (final serverEntry in decoded.entries)
          if (serverEntry.value is Map)
            serverEntry.key as String: {
              for (final fieldEntry in (serverEntry.value as Map).entries)
                if (fieldEntry.value is List)
                  fieldEntry.key as String: (fieldEntry.value as List).whereType<String>().toList(),
            },
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(String profileId, Map<String, Map<String, List<String>>> data) async {
    await SettingsService.instanceOrNull?.write(
      SettingsService.recentMetadataTagsForProfile(profileId),
      jsonEncode(data),
    );
  }
}
