import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../sources/source_database.dart';
import '../sources/source_models.dart';
import 'canonical_video_identity.dart';
import 'media_item.dart';
import 'media_kind.dart';

const canonicalLibrarySchema = [
  'CREATE TABLE canonical_cards (profile TEXT NOT NULL, id TEXT NOT NULL, created INTEGER NOT NULL, PRIMARY KEY(profile,id))',
  'CREATE TABLE canonical_aliases (profile TEXT NOT NULL, alias TEXT NOT NULL, card TEXT NOT NULL, PRIMARY KEY(profile,alias))',
  'CREATE INDEX canonical_alias_card ON canonical_aliases(profile,card)',
  'CREATE TABLE canonical_copies (profile TEXT NOT NULL, copy_key TEXT NOT NULL, card TEXT NOT NULL, source TEXT NOT NULL, item TEXT NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL, updated INTEGER NOT NULL, PRIMARY KEY(profile,copy_key))',
  'CREATE INDEX canonical_copy_card ON canonical_copies(profile,card)',
  'CREATE INDEX canonical_copy_source ON canonical_copies(profile,source)',
  'CREATE TABLE canonical_redirects (profile TEXT NOT NULL, previous TEXT NOT NULL, card TEXT NOT NULL, PRIMARY KEY(profile,previous))',
];

class CanonicalLibraryCopy {
  const CanonicalLibraryCopy({
    required this.key,
    required this.source,
    required this.item,
    this.serverItem,
    this.entry,
  });
  final String key, source, item;
  final MediaItem? serverItem;
  final SourceEntry? entry;
}

class CanonicalLibraryCard {
  const CanonicalLibraryCard(this.id, this.copies, {required this.profile});
  final String id;
  final String profile;
  final List<CanonicalLibraryCopy> copies;
  MediaItem? get serverItem => copies.map((copy) => copy.serverItem).whereType<MediaItem>().firstOrNull;
  SourceEntry? get entry => copies.map((copy) => copy.entry).whereType<SourceEntry>().firstOrNull;
}

/// Profile-local identities, independent of any particular provider. Exact
/// aliases may bridge cards discovered in either order. A contradictory ID
/// from the same namespace is quarantined as a separate card, never guessed.
class CanonicalLibrary {
  CanonicalLibrary(this.database);
  final SourceDatabase database;
  static String serverKey(MediaItem item) => 'server:${sourceKey(item.serverId ?? '', item.id)}';
  static String entryKey(SourceEntry entry) => 'source:${entry.key}';

  Future<String> recordSource(String profile, SourceEntry entry) => _record(
    profile,
    entryKey(entry),
    entry.sourceId,
    entry.id,
    'source',
    '{}',
    canonicalVideoIdentitiesForSourceEntry(entry),
  );

  Future<void> recordServerItems(
    String profile,
    Iterable<MediaItem> items, {
    Map<String, Set<String>> identities = const {},
  }) async {
    for (final item in items) {
      final aliases = identities[item.globalKey] ?? canonicalVideoIdentitiesForMediaItem(item);
      if (item.serverId == null || !const {MediaKind.movie, MediaKind.show, MediaKind.episode}.contains(item.kind)) {
        continue;
      }
      final json = item.toJson();
      // Presentation and stable locators only. Part URLs, bearer headers and
      // provider raw payloads must be reacquired from the selected server.
      const keys = {
        'backend',
        'dialect',
        'id',
        'kind',
        'title',
        'year',
        'parentId',
        'parentTitle',
        'grandparentId',
        'grandparentTitle',
        'parentIndex',
        'index',
        'serverId',
        'serverName',
        'libraryId',
        'libraryTitle',
        'durationMs',
        'thumbPath',
        'artPath',
        'viewOffsetMs',
        'viewCount',
      };
      final safe = {
        for (final e in json.entries)
          if (keys.contains(e.key)) e.key: e.value,
      };
      for (final key in ['thumbPath', 'artPath']) {
        final value = safe[key];
        final uri = value is String ? Uri.tryParse(value) : null;
        if (uri != null && (uri.hasQuery || uri.userInfo.isNotEmpty)) safe.remove(key);
      }
      await _record(profile, serverKey(item), item.serverId!, item.id, 'server', jsonEncode(safe), aliases);
    }
  }

  Future<String> _record(
    String profile,
    String key,
    String source,
    String item,
    String kind,
    String payload,
    Set<String> aliases,
  ) => database.transaction(() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Acquire the write lock before reading the graph. Separate background
    // and foreground connections cannot both create a different winner.
    await database.customStatement('UPDATE canonical_cards SET created=created WHERE profile=?', [profile]);
    final removed = await database
        .customSelect('SELECT 1 FROM remote_deleted_profiles WHERE profile=?', variables: [Variable(profile)])
        .getSingleOrNull();
    if (removed != null) throw StateError('Profile was removed');
    final previous = await database
        .customSelect(
          'SELECT card FROM canonical_copies WHERE profile=? AND copy_key=?',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    final candidates = <String>{};
    for (final alias in aliases) {
      final row = await database
          .customSelect(
            'SELECT card FROM canonical_aliases WHERE profile=? AND alias=?',
            variables: [Variable(profile), Variable(alias)],
          )
          .getSingleOrNull();
      if (row != null) candidates.add(row.read<String>('card'));
    }
    if (previous != null) candidates.add(previous.read<String>('card'));
    final allAliases = <String>{...aliases};
    for (final candidate in candidates) {
      final rows = await database
          .customSelect(
            'SELECT alias FROM canonical_aliases WHERE profile=? AND card=?',
            variables: [Variable(profile), Variable(candidate)],
          )
          .get();
      allAliases.addAll(rows.map((r) => r.read<String>('alias')));
    }
    final namespaces = <String, String>{};
    var conflict = false;
    for (final alias in allAliases) {
      final namespace = alias.substring(0, alias.indexOf(':'));
      if (namespaces.containsKey(namespace) && namespaces[namespace] != alias) conflict = true;
      namespaces[namespace] = alias;
    }
    String winner;
    if (conflict) {
      // Detach a corrected/conflicting copy from the old work. Its conflicting
      // aliases are deliberately not allowed to steal the existing mapping.
      final previousId = previous?.read<String>('card');
      final aliasesOfPrevious = previousId == null
          ? null
          : await database
                .customSelect(
                  'SELECT 1 FROM canonical_aliases WHERE profile=? AND card=? LIMIT 1',
                  variables: [Variable(profile), Variable(previousId)],
                )
                .getSingleOrNull();
      winner = previousId != null && aliasesOfPrevious == null ? previousId : const Uuid().v4();
    } else if (candidates.isNotEmpty) {
      final ordered = await database
          .customSelect(
            'SELECT id FROM canonical_cards WHERE profile=? '
            'AND id IN (${List.filled(candidates.length, '?').join(',')}) ORDER BY created,id LIMIT 1',
            variables: [Variable(profile), ...candidates.map(Variable.new)],
          )
          .get();
      winner = ordered.single.read<String>('id');
    } else {
      winner = const Uuid().v4();
    }
    await database.customStatement('INSERT OR IGNORE INTO canonical_cards VALUES (?,?,?)', [profile, winner, now]);
    if (!conflict) {
      for (final loser in candidates.where((id) => id != winner)) {
        await database.customStatement('UPDATE canonical_copies SET card=? WHERE profile=? AND card=?', [
          winner,
          profile,
          loser,
        ]);
        await database.customStatement('UPDATE canonical_aliases SET card=? WHERE profile=? AND card=?', [
          winner,
          profile,
          loser,
        ]);
        await database.customStatement('UPDATE canonical_redirects SET card=? WHERE profile=? AND card=?', [
          winner,
          profile,
          loser,
        ]);
        await database.customStatement('INSERT OR REPLACE INTO canonical_redirects VALUES (?,?,?)', [
          profile,
          loser,
          winner,
        ]);
        await database.customStatement('DELETE FROM canonical_cards WHERE profile=? AND id=?', [profile, loser]);
      }
      for (final alias in aliases) {
        await database.customStatement('INSERT OR IGNORE INTO canonical_aliases VALUES (?,?,?)', [
          profile,
          alias,
          winner,
        ]);
      }
    }
    await database.customStatement(
      'INSERT INTO canonical_copies VALUES (?,?,?,?,?,?,?,?) '
      'ON CONFLICT(profile,copy_key) DO UPDATE SET card=excluded.card,payload=excluded.payload,updated=excluded.updated',
      [profile, key, winner, source, item, kind, payload, now],
    );
    return winner;
  });

  Future<CanonicalLibraryCard?> cardForCopy(String profile, String key) async {
    final row = await database
        .customSelect(
          'SELECT card FROM canonical_copies WHERE profile=? AND copy_key=?',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    return row == null ? null : _card(profile, row.read<String>('card'));
  }

  Future<List<CanonicalLibraryCard>> cards(String profile, {int limit = 120, int offset = 0}) async {
    final rows = await database
        .customSelect(
          'SELECT card FROM canonical_copies WHERE profile=? GROUP BY card '
          'ORDER BY MAX(updated) DESC,card LIMIT ? OFFSET ?',
          variables: [Variable(profile), Variable(limit), Variable(offset)],
        )
        .get();
    return Future.wait(rows.map((row) => _card(profile, row.read<String>('card'))));
  }

  Future<CanonicalLibraryCard> card(String profile, String id) => _card(profile, id);
  Future<CanonicalLibraryCard> _card(String profile, String id) async {
    final redirect = await database
        .customSelect(
          'SELECT card FROM canonical_redirects WHERE profile=? AND previous=?',
          variables: [Variable(profile), Variable(id)],
        )
        .getSingleOrNull();
    id = redirect?.read<String>('card') ?? id;
    final rows = await database
        .customSelect(
          'SELECT c.*,e.payload AS entry_payload FROM canonical_copies c '
          "LEFT JOIN entries e ON c.kind='source' AND e.profile=c.profile AND e.source=c.source AND e.id=c.item "
          'WHERE c.profile=? AND c.card=? ORDER BY c.kind,c.source,c.item',
          variables: [Variable(profile), Variable(id)],
        )
        .get();
    final copies = <CanonicalLibraryCopy>[];
    for (final row in rows) {
      final kind = row.read<String>('kind');
      final entryPayload = row.readNullable<String>('entry_payload');
      final entry = entryPayload == null ? null : SourceEntry.fromJson(sourceMap(jsonDecode(entryPayload)));
      if (kind == 'source' && (entry == null || entry.unavailable)) continue;
      copies.add(
        CanonicalLibraryCopy(
          key: row.read<String>('copy_key'),
          source: row.read<String>('source'),
          item: row.read<String>('item'),
          entry: entry,
          serverItem: kind == 'server'
              ? MediaItem.fromJson(Map<String, dynamic>.from(jsonDecode(row.read<String>('payload')) as Map))
              : null,
        ),
      );
    }
    return CanonicalLibraryCard(id, copies, profile: profile);
  }

  Future<Set<String>> aliases(String profile, String card) async =>
      (await database
              .customSelect(
                'SELECT alias FROM canonical_aliases WHERE profile=? AND card=?',
                variables: [Variable(profile), Variable(card)],
              )
              .get())
          .map((row) => row.read<String>('alias'))
          .toSet();

  Future<void> removeServer(String profile, String server) => database.customStatement(
    "DELETE FROM canonical_copies WHERE profile=? AND source=? AND kind='server'",
    [profile, server],
  );
}
