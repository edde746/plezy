import 'dart:async';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

import '../sources/source_database.dart';
import '../sources/source_models.dart';
import '../sources/source_oauth.dart';
import '../sources/source_transport.dart';

/// Library services remain independent of owned files, watched state and DRM.
enum LendingProvider { openLibrary, overdrive, hoopla, palace, cloudLibrary, borrowBox, cantook, onleihe, other }

extension LendingProviderInfo on LendingProvider {
  String get label => switch (this) {
    LendingProvider.openLibrary => 'Open Library',
    LendingProvider.overdrive => 'Libby / OverDrive',
    LendingProvider.hoopla => 'Hoopla',
    LendingProvider.palace => 'The Palace Project',
    LendingProvider.cloudLibrary => 'cloudLibrary',
    LendingProvider.borrowBox => 'BorrowBox',
    LendingProvider.cantook => 'Cantook',
    LendingProvider.onleihe => 'Onleihe',
    LendingProvider.other => '',
  };
  String get home => switch (this) {
    LendingProvider.openLibrary => 'https://openlibrary.org',
    LendingProvider.overdrive => 'https://libbyapp.com',
    LendingProvider.hoopla => 'https://www.hoopladigital.com',
    LendingProvider.palace => 'https://thepalaceproject.org/information-for-library-patrons/',
    LendingProvider.cloudLibrary => 'https://www.yourcloudlibrary.com/',
    LendingProvider.borrowBox => 'https://www.borrowbox.com/',
    LendingProvider.cantook => 'https://app.doc.cantook.com/en/doc/APP2445/app-cantook/connecting-to-a-library',
    LendingProvider.onleihe => 'https://hilfe.onleihe.de/',
    LendingProvider.other => '',
  };
}

Uri lendingHttps(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    throw const SourceException(SourceFailure.permission);
  }
  return uri;
}

class LendingLibrary {
  const LendingLibrary({
    required this.id,
    required this.provider,
    required this.name,
    required this.home,
    this.gateway = '',
    this.remoteId = '',
    this.integration = false,
    this.circulation = false,
  });
  final String id, name, home, gateway, remoteId;
  final LendingProvider provider;
  final bool integration, circulation;
  bool get native => provider == LendingProvider.overdrive && gateway.isNotEmpty && remoteId.isNotEmpty;
  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.name,
    'name': name,
    'home': home,
    'gateway': gateway,
    'remoteId': remoteId,
    'integration': integration,
    'circulation': circulation,
  };
  factory LendingLibrary.fromJson(Map<String, dynamic> value) => LendingLibrary(
    id: value['id'] as String,
    provider: LendingProvider.values.byName(value['provider'] as String),
    name: value['name'] as String,
    home: value['home'] as String,
    gateway: value['gateway'] as String? ?? '',
    remoteId: value['remoteId'] as String? ?? '',
    integration: value['integration'] == true,
    circulation: value['circulation'] == true,
  );
}

class LendingBook {
  const LendingBook({
    required this.id,
    required this.title,
    this.author = '',
    this.cover,
    this.page,
    this.data = const {},
    this.loan = false,
    this.hold = false,
  });
  final String id, title, author;
  final Uri? cover, page;
  final Map<String, dynamic> data;
  final bool loan, hold;
  DateTime? get due => DateTime.tryParse(data['expires'] as String? ?? '');
  int? get queuePosition => sourceInt(data['holdListPosition']);
  String? action(String name) => sourceMap(sourceMap(data['actions'])[name])['href'] as String?;
  String? link(String name) => sourceMap(sourceMap(data['links'])[name])['href'] as String?;
}

class LendingPage {
  const LendingPage(this.books, {this.more = false});
  final List<LendingBook> books;
  final bool more;
}

class LendingService {
  static const overdriveEnabled = bool.fromEnvironment('ENABLE_OVERDRIVE', defaultValue: false);
  LendingService(
    this.repository,
    this.profile, {
    required this.valid,
    SourceTransport? transport,
    Future<bool> Function(Uri)? launch,
    this.enableOverdrive = overdriveEnabled,
  }) : transport = transport ?? SourceTransport(),
       launch = launch ?? ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));
  final SourceRepository repository;
  final String profile;
  final bool Function() valid;
  final SourceTransport transport;
  final bool enableOverdrive;
  void _native() {
    check();
    if (!enableOverdrive) throw const SourceException(SourceFailure.unsupported);
  }

  final Future<bool> Function(Uri) launch;
  final Map<String, Future<Map<String, dynamic>>> _refreshing = {};
  final Map<String, Map<String, dynamic>> _patrons = {};
  static DateTime _lastSearch = DateTime.fromMillisecondsSinceEpoch(0);
  int _authorization = 0;
  final _removedLibraries = <String>{};
  bool _closed = false;
  void check() {
    if (_closed || !valid()) throw const SourceException(SourceFailure.cancelled);
  }

  Future<List<LendingLibrary>> libraries() async {
    check();
    final data = await repository.preference(profile, 'lending:libraries');
    check();
    return sourceList(data['libraries']).map((l) => LendingLibrary.fromJson(sourceMap(l))).toList();
  }

  Future<void> save(LendingLibrary library) async {
    lendingHttps(library.home);
    final items = await libraries();
    check();
    await repository.savePreference(profile, 'lending:libraries', {
      'libraries': [...items.where((l) => l.id != library.id).map((l) => l.toJson()), library.toJson()],
    });
  }

  Future<void> remove(LendingLibrary library) async {
    _removedLibraries.add(library.id);
    final items = await libraries();
    check();
    await repository.forgetPreference(profile, 'lending:token:${library.id}');
    await repository.savePreference(profile, 'lending:libraries', {
      'libraries': items.where((l) => l.id != library.id).map((l) => l.toJson()).toList(),
    });
    _patrons.remove(library.id);
  }

  Future<void> openPage(Uri uri) async {
    check();
    lendingHttps(uri.toString());
    if (!await launch(uri)) throw const SourceException(SourceFailure.unavailable);
  }

  Future<LendingPage> openLibrarySearch(String query, {int page = 1}) async {
    check();
    // Open Library's public API requests must be at least a second apart.
    final now = DateTime.now();
    final next = _lastSearch.add(const Duration(milliseconds: 1100));
    _lastSearch = next.isAfter(now) ? next : now;
    final delay = _lastSearch.difference(now);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    check();
    final result = await transport.json(
      'GET',
      Uri.https('openlibrary.org', '/search.json', {
        'q': query,
        'page': '$page',
        'limit': '30',
        'fields': 'key,title,author_name,cover_i',
      }),
      headers: const {'User-Agent': 'PlezyNG (https://github.com/snapetech-org/PlezyNG)'},
    );
    check();
    final books = sourceList(result['docs'])
        .map(sourceMap)
        .where((b) => RegExp(r'^/works/OL\d+W$').hasMatch('${b['key']}'))
        .map((b) {
          final cover = sourceInt(b['cover_i']);
          return LendingBook(
            id: b['key'] as String,
            title: b['title'] as String? ?? '',
            author: sourceList(b['author_name']).join(', '),
            cover: cover == null ? null : Uri.https('covers.openlibrary.org', '/b/id/$cover-M.jpg'),
            page: Uri.https('openlibrary.org', b['key'] as String),
          );
        })
        .toList();
    return LendingPage(books, more: page * 30 < (sourceInt(result['numFound']) ?? 0));
  }

  Uri _gateway(LendingLibrary library, String path) {
    final uri = lendingHttps(library.gateway);
    if (uri.path.isNotEmpty && uri.path != '/' || uri.hasQuery || uri.hasFragment) {
      throw const SourceException(SourceFailure.permission);
    }
    return uri.replace(path: path);
  }

  Future<List<Map<String, dynamic>>> gatewayLibraries(String endpoint) async {
    _native();
    final placeholder = LendingLibrary(
      id: '',
      provider: LendingProvider.overdrive,
      name: '',
      home: '',
      gateway: endpoint,
    );
    final result = await transport.json('GET', _gateway(placeholder, '/v1/libraries'));
    check();
    return sourceList(result['libraries']).map(sourceMap).toList();
  }

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, dynamic> data) =>
      transport.json('POST', uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(data));
  Future<bool> connected(LendingLibrary library) async =>
      (await repository.privatePreference(profile, 'lending:token:${library.id}'))['access_token'] != null;
  void cancelAuthorization() => _authorization++;
  Future<void> authorize(LendingLibrary library) async {
    _native();
    final epoch = ++_authorization, verifier = SourceOAuthService.randomSecret();
    final response = await _post(_gateway(library, '/v1/authorizations'), {
      'library': library.remoteId,
      'challenge': SourceOAuthService.challenge(verifier),
    });
    final id = response['id'] as String;
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(id)) throw const SourceException(SourceFailure.invalidData);
    final uri = lendingHttps(response['authorizeUrl'] as String);
    if (uri.host != 'oauth-patron.overdrive.com' || uri.path != '/device/initiate') {
      throw const SourceException(SourceFailure.permission);
    }
    check();
    if (!await launch(uri)) throw const SourceException(SourceFailure.unavailable);
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      check();
      if (epoch != _authorization) throw const SourceException(SourceFailure.cancelled);
      final data = await _post(_gateway(library, '/v1/authorizations/$id/token'), {'verifier': verifier});
      if (data['pending'] == true) continue;
      check();
      if (epoch != _authorization) throw const SourceException(SourceFailure.cancelled);
      await _saveTokens(library, data);
      return;
    }
    throw const SourceException(SourceFailure.cancelled);
  }

  Future<void> _saveTokens(LendingLibrary library, Map<String, dynamic> tokens) async {
    if (tokens['access_token'] is! String || (tokens['access_token'] as String).isEmpty) {
      throw const SourceException(SourceFailure.authentication);
    }
    check();
    if (_removedLibraries.contains(library.id)) throw const SourceException(SourceFailure.cancelled);
    await repository.savePrivatePreference(profile, 'lending:token:${library.id}', {
      ...tokens,
      'expiresAt': DateTime.now()
          .add(Duration(seconds: sourceInt(tokens['expires_in']) ?? 3600))
          .millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>> _tokens(LendingLibrary library, {bool force = false}) async {
    _native();
    final stored = await repository.privatePreference(profile, 'lending:token:${library.id}');
    if (!force &&
        (sourceInt(stored['expiresAt']) ?? 0) >
            DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch) {
      return stored;
    }
    if (stored['refresh_token'] == null) throw const SourceException(SourceFailure.authentication);
    return _refreshing.putIfAbsent(library.id, () async {
      try {
        final fresh = await _post(_gateway(library, '/v1/refresh'), {
          'library': library.remoteId,
          'refresh_token': stored['refresh_token'],
          'refreshProof': stored['refreshProof'],
        });
        check();
        // A disconnect may happen during a token refresh; never resurrect it.
        if (!await connected(library)) throw const SourceException(SourceFailure.cancelled);
        await _saveTokens(library, fresh);
        return fresh;
      } finally {
        _refreshing.remove(library.id)?.ignore();
      }
    });
  }

  Uri patronUri(LendingLibrary library, [String suffix = '']) => Uri.https(
    library.integration ? 'integration-patron.api.overdrive.com' : 'patron.api.overdrive.com',
    '/v1/patrons/me$suffix',
  );
  void validateApi(LendingLibrary library, Uri uri) {
    lendingHttps(uri.toString());
    final hosts = library.integration
        ? {'integration-patron.api.overdrive.com', 'integration.api.overdrive.com'}
        : {'patron.api.overdrive.com', 'api.overdrive.com'};
    if (!hosts.contains(uri.host) || uri.port != 443 || !uri.path.startsWith('/v1/')) {
      throw const SourceException(SourceFailure.permission);
    }
  }

  Future<String> _request(LendingLibrary library, String method, Uri uri, {Map<String, dynamic>? data}) async {
    validateApi(library, uri);
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _tokens(library, force: attempt > 0);
      check();
      try {
        final result = await transport.text(
          method,
          uri,
          headers: {
            'Authorization': 'Bearer ${token['access_token']}',
            'User-Agent': 'PlezyNG',
            if (data != null) 'Content-Type': 'application/json',
          },
          body: data == null ? null : jsonEncode(data),
        );
        check();
        return result;
      } on SourceException catch (error) {
        if (error.status != 401 || attempt == 1) rethrow;
      }
    }
    throw const SourceException(SourceFailure.authentication);
  }

  Future<Map<String, dynamic>> _get(LendingLibrary library, Uri uri) async =>
      sourceMap(jsonDecode(await _request(library, 'GET', uri)));
  Future<Map<String, dynamic>> patron(LendingLibrary library) async =>
      _patrons[library.id] ??= await _get(library, patronUri(library));
  Future<LendingPage> search(LendingLibrary library, String query, {int page = 1}) async {
    final info = await patron(library);
    final template = sourceMap(sourceMap(info['linkTemplates'])['search'])['href'] as String?;
    if (template == null) throw const SourceException(SourceFailure.unsupported);
    // Preserve the patron's own collection, including Advantage entitlement.
    final uri = Uri.parse(
      template.split('?').first,
    ).replace(queryParameters: {'q': query, 'limit': '30', 'offset': '${(page - 1) * 30}'});
    final result = await _get(library, uri);
    final books = sourceList(result['products']).map((b) => _book(sourceMap(b))).toList();
    return LendingPage(books, more: page * 30 < (sourceInt(result['totalItems']) ?? 0));
  }

  LendingBook _book(Map<String, dynamic> data, {bool loan = false, bool hold = false}) {
    Uri? optional(String? text) {
      try {
        return text == null ? null : lendingHttps(text);
      } catch (_) {
        return null;
      }
    }

    final images = sourceMap(data['images']);
    return LendingBook(
      id: '${data['id'] ?? data['reserveId']}',
      title: data['title'] as String? ?? '',
      author: sourceMap(data['primaryCreator'])['name'] as String? ?? '',
      cover: optional(sourceMap(images['cover300Wide'] ?? images['cover'])['href'] as String?),
      page: optional(sourceMap(sourceList(data['contentDetails']).firstOrNull)['href'] as String?),
      data: data,
      loan: loan,
      hold: hold,
    );
  }

  Future<LendingPage> shelf(LendingLibrary library, {required bool holds}) async {
    final result = await _get(library, patronUri(library, holds ? '/holds' : '/checkouts'));
    final books = <LendingBook>[];
    for (final row in sourceList(result[holds ? 'holds' : 'checkouts'])) {
      check();
      final data = sourceMap(row), metadata = sourceMap(sourceMap(sourceMap(row)['links'])['metadata'])['href'];
      Map<String, dynamic> detail = {};
      if (metadata is String) detail = await _get(library, Uri.parse(metadata));
      books.add(_book({...detail, ...data}, loan: !holds, hold: holds));
    }
    return LendingPage(books);
  }

  Future<Map<String, dynamic>> availability(LendingLibrary library, LendingBook book) async {
    final info = await patron(library);
    final template = sourceMap(sourceMap(info['linkTemplates'])['availability'])['href'] as String?;
    if (template == null) throw const SourceException(SourceFailure.unsupported);
    return _get(library, Uri.parse(template.replaceAll('{reserveId}', Uri.encodeComponent(book.id))));
  }

  Future<void> borrow(LendingLibrary library, LendingBook book, {String? holdEmail}) async {
    if (!library.circulation) throw const SourceException(SourceFailure.unsupported);
    await _request(
      library,
      'POST',
      patronUri(library, holdEmail == null ? '/checkouts' : '/holds'),
      data: {
        'fields': [
          {'name': 'id', 'value': book.id},
          if (holdEmail != null) {'name': 'emailAddress', 'value': holdEmail},
        ],
      },
    );
  }

  Future<void> returnOrCancel(LendingLibrary library, LendingBook book) async {
    if (!library.circulation) throw const SourceException(SourceFailure.unsupported);
    final href = book.action(book.hold ? 'removeHold' : 'earlyReturn');
    if (href == null) throw const SourceException(SourceFailure.unsupported);
    await _request(library, 'DELETE', Uri.parse(href));
  }

  Future<void> suspendHold(LendingLibrary library, LendingBook book, {required bool resume}) async {
    if (!library.circulation || !book.hold) throw const SourceException(SourceFailure.unsupported);
    final href = book.action(resume ? 'releaseSuspension' : 'addSuspension');
    if (href == null) throw const SourceException(SourceFailure.unsupported);
    await _request(library, resume ? 'DELETE' : 'POST', Uri.parse(href));
  }

  Future<void> editHoldEmail(LendingLibrary library, LendingBook book, String email) async {
    if (!library.circulation || !book.hold || !email.contains('@')) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final href = book.action('editHold');
    if (href == null) throw const SourceException(SourceFailure.unsupported);
    await _request(
      library,
      'PUT',
      Uri.parse(href),
      data: {
        'fields': [
          {'name': 'id', 'value': book.id},
          {'name': 'emailAddress', 'value': email},
        ],
      },
    );
  }

  Future<void> fulfill(LendingLibrary library, LendingBook book) async {
    final href = book.link('downloadRedirect');
    if (href == null) throw const SourceException(SourceFailure.unsupported);
    final uri = Uri.parse(href);
    validateApi(library, uri);
    var token = await _tokens(library);
    var response = await transport.send(
      'GET',
      uri,
      headers: {'Authorization': 'Bearer ${token['access_token']}', 'User-Agent': 'PlezyNG'},
    );
    if (response.statusCode == 401) {
      await response.stream.listen(null).cancel();
      token = await _tokens(library, force: true);
      check();
      response = await transport.send(
        'GET',
        uri,
        headers: {'Authorization': 'Bearer ${token['access_token']}', 'User-Agent': 'PlezyNG'},
      );
    }
    await response.stream.listen(null).cancel();
    check();
    if (response.statusCode != 302) {
      SourceTransport.check(response.statusCode);
      throw const SourceException(SourceFailure.invalidData);
    }
    final target = lendingHttps(response.headers['location'] ?? '');
    if (target.host != 'overdrive.com' && !target.host.endsWith('.overdrive.com')) {
      throw const SourceException(SourceFailure.permission);
    }
    await openPage(target); // One-use fulfillment URL is never persisted.
  }

  void close() {
    _closed = true;
    cancelAuthorization();
    transport.close();
    _patrons.clear();
  }
}
