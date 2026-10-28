import 'dart:convert';
import 'dart:typed_data';

import '../../../models/trakt/trakt_movie_history_entry.dart';
import 'trakt_client.dart';

class TraktLetterboxdExportPart {
  final Uint8List bytes;
  final int entryCount;

  const TraktLetterboxdExportPart({required this.bytes, required this.entryCount});
}

class TraktLetterboxdExport {
  final int playCount;
  final int movieCount;
  final int skippedCount;
  final List<TraktLetterboxdExportPart> parts;

  const TraktLetterboxdExport({
    required this.playCount,
    required this.movieCount,
    required this.skippedCount,
    required this.parts,
  });
}

class TraktLetterboxdExportException implements Exception {
  final String message;
  final bool isSizeLimit;

  const TraktLetterboxdExportException(this.message, {this.isSizeLimit = false});

  @override
  String toString() => message;
}

/// Builds a local Letterboxd import CSV from Trakt movie history. No data is
/// uploaded; each output part stays below Letterboxd's documented file limit.
class TraktLetterboxdExportService {
  static const int _pageSize = 250;
  static const int _maxPages = 500;
  static const int maxPartSizeBytes = 950000;
  static const String _header = 'tmdbID,imdbID,Title,Year,WatchedDate,Rewatch\n';

  static Future<TraktLetterboxdExport> create(TraktClient client) async {
    final exportEndAt = DateTime.now().toUtc();
    final events = <TraktMovieHistoryEntry>[];
    final historyIds = <String>{};
    var skippedCount = 0;
    int? expectedPageCount;

    for (var pageNumber = 1; ; pageNumber++) {
      if (pageNumber > _maxPages) {
        throw const TraktLetterboxdExportException(
          'Trakt history exceeds the safe export page limit.',
          isSizeLimit: true,
        );
      }

      final page = await client.getMovieHistory(page: pageNumber, limit: _pageSize, endAt: exportEndAt);
      if (page.hasPaginationMetadata) {
        if (page.page != pageNumber || page.pageCount < pageNumber || page.pageCount < 1) {
          throw const TraktLetterboxdExportException('Trakt returned inconsistent history pagination.');
        }
        expectedPageCount ??= page.pageCount;
        if (page.pageCount != expectedPageCount || page.pageCount > _maxPages) {
          throw const TraktLetterboxdExportException(
            'Trakt history changed or exceeds the safe export page limit.',
            isSizeLimit: true,
          );
        }
      } else if (page.items.isNotEmpty && page.items.length < _pageSize) {
        throw const TraktLetterboxdExportException('Trakt omitted pagination metadata for a partial history page.');
      }

      if (page.items.isEmpty && page.hasMore) {
        throw const TraktLetterboxdExportException('Trakt returned an incomplete history page.');
      }

      for (final event in page.items) {
        final id = event.historyId?.trim();
        if (id == null || id.isEmpty) {
          skippedCount++;
          continue;
        }
        if (historyIds.add(id)) events.add(event);
      }

      if (page.hasPaginationMetadata) {
        if (pageNumber >= page.pageCount) break;
      } else if (page.items.length < _pageSize) {
        break;
      }
    }

    final exportRows = <_LetterboxdRow>[];
    final filmKeys = <String>{};
    for (final event in events) {
      final watchedAt = event.watchedAt;
      if (watchedAt == null) {
        skippedCount++;
        continue;
      }
      final title = event.title?.trim() ?? '';
      final imdbId = event.ids.imdb?.trim();
      final tmdbId = event.ids.tmdb;
      final hasSupportedId = (imdbId != null && imdbId.isNotEmpty) || (tmdbId != null && tmdbId > 0);
      if (title.isEmpty && !hasSupportedId) {
        skippedCount++;
        continue;
      }

      final filmKey = _filmKey(event, title, imdbId);
      filmKeys.add(filmKey);
      exportRows.add(
        _LetterboxdRow(
          historyId: event.historyId!,
          watchedAt: watchedAt,
          title: title,
          year: event.year,
          imdbId: imdbId == null || imdbId.isEmpty ? '' : imdbId,
          tmdbId: tmdbId == null || tmdbId <= 0 ? '' : tmdbId.toString(),
          filmKey: filmKey,
        ),
      );
    }

    exportRows.sort((left, right) {
      final byDate = left.watchedAt.compareTo(right.watchedAt);
      if (byDate != 0) return byDate;
      return left.historyId.compareTo(right.historyId);
    });

    final seenFilms = <String>{};
    final csvRows = <String>[];
    for (final row in exportRows) {
      final isRewatch = !seenFilms.add(row.filmKey);
      final localDate = row.watchedAt.toLocal();
      csvRows.add(
        [
          row.tmdbId,
          row.imdbId,
          _csvCell(row.title),
          row.year?.toString() ?? '',
          _csvCell(_dateOnly(localDate)),
          isRewatch ? 'true' : 'false',
        ].join(','),
      );
    }

    return TraktLetterboxdExport(
      playCount: csvRows.length,
      movieCount: filmKeys.length,
      skippedCount: skippedCount,
      parts: _splitIntoParts(csvRows),
    );
  }

  static String _filmKey(TraktMovieHistoryEntry event, String title, String? imdbId) {
    if (imdbId != null && imdbId.isNotEmpty) return 'imdb:${imdbId.toLowerCase()}';
    final tmdbId = event.ids.tmdb;
    if (tmdbId != null && tmdbId > 0) return 'tmdb:$tmdbId';
    final traktId = event.ids.trakt;
    if (traktId != null && traktId > 0) return 'trakt:$traktId';
    final slug = event.ids.slug?.trim().toLowerCase();
    if (slug != null && slug.isNotEmpty) return 'slug:$slug';
    return 'title:${title.toLowerCase()}:${event.year ?? ''}';
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _csvCell(String value) {
    if (!value.contains(RegExp(r'[,"\r\n]'))) return value;
    return '"${value.replaceAll('"', r'\"')}"';
  }

  static List<TraktLetterboxdExportPart> _splitIntoParts(List<String> rows) {
    if (rows.isEmpty) return const [];

    final headerBytes = utf8.encode(_header).length;
    var current = StringBuffer(_header);
    var currentBytes = headerBytes;
    var currentEntries = 0;
    final parts = <TraktLetterboxdExportPart>[];

    void finishPart() {
      parts.add(
        TraktLetterboxdExportPart(
          bytes: Uint8List.fromList(utf8.encode(current.toString())),
          entryCount: currentEntries,
        ),
      );
      current = StringBuffer(_header);
      currentBytes = headerBytes;
      currentEntries = 0;
    }

    for (final row in rows) {
      final line = '$row\n';
      final lineBytes = utf8.encode(line).length;
      if (currentBytes + lineBytes > maxPartSizeBytes && currentEntries > 0) {
        finishPart();
      }
      if (currentBytes + lineBytes > maxPartSizeBytes) {
        throw const TraktLetterboxdExportException(
          'A single history row exceeds the import-file size limit.',
          isSizeLimit: true,
        );
      }
      current.write(line);
      currentBytes += lineBytes;
      currentEntries++;
    }

    if (currentEntries > 0) {
      parts.add(
        TraktLetterboxdExportPart(
          bytes: Uint8List.fromList(utf8.encode(current.toString())),
          entryCount: currentEntries,
        ),
      );
    }
    return parts;
  }
}

class _LetterboxdRow {
  final String historyId;
  final DateTime watchedAt;
  final String title;
  final int? year;
  final String imdbId;
  final String tmdbId;
  final String filmKey;

  const _LetterboxdRow({
    required this.historyId,
    required this.watchedAt,
    required this.title,
    required this.year,
    required this.imdbId,
    required this.tmdbId,
    required this.filmKey,
  });
}
