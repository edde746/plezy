import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'real_debrid_client.dart';
import 'remote_stream_models.dart';

/// Bounded adapters for the other widely used hosted debrid services.
/// Credentials stay in the account snapshot; they are never put in playback
/// URLs or written to logs.
class AllDebridClient {
  AllDebridClient({http.Client? client, required this.account}) : _http = client ?? http.Client();

  static const _base = 'https://api.alldebrid.com';
  final http.Client _http;
  final RemoteStreamAccount account;

  static Future<AllDebridDeviceCode> startDeviceAuthorization({http.Client? client}) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse('$_base/v4.1/pin/get'))
          .timeout(const Duration(seconds: 15));
      final row = _decodeEnvelope(response.bodyBytes, response.statusCode);
      final pin = row['pin'];
      final check = row['check'];
      final userUrl = row['user_url'];
      final url = userUrl is String ? Uri.tryParse(userUrl) : null;
      if (pin is! String || check is! String || url == null || url.scheme != 'https' || url.host != 'alldebrid.com') {
        throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      }
      return AllDebridDeviceCode(
        pin: pin,
        check: check,
        userUrl: url,
        expiresInSeconds: _int(row['expires_in'], fallback: 600).clamp(30, 600),
      );
    } finally {
      if (owned) httpClient.close();
    }
  }

  static Future<RemoteStreamAccount?> finishDeviceAuthorization(
    AllDebridDeviceCode code, {
    bool Function()? shouldCancel,
    http.Client? client,
  }) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final deadline = DateTime.now().add(Duration(seconds: code.expiresInSeconds));
      while (DateTime.now().isBefore(deadline)) {
        if (shouldCancel?.call() == true) return null;
        final response = await httpClient
            .post(
              Uri.parse('$_base/v4/pin/check'),
              body: {'check': code.check, 'pin': code.pin},
            )
            .timeout(const Duration(seconds: 15));
        final row = _decodeEnvelope(response.bodyBytes, response.statusCode, allowPending: true);
        final apiKey = row['apikey'];
        if (apiKey is String && apiKey.isNotEmpty) {
          final clientApi = AllDebridClient(
            client: httpClient,
            account: RemoteStreamAccount.create(
              service: RemoteStreamService.allDebrid,
              displayName: 'AllDebrid',
              accessToken: apiKey,
            ),
          );
          final user = await clientApi._api('GET', '/v4/user');
          final rawUser = user['user'];
          final userMap = rawUser is Map ? Map<String, dynamic>.from(rawUser) : user;
          final username = userMap['username'];
          return RemoteStreamAccount.create(
            service: RemoteStreamService.allDebrid,
            displayName: username is String && username.trim().isNotEmpty ? username.trim() : 'AllDebrid',
            accessToken: apiKey,
          );
        }
        if (row['expires_in'] is num && (row['expires_in'] as num) <= 0) return null;
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      return null;
    } on RemoteProviderException {
      rethrow;
    } on Object {
      throw const RemoteProviderException(RemoteProviderFailure.unavailable);
    } finally {
      if (owned) httpClient.close();
    }
  }

  Future<ResolvedRemoteStream> resolveTorrentHash(
    String hash, {
    int? fileIndex,
    bool Function()? shouldCancel,
    RemotePreparationProgress? onProgress,
    String? existingJobId,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hash)) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    var id = existingJobId ?? '';
    if (id.isEmpty) {
      final uploaded = await _api('POST', '/v4/magnet/upload', fields: {'magnets[]': hash.toLowerCase()});
      final magnets = uploaded['magnets'];
      if (magnets is! List || magnets.isEmpty || magnets.first is! Map) {
        throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      }
      final rawId = (magnets.first as Map)['id'];
      id = rawId?.toString() ?? '';
    }
    if (!RegExp(r'^\d{1,16}$').hasMatch(id)) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    await onProgress?.call(stage: 'provider_job_created', providerJobId: id);

    final deadline = DateTime.now().add(const Duration(minutes: 8));
    var ready = false;
    Object? lastStatus;
    while (DateTime.now().isBefore(deadline)) {
      if (shouldCancel?.call() == true) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
      final status = await _api('POST', '/v4.1/magnet/status', fields: {'id': id});
      final rows = status['magnets'];
      if (rows is! List || rows.isEmpty || rows.first is! Map) {
        throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      }
      final statusCode = (rows.first as Map)['statusCode'];
      if (statusCode != lastStatus) {
        lastStatus = statusCode;
        await onProgress?.call(
          stage: statusCode == 4 ? 'ready' : statusCode is num && statusCode >= 5 ? 'failed' : 'preparing',
          providerJobId: id,
        );
      }
      if (statusCode == 4) {
        ready = true;
        break;
      }
      if (statusCode is num && statusCode >= 5) {
        throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    if (!ready) throw const RemoteProviderException(RemoteProviderFailure.timeout);

    await onProgress?.call(stage: 'files_ready', providerJobId: id);
    final response = await _api('POST', '/v4.1/magnet/files', fields: {'id[]': id});
    final magnetRows = response['magnets'];
    if (magnetRows is! List || magnetRows.isEmpty || magnetRows.first is! Map) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    final files = <_DebridFile>[];
    _flattenAllDebridFiles((magnetRows.first as Map)['files'], '', files, 0);
    if (files.isEmpty) throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    final selected = _selectFile(files, fileIndex);
    await onProgress?.call(stage: 'file_selected', providerJobId: id);
    final unlocked = await _api('POST', '/v4/link/unlock', fields: {'link': selected.url.toString()});
    final rawUrl = unlocked['link'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    return ResolvedRemoteStream(uri: uri, fileName: selected.name, size: selected.size);
  }

  Future<ResolvedRemoteStream> resolveHosterLink(Uri link) async {
    if (link.scheme != 'https' || link.host.isEmpty || link.userInfo.isNotEmpty || link.toString().length > 4096) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    final result = await _api('POST', '/v4/link/unlock', fields: {'link': link.toString()});
    final rawUrl = result['link'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    final rawName = result['filename'];
    final name = _safeFileName(rawName is String ? rawName : link.pathSegments.lastOrNull ?? 'Video.mp4');
    return ResolvedRemoteStream(
      uri: uri,
      fileName: name,
      size: result['filesize'] is num ? (result['filesize'] as num).toInt() : null,
    );
  }

  Future<RemoteCloudPage> browseCloud({String? magnetId}) async {
    if (magnetId == null) {
      final response = await _api('POST', '/v4.1/magnet/status');
      final magnets = response['magnets'];
      if (magnets is! List) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      return RemoteCloudPage(
        items: [
          for (final raw in magnets)
            if (raw is Map)
              if ((raw['statusCode'] == 4 || raw['ready'] == true) && raw['id'] != null)
                RemoteCloudItem(
                  id: 'ad:${raw['id']}',
                  name: _safeFileName(raw['filename'] as String? ?? raw['name'] as String? ?? 'Magnet'),
                  service: RemoteStreamService.allDebrid,
                  kind: RemoteCloudItemKind.folder,
                  size: _safeSize(raw['size']),
                  providerId: raw['id'].toString(),
                ),
        ],
      );
    }
    if (!RegExp(r'^\d{1,16}$').hasMatch(magnetId)) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    final result = await _api('POST', '/v4.1/magnet/files', fields: {'id[]': magnetId});
    final magnets = result['magnets'];
    if (magnets is! List || magnets.isEmpty || magnets.first is! Map) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    final files = <_DebridFile>[];
    _flattenAllDebridFiles((magnets.first as Map)['files'], '', files, 0);
    return RemoteCloudPage(
      items: [
        for (final file in files)
          RemoteCloudItem(
            id: 'ad:$magnetId:${file.id ?? file.name}',
            name: file.name,
            service: RemoteStreamService.allDebrid,
            kind: RemoteCloudItemKind.file,
            size: file.size,
            providerId: magnetId,
            providerFileId: file.id,
            uri: file.url,
          ),
      ],
    );
  }

  Future<Map<String, dynamic>> _api(String method, String path, {Map<String, String>? fields}) async {
    final uri = Uri.parse('$_base$path');
    final headers = {'authorization': 'Bearer ${account.accessToken}', 'accept': 'application/json'};
    final response = await (method == 'GET'
            ? _http.get(uri, headers: headers)
            : _http.post(uri, headers: headers, body: fields ?? const {}))
        .timeout(const Duration(seconds: 20));
    return _decodeEnvelope(response.bodyBytes, response.statusCode);
  }

  void close() => _http.close();
}

class AllDebridDeviceCode {
  const AllDebridDeviceCode({required this.pin, required this.check, required this.userUrl, required this.expiresInSeconds});
  final String pin;
  final String check;
  final Uri userUrl;
  final int expiresInSeconds;
}

class PremiumizeClient {
  PremiumizeClient({http.Client? client, required this.account}) : _http = client ?? http.Client();
  static const _base = 'https://www.premiumize.me/api';
  final http.Client _http;
  final RemoteStreamAccount account;

  static Future<RemoteStreamAccount> connectWithApiKey(String apiKey, {http.Client? client}) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(
            Uri.parse('$_base/account/info'),
            headers: {'authorization': 'Bearer ${apiKey.trim()}', 'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      final body = _decodeObject(response.bodyBytes, response.statusCode);
      if (body['status'] != 'success') throw const RemoteProviderException(RemoteProviderFailure.authentication);
      final customer = body['customer_id'];
      return RemoteStreamAccount.create(
        service: RemoteStreamService.premiumize,
        displayName: customer == null ? 'Premiumize' : 'Premiumize · $customer',
        accessToken: apiKey.trim(),
      );
    } finally {
      if (owned) httpClient.close();
    }
  }

  Future<ResolvedRemoteStream> resolveTorrentHash(
    String hash, {
    int? fileIndex,
    bool Function()? shouldCancel,
    RemotePreparationProgress? onProgress,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hash)) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    if (shouldCancel?.call() == true) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    await onProgress?.call(stage: 'provider_request');
    final response = await _http
        .post(
          Uri.parse('$_base/transfer/directdl'),
          headers: {'authorization': 'Bearer ${account.accessToken}', 'accept': 'application/json'},
          body: {'src': 'magnet:?xt=urn:btih:${hash.toLowerCase()}'},
        )
        .timeout(const Duration(seconds: 90));
    final body = _decodeObject(response.bodyBytes, response.statusCode);
    if (body['status'] != 'success') throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    final content = body['content'];
    if (content is! List) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    await onProgress?.call(stage: 'files_ready');
    final files = <_DebridFile>[];
    for (final item in content) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      final rawUrl = row['link'];
      final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) continue;
      files.add(_DebridFile(
        name: _safeFileName(row['path'] as String? ?? 'Video'),
        url: uri,
        size: row['size'] is num ? (row['size'] as num).toInt() : null,
      ));
    }
    if (files.isEmpty) throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    final selected = _selectFile(files, fileIndex);
    await onProgress?.call(stage: 'file_selected');
    return ResolvedRemoteStream(uri: selected.url, fileName: selected.name, size: selected.size);
  }

  Future<ResolvedRemoteStream> resolveHosterLink(Uri link) async {
    if (link.scheme != 'https' || link.host.isEmpty || link.userInfo.isNotEmpty || link.toString().length > 4096) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    final response = await _http
        .post(
          Uri.parse('$_base/transfer/directdl'),
          headers: {'authorization': 'Bearer ${account.accessToken}', 'accept': 'application/json'},
          body: {'src': link.toString()},
        )
        .timeout(const Duration(seconds: 90));
    final body = _decodeObject(response.bodyBytes, response.statusCode);
    if (body['status'] != 'success') throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    final content = body['content'];
    if (content is! List) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    final files = <_DebridFile>[];
    for (final item in content) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      final rawUrl = row['link'];
      final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) continue;
      files.add(_DebridFile(
        name: _safeFileName(row['path'] as String? ?? 'Video'),
        url: uri,
        size: row['size'] is num ? (row['size'] as num).toInt() : null,
      ));
    }
    if (files.isEmpty) throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    final selected = _selectFile(files, null);
    return ResolvedRemoteStream(uri: selected.url, fileName: selected.name, size: selected.size);
  }

  Future<RemoteCloudPage> browseCloud({String? folderId}) async {
    final baseUri = Uri.parse('$_base/folder/list');
    final uri = baseUri.replace(queryParameters: {
      if (folderId != null && folderId.isNotEmpty) 'id': folderId,
    });
    final response = await _http
        .get(uri, headers: {'authorization': 'Bearer ${account.accessToken}', 'accept': 'application/json'})
        .timeout(const Duration(seconds: 25));
    final body = _decodeObject(response.bodyBytes, response.statusCode);
    final content = body['content'];
    if (content is! List) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    final items = <RemoteCloudItem>[];
    for (final raw in content) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final rawId = row['id'];
      final name = row['name'];
      if (rawId == null || name is! String || name.trim().isEmpty || name.length > 512) continue;
      final id = rawId.toString();
      final type = row['type'];
      if (type != 'folder' && type != 'file') continue;
      final isFolder = type == 'folder';
      final rawLink = row['link'];
      final link = rawLink is String ? Uri.tryParse(rawLink) : null;
      if (!isFolder &&
          (link == null ||
              link.scheme != 'https' ||
              link.host.isEmpty ||
              link.userInfo.isNotEmpty ||
              link.toString().length > 8192)) {
        continue;
      }
      items.add(RemoteCloudItem(
        id: 'pm:${isFolder ? 'folder' : 'file'}:$id',
        name: _safeFileName(name),
        service: RemoteStreamService.premiumize,
        kind: isFolder ? RemoteCloudItemKind.folder : RemoteCloudItemKind.file,
        size: _safeSize(row['size']),
        mimeType: row['mime_type'] as String?,
        providerId: id,
        providerFileId: isFolder ? null : id,
        uri: isFolder ? null : link,
      ));
    }
    return RemoteCloudPage(items: items);
  }

  void close() => _http.close();
}

class TorBoxClient {
  TorBoxClient({http.Client? client, required this.account}) : _http = client ?? http.Client();
  static const _base = 'https://api.torbox.app/v1/api';
  final http.Client _http;
  final RemoteStreamAccount account;

  static Future<RemoteStreamAccount> connectWithApiKey(String apiKey, {http.Client? client}) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(
            Uri.parse('$_base/user/me'),
            headers: {'authorization': 'Bearer ${apiKey.trim()}', 'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      final envelope = _decodeObject(response.bodyBytes, response.statusCode);
      if (envelope['success'] != true || envelope['data'] is! Map) {
        throw const RemoteProviderException(RemoteProviderFailure.authentication);
      }
      final user = Map<String, dynamic>.from(envelope['data'] as Map);
      final email = user['email'];
      final username = user['username'];
      final name = username is String && username.trim().isNotEmpty
          ? username.trim()
          : email is String && email.trim().isNotEmpty
          ? email.trim()
          : 'TorBox';
      return RemoteStreamAccount.create(
        service: RemoteStreamService.torbox,
        displayName: name,
        accessToken: apiKey.trim(),
      );
    } finally {
      if (owned) httpClient.close();
    }
  }

  Future<ResolvedRemoteStream> resolveTorrentHash(
    String hash, {
    int? fileIndex,
    bool Function()? shouldCancel,
    RemotePreparationProgress? onProgress,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hash)) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    if (shouldCancel?.call() == true) throw const RemoteProviderException(RemoteProviderFailure.cancelled);

    // Reuse a matching account item when available so repeated playback does
    // not create another remote item. New items are admitted only when cached.
    final listUri = Uri.parse('$_base/torrents/mylist').replace(queryParameters: {'bypass_cache': 'true', 'limit': '1000'});
    final list = await _request('GET', listUri);
    final rows = list['data'];
    final existing = rows is List
        ? rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).where((row) =>
            (row['hash'] as String?)?.toLowerCase() == hash.toLowerCase() && row['id'] != null,
          ).firstOrNull
        : null;
    var torrent = existing;
    if (torrent != null) {
      await onProgress?.call(stage: 'provider_job_found', providerJobId: '${torrent['id']}');
    }
    if (torrent == null) {
      final created = await _request(
        'POST',
        Uri.parse('$_base/torrents/createtorrent'),
        fields: {
          'magnet': 'magnet:?xt=urn:btih:${hash.toLowerCase()}',
          'seed': '3',
          'allow_zip': 'false',
          'add_only_if_cached': 'true',
        },
      );
      final data = created['data'];
      if (data is! Map || data['torrent_id'] == null) {
        throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
      }
      final id = data['torrent_id'].toString();
      await onProgress?.call(stage: 'provider_job_created', providerJobId: id);
      torrent = await _loadTorrent(id);
    }
    if (shouldCancel?.call() == true) throw const RemoteProviderException(RemoteProviderFailure.cancelled);
    if (!_isTorBoxReady(torrent)) {
      throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    }
    await onProgress?.call(stage: 'files_ready', providerJobId: '${torrent['id']}');
    final rawFiles = torrent['files'];
    final files = <_DebridFile>[];
    if (rawFiles is List) {
      for (final item in rawFiles) {
        if (item is! Map) continue;
        final row = Map<String, dynamic>.from(item);
        final fileId = row['id'];
        if (fileId == null) continue;
        files.add(_DebridFile(
          name: _safeFileName(row['name'] as String? ?? 'Video'),
          size: row['size'] is num ? (row['size'] as num).toInt() : null,
          url: Uri.https('pending.invalid', '/$fileId'),
          id: fileId.toString(),
        ));
      }
    }
    if (files.isEmpty) throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    final selected = _selectFile(files, fileIndex);
    await onProgress?.call(stage: 'file_selected', providerJobId: '${torrent['id']}');
    final downloadUri = Uri.parse('$_base/torrents/requestdl').replace(queryParameters: {
      'token': account.accessToken,
      'torrent_id': '${torrent['id']}',
      'file_id': selected.id!,
      'redirect': 'false',
      'append_name': 'true',
    });
    final download = await _request('GET', downloadUri);
    final rawUrl = download['data'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    return ResolvedRemoteStream(uri: uri, fileName: selected.name, size: selected.size);
  }

  Future<RemoteCloudPage> browseCloud({String? torrentId, int offset = 0, int limit = 100}) async {
    if (torrentId == null) {
      if (offset < 0 || offset > 1000000000 || limit < 1 || limit > 100) {
        throw const RemoteProviderException(RemoteProviderFailure.unsupported);
      }
      final uri = Uri.parse('$_base/torrents/mylist').replace(queryParameters: {
        'bypass_cache': 'true',
        'limit': '$limit',
        'offset': '$offset',
      });
      final response = await _request('GET', uri);
      final rows = response['data'];
      if (rows is! List) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
      return RemoteCloudPage(
        items: [
          for (final raw in rows)
            if (raw is Map)
              if (_isTorBoxReady(Map<String, dynamic>.from(raw)) && raw['id'] != null)
                RemoteCloudItem(
                  id: 'tb:${raw['id']}',
                  name: _safeFileName(raw['name'] as String? ?? 'Torrent'),
                  service: RemoteStreamService.torbox,
                  kind: RemoteCloudItemKind.folder,
                  size: _safeSize(raw['size']),
                  providerId: raw['id'].toString(),
                ),
        ],
        nextCursor: rows.length >= limit ? '${offset + limit}' : null,
      );
    }
    if (torrentId.isEmpty || torrentId.length > 128) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    final torrent = await _loadTorrent(torrentId);
    if (!_isTorBoxReady(torrent)) return const RemoteCloudPage(items: []);
    final rawFiles = torrent['files'];
    if (rawFiles is! List) return const RemoteCloudPage(items: []);
    return RemoteCloudPage(
      items: [
        for (final raw in rawFiles)
          if (raw is Map)
            if (raw['id'] != null && raw['name'] is String)
              RemoteCloudItem(
                id: 'tb:$torrentId:${raw['id']}',
                name: _safeFileName(raw['name'] as String),
                service: RemoteStreamService.torbox,
                kind: RemoteCloudItemKind.file,
                size: _safeSize(raw['size']),
                mimeType: raw['mime_type'] as String? ?? raw['mimetype'] as String?,
                providerId: torrentId,
                providerFileId: raw['id'].toString(),
              ),
      ],
    );
  }

  Future<ResolvedRemoteStream> resolveCloudFile(RemoteCloudItem item) async {
    final torrentId = item.providerId;
    final fileId = item.providerFileId;
    if (torrentId == null || fileId == null || torrentId.length > 128 || fileId.length > 128) {
      throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    }
    final uri = Uri.parse('$_base/torrents/requestdl').replace(queryParameters: {
      'token': account.accessToken,
      'torrent_id': torrentId,
      'file_id': fileId,
      'redirect': 'false',
      'append_name': 'true',
    });
    final response = await _request('GET', uri);
    final rawUrl = response['data'];
    final downloadUri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (downloadUri == null || downloadUri.scheme != 'https' || downloadUri.host.isEmpty || downloadUri.userInfo.isNotEmpty) {
      throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    }
    return ResolvedRemoteStream(uri: downloadUri, fileName: item.name, size: item.size);
  }

  Future<Map<String, dynamic>> _loadTorrent(String id) async {
    final uri = Uri.parse('$_base/torrents/mylist').replace(queryParameters: {'id': id, 'bypass_cache': 'true'});
    final response = await _request('GET', uri);
    final data = response['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) return Map<String, dynamic>.from(data.first as Map);
    throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
  }

  static bool _isTorBoxReady(Map<String, dynamic> row) =>
      row['cached'] == true || row['download_finished'] == true || row['status'] == 'cached';

  Future<Map<String, dynamic>> _request(
    String method,
    Uri uri, {
    Map<String, String>? fields,
  }) async {
    final headers = {'accept': 'application/json', 'authorization': 'Bearer ${account.accessToken}'};
    late final http.Response response;
    if (method == 'GET') {
      response = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    } else if (uri.path.endsWith('/torrents/createtorrent')) {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields.addAll(fields ?? const {});
      response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 30)),
      ).timeout(const Duration(seconds: 30));
    } else {
      response = await _http.post(uri, headers: headers, body: fields ?? const {}).timeout(const Duration(seconds: 30));
    }
    final envelope = _decodeObject(response.bodyBytes, response.statusCode);
    if (envelope['success'] != true) {
      final error = envelope['error'];
      if (error == 'AUTH_INVALID' || error == 'INVALID_TOKEN') {
        throw const RemoteProviderException(RemoteProviderFailure.authentication);
      }
      throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
    }
    return envelope;
  }

  void close() => _http.close();
}

class _DebridFile {
  const _DebridFile({required this.name, required this.url, this.size, this.id});
  final String name;
  final Uri url;
  final int? size;
  final String? id;
}

List<_DebridFile> _flattenAllDebridFiles(Object? raw, String parent, List<_DebridFile> output, int depth) {
  if (depth > 20 || output.length > 10000 || raw is! List) return output;
  for (final item in raw) {
    if (item is! Map || output.length > 10000) continue;
    final row = Map<String, dynamic>.from(item);
    final name = row['n'];
    if (name is! String || name.isEmpty || name.length > 512) continue;
    final path = parent.isEmpty ? name : '$parent/$name';
    final children = row['e'];
    if (children is List) {
      _flattenAllDebridFiles(children, path, output, depth + 1);
      continue;
    }
    final rawUrl = row['l'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) continue;
    output.add(_DebridFile(
      name: _safeFileName(path),
      url: uri,
      size: _safeSize(row['s']),
      id: path,
    ));
  }
  return output;
}

_DebridFile _selectFile(List<_DebridFile> files, int? fileIndex) {
  if (fileIndex != null) {
    if (fileIndex < 0 || fileIndex >= files.length) throw const RemoteProviderException(RemoteProviderFailure.unsupported);
    return files[fileIndex];
  }
  final videos = files.where((file) => _isVideoName(file.name)).toList();
  final pool = videos.isEmpty ? files : videos;
  pool.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
  return pool.first;
}

String _safeFileName(String value) {
  final normalized = value.replaceAll('\\', '/').split('/').where((part) => part.isNotEmpty && part != '.' && part != '..').lastOrNull;
  final name = (normalized ?? 'Video').replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
  if (name.isEmpty) return 'Video.mp4';
  return name.length > 240 ? name.substring(name.length - 240) : name;
}

bool _isVideoName(String name) =>
    const {'.mkv', '.mp4', '.avi', '.m4v', '.mov', '.ts', '.webm', '.mpg', '.mpeg'}
        .contains(name.contains('.') ? name.substring(name.lastIndexOf('.')).toLowerCase() : '');

Map<String, dynamic> _decodeObject(List<int> bytes, int statusCode) {
  if (statusCode == 401 || statusCode == 403) throw const RemoteProviderException(RemoteProviderFailure.authentication);
  if (statusCode < 200 || statusCode >= 300 || bytes.length > 2 * 1024 * 1024) {
    throw const RemoteProviderException(RemoteProviderFailure.unavailable);
  }
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
  return Map<String, dynamic>.from(decoded);
}

Map<String, dynamic> _decodeEnvelope(List<int> bytes, int statusCode, {bool allowPending = false}) {
  final decoded = _decodeObject(bytes, statusCode);
  final status = decoded['status'];
  if (status == 'success') {
    final data = decoded['data'];
    if (data is! Map) throw const RemoteProviderException(RemoteProviderFailure.invalidResponse);
    return Map<String, dynamic>.from(data);
  }
  if (allowPending && status == 'error') {
    final error = decoded['error'];
    final code = error is Map ? error['code'] : null;
    if (code == 'AUTH_MISSING' || code == 'PIN_NOT_VALIDATED' || code == 'AUTH_PIN_MISSING') {
      return {'data': const <String, dynamic>{}};
    }
  }
  if (statusCode == 401 || statusCode == 403) throw const RemoteProviderException(RemoteProviderFailure.authentication);
  throw const RemoteProviderException(RemoteProviderFailure.preparationFailed);
}

int _int(Object? value, {required int fallback}) => value is num ? value.toInt() : fallback;

int? _safeSize(Object? value) {
  if (value is int && value >= 0) return value;
  if (value is num && value.isFinite && value >= 0) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0) return parsed;
  }
  return null;
}
