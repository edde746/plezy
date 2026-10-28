import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../profiles/profile.dart';
import '../services/base_shared_preferences_service.dart';
import '../utils/serial_future_queue.dart';
import 'integration_contracts.dart';

/// Explicit, reversible identity mapping between provider records. Suggestions
/// are never persisted as joins and no progress or entitlement data is merged.
class IdentityCrosswalk {
  const IdentityCrosswalk({
    required this.id,
    required this.from,
    required this.to,
    required this.relation,
    required this.method,
    required this.confirmedAt,
  });

  final String id;
  final IntegrationEntityRef from;
  final IntegrationEntityRef to;
  final EntityRelationKind relation;
  final IdentifierMatchMethod method;
  final DateTime confirmedAt;

  bool get isValid =>
      id.trim().isNotEmpty &&
      id.length <= 128 &&
      !id.contains(RegExp(r'[\x00-\x1f\x7f]')) &&
      from.isValid &&
      to.isValid &&
      !(from.providerId == to.providerId &&
          from.nativeId == to.nativeId &&
          from.kind == to.kind &&
          from.editionId == to.editionId) &&
      method != IdentifierMatchMethod.suggested;

  Map<String, Object?> toJson() => {
    'id': id,
    'from': _entityJson(from),
    'to': _entityJson(to),
    'relation': relation.name,
    'method': method.name,
    'confirmedAt': confirmedAt.millisecondsSinceEpoch,
  };

  static IdentityCrosswalk? fromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final from = _entityFromJson(json['from']);
    final to = _entityFromJson(json['to']);
    final relationName = json['relation'];
    final methodName = json['method'];
    if (from == null || to == null || relationName is! String || methodName is! String || json['confirmedAt'] is! int) {
      return null;
    }
    final relation = EntityRelationKind.values.where((value) => value.name == relationName).firstOrNull;
    final method = IdentifierMatchMethod.values.where((value) => value.name == methodName).firstOrNull;
    if (relation == null || method == null) return null;
    final crosswalk = IdentityCrosswalk(
      id: '${json['id'] ?? ''}',
      from: from,
      to: to,
      relation: relation,
      method: method,
      confirmedAt: DateTime.fromMillisecondsSinceEpoch(json['confirmedAt'] as int),
    );
    return crosswalk.isValid ? crosswalk : null;
  }
}

/// Profile-scoped store for user-confirmed provider identity crosswalks.
/// The JSON envelope is versioned and malformed rows are ignored rather than
/// being turned into automatic matches.
class IntegrationIdentityStore {
  IntegrationIdentityStore({this.cacheLoader = BaseSharedPreferencesService.sharedCache});

  static const _baseKey = 'integration_identity_crosswalks_v1';
  static const _maxCrosswalks = 5000;
  static final _persistence = SerialFutureQueue();

  final Future<SharedPreferencesWithCache> Function() cacheLoader;

  String keyForProfile(String profileId) => profileScopedPrefsKey(profileId, _baseKey);

  Future<List<IdentityCrosswalk>> load(String profileId) => _persistence.run(() async {
    final prefs = await cacheLoader();
    final raw = prefs.getString(keyForProfile(profileId));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != 1 || decoded['crosswalks'] is! List) return const [];
      return (decoded['crosswalks'] as List)
          .take(_maxCrosswalks)
          .map(IdentityCrosswalk.fromJson)
          .whereType<IdentityCrosswalk>()
          .toList(growable: false);
    } on Object {
      return const [];
    }
  });

  Future<void> put(String profileId, IdentityCrosswalk crosswalk) => _persistence.run(() async {
    if (!crosswalk.isValid) throw ArgumentError.value(crosswalk, 'crosswalk');
    final prefs = await cacheLoader();
    final current = await _loadFromPrefs(prefs, profileId);
    final updated = [
      for (final row in current)
        if (row.id != crosswalk.id) row,
      crosswalk,
    ];
    final conflicting = updated.where(
      (row) =>
          row.id != crosswalk.id &&
          row.relation == crosswalk.relation &&
          _sameEntity(row.from, crosswalk.from) &&
          !_sameEntity(row.to, crosswalk.to),
    );
    if (conflicting.isNotEmpty) {
      throw StateError('This provider item already has a different confirmed match. Remove it before remapping.');
    }
    if (updated.length > _maxCrosswalks) throw StateError('Integration identity limit reached.');
    await _save(prefs, profileId, updated);
  });

  Future<void> remove(String profileId, String crosswalkId) => _persistence.run(() async {
    final prefs = await cacheLoader();
    final current = await _loadFromPrefs(prefs, profileId);
    await _save(prefs, profileId, current.where((row) => row.id != crosswalkId).toList(growable: false));
  });

  Future<void> clearForProfile(String profileId) => _persistence.run(() async {
    final prefs = await cacheLoader();
    await prefs.remove(keyForProfile(profileId));
  });

  Future<List<IdentityCrosswalk>> _loadFromPrefs(SharedPreferencesWithCache prefs, String profileId) async {
    final raw = prefs.getString(keyForProfile(profileId));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != 1 || decoded['crosswalks'] is! List) return const [];
      return (decoded['crosswalks'] as List)
          .take(_maxCrosswalks)
          .map(IdentityCrosswalk.fromJson)
          .whereType<IdentityCrosswalk>()
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  Future<void> _save(SharedPreferencesWithCache prefs, String profileId, List<IdentityCrosswalk> crosswalks) async {
    await prefs.setString(
      keyForProfile(profileId),
      jsonEncode({'version': 1, 'crosswalks': crosswalks.map((row) => row.toJson()).toList(growable: false)}),
    );
  }
}

Map<String, Object?> _entityJson(IntegrationEntityRef entity) => {
  'providerId': entity.providerId,
  'nativeId': entity.nativeId,
  'kind': entity.kind.name,
  'editionId': entity.editionId,
};

IntegrationEntityRef? _entityFromJson(Object? value) {
  if (value is! Map) return null;
  final json = Map<String, dynamic>.from(value);
  final providerId = json['providerId'], nativeId = json['nativeId'], kindName = json['kind'];
  if (providerId is! String || nativeId is! String || kindName is! String) return null;
  final kind = IntegrationEntityKind.values.where((value) => value.name == kindName).firstOrNull;
  if (kind == null) return null;
  final editionId = json['editionId'];
  if (editionId != null && editionId is! String) return null;
  final entity = IntegrationEntityRef(
    providerId: providerId,
    nativeId: nativeId,
    kind: kind,
    editionId: editionId as String?,
  );
  return entity.isValid ? entity : null;
}

bool _sameEntity(IntegrationEntityRef a, IntegrationEntityRef b) =>
    a.providerId == b.providerId && a.nativeId == b.nativeId && a.kind == b.kind && a.editionId == b.editionId;
