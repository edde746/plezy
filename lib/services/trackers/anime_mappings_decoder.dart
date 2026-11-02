import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../models/trackers/anime_lists_mapping.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import 'anime_lists_index.dart';
import 'fribb_index.dart';

/// Both datasets of one `anime-mappings.bin.gz`, indexed for lookup.
class AnimeMappingsIndex {
  final FribbIndex fribb;
  final AnimeListsIndex animeLists;

  const AnimeMappingsIndex({required this.fribb, required this.animeLists});

  static const empty = AnimeMappingsIndex(fribb: FribbIndex.empty, animeLists: AnimeListsIndex.empty);

  bool get isEmpty => fribb.isEmpty && animeLists.isEmpty;

  String get logSummary => '${fribb.byTvdb.length} Fribb and ${animeLists.byTvdb.length} Anime-Lists tvdb ids';
}

const _magic = [0x41, 0x4D, 0x41, 0x50]; // AMAP
const _version = 1;

// Column types, one byte each in the file.
const _typeInt = 1;
const _typeIntDelta = 2;
const _typeStr = 3;
const _typeDict = 4;
const _typeIntList = 5;
const _typeStrList = 6;

/// Decode `anime-mappings.bin.gz` from https://github.com/edde746/anime-mappings
/// (gzipped, or already inflated by a transport) into its two indexes.
///
/// The file is a packed list: named tables of named, typed columns, specified
/// in that repository's README. Tables and columns are found by name, so ones
/// this reader does not use — or whose type it does not know — are skipped, as
/// the format allows later files of the same version to add them. Throws
/// [FormatException] for anything that is not a version 1 packed list.
AnimeMappingsIndex decodeAnimeMappings(Uint8List data) {
  final bytes = data.length >= 2 && data[0] == 0x1f && data[1] == 0x8b ? _inflate(data) : data;
  final tables = _readTables(bytes);
  return AnimeMappingsIndex(
    fribb: FribbIndex.fromRows(_fribbRows(tables['fribb'])),
    animeLists: AnimeListsIndex.fromEntries(
      _animeListEntries(tables['anime_lists'], _episodeMappings(tables['anime_lists_mappings'])),
    ),
  );
}

Uint8List _inflate(Uint8List data) {
  final inflated = gzip.decode(data);
  return inflated is Uint8List ? inflated : Uint8List.fromList(inflated);
}

Map<String, _Table> _readTables(Uint8List data) {
  final r = _Reader(data, 0, data.length);
  for (final byte in _magic) {
    if (r.byte() != byte) throw const FormatException('Not an anime mappings packed list');
  }
  final version = r.byte();
  if (version != _version) throw FormatException('Anime mappings format version $version, expected $_version');
  final tables = <String, _Table>{};
  for (var t = r.varint(); t > 0; t--) {
    final name = r.text();
    final table = tables[name] = _Table(data, r.varint());
    for (var c = r.varint(); c > 0; c--) {
      final column = r.text();
      final type = r.byte();
      final start = r.skip(r.varint());
      table.columns[column] = (type: type, start: start, end: r.pos);
    }
  }
  if (r.pos != data.length) throw FormatException('${data.length - r.pos} bytes after the last anime mappings table');
  return tables;
}

class _Table {
  final Uint8List data;
  final int rows;
  final Map<String, ({int type, int start, int end})> columns = {};

  _Table(this.data, this.rows);

  /// One value per row: an int, a String, a `List<int>` or a `List<String>`
  /// by the column's type, null where absent. All null when the table has no
  /// such column or stores it in a type this reader does not know.
  List<Object?> column(String name) {
    final values = List<Object?>.filled(rows, null);
    final column = columns[name];
    if (column == null || column.type < _typeInt || column.type > _typeStrList) return values;
    final r = _Reader(data, column.start, column.end);
    final words = column.type == _typeDict ? [for (var i = r.varint(); i > 0; i--) r.text()] : const <String>[];
    var previous = 0;
    for (var i = 0; i < rows; i++) {
      final tag = r.varint();
      if (tag == 0) continue;
      values[i] = switch (column.type) {
        _typeInt => _unzigzag(tag - 1),
        _typeIntDelta => previous += _unzigzag(tag - 1),
        _typeStr => r.string(tag - 1),
        _typeDict when tag <= words.length => words[tag - 1],
        _typeDict => throw FormatException('Anime mappings $name: dictionary word ${tag - 1} of ${words.length}'),
        _typeIntList => <int>[for (var k = tag - 1; k > 0; k--) r.signed()],
        _ => <String>[for (var k = tag - 1; k > 0; k--) r.text()],
      };
    }
    if (r.pos != r.end) throw FormatException('Anime mappings $name: ${r.end - r.pos} bytes left in the column');
    return values;
  }
}

class _Reader {
  final Uint8List data;
  int pos;
  final int end;

  _Reader(this.data, this.pos, this.end);

  int byte() {
    if (pos >= end) throw const FormatException('Anime mappings packed list is cut short');
    return data[pos++];
  }

  /// Unsigned LEB128; a 64-bit value can fill all of an int's bits.
  int varint() {
    var n = 0;
    for (var shift = 0; shift < 64; shift += 7) {
      final b = byte();
      n |= (b & 0x7f) << shift;
      if (b < 0x80) return n;
    }
    throw const FormatException('Anime mappings varint is longer than 64 bits');
  }

  int signed() => _unzigzag(varint());

  String text() => string(varint());

  String string(int length) => utf8.decode(Uint8List.sublistView(data, skip(length), pos));

  /// Advance past [length] bytes and return where they start.
  int skip(int length) {
    if (length > end - pos) throw const FormatException('Anime mappings packed list is cut short');
    final start = pos;
    pos += length;
    return start;
  }
}

int _unzigzag(int n) => n.isEven ? n >>> 1 : -(n >>> 1) - 1;

int? _int(Object? value) => value is int ? value : null;

String? _string(Object? value) => value is String ? value : null;

List<int>? _ints(Object? value) => value is List<int> && value.isNotEmpty ? value : null;

List<String>? _strings(Object? value) => value is List<String> && value.isNotEmpty ? value : null;

/// The `fribb` table: one row per element of Fribb's `anime-list-mini.json`,
/// a nested key such as `{"season": {"tvdb": 1}}` as the column `season.tvdb`.
List<FribbMappingRow> _fribbRows(_Table? table) {
  if (table == null) return const [];
  final type = table.column('type');
  final anidb = table.column('anidb_id');
  final mal = table.column('mal_id');
  final anilist = table.column('anilist_id');
  final simkl = table.column('simkl_id');
  final tmdbTv = table.column('themoviedb_id.tv');
  final tmdbMovies = table.column('themoviedb_id.movie');
  final imdb = table.column('imdb_id');
  final tvdb = table.column('tvdb_id');
  final tvdbSeason = table.column('season.tvdb');
  final tmdbSeason = table.column('season.tmdb');
  return [
    for (var i = 0; i < table.rows; i++)
      FribbMappingRow(
        type: _string(type[i]),
        anidbId: _int(anidb[i]),
        malId: _int(mal[i]),
        anilistId: _int(anilist[i]),
        simklId: _int(simkl[i]),
        tmdbTvId: _int(tmdbTv[i]),
        tmdbMovieIds: _ints(tmdbMovies[i]),
        imdbIds: _strings(imdb[i]),
        tvdbId: _int(tvdb[i]),
        tvdbSeason: _int(tvdbSeason[i]),
        tmdbSeason: _int(tmdbSeason[i]),
      ),
  ];
}

/// The `anime_lists` table: one row per `<anime>` of Anime-Lists'
/// `anime-list.xml`, its attributes as columns. An attribute holding either a
/// number or a word (`tvdbid="movie"`, `defaulttvdbseason="a"`) is two columns,
/// the word in `<name>_text`.
List<AnimeListEntry> _animeListEntries(_Table? table, Map<int, List<AnimeListEpisodeMapping>> mappings) {
  if (table == null) return const [];
  final anidb = table.column('anidbid');
  final name = table.column('name');
  final tvdb = table.column('tvdbid');
  final tvdbText = table.column('tvdbid_text');
  final defaultTvdbSeason = table.column('defaulttvdbseason');
  final defaultTvdbSeasonText = table.column('defaulttvdbseason_text');
  final episodeOffset = table.column('episodeoffset');
  final tmdbTv = table.column('tmdbtv');
  final tmdbSeason = table.column('tmdbseason');
  final tmdbSeasonText = table.column('tmdbseason_text');
  final tmdbOffset = table.column('tmdboffset');
  final tmdbMovies = table.column('tmdbid');
  final imdb = table.column('imdbid');
  return [
    for (var i = 0; i < table.rows; i++)
      if (_int(anidb[i]) case final anidbId?)
        AnimeListEntry(
          anidbId: anidbId,
          name: _string(name[i])?.trim(),
          rawTvdbId: _int(tvdb[i])?.toString() ?? _string(tvdbText[i]),
          tvdbId: _int(tvdb[i]),
          defaultTvdbSeason: _seasonRef(defaultTvdbSeason[i], defaultTvdbSeasonText[i]),
          episodeOffset: _int(episodeOffset[i]) ?? 0,
          tmdbTvId: _int(tmdbTv[i]),
          tmdbSeason: _seasonRef(tmdbSeason[i], tmdbSeasonText[i]),
          tmdbOffset: _int(tmdbOffset[i]) ?? 0,
          tmdbMovieIds: _ints(tmdbMovies[i]) ?? const [],
          imdbIds: [
            for (final id in _strings(imdb[i]) ?? const <String>[])
              if (id.trim().isNotEmpty) id.trim(),
          ],
          mappings: mappings[anidbId] ?? const [],
        ),
  ];
}

/// `a` is absolute numbering; any other word is not a season.
AnimeListSeasonRef? _seasonRef(Object? number, Object? word) => switch ((number, word)) {
  (final int season, _) => AnimeListSeasonRef.number(season),
  (_, 'a') => const AnimeListSeasonRef.absolute(),
  _ => null,
};

/// The `anime_lists_mappings` table: one row per `<mapping>`, keyed to its
/// `<anime>` by `anidbid`. A mapping naming both a TVDB and a TMDB season
/// yields one [AnimeListEpisodeMapping] per provider.
Map<int, List<AnimeListEpisodeMapping>> _episodeMappings(_Table? table) {
  final byAnidb = <int, List<AnimeListEpisodeMapping>>{};
  if (table == null) return byAnidb;
  final anidb = table.column('anidbid');
  final anidbSeason = table.column('anidbseason');
  final tvdbSeason = table.column('tvdbseason');
  final tmdbSeason = table.column('tmdbseason');
  final start = table.column('start');
  final end = table.column('end');
  final offset = table.column('offset');
  final text = table.column('text');
  for (var i = 0; i < table.rows; i++) {
    final anidbId = _int(anidb[i]);
    final season = _int(anidbSeason[i]);
    if (anidbId == null || season == null) continue;
    final explicit = _explicitMappings(_string(text[i]) ?? '');
    for (final (provider, externalSeason) in [
      (AnimeListProvider.tvdb, _int(tvdbSeason[i])),
      (AnimeListProvider.tmdb, _int(tmdbSeason[i])),
    ]) {
      if (externalSeason == null) continue;
      (byAnidb[anidbId] ??= []).add(
        AnimeListEpisodeMapping(
          anidbSeason: season,
          provider: provider,
          externalSeason: externalSeason,
          start: _int(start[i]),
          end: _int(end[i]),
          offset: _int(offset[i]) ?? 0,
          explicit: explicit,
        ),
      );
    }
  }
  return byAnidb;
}

/// A `<mapping>`'s text, `;anidb-external;…;`: `+` joins several external
/// episodes, and `-0` maps an AniDB episode to none.
List<AnimeListExplicitEpisodeMapping> _explicitMappings(String raw) {
  final mappings = <AnimeListExplicitEpisodeMapping>[];
  for (final segment in raw.split(';')) {
    final item = segment.trim();
    final separator = item.indexOf('-');
    if (separator <= 0 || separator == item.length - 1) continue;
    final anidbEpisode = int.tryParse(item.substring(0, separator));
    if (anidbEpisode == null) continue;
    final externalEpisodes = [
      for (final target in item.substring(separator + 1).split('+'))
        if (int.tryParse(target.trim()) case final episode? when episode != 0) episode,
    ];
    if (externalEpisodes.isEmpty) continue;
    mappings.add(AnimeListExplicitEpisodeMapping(anidbEpisode: anidbEpisode, externalEpisodes: externalEpisodes));
  }
  return mappings;
}
