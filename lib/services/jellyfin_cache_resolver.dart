import 'package:drift/drift.dart';

import '../database/app_database.dart';

typedef JellyfinItemCacheKey = ({String scopeId, String machineId, String userId, String itemId});
typedef JellyfinCacheItem = ({ApiCacheData cacheRow, JellyfinItemCacheKey key});
typedef ResolvedJellyfinCacheItem = ({ApiCacheData cacheRow, ConnectionRow connection, JellyfinItemCacheKey key});

/// Canonical Jellyfin connection and item-cache key resolution.
class JellyfinCacheResolver {
  JellyfinCacheResolver(this.database);

  final AppDatabase database;

  static const _likeEscape = r'\';
  static const _usersMarker = ':/Users/';
  static const _itemsMarker = '/Items/';

  Expression<bool> itemKeyPredicate(GeneratedColumn<String> column, String serverOrScopeId, String itemId) {
    final scope = _splitScope(serverOrScopeId);
    final escapedItemId = _escapeLike(itemId);
    final scopedUser = scope.userId == null ? '%' : _escapeLike(scope.userId!);
    final scopedPattern = '${_escapeLike(serverOrScopeId)}:/Users/$scopedUser/Items/$escapedItemId';
    var predicate = column.like(scopedPattern, escapeChar: _likeEscape);

    if (scope.userId == null) {
      final compoundPattern = '${_escapeLike(scope.machineId)}/%:/Users/%/Items/$escapedItemId';
      predicate = predicate | column.like(compoundPattern, escapeChar: _likeEscape);
    } else {
      final legacyPattern = '${_escapeLike(scope.machineId)}:/Users/${_escapeLike(scope.userId!)}/Items/$escapedItemId';
      predicate = predicate | column.like(legacyPattern, escapeChar: _likeEscape);
    }
    return predicate;
  }

  Future<JellyfinCacheItem?> findItem(String serverOrScopeId, String itemId) async {
    final matches = await _findItems(serverOrScopeId, itemId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<ResolvedJellyfinCacheItem?> findResolvedItem(String serverOrScopeId, String itemId) async {
    final matches = await _findItems(serverOrScopeId, itemId);
    for (final match in matches) {
      final connection = await findConnection(match.key.scopeId, userId: match.key.userId);
      if (connection != null) return (cacheRow: match.cacheRow, connection: connection, key: match.key);
    }
    return null;
  }

  Future<List<JellyfinCacheItem>> _findItems(String serverOrScopeId, String itemId) async {
    final rows =
        await (database.select(database.apiCache)
              ..where((t) => itemKeyPredicate(t.cacheKey, serverOrScopeId, itemId))
              ..orderBy([(t) => OrderingTerm.asc(t.cacheKey)]))
            .get();
    final requested = _splitScope(serverOrScopeId);
    final matches = <JellyfinCacheItem>[];
    for (final row in rows) {
      final key = parseItemKey(row.cacheKey);
      if (key == null || key.itemId != itemId) continue;
      if (key.machineId != requested.machineId) continue;
      if (requested.userId != null && key.userId != requested.userId) continue;
      matches.add((cacheRow: row, key: key));
    }
    if (requested.userId != null) {
      matches.sort((a, b) => a.key.scopeId == serverOrScopeId ? -1 : (b.key.scopeId == serverOrScopeId ? 1 : 0));
    }
    return matches;
  }

  Future<List<ResolvedJellyfinCacheItem>> findPinnedItems() async {
    final rows =
        await (database.select(database.apiCache)
              ..where((t) => t.pinned.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.cacheKey)]))
            .get();
    if (rows.isEmpty) return const [];

    final connections = await (database.select(database.connections)..where((t) => t.kind.equals('jellyfin'))).get();
    final connectionById = {for (final connection in connections) connection.id: connection};
    final bindings = await database.select(database.profileConnections).get();
    final bindingsByConnection = <String, List<ProfileConnectionRow>>{};
    for (final binding in bindings) {
      bindingsByConnection.putIfAbsent(binding.connectionId, () => []).add(binding);
    }

    bool matchesBinding(String connectionId, String userId) {
      final connectionBindings = bindingsByConnection[connectionId];
      return connectionBindings == null ||
          connectionBindings.isEmpty ||
          connectionBindings.any((binding) => binding.userIdentifier == userId);
    }

    final matches = <ResolvedJellyfinCacheItem>[];
    for (final row in rows) {
      final key = parseItemKey(row.cacheKey);
      if (key == null) continue;
      final compoundId = '${key.machineId}/${key.userId}';
      final compound = connectionById[compoundId];
      if (compound != null && matchesBinding(compound.id, key.userId)) {
        matches.add((cacheRow: row, connection: compound, key: key));
        continue;
      }
      final legacy = connectionById[key.machineId];
      if (legacy != null && matchesBinding(legacy.id, key.userId)) {
        matches.add((cacheRow: row, connection: legacy, key: key));
      }
    }
    return matches;
  }

  Future<ConnectionRow?> findConnection(String serverOrScopeId, {String? userId}) async {
    final scope = _splitScope(serverOrScopeId);
    if (scope.userId != null && userId != null && scope.userId != userId) return null;
    final expectedUserId = userId ?? scope.userId;

    if (expectedUserId != null) {
      final compoundId = '${scope.machineId}/$expectedUserId';
      final compound = await (database.select(
        database.connections,
      )..where((t) => t.id.equals(compoundId) & t.kind.equals('jellyfin'))).getSingleOrNull();
      if (compound != null && await _matchesProfileBinding(compound.id, expectedUserId)) return compound;

      final legacy = await (database.select(
        database.connections,
      )..where((t) => t.id.equals(scope.machineId) & t.kind.equals('jellyfin'))).getSingleOrNull();
      if (legacy != null && await _matchesProfileBinding(legacy.id, expectedUserId)) return legacy;
      return null;
    }

    final exact = await (database.select(
      database.connections,
    )..where((t) => t.id.equals(scope.machineId))).getSingleOrNull();
    if (exact != null) return exact;

    final prefix = '${scope.machineId}/';
    return (database.select(database.connections)
          ..where((t) => t.id.substr(1, prefix.length).equals(prefix) & t.kind.equals('jellyfin'))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> _matchesProfileBinding(String connectionId, String userId) async {
    final bindings = await (database.select(
      database.profileConnections,
    )..where((t) => t.connectionId.equals(connectionId))).get();
    return bindings.isEmpty || bindings.any((binding) => binding.userIdentifier == userId);
  }

  static JellyfinItemCacheKey? parseItemKey(String cacheKey) {
    final usersMarker = cacheKey.indexOf(_usersMarker);
    if (usersMarker <= 0) return null;
    final scopeId = cacheKey.substring(0, usersMarker);
    final userStart = usersMarker + _usersMarker.length;
    final itemsMarker = cacheKey.indexOf(_itemsMarker, userStart);
    if (itemsMarker <= userStart) return null;
    final userId = cacheKey.substring(userStart, itemsMarker);
    final itemId = cacheKey.substring(itemsMarker + _itemsMarker.length);
    if (itemId.isEmpty || itemId.contains('/') || itemId.contains('?')) return null;

    final scope = _splitScope(scopeId);
    if (scope.userId != null && scope.userId != userId) return null;
    return (scopeId: scopeId, machineId: scope.machineId, userId: userId, itemId: itemId);
  }

  static ({String machineId, String? userId}) _splitScope(String scopeId) {
    final slash = scopeId.indexOf('/');
    if (slash <= 0 || slash == scopeId.length - 1) return (machineId: scopeId, userId: null);
    return (machineId: scopeId.substring(0, slash), userId: scopeId.substring(slash + 1));
  }

  static String _escapeLike(String value) {
    return value.replaceAll(_likeEscape, '$_likeEscape$_likeEscape').replaceAll('%', r'\%').replaceAll('_', r'\_');
  }
}
