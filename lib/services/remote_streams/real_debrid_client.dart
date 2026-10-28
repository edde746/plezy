import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'remote_stream_models.dart';

class RealDebridException implements Exception {
  const RealDebridException(this.reason);
  final RealDebridFailure reason;
}

enum RealDebridFailure { authentication, unavailable, invalidResponse, unsupported, preparationFailed, timeout, cancelled }

class RealDebridDeviceCode {
  const RealDebridDeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.intervalSeconds,
    required this.expiresInSeconds,
  });
  final String deviceCode;
  final String userCode;
  final Uri verificationUrl;
  final int intervalSeconds;
  final int expiresInSeconds;
}

class ResolvedRemoteStream {
  const ResolvedRemoteStream({required this.uri, required this.fileName, this.size});
  final Uri uri;
  final String fileName;
  final int? size;
}

/// Real-Debrid's documented open-source device flow and torrent resolver.
/// The public app id is the one Real-Debrid publishes for open-source apps;
/// user-bound client credentials are acquired separately per account.
class RealDebridClient {
  RealDebridClient({http.Client? client, required RemoteStreamAccount account, this.onAccountRefreshed})
    : _http = client ?? http.Client(),
      _account = account;

  static const _publicClientId = 'X245A4XAIBGVM';
  static const _oauthBase = 'https://api.real-debrid.com/oauth/v2';
  static const _apiBase = 'https://api.real-debrid.com/rest/1.0';
  final http.Client _http;
  RemoteStreamAccount _account;
  final Future<void> Function(RemoteStreamAccount account)? onAccountRefreshed;
  Future<RemoteStreamAccount>? _refreshing;

  static Future<RealDebridDeviceCode> startDeviceAuthorization({http.Client? client}) async {
    final owned = client == null;
    final transport = client ?? http.Client();
    try {
      final uri = Uri.parse('$_oauthBase/device/code').replace(
        queryParameters: {'client_id': _publicClientId, 'new_credentials': 'yes'},
      );
      final response = await transport.get(uri, headers: const {'accept': 'application/json'}).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const RealDebridException(RealDebridFailure.unavailable);
      }
      final body = _decodeObject(response.bodyBytes);
      final deviceCode = body['device_code'];
      final userCode = body['user_code'];
      final verification = body['verification_url'];
      if (deviceCode is! String || userCode is! String || verification is! String) {
        throw const RealDebridException(RealDebridFailure.invalidResponse);
      }
      final verificationUrl = Uri.tryParse(verification);
      if (verificationUrl == null || verificationUrl.scheme != 'https' || verificationUrl.host != 'real-debrid.com') {
        throw const RealDebridException(RealDebridFailure.invalidResponse);
      }
      return RealDebridDeviceCode(
        deviceCode: deviceCode,
        userCode: userCode,
        verificationUrl: verificationUrl,
        intervalSeconds: _positiveInt(body['interval'], 5).clamp(3, 30).toInt(),
        expiresInSeconds: _positiveInt(body['expires_in'], 1800).clamp(60, 3600).toInt(),
      );
    } finally {
      if (owned) transport.close();
    }
  }

  static Future<RemoteStreamAccount?> finishDeviceAuthorization(
    RealDebridDeviceCode code, {
    bool Function()? shouldCancel,
    http.Client? client,
  }) async {
    final owned = client == null;
    final transport = client ?? http.Client();
    try {
      final deadline = DateTime.now().add(Duration(seconds: code.expiresInSeconds));
      Map<String, dynamic>? credentials;
      while (DateTime.now().isBefore(deadline)) {
        if (shouldCancel?.call() == true) return null;
        final uri = Uri.parse('$_oauthBase/device/credentials').replace(
          queryParameters: {'client_id': _publicClientId, 'code': code.deviceCode},
        );
        final response = await transport.get(uri, headers: const {'accept': 'application/json'}).timeout(
          const Duration(seconds: 15),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          credentials = _decodeObject(response.bodyBytes);
          break;
        }
        // Real-Debrid replies with a client error while the user has not yet
        // entered the code. Keep polling until authorization or expiry.
        if (response.statusCode != 400 && response.statusCode != 403 && response.statusCode != 404) {
          throw const RealDebridException(RealDebridFailure.unavailable);
        }
        await Future<void>.delayed(Duration(seconds: code.intervalSeconds));
      }
      if (credentials == null) return null;
      final clientId = credentials['client_id'];
      final clientSecret = credentials['client_secret'];
      if (clientId is! String || clientSecret is! String) {
        throw const RealDebridException(RealDebridFailure.invalidResponse);
      }
      final tokenResponse = await transport
          .post(
            Uri.parse('$_oauthBase/token'),
            headers: const {'accept': 'application/json'},
            body: {
              'client_id': clientId,
              'client_secret': clientSecret,
              'code': code.deviceCode,
              'grant_type': 'http://oauth.net/grant_type/device/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
        throw const RealDebridException(RealDebridFailure.authentication);
      }
      final token = _decodeObject(tokenResponse.bodyBytes);
      final access = token['access_token'];
      final refresh = token['refresh_token'];
      final expires = token['expires_in'];
      if (access is! String || refresh is! String || expires is! num) {
        throw const RealDebridException(RealDebridFailure.invalidResponse);
      }
      final account = RemoteStreamAccount.create(
        service: RemoteStreamService.realDebrid,
        displayName: 'Real-Debrid',
        accessToken: access,
        refreshToken: refresh,
        clientId: clientId,
        clientSecret: clientSecret,
        expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + expires.toInt(),
      );
      final clientApi = RealDebridClient(client: transport, account: account);
      final user = await clientApi._apiGet('/user');
      final username = user['username'];
      return RemoteStreamAccount(
        id: account.id,
        service: account.service,
        displayName: username is String && username.trim().isNotEmpty ? username.trim() : 'Real-Debrid',
        accessToken: account.accessToken,
        refreshToken: account.refreshToken,
        clientId: account.clientId,
        clientSecret: account.clientSecret,
        expiresAt: account.expiresAt,
      );
    } on RealDebridException {
      rethrow;
    } on Object {
      throw const RealDebridException(RealDebridFailure.unavailable);
    } finally {
      if (owned) transport.close();
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
      throw const RealDebridException(RealDebridFailure.unsupported);
    }
    if (_account.service != RemoteStreamService.realDebrid) {
      throw const RealDebridException(RealDebridFailure.authentication);
    }
    var torrentId = existingJobId ?? '';
    if (torrentId.isEmpty) {
      final magnet = 'magnet:?xt=urn:btih:${hash.toLowerCase()}';
      final created = await _apiPost('/torrents/addMagnet', {'magnet': magnet});
      final rawTorrentId = created['id'];
      torrentId = rawTorrentId is String ? rawTorrentId : rawTorrentId is num ? '$rawTorrentId' : '';
    }
    if (!RegExp(r'^\d{1,32}$').hasMatch(torrentId)) {
      throw const RealDebridException(RealDebridFailure.invalidResponse);
    }
    await onProgress?.call(
      stage: existingJobId == null || existingJobId.isEmpty ? 'provider_job_created' : 'provider_job_found',
      providerJobId: torrentId,
    );

    final deadline = DateTime.now().add(const Duration(minutes: 8));
    var selectedName = '';
    int? selectedSize;
    var filesSelected = false;
    String? lastStatus;
    while (DateTime.now().isBefore(deadline)) {
      if (shouldCancel?.call() == true) throw const RealDebridException(RealDebridFailure.cancelled);
      final info = await _apiGet('/torrents/info/${Uri.encodeComponent(torrentId)}');
      final remoteHash = info['hash'];
      if (remoteHash is! String || remoteHash.toLowerCase() != hash.toLowerCase()) {
        throw const RealDebridException(RealDebridFailure.preparationFailed);
      }
      final status = info['status'];
      if (status is String && status != lastStatus) {
        lastStatus = status;
        await onProgress?.call(
          stage: switch (status) {
            'waiting_files_selection' => 'selecting_files',
            'downloading' || 'queued' => 'preparing',
            'downloaded' => 'ready',
            _ => 'provider_processing',
          },
          providerJobId: torrentId,
        );
      }
      final files = _fileList(info['files']);
      if (!filesSelected && files.isNotEmpty && status == 'waiting_files_selection') {
        final selected = _chooseFile(files, fileIndex);
        final chosenId = selected['id'];
        if (chosenId == null) throw const RealDebridException(RealDebridFailure.invalidResponse);
        selectedName = selected['path'] as String? ?? 'Video';
        selectedSize = (selected['bytes'] as num?)?.toInt();
        await _apiPost('/torrents/selectFiles/${Uri.encodeComponent(torrentId)}', {'files': '$chosenId'});
        filesSelected = true;
        await onProgress?.call(stage: 'file_selected', providerJobId: torrentId);
        continue;
      }
      if (status == 'downloaded') {
        final selectedFiles = files.where((file) => file['selected'] == 1).toList(growable: false);
        if (selectedFiles.isEmpty) throw const RealDebridException(RealDebridFailure.preparationFailed);
        final requestedFile = fileIndex == null ? _chooseFile(selectedFiles, null) : _chooseFile(files, fileIndex);
        final selected = selectedFiles.where((file) => '${file['id']}' == '${requestedFile['id']}').firstOrNull;
        if (selected == null) throw const RealDebridException(RealDebridFailure.preparationFailed);
        final linkIndex = selectedFiles.indexWhere((file) => '${file['id']}' == '${selected['id']}');
        if (linkIndex < 0) throw const RealDebridException(RealDebridFailure.preparationFailed);
        selectedName = (selected['path'] as String?) ?? (selectedName.isNotEmpty ? selectedName : 'Video');
        selectedSize = (selected['bytes'] as num?)?.toInt() ?? selectedSize;
        final links = info['links'];
        if (links is! List || linkIndex >= links.length || links[linkIndex] is! String) {
          throw const RealDebridException(RealDebridFailure.invalidResponse);
        }
        final unrestricted = await _apiPost('/unrestrict/link', {'link': links[linkIndex] as String});
        final download = unrestricted['download'];
        final uri = download is String ? Uri.tryParse(download) : null;
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
          throw const RealDebridException(RealDebridFailure.invalidResponse);
        }
        return ResolvedRemoteStream(uri: uri, fileName: selectedName, size: selectedSize);
      }
      if (status == 'error' || status == 'magnet_error' || status == 'virus') {
        throw const RealDebridException(RealDebridFailure.preparationFailed);
      }
      await Future<void>.delayed(const Duration(seconds: 4));
    }
    throw const RealDebridException(RealDebridFailure.timeout);
  }

  Future<ResolvedRemoteStream> resolveHosterLink(Uri link) async {
    if (link.scheme != 'https' || link.host.isEmpty || link.userInfo.isNotEmpty || link.toString().length > 4096) {
      throw const RealDebridException(RealDebridFailure.unsupported);
    }
    final result = await _apiPost('/unrestrict/link', {'link': link.toString()});
    final rawUrl = result['download'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const RealDebridException(RealDebridFailure.invalidResponse);
    }
    final rawName = result['filename'] ?? result['original_filename'];
    final name = rawName is String ? rawName : link.pathSegments.isEmpty ? 'Video.mp4' : link.pathSegments.last;
    final safeName = name
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .lastOrNull
        ?.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '')
        .trim();
    return ResolvedRemoteStream(
      uri: uri,
      fileName: safeName == null || safeName.isEmpty
          ? 'Video.mp4'
          : safeName.length > 240
          ? safeName.substring(safeName.length - 240)
          : safeName,
      size: result['filesize'] is num ? (result['filesize'] as num).toInt() : null,
    );
  }

  Future<RemoteCloudPage> browseCloud({String? torrentId, int offset = 0, int limit = 100}) async {
    if (torrentId == null) {
      if (offset < 0 || offset > 1000000000 || limit < 1 || limit > 100) {
        throw const RealDebridException(RealDebridFailure.unsupported);
      }
      final rows = await _apiList('/torrents?limit=$limit&offset=$offset');
      return RemoteCloudPage(
        items: [
          for (final row in rows)
            if (row['status'] == 'downloaded' && row['id'] != null)
              RemoteCloudItem(
                id: 'rd:${row['id']}',
                name: _safeFileName(row['filename'] as String? ?? 'Torrent'),
                service: RemoteStreamService.realDebrid,
                kind: RemoteCloudItemKind.folder,
                size: (row['bytes'] as num?)?.toInt(),
                providerId: row['id'].toString(),
              ),
        ],
        nextCursor: rows.length >= limit ? '${offset + limit}' : null,
      );
    }
    if (torrentId.isEmpty || torrentId.length > 128) {
      throw const RealDebridException(RealDebridFailure.unsupported);
    }
    final info = await _apiGet('/torrents/info/${Uri.encodeComponent(torrentId)}');
    if (info['status'] != 'downloaded') return const RemoteCloudPage(items: []);
    final files = _fileList(info['files']).where((file) => file['selected'] == 1).toList(growable: false);
    final links = info['links'];
    if (files.isEmpty || links is! List || files.length != links.length) {
      return const RemoteCloudPage(items: []);
    }
    return RemoteCloudPage(
      items: [
        for (var index = 0; index < files.length; index++)
          if (links[index] is String)
            if (_safeProviderLink(links[index] as String) case final link?)
              RemoteCloudItem(
                id: 'rd:$torrentId:${files[index]['id']}',
                name: _safeFileName(files[index]['path'] as String? ?? 'Video.mp4'),
                service: RemoteStreamService.realDebrid,
                kind: RemoteCloudItemKind.file,
                size: (files[index]['bytes'] as num?)?.toInt(),
                providerId: torrentId,
                providerFileId: files[index]['id']?.toString(),
                uri: link,
              ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _apiList(String path) async {
    var active = await _currentAccount();
    var response = await _sendApiRequest('GET', path, active.accessToken);
    if (response.statusCode == 401 && active.refreshToken != null) {
      active = await _refresh(active);
      response = await _sendApiRequest('GET', path, active.accessToken);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RealDebridException(RealDebridFailure.authentication);
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || response.bodyBytes.length > 4 * 1024 * 1024) {
      throw const RealDebridException(RealDebridFailure.unavailable);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw const RealDebridException(RealDebridFailure.invalidResponse);
    return decoded.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<Map<String, dynamic>> _apiGet(String path) async => _apiRequest('GET', path);
  Future<Map<String, dynamic>> _apiPost(String path, Map<String, String> fields) async =>
      _apiRequest('POST', path, fields: fields);

  Future<Map<String, dynamic>> _apiRequest(String method, String path, {Map<String, String>? fields}) async {
    var active = await _currentAccount();
    var response = await _sendApiRequest(method, path, active.accessToken, fields: fields);
    if (response.statusCode == 401 && active.refreshToken != null) {
      active = await _refresh(active);
      response = await _sendApiRequest(method, path, active.accessToken, fields: fields);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RealDebridException(RealDebridFailure.authentication);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RealDebridException(RealDebridFailure.unavailable);
    }
    if (response.bodyBytes.isEmpty) return const {};
    return _decodeObject(response.bodyBytes);
  }

  Future<http.Response> _sendApiRequest(String method, String path, String token, {Map<String, String>? fields}) {
    final uri = Uri.parse('$_apiBase$path');
    final headers = {'authorization': 'Bearer $token', 'accept': 'application/json'};
    return (method == 'GET'
            ? _http.get(uri, headers: headers)
            : _http.post(uri, headers: headers, body: fields ?? const {}))
        .timeout(const Duration(seconds: 20));
  }

  Future<RemoteStreamAccount> _currentAccount() async {
    final expiresAt = _account.expiresAt;
    if (expiresAt == null || expiresAt > DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60) return _account;
    return _refresh(_account);
  }

  Future<RemoteStreamAccount> _refresh(RemoteStreamAccount old) async {
    final current = _refreshing;
    if (current != null) return current;
    final refreshToken = old.refreshToken, clientId = old.clientId, clientSecret = old.clientSecret;
    if (refreshToken == null || clientId == null || clientSecret == null) {
      throw const RealDebridException(RealDebridFailure.authentication);
    }
    late final Future<RemoteStreamAccount> pending;
    pending = () async {
      try {
        final response = await _http
            .post(
              Uri.parse('$_oauthBase/token'),
              headers: const {'accept': 'application/json'},
              body: {
                'client_id': clientId,
                'client_secret': clientSecret,
                'code': refreshToken,
                'grant_type': 'http://oauth.net/grant_type/device/1.0',
              },
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw const RealDebridException(RealDebridFailure.authentication);
        }
        final json = _decodeObject(response.bodyBytes);
        final access = json['access_token'];
        final nextRefresh = json['refresh_token'];
        final expires = json['expires_in'];
        if (access is! String || nextRefresh is! String || expires is! num) {
          throw const RealDebridException(RealDebridFailure.invalidResponse);
        }
        final updated = old.copyWith(
          accessToken: access,
          refreshToken: nextRefresh,
          expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + expires.toInt(),
        );
        _account = updated;
        await onAccountRefreshed?.call(updated);
        return updated;
      } on RealDebridException {
        rethrow;
      } on Object {
        throw const RealDebridException(RealDebridFailure.unavailable);
      } finally {
        _refreshing = null;
      }
    }();
    _refreshing = pending;
    return pending;
  }

  static List<Map<String, dynamic>> _fileList(Object? raw) => raw is List
      ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList(growable: false)
      : const [];

  static Map<String, dynamic> _chooseFile(List<Map<String, dynamic>> files, int? fileIndex) {
    if (fileIndex != null) {
      if (fileIndex < 0 || fileIndex >= files.length) throw const RealDebridException(RealDebridFailure.unsupported);
      return files[fileIndex];
    }
    final video = files.where((file) => _looksLikeVideo(file['path'] as String? ?? '')).toList();
    final pool = video.isEmpty ? files : video;
    pool.sort((a, b) => ((b['bytes'] as num?)?.toInt() ?? 0).compareTo((a['bytes'] as num?)?.toInt() ?? 0));
    return pool.first;
  }

  static bool _looksLikeVideo(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return const {'.mkv', '.mp4', '.avi', '.m4v', '.mov', '.ts', '.webm', '.mpg', '.mpeg'}
        .contains(path.substring(dot).toLowerCase());
  }

  static Map<String, dynamic> _decodeObject(List<int> bytes) {
    if (bytes.length > 1024 * 1024) throw const RealDebridException(RealDebridFailure.invalidResponse);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const RealDebridException(RealDebridFailure.invalidResponse);
    return Map<String, dynamic>.from(decoded);
  }

  static String _safeFileName(String value) {
    final pieces = value.replaceAll('\\', '/').split('/').where((part) => part.isNotEmpty && part != '.' && part != '..');
    final name = pieces.isEmpty ? 'Video.mp4' : pieces.last.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (name.isEmpty) return 'Video.mp4';
    return name.length > 240 ? name.substring(name.length - 240) : name;
  }

  static Uri? _safeProviderLink(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty ? uri : null;
  }

  static int _positiveInt(Object? value, int fallback) => value is num && value > 0 ? value.toInt() : fallback;

  void close() => _http.close();
}
