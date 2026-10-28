import '../sources/source_database.dart';
import '../sources/source_models.dart';
import 'discovery_choice.dart';

/// Local, profile-scoped taste controls for Find your next.
///
/// These controls only change discovery ranking. A skip never writes a
/// preference, and hidden/genre preferences are not part of Saved-pick sync.
class DiscoveryTastePreferences {
  const DiscoveryTastePreferences({
    this.preferredGenres = const {},
    this.avoidedGenres = const {},
    this.hidden = const [],
  });

  final Set<String> preferredGenres;
  final Set<String> avoidedGenres;
  final List<DiscoveryHiddenPick> hidden;

  bool hides(String id) => hidden.any((pick) => pick.id == id);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'preferredGenres': preferredGenres.take(96).toList(growable: false),
    'avoidedGenres': avoidedGenres.take(96).toList(growable: false),
    'hidden': hidden.take(100).map((pick) => pick.toJson()).toList(growable: false),
  };

  factory DiscoveryTastePreferences.fromJson(Map<String, dynamic> value) {
    if (value['version'] != 1) return const DiscoveryTastePreferences();
    final preferred = _genres(value['preferredGenres']);
    final avoided = _genres(value['avoidedGenres'])..removeAll(preferred);
    final hidden = <DiscoveryHiddenPick>[];
    for (final raw in sourceList(value['hidden']).take(100)) {
      try {
        final pick = DiscoveryHiddenPick.fromJson(sourceMap(raw));
        if (!hidden.any((item) => item.id == pick.id)) hidden.add(pick);
      } on FormatException {
        // One malformed hidden record does not discard the remaining controls.
      }
    }
    return DiscoveryTastePreferences(
      preferredGenres: Set.unmodifiable(preferred),
      avoidedGenres: Set.unmodifiable(avoided),
      hidden: List.unmodifiable(hidden),
    );
  }

  static Set<String> _genres(Object? value) => sourceList(value)
      .whereType<String>()
      .map((item) => item.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((item) => item.isNotEmpty && item.length <= 80)
      .take(96)
      .toSet();
}

class DiscoveryHiddenPick {
  const DiscoveryHiddenPick({required this.id, required this.title, required this.type});

  final String id;
  final String title;
  final String type;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'type': type};

  factory DiscoveryHiddenPick.fromJson(Map<String, dynamic> value) {
    final id = value['id'];
    final title = value['title'];
    final type = value['type'];
    if (id is! String || id.isEmpty || id.length > 512 || title is! String || title.trim().isEmpty || type is! String) {
      throw const FormatException('Invalid hidden discovery pick');
    }
    final normalizedTitle = title.trim();
    return DiscoveryHiddenPick(
      id: id,
      title: normalizedTitle.substring(0, normalizedTitle.length > 160 ? 160 : normalizedTitle.length),
      type: type.substring(0, type.length > 40 ? 40 : type.length),
    );
  }
}

class DiscoveryTasteStore {
  const DiscoveryTasteStore(this._repository);

  static const preferenceKey = 'discovery.taste.v1';
  final SourceRepository _repository;

  Future<DiscoveryTastePreferences> load(String profileId) async =>
      DiscoveryTastePreferences.fromJson(await _repository.preference(profileId, preferenceKey));

  Future<DiscoveryTastePreferences> saveGenres(
    String profileId, {
    required Set<String> preferred,
    required Set<String> avoided,
  }) => _update(profileId, (current) {
    final parsed = DiscoveryTastePreferences.fromJson(current);
    return DiscoveryTastePreferences(
      preferredGenres: Set.unmodifiable(preferred),
      avoidedGenres: Set.unmodifiable(avoided.difference(preferred)),
      hidden: parsed.hidden,
    ).toJson();
  });

  Future<DiscoveryTastePreferences> save({
    required String profileId,
    required Set<String> preferred,
    required Set<String> avoided,
    required Set<String> hiddenIds,
  }) => _update(profileId, (current) {
    final parsed = DiscoveryTastePreferences.fromJson(current);
    return DiscoveryTastePreferences(
      preferredGenres: Set.unmodifiable(preferred),
      avoidedGenres: Set.unmodifiable(avoided.difference(preferred)),
      hidden: parsed.hidden.where((pick) => hiddenIds.contains(pick.id)).toList(growable: false),
    ).toJson();
  });

  Future<DiscoveryTastePreferences> hide(String profileId, DiscoveryChoice choice) => _update(profileId, (current) {
    final parsed = DiscoveryTastePreferences.fromJson(current);
    if (parsed.hides(choice.id)) return parsed.toJson();
    final hidden = [...parsed.hidden, DiscoveryHiddenPick(id: choice.id, title: choice.title, type: choice.type.name)];
    return DiscoveryTastePreferences(
      preferredGenres: parsed.preferredGenres,
      avoidedGenres: parsed.avoidedGenres,
      hidden: List.unmodifiable(hidden.length > 100 ? hidden.skip(hidden.length - 100) : hidden),
    ).toJson();
  });

  Future<DiscoveryTastePreferences> unhide(String profileId, String id) => _update(profileId, (current) {
    final parsed = DiscoveryTastePreferences.fromJson(current);
    return DiscoveryTastePreferences(
      preferredGenres: parsed.preferredGenres,
      avoidedGenres: parsed.avoidedGenres,
      hidden: parsed.hidden.where((pick) => pick.id != id).toList(growable: false),
    ).toJson();
  });

  Future<DiscoveryTastePreferences> clearHidden(String profileId) => _update(profileId, (current) {
    final parsed = DiscoveryTastePreferences.fromJson(current);
    return DiscoveryTastePreferences(
      preferredGenres: parsed.preferredGenres,
      avoidedGenres: parsed.avoidedGenres,
      hidden: const [],
    ).toJson();
  });

  Future<DiscoveryTastePreferences> resetTaste(String profileId) => _update(profileId, (current) {
    return const DiscoveryTastePreferences().toJson();
  });

  Future<DiscoveryTastePreferences> _update(
    String profileId,
    Map<String, dynamic> Function(Map<String, dynamic>) update,
  ) async => DiscoveryTastePreferences.fromJson(
    await _repository.updatePreferenceAtomically(profileId, preferenceKey, update),
  );
}
