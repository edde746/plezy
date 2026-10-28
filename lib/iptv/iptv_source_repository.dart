import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../media/live_tv_support.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../services/credential_vault.dart';
import '../sources/source_models.dart';
import '../sources/source_transport.dart';
import '../sources/universal_media_input.dart';
import 'iptv_live_tv_session.dart';
import 'dispatcharr_dvr_client.dart';
import 'stalker_portal_client.dart';
import 'iptv_models.dart';
import 'iptv_playlist_parser.dart';

class IptvImportException implements Exception {
  const IptvImportException(this.code);
  final String code;

  @override
  String toString() => 'IptvImportException($code)';
}

/// Profile-scoped IPTV catalog and import service. Provider URLs, passwords
/// and resolved stream addresses are encrypted before they enter SQLite.
class IptvSourceRepository {
  IptvSourceRepository(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();
  static const maxPlaylistBytes = IptvPlaylistParser.maxCharacters;
  static const maxXmltvBytes = IptvXmltvParser.maxCharacters;

  Future<String> createSource({
    required String profileId,
    required String displayName,
    required IptvInputKind kind,
    required String endpoint,
    String guideEndpoint = '',
    List<String> additionalGuideEndpoints = const [],
    String username = '',
    String password = '',
    String macAddress = '',
    String dispatcharrApiEndpoint = '',
    String dispatcharrApiKey = '',
    bool localTimeShiftEnabled = true,
    bool allowHttp = false,
  }) async {
    final config = IptvSourceConfiguration(
      id: _uuid.v4(),
      profileId: profileId,
      displayName: displayName.trim(),
      kind: kind,
      endpoint: endpoint.trim(),
      guideEndpoint: guideEndpoint.trim(),
      additionalGuideEndpoints: additionalGuideEndpoints.map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
      username: username,
      password: password,
      macAddress: macAddress.trim().toUpperCase(),
      dispatcharrApiEndpoint: dispatcharrApiEndpoint.trim(),
      dispatcharrApiKey: dispatcharrApiKey.trim(),
      localTimeShiftEnabled: localTimeShiftEnabled,
      allowHttp: allowHttp,
    );
    _validate(config);
    final protectedConfig = await CredentialVault.protect(jsonEncode(config.toJson()));
    await _database.runIdentityMutation(() => _database.customStatement(
      'INSERT INTO iptv_sources(id, profile_id, display_name, kind, config_ciphertext, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        config.id,
        config.profileId,
        config.displayName,
        config.kind.name,
        protectedConfig,
        DateTime.now().millisecondsSinceEpoch,
      ],
    ));
    return config.id;
  }

  Future<void> updateSource(IptvSourceConfiguration config) async {
    _validate(config);
    final protectedConfig = await CredentialVault.protect(jsonEncode(config.toJson()));
    final changed = await _database.runIdentityMutation(
      () => _database.customUpdate(
        'UPDATE iptv_sources SET display_name=?, kind=?, config_ciphertext=?, revision=revision+1, last_error_code=NULL WHERE id=? AND profile_id=?',
        variables: [
          Variable(config.displayName.trim()),
          Variable(config.kind.name),
          Variable(protectedConfig),
          Variable(config.id),
          Variable(config.profileId),
        ],
      ),
    );
    if (changed != 1) throw const IptvImportException('source_missing');
  }

  Future<IptvSourceConfiguration?> configuration(String profileId, String sourceId) async {
    final row = await _database
        .customSelect(
          'SELECT config_ciphertext FROM iptv_sources WHERE profile_id=? AND id=?',
          variables: [Variable(profileId), Variable(sourceId)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    final clear = await CredentialVault.reveal(row.read<String>('config_ciphertext'));
    if (clear == null) throw const IptvImportException('credential_unavailable');
    try {
      return IptvSourceConfiguration.fromJson(jsonDecode(clear) as Map<String, dynamic>);
    } on Object {
      throw const IptvImportException('source_invalid');
    }
  }

  Future<List<IptvSourceSummary>> sources(String profileId) async {
    final rows = await _database.customSelect('''
      SELECT s.id, s.profile_id, s.display_name, s.kind, s.generation, s.last_success_at, s.last_error_code,
             (SELECT COUNT(*) FROM iptv_channels c WHERE c.source_id=s.id) AS channel_count,
             (SELECT COUNT(*) FROM iptv_programmes p WHERE p.source_id=s.id) AS programme_count
      FROM iptv_sources s WHERE s.profile_id=? ORDER BY s.created_at
    ''', variables: [Variable(profileId)]).get();
    return [
      for (final row in rows)
        IptvSourceSummary(
          id: row.read<String>('id'),
          profileId: row.read<String>('profile_id'),
          displayName: row.read<String>('display_name'),
          kind: _kind(row.read<String>('kind')),
          generation: row.read<int>('generation'),
          channelCount: row.read<int>('channel_count'),
          programmeCount: row.read<int>('programme_count'),
          lastSuccessAt: row.readNullable<int>('last_success_at') == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(row.read<int>('last_success_at')),
          lastErrorCode: row.readNullable<String>('last_error_code'),
        ),
    ];
  }

  Future<List<LiveTvChannel>> channels(String profileId) async {
    final sourceRows = await _database
        .customSelect('SELECT id, display_name FROM iptv_sources WHERE profile_id=? ORDER BY created_at',
            variables: [Variable(profileId)])
        .get();
    final channels = <LiveTvChannel>[];
    for (final source in sourceRows) {
      final sourceId = source.read<String>('id');
      final rows = await _database
          .customSelect('SELECT channel_id, title, tvg_id, number, group_title, logo_url, is_radio, catchup_days, catchup_source_ciphertext FROM iptv_channels WHERE source_id=?',
              variables: [Variable(sourceId)])
          .get();
      final overrideRows = await _database.customSelect(
        'SELECT channel_id, favorite, favorite_order, hidden, custom_title, group_override, guide_id_override, parental_locked FROM iptv_channel_overrides WHERE profile_id=? AND source_id=?',
        variables: [Variable(profileId), Variable(sourceId)],
      ).get();
      final groupLockRows = await _database.customSelect(
        'SELECT group_key FROM iptv_group_locks WHERE profile_id=? AND source_id=?',
        variables: [Variable(profileId), Variable(sourceId)],
      ).get();
      final lockedGroups = {for (final row in groupLockRows) row.read<String>('group_key')};
      final overrides = {for (final row in overrideRows) row.read<String>('channel_id'): row};
      final snapshots = <IptvChannelSnapshot>[];
      for (final row in rows) {
        final id = row.read<String>('channel_id');
        final override = overrides[id];
        if (override?.read<int>('hidden') == 1) continue;
        final customTitle = override?.readNullable<String>('custom_title')?.trim();
        final groupOverride = override?.readNullable<String>('group_override')?.trim();
        final guideIdOverride = override?.readNullable<String>('guide_id_override')?.trim();
        final groupTitle = groupOverride != null && groupOverride.isNotEmpty
            ? groupOverride
            : row.readNullable<String>('group_title');
        snapshots.add(
          IptvChannelSnapshot(
            id: id,
            sourceId: sourceId,
            title: customTitle != null && customTitle.isNotEmpty ? customTitle : row.read<String>('title'),
            tvgId: guideIdOverride != null && guideIdOverride.isNotEmpty ? guideIdOverride : row.readNullable<String>('tvg_id'),
            number: row.readNullable<String>('number'),
            groupTitle: groupTitle,
            logoUrl: row.readNullable<String>('logo_url'),
            radio: row.read<int>('is_radio') == 1,
            hasCatchup: row.readNullable<String>('catchup_source_ciphertext') != null,
            catchupDays: row.readNullable<int>('catchup_days'),
            favorite: override?.read<int>('favorite') == 1,
            favoriteOrder: override?.read<int>('favorite_order') ?? 0,
            parentalLocked: override?.read<int>('parental_locked') == 1 ||
                lockedGroups.contains(iptvGroupLockKey(groupTitle)),
          ),
        );
      }
      snapshots.sort((a, b) {
        final number = (double.tryParse(a.number ?? '') ?? double.infinity)
            .compareTo(double.tryParse(b.number ?? '') ?? double.infinity);
        return number != 0 ? number : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      channels.addAll(snapshots.map((channel) => channel.toLiveTvChannel(source.read<String>('display_name'))));
    }
    return channels;
  }

  Future<List<IptvEditableChannel>> editableChannels(String profileId, String sourceId) async {
    final source = await _source(profileId, sourceId);
    if (source == null) throw const IptvImportException('source_missing');
    final rows = await _database.customSelect('''
      SELECT c.channel_id, c.title, c.tvg_id, c.number, c.group_title, c.logo_url,
             COALESCE(o.hidden, 0) AS hidden, o.custom_title, o.group_override, o.guide_id_override,
             COALESCE(o.parental_locked, 0) AS parental_locked
      FROM iptv_channels c LEFT JOIN iptv_channel_overrides o
        ON o.profile_id=? AND o.source_id=c.source_id AND o.channel_id=c.channel_id
      WHERE c.source_id=? ORDER BY c.number, c.title
    ''', variables: [Variable(profileId), Variable(sourceId)]).get();
    return [
      for (final row in rows)
        IptvEditableChannel(
          id: row.read<String>('channel_id'),
          title: row.read<String>('title'),
          number: row.readNullable<String>('number'),
          groupTitle: row.readNullable<String>('group_title'),
          tvgId: row.readNullable<String>('tvg_id'),
          guideIdOverride: row.readNullable<String>('guide_id_override'),
          logoUrl: row.readNullable<String>('logo_url'),
          hidden: row.read<int>('hidden') == 1,
          customTitle: row.readNullable<String>('custom_title'),
          groupOverride: row.readNullable<String>('group_override'),
          parentalLocked: row.read<int>('parental_locked') == 1,
        ),
    ];
  }

  Future<void> saveChannelPresentation({
    required String profileId,
    required String sourceId,
    required String channelId,
    required bool hidden,
    required String? customTitle,
    required String? groupOverride,
    required String? guideIdOverride,
    required bool parentalLocked,
  }) async {
    final source = await _source(profileId, sourceId);
    if (source == null) throw const IptvImportException('source_missing');
    final title = customTitle?.trim();
    final group = groupOverride?.trim();
    final guideId = guideIdOverride?.trim();
    if ((title?.length ?? 0) > 160 || (group?.length ?? 0) > 120 || (guideId?.length ?? 0) > 180) {
      throw const IptvImportException('source_invalid');
    }
    final changed = await _database.runIdentityMutation(() => _database.customUpdate('''
      INSERT INTO iptv_channel_overrides(
        profile_id, source_id, channel_id, favorite, favorite_order, hidden, custom_title, group_override, guide_id_override, parental_locked
      )
      SELECT ?, ?, channel_id, 0, 0, ?, ?, ?, ?, ? FROM iptv_channels WHERE source_id=? AND channel_id=?
      ON CONFLICT(profile_id, source_id, channel_id) DO UPDATE SET
        hidden=excluded.hidden, custom_title=excluded.custom_title, group_override=excluded.group_override,
        guide_id_override=excluded.guide_id_override, parental_locked=excluded.parental_locked
    ''', variables: [
      Variable(profileId),
      Variable(sourceId),
      Variable(hidden ? 1 : 0),
      Variable(title == null || title.isEmpty ? null : title),
      Variable(group == null || group.isEmpty ? null : group),
      Variable(guideId == null || guideId.isEmpty ? null : guideId),
      Variable(parentalLocked ? 1 : 0),
      Variable(sourceId),
      Variable(channelId),
    ]));
    if (changed != 1) throw const IptvImportException('source_missing');
  }

  Future<Set<String>> lockedGroups(String profileId, String sourceId) async {
    final rows = await _database.customSelect(
      'SELECT group_key FROM iptv_group_locks WHERE profile_id=? AND source_id=?',
      variables: [Variable(profileId), Variable(sourceId)],
    ).get();
    return {for (final row in rows) row.read<String>('group_key')};
  }

  Future<void> saveGroupLock({
    required String profileId,
    required String sourceId,
    required String groupTitle,
    required bool locked,
  }) async {
    final source = await _source(profileId, sourceId);
    final title = groupTitle.trim();
    if (source == null) throw const IptvImportException('source_missing');
    if (title.isEmpty || title.length > 120) throw const IptvImportException('source_invalid');
    final key = iptvGroupLockKey(title);
    await _database.runIdentityMutation(() async {
      if (locked) {
        await _database.customStatement('''
          INSERT INTO iptv_group_locks(profile_id, source_id, group_key, group_title)
          VALUES (?, ?, ?, ?)
          ON CONFLICT(profile_id, source_id, group_key) DO UPDATE SET group_title=excluded.group_title
        ''', [profileId, sourceId, key, title]);
      } else {
        await _database.customStatement(
          'DELETE FROM iptv_group_locks WHERE profile_id=? AND source_id=? AND group_key=?',
          [profileId, sourceId, key],
        );
      }
    });
  }

  Future<List<FavoriteChannel>> favorites(String profileId) async {
    final rows = await _database.customSelect('''
      SELECT o.source_id, o.channel_id, COALESCE(NULLIF(o.custom_title, ''), c.title) AS title, c.logo_url, c.number
      FROM iptv_channel_overrides o JOIN iptv_channels c
        ON c.source_id=o.source_id AND c.channel_id=o.channel_id
      JOIN iptv_sources s ON s.id=o.source_id AND s.profile_id=o.profile_id
      WHERE o.profile_id=? AND o.favorite=1 AND o.hidden=0 ORDER BY o.favorite_order, c.number, c.title
    ''', variables: [Variable(profileId)]).get();
    return [
      for (final row in rows)
        FavoriteChannel(
          source: iptvFavoriteSource(row.read<String>('source_id')),
          id: '${row.read<String>('source_id')}:${row.read<String>('channel_id')}',
          title: row.read<String>('title'),
          thumb: row.readNullable<String>('logo_url'),
          vcn: row.readNullable<String>('number'),
        ),
    ];
  }

  Future<void> saveFavoriteOrder(String profileId, String sourceId, List<String> channelIds) async {
    final source = await _source(profileId, sourceId);
    if (source == null) throw const IptvImportException('source_missing');
    final orderedIds = channelIds.toSet().toList();
    await _database.runIdentityMutation(() => _database.transaction(() async {
      await _database.customStatement(
        'UPDATE iptv_channel_overrides SET favorite=0 WHERE profile_id=? AND source_id=? AND favorite=1 AND hidden=0',
        [profileId, sourceId],
      );
      for (var index = 0; index < orderedIds.length; index++) {
        await _database.customStatement('''
          INSERT INTO iptv_channel_overrides(profile_id, source_id, channel_id, favorite, favorite_order)
          SELECT ?, ?, channel_id, 1, ? FROM iptv_channels WHERE source_id=? AND channel_id=?
          ON CONFLICT(profile_id, source_id, channel_id) DO UPDATE SET favorite=1, favorite_order=excluded.favorite_order
        ''', [profileId, sourceId, index, sourceId, orderedIds[index]]);
      }
    }));
  }

  Future<List<LiveTvProgram>> schedule(
    String profileId,
    DateTime from,
    DateTime to, {
    String? sourceId,
    String? channelId,
  }) async {
    final rows = await _database.customSelect('''
      SELECT p.source_id, p.channel_id, p.begins_at, p.ends_at, p.title, p.summary, p.category, p.episode_id, p.thumb_url
      FROM iptv_programmes p JOIN iptv_sources s ON s.id=p.source_id
      WHERE s.profile_id=? AND p.begins_at < ? AND p.ends_at > ?
        AND (? IS NULL OR p.source_id=?) AND (? IS NULL OR p.channel_id=?)
      ORDER BY p.begins_at
    ''', variables: [
      Variable(profileId),
      Variable(to.millisecondsSinceEpoch ~/ 1000),
      Variable(from.millisecondsSinceEpoch ~/ 1000),
      Variable(sourceId),
      Variable(sourceId),
      Variable(channelId),
      Variable(channelId),
    ]).get();
    return [
      for (final row in rows)
        IptvProgrammeSnapshot(
          channelId: row.read<String>('channel_id'),
          beginsAt: row.read<int>('begins_at'),
          endsAt: row.read<int>('ends_at'),
          title: row.read<String>('title'),
          summary: row.readNullable<String>('summary'),
          category: row.readNullable<String>('category'),
          episodeId: row.readNullable<String>('episode_id'),
          thumb: row.readNullable<String>('thumb_url'),
        ).toLiveTvProgram(row.read<String>('source_id')),
    ];
  }

  Future<List<IptvSourceSummary>> vodSources(String profileId) async {
    final available = <IptvSourceSummary>[];
    for (final source in await sources(profileId)) {
      if (!source.kind.supportsXtreamVod) continue;
      final config = await configuration(profileId, source.id);
      if (config?.supportsXtreamCatalog == true) available.add(source);
    }
    return available;
  }

  Future<List<IptvVodCategory>> fetchVodCategories(
    String profileId,
    String sourceId,
    IptvVodKind kind,
  ) async {
    final config = await configuration(profileId, sourceId);
    if (config == null) throw const IptvImportException('source_missing');
    if (!config.supportsXtreamCatalog) throw const IptvImportException('vod_unavailable');
    final action = kind == IptvVodKind.movie ? 'get_vod_categories' : 'get_series_categories';
    final stored = await _source(profileId, sourceId);
    if (stored == null) throw const IptvImportException('source_missing');
    final transport = SourceTransport(allowHttp: config.allowHttp);
    try {
      final response = await _xtreamJson(transport, config.playerApiUri(action));
      final rows = _xtreamRows(response);
      final categories = <IptvVodCategory>[];
      for (final value in rows) {
        final row = sourceMap(value);
        final id = _valueString(row, const ['category_id', 'id']);
        final name = _valueString(row, const ['category_name', 'name']);
        if (id == null || name == null) continue;
        categories.add(IptvVodCategory(id: id, name: name, kind: kind));
      }
      await _replaceVodCategories(stored, kind, categories);
      return categories;
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } on IptvImportException {
      rethrow;
    } on Object {
      throw const IptvImportException('provider_unavailable');
    } finally {
      transport.close();
    }
  }

  Future<List<IptvVodItem>> fetchVodItems(
    String profileId,
    String sourceId,
    IptvVodKind kind, {
    String? categoryId,
  }) async {
    final config = await configuration(profileId, sourceId);
    if (config == null) throw const IptvImportException('source_missing');
    if (!config.supportsXtreamCatalog) throw const IptvImportException('vod_unavailable');
    final stored = await _source(profileId, sourceId);
    if (stored == null) throw const IptvImportException('source_missing');
    final action = kind == IptvVodKind.movie ? 'get_vod_streams' : 'get_series';
    final transport = SourceTransport(allowHttp: config.allowHttp);
    try {
      final response = await _xtreamJson(
        transport,
        config.playerApiUri(action, parameters: categoryId == null ? const {} : {'category_id': categoryId}),
      );
      final rows = _xtreamRows(response);
      if (rows.length > IptvPlaylistParser.maxEntries) throw const IptvImportException('invalid_data');
      final items = <IptvVodItem>[];
      for (final value in rows) {
        final row = sourceMap(value);
        final id = _valueString(row, kind == IptvVodKind.movie ? const ['stream_id', 'id'] : const ['series_id', 'id']);
        final title = _valueString(row, const ['name', 'title']);
        if (id == null || title == null) continue;
        final info = sourceMap(row['info']);
        final poster = _safeVodArtwork(
          _valueString(row, const ['stream_icon', 'cover', 'cover_big', 'poster']) ??
              _valueString(info, const ['movie_image', 'cover', 'cover_big']),
          config,
        );
        final backdropRaw = _firstStringValue(row, const ['backdrop_path', 'backdrop', 'backdrop_url']) ??
            _firstStringValue(info, const ['backdrop_path', 'backdrop', 'backdrop_url']);
        items.add(
          IptvVodItem(
            id: id,
            sourceId: sourceId,
            kind: kind,
            title: _safeCatalogText(title, 240),
            categoryId: _valueString(row, const ['category_id']),
            plot: _safeCatalogText(_valueString(row, const ['plot', 'description']) ?? _valueString(info, const ['plot']), 4000),
            year: _valueInt(row, const ['year', 'releasedate']) ?? _valueInt(info, const ['releasedate', 'year']),
            durationSeconds: _valueInt(row, const ['duration_secs', 'duration']) ??
                _durationSeconds(_valueString(row, const ['duration']) ?? _valueString(info, const ['duration'])),
            rating: _valueDouble(row, const ['rating', 'rating_5based']),
            posterUrl: poster,
            backdropUrl: _safeVodArtwork(backdropRaw, config),
            containerExtension: _safeContainerExtension(
              _valueString(row, const ['container_extension']) ?? _valueString(info, const ['container_extension']) ?? 'mp4',
            ),
          ),
        );
      }
      await _replaceVodItems(stored, kind, categoryId, items);
      return items;
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } on IptvImportException {
      rethrow;
    } on Object {
      throw const IptvImportException('provider_unavailable');
    } finally {
      transport.close();
    }
  }

  Future<IptvVodSeriesDetails> fetchVodSeriesDetails(
    String profileId,
    String sourceId,
    IptvVodItem series,
  ) async {
    if (series.kind != IptvVodKind.series || series.sourceId != sourceId) {
      throw const IptvImportException('invalid_data');
    }
    final config = await configuration(profileId, sourceId);
    if (config == null || !config.supportsXtreamCatalog) throw const IptvImportException('source_missing');
    final transport = SourceTransport(allowHttp: config.allowHttp);
    try {
      final response = await _xtreamJson(
        transport,
        config.playerApiUri('get_series_info', parameters: {'series_id': series.id}),
      );
      final envelope = sourceMap(response);
      final info = sourceMap(envelope['info']);
      final episodeMap = envelope['episodes'];
      final episodes = <IptvVodEpisode>[];
      if (episodeMap is List) {
        for (final episode in episodeMap) {
          _appendEpisode(episodes, episode, config, null);
        }
      } else if (episodeMap is Map) {
        for (final seasonEntry in episodeMap.entries) {
          final season = int.tryParse('${seasonEntry.key}') ?? 0;
          final rows = seasonEntry.value is List ? seasonEntry.value as List : const [];
          for (final episode in rows) {
            _appendEpisode(episodes, episode, config, season);
          }
        }
      }
      episodes.sort((a, b) {
        final season = a.season.compareTo(b.season);
        return season != 0 ? season : a.episode.compareTo(b.episode);
      });
      final updatedSeries = IptvVodItem(
        id: series.id,
        sourceId: sourceId,
        kind: IptvVodKind.series,
        title: _safeCatalogText(_valueString(info, const ['name', 'title']) ?? series.title, 240),
        categoryId: series.categoryId,
        plot: _safeCatalogText(_valueString(info, const ['plot', 'description']) ?? series.plot, 4000),
        year: _valueInt(info, const ['year', 'releaseDate']) ?? series.year,
        rating: _valueDouble(info, const ['rating']) ?? series.rating,
        posterUrl: _safeVodArtwork(
          _valueString(info, const ['cover', 'cover_big', 'movie_image']) ?? series.posterUrl,
          config,
        ),
        backdropUrl: _safeVodArtwork(_firstStringValue(info, const ['backdrop_path', 'backdrop', 'backdrop_url']), config) ??
            series.backdropUrl,
      );
      return IptvVodSeriesDetails(series: updatedSeries, episodes: episodes);
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } on IptvImportException {
      rethrow;
    } on Object {
      throw const IptvImportException('provider_unavailable');
    } finally {
      transport.close();
    }
  }

  Future<List<IptvVodCategory>> cachedVodCategories(String profileId, String sourceId, IptvVodKind kind) async {
    final rows = await _database.customSelect('''
      SELECT category_id, name FROM iptv_vod_categories WHERE source_id=? AND kind=? ORDER BY name COLLATE NOCASE
    ''', variables: [Variable(sourceId), Variable(kind.name)]).get();
    return [for (final row in rows) IptvVodCategory(id: row.read<String>('category_id'), name: row.read<String>('name'), kind: kind)];
  }

  Future<List<IptvVodItem>> cachedVodItems(
    String profileId,
    String sourceId,
    IptvVodKind kind, {
    String? categoryId,
  }) async {
    final rows = await _database.customSelect('''
      SELECT item_id, category_id, title, plot, year, duration_seconds, rating, poster_url, backdrop_url, container_extension
      FROM iptv_vod_items
      WHERE source_id=? AND kind=? AND (? IS NULL OR category_id=?)
      ORDER BY title COLLATE NOCASE
    ''', variables: [Variable(sourceId), Variable(kind.name), Variable(categoryId), Variable(categoryId)]).get();
    return [
      for (final row in rows)
        IptvVodItem(
          id: row.read<String>('item_id'),
          sourceId: sourceId,
          kind: kind,
          categoryId: row.readNullable<String>('category_id'),
          title: row.read<String>('title'),
          plot: row.readNullable<String>('plot'),
          year: row.readNullable<int>('year'),
          durationSeconds: row.readNullable<int>('duration_seconds'),
          rating: row.readNullable<double>('rating'),
          posterUrl: row.readNullable<String>('poster_url'),
          backdropUrl: row.readNullable<String>('backdrop_url'),
          containerExtension: row.read<String>('container_extension'),
        ),
    ];
  }

  /// Searches the locally cached Xtream catalog without issuing provider
  /// requests for every global-search keystroke.
  Future<List<IptvVodItem>> searchVod(String profileId, String query, {int limit = 40}) async {
    final value = query.trim();
    if (value.isEmpty) return const [];
    final rows = await _database.customSelect('''
      SELECT v.source_id, v.kind, v.item_id, v.category_id, v.title, v.plot, v.year,
             v.duration_seconds, v.rating, v.poster_url, v.backdrop_url, v.container_extension
      FROM iptv_vod_items v JOIN iptv_sources s ON s.id=v.source_id
      WHERE s.profile_id=? AND v.kind IN ('movie', 'series')
        AND (instr(lower(v.title), lower(?)) > 0 OR instr(lower(COALESCE(v.plot, '')), lower(?)) > 0)
      ORDER BY CASE WHEN instr(lower(v.title), lower(?))=1 THEN 0 ELSE 1 END, v.title COLLATE NOCASE
      LIMIT ?
    ''', variables: [Variable(profileId), Variable(value), Variable(value), Variable(value), Variable(limit.clamp(1, 100).toInt())]).get();
    return [
      for (final row in rows)
        IptvVodItem(
          id: row.read<String>('item_id'),
          sourceId: row.read<String>('source_id'),
          kind: IptvVodKind.values.byName(row.read<String>('kind')),
          categoryId: row.readNullable<String>('category_id'),
          title: row.read<String>('title'),
          plot: row.readNullable<String>('plot'),
          year: row.readNullable<int>('year'),
          durationSeconds: row.readNullable<int>('duration_seconds'),
          rating: row.readNullable<double>('rating'),
          posterUrl: row.readNullable<String>('poster_url'),
          backdropUrl: row.readNullable<String>('backdrop_url'),
          containerExtension: row.read<String>('container_extension'),
        ),
    ];
  }

  Future<List<IptvVodProgress>> vodProgresses(String profileId, String sourceId, IptvVodKind kind) async {
    final rows = await _database.customSelect('''
      SELECT p.source_id, p.kind, p.item_id, p.episode_id, p.position_ms, p.duration_ms, p.updated_at, p.finished
      FROM iptv_vod_progress p JOIN iptv_sources s ON s.id=p.source_id
      WHERE s.profile_id=? AND p.source_id=? AND p.kind=?
      ORDER BY p.updated_at DESC LIMIT 2000
    ''', variables: [Variable(profileId), Variable(sourceId), Variable(kind.name)]).get();
    return [for (final row in rows) _vodProgressFromRow(row)];
  }

  Future<IptvVodProgress?> vodProgress(
    String profileId,
    String sourceId, {
    required IptvVodKind kind,
    required String itemId,
    String episodeId = '',
  }) async {
    final row = await _database.customSelect('''
      SELECT p.source_id, p.kind, p.item_id, p.episode_id, p.position_ms, p.duration_ms, p.updated_at, p.finished
      FROM iptv_vod_progress p JOIN iptv_sources s ON s.id=p.source_id
      WHERE s.profile_id=? AND p.source_id=? AND p.kind=? AND p.item_id=? AND p.episode_id=?
    ''', variables: [Variable(profileId), Variable(sourceId), Variable(kind.name), Variable(itemId), Variable(episodeId)]).getSingleOrNull();
    return row == null ? null : _vodProgressFromRow(row);
  }

  Future<void> saveVodProgress(
    String profileId, {
    required String sourceId,
    required IptvVodKind kind,
    required String itemId,
    String episodeId = '',
    required int positionMs,
    required int durationMs,
    required bool finished,
  }) async {
    if (itemId.isEmpty || itemId.length > 180 || episodeId.length > 180 || positionMs < 0 || durationMs < 0) {
      throw const IptvImportException('invalid_data');
    }
    if (await _source(profileId, sourceId) == null) throw const IptvImportException('source_missing');
    final duration = durationMs.clamp(0, 14 * 24 * 60 * 60 * 1000).toInt();
    final position = positionMs.clamp(0, 14 * 24 * 60 * 60 * 1000).toInt();
    await _database.customStatement('''
      INSERT INTO iptv_vod_progress(source_id, kind, item_id, episode_id, position_ms, duration_ms, updated_at, finished)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(source_id, kind, item_id, episode_id) DO UPDATE SET
        position_ms=excluded.position_ms, duration_ms=excluded.duration_ms,
        updated_at=excluded.updated_at, finished=excluded.finished
    ''', [
      sourceId,
      kind.name,
      itemId,
      episodeId,
      position,
      duration,
      DateTime.now().millisecondsSinceEpoch,
      finished ? 1 : 0,
    ]);
  }

  /// Compact, credential-free progress rows suitable for the user's opt-in
  /// Plex account sync. Source endpoints and usernames are represented only
  /// by a SHA-256 fingerprint.
  Future<List<Map<String, Object?>>> exportVodProgressForSync(String profileId) async {
    final rows = await _database.customSelect('''
      SELECT p.source_id, p.kind, p.item_id, p.episode_id, p.position_ms, p.duration_ms, p.updated_at, p.finished
      FROM iptv_vod_progress p JOIN iptv_sources s ON s.id=p.source_id
      WHERE s.profile_id=? ORDER BY p.updated_at DESC LIMIT 1000
    ''', variables: [Variable(profileId)]).get();
    final fingerprints = <String, String>{};
    for (final sourceId in rows.map((row) => row.read<String>('source_id')).toSet()) {
      final config = await configuration(profileId, sourceId);
      if (config != null) fingerprints[sourceId] = _progressSourceFingerprint(config);
    }
    return [
      for (final row in rows)
        if (fingerprints[row.read<String>('source_id')] case final fingerprint?)
          {
            'source': fingerprint,
            'kind': row.read<String>('kind'),
            'item': row.read<String>('item_id'),
            'episode': row.read<String>('episode_id'),
            'position': row.read<int>('position_ms'),
            'duration': row.read<int>('duration_ms'),
            'updated': row.read<int>('updated_at'),
            'finished': row.read<int>('finished') == 1,
          },
    ];
  }

  /// Merge remote progress by timestamp. A more recent local or remote update
  /// wins; provider IDs remain scoped by a matching per-device source.
  Future<void> mergeVodProgressFromSync(String profileId, List<dynamic> remoteRows) async {
    final fingerprints = <String, String>{};
    for (final source in await sources(profileId)) {
      final config = await configuration(profileId, source.id);
      if (config != null) fingerprints.putIfAbsent(_progressSourceFingerprint(config), () => source.id);
    }
    for (final raw in remoteRows.take(1000)) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final fingerprint = row['source'];
      final kind = row['kind'];
      final item = row['item'];
      final episode = row['episode'];
      final position = row['position'];
      final duration = row['duration'];
      final updated = row['updated'];
      final finished = row['finished'];
      if (fingerprint is! String || fingerprint.length != 64 ||
          kind is! String || !const {'movie', 'series'}.contains(kind) ||
          item is! String || item.isEmpty || item.length > 180 ||
          episode is! String || episode.length > 180 ||
          position is! int || position < 0 || duration is! int || duration < 0 ||
          updated is! int || updated < 0 || finished is! bool) {
        continue;
      }
      final sourceId = fingerprints[fingerprint];
      if (sourceId == null) continue;
      await _database.customStatement('''
        INSERT INTO iptv_vod_progress(source_id, kind, item_id, episode_id, position_ms, duration_ms, updated_at, finished)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(source_id, kind, item_id, episode_id) DO UPDATE SET
          position_ms=excluded.position_ms, duration_ms=excluded.duration_ms,
          updated_at=excluded.updated_at, finished=excluded.finished
        WHERE excluded.updated_at > iptv_vod_progress.updated_at
      ''', [
        sourceId,
        kind,
        item,
        episode,
        position.clamp(0, 14 * 24 * 60 * 60 * 1000).toInt(),
        duration.clamp(0, 14 * 24 * 60 * 60 * 1000).toInt(),
        updated,
        finished ? 1 : 0,
      ]);
    }
  }

  String _progressSourceFingerprint(IptvSourceConfiguration config) {
    final endpoint = Uri.tryParse(config.endpoint);
    final canonicalEndpoint = endpoint == null
        ? config.endpoint.trim()
        : endpoint.replace(query: '', fragment: '').toString().toLowerCase();
    final identity = [
      config.kind.name,
      config.displayName.trim().toLowerCase(),
      canonicalEndpoint,
      config.username.trim().toLowerCase(),
    ].join('\n');
    return sha256.convert(utf8.encode(identity)).toString();
  }

  IptvVodProgress _vodProgressFromRow(QueryRow row) => IptvVodProgress(
    sourceId: row.read<String>('source_id'),
    kind: IptvVodKind.values.byName(row.read<String>('kind')),
    itemId: row.read<String>('item_id'),
    episodeId: row.read<String>('episode_id'),
    positionMs: row.read<int>('position_ms'),
    durationMs: row.read<int>('duration_ms'),
    updatedAt: row.read<int>('updated_at'),
    finished: row.read<int>('finished') == 1,
  );

  Future<Uri> vodPlaybackUri(
    String profileId,
    String sourceId, {
    required String itemId,
    required String extension,
    bool series = false,
  }) async {
    final config = await configuration(profileId, sourceId);
    if (config == null) throw const IptvImportException('source_missing');
    try {
      return config.vodStreamUri(itemId: itemId, extension: extension, series: series);
    } on Object {
      throw const IptvImportException('source_invalid');
    }
  }

  Future<List<IptvLocalRecording>> localRecordings(String profileId) async {
    final rows = await _database.customSelect('''
      SELECT id, source_id, channel_id, title, programme_title, file_path, started_at, completed_at,
             duration_seconds, size_bytes, state, error_code
      FROM iptv_recordings WHERE profile_id=? ORDER BY started_at DESC
    ''', variables: [Variable(profileId)]).get();
    return [
      for (final row in rows)
        IptvLocalRecording(
          id: row.read<String>('id'),
          profileId: profileId,
          sourceId: row.readNullable<String>('source_id'),
          channelId: row.readNullable<String>('channel_id'),
          title: row.read<String>('title'),
          programmeTitle: row.readNullable<String>('programme_title'),
          filePath: row.read<String>('file_path'),
          startedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('started_at') * 1000),
          completedAt: row.readNullable<int>('completed_at') == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(row.read<int>('completed_at')! * 1000),
          durationSeconds: row.readNullable<int>('duration_seconds'),
          sizeBytes: row.readNullable<int>('size_bytes'),
          state: row.read<String>('state'),
          errorCode: row.readNullable<String>('error_code'),
        ),
    ];
  }

  Future<void> beginLocalRecording(IptvLocalRecording recording) async {
    await _database.runIdentityMutation(() => _database.customStatement('''
      INSERT INTO iptv_recordings(id, profile_id, source_id, channel_id, title, programme_title, file_path,
        started_at, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'recording')
    ''', [
      recording.id,
      recording.profileId,
      recording.sourceId,
      recording.channelId,
      recording.title,
      recording.programmeTitle,
      recording.filePath,
      recording.startedAt.millisecondsSinceEpoch ~/ 1000,
    ]));
  }

  Future<void> updateLocalRecordingFilePath({
    required String profileId,
    required String recordingId,
    required String filePath,
  }) async {
    await _database.runIdentityMutation(() => _database.customStatement(
      'UPDATE iptv_recordings SET file_path=? WHERE profile_id=? AND id=?',
      [filePath, profileId, recordingId],
    ));
  }

  Future<String> scheduleLocalRecording(String profileId, LiveTvChannel channel, LiveTvProgram program) async {
    final sourceId = channel.iptvSourceId;
    final channelId = channel.iptvChannelId;
    final startsAt = program.beginsAt;
    final endsAt = program.endsAt;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (sourceId == null || channelId == null || startsAt == null || endsAt == null || endsAt <= now || endsAt <= startsAt) {
      throw const IptvImportException('recording_schedule_invalid');
    }
    if (await _source(profileId, sourceId) == null) throw const IptvImportException('source_missing');
    final id = _uuid.v4();
    final stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      await _database.runIdentityMutation(() => _database.transaction(() async {
        final active = await _database.customSelect('''
          SELECT id FROM iptv_recording_schedules
          WHERE profile_id=? AND source_id=? AND channel_id=? AND starts_at=?
            AND state IN ('scheduled', 'starting', 'recording')
          LIMIT 1
        ''', variables: [Variable(profileId), Variable(sourceId), Variable(channelId), Variable(startsAt)]).getSingleOrNull();
        if (active != null) throw const IptvImportException('recording_schedule_exists');
        await _database.customStatement('''
          DELETE FROM iptv_recording_schedules
          WHERE profile_id=? AND source_id=? AND channel_id=? AND starts_at=?
            AND state IN ('completed', 'failed', 'missed', 'cancelled')
        ''', [profileId, sourceId, channelId, startsAt]);
        await _database.customStatement('''
          INSERT INTO iptv_recording_schedules(
            id, profile_id, source_id, channel_id, title, programme_title, starts_at, ends_at,
            state, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'scheduled', ?, ?)
        ''', [id, profileId, sourceId, channelId, channel.displayName, program.displayTitle, startsAt, endsAt, stamp, stamp]);
      }));
    } on IptvImportException {
      rethrow;
    } on Object {
      throw const IptvImportException('recording_schedule_exists');
    }
    return id;
  }

  Future<List<IptvLocalRecordingSchedule>> localRecordingSchedules({String? profileId}) async {
    final rows = await _database.customSelect('''
      SELECT id, profile_id, source_id, channel_id, title, programme_title, starts_at, ends_at, state,
             recording_id, error_code, created_at, updated_at
      FROM iptv_recording_schedules
      WHERE (? IS NULL OR profile_id=?) AND state IN ('scheduled', 'starting', 'recording', 'failed', 'missed')
      ORDER BY starts_at, title COLLATE NOCASE
    ''', variables: [Variable(profileId), Variable(profileId)]).get();
    return [
      for (final row in rows)
        IptvLocalRecordingSchedule(
          id: row.read<String>('id'),
          profileId: row.read<String>('profile_id'),
          sourceId: row.read<String>('source_id'),
          channelId: row.read<String>('channel_id'),
          title: row.read<String>('title'),
          programmeTitle: row.readNullable<String>('programme_title'),
          startsAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('starts_at') * 1000),
          endsAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('ends_at') * 1000),
          state: row.read<String>('state'),
          recordingId: row.readNullable<String>('recording_id'),
          errorCode: row.readNullable<String>('error_code'),
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at') * 1000),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at') * 1000),
        ),
    ];
  }

  Future<List<IptvLocalRecordingSchedule>> dueLocalRecordingSchedules() async {
    final rows = await _database.customSelect('''
      SELECT id, profile_id, source_id, channel_id, title, programme_title, starts_at, ends_at, state,
             recording_id, error_code, created_at, updated_at
      FROM iptv_recording_schedules WHERE state='scheduled' ORDER BY starts_at
    ''').get();
    return [
      for (final row in rows)
        IptvLocalRecordingSchedule(
          id: row.read<String>('id'),
          profileId: row.read<String>('profile_id'),
          sourceId: row.read<String>('source_id'),
          channelId: row.read<String>('channel_id'),
          title: row.read<String>('title'),
          programmeTitle: row.readNullable<String>('programme_title'),
          startsAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('starts_at') * 1000),
          endsAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('ends_at') * 1000),
          state: row.read<String>('state'),
          recordingId: row.readNullable<String>('recording_id'),
          errorCode: row.readNullable<String>('error_code'),
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at') * 1000),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at') * 1000),
        ),
    ];
  }

  Future<void> updateLocalRecordingSchedule(
    String scheduleId, {
    required String state,
    String? recordingId,
    String? errorCode,
  }) async {
    if (!const {'scheduled', 'starting', 'recording', 'completed', 'failed', 'missed', 'cancelled'}.contains(state)) {
      throw const IptvImportException('invalid_data');
    }
    await _database.runIdentityMutation(() => _database.customStatement('''
      UPDATE iptv_recording_schedules SET state=?, recording_id=?, error_code=?, updated_at=? WHERE id=?
    ''', [state, recordingId, errorCode, DateTime.now().millisecondsSinceEpoch ~/ 1000, scheduleId]));
  }

  Future<void> recoverLocalRecordingSchedules() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _database.runIdentityMutation(() => _database.transaction(() async {
      await _database.customStatement('''
        UPDATE iptv_recordings SET state='interrupted', completed_at=?, error_code='app_interrupted'
        WHERE state='recording'
      ''', [now]);
      await _database.customStatement('''
        UPDATE iptv_recording_schedules SET state='failed', error_code='app_interrupted', updated_at=?
        WHERE state IN ('starting', 'recording')
      ''', [now]);
    }));
  }

  Future<void> cancelLocalRecordingSchedule(String profileId, String scheduleId) async {
    await _database.runIdentityMutation(() => _database.customStatement('''
      UPDATE iptv_recording_schedules SET state='cancelled', updated_at=?
      WHERE profile_id=? AND id=? AND state='scheduled'
    ''', [DateTime.now().millisecondsSinceEpoch ~/ 1000, profileId, scheduleId]));
  }

  Future<void> finishLocalRecording({
    required String profileId,
    required String recordingId,
    required bool completed,
    int? durationSeconds,
    int? sizeBytes,
    String? errorCode,
  }) async {
    await _database.runIdentityMutation(() => _database.customStatement('''
      UPDATE iptv_recordings SET completed_at=?, duration_seconds=?, size_bytes=?, state=?, error_code=?
      WHERE profile_id=? AND id=?
    ''', [
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      durationSeconds,
      sizeBytes,
      completed ? 'complete' : 'failed',
      errorCode,
      profileId,
      recordingId,
    ]));
  }

  Future<void> deleteLocalRecording(String profileId, String recordingId) async {
    await _database.runIdentityMutation(() => _database.customStatement(
      'DELETE FROM iptv_recordings WHERE profile_id=? AND id=?',
      [profileId, recordingId],
    ));
  }

  Future<List<IptvDispatcharrRecording>> dispatcharrRecordings(String profileId) async {
    final records = <IptvDispatcharrRecording>[];
    for (final source in await sources(profileId)) {
      if (source.kind != IptvInputKind.dispatcharr) continue;
      final config = await configuration(profileId, source.id);
      if (config?.supportsDispatcharrDvr != true) continue;
      final client = DispatcharrDvrClient(config!);
      try {
        records.addAll(await client.recordings());
      } finally {
        client.close();
      }
    }
    records.sort((a, b) => (a.startedAt ?? DateTime(9999)).compareTo(b.startedAt ?? DateTime(9999)));
    return records;
  }

  Future<List<IptvDispatcharrRule>> dispatcharrRules(String profileId) async {
    final rules = <IptvDispatcharrRule>[];
    for (final source in await sources(profileId)) {
      if (source.kind != IptvInputKind.dispatcharr) continue;
      final config = await configuration(profileId, source.id);
      if (config?.supportsDispatcharrDvr != true) continue;
      final client = DispatcharrDvrClient(config!);
      try {
        rules.addAll(await client.rules());
      } finally {
        client.close();
      }
    }
    return rules;
  }

  Future<({Uri uri, Map<String, String> headers})> dispatcharrRecordingPlayback(
    String profileId,
    IptvDispatcharrRecording recording,
  ) async {
    final config = await configuration(profileId, recording.sourceId);
    if (config?.supportsDispatcharrDvr != true) throw const IptvImportException('dvr_unavailable');
    final client = DispatcharrDvrClient(config!);
    try {
      return (
        uri: client.recordingFileUri(recording.id),
        headers: {'Authorization': 'ApiKey ${config.dispatcharrApiKey.trim()}'},
      );
    } finally {
      client.close();
    }
  }

  Future<void> stopDispatcharrRecording(String profileId, IptvDispatcharrRecording recording) async {
    final config = await configuration(profileId, recording.sourceId);
    if (config?.supportsDispatcharrDvr != true) throw const IptvImportException('dvr_unavailable');
    final client = DispatcharrDvrClient(config!);
    try {
      await client.stopRecording(recording.id);
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } finally {
      client.close();
    }
  }

  Future<void> deleteDispatcharrRecording(String profileId, IptvDispatcharrRecording recording) async {
    final config = await configuration(profileId, recording.sourceId);
    if (config?.supportsDispatcharrDvr != true) throw const IptvImportException('dvr_unavailable');
    final client = DispatcharrDvrClient(config!);
    try {
      await client.deleteRecording(recording.id);
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } finally {
      client.close();
    }
  }

  Future<void> deleteDispatcharrRule(String profileId, IptvDispatcharrRule rule) async {
    final config = await configuration(profileId, rule.sourceId);
    if (config?.supportsDispatcharrDvr != true) throw const IptvImportException('dvr_unavailable');
    final client = DispatcharrDvrClient(config!);
    try {
      await client.deleteRule(rule);
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } finally {
      client.close();
    }
  }

  Future<void> scheduleDispatcharrRecording(
    String profileId,
    LiveTvChannel channel,
    LiveTvProgram program,
  ) async {
    final sourceId = channel.iptvSourceId;
    if (sourceId == null) throw const IptvImportException('dvr_unavailable');
    final config = await configuration(profileId, sourceId);
    if (config?.supportsDispatcharrDvr != true) throw const IptvImportException('dvr_unavailable');
    final client = DispatcharrDvrClient(config!);
    try {
      await client.schedule(channel: channel, program: program);
    } on SourceException catch (error) {
      throw IptvImportException(_iptvCodeForSourceFailure(error));
    } finally {
      client.close();
    }
  }

  Future<bool> supportsDispatcharrDvr(String profileId, String sourceId) async {
    final config = await configuration(profileId, sourceId);
    return config?.supportsDispatcharrDvr == true;
  }

  Future<String?> resolveStream(String profileId, String sourceId, String channelId) async {
    final row = await _database.customSelect('''
      SELECT c.stream_url_ciphertext FROM iptv_sources s
      JOIN iptv_channels c ON c.source_id=s.id
      WHERE s.profile_id=? AND s.id=? AND c.channel_id=?
    ''', variables: [Variable(profileId), Variable(sourceId), Variable(channelId)]).getSingleOrNull();
    if (row == null) return null;
    return CredentialVault.reveal(row.read<String>('stream_url_ciphertext'));
  }

  Future<LiveTvPlaybackSession?> startPlayback(
    String profileId,
    String sourceId,
    String channelId, {
    LiveTvProgram? program,
  }) async {
    final config = await configuration(profileId, sourceId);
    if (config == null) return null;
    final row = await _database.customSelect('''
      SELECT c.stream_url_ciphertext, c.catchup_source_ciphertext, c.catchup_days, c.stream_headers_ciphertext
      FROM iptv_sources s JOIN iptv_channels c ON c.source_id=s.id
      WHERE s.profile_id=? AND s.id=? AND c.channel_id=?
    ''', variables: [Variable(profileId), Variable(sourceId), Variable(channelId)]).getSingleOrNull();
    if (row == null) return null;
    final streamCiphertext = row.read<String>('stream_url_ciphertext');
    final catchupCiphertext = row.readNullable<String>('catchup_source_ciphertext');
    final catchupDays = row.readNullable<int>('catchup_days');
    final headersCiphertext = row.readNullable<String>('stream_headers_ciphertext');
    final headersJson = headersCiphertext == null ? null : await CredentialVault.reveal(headersCiphertext);
    if (headersCiphertext != null && headersJson == null) throw const IptvImportException('credential_unavailable');
    final headers = <String, String>{};
    if (headersJson != null) {
      try {
        final decoded = jsonDecode(headersJson);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.key is! String || entry.value is! String) continue;
            final key = (entry.key as String).toLowerCase();
            if (key == 'user-agent' || key == 'referer' || key == 'origin') {
              headers[key == 'user-agent' ? 'User-Agent' : key == 'referer' ? 'Referer' : 'Origin'] = entry.value as String;
            }
          }
        }
      } on FormatException {
        throw const IptvImportException('invalid_data');
      }
    }
    final catchupTemplate = catchupCiphertext == null ? null : await CredentialVault.reveal(catchupCiphertext);
    if (catchupCiphertext != null && catchupTemplate == null) {
      throw const IptvImportException('credential_unavailable');
    }
    Future<String?> resolve() async {
      if (program != null && catchupTemplate != null) {
        final start = program.beginsAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (start == null || start > now || (catchupDays != null && now - start > catchupDays * 86400)) {
          throw const IptvImportException('catchup_unavailable');
        }
        return _catchupUrl(catchupTemplate, program, config);
      }
      final value = await CredentialVault.reveal(streamCiphertext);
      if (value == null) return null;
      if (config.kind == IptvInputKind.stalker) {
        final command = _stalkerCommand(value);
        final client = StalkerPortalClient(config);
        try {
          return await client.createLink(command);
        } finally {
          client.close();
        }
      }
      try {
        return UniversalMediaAddress.parse(value, allowHttp: config.allowHttp, allowMpvProtocols: true).toString();
      } on SourceException {
        throw const IptvImportException('invalid_stream_address');
      }
    }

    final url = await resolve();
    if (url == null) return null;
    return IptvLiveTvPlaybackSession(
      initialUrl: url,
      refreshUrl: resolve,
      streamHeaders: Map.unmodifiable(headers),
      localTimeShiftEnabled: config.localTimeShiftEnabled,
      isCatchup: program != null && catchupTemplate != null,
      programInfo: program == null
          ? LiveProgramInfo.none
          : LiveProgramInfo(
              beginsAt: program.beginsAt,
              durationMs: program.durationMinutes == 0 ? null : program.durationMinutes * 60 * 1000,
            ),
    );
  }

  String _stalkerCommand(String stored) {
    const prefix = 'stalker:';
    if (!stored.startsWith(prefix)) throw const IptvImportException('invalid_stream_address');
    try {
      final payload = sourceMap(jsonDecode(stored.substring(prefix.length)));
      final command = payload['cmd'];
      if (command is! String || command.trim().isEmpty || command.length > 8192) {
        throw const IptvImportException('invalid_stream_address');
      }
      return command;
    } on IptvImportException {
      rethrow;
    } on Object {
      throw const IptvImportException('invalid_stream_address');
    }
  }

  Future<void> deleteSource(String profileId, String sourceId) async {
    await _database.runIdentityMutation(() => _database.customUpdate(
      'DELETE FROM iptv_sources WHERE profile_id=? AND id=?',
      variables: [Variable(profileId), Variable(sourceId)],
    ));
  }

  Future<void> deleteProfile(String profileId) async {
    List<IptvLocalRecording> recordings = const [];
    try {
      recordings = await localRecordings(profileId);
    } on Object {
      // Profile removal can continue if the recording catalog is unavailable.
    }
    await _database.runIdentityMutation(() async {
      await _database.customStatement('DELETE FROM iptv_recordings WHERE profile_id=?', [profileId]);
      await _database.customUpdate(
        'DELETE FROM iptv_sources WHERE profile_id=?',
        variables: [Variable(profileId)],
      );
    });
    try {
      final appSupport = await getApplicationSupportDirectory();
      final recordingRoot = p.normalize(p.join(appSupport.path, 'iptv-recordings'));
      for (final recording in recordings) {
        final path = p.normalize(recording.filePath);
        if (!p.isWithin(recordingRoot, path)) continue;
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } on Object {
          // A stale file is safer than blocking profile removal.
        }
      }
    } on Object {
      // The user can still remove orphaned storage outside this profile.
    }
  }

  Future<int> refresh(String profileId, String sourceId) async {
    final source = await _source(profileId, sourceId);
    if (source == null) throw const IptvImportException('source_missing');
    final config = await configuration(profileId, sourceId);
    if (config == null) throw const IptvImportException('source_missing');

    final transport = SourceTransport(allowHttp: config.allowHttp);
    StalkerPortalClient? stalker;
    try {
      late final Uri playlistUri;
      late final List<IptvPlaylistEntry> playlistEntries;
      Uri? playlistGuideUri;
      if (config.kind == IptvInputKind.stalker) {
        stalker = StalkerPortalClient(config);
        playlistUri = stalker.loadUri;
        playlistEntries = await stalker.channels();
      } else {
        playlistUri = config.playlistUri();
        transport.validate(playlistUri);
        final playlistBody = await transport.text(
          'GET',
          playlistUri,
          limit: maxPlaylistBytes,
          redirects: true,
          headers: const {'Accept': 'audio/x-mpegurl, application/vnd.apple.mpegurl, text/plain, */*'},
        );
        final playlist = IptvPlaylistParser.parse(playlistBody, base: playlistUri, allowHttp: config.allowHttp);
        if (playlist.isHls) throw const IptvImportException('playlist_is_stream');
        playlistEntries = playlist.entries;
        playlistGuideUri = playlist.guideUri;
      }

      final guideUris = <Uri>[];
      final primaryGuideUri = config.guideUri() ?? playlistGuideUri;
      if (primaryGuideUri != null) guideUris.add(primaryGuideUri);
      for (final address in config.additionalGuideEndpoints) {
        final uri = Uri.parse(address.trim());
        if (!guideUris.contains(uri)) guideUris.add(uri);
      }
      final programmes = <IptvXmltvProgramme>[];
      final guideLogos = <String, String>{};
      for (final guideUri in guideUris) {
        transport.validate(guideUri);
        final guideBody = await transport.text('GET', guideUri, limit: maxXmltvBytes, redirects: true);
        final guide = IptvXmltvParser.parse(guideBody, base: guideUri, allowHttp: config.allowHttp);
        if (programmes.length + guide.programmes.length > IptvXmltvParser.maxProgrammes) {
          throw const IptvImportException('invalid_data');
        }
        programmes.addAll(guide.programmes);
        for (final entry in guide.channelLogos.entries) {
          guideLogos.putIfAbsent(entry.key, () => entry.value);
        }
      }

      final overrideRows = await _database.customSelect(
        'SELECT channel_id, guide_id_override FROM iptv_channel_overrides WHERE profile_id=? AND source_id=?',
        variables: [Variable(profileId), Variable(sourceId)],
      ).get();
      final guideIdOverrides = {
        for (final row in overrideRows)
          row.read<String>('channel_id'): row.readNullable<String>('guide_id_override')?.trim(),
      };
      final effectiveTvgIds = <String, String?>{
        for (final channel in playlistEntries)
          channel.id: guideIdOverrides[channel.id]?.isNotEmpty == true ? guideIdOverrides[channel.id] : channel.tvgId,
      };
      final tvgToChannelId = <String, String>{};
      for (final channel in playlistEntries) {
        final tvgId = effectiveTvgIds[channel.id];
        if (tvgId != null) tvgToChannelId.putIfAbsent(tvgId, () => channel.id);
      }
      final mappedPrograms = <IptvProgrammeSnapshot>[
        for (final program in programmes)
          if (tvgToChannelId[program.channelTvgId] case final channelId?)
            IptvProgrammeSnapshot(
              channelId: channelId,
              beginsAt: program.beginsAt,
              endsAt: program.endsAt,
              title: program.title,
              summary: program.summary,
              category: program.category,
              episodeId: program.episodeId,
              thumb: program.thumb,
            ),
      ];
      final entries = [
        for (final channel in playlistEntries)
          IptvPlaylistEntry(
            id: channel.id,
            title: channel.title,
            streamUrl: channel.streamUrl,
            tvgId: channel.tvgId,
            number: channel.number,
            groupTitle: channel.groupTitle,
            logoUrl: channel.logoUrl ??
                (effectiveTvgIds[channel.id] == null ? null : guideLogos[effectiveTvgIds[channel.id]!]),
            radio: channel.radio,
            catchupSource: channel.catchupSource,
            catchupDays: channel.catchupDays,
            streamHeaders: channel.streamHeaders,
          ),
      ];
      return await _replaceSnapshot(source, entries, mappedPrograms);
    } on IptvImportException catch (error) {
      await _recordError(profileId, sourceId, error.code);
      rethrow;
    } on SourceException catch (error) {
      final code = switch (error.reason) {
        SourceFailure.authentication => 'authentication',
        SourceFailure.permission => 'permission',
        SourceFailure.invalidData => 'invalid_data',
        SourceFailure.cancelled => 'cancelled',
        _ => 'provider_unavailable',
      };
      await _recordError(profileId, sourceId, code);
      throw IptvImportException(code);
    } on Object {
      await _recordError(profileId, sourceId, 'provider_unavailable');
      throw const IptvImportException('provider_unavailable');
    } finally {
      stalker?.close();
      transport.close();
    }
  }

  Future<int> _replaceSnapshot(
    _StoredIptvSource expected,
    List<IptvPlaylistEntry> entries,
    List<IptvProgrammeSnapshot> programmes,
  ) async {
    final protectedStreams = await _mapInBatches(entries, (entry) => CredentialVault.protect(entry.streamUrl));
    final protectedCatchup = await _mapInBatches(
      entries,
      (entry) => entry.catchupSource == null ? Future<String?>.value(null) : CredentialVault.protect(entry.catchupSource!),
    );
    final protectedHeaders = await _mapInBatches(
      entries,
      (entry) => entry.streamHeaders.isEmpty
          ? Future<String?>.value(null)
          : CredentialVault.protect(jsonEncode(entry.streamHeaders)),
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.runIdentityMutation(() => _database.transaction(() async {
      final current = await _source(expected.profileId, expected.id);
      if (current == null || current.revision != expected.revision || current.generation != expected.generation) {
        throw const IptvImportException('source_changed');
      }
      await _database.customStatement('DELETE FROM iptv_programmes WHERE source_id=?', [expected.id]);
      await _database.customStatement('DELETE FROM iptv_channels WHERE source_id=?', [expected.id]);
      final channelRows = <List<Object?>>[];
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        channelRows.add([
          expected.id,
          entry.id,
          entry.title,
          entry.tvgId,
          entry.number,
          entry.groupTitle,
          entry.logoUrl,
          protectedCatchup[index],
          entry.catchupDays,
          protectedStreams[index],
          entry.radio ? 1 : 0,
          protectedHeaders[index],
          now,
        ]);
      }
      await _insertRows(
        table: 'iptv_channels',
        columns: const [
          'source_id',
          'channel_id',
          'title',
          'tvg_id',
          'number',
          'group_title',
          'logo_url',
          'catchup_source_ciphertext',
          'catchup_days',
          'stream_url_ciphertext',
          'is_radio',
          'stream_headers_ciphertext',
          'updated_at',
        ],
        rows: channelRows,
      );
      final programmeRows = [
        for (final item in programmes)
          [
            expected.id,
            item.channelId,
            item.beginsAt,
            item.endsAt,
            item.title,
            item.summary,
            item.category,
            item.episodeId,
            item.thumb,
          ],
      ];
      await _insertRows(
        table: 'iptv_programmes',
        columns: const [
          'source_id',
          'channel_id',
          'begins_at',
          'ends_at',
          'title',
          'summary',
          'category',
          'episode_id',
          'thumb_url',
        ],
        rows: programmeRows,
      );
      await _database.customStatement('''
        DELETE FROM iptv_channel_overrides
        WHERE source_id=? AND profile_id=?
          AND channel_id NOT IN (SELECT channel_id FROM iptv_channels WHERE source_id=?)
      ''', [expected.id, expected.profileId, expected.id]);
      await _database.customStatement('''
        UPDATE iptv_sources SET generation=generation+1, last_success_at=?, last_error_code=NULL
        WHERE id=? AND profile_id=? AND revision=? AND generation=?
      ''', [now, expected.id, expected.profileId, expected.revision, expected.generation]);
    }));
    return entries.length;
  }

  Future<void> _insertRows({required String table, required List<String> columns, required List<List<Object?>> rows}) async {
    if (rows.isEmpty) return;
    final rowsPerStatement = (900 ~/ columns.length).clamp(1, 100).toInt();
    for (var start = 0; start < rows.length; start += rowsPerStatement) {
      final chunk = rows.skip(start).take(rowsPerStatement).toList(growable: false);
      final rowPlaceholder = '(${List.filled(columns.length, '?').join(', ')})';
      final valuesClause = List.filled(chunk.length, rowPlaceholder).join(', ');
      final values = <Object?>[for (final row in chunk) ...row];
      await _database.customStatement(
        'INSERT OR IGNORE INTO $table(${columns.join(', ')}) VALUES $valuesClause',
        values,
      );
    }
  }

  Future<void> _replaceVodCategories(
    _StoredIptvSource expected,
    IptvVodKind kind,
    List<IptvVodCategory> categories,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.runIdentityMutation(() => _database.transaction(() async {
      final current = await _source(expected.profileId, expected.id);
      if (current == null || current.revision != expected.revision) {
        throw const IptvImportException('source_changed');
      }
      await _database.customStatement('DELETE FROM iptv_vod_categories WHERE source_id=? AND kind=?', [expected.id, kind.name]);
      if (categories.isNotEmpty) {
        await _insertRows(
          table: 'iptv_vod_categories',
          columns: const ['source_id', 'kind', 'category_id', 'name', 'updated_at'],
          rows: [for (final item in categories) [expected.id, kind.name, item.id, item.name, now]],
        );
      }
    }));
  }

  Future<void> _replaceVodItems(
    _StoredIptvSource expected,
    IptvVodKind kind,
    String? categoryId,
    List<IptvVodItem> items,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.runIdentityMutation(() => _database.transaction(() async {
      final current = await _source(expected.profileId, expected.id);
      if (current == null || current.revision != expected.revision) {
        throw const IptvImportException('source_changed');
      }
      if (categoryId == null) {
        await _database.customStatement('DELETE FROM iptv_vod_items WHERE source_id=? AND kind=?', [expected.id, kind.name]);
      } else {
        await _database.customStatement(
          'DELETE FROM iptv_vod_items WHERE source_id=? AND kind=? AND category_id=?',
          [expected.id, kind.name, categoryId],
        );
      }
      if (items.isNotEmpty) {
        await _insertRows(
          table: 'iptv_vod_items',
          columns: const [
            'source_id',
            'kind',
            'item_id',
            'category_id',
            'title',
            'plot',
            'year',
            'duration_seconds',
            'rating',
            'poster_url',
            'backdrop_url',
            'container_extension',
            'updated_at',
          ],
          rows: [
            for (final item in items)
              [
                expected.id,
                kind.name,
                item.id,
                item.categoryId,
                item.title,
                item.plot,
                item.year,
                item.durationSeconds,
                item.rating,
                item.posterUrl,
                item.backdropUrl,
                item.containerExtension,
                now,
              ],
          ],
        );
      }
    }));
  }

  Future<Object?> _xtreamJson(SourceTransport transport, Uri uri) async {
    transport.validate(uri);
    final body = await transport.text(
      'GET',
      uri,
      limit: 32 * 1024 * 1024,
      redirects: true,
      headers: const {'Accept': 'application/json, text/plain, */*'},
    );
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const IptvImportException('invalid_data');
    }
  }

  List<dynamic> _xtreamRows(Object? value) {
    if (value is List) return value;
    if (value is Map) {
      final map = sourceMap(value);
      for (final key in const ['data', 'results', 'streams', 'categories', 'series']) {
        if (map[key] is List) return map[key] as List;
      }
    }
    throw const IptvImportException('invalid_data');
  }

  void _appendEpisode(List<IptvVodEpisode> target, Object? raw, IptvSourceConfiguration config, int? seasonHint) {
    final row = sourceMap(raw);
    final id = _valueString(row, const ['id', 'stream_id', 'episode_id']);
    final title = _valueString(row, const ['title', 'name', 'episode_name']);
    if (id == null || title == null) return;
    final info = sourceMap(row['info']);
    final season = _valueInt(row, const ['season', 'season_number']) ?? seasonHint ?? 0;
    final episode = _valueInt(row, const ['episode_num', 'episode', 'episode_number', 'index']) ?? 0;
    target.add(
      IptvVodEpisode(
        id: id,
        title: _safeCatalogText(title, 240) ?? 'Episode',
        season: season.clamp(0, 999).toInt(),
        episode: episode.clamp(0, 9999).toInt(),
        plot: _safeCatalogText(_valueString(row, const ['plot', 'description']) ?? _valueString(info, const ['plot']), 4000),
        durationSeconds: _valueInt(row, const ['duration_secs', 'duration']) ??
            _durationSeconds(_valueString(info, const ['duration'])),
        posterUrl: _safeVodArtwork(
          _valueString(info, const ['movie_image', 'cover', 'cover_big']) ?? _valueString(row, const ['cover']),
          config,
        ),
        containerExtension: _iptvSafeExtension(
          _valueString(row, const ['container_extension']) ?? _valueString(info, const ['container_extension']) ?? 'mp4',
        ),
      ),
    );
  }

  String? _valueString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = '$value'.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null' && text != '0') return text;
    }
    return null;
  }

  String? _firstStringValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List && value.isNotEmpty && value.first is String) return (value.first as String).trim();
    }
    return null;
  }

  int? _valueInt(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  double? _valueDouble(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num && value.isFinite) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null && parsed.isFinite) return parsed;
      }
    }
    return null;
  }

  int? _durationSeconds(String? value) {
    if (value == null) return null;
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null || part < 0)) return int.tryParse(value);
    return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
  }

  String? _safeCatalogText(String? value, int maxLength) {
    final clean = value?.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (clean == null || clean.isEmpty) return null;
    return clean.length <= maxLength ? clean : clean.substring(0, maxLength);
  }

  String? _safeVodArtwork(String? raw, IptvSourceConfiguration config) {
    if (raw == null || raw.length > UniversalMediaAddress.maxLength) return null;
    try {
      final uri = UniversalMediaAddress.parse(raw, allowHttp: config.allowHttp, base: config.xtreamBaseUri);
      return uri.toString();
    } on Object {
      return null;
    }
  }

  String _iptvSafeExtension(String raw) {
    final value = raw.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
    return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(value) ? value : 'mp4';
  }

  String _iptvCodeForSourceFailure(SourceException error) => switch (error.reason) {
    SourceFailure.authentication => 'authentication',
    SourceFailure.permission => 'permission',
    SourceFailure.invalidData => 'invalid_data',
    SourceFailure.unsupported => 'unsupported',
    _ => 'provider_unavailable',
  };

  Future<List<R>> _mapInBatches<T, R>(List<T> values, Future<R> Function(T) resolve) async {
    const batchSize = 64;
    final result = <R>[];
    for (var start = 0; start < values.length; start += batchSize) {
      result.addAll(await Future.wait(values.skip(start).take(batchSize).map(resolve)));
    }
    return result;
  }

  Future<_StoredIptvSource?> _source(String profileId, String sourceId) async {
    final row = await _database.customSelect('''
      SELECT id, profile_id, display_name, kind, revision, generation, created_at, last_success_at, last_error_code
      FROM iptv_sources WHERE profile_id=? AND id=?
    ''', variables: [Variable(profileId), Variable(sourceId)]).getSingleOrNull();
    if (row == null) return null;
    return _StoredIptvSource(
      id: row.read<String>('id'),
      profileId: row.read<String>('profile_id'),
      displayName: row.read<String>('display_name'),
      kind: row.read<String>('kind'),
      revision: row.read<int>('revision'),
      generation: row.read<int>('generation'),
      createdAt: row.read<int>('created_at'),
      lastSuccessAt: row.readNullable<int>('last_success_at'),
      lastErrorCode: row.readNullable<String>('last_error_code'),
    );
  }

  String _catchupUrl(String template, LiveTvProgram program, IptvSourceConfiguration config) {
    final start = program.beginsAt;
    final end = program.endsAt;
    if (start == null || end == null || end <= start) throw const IptvImportException('catchup_unavailable');
    final duration = end - start;
    final startTime = _catchupTimestamp(start);
    final endTime = _catchupTimestamp(end);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final values = <String, String>{
      '{utcstart}': '$start',
      '{utcend}': '$end',
      '{utc}': '$start',
      '{lutc}': '$now',
      '{duration}': '$duration',
      '{start}': startTime,
      '{end}': endTime,
      '%s': '$start',
      '%Y': startTime.substring(0, 4),
      '%m': startTime.substring(4, 6),
      '%d': startTime.substring(6, 8),
      '%H': startTime.substring(8, 10),
      '%M': startTime.substring(10, 12),
      '%S': startTime.substring(12, 14),
    };
    var expanded = template;
    for (final entry in values.entries) {
      expanded = expanded.replaceAll(entry.key, entry.value);
    }
    try {
      return UniversalMediaAddress.parse(
        expanded,
        allowHttp: config.allowHttp,
        allowMpvProtocols: true,
        base: config.playlistUri(),
      ).toString();
    } on SourceException {
      throw const IptvImportException('catchup_unavailable');
    } on FormatException {
      throw const IptvImportException('catchup_unavailable');
    }
  }

  String _catchupTimestamp(int epochSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }

  Future<void> _recordError(String profileId, String sourceId, String code) async {
    try {
      await _database.runIdentityMutation(() => _database.customStatement(
        'UPDATE iptv_sources SET last_error_code=? WHERE profile_id=? AND id=?',
        [code, profileId, sourceId],
      ));
    } on Object {
      // A removed source is intentionally not recreated by a late failure.
    }
  }

  IptvInputKind _kind(String value) {
    try {
      return IptvInputKind.values.byName(value);
    } on ArgumentError {
      throw const IptvImportException('source_invalid');
    }
  }

  void _validate(IptvSourceConfiguration config) {
    if (config.profileId.isEmpty || config.displayName.isEmpty || config.displayName.length > 80) {
      throw const IptvImportException('source_invalid');
    }
    for (final value in [
      config.endpoint,
      if (config.guideEndpoint.isNotEmpty) config.guideEndpoint,
      ...config.additionalGuideEndpoints,
    ]) {
      final uri = Uri.tryParse(value);
      if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment || value.length > 4096) {
        throw const IptvImportException('source_invalid');
      }
      if (uri.scheme != 'https' && !(config.allowHttp && uri.scheme == 'http')) {
        throw const IptvImportException('http_not_allowed');
      }
      if (value == config.endpoint && config.kind == IptvInputKind.xtream && uri.queryParameters.keys.any((key) => key == 'password')) {
        throw const IptvImportException('source_invalid');
      }
    }
    if (config.kind == IptvInputKind.xtream && (config.username.isEmpty || config.password.isEmpty)) {
      throw const IptvImportException('source_invalid');
    }
    if (config.kind == IptvInputKind.dispatcharr && config.username.isNotEmpty != config.password.isNotEmpty) {
      throw const IptvImportException('source_invalid');
    }
    if (config.kind == IptvInputKind.stalker &&
        !RegExp(r'^(?:[0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(config.macAddress.trim().toUpperCase())) {
      throw const IptvImportException('source_invalid');
    }
    if (config.additionalGuideEndpoints.length > 8) throw const IptvImportException('source_invalid');
    final apiEndpoint = config.dispatcharrApiEndpoint.trim();
    final apiKey = config.dispatcharrApiKey.trim();
    if (apiEndpoint.isNotEmpty != apiKey.isNotEmpty) {
      throw const IptvImportException('source_invalid');
    }
    if (apiEndpoint.isNotEmpty) {
      if (config.kind != IptvInputKind.dispatcharr) throw const IptvImportException('source_invalid');
      final uri = Uri.tryParse(apiEndpoint);
      if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment || uri.hasQuery) {
        throw const IptvImportException('source_invalid');
      }
      if (uri.scheme != 'https' && !(config.allowHttp && uri.scheme == 'http')) {
        throw const IptvImportException('http_not_allowed');
      }
    }
  }
}

String iptvGroupLockKey(String? title) => title?.trim().toLowerCase() ?? '';

class _StoredIptvSource {
  const _StoredIptvSource({
    required this.id,
    required this.profileId,
    required this.displayName,
    required this.kind,
    required this.revision,
    required this.generation,
    required this.createdAt,
    this.lastSuccessAt,
    this.lastErrorCode,
  });

  final String id;
  final String profileId;
  final String displayName;
  final String kind;
  final int revision;
  final int generation;
  final int createdAt;
  final int? lastSuccessAt;
  final String? lastErrorCode;
}
