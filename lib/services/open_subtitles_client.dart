import 'dart:convert';
import 'dart:typed_data';

import '../models/subtitles/subtitle_search_result.dart';
import '../sources/source_models.dart';
import '../sources/source_transport.dart';
import '../utils/language_codes.dart';

class OpenSubtitleDownload {
  const OpenSubtitleDownload({
    required this.fileName,
    required this.bytes,
    this.languageCode = '',
    this.forced = false,
    this.hearingImpaired = false,
  });
  final String fileName;
  final Uint8List bytes;
  final String languageCode;
  final bool forced;
  final bool hearingImpaired;
}

/// Small OpenSubtitles REST client for user-initiated standalone-file searches.
/// The API key and optional account credentials are supplied by the encrypted
/// file-source credential vault and are never stored in result/catalog records.
class OpenSubtitlesClient {
  OpenSubtitlesClient({required String apiKey, this.username, this.password, SourceTransport? transport})
    : _apiKey = apiKey.trim(),
      _transport = transport ?? SourceTransport();

  static final Uri _api = Uri.https('api.opensubtitles.com', '/api/v1');
  static const _userAgent = 'PlezyNG/1.0.0';
  final String _apiKey;
  final String? username;
  final String? password;
  final SourceTransport _transport;
  Future<String?>? _tokenRequest;
  bool _closed = false;

  Map<String, String> get _headers => {'Api-Key': _apiKey, 'User-Agent': _userAgent, 'Accept': 'application/json'};

  Future<String?> _token() {
    final current = _tokenRequest;
    if (current != null) return current;
    final opening = _login();
    _tokenRequest = opening;
    return opening;
  }

  Future<String?> _login() async {
    if ((username?.trim().isNotEmpty ?? false) != true || (password?.isNotEmpty ?? false) != true) {
      return null;
    }
    final response = await _transport.json(
      'POST',
      _api.resolve('/api/v1/login'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'username': username!.trim(), 'password': password}),
    );
    final token = response['token'];
    return token is String && token.isNotEmpty ? token : null;
  }

  Future<List<SubtitleSearchResult>> search({
    required String query,
    required String languageCode,
    String? imdbId,
    String? tmdbId,
    int? year,
    String? movieHash,
  }) async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    if (_apiKey.isEmpty || query.trim().isEmpty) throw const SourceException(SourceFailure.authentication);
    final imdb = imdbId?.trim().replaceFirst(RegExp(r'^(tt)', caseSensitive: false), '');
    final trimmedQuery = query.trim();
    final boundedQuery = trimmedQuery.length > 120 ? trimmedQuery.substring(0, 120) : trimmedQuery;
    final normalizedMovieHash = movieHash?.trim().toLowerCase();
    final validMovieHash =
        normalizedMovieHash != null && RegExp(r'^[0-9a-f]{16}$').hasMatch(normalizedMovieHash)
        ? normalizedMovieHash
        : null;
    final params = <String, String>{
      'query': boundedQuery.toLowerCase(),
      'languages': languageCodeFor(languageCode),
      'order_by': 'download_count',
      'order_direction': 'desc',
      'limit': '30',
      if (validMovieHash != null) 'moviehash': validMovieHash,
      if (validMovieHash == null && imdb != null && imdb.isNotEmpty) 'imdb_id': imdb,
      if (validMovieHash == null && (tmdbId?.trim().isNotEmpty ?? false)) 'tmdb_id': tmdbId!.trim(),
      if (validMovieHash == null && year != null && year > 1800 && year < 2200) 'year': '$year',
    };
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final uri = _api.resolve('/api/v1/subtitles').replace(queryParameters: sortedParams);
    final response = await _transport.json('GET', uri, headers: _headers);
    final rows = response['data'];
    if (rows is! List) return const [];
    final results = <SubtitleSearchResult>[];
    for (final value in rows) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final attributes = sourceMap(row['attributes']);
      final files = sourceList(attributes['files']);
      for (final fileValue in files) {
        if (fileValue is! Map) continue;
        final file = Map<String, dynamic>.from(fileValue);
        final fileId = _string(file['file_id']);
        if (fileId.isEmpty) continue;
        final fileName = _string(file['file_name']);
        final release = _string(attributes['release']).trim();
        final feature = sourceMap(attributes['feature_details']);
        final title = release.isNotEmpty ? release : _string(feature['title']);
        final language = _string(attributes['language']);
        final ext = _extension(fileName);
        final id = int.tryParse(_string(row['id'])) ?? int.tryParse(fileId) ?? 0;
        results.add(
          SubtitleSearchResult(
            id: id,
            key: fileId,
            codec: ext,
            language: language.isEmpty ? languageCodeFor(languageCode) : language,
            languageCode: language.isEmpty ? languageCodeFor(languageCode) : language,
            score: _number(attributes['ratings']),
            providerTitle: 'OpenSubtitles',
            title: title.isEmpty ? fileName : title,
            displayTitle: fileName.isEmpty ? title : fileName,
            hearingImpaired: attributes['hearing_impaired'] == true,
            perfectMatch: attributes['moviehash_match'] == true || attributes['match'] == true,
            forced: attributes['foreign_parts_only'] == true,
          ),
        );
      }
    }
    results.sort((a, b) {
      final matchOrder = (b.perfectMatch ? 1 : 0).compareTo(a.perfectMatch ? 1 : 0);
      return matchOrder != 0 ? matchOrder : (b.score ?? 0).compareTo(a.score ?? 0);
    });
    return results.take(40).toList(growable: false);
  }

  Future<OpenSubtitleDownload> download(SubtitleSearchResult result) async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    if (_apiKey.isEmpty) throw const SourceException(SourceFailure.authentication);
    final fileId = int.tryParse(result.key);
    if (fileId == null || fileId <= 0) throw const SourceException(SourceFailure.invalidData);
    final token = await _token();
    final response = await _transport.json(
      'POST',
      _api.resolve('/api/v1/download'),
      headers: {..._headers, 'Content-Type': 'application/json', 'Authorization': ?token},
      body: jsonEncode({'file_id': fileId, if (result.codec != null) 'sub_format': result.codec}),
    );
    final link = _string(response['link']);
    final uri = Uri.tryParse(link);
    final host = uri?.host.toLowerCase();
    if (uri == null ||
        uri.scheme != 'https' ||
        host == null ||
        !(host == 'opensubtitles.com' || host.endsWith('.opensubtitles.com')) ||
        uri.userInfo.isNotEmpty) {
      throw const SourceException(SourceFailure.permission);
    }
    final downloaded = await _transport.send('GET', uri, redirects: true);
    if (downloaded.statusCode < 200 || downloaded.statusCode >= 300) {
      await downloaded.stream.listen(null).cancel();
      SourceTransport.check(downloaded.statusCode);
    }
    final bytes = <int>[];
    await for (final chunk in downloaded.stream.timeout(const Duration(seconds: 30))) {
      if (bytes.length + chunk.length > 5 * 1024 * 1024) {
        throw const SourceException(SourceFailure.invalidData);
      }
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty || bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4b) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final decoded = utf8.decode(bytes, allowMalformed: true);
    if (decoded.trim().isEmpty || decoded.contains('\u0000')) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final fileName = _string(response['file_name']).trim();
    final resultLanguage = result.languageCode?.trim();
    final languageCode = resultLanguage?.isNotEmpty == true ? resultLanguage! : result.language?.trim() ?? '';
    return OpenSubtitleDownload(
      fileName: fileName.isEmpty ? 'subtitle.${result.codec ?? 'srt'}' : fileName,
      bytes: Uint8List.fromList(bytes),
      languageCode: languageCode,
      forced: result.forced,
      hearingImpaired: result.hearingImpaired,
    );
  }

  /// OpenSubtitles uses service-specific Chinese and Portuguese region codes.
  /// Preserve them, and resolve ISO 639-2 aliases instead of truncating them.
  static String languageCodeFor(String value) {
    final normalized = value.trim().replaceAll('_', '-').toLowerCase();
    final code = LanguageCodes.getIso6391Code(normalized);
    if (code == 'zh') {
      return normalized.contains('hant') || normalized.endsWith('-tw') || normalized.endsWith('-hk')
          ? 'zh-tw'
          : 'zh-cn';
    }
    if (code == 'pt') return normalized.endsWith('-br') ? 'pt-br' : 'pt-pt';
    if (code == 'nb' || code == 'nn') return 'no';
    return code ?? 'en';
  }

  static String _string(Object? value) => value == null ? '' : '$value';

  static double? _number(Object? value) => value is num ? value.toDouble() : double.tryParse('$value');

  static String _extension(String name) {
    final match = RegExp(r'\.([a-zA-Z0-9]{2,5})$').firstMatch(name);
    final extension = match?.group(1)?.toLowerCase();
    return extension != null && const {'srt', 'ass', 'ssa', 'vtt', 'sub'}.contains(extension) ? extension : 'srt';
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _transport.close();
  }
}
