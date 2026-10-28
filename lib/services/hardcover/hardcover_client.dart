import 'dart:convert';

import 'package:http/http.dart' as http;

import '../book_identifiers.dart';
import '../../sources/source_models.dart';

const _hardcoverGraphqlEndpoint = 'https://api.hardcover.app/v1/graphql';

class HardcoverAccount {
  const HardcoverAccount({required this.id, required this.username, required this.name});

  final int id;
  final String username;
  final String name;

  String get displayName => name.trim().isNotEmpty ? name : username;

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'name': name};

  factory HardcoverAccount.fromJson(Map<String, dynamic> json) => HardcoverAccount(
    id: sourceInt(json['id']) ?? 0,
    username: json['username'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
}

class HardcoverStatus {
  const HardcoverStatus({required this.id, required this.status, required this.slug});

  final int id;
  final String status;
  final String slug;

  String get normalized => '${slug.trim()} ${status.trim()}'.toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ');

  Map<String, dynamic> toJson() => {'id': id, 'status': status, 'slug': slug};

  factory HardcoverStatus.fromJson(Map<String, dynamic> json) => HardcoverStatus(
    id: sourceInt(json['id']) ?? 0,
    status: json['status'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
  );
}

class HardcoverRead {
  const HardcoverRead({
    this.id,
    this.editionId,
    this.startedAt,
    this.finishedAt,
    this.progressPages,
    this.progressSeconds,
  });

  final int? id;
  final int? editionId;
  final String? startedAt;
  final String? finishedAt;
  final int? progressPages;
  final int? progressSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'editionId': editionId,
    'startedAt': startedAt,
    'finishedAt': finishedAt,
    'progressPages': progressPages,
    'progressSeconds': progressSeconds,
  };

  factory HardcoverRead.fromJson(Map<String, dynamic> json) => HardcoverRead(
    id: sourceInt(json['id']),
    editionId: sourceInt(json['editionId'] ?? json['edition_id']),
    startedAt: json['startedAt'] as String? ?? json['started_at'] as String?,
    finishedAt: json['finishedAt'] as String? ?? json['finished_at'] as String?,
    progressPages: sourceInt(json['progressPages'] ?? json['progress_pages']),
    progressSeconds: sourceInt(json['progressSeconds'] ?? json['progress_seconds']),
  );
}

class HardcoverEditionMatch {
  const HardcoverEditionMatch({
    required this.editionId,
    required this.bookId,
    required this.title,
    required this.isbn,
  });

  final int editionId;
  final int bookId;
  final String title;
  final String isbn;

  factory HardcoverEditionMatch.fromApi(Map<String, dynamic> json, String isbn) {
    final book = sourceMap(json['book']);
    return HardcoverEditionMatch(
      editionId: sourceInt(json['id']) ?? 0,
      bookId: sourceInt(json['book_id']) ?? sourceInt(book['id']) ?? 0,
      title: book['title'] as String? ?? '',
      isbn: isbn,
    );
  }
}

class HardcoverBookRecord {
  const HardcoverBookRecord({
    required this.userBookId,
    required this.bookId,
    required this.statusId,
    this.editionId,
    this.editionPages,
    required this.title,
    required this.identifiers,
    this.rating,
    this.updatedAt,
    this.status,
    this.read,
    this.recentRead,
  });

  final int userBookId;
  final int bookId;
  final int statusId;
  final int? editionId;
  final int? editionPages;
  final String title;
  final Map<String, String> identifiers;
  final double? rating;
  final String? updatedAt;
  final HardcoverStatus? status;
  final HardcoverRead? read;
  final HardcoverRead? recentRead;

  Map<String, dynamic> toJson() => {
    'userBookId': userBookId,
    'bookId': bookId,
    'statusId': statusId,
    'editionId': editionId,
    'editionPages': editionPages,
    'title': title,
    'identifiers': identifiers,
    'rating': rating,
    'updatedAt': updatedAt,
    'status': status?.toJson(),
    'read': read?.toJson(),
    'recentRead': recentRead?.toJson(),
  };

  factory HardcoverBookRecord.fromJson(Map<String, dynamic> json) => HardcoverBookRecord(
    userBookId: sourceInt(json['userBookId']) ?? 0,
    bookId: sourceInt(json['bookId']) ?? 0,
    statusId: sourceInt(json['statusId']) ?? 0,
    editionId: sourceInt(json['editionId'] ?? json['edition_id']),
    editionPages: sourceInt(json['editionPages'] ?? json['edition_pages']),
    title: json['title'] as String? ?? '',
    identifiers: sourceMap(json['identifiers']).map((key, value) => MapEntry(key, '$value')),
    rating: (json['rating'] as num?)?.toDouble(),
    updatedAt: json['updatedAt'] as String?,
    status: json['status'] is Map ? HardcoverStatus.fromJson(sourceMap(json['status'])) : null,
    read: json['read'] is Map ? HardcoverRead.fromJson(sourceMap(json['read'])) : null,
    recentRead: json['recentRead'] is Map ? HardcoverRead.fromJson(sourceMap(json['recentRead'])) : null,
  );

  factory HardcoverBookRecord.fromApi(Map<String, dynamic> json) {
    final book = sourceMap(json['book']);
    final edition = sourceMap(json['edition']);
    final identifiers = <String, String>{};
    void addIdentifiers(Map<String, dynamic> source) {
      for (final key in const ['isbn_10', 'isbn_13']) {
        final value = source[key];
        if (value is String && value.trim().isNotEmpty) identifiers[key == 'isbn_10' ? 'isbn10' : 'isbn13'] = value;
      }
    }

    // Match only the exact edition in the user's Hardcover shelf. ISBNs from
    // sibling editions on the parent book could point at a different format.
    addIdentifiers(edition);
    final activeReads = sourceList(json['active_reads'] ?? json['user_book_reads']).map(sourceMap).toList();
    final recentReads = sourceList(json['latest_reads']).map(sourceMap).toList();
    final status = json['user_book_status'] is Map ? HardcoverStatus.fromJson(sourceMap(json['user_book_status'])) : null;
    return HardcoverBookRecord(
      userBookId: sourceInt(json['id']) ?? 0,
      bookId: sourceInt(json['book_id']) ?? sourceInt(book['id']) ?? 0,
      statusId: sourceInt(json['status_id']) ?? status?.id ?? 0,
      editionId: sourceInt(json['edition_id']) ?? sourceInt(edition['id']),
      editionPages: sourceInt(edition['pages']),
      title: book['title'] as String? ?? '',
      identifiers: Map.unmodifiable(identifiers),
      rating: (json['rating'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] as String?,
      status: status,
      read: activeReads.isEmpty ? null : HardcoverRead.fromJson(activeReads.first),
      recentRead: recentReads.isEmpty
          ? (activeReads.isEmpty ? null : HardcoverRead.fromJson(activeReads.first))
          : HardcoverRead.fromJson(recentReads.first),
    );
  }
}

/// Thin GraphQL client for the official Hardcover API. It accepts only the
/// user's Personal API token and never includes request/response bodies in
/// errors or logs.
class HardcoverClient {
  HardcoverClient({required String token, http.Client? client}) : _token = _cleanToken(token), _client = client ?? http.Client();

  final String _token;
  final http.Client _client;
  bool _disposed = false;

  static String _cleanToken(String token) {
    final value = token.trim();
    if (value.isEmpty || value.length > 4096 || value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw const SourceException(SourceFailure.authentication);
    }
    return value;
  }

  Future<Map<String, dynamic>> _query(String query, [Map<String, Object?> variables = const {}]) async {
    if (_disposed) throw const SourceException(SourceFailure.cancelled);
    try {
      final response = await _client
          .post(
            Uri.parse(_hardcoverGraphqlEndpoint),
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'PlezyNG',
            },
            body: jsonEncode({'query': query, 'variables': variables}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 401) throw const SourceException(SourceFailure.authentication, status: 401);
      if (response.statusCode == 403) throw const SourceException(SourceFailure.permission, status: 403);
      if (response.statusCode == 429) throw const SourceException(SourceFailure.unavailable, status: 429);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SourceException(SourceFailure.unavailable, status: response.statusCode);
      }
      if (response.bodyBytes.length > 8 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
      final root = sourceMap(jsonDecode(utf8.decode(response.bodyBytes)));
      if (sourceList(root['errors']).isNotEmpty) throw const SourceException(SourceFailure.invalidData);
      final data = sourceMap(root['data']);
      if (data.isEmpty) throw const SourceException(SourceFailure.invalidData);
      return data;
    } on SourceException {
      rethrow;
    } on FormatException {
      throw const SourceException(SourceFailure.invalidData);
    } on Object {
      throw const SourceException(SourceFailure.unavailable);
    }
  }

  Future<HardcoverAccount> account() async {
    final data = await _query('''
query HardcoverMe {
  me(limit: 1) { id username name }
}
''');
    final users = sourceList(data['me']);
    if (users.isEmpty) throw const SourceException(SourceFailure.authentication);
    final user = sourceMap(users.first);
    final account = HardcoverAccount.fromJson(user);
    if (account.id <= 0 || account.username.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return account;
  }

  Future<List<HardcoverStatus>> statuses() async {
    final data = await _query('''
query HardcoverStatuses {
  user_book_statuses { id status slug }
}
''');
    return sourceList(data['user_book_statuses'])
        .map((value) => HardcoverStatus.fromJson(sourceMap(value)))
        .where((status) => status.id > 0 && status.normalized.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<HardcoverBookRecord?> userBook({required int userId, required int userBookId}) async {
    if (userId <= 0 || userBookId <= 0) throw const SourceException(SourceFailure.invalidData);
    const query = '''
query HardcoverUserBook(\$userId: Int!, \$id: Int!) {
  user_books(where: {user_id: {_eq: \$userId}, id: {_eq: \$id}}, limit: 1) {
    id book_id edition_id status_id rating updated_at
    user_book_status { id status slug }
    book { id title }
    edition { id isbn_10 isbn_13 pages }
    active_reads: user_book_reads(where: {finished_at: {_is_null: true}}, order_by: {id: desc}, limit: 1) {
      id edition_id started_at finished_at progress_pages progress_seconds
    }
    latest_reads: user_book_reads(order_by: {id: desc}, limit: 1) {
      id edition_id started_at finished_at progress_pages progress_seconds
    }
  }
}
''';
    final data = await _query(query, {'userId': userId, 'id': userBookId});
    final rows = sourceList(data['user_books']);
    if (rows.isEmpty) return null;
    if (rows.length != 1) throw const SourceException(SourceFailure.invalidData);
    return HardcoverBookRecord.fromApi(sourceMap(rows.single));
  }

  Future<List<HardcoverBookRecord>> library(int userId) async {
    if (userId <= 0) throw const SourceException(SourceFailure.invalidData);
    const query = '''
query HardcoverLibrary(\$userId: Int!, \$limit: Int!, \$offset: Int!) {
  user_books(
    where: {user_id: {_eq: \$userId}}
    order_by: {id: asc}
    limit: \$limit
    offset: \$offset
  ) {
    id book_id edition_id status_id rating updated_at
    user_book_status { id status slug }
    book { id title }
    edition { id isbn_10 isbn_13 pages }
    active_reads: user_book_reads(where: {finished_at: {_is_null: true}}, order_by: {id: desc}, limit: 1) {
      id edition_id started_at finished_at progress_pages progress_seconds
    }
    latest_reads: user_book_reads(order_by: {id: desc}, limit: 1) {
      id edition_id started_at finished_at progress_pages progress_seconds
    }
  }
}
''';
    final result = <HardcoverBookRecord>[];
    const pageSize = 100;
    const maxRecords = 10000;
    for (var offset = 0; offset <= maxRecords; offset += pageSize) {
      final limit = offset == maxRecords ? 1 : pageSize;
      final data = await _query(query, {'userId': userId, 'limit': limit, 'offset': offset});
      final page = sourceList(data['user_books']);
      if (page.length > limit) throw const SourceException(SourceFailure.invalidData);
      if (offset == maxRecords) {
        if (page.isNotEmpty) throw const SourceException(SourceFailure.invalidData);
        break;
      }
      result.addAll(page.map((value) => HardcoverBookRecord.fromApi(sourceMap(value))));
      if (page.length < pageSize) break;
    }
    return List.unmodifiable(result);
  }

  Future<void> updateStatus({required int userBookId, required int statusId}) async {
    if (userBookId <= 0 || statusId <= 0) throw const SourceException(SourceFailure.invalidData);
    const mutation = '''
mutation HardcoverUpdateStatus(\$id: Int!, \$statusId: Int!) {
  update_user_book(id: \$id, object: {status_id: \$statusId}) { id error user_book { id status_id } }
}
''';
    final data = await _query(mutation, {'id': userBookId, 'statusId': statusId});
    final result = sourceMap(data['update_user_book']);
    if (result['error'] is String && (result['error'] as String).isNotEmpty) {
      throw const SourceException(SourceFailure.conflict);
    }
    final updated = sourceMap(result['user_book']);
    if (sourceInt(updated['id']) != userBookId || sourceInt(updated['status_id']) != statusId) {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  Future<HardcoverEditionMatch?> editionForIsbn(String value) async {
    final isbn = BookIdentifiers.normalize(value);
    if (isbn == null) throw const SourceException(SourceFailure.invalidData);
    final field = isbn.length == 13 ? 'isbn_13' : 'isbn_10';
    final query = '''
query HardcoverEditionByIsbn(\$isbn: String!) {
  editions(where: {$field: {_eq: \$isbn}}, limit: 10) {
    id isbn_10 isbn_13 book_id book { id title }
  }
}
''';
    final data = await _query(query, {'isbn': isbn});
    final values = sourceList(data['editions']);
    final rows = values
        .map((value) => HardcoverEditionMatch.fromApi(sourceMap(value), isbn))
        .where((edition) => edition.editionId > 0 && edition.bookId > 0)
        .toList(growable: false);
    if (rows.length != 1) return null;
    final returnedIsbn = sourceMap(values.single)[field];
    if (returnedIsbn is! String || BookIdentifiers.normalize(returnedIsbn) != isbn) return null;
    return rows.single;
  }

  Future<Map<String, HardcoverEditionMatch?>> editionsForIsbns(Iterable<String> values) async {
    final isbns = values.map(BookIdentifiers.normalize).whereType<String>().toSet().toList()..sort();
    final matches = <String, HardcoverEditionMatch?>{};
    const batchSize = 100;
    const resultLimit = 1000;
    for (var offset = 0; offset < isbns.length; offset += batchSize) {
      final batch = isbns.skip(offset).take(batchSize).toList(growable: false);
      final isbn10s = batch.where((isbn) => isbn.length == 10).toList(growable: false);
      final isbn13s = batch.where((isbn) => isbn.length == 13).toList(growable: false);
      const query = '''
query HardcoverEditionsByIsbn(\$isbn10s: [String!]!, \$isbn13s: [String!]!, \$limit: Int!) {
  editions(
    where: {_or: [{isbn_10: {_in: \$isbn10s}}, {isbn_13: {_in: \$isbn13s}}]}
    limit: \$limit
  ) {
    id isbn_10 isbn_13 book_id book { id title }
  }
}
''';
      final data = await _query(query, {
        'isbn10s': isbn10s,
        'isbn13s': isbn13s,
        'limit': resultLimit,
      });
      final rows = sourceList(data['editions']);
      if (rows.length >= resultLimit) {
        for (final isbn in batch) {
          matches[isbn] = null;
        }
        continue;
      }
      final matchesByIsbn = {for (final isbn in batch) isbn: <int, HardcoverEditionMatch>{}};
      for (final value in rows) {
        final json = sourceMap(value);
        for (final isbn in batch) {
          final key = isbn.length == 13 ? 'isbn_13' : 'isbn_10';
          final returned = json[key];
          if (returned is String && BookIdentifiers.normalize(returned) == isbn) {
            final edition = HardcoverEditionMatch.fromApi(json, isbn);
            if (edition.editionId > 0 && edition.bookId > 0) {
              matchesByIsbn[isbn]![edition.editionId] = edition;
            }
          }
        }
      }
      for (final isbn in batch) {
        final editions = matchesByIsbn[isbn]!.values;
        matches[isbn] = editions.length == 1 ? editions.single : null;
      }
    }
    return Map.unmodifiable(matches);
  }

  Future<({int id, String? updatedAt})> addUserBook({
    required int bookId,
    required int editionId,
    required int statusId,
  }) async {
    if (bookId <= 0 || editionId <= 0 || statusId <= 0) {
      throw const SourceException(SourceFailure.invalidData);
    }
    const mutation = '''
mutation HardcoverInsertUserBook(\$bookId: Int!, \$editionId: Int!, \$statusId: Int!) {
  insert_user_book(object: {book_id: \$bookId, edition_id: \$editionId, status_id: \$statusId}) {
    id error user_book { id book_id edition_id status_id updated_at }
  }
}
''';
    final data = await _query(mutation, {'bookId': bookId, 'editionId': editionId, 'statusId': statusId});
    final result = sourceMap(data['insert_user_book']);
    if (result['error'] is String && (result['error'] as String).isNotEmpty) {
      throw const SourceException(SourceFailure.conflict);
    }
    final added = sourceMap(result['user_book']);
    final id = sourceInt(added['id']) ?? sourceInt(result['id']) ?? 0;
    if (id <= 0 ||
        (sourceInt(added['book_id']) != null && sourceInt(added['book_id']) != bookId) ||
        (sourceInt(added['edition_id']) != null && sourceInt(added['edition_id']) != editionId) ||
        (sourceInt(added['status_id']) != null && sourceInt(added['status_id']) != statusId)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return (id: id, updatedAt: added['updated_at'] as String?);
  }

  Future<void> deleteUserBook({required int userBookId}) async {
    if (userBookId <= 0) throw const SourceException(SourceFailure.invalidData);
    const mutation = '''
mutation HardcoverDeleteUserBook(\$id: Int!) {
  delete_user_book(id: \$id) { id error }
}
''';
    final data = await _query(mutation, {'id': userBookId});
    final result = sourceMap(data['delete_user_book']);
    if (result['error'] is String && (result['error'] as String).isNotEmpty) {
      throw const SourceException(SourceFailure.conflict);
    }
    final deletedId = sourceInt(result['id']);
    if (deletedId != null && deletedId != userBookId) {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  Future<void> updateReadingProgress({required int readId, required int? pages}) async {
    if (readId <= 0 || (pages != null && pages < 0)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    const mutation = '''
mutation HardcoverUpdateReadingProgress(\$id: Int!, \$pages: Int) {
  update_user_book_read(id: \$id, object: {progress_pages: \$pages}) {
    id error user_book_read { id progress_pages }
  }
}
''';
    final data = await _query(mutation, {'id': readId, 'pages': pages});
    final result = sourceMap(data['update_user_book_read']);
    if (result['error'] is String && (result['error'] as String).isNotEmpty) {
      throw const SourceException(SourceFailure.conflict);
    }
    final updated = sourceMap(result['user_book_read']);
    if (sourceInt(updated['id']) != readId ||
        (pages != null && sourceInt(updated['progress_pages']) != pages) ||
        (pages == null && updated['progress_pages'] != null)) {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _client.close();
  }
}
