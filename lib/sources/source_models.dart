import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

enum FileSourceKind { local, webdav, smb, ftp, sftp, nfs, dlna, googleDrive, oneDrive, dropbox, s3, opds, audiobookshelf, komga }

enum SourceItemKind { folder, ebook, audiobook, comic, music, video, unknown }

enum PublicationMode { reading, listening, watching }

enum SourceFailure { authentication, permission, unavailable, unsupported, invalidData, cancelled, conflict }

/// Deliberately carries no URL, token or provider response into UI/logging.
class SourceException implements Exception {
  const SourceException(this.reason, {this.status});
  final SourceFailure reason;
  final int? status;
  @override
  String toString() => 'SourceException(${reason.name}, $status)';
}

String sourceKey(String sourceId, String itemId) => jsonEncode([sourceId, itemId]);
String sourceDigest(String value) => sha256.convert(utf8.encode(value)).toString();

Map<String, dynamic> sourceMap(Object? value) => value is Map ? Map<String, dynamic>.from(value) : {};
List<dynamic> sourceList(Object? value) => value is List ? value : const [];
int? sourceInt(Object? value) => value is num ? value.toInt() : int.tryParse('$value');

/// Signed acquisition URLs are transient. Public connection/catalogue records
/// must not accidentally retain credentials pasted into a URL.
final sourceCredentialParameter = RegExp(
  r'(token|password|signature|credential|authorization|secret|api[_-]?key|^auth$|^key$|^code$|x-amz-|x-goog-|^(expires|expiry|expiration|policy|key-pair-id|sig|se|sp|sv|sr|st|skoid|sktid|skt|ske|sks|skv|rscc|rscd|rsct)$)',
  caseSensitive: false,
);

void validatePublicSourceUri(Uri uri, {bool allowHttp = false}) {
  if (uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      (uri.scheme != 'https' && !(allowHttp && uri.scheme == 'http')) ||
      uri.queryParameters.keys.any(sourceCredentialParameter.hasMatch)) {
    throw const SourceException(SourceFailure.permission);
  }
}

/// SMB endpoints identify one server share. Credentials stay in the encrypted
/// vault, and the default port is enforced until custom ports are supported.
Uri validateSmbSourceEndpoint(String value) {
  final schemeEnd = value.indexOf('://');
  String rawPath = '';
  if (schemeEnd >= 0) {
    final pathStart = value.indexOf('/', schemeEnd + 3);
    if (pathStart >= 0) {
      final pathEnd = value.indexOf(RegExp(r'[?#]'), pathStart);
      rawPath = value.substring(pathStart + 1, pathEnd < 0 ? value.length : pathEnd);
    }
  }
  var unsafeRawSegment = false;
  for (final segment in rawPath.split('/').where((part) => part.isNotEmpty)) {
    try {
      final decoded = Uri.decodeComponent(segment);
      if (decoded == '.' ||
          decoded == '..' ||
          decoded.contains('/') ||
          decoded.contains('\\') ||
          decoded.contains('\u0000')) {
        unsafeRawSegment = true;
        break;
      }
    } on FormatException {
      unsafeRawSegment = true;
      break;
    }
  }
  final uri = Uri.tryParse(value);
  final shares = uri?.pathSegments.where((segment) => segment.isNotEmpty).toList() ?? const <String>[];
  if (unsafeRawSegment ||
      uri == null ||
      uri.scheme != 'smb' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.hasPort && uri.port != 445) ||
      shares.length != 1 ||
      shares.any(
        (segment) =>
            segment == '.' ||
            segment == '..' ||
            segment.contains('/') ||
            segment.contains('\\') ||
            segment.contains('\u0000'),
      )) {
    throw const SourceException(SourceFailure.permission);
  }
  return uri;
}

class FileSource {
  const FileSource({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.name,
    this.endpoint = '',
    this.root = '',
    this.options = const {},
  });
  final String id;
  final String profileId;
  final FileSourceKind kind;
  final String name;
  final String endpoint;
  final String root;

  /// Public configuration only. Credentials are a separate encrypted record.
  final Map<String, String> options;

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'kind': kind.name,
    'name': name,
    'endpoint': endpoint,
    'root': root,
    'options': options,
  };
  factory FileSource.fromJson(Map<String, dynamic> json) => FileSource(
    id: json['id'] as String,
    profileId: json['profileId'] as String,
    kind: FileSourceKind.values.byName(json['kind'] as String),
    name: json['name'] as String,
    endpoint: json['endpoint'] as String? ?? '',
    root: json['root'] as String? ?? '',
    options: sourceMap(json['options']).map((key, value) => MapEntry(key, '$value')),
  );
}

class SourceCapabilities {
  const SourceCapabilities({
    this.search = false,
    this.audioProgress = false,
    this.readingProgress = false,
    this.annotations = false,
    this.rangeRequests = true,
    this.writableState = false,
  });
  final bool search;
  final bool audioProgress;
  final bool readingProgress;
  final bool annotations;
  final bool rangeRequests;
  final bool writableState;
}

class PublicationFile {
  const PublicationFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.size,
    this.revision,
    this.durationMs,
    this.primary = true,
    this.streamOnly = false,
  });
  final String id;
  final String name;
  final String mimeType;
  final int? size;
  final String? revision;
  final int? durationMs;
  final bool primary;
  final bool streamOnly;
  SourceItemKind get kind => classifySourceFile(name, mimeType);
  // Preserve the historical identity for archived files; only stream-only
  // representations need the extra discriminator.
  String get fingerprint => sourceDigest(jsonEncode([id, revision, size, if (streamOnly) true]));
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mimeType': mimeType,
    'size': size,
    'revision': revision,
    'durationMs': durationMs,
    'primary': primary,
    'streamOnly': streamOnly,
  };
  factory PublicationFile.fromJson(Map<String, dynamic> j) => PublicationFile(
    id: j['id'] as String,
    name: j['name'] as String,
    mimeType: j['mimeType'] as String? ?? '',
    size: sourceInt(j['size']),
    revision: j['revision'] as String?,
    durationMs: sourceInt(j['durationMs']),
    primary: j['primary'] as bool? ?? true,
    streamOnly: j['streamOnly'] as bool? ?? false,
  );
}

class BookChapter {
  const BookChapter({required this.title, required this.startMs, required this.endMs});
  final String title;
  final int startMs;
  final int endMs;
  Map<String, dynamic> toJson() => {'title': title, 'startMs': startMs, 'endMs': endMs};
  factory BookChapter.fromJson(Map<String, dynamic> j) => BookChapter(
    title: j['title'] as String? ?? '',
    startMs: sourceInt(j['startMs']) ?? 0,
    endMs: sourceInt(j['endMs']) ?? 0,
  );
}

/// A catalog entry may contain multiple editions. File identity, rather than
/// display title or work grouping, owns progress and annotations.
class SourceEntry {
  const SourceEntry({
    required this.sourceId,
    required this.id,
    required this.title,
    required this.kind,
    this.parentId,
    this.author = '',
    this.narrator = '',
    this.series = '',
    this.seriesOrder,
    this.description = '',
    this.language = '',
    this.coverId,
    this.files = const [],
    this.chapters = const [],
    this.identifiers = const {},
    this.releaseYear,
    this.rating,
    this.genres = const [],
    this.syncIdentity,
    this.onlineTitle,
    this.onlinePosterUrl,
    this.trailerUrl,
    this.cast = const [],
    this.onlineMetadataProvider,
    this.onlineMetadataCheckedAt,
  });
  final String sourceId;
  final String id;
  final String title;
  final SourceItemKind kind;
  final String? parentId;
  final String author;
  final String narrator;
  final String series;
  final double? seriesOrder;
  final String description;
  final String language;
  final String? coverId;
  final List<PublicationFile> files;
  final List<BookChapter> chapters;
  final Map<String, String> identifiers;
  final int? releaseYear;
  final double? rating;
  final List<String> genres;
  final String? syncIdentity;
  final String? onlineTitle;
  final String? onlinePosterUrl;
  final String? trailerUrl;
  final List<String> cast;
  final String? onlineMetadataProvider;
  final int? onlineMetadataCheckedAt;

  SourceEntry copyWith({
    String? parentId,
    String? title,
    String? description,
    String? coverId,
    int? releaseYear,
    double? rating,
    List<String>? genres,
    Map<String, String>? identifiers,
    String? syncIdentity,
    String? onlineTitle,
    String? onlinePosterUrl,
    String? trailerUrl,
    List<String>? cast,
    String? onlineMetadataProvider,
    int? onlineMetadataCheckedAt,
  }) => SourceEntry(
    sourceId: sourceId,
    id: id,
    title: title ?? this.title,
    kind: kind,
    parentId: parentId ?? this.parentId,
    author: author,
    narrator: narrator,
    series: series,
    seriesOrder: seriesOrder,
    description: description ?? this.description,
    language: language,
    coverId: coverId ?? this.coverId,
    files: files,
    chapters: chapters,
    identifiers: identifiers ?? this.identifiers,
    releaseYear: releaseYear ?? this.releaseYear,
    rating: rating ?? this.rating,
    genres: genres ?? this.genres,
    syncIdentity: syncIdentity ?? this.syncIdentity,
    onlineTitle: onlineTitle ?? this.onlineTitle,
    onlinePosterUrl: onlinePosterUrl ?? this.onlinePosterUrl,
    trailerUrl: trailerUrl ?? this.trailerUrl,
    cast: cast ?? this.cast,
    onlineMetadataProvider: onlineMetadataProvider ?? this.onlineMetadataProvider,
    onlineMetadataCheckedAt: onlineMetadataCheckedAt ?? this.onlineMetadataCheckedAt,
  );

  String get key => sourceKey(sourceId, id);
  bool get isFolder => kind == SourceItemKind.folder;

  /// Video source names begin as filenames. Keep their descriptive stem while
  /// omitting only the container extension in user-facing titles.
  String get displayTitle {
    if (kind != SourceItemKind.video) return title;
    // Offline NFO titles stay authoritative; online matching only replaces the
    // original filename stem when no richer local title was supplied.
    final filename = files.firstOrNull?.name;
    final isFilename = filename == null || filename == title;
    final matched = onlineTitle?.trim();
    if (isFilename && matched?.isNotEmpty == true) return matched!;
    return isFilename ? p.withoutExtension(title) : title;
  }

  List<PublicationFile> get ebooks =>
      files.where((f) => (f.kind == SourceItemKind.ebook || f.kind == SourceItemKind.comic)).toList();
  List<PublicationFile> get audio =>
      files.where((f) => f.kind == SourceItemKind.music || f.kind == SourceItemKind.audiobook).toList();
  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'id': id,
    'title': title,
    'kind': kind.name,
    'parentId': parentId,
    'author': author,
    'narrator': narrator,
    'series': series,
    'seriesOrder': seriesOrder,
    'description': description,
    'language': language,
    'coverId': coverId,
    'files': files.map((f) => f.toJson()).toList(),
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'identifiers': identifiers,
    if (releaseYear != null) 'releaseYear': releaseYear,
    if (rating != null) 'rating': rating,
    if (genres.isNotEmpty) 'genres': genres,
    if (syncIdentity != null) 'syncIdentity': syncIdentity,
    if (onlineTitle != null) 'onlineTitle': onlineTitle,
    if (onlinePosterUrl != null) 'onlinePosterUrl': onlinePosterUrl,
    if (trailerUrl != null) 'trailerUrl': trailerUrl,
    if (cast.isNotEmpty) 'cast': cast,
    if (onlineMetadataProvider != null) 'onlineMetadataProvider': onlineMetadataProvider,
    if (onlineMetadataCheckedAt != null) 'onlineMetadataCheckedAt': onlineMetadataCheckedAt,
  };
  factory SourceEntry.fromJson(Map<String, dynamic> j) => SourceEntry(
    sourceId: j['sourceId'] as String,
    id: j['id'] as String,
    title: j['title'] as String,
    kind: SourceItemKind.values.byName(j['kind'] as String),
    parentId: j['parentId'] as String?,
    author: j['author'] as String? ?? '',
    narrator: j['narrator'] as String? ?? '',
    series: j['series'] as String? ?? '',
    seriesOrder: (j['seriesOrder'] as num?)?.toDouble(),
    description: j['description'] as String? ?? '',
    language: j['language'] as String? ?? '',
    coverId: j['coverId'] as String?,
    files: sourceList(j['files']).map((f) => PublicationFile.fromJson(sourceMap(f))).toList(),
    chapters: sourceList(j['chapters']).map((c) => BookChapter.fromJson(sourceMap(c))).toList(),
    identifiers: sourceMap(j['identifiers']).map((k, v) => MapEntry(k, '$v')),
    releaseYear: sourceInt(j['releaseYear']),
    rating: (j['rating'] as num?)?.toDouble(),
    genres: sourceList(j['genres']).whereType<String>().toList(),
    syncIdentity: j['syncIdentity'] as String?,
    onlineTitle: j['onlineTitle'] as String?,
    onlinePosterUrl: j['onlinePosterUrl'] as String?,
    trailerUrl: j['trailerUrl'] as String?,
    cast: sourceList(j['cast']).whereType<String>().toList(),
    onlineMetadataProvider: j['onlineMetadataProvider'] as String?,
    onlineMetadataCheckedAt: sourceInt(j['onlineMetadataCheckedAt']),
  );
}

class SourcePage {
  const SourcePage(this.entries, {this.next, this.title});
  final List<SourceEntry> entries;
  final String? next;
  final String? title;
}

/// Ephemeral. Never serialized, cached in catalog records, or sent to OS media
/// metadata. A lease can be renewed before each range request.
class ContentLease {
  const ContentLease(this.uri, {this.headers = const {}, this.expiresAt, this.size});
  final Uri uri;
  final Map<String, String> headers;
  final DateTime? expiresAt;
  final int? size;
}

/// Provider-native byte stream for sources without an HTTP media URL.
class SourceByteStream {
  const SourceByteStream({required this.stream, required this.size, required this.offset, required this.length});
  final Stream<List<int>> stream;
  final int size;
  final int offset;
  final int length;
}

class ReadingLocator {
  const ReadingLocator({required this.href, this.cfi, this.progression = 0, this.page, this.text = ''});
  final String href;
  final String? cfi;
  final double progression;
  final int? page;
  final String text;
  Map<String, dynamic> toJson() => {'href': href, 'cfi': cfi, 'progression': progression, 'page': page, 'text': text};
  factory ReadingLocator.fromJson(Map<String, dynamic> j) => ReadingLocator(
    href: j['href'] as String? ?? '',
    cfi: j['cfi'] as String?,
    progression: ((j['progression'] as num?)?.toDouble() ?? 0).clamp(0, 1),
    page: sourceInt(j['page']),
    text: j['text'] as String? ?? '',
  );
}

class PublicationProgress {
  const PublicationProgress({
    required this.entryKey,
    required this.edition,
    required this.mode,
    required this.session,
    this.revision = 0,
    this.positionMs = 0,
    this.filePositionMs = 0,
    this.fileIndex = 0,
    this.locator,
    this.fraction = 0,
    this.finished = false,
    this.speed = 1,
    this.updatedAt = 0,
  });
  final String entryKey;
  final String edition;
  final PublicationMode mode;
  final String session;
  final int revision;

  /// Source time, unaffected by listening speed or silence processing.
  final int positionMs;

  /// Explicit file-relative cursor also works before all durations are known.
  final int filePositionMs;
  final int fileIndex;
  final ReadingLocator? locator;
  final double fraction;
  final bool finished;
  final double speed;
  final int updatedAt;
  String get key => jsonEncode([entryKey, edition, mode.name]);
  PublicationProgress copyWith({
    int? revision,
    int? positionMs,
    int? filePositionMs,
    int? fileIndex,
    ReadingLocator? locator,
    double? fraction,
    bool? finished,
    double? speed,
    int? updatedAt,
    String? session,
  }) => PublicationProgress(
    entryKey: entryKey,
    edition: edition,
    mode: mode,
    session: session ?? this.session,
    revision: revision ?? this.revision,
    positionMs: positionMs ?? this.positionMs,
    filePositionMs: filePositionMs ?? this.filePositionMs,
    fileIndex: fileIndex ?? this.fileIndex,
    locator: locator ?? this.locator,
    fraction: fraction ?? this.fraction,
    finished: finished ?? this.finished,
    speed: speed ?? this.speed,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Map<String, dynamic> toJson() => {
    'entryKey': entryKey,
    'edition': edition,
    'mode': mode.name,
    'session': session,
    'revision': revision,
    'positionMs': positionMs,
    'fileIndex': fileIndex,
    'filePositionMs': filePositionMs,
    'locator': locator?.toJson(),
    'fraction': fraction,
    'finished': finished,
    'speed': speed,
    'updatedAt': updatedAt,
  };
  factory PublicationProgress.fromJson(Map<String, dynamic> j) => PublicationProgress(
    entryKey: j['entryKey'] as String,
    edition: j['edition'] as String,
    mode: PublicationMode.values.byName(j['mode'] as String),
    session: j['session'] as String,
    revision: sourceInt(j['revision']) ?? 0,
    positionMs: sourceInt(j['positionMs']) ?? 0,
    fileIndex: sourceInt(j['fileIndex']) ?? 0,
    filePositionMs: sourceInt(j['filePositionMs']) ?? sourceInt(j['positionMs']) ?? 0,
    locator: j['locator'] == null ? null : ReadingLocator.fromJson(sourceMap(j['locator'])),
    fraction: ((j['fraction'] as num?)?.toDouble() ?? 0).clamp(0, 1),
    finished: j['finished'] as bool? ?? false,
    speed: ((j['speed'] as num?)?.toDouble() ?? 1).clamp(.25, 8),
    updatedAt: sourceInt(j['updatedAt']) ?? 0,
  );
}

class BookAnnotation {
  const BookAnnotation({
    required this.id,
    required this.entryKey,
    required this.edition,
    required this.mode,
    this.locator,
    this.positionMs,
    this.fileIndex,
    this.filePositionMs,
    this.quote = '',
    this.note = '',
    this.color = 'yellow',
    required this.updatedAt,
    this.deleted = false,
  });
  final String id;
  final String entryKey;
  final String edition;
  final PublicationMode mode;
  final ReadingLocator? locator;
  final int? positionMs;
  final int? fileIndex;
  final int? filePositionMs;
  final String quote;
  final String note;
  final String color;
  final int updatedAt;
  final bool deleted;
  Map<String, dynamic> toJson() => {
    'id': id,
    'entryKey': entryKey,
    'edition': edition,
    'mode': mode.name,
    'locator': locator?.toJson(),
    'positionMs': positionMs,
    'fileIndex': fileIndex,
    'filePositionMs': filePositionMs,
    'quote': quote,
    'note': note,
    'color': color,
    'updatedAt': updatedAt,
    'deleted': deleted,
  };
  factory BookAnnotation.fromJson(Map<String, dynamic> j) => BookAnnotation(
    id: j['id'] as String,
    entryKey: j['entryKey'] as String,
    edition: j['edition'] as String,
    mode: PublicationMode.values.byName(j['mode'] as String),
    locator: j['locator'] == null ? null : ReadingLocator.fromJson(sourceMap(j['locator'])),
    positionMs: sourceInt(j['positionMs']),
    fileIndex: sourceInt(j['fileIndex']),
    filePositionMs: sourceInt(j['filePositionMs']),
    quote: j['quote'] as String? ?? '',
    note: j['note'] as String? ?? '',
    color: j['color'] as String? ?? 'yellow',
    updatedAt: sourceInt(j['updatedAt']) ?? 0,
    deleted: j['deleted'] as bool? ?? false,
  );
}

SourceItemKind classifySourceFile(String name, [String mime = '']) {
  final ext = p.extension(name.split('?').first).toLowerCase();
  if (ext == '.cbz' || mime == 'application/vnd.comicbook+zip') return SourceItemKind.comic;
  if (const {'.epub', '.pdf'}.contains(ext) || const {'application/epub+zip', 'application/pdf'}.contains(mime)) {
    return SourceItemKind.ebook;
  }
  if (ext == '.m4b') return SourceItemKind.audiobook;
  if (mime.startsWith('audio/') ||
      const {'.mp3', '.m4a', '.aac', '.flac', '.ogg', '.opus', '.wav', '.aiff', '.alac'}.contains(ext)) {
    return SourceItemKind.music;
  }
  if (mime.startsWith('video/') ||
      const {'.mp4', '.mkv', '.mov', '.avi', '.webm', '.m4v', '.ts', '.mpeg', '.mpg'}.contains(ext)) {
    return SourceItemKind.video;
  }
  return SourceItemKind.unknown;
}
