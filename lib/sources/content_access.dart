import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:background_downloader/background_downloader.dart';
import 'package:disk_usage/disk_usage.dart';
import 'package:path/path.dart' as p;

import '../services/credential_vault.dart';
import 'source_database.dart';
import 'source_models.dart';
import 'adapters/s3_source.dart';
import 'source_oauth.dart';
import 'source_transport.dart';

const _encryptedLeaseTaskUrl = 'https://plezyng.invalid/native-download';

/// Native task rows contain only this encrypted lease in [Task.metaData].
/// Decryption, provider renewal, and request-header installation happen in
/// the headless callback immediately before a run.
class _RenewedBackgroundLease {
  const _RenewedBackgroundLease(this.uri, this.headers, {this.refreshDescriptor});
  final Uri uri;
  final Map<String, String> headers;
  final Map<String, dynamic>? refreshDescriptor;
}

String? _renewalText(Map<String, dynamic> data, String key, {int maxLength = 4096}) {
  final value = data[key];
  if (value is! String || value.isEmpty || value.length > maxLength || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
    return null;
  }
  return value;
}

int? _renewalNumber(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num && value.isFinite && value >= 0) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int? _renewalSize(Map<String, dynamic> data) => _renewalNumber(data, 'size');

void _checkRenewedRepresentation(Map<String, dynamic> descriptor, String? revision, int? size) {
  final expectedRevision = _renewalText(descriptor, 'revision', maxLength: 2048);
  if (expectedRevision != null && expectedRevision != revision) {
    throw const SourceException(SourceFailure.conflict);
  }
  final expectedSize = _renewalSize(descriptor);
  if (expectedSize == null || size == null || expectedSize != size) {
    throw const SourceException(SourceFailure.conflict);
  }
}

Future<Map<String, dynamic>> _renewalJson(
  Uri uri, {
  String method = 'POST',
  Map<String, String> headers = const {},
  Map<String, String>? form,
  Object? jsonBody,
}) async {
  if (uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.toString().length > 8192) {
    throw const SourceException(SourceFailure.permission);
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  // Per-chunk idle timeouts alone allow a peer to keep a lease renewal alive
  // indefinitely by trickling bytes. Bound the entire connection and response.
  final hardDeadline = Timer(const Duration(seconds: 45), () => client.close(force: true));
  try {
    final request = await client.openUrl(method, uri).timeout(const Duration(seconds: 15));
    request.followRedirects = false;
    request.maxRedirects = 0;
    headers.forEach((name, value) => request.headers.set(name, value));
    if (form != null) {
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write(Uri(queryParameters: form).query);
    } else if (jsonBody != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(jsonBody));
    }
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) throw const SourceException(SourceFailure.unavailable);
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 65536) throw const SourceException(SourceFailure.invalidData);
      bytes.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const SourceException(SourceFailure.invalidData);
    return Map<String, dynamic>.from(decoded);
  } finally {
    hardDeadline.cancel();
    client.close(force: true);
  }
}

Future<Map<String, dynamic>> _refreshProviderToken(Map<String, dynamic> descriptor) async {
  final provider = _renewalText(descriptor, 'provider', maxLength: 32);
  final clientId = _renewalText(descriptor, 'clientId');
  final refreshToken = _renewalText(descriptor, 'refreshToken', maxLength: 8192);
  if (clientId == null || refreshToken == null) throw const SourceException(SourceFailure.authentication);
  final endpoint = switch (provider) {
    'googleDrive' => Uri.https('oauth2.googleapis.com', '/token'),
    'oneDrive' => Uri.https('login.microsoftonline.com', '/common/oauth2/v2.0/token'),
    'dropbox' => Uri.https('api.dropboxapi.com', '/oauth2/token'),
    _ => throw const SourceException(SourceFailure.unsupported),
  };
  final body = <String, String>{
    'grant_type': 'refresh_token',
    'refresh_token': refreshToken,
    'client_id': clientId,
    'client_secret': ?_renewalText(descriptor, 'clientSecret', maxLength: 4096),
  };
  final result = await _renewalJson(endpoint, form: body);
  final accessToken = result['access_token'];
  if (accessToken is! String || accessToken.isEmpty || accessToken.length > 16384) {
    throw const SourceException(SourceFailure.authentication);
  }
  final rotated = result['refresh_token'];
  return {
    'accessToken': accessToken,
    if (rotated is String && rotated.isNotEmpty && rotated.length <= 8192) 'refreshToken': rotated,
  };
}

bool _hostMatchesDomain(String host, Iterable<String> domains) {
  final normalized = host.toLowerCase();
  return domains.any((domain) => normalized == domain || normalized.endsWith('.$domain'));
}

bool _safeProviderDownloadUri(Uri uri, Iterable<String> domains) =>
    uri.scheme == 'https' &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    !uri.hasFragment &&
    (!uri.hasPort || uri.port == 443) &&
    uri.toString().length <= 8192 &&
    InternetAddress.tryParse(uri.host) == null &&
    _hostMatchesDomain(uri.host, domains);

bool _safeRemoteCloudDownloadUri(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host.isNotEmpty &&
    uri.host.contains('.') &&
    !uri.host.toLowerCase().endsWith('.localhost') &&
    !uri.host.toLowerCase().endsWith('.local') &&
    !uri.host.toLowerCase().endsWith('.internal') &&
    uri.userInfo.isEmpty &&
    !uri.hasFragment &&
    (!uri.hasPort || uri.port == 443) &&
    uri.toString().length <= 8192 &&
    InternetAddress.tryParse(uri.host) == null;

Future<Map<String, dynamic>> _remoteCloudApi(
  String host,
  String path, {
  required String token,
  String method = 'GET',
  Map<String, String>? query,
  Map<String, String>? form,
}) => _renewalJson(
  Uri.https(host, path, query),
  method: method,
  headers: {'Authorization': 'Bearer $token'},
  form: form,
);

String? _remoteCloudId(Map<String, dynamic> descriptor, String key, {int maxLength = 128}) {
  final value = _renewalText(descriptor, key, maxLength: maxLength);
  if (value == null || value == '.' || value == '..' || value.contains('/') || value.contains('\\')) return null;
  return value;
}

String? _remoteCloudFileId(Map<String, dynamic> descriptor) {
  final value = _renewalText(descriptor, 'providerFileId', maxLength: 1024);
  if (value == null || value == '.' || value == '..' || value.contains('\\')) return null;
  if (value.split('/').any((segment) => segment == '.' || segment == '..')) return null;
  return value;
}

Future<_RenewedBackgroundLease> _renewRemoteCloudBackgroundLease(Map<String, dynamic> descriptor) async {
  final service = _renewalText(descriptor, 'service', maxLength: 32);
  final accountId = _remoteCloudId(descriptor, 'accountId');
  final providerId = _remoteCloudId(descriptor, 'providerId');
  final fileId = _remoteCloudFileId(descriptor);
  final expectedSize = _renewalSize(descriptor);
  var accessToken = _renewalText(descriptor, 'accessToken', maxLength: 16384);
  if (service == null ||
      accountId == null ||
      providerId == null ||
      fileId == null ||
      expectedSize == null ||
      expectedSize <= 0 ||
      accessToken == null) {
    throw const SourceException(SourceFailure.permission);
  }

  var updatedDescriptor = Map<String, dynamic>.from(descriptor);
  if (service == 'realDebrid') {
    final refreshToken = _renewalText(descriptor, 'refreshToken', maxLength: 8192);
    final clientId = _renewalText(descriptor, 'clientId', maxLength: 512);
    final clientSecret = _renewalText(descriptor, 'clientSecret', maxLength: 4096);
    final expiresAt = _renewalNumber(descriptor, 'expiresAt');
    if (expiresAt != null && expiresAt <= DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60) {
      if (refreshToken == null || clientId == null || clientSecret == null) {
        throw const SourceException(SourceFailure.authentication);
      }
      final refreshed = await _renewalJson(
        Uri.https('api.real-debrid.com', '/oauth/v2/token'),
        form: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': refreshToken,
          'grant_type': 'http://oauth.net/grant_type/device/1.0',
        },
      );
      final nextAccessToken = _renewalText(refreshed, 'access_token', maxLength: 16384);
      final nextRefreshToken = _renewalText(refreshed, 'refresh_token', maxLength: 8192);
      final expiresIn = _renewalNumber(refreshed, 'expires_in');
      if (nextAccessToken == null || nextRefreshToken == null || expiresIn == null || expiresIn <= 0) {
        throw const SourceException(SourceFailure.authentication);
      }
      accessToken = nextAccessToken;
      updatedDescriptor
        ..['accessToken'] = nextAccessToken
        ..['refreshToken'] = nextRefreshToken
        ..['expiresAt'] = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
    }

    if (!RegExp(r'^\d{1,32}$').hasMatch(providerId) || !RegExp(r'^\d{1,32}$').hasMatch(fileId)) {
      throw const SourceException(SourceFailure.permission);
    }
    final info = await _remoteCloudApi(
      'api.real-debrid.com',
      '/rest/1.0/torrents/info/$providerId',
      token: accessToken,
    );
    if (info['status'] != 'downloaded' || info['files'] is! List || info['links'] is! List) {
      throw const SourceException(SourceFailure.conflict);
    }
    final allFiles = (info['files'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    final selectedFiles = allFiles.where((row) => row['selected'] == 1).toList(growable: false);
    final fileIndex = selectedFiles.indexWhere((row) => '${row['id']}' == fileId);
    if (fileIndex < 0 || fileIndex >= (info['links'] as List).length) throw const SourceException(SourceFailure.conflict);
    final selected = selectedFiles[fileIndex];
    final size = _renewalNumber(selected, 'bytes');
    final stableRevision = 'realDebrid:$providerId:$fileId:$size';
    _checkRenewedRepresentation(descriptor, stableRevision, size);
    final rawLink = (info['links'] as List)[fileIndex];
    if (rawLink is! String || rawLink.length > 8192) throw const SourceException(SourceFailure.invalidData);
    final unrestricted = await _remoteCloudApi(
      'api.real-debrid.com',
      '/rest/1.0/unrestrict/link',
      token: accessToken,
      method: 'POST',
      form: {'link': rawLink},
    );
    final rawUrl = unrestricted['download'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || !_safeRemoteCloudDownloadUri(uri)) throw const SourceException(SourceFailure.permission);
    return _RenewedBackgroundLease(uri, const {}, refreshDescriptor: updatedDescriptor);
  }

  if (service == 'allDebrid') {
    if (!RegExp(r'^\d{1,32}$').hasMatch(providerId)) throw const SourceException(SourceFailure.permission);
    final response = await _remoteCloudApi(
      'api.alldebrid.com',
      '/v4.1/magnet/files',
      token: accessToken,
      method: 'POST',
      form: {'id[]': providerId},
    );
    final magnets = response['magnets'];
    if (magnets is! List || magnets.isEmpty || magnets.first is! Map) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final files = <({String path, String link, int? size})>[];
    void collect(Object? rows, String parent, int depth) {
      if (depth > 20 || files.length >= 10000 || rows is! List) return;
      for (final raw in rows) {
        if (raw is! Map || files.length >= 10000) continue;
        final row = Map<String, dynamic>.from(raw);
        final name = row['n'];
        if (name is! String || name.isEmpty || name.length > 512) continue;
        final path = parent.isEmpty ? name : '$parent/$name';
        final children = row['e'];
        if (children is List) {
          collect(children, path, depth + 1);
        } else if (row['l'] is String && (row['l'] as String).length <= 8192) {
          files.add((path: path, link: row['l'] as String, size: _renewalNumber(row, 's')));
        }
      }
    }

    collect((magnets.first as Map)['files'], '', 0);
    final selected = files.where((file) => file.path == fileId).firstOrNull;
    if (selected == null) throw const SourceException(SourceFailure.conflict);
    final stableRevision = 'allDebrid:$providerId:$fileId:${selected.size}';
    _checkRenewedRepresentation(descriptor, stableRevision, selected.size);
    final unlocked = await _remoteCloudApi(
      'api.alldebrid.com',
      '/v4/link/unlock',
      token: accessToken,
      method: 'POST',
      form: {'link': selected.link},
    );
    final rawUrl = unlocked['link'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || !_safeRemoteCloudDownloadUri(uri)) throw const SourceException(SourceFailure.permission);
    return _RenewedBackgroundLease(uri, const {});
  }

  if (service == 'premiumize') {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(fileId)) {
      throw const SourceException(SourceFailure.permission);
    }
    final parentId = descriptor['parentProviderId'] == null
        ? null
        : _remoteCloudId(descriptor, 'parentProviderId');
    if (descriptor['parentProviderId'] != null && parentId == null) {
      throw const SourceException(SourceFailure.permission);
    }
    final list = await _remoteCloudApi(
      'www.premiumize.me',
      '/api/folder/list',
      token: accessToken,
      query: {if (parentId != null) 'id': parentId},
    );
    final content = list['content'];
    if (content is! List) throw const SourceException(SourceFailure.invalidData);
    final file = content
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => '${row['id']}' == fileId && row['type'] == 'file')
        .firstOrNull;
    if (file == null) throw const SourceException(SourceFailure.conflict);
    final size = _renewalNumber(file, 'size');
    final stableRevision = 'premiumize:${parentId ?? 'root'}:$fileId:$size';
    _checkRenewedRepresentation(descriptor, stableRevision, size);
    final rawUrl = file['link'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || !_safeRemoteCloudDownloadUri(uri)) throw const SourceException(SourceFailure.permission);
    return _RenewedBackgroundLease(uri, const {});
  }

  if (service == 'torbox') {
    if (!RegExp(r'^\d{1,32}$').hasMatch(providerId) || !RegExp(r'^\d{1,32}$').hasMatch(fileId)) {
      throw const SourceException(SourceFailure.permission);
    }
    final list = await _remoteCloudApi(
      'api.torbox.app',
      '/v1/api/torrents/mylist',
      token: accessToken,
      query: {'id': providerId, 'bypass_cache': 'true'},
    );
    final rawData = list['data'];
    final torrent = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : rawData is List && rawData.isNotEmpty && rawData.first is Map
        ? Map<String, dynamic>.from(rawData.first as Map)
        : null;
    if (torrent == null || !(torrent['cached'] == true || torrent['download_finished'] == true || torrent['status'] == 'cached')) {
      throw const SourceException(SourceFailure.conflict);
    }
    final rawFiles = torrent['files'];
    if (rawFiles is! List) throw const SourceException(SourceFailure.invalidData);
    final file = rawFiles
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => '${row['id']}' == fileId)
        .firstOrNull;
    if (file == null) throw const SourceException(SourceFailure.conflict);
    final size = _renewalNumber(file, 'size');
    final stableRevision = 'torbox:$providerId:$fileId:$size';
    _checkRenewedRepresentation(descriptor, stableRevision, size);
    final request = await _remoteCloudApi(
      'api.torbox.app',
      '/v1/api/torrents/requestdl',
      token: accessToken,
      query: {
        'token': accessToken,
        'torrent_id': providerId,
        'file_id': fileId,
        'redirect': 'false',
        'append_name': 'true',
      },
    );
    final rawUrl = request['data'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || !_safeRemoteCloudDownloadUri(uri)) throw const SourceException(SourceFailure.permission);
    return _RenewedBackgroundLease(uri, const {});
  }

  throw const SourceException(SourceFailure.unsupported);
}

Future<_RenewedBackgroundLease> _renewBackgroundLease(Map<String, dynamic> descriptor) async {
  final provider = _renewalText(descriptor, 'provider', maxLength: 32);
  if (provider == 'remoteCloud') return _renewRemoteCloudBackgroundLease(descriptor);
  if (provider == 's3') {
    final rawUri = _renewalText(descriptor, 'uri', maxLength: 4096);
    final uri = Uri.tryParse(rawUri ?? '');
    final accessKey = _renewalText(descriptor, 'accessKey', maxLength: 512);
    final secretKey = _renewalText(descriptor, 'secretKey', maxLength: 4096);
    final region = _renewalText(descriptor, 'region', maxLength: 64);
    final sessionToken = _renewalText(descriptor, 'sessionToken', maxLength: 8192);
    final revision = _renewalText(descriptor, 'revision', maxLength: 2048);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        accessKey == null ||
        secretKey == null ||
        region == null ||
        !RegExp(r'^[a-z0-9-]+$').hasMatch(region)) {
      throw const SourceException(SourceFailure.permission);
    }
    return _RenewedBackgroundLease(
      S3SourceAdapter.sign(
        uri: uri,
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        sessionToken: sessionToken,
        time: DateTime.now(),
        expires: 900,
      ),
      {'If-Match': ?revision},
    );
  }
  final token = await _refreshProviderToken(descriptor);
  final accessToken = token['accessToken'] as String;
  Map<String, dynamic> updatedDescriptor = descriptor;
  final rotatedRefreshToken = token['refreshToken'];
  if (rotatedRefreshToken is String && rotatedRefreshToken != descriptor['refreshToken']) {
    updatedDescriptor = {...descriptor, 'refreshToken': rotatedRefreshToken};
  }
  if (provider == 'googleDrive') {
    final fileId = _renewalText(descriptor, 'fileId', maxLength: 256);
    if (fileId == null || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(fileId)) {
      throw const SourceException(SourceFailure.permission);
    }
    final metadata = await _renewalJson(
      Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {
        'fields': 'id,size,md5Checksum,version,modifiedTime',
        'supportsAllDrives': 'true',
      }),
      method: 'GET',
      headers: {
        'Authorization': 'Bearer $accessToken',
        if (_renewalText(descriptor, 'resourceKey', maxLength: 2048) case final resourceKey?)
          'X-Goog-Drive-Resource-Keys': '$fileId/$resourceKey',
      },
    );
    final revision = (metadata['md5Checksum'] ?? metadata['version'] ?? metadata['modifiedTime'])?.toString();
    _checkRenewedRepresentation(descriptor, revision, _renewalSize(metadata));
    final resourceKey = _renewalText(descriptor, 'resourceKey', maxLength: 2048);
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      if (resourceKey != null) 'X-Goog-Drive-Resource-Keys': '$fileId/$resourceKey',
    };
    return _RenewedBackgroundLease(
      Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {'alt': 'media', 'supportsAllDrives': 'true'}),
      headers,
      refreshDescriptor: updatedDescriptor,
    );
  }
  if (provider == 'oneDrive') {
    final fileId = _renewalText(descriptor, 'fileId', maxLength: 2048);
    if (fileId == null) throw const SourceException(SourceFailure.permission);
    final driveId = _renewalText(descriptor, 'driveId', maxLength: 2048);
    final encodedFileId = Uri.encodeComponent(fileId);
    final encodedDriveId = driveId == null ? null : Uri.encodeComponent(driveId);
    final path = encodedDriveId == null
        ? '/v1.0/me/drive/items/$encodedFileId'
        : '/v1.0/drives/$encodedDriveId/items/$encodedFileId';
    final metadata = await _renewalJson(
      Uri.parse(
        'https://graph.microsoft.com$path',
      ).replace(queryParameters: const {'\$select': 'id,size,eTag,cTag,@microsoft.graph.downloadUrl'}),
      method: 'GET',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final revision = (metadata['cTag'] ?? metadata['eTag']) as String?;
    _checkRenewedRepresentation(descriptor, revision, _renewalSize(metadata));
    final rawUrl = metadata['@microsoft.graph.downloadUrl'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null ||
        !_safeProviderDownloadUri(uri, const [
          'sharepoint.com',
          'sharepointonline.com',
          'sharepoint-df.com',
          '1drv.com',
          '1drv.ms',
          'onedrive.live.com',
          'livefilestore.com',
        ])) {
      throw const SourceException(SourceFailure.permission);
    }
    return _RenewedBackgroundLease(uri, const {}, refreshDescriptor: updatedDescriptor);
  }
  if (provider == 'dropbox') {
    final fileId = _renewalText(descriptor, 'fileId', maxLength: 2048);
    if (fileId == null) throw const SourceException(SourceFailure.permission);
    final link = await _renewalJson(
      Uri.https('api.dropboxapi.com', '/2/files/get_temporary_link'),
      headers: {'Authorization': 'Bearer $accessToken'},
      jsonBody: {'path': fileId},
    );
    final metadata = sourceMap(link['metadata']);
    final revision = metadata['rev'] as String?;
    _checkRenewedRepresentation(descriptor, revision, _renewalSize(metadata));
    final rawUrl = link['link'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || !_safeProviderDownloadUri(uri, const ['dropboxusercontent.com', 'dropbox.com'])) {
      throw const SourceException(SourceFailure.permission);
    }
    return _RenewedBackgroundLease(uri, const {}, refreshDescriptor: updatedDescriptor);
  }
  throw const SourceException(SourceFailure.unsupported);
}

/// Native task rows contain only this encrypted lease in [Task.metaData].
/// Decryption and lease renewal happen immediately before each transfer run.
@pragma('vm:entry-point')
Future<Task?> resolveEncryptedBackgroundLease(Task original) async {
  if ((!Platform.isIOS && !Platform.isAndroid) ||
      original.url != _encryptedLeaseTaskUrl ||
      original.headers.isNotEmpty ||
      original.metaData.isEmpty ||
      original.metaData.length > 16384 ||
      !CredentialVault.isProtected(original.metaData)) {
    return null;
  }
  try {
    final clear = await CredentialVault.reveal(original.metaData);
    if (clear == null || clear.length > 12288) return null;
    final decoded = jsonDecode(clear);
    if (decoded is! Map) return null;
    final descriptor = Map<String, dynamic>.from(decoded);
    if (descriptor['taskId'] != original.taskId) return null;
    final refresh = descriptor['refresh'];
    if (refresh is Map && descriptor['uri'] != _encryptedLeaseTaskUrl) return null;
    final Uri uri;
    final headers = <String, String>{};
    String metadata = original.metaData;
    if (refresh is Map) {
      final renewal = Map<String, dynamic>.from(refresh);
      final renewed = await _renewBackgroundLease(renewal);
      uri = renewed.uri;
      headers.addAll(renewed.headers);
      if (renewed.refreshDescriptor != null && jsonEncode(renewed.refreshDescriptor) != jsonEncode(refresh)) {
        descriptor['refresh'] = renewed.refreshDescriptor;
        metadata = await CredentialVault.protect(jsonEncode(descriptor));
      }
      final provider = renewal['provider'];
      if (provider == 's3' &&
          (uri.scheme != 'https' ||
              uri.host.isEmpty ||
              uri.userInfo.isNotEmpty ||
              uri.hasFragment ||
              !uri.hasQuery ||
              headers.keys.any((key) => key.toLowerCase() != 'if-match') ||
              headers.values.any((value) => value.length > 2048 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)))) {
        return null;
      }
      if (provider == 'googleDrive') {
        if (uri.scheme != 'https' ||
            uri.host != 'www.googleapis.com' ||
            uri.pathSegments.length < 4 ||
            headers.length > 2 ||
            headers['Authorization']?.startsWith('Bearer ') != true) {
          return null;
        }
        const allowed = {'authorization', 'x-goog-drive-resource-keys'};
        if (headers.keys.any((key) => !allowed.contains(key.toLowerCase())) ||
            headers.values.any((value) => value.length > 8192 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value))) {
          return null;
        }
      } else if (provider != 's3' && headers.isNotEmpty) {
        return null;
      }
    } else {
      final rawUri = Uri.tryParse(descriptor['uri'] as String? ?? '');
      final rawHeaders = descriptor['headers'];
      if (rawUri == null || rawHeaders is! Map) return null;
      uri = rawUri;
      for (final entry in rawHeaders.entries) {
        if (entry.key is! String || entry.value is! String) return null;
        headers[entry.key as String] = entry.value as String;
      }
      final lease = ContentLease(uri, headers: headers, backgroundTransferSafe: true);
      if (!lease.canPersistEncryptedAuthForBackgroundTransfer) return null;
    }
    final originalOptions = original.options;
    final safeOptions = originalOptions == null
        ? null
        : TaskOptions(
            beforeTaskStart: originalOptions.beforeTaskStartCallBack,
            onTaskStart: originalOptions.onTaskStartCallBack,
            onTaskFinished: originalOptions.onTaskFinishedCallBack,
          );
    return original.copyWith(url: uri.toString(), headers: headers, metaData: metadata, options: safeOptions);
  } on Object {
    // Missing/locked vault keys, expired credentials, invalid provider responses,
    // or corrupt descriptors fail closed to the inert placeholder URL.
    return null;
  }
}

class TransferCancellation {
  bool cancelled = false;
  final _aborted = Completer<void>();
  Future<void> get aborted => _aborted.future;
  void cancel() {
    cancelled = true;
    if (!_aborted.isCompleted) _aborted.complete();
  }

  void check() {
    if (cancelled) throw const SourceException(SourceFailure.cancelled);
  }
}

class PublicationDownloads {
  PublicationDownloads(this.repository, this.directory);
  static const int maxConcurrentTransfers = 2;
  final SourceRepository repository;
  final Directory directory;
  final Map<String, Future<File>> _pending = {};
  final Map<String, TransferCancellation> _cancellations = {};
  final Map<String, _DownloadTask> _tasks = {};
  final Queue<_DownloadTask> _queue = Queue();
  final Map<String, int> _pendingStorageWrites = {};
  Future<void> _storageCheckQueue = Future<void>.value();
  int _activeTransfers = 0;

  static const _nativeDownloadGroup = 'publication_source_downloads';
  static Future<void>? _nativeDownloaderSetup;
  static final Map<String, Completer<TaskStatusUpdate>> _nativeWaiters = {};
  static final Map<String, _NativeDownloadContext> _nativeContexts = {};

  static bool get _supportsNativeBackgroundDownloads => Platform.isAndroid || Platform.isIOS;

  Future<void> _ensureNativeDownloader() {
    if (!_supportsNativeBackgroundDownloads) return Future<void>.value();
    final existing = _nativeDownloaderSetup;
    if (existing != null) return existing;
    final setup = () async {
      FileDownloader().registerCallbacks(
        group: _nativeDownloadGroup,
        taskStatusCallback: _handleNativeTaskStatus,
        taskProgressCallback: _handleNativeTaskProgress,
      );
      await FileDownloader().configure(
        globalConfig: [(Config.checkAvailableSpace, true), (Config.holdingQueue, (1, 1, 1))],
      );
      await FileDownloader().trackTasksInGroup(_nativeDownloadGroup);
      await FileDownloader().resumeFromBackground();
      Timer(const Duration(seconds: 5), () {
        unawaited(FileDownloader().rescheduleKilledTasks().then<void>((_) {}, onError: (Object _) {}));
      });
    }();
    _nativeDownloaderSetup = setup.catchError((Object error, StackTrace stackTrace) {
      _nativeDownloaderSetup = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    return _nativeDownloaderSetup!;
  }

  static String _nativeTaskId(String profile, String sourceId, PublicationFile file) =>
      'plezy-source-${sourceDigest(jsonEncode([profile, sourceId, file.id, file.fingerprint]))}';

  static void _handleNativeTaskStatus(TaskStatusUpdate update) {
    final context = _nativeContexts[update.task.taskId];
    if (context != null && (update.status.isFinalState || update.status == TaskStatus.paused)) {
      context.acceptingProgress = false;
    }
    final waiter = _nativeWaiters[update.task.taskId];
    if (waiter != null && !waiter.isCompleted && (update.status.isFinalState || update.status == TaskStatus.paused)) {
      waiter.complete(update);
    }
  }

  static void _handleNativeTaskProgress(TaskProgressUpdate update) {
    final context = _nativeContexts[update.task.taskId];
    if (context == null ||
        !context.acceptingProgress ||
        context.task.cancellation.cancelled ||
        !update.progress.isFinite ||
        update.progress < 0) {
      return;
    }
    final total = update.hasExpectedFileSize && update.expectedFileSize > 0
        ? update.expectedFileSize
        : context.expectedSize;
    if (total <= 0) return;
    final bytes = (total * update.progress.clamp(0.0, 1.0)).round().clamp(0, total).toInt();
    if (bytes == context.bytes && bytes < total) return;
    context.bytes = bytes;
    context.task.onProgress?.call(bytes, total);
    context.progressWrites = context.progressWrites
        .then<void>((_) async {
          if (context.acceptingProgress && !context.task.cancellation.cancelled) {
            await context.owner._persistNativeProgress(context, bytes);
          }
        })
        .catchError((Object _) {});
  }

  Future<void> _persistNativeProgress(_NativeDownloadContext context, int bytes) async {
    final task = context.task;
    final safeBytes = bytes.clamp(0, context.expectedSize).toInt();
    await repository.reserveDownload(
      profile: task.profile,
      key: key(task.adapter.source.id, task.file),
      sourceId: task.adapter.source.id,
      file: task.file,
      path: '${_target(task.profile, task.adapter.source.id, task.file).path}.partial',
      reservedBytes: context.expectedSize,
      bytes: safeBytes,
      state: 'running',
      label: task.label,
    );
  }

  Future<bool> _isValidNativePartial(File partial, int expectedSize) async {
    if (!await partial.exists()) return false;
    final stat = await partial.stat();
    return stat.type == FileSystemEntityType.file && stat.size > 0 && stat.size == expectedSize;
  }

  bool _sameEncryptedRefreshRequest(String savedPayload, String currentPayload) {
    try {
      final saved = jsonDecode(savedPayload);
      final current = jsonDecode(currentPayload);
      if (saved is! Map ||
          current is! Map ||
          saved['taskId'] != current['taskId'] ||
          saved['uri'] != _encryptedLeaseTaskUrl ||
          current['uri'] != _encryptedLeaseTaskUrl ||
          saved['headers'] is! Map ||
          current['headers'] is! Map ||
          (saved['headers'] as Map).isNotEmpty ||
          (current['headers'] as Map).isNotEmpty ||
          saved['refresh'] is! Map ||
          current['refresh'] is! Map) {
        return false;
      }
      final oldRefresh = Map<String, dynamic>.from(saved['refresh'] as Map);
      final newRefresh = Map<String, dynamic>.from(current['refresh'] as Map);
      if (oldRefresh['provider'] != newRefresh['provider'] ||
          oldRefresh['credentialVersion'] != newRefresh['credentialVersion']) {
        return false;
      }
      oldRefresh.remove('refreshToken');
      newRefresh.remove('refreshToken');
      if (oldRefresh['provider'] == 'remoteCloud') {
        // OAuth tokens can rotate in the headless renewal callback. Compare
        // the account and selected-file identity, not those rotating secrets.
        oldRefresh
          ..remove('accessToken')
          ..remove('expiresAt');
        newRefresh
          ..remove('accessToken')
          ..remove('expiresAt');
      }
      String canonical(Map<String, dynamic> map) =>
          jsonEncode(Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key))));
      return canonical(oldRefresh) == canonical(newRefresh);
    } on Object {
      return false;
    }
  }

  Future<void> _runNativeDownload({
    required _DownloadTask task,
    required ContentLease lease,
    required int expectedSize,
    required File partial,
    required File validatorFile,
  }) async {
    final taskId = _nativeTaskId(task.profile, task.adapter.source.id, task.file);
    final renewableLease =
        (Platform.isIOS || Platform.isAndroid) && lease.canPersistEncryptedRefreshForBackgroundTransfer;
    final encryptedLease =
        (Platform.isIOS || Platform.isAndroid) &&
        (lease.canPersistEncryptedAuthForBackgroundTransfer || renewableLease);
    final payloadHeaders = Map<String, String>.fromEntries(
      lease.headers.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );
    final leasePayload = encryptedLease
        ? jsonEncode({
            'taskId': taskId,
            'uri': renewableLease ? _encryptedLeaseTaskUrl : lease.uri.toString(),
            'headers': renewableLease ? const <String, String>{} : payloadHeaders,
            'refresh': renewableLease ? lease.backgroundRefresh : null,
          })
        : null;
    var protectedLease = leasePayload == null ? '' : await CredentialVault.protect(leasePayload);
    final taskUrl = encryptedLease ? _encryptedLeaseTaskUrl : lease.uri.toString();
    await _ensureNativeDownloader();
    task.cancellation.check();

    var waiter = Completer<TaskStatusUpdate>();
    _nativeWaiters[taskId] = waiter;
    final context = _NativeDownloadContext(this, task, expectedSize);
    _nativeContexts[taskId] = context;
    try {
      var record = await FileDownloader().database.recordForId(taskId);
      if (record != null && (record.task.group != _nativeDownloadGroup || record.task is! DownloadTask)) {
        throw const SourceException(SourceFailure.invalidData);
      }
      var sameRequest = record == null || (record.task.url == taskUrl && record.task.headers.isEmpty);
      if (record != null && encryptedLease) {
        final savedLease = record.task.metaData;
        final savedPayload = CredentialVault.isProtected(savedLease) ? await CredentialVault.reveal(savedLease) : null;
        sameRequest =
            sameRequest &&
            (savedPayload == leasePayload ||
                (savedPayload != null &&
                    leasePayload != null &&
                    _sameEncryptedRefreshRequest(savedPayload, leasePayload)));
        if (sameRequest) protectedLease = savedLease;
      } else if (record != null) {
        sameRequest = sameRequest && record.task.metaData.isEmpty && record.task.options?.auth == null;
      }
      if (record != null && !sameRequest) {
        // Source configuration can change while a job is suspended. Never
        // resume a stale endpoint or credential lease under the new identity.
        context.acceptingProgress = false;
        _nativeContexts.remove(taskId);
        await _removeNativeTask(taskId);
        waiter = Completer<TaskStatusUpdate>();
        _nativeWaiters[taskId] = waiter;
        context.acceptingProgress = true;
        _nativeContexts[taskId] = context;
        record = null;
      }
      if (record != null && record.status == TaskStatus.complete) {
        if (await _isValidNativePartial(partial, expectedSize)) return;
        await FileDownloader().database.deleteRecordWithId(taskId);
        record = null;
      }
      if (record != null && record.status == TaskStatus.paused) {
        final existing = record.task;
        if (existing is DownloadTask && await FileDownloader().resume(existing)) {
          await _awaitNativeDownload(taskId, waiter, task.cancellation, partial, expectedSize);
          return;
        }
        await FileDownloader().database.deleteRecordWithId(taskId);
        record = null;
      } else if (record != null && !record.status.isFinalState) {
        await _awaitNativeDownload(taskId, waiter, task.cancellation, partial, expectedSize);
        return;
      } else if (record != null) {
        await FileDownloader().database.deleteRecordWithId(taskId);
      }

      if (await partial.exists()) await partial.delete();
      if (await validatorFile.exists()) await validatorFile.delete();
      task.cancellation.check();
      final nativeTask = UriDownloadTask(
        taskId: taskId,
        url: taskUrl,
        filename: p.basename(partial.path),
        directoryUri: partial.parent.uri,
        headers: const {},
        metaData: protectedLease,
        group: _nativeDownloadGroup,
        updates: Updates.statusAndProgress,
        allowPause: true,
        retries: 3,
        displayName: 'Publication download',
        options: encryptedLease
            ? TaskOptions(
                auth: Auth(
                  accessTokenExpiryTime: DateTime.fromMillisecondsSinceEpoch(0),
                  onAuth: resolveEncryptedBackgroundLease,
                ),
              )
            : null,
      );
      final enqueued = await FileDownloader().enqueue(nativeTask);
      if (!enqueued) {
        final current = await FileDownloader().database.recordForId(taskId);
        if (current == null || current.status.isFinalState) {
          throw const SourceException(SourceFailure.unavailable);
        }
      }
      await _awaitNativeDownload(taskId, waiter, task.cancellation, partial, expectedSize);
    } finally {
      context.acceptingProgress = false;
      await context.progressWrites;
      _nativeWaiters.remove(taskId);
      _nativeContexts.remove(taskId);
    }
  }

  Future<void> _awaitNativeDownload(
    String taskId,
    Completer<TaskStatusUpdate> waiter,
    TransferCancellation cancellation,
    File partial,
    int expectedSize,
  ) async {
    unawaited(cancellation.aborted.then((_) => _pauseNativeTask(taskId)));
    final record = await FileDownloader().database.recordForId(taskId);
    if (record?.status == TaskStatus.complete) {
      if (await _isValidNativePartial(partial, expectedSize)) return;
      throw const SourceException(SourceFailure.invalidData);
    }
    if (record != null && record.status.isFinalState && record.status != TaskStatus.complete) {
      if (cancellation.cancelled || record.status == TaskStatus.canceled) {
        throw const SourceException(SourceFailure.cancelled);
      }
      throw const SourceException(SourceFailure.unavailable);
    }
    final update = await waiter.future;
    if (cancellation.cancelled || update.status == TaskStatus.paused || update.status == TaskStatus.canceled) {
      throw const SourceException(SourceFailure.cancelled);
    }
    if (update.status != TaskStatus.complete || !await _isValidNativePartial(partial, expectedSize)) {
      throw const SourceException(SourceFailure.unavailable);
    }
  }

  static Future<void> _pauseNativeTask(String taskId) async {
    if (!_supportsNativeBackgroundDownloads) return;
    try {
      final record = await FileDownloader().database.recordForId(taskId);
      if (record == null || record.status.isFinalState || record.status == TaskStatus.paused) {
        return;
      }
      final existing = record.task;
      if (existing is DownloadTask && !await FileDownloader().pause(existing)) {
        await FileDownloader().cancelTaskWithId(taskId);
      }
    } on Object {
      // Keep cancellation best-effort and avoid exposing native task details.
    }
  }

  static Future<void> _removeNativeTask(String taskId) async {
    if (!_supportsNativeBackgroundDownloads) return;
    await _ensureNativeSetupForRemoval();
    final record = await FileDownloader().database.recordForId(taskId);
    if (record == null) return;
    if (!record.status.isFinalState && record.status != TaskStatus.paused) {
      await FileDownloader().cancelTaskWithId(taskId);
      var stillActive = true;
      for (var attempt = 0; attempt < 20; attempt++) {
        final tasks = await FileDownloader().allTasks(group: _nativeDownloadGroup);
        if (!tasks.any((task) => task.taskId == taskId)) {
          stillActive = false;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (stillActive) throw const SourceException(SourceFailure.conflict);
    }
    await FileDownloader().database.deleteRecordWithId(taskId);
  }

  static Future<void> _ensureNativeSetupForRemoval() async {
    if (_nativeDownloaderSetup == null) {
      await FileDownloader().trackTasksInGroup(_nativeDownloadGroup);
    } else {
      await _nativeDownloaderSetup;
    }
  }

  static const int minimumFreeStorageReserveBytes = 512 * 1024 * 1024;
  static const bool _webOsBuild = bool.fromEnvironment('PLEZY_WEBOS');
  static const bool _tvOsBuild = bool.fromEnvironment('TVOS_BUILD');

  bool get _supportsFreeSpaceProbe =>
      !_webOsBuild &&
      !_tvOsBuild &&
      const {'android', 'ios', 'linux', 'macos', 'windows'}.contains(Platform.operatingSystem);
  String key(String sourceId, PublicationFile file) => sourceKey(sourceId, file.id);
  File _target(String profile, String sourceId, PublicationFile file) {
    final extension = p.extension(file.name).toLowerCase();
    return File(
      p.join(
        directory.path,
        sourceDigest(profile),
        '${sourceDigest(key(sourceId, file))}-${file.fingerprint}${RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension) ? extension : ''}',
      ),
    );
  }

  Future<File?> local(String profile, String sourceId, PublicationFile file) async {
    final record = await repository.download(profile, key(sourceId, file));
    if (record == null || record['complete'] != 1 || record['fingerprint'] != file.fingerprint) return null;
    final value = File(record['path'] as String);
    final expected = p.join(directory.path, sourceDigest(profile));
    if (!p.isWithin(expected, value.path)) throw const SourceException(SourceFailure.permission);
    if (!await value.exists() || await value.length() != record['bytes']) return null;
    return value;
  }

  Future<void> reconcileProfile(String profile) async {
    final expected = p.join(directory.path, sourceDigest(profile));
    for (final row in await repository.downloads(profile)) {
      final path = row['path'] as String? ?? '';
      if (path.isEmpty || !p.isWithin(expected, path)) {
        if (row['state'] != 'queued' && row['state'] != 'running') {
          await repository.forgetDownload(profile, row['key'] as String);
        }
        continue;
      }
      final file = File(path);
      if (await file.exists()) continue;
      if (row['state'] != 'queued' && row['state'] != 'running') {
        await repository.forgetDownload(profile, row['key'] as String);
      }
    }
  }

  /// Accounts for picker copies created before imports were stored in the
  /// download ledger. This is idempotent and only inspects the app-owned
  /// per-profile imports directory; links and unrecognized files are ignored.
  Future<void> reconcileImportedFiles(String profile, FileSource source) async {
    if (source.profileId != profile ||
        source.id.isEmpty ||
        source.kind != FileSourceKind.local ||
        source.options['imported'] != 'true') {
      throw const SourceException(SourceFailure.permission);
    }
    final profileRoot = p.join(directory.path, sourceDigest(profile));
    final importsRoot = p.join(profileRoot, 'imports');
    final importDirectory = Directory(importsRoot);
    if (!await importDirectory.exists()) return;
    await for (final entity in importDirectory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (classifySourceFile(name) == SourceItemKind.unknown) continue;
      final id = p.relative(entity.path, from: importsRoot);
      if (id.isEmpty || id == '.' || !p.isWithin(importsRoot, entity.path)) continue;
      final stat = await entity.stat();
      if (stat.type != FileSystemEntityType.file || stat.size <= 0) continue;
      final file = PublicationFile(
        id: id,
        name: name,
        mimeType: '',
        size: stat.size,
        revision: '${stat.modified.microsecondsSinceEpoch}:${stat.size}',
      );
      final recordKey = key(source.id, file);
      final existing = await repository.download(profile, recordKey);
      if (existing != null &&
          existing['complete'] == 1 &&
          existing['fingerprint'] == file.fingerprint &&
          existing['path'] == entity.path &&
          existing['bytes'] == stat.size) {
        continue;
      }
      await repository.recordDownload(
        profile,
        recordKey,
        entity.path,
        file.fingerprint,
        stat.size,
        reservedBytes: stat.size,
        sourceId: source.id,
        file: file,
        label: name,
      );
    }
  }

  /// Reserves OS storage for a single chunk before any bytes are written.
  /// Known-size jobs are counted from their durable reservation; unknown-size
  /// jobs reserve the incoming chunk until the ledger has observed it.
  Future<void Function()> reserveStorageWrite({
    required String profile,
    required String transferKey,
    required int chunkBytes,
    required bool unknownSize,
  }) {
    if (chunkBytes <= 0 || !_supportsFreeSpaceProbe) return Future.value(() {});
    final previous = _storageCheckQueue;
    final gate = Completer<void>();
    _storageCheckQueue = gate.future;
    return previous.then((_) async {
      try {
        int? available;
        try {
          available = await DiskUsage.freeSpace(directory.path).timeout(const Duration(seconds: 3));
        } on Object {
          throw const SourceException(SourceFailure.storageUnavailable);
        }
        if (available == null) throw const SourceException(SourceFailure.storageUnavailable);
        final remainingReservations = await repository.activeDownloadReservationBytes();
        final pendingWrites = _pendingStorageWrites.values.fold<int>(0, (sum, bytes) => sum + bytes);
        final incomingUnknownBytes = unknownSize ? chunkBytes : 0;
        final required = minimumFreeStorageReserveBytes + remainingReservations + pendingWrites + incomingUnknownBytes;
        if (available < required) throw const SourceException(SourceFailure.storageLow);
        final pendingKey = sourceKey(profile, transferKey);
        _pendingStorageWrites[pendingKey] = (_pendingStorageWrites[pendingKey] ?? 0) + chunkBytes;
        var released = false;
        return () {
          if (released) return;
          released = true;
          final remaining = (_pendingStorageWrites[pendingKey] ?? 0) - chunkBytes;
          if (remaining <= 0) {
            _pendingStorageWrites.remove(pendingKey);
          } else {
            _pendingStorageWrites[pendingKey] = remaining;
          }
        };
      } finally {
        gate.complete();
      }
    });
  }

  Future<File> download(
    String profile,
    SourceAdapter adapter,
    PublicationFile file, {
    String label = '',
    void Function(int, int?)? onProgress,
  }) async {
    final transferKey = sourceKey(profile, key(adapter.source.id, file));
    final existing = _pending[transferKey];
    if (existing != null) return existing;
    final cancellation = TransferCancellation();
    final completer = Completer<File>();
    final task = _DownloadTask(
      profile: profile,
      adapter: adapter,
      file: file,
      transferKey: transferKey,
      label: label,
      onProgress: onProgress,
      cancellation: cancellation,
      completer: completer,
    );
    _tasks[transferKey] = task;
    final pending = completer.future.whenComplete(() {
      _pending.remove(transferKey);
      _cancellations.remove(transferKey);
      _tasks.remove(transferKey);
    });
    _pending[transferKey] = pending;
    _cancellations[transferKey] = cancellation;
    final partial = File('${_target(profile, adapter.source.id, file).path}.partial');
    try {
      await reconcileProfile(profile);
      final bytes = await partial.exists() ? await partial.length() : 0;
      await repository.reserveDownload(
        profile: profile,
        key: key(adapter.source.id, file),
        sourceId: adapter.source.id,
        file: file,
        path: partial.path,
        reservedBytes: file.size ?? bytes,
        bytes: bytes,
        state: 'queued',
        label: label,
      );
      _queue.addLast(task);
      _drainQueue();
    } on Object catch (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    }
    return pending;
  }

  /// Requeues transfers interrupted by process death. Explicitly paused and
  /// failed jobs stay available for an intentional retry.
  Future<void> restoreProfile(String profile, SourceAdapter? Function(String) resolveAdapter) async {
    if (_supportsNativeBackgroundDownloads) await _ensureNativeDownloader();
    for (final row in await repository.downloads(profile)) {
      if (row['state'] == 'importing') {
        // A picker-backed input grant cannot be resumed after process death.
        // If promotion completed just before the crash, reconstruct the final
        // descriptor from its file metadata and commit the already-copied file.
        final rowKey = row['key'] as String;
        final sourceId = row['source_id'] as String? ?? '';
        final path = row['path'] as String? ?? '';
        final expectedRoot = p.join(directory.path, sourceDigest(profile));
        PublicationFile? pendingFile;
        try {
          pendingFile = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        } on Object {
          // Keep malformed rows removable; never derive a path from bad data.
        }
        final isContainedPartial =
            path.isNotEmpty &&
            p.isWithin(expectedRoot, path) &&
            p.equals(p.dirname(path), p.join(expectedRoot, 'imports')) &&
            p.basename(path).startsWith('.') &&
            p.basename(path).endsWith('.partial');
        final name = pendingFile?.name ?? '';
        final pendingSize = pendingFile?.size;
        final finalCopy = isContainedPartial && name.isNotEmpty && p.basename(name) == name
            ? File(p.join(p.dirname(path), name))
            : null;
        if (sourceId.isNotEmpty && finalCopy != null && await finalCopy.exists()) {
          final stat = await finalCopy.stat();
          if (stat.type == FileSystemEntityType.file &&
              stat.size > 0 &&
              (pendingSize == null || pendingSize == stat.size)) {
            final file = PublicationFile(
              id: name,
              name: name,
              mimeType: '',
              size: stat.size,
              revision: '${stat.modified.microsecondsSinceEpoch}:${stat.size}',
            );
            await repository.recordDownload(
              profile,
              rowKey,
              finalCopy.path,
              file.fingerprint,
              stat.size,
              reservedBytes: stat.size,
              sourceId: sourceId,
              file: file,
              label: row['label'] as String? ?? name,
            );
            continue;
          }
        }
        // Keep the partial and reservation removable, but never replay it as
        // a provider download because the picker grant is no longer valid.
        await repository.setDownloadState(profile, row['key'] as String, 'orphaned');
        continue;
      }
      if (row['state'] != 'queued' && row['state'] != 'running') continue;
      try {
        final sourceId = row['source_id'] as String;
        final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (sourceId.isEmpty || file.fingerprint != row['fingerprint'] || row['key'] != key(sourceId, file)) {
          throw const SourceException(SourceFailure.invalidData);
        }
        final adapter = resolveAdapter(sourceId);
        if (adapter == null) {
          await _pauseNativeTask(_nativeTaskId(profile, sourceId, file));
          // Virtual account sources are published after their encrypted
          // provider settings finish loading. Keep this durable job queued so
          // the reconciler can resume it as soon as that adapter is available.
          continue;
        }
        unawaited(
          download(
            profile,
            adapter,
            file,
            label: row['label'] as String? ?? '',
          ).then<void>((_) {}, onError: (Object _) {}),
        );
      } on Object {
        await repository.setDownloadState(profile, row['key'] as String, 'failed');
      }
    }
  }

  Future<void> _persistChunk({
    required String profile,
    required String key,
    required SourceAdapter adapter,
    required PublicationFile file,
    required String path,
    required String label,
    required int bytes,
    required int? expected,
  }) => repository.reserveDownload(
    profile: profile,
    key: key,
    sourceId: adapter.source.id,
    file: file,
    path: path,
    reservedBytes: expected ?? bytes,
    bytes: bytes,
    state: 'running',
    label: label,
  );

  void _drainQueue() {
    while (_activeTransfers < maxConcurrentTransfers && _queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (task.cancellation.cancelled) {
        unawaited(
          repository
              .setDownloadState(task.profile, key(task.adapter.source.id, task.file), 'paused')
              .catchError((_) {}),
        );
        if (!task.completer.isCompleted) {
          task.completer.completeError(const SourceException(SourceFailure.cancelled));
        }
        continue;
      }
      _activeTransfers++;
      unawaited(
        _download(
              task.profile,
              task.adapter,
              task.file,
              task.transferKey,
              task.cancellation,
              task.label,
              task.onProgress,
            )
            .then<void>(
              (file) {
                unawaited(
                  repository
                      .setDownloadState(task.profile, key(task.adapter.source.id, task.file), 'completed')
                      .catchError((_) {}),
                );
                if (!task.completer.isCompleted) task.completer.complete(file);
              },
              onError: (Object error, StackTrace stackTrace) {
                unawaited(
                  repository
                      .setDownloadState(
                        task.profile,
                        key(task.adapter.source.id, task.file),
                        error is SourceException && error.reason == SourceFailure.cancelled ? 'paused' : 'failed',
                      )
                      .catchError((_) {}),
                );
                if (!task.completer.isCompleted) task.completer.completeError(error, stackTrace);
              },
            )
            .whenComplete(() {
              _activeTransfers--;
              _drainQueue();
            }),
      );
    }
  }

  Future<File> _download(
    String profile,
    SourceAdapter adapter,
    PublicationFile file,
    String transferKey,
    TransferCancellation cancel,
    String label,
    void Function(int, int?)? onProgress,
  ) async {
    final recordKey = key(adapter.source.id, file);
    await repository.setDownloadState(profile, recordKey, 'running');
    final cached = await local(profile, adapter.source.id, file);
    cancel.check();
    if (cached != null) return cached;
    final folder = Directory(p.join(directory.path, sourceDigest(profile)));
    await folder.create(recursive: true);
    cancel.check();
    final target = _target(profile, adapter.source.id, file);
    final partial = File('${target.path}.partial');
    final validatorFile = File('${target.path}.validator');
    var offset = await partial.exists() ? await partial.length() : 0;
    final validator = await validatorFile.exists() ? await validatorFile.readAsString() : null;
    // A durable incomplete row lets startup and the download surface
    // distinguish a recoverable transfer from a completed offline edition.
    var expectedSize = file.size ?? await adapter.contentSize(file);
    var usedNativeBackgroundTask = false;
    await repository.reserveDownload(
      profile: profile,
      key: recordKey,
      sourceId: adapter.source.id,
      file: file,
      path: partial.path,
      reservedBytes: expectedSize ?? offset,
      bytes: offset,
      state: 'running',
      label: label,
    );
    cancel.check();
    // Provider streams can resume against the immutable file fingerprint
    // encoded in the partial path. HTTP URLs need a representation validator.
    final directOffset =
        offset > 0 && expectedSize != null && offset < expectedSize && adapter.capabilities.rangeRequests ? offset : 0;
    final directStream = await adapter.openContent(
      file,
      offset: directOffset,
      length: expectedSize == null ? 0 : expectedSize - directOffset,
    );
    cancel.check();
    if (directStream != null) {
      if (expectedSize != null && directStream.size != expectedSize) {
        throw const SourceException(SourceFailure.invalidData);
      }
      expectedSize = directStream.size;
      await _persistChunk(
        profile: profile,
        key: recordKey,
        adapter: adapter,
        file: file,
        path: partial.path,
        label: label,
        bytes: offset,
        expected: expectedSize,
      );
      if (directStream.offset != directOffset || directStream.length != directStream.size - directOffset) {
        throw const SourceException(SourceFailure.invalidData);
      }
      var received = directOffset;
      final output = await partial.open(mode: directOffset > 0 ? FileMode.append : FileMode.write);
      try {
        await for (final bytes in directStream.stream.timeout(const Duration(seconds: 45))) {
          cancel.check();
          final nextReceived = received + bytes.length;
          if (nextReceived > directStream.size) throw const SourceException(SourceFailure.invalidData);
          final releaseStorage = await reserveStorageWrite(
            profile: profile,
            transferKey: transferKey,
            chunkBytes: bytes.length,
            unknownSize: false,
          );
          try {
            cancel.check();
            await _persistChunk(
              profile: profile,
              key: recordKey,
              adapter: adapter,
              file: file,
              path: partial.path,
              label: label,
              bytes: nextReceived,
              expected: directStream.size,
            );
            await output.writeFrom(bytes);
            received = nextReceived;
            onProgress?.call(received, directStream.size);
          } finally {
            releaseStorage();
          }
        }
        await output.flush();
      } finally {
        await output.close();
      }
      if (received != directStream.size) throw const SourceException(SourceFailure.invalidData);
    } else {
      // A byte range is safe to append only when HTTP can condition it on the
      // exact representation previously received. Otherwise restart.
      if (offset > 0 && validator == null) offset = 0;
      var lease = await adapter.resolve(file);
      expectedSize ??= lease.size;
      cancel.check();
      final canUseNativeBackgroundTransfer =
          lease.canPersistForBackgroundTransfer ||
          ((Platform.isIOS || Platform.isAndroid) &&
              (lease.canPersistEncryptedAuthForBackgroundTransfer ||
                  lease.canPersistEncryptedRefreshForBackgroundTransfer));
      if (_supportsNativeBackgroundDownloads &&
          canUseNativeBackgroundTransfer &&
          expectedSize != null &&
          expectedSize > 0 &&
          lease.size == expectedSize) {
        // The durable app quota already reserves the full known file size.
        // Check that reservation plus the stricter free-space floor before
        // handing writes to the native downloader.
        final releaseStorage = await reserveStorageWrite(
          profile: profile,
          transferKey: transferKey,
          chunkBytes: 1,
          unknownSize: false,
        );
        releaseStorage();
        final queuedTask = _tasks[transferKey];
        if (queuedTask == null) throw const SourceException(SourceFailure.cancelled);
        await _runNativeDownload(
          task: queuedTask,
          lease: lease,
          expectedSize: expectedSize,
          partial: partial,
          validatorFile: validatorFile,
        );
        usedNativeBackgroundTask = true;
        offset = expectedSize;
      } else if (lease.uri.scheme == 'file') {
        final input = File.fromUri(lease.uri);
        final inputSize = await input.length();
        expectedSize ??= inputSize;
        await _persistChunk(
          profile: profile,
          key: recordKey,
          adapter: adapter,
          file: file,
          path: partial.path,
          label: label,
          bytes: 0,
          expected: expectedSize,
        );
        final output = await partial.open(mode: FileMode.write);
        var copiedBytes = 0;
        try {
          await for (final bytes in input.openRead()) {
            cancel.check();
            final nextBytes = copiedBytes + bytes.length;
            if (nextBytes > inputSize) throw const SourceException(SourceFailure.invalidData);
            final releaseStorage = await reserveStorageWrite(
              profile: profile,
              transferKey: transferKey,
              chunkBytes: bytes.length,
              unknownSize: false,
            );
            try {
              cancel.check();
              await _persistChunk(
                profile: profile,
                key: recordKey,
                adapter: adapter,
                file: file,
                path: partial.path,
                label: label,
                bytes: nextBytes,
                expected: inputSize,
              );
              await output.writeFrom(bytes);
              copiedBytes = nextBytes;
              onProgress?.call(copiedBytes, inputSize);
            } finally {
              releaseStorage();
            }
          }
          await output.flush();
        } finally {
          await output.close();
        }
        if (copiedBytes != inputSize) throw const SourceException(SourceFailure.invalidData);
      } else {
        var response = await adapter.transport.send(
          'GET',
          lease.uri,
          headers: {
            ...lease.headers,
            if (offset > 0) 'Range': 'bytes=$offset-',
            if (offset > 0) 'If-Range': validator!,
          },
          redirects: true,
          abort: cancel.aborted,
        );
        if (const {401, 403}.contains(response.statusCode)) {
          await response.stream.listen(null).cancel();
          await adapter.refreshAuthorization();
          lease = await adapter.resolve(file);
          expectedSize ??= lease.size;
          response = await adapter.transport.send(
            'GET',
            lease.uri,
            headers: {
              ...lease.headers,
              if (offset > 0) 'Range': 'bytes=$offset-',
              if (offset > 0) 'If-Range': validator!,
            },
            redirects: true,
            abort: cancel.aborted,
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.stream.listen(null).cancel();
          // A stale or complete partial is never promoted on a 416 response.
          if (response.statusCode == 416 && await partial.exists()) await partial.delete();
        }
        SourceTransport.check(response.statusCode);
        if (offset > 0 && response.statusCode != 206) offset = 0;
        final rangeHeader = RegExp(r'^bytes (\d+)-(\d+)/(\d+|\*)$').firstMatch(response.headers['content-range'] ?? '');
        final contentLength = int.tryParse(response.headers['content-length'] ?? '');
        if (expectedSize == null) {
          final rangeTotal = rangeHeader == null || rangeHeader[3] == '*' ? null : int.tryParse(rangeHeader[3]!);
          expectedSize =
              rangeTotal ??
              (response.statusCode == 206 && contentLength != null ? offset + contentLength : contentLength);
        }
        await _persistChunk(
          profile: profile,
          key: recordKey,
          adapter: adapter,
          file: file,
          path: partial.path,
          label: label,
          bytes: offset,
          expected: expectedSize,
        );
        final etag = response.headers['etag'];
        final freshValidator = etag != null && !etag.startsWith('W/') ? etag : response.headers['last-modified'];
        if (offset > 0 && freshValidator != null && validator != freshValidator) {
          await response.stream.listen(null).cancel();
          await partial.delete();
          throw const SourceException(SourceFailure.conflict);
        }
        if (response.statusCode == 206) {
          final rangeStart = rangeHeader == null ? null : int.tryParse(rangeHeader[1]!);
          final rangeEnd = rangeHeader == null ? null : int.tryParse(rangeHeader[2]!);
          final rangeTotal = rangeHeader == null || rangeHeader[3] == '*' ? null : int.tryParse(rangeHeader[3]!);
          final rangeLength = rangeStart == null || rangeEnd == null || rangeEnd < rangeStart
              ? null
              : rangeEnd - rangeStart + 1;
          if (rangeHeader == null ||
              rangeStart != offset ||
              rangeLength == null ||
              rangeHeader[3] != '*' && rangeTotal == null ||
              contentLength != null && contentLength != rangeLength ||
              rangeTotal != null && (rangeEnd! >= rangeTotal || expectedSize != null && rangeTotal != expectedSize) ||
              rangeTotal == null && expectedSize != null && rangeEnd! + 1 != expectedSize) {
            await response.stream.listen(null).cancel();
            if (await partial.exists()) await partial.delete();
            if (await validatorFile.exists()) await validatorFile.delete();
            throw const SourceException(SourceFailure.invalidData);
          }
        }
        if (freshValidator != null) {
          await validatorFile.writeAsString(freshValidator);
        } else if (await validatorFile.exists()) {
          await validatorFile.delete();
        }
        final output = await partial.open(mode: offset > 0 ? FileMode.append : FileMode.write);
        try {
          await for (final bytes in response.stream.timeout(const Duration(seconds: 45))) {
            cancel.check();
            final nextOffset = offset + bytes.length;
            if (expectedSize != null && nextOffset > expectedSize) {
              throw const SourceException(SourceFailure.invalidData);
            }
            final releaseStorage = await reserveStorageWrite(
              profile: profile,
              transferKey: transferKey,
              chunkBytes: bytes.length,
              unknownSize: expectedSize == null,
            );
            try {
              cancel.check();
              await _persistChunk(
                profile: profile,
                key: recordKey,
                adapter: adapter,
                file: file,
                path: partial.path,
                label: label,
                bytes: nextOffset,
                expected: expectedSize,
              );
              await output.writeFrom(bytes);
              offset = nextOffset;
              onProgress?.call(offset, expectedSize);
            } finally {
              releaseStorage();
            }
          }
          await output.flush();
        } finally {
          await output.close();
        }
      }
    }
    cancel.check();
    final size = await partial.length();
    cancel.check();
    if (size == 0 || (expectedSize != null && size != expectedSize)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    // Same-directory rename publishes a complete file atomically. A different
    // edition uses a different name and cannot overwrite an active reader.
    await partial.rename(target.path);
    try {
      if (await validatorFile.exists()) await validatorFile.delete();
      cancel.check();
      await repository.recordDownload(
        profile,
        recordKey,
        target.path,
        file.fingerprint,
        size,
        reservedBytes: expectedSize ?? size,
        sourceId: adapter.source.id,
        file: file,
        label: label,
      );
      cancel.check();
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
    if (usedNativeBackgroundTask) {
      try {
        await FileDownloader().database.deleteRecordWithId(_nativeTaskId(profile, adapter.source.id, file));
      } on Object {
        // A stale native record must not invalidate an already committed copy.
      }
    }
    return target;
  }

  void cancelAll() {
    for (final task in _tasks.values) {
      task.cancellation.cancel();
      if (_supportsNativeBackgroundDownloads) {
        unawaited(_pauseNativeTask(_nativeTaskId(task.profile, task.adapter.source.id, task.file)));
      }
    }
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      unawaited(
        repository.setDownloadState(task.profile, key(task.adapter.source.id, task.file), 'paused').catchError((_) {}),
      );
      if (!task.completer.isCompleted) {
        task.completer.completeError(const SourceException(SourceFailure.cancelled));
      }
    }
  }

  void cancel(String profile, String sourceId, PublicationFile file) {
    final transferKey = sourceKey(profile, key(sourceId, file));
    final task = _tasks[transferKey];
    task?.cancellation.cancel();
    if (_supportsNativeBackgroundDownloads) {
      unawaited(_pauseNativeTask(_nativeTaskId(profile, sourceId, file)));
      if (task == null) {
        unawaited(repository.setDownloadState(profile, key(sourceId, file), 'paused').catchError((_) {}));
      }
    }
    if (task != null && _queue.remove(task)) {
      unawaited(repository.setDownloadState(profile, key(sourceId, file), 'paused').catchError((_) {}));
      if (!task.completer.isCompleted) task.completer.completeError(const SourceException(SourceFailure.cancelled));
      _drainQueue();
    }
  }

  Future<void> cancelAndWait(String profile, String sourceId, PublicationFile file) async {
    final transferKey = sourceKey(profile, key(sourceId, file));
    cancel(profile, sourceId, file);
    if (_supportsNativeBackgroundDownloads) {
      await _pauseNativeTask(_nativeTaskId(profile, sourceId, file));
    }
    final pending = _pending[transferKey];
    if (pending != null) await pending.then<void>((_) {}, onError: (Object _) {});
    await repository.setDownloadState(profile, key(sourceId, file), 'paused');
  }

  Future<void> removeQueuedJob(String profile, String downloadKey) async {
    var row = await repository.download(profile, downloadKey);
    if (row == null) return;
    final sourceId = row['source_id'] as String? ?? '';
    final interruptedImport = row['state'] == 'orphaned';
    final task = _tasks.values
        .where((task) => task.profile == profile && key(task.adapter.source.id, task.file) == downloadKey)
        .firstOrNull;
    if (task != null) {
      await cancelAndWait(profile, task.adapter.source.id, task.file);
    } else if (!interruptedImport &&
        sourceId.isNotEmpty &&
        row['file_payload'] is String &&
        row['file_payload'] != '{}') {
      try {
        final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (key(sourceId, file) == downloadKey) await cancelAndWait(profile, sourceId, file);
      } on SourceException {
        rethrow;
      } on Object {
        throw const SourceException(SourceFailure.invalidData);
      }
    }
    row = await repository.download(profile, downloadKey);
    if (row == null) return;
    if (row['complete'] == 1) throw const SourceException(SourceFailure.conflict);
    final path = row['path'] as String? ?? '';
    final expected = p.join(directory.path, sourceDigest(profile));
    if (path.isEmpty || !p.isWithin(expected, path)) throw const SourceException(SourceFailure.permission);
    if (!interruptedImport && sourceId.isNotEmpty && row['file_payload'] is String && row['file_payload'] != '{}') {
      try {
        final nativeFile = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (key(sourceId, nativeFile) == downloadKey) {
          await _removeNativeTask(_nativeTaskId(profile, sourceId, nativeFile));
        }
      } on SourceException {
        rethrow;
      } on Object {
        throw const SourceException(SourceFailure.invalidData);
      }
    }
    final partial = File(path);
    if (await partial.exists()) await partial.delete();
    if (path.endsWith('.partial')) {
      final validator = File('${p.withoutExtension(path)}.validator');
      if (await validator.exists() && p.isWithin(expected, validator.path)) await validator.delete();
    }
    if (sourceId.isNotEmpty && row['file_payload'] is String && row['file_payload'] != '{}') {
      PublicationFile? descriptor;
      try {
        final candidate = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (key(sourceId, candidate) == downloadKey && candidate.fingerprint == row['fingerprint']) {
          descriptor = candidate;
        }
      } on Object {
        // The row can be removed without touching a path from an invalid descriptor.
      }
      if (descriptor != null) {
        if (interruptedImport) {
          final imports = p.join(expected, 'imports');
          final imported = File(p.join(imports, p.basename(descriptor.name)));
          if (p.basename(descriptor.name) == descriptor.name &&
              p.isWithin(imports, imported.path) &&
              await imported.exists()) {
            await imported.delete();
          }
        } else {
          final target = _target(profile, sourceId, descriptor);
          if (target.path != path && p.isWithin(expected, target.path) && await target.exists()) await target.delete();
        }
      }
    }
    await repository.forgetDownload(profile, downloadKey);
  }

  Future<void> cancelSource(String profile, String sourceId) async {
    final tasks = _tasks.values.where((task) => task.profile == profile && task.adapter.source.id == sourceId).toList();
    final transferKeys = tasks.map((task) => task.transferKey).toList(growable: false);
    for (final task in tasks) {
      task.cancellation.cancel();
      if (_supportsNativeBackgroundDownloads) {
        unawaited(_pauseNativeTask(_nativeTaskId(profile, sourceId, task.file)));
      }
      if (_queue.remove(task)) {
        unawaited(repository.setDownloadState(profile, key(sourceId, task.file), 'paused').catchError((_) {}));
        if (!task.completer.isCompleted) task.completer.completeError(const SourceException(SourceFailure.cancelled));
      }
    }
    _drainQueue();
    await Future.wait(
      transferKeys.map((transferKey) {
        final transfer = _pending[transferKey];
        return transfer == null ? Future<void>.value() : transfer.then<void>((_) {}, onError: (Object _) {});
      }),
    );
    for (final row in await repository.downloads(profile)) {
      if (row['source_id'] != sourceId || row['complete'] == 1) continue;
      final downloadKey = row['key'] as String;
      try {
        await removeQueuedJob(profile, downloadKey);
      } on SourceException {
        final current = await repository.download(profile, downloadKey);
        if (current != null && current['complete'] != 1) await repository.forgetDownload(profile, downloadKey);
      }
    }
  }

  /// Profile deletion waits for file writers to retire before removing their
  /// directory, including a local copy already in progress at cancellation.
  Future<void> settleCancelled() async {
    cancelAll();
    await Future.wait(_pending.values.toList().map((transfer) => transfer.then<void>((_) {}, onError: (Object _) {})));
  }

  Future<void> remove(String profile, String sourceId, PublicationFile file) async {
    final record = await repository.download(profile, key(sourceId, file));
    if (record != null) {
      final path = record['path'] as String;
      if (!p.isWithin(p.join(directory.path, sourceDigest(profile)), path)) {
        throw const SourceException(SourceFailure.permission);
      }
      final target = File(path);
      if (await target.exists()) await target.delete();
    }
    await repository.forgetDownload(profile, key(sourceId, file));
  }
}

class _NativeDownloadContext {
  _NativeDownloadContext(this.owner, this.task, this.expectedSize);

  final PublicationDownloads owner;
  final _DownloadTask task;
  final int expectedSize;
  int bytes = 0;
  bool acceptingProgress = true;
  Future<void> progressWrites = Future<void>.value();
}

class _DownloadTask {
  const _DownloadTask({
    required this.profile,
    required this.adapter,
    required this.file,
    required this.transferKey,
    required this.label,
    required this.onProgress,
    required this.cancellation,
    required this.completer,
  });

  final String profile;
  final SourceAdapter adapter;
  final PublicationFile file;
  final String transferKey;
  final String label;
  final void Function(int, int?)? onProgress;
  final TransferCancellation cancellation;
  final Completer<File> completer;
}

({int offset, int length})? _byteRange(String? value, int size) {
  if (value == null) return (offset: 0, length: size);
  final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(value);
  if (match == null || size < 0) return null;
  final first = match[1]!, last = match[2]!;
  if ((first.isEmpty && last.isEmpty) || size == 0) return null;
  if (first.isEmpty) {
    final suffix = int.tryParse(last);
    if (suffix == null || suffix <= 0) return null;
    final length = math.min(suffix, size).toInt();
    return (offset: size - length, length: length);
  }
  final offset = int.tryParse(first);
  final end = last.isEmpty ? size - 1 : int.tryParse(last);
  if (offset == null || end == null || offset >= size || end < offset) return null;
  final boundedEnd = math.min(end, size - 1).toInt();
  return (offset: offset, length: boundedEnd - offset + 1);
}

/// A session-owned loopback gateway keeps provider credentials away from
/// native player logging, redirects and OS metadata. It only serves explicitly
/// registered files, renews expired leases, and streams with backpressure.
typedef SourceUriRenewal = Future<({Uri uri, Map<String, String> headers})> Function();

class SourceStreamGateway {
  SourceStreamGateway({required this.valid});
  final bool Function() valid;
  HttpServer? _server;
  final _secret = SourceOAuthService.randomSecret();
  final Map<String, ({SourceAdapter adapter, PublicationFile file})> _files = {};
  final Map<String, ContentLease> _leases = {};
  final LinkedHashMap<String, ({Uri uri, Map<String, String> headers, SourceUriRenewal? renew})> _directUris =
      LinkedHashMap();
  final Map<String, String> _directIdsByUri = {};
  final Set<String> _nonDeduplicatedDirectIds = {};
  final Map<String, Future<({Uri uri, Map<String, String> headers})>> _directRenewals = {};
  var _directCounter = 0;
  final _abort = Completer<void>();

  Future<void> _ensureServer() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((request) => unawaited(_serve(request)));
  }

  Future<Uri> register(SourceAdapter adapter, PublicationFile file) async {
    if (!valid()) throw const SourceException(SourceFailure.cancelled);
    await _ensureServer();
    final id = sourceDigest(sourceKey(adapter.source.id, file.id));
    _files[id] = (adapter: adapter, file: file);
    return Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/$id');
  }

  /// Registers a user-entered HTTP(S) address behind this session's loopback
  /// capability. The native player sees only localhost; credentials and
  /// signed query strings stay in this in-memory proxy and are never logged by
  /// the player or written to the source database.
  Future<Uri> registerUri(
    Uri uri, {
    Map<String, String> headers = const {},
    SourceUriRenewal? renew,
    bool deduplicate = true,
  }) async {
    if (!valid()) throw const SourceException(SourceFailure.cancelled);
    if (uri.hasFragment || uri.userInfo.isNotEmpty || !const {'http', 'https'}.contains(uri.scheme)) {
      throw const SourceException(SourceFailure.permission);
    }
    final safeHeaders = _validateDirectHeaders(headers);
    SourceTransport(allowHttp: uri.scheme == 'http').validate(uri);
    await _ensureServer();
    final uriText = sourceDigest(
      jsonEncode([
        uri.toString(),
        safeHeaders.entries.map((entry) => [entry.key.toLowerCase(), entry.value]).toList(),
      ]),
    );
    final existing = deduplicate ? _directIdsByUri[uriText] : null;
    if (existing != null) {
      final registered = _directUris[existing];
      if (registered != null && registered.renew == null && renew != null) {
        _directUris[existing] = (uri: registered.uri, headers: registered.headers, renew: renew);
      }
      return Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/$existing');
    }
    final id = sourceDigest('direct:$_secret:${_directCounter++}');
    _directUris[id] = (uri: uri, headers: safeHeaders, renew: renew);
    if (deduplicate) {
      _directIdsByUri[uriText] = id;
    } else {
      _nonDeduplicatedDirectIds.add(id);
    }
    while (_directUris.length > 4096) {
      final oldest = _directUris.keys.first;
      _directUris.remove(oldest);
      _nonDeduplicatedDirectIds.remove(oldest);
      _directIdsByUri.removeWhere((_, value) => value == oldest);
    }
    return Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/$id');
  }

  Map<String, String> _validateDirectHeaders(Map<String, String> headers) {
    if (headers.length > 32) throw const SourceException(SourceFailure.invalidData);
    const forbidden = {
      'host',
      'content-length',
      'connection',
      'transfer-encoding',
      'proxy-authorization',
      'range',
      'accept-encoding',
      'origin',
    };
    final safe = <String, String>{};
    for (final entry in headers.entries) {
      final name = entry.key.trim();
      final value = entry.value.trim();
      if (name.isEmpty || name.length > 100 || value.length > 4096 || forbidden.contains(name.toLowerCase())) {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (!RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(name) ||
          name.runes.any((code) => code < 32 || code == 127) ||
          value.runes.any((code) => code < 32 && code != 9 || code == 127)) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final normalizedName = name.toLowerCase();
      if (safe.containsKey(normalizedName)) throw const SourceException(SourceFailure.invalidData);
      safe[normalizedName] = value;
    }
    return Map.unmodifiable(safe);
  }

  bool _sameDirectHeaders(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((entry) => b[entry.key] == entry.value);

  Future<({Uri uri, Map<String, String> headers, SourceUriRenewal? renew})> _renewDirectUri(
    String id, {
    required Uri expiredUri,
    required Map<String, String> expiredHeaders,
    required SourceUriRenewal renew,
  }) async {
    final current = _directUris[id];
    if (current == null) throw const SourceException(SourceFailure.cancelled);
    if (current.uri != expiredUri || !_sameDirectHeaders(current.headers, expiredHeaders)) return current;

    final inFlight = _directRenewals[id];
    if (inFlight != null) {
      await inFlight;
      return _directUris[id] ?? (throw const SourceException(SourceFailure.cancelled));
    }

    final pending = renew();
    _directRenewals[id] = pending;
    try {
      final refreshed = await pending;
      if (!valid() ||
          !const {'http', 'https'}.contains(refreshed.uri.scheme) ||
          refreshed.uri.host.isEmpty ||
          refreshed.uri.userInfo.isNotEmpty ||
          refreshed.uri.hasFragment) {
        throw const SourceException(SourceFailure.permission);
      }
      final safeHeaders = _validateDirectHeaders(refreshed.headers);
      final latest = _directUris[id];
      if (latest == null) throw const SourceException(SourceFailure.cancelled);
      // A newer concurrent renewal owns the slot; do not overwrite it with an
      // older callback result that happened to complete later.
      if (latest.uri != expiredUri || !_sameDirectHeaders(latest.headers, expiredHeaders)) return latest;
      final key = sourceDigest(
        jsonEncode([
          refreshed.uri.toString(),
          safeHeaders.entries.map((entry) => [entry.key.toLowerCase(), entry.value]).toList(),
        ]),
      );
      final expiredKey = sourceDigest(
        jsonEncode([
          expiredUri.toString(),
          expiredHeaders.entries.map((entry) => [entry.key.toLowerCase(), entry.value]).toList(),
        ]),
      );
      final next = (uri: refreshed.uri, headers: safeHeaders, renew: renew);
      _directUris[id] = next;
      if (_directIdsByUri[expiredKey] == id) _directIdsByUri.remove(expiredKey);
      if (!_nonDeduplicatedDirectIds.contains(id)) _directIdsByUri.putIfAbsent(key, () => id);
      return next;
    } finally {
      if (identical(_directRenewals[id], pending)) _directRenewals.remove(id);
    }
  }

  Future<void> _serve(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      final expectedHost = '127.0.0.1:${_server?.port}';
      if (!valid() ||
          request.headers.value(HttpHeaders.hostHeader) != expectedHost ||
          request.headers.value('origin') != null ||
          segments.length != 2 ||
          segments[0] != _secret ||
          !const {'GET', 'HEAD'}.contains(request.method)) {
        request.response.statusCode = 403;
        return;
      }
      final ref = _files[segments[1]];
      if (ref == null) {
        final direct = _directUris[segments[1]];
        if (direct == null) {
          request.response.statusCode = 404;
          return;
        }
        await _serveDirect(request, id: segments[1], uri: direct.uri, headers: direct.headers, renew: direct.renew);
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null && !RegExp(r'^bytes=(\d+-\d*|-\d+)$').hasMatch(range)) {
        request.response.statusCode = 416;
        return;
      }
      final size = await ref.adapter.contentSize(ref.file);
      if (size != null) {
        final requested = _byteRange(range, size);
        if (requested == null) {
          request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$size');
          request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
          return;
        }
        final content = await ref.adapter.openContent(ref.file, offset: requested.offset, length: requested.length);
        if (content != null) {
          request.response.statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent;
          request.response.headers
            ..set(HttpHeaders.cacheControlHeader, 'no-store')
            ..set(HttpHeaders.acceptRangesHeader, 'bytes')
            ..set(HttpHeaders.contentLengthHeader, content.length)
            ..set(
              HttpHeaders.contentTypeHeader,
              ref.file.mimeType.isEmpty ? 'application/octet-stream' : ref.file.mimeType,
            );
          if (range != null && content.length > 0) {
            request.response.headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes ${content.offset}-${content.offset + content.length - 1}/${content.size}',
            );
          }
          if (request.method == 'HEAD') return;
          await request.response.addStream(
            content.stream.timeout(const Duration(seconds: 45)).map((bytes) {
              if (!valid()) throw const SourceException(SourceFailure.cancelled);
              return bytes;
            }),
          );
          return;
        }
      }
      var lease = _leases[segments[1]];
      if (lease == null || (lease.expiresAt?.isBefore(DateTime.now().add(const Duration(seconds: 30))) ?? false)) {
        lease = await ref.adapter.resolve(ref.file);
        _leases[segments[1]] = lease;
      }
      if (!valid()) throw const SourceException(SourceFailure.cancelled);
      if (lease.uri.scheme == 'file') throw const SourceException(SourceFailure.invalidData);
      var response = await ref.adapter.transport.send(
        'GET',
        lease.uri,
        headers: {...lease.headers, 'Range': ?range},
        redirects: true,
        abort: _abort.future,
      );
      if (const {401, 403}.contains(response.statusCode)) {
        await response.stream.drain<void>();
        _leases.remove(segments[1]);
        await ref.adapter.refreshAuthorization();
        lease = await ref.adapter.resolve(ref.file);
        response = await ref.adapter.transport.send(
          'GET',
          lease.uri,
          headers: {...lease.headers, 'Range': ?range},
          redirects: true,
          abort: _abort.future,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) await response.stream.listen(null).cancel();
      SourceTransport.check(response.statusCode);
      request.response.statusCode = response.statusCode;
      request.response.headers.set('Cache-Control', 'no-store');
      for (final name in [
        'content-type',
        'content-length',
        'content-range',
        'accept-ranges',
        'etag',
        'last-modified',
      ]) {
        final value = response.headers[name];
        if (value != null) request.response.headers.set(name, value);
      }
      if (request.method == 'HEAD') {
        await response.stream.listen(null).cancel();
        return;
      }
      await request.response.addStream(
        response.stream.timeout(const Duration(seconds: 45)).map((bytes) {
          if (!valid()) throw const SourceException(SourceFailure.cancelled);
          return bytes;
        }),
      );
    } catch (_) {
      try {
        request.response.statusCode = 502;
      } catch (_) {}
    } finally {
      try {
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<String> _registerManifestUri(
    Uri base,
    String value,
    Map<String, String> headers, {
    required String parentId,
    required SourceUriRenewal? parentRenew,
    required int referenceIndex,
  }) async {
    final raw = value.trim();
    final uri = base.resolve(raw);
    final scheme = uri.scheme.toLowerCase();
    // FairPlay's skd: key URI is handled by the platform DRM path. Inline
    // data: URIs are self-contained. Never hand file: or another network
    // scheme from a remote manifest to the native player.
    if (scheme == 'skd' || scheme == 'data') return raw;
    if (!const {'http', 'https'}.contains(scheme) || (base.scheme == 'https' && scheme != 'https')) {
      throw const SourceException(SourceFailure.permission);
    }
    // Manifest children can point at a CDN or a different host. Request
    // credentials are scoped to the stream origin and must never follow them.
    final childHeaders = sameSourceOrigin(base, uri) ? headers : const <String, String>{};
    final SourceUriRenewal? childRenew = parentRenew == null
        ? null
        : () => _renewManifestChildUri(
            parentId,
            parentRenew: parentRenew,
            referenceIndex: referenceIndex,
            expectedPath: uri.path,
          );
    // Each manifest reference keeps its own renewal ordinal. Reusing an
    // identical URI for two playlist slots would otherwise bind both slots to
    // whichever callback registered first.
    final local = await registerUri(uri, headers: childHeaders, renew: childRenew, deduplicate: false);
    return local.toString();
  }

  Future<String> _rewriteHlsManifest(
    String value,
    Uri base,
    Map<String, String> headers, {
    required String parentId,
    required SourceUriRenewal? parentRenew,
  }) async {
    final lines = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    var rewrittenUris = 0;
    var referenceIndex = 0;
    final attributeUri = RegExp(r'URI="([^"]+)"');
    for (var index = 0; index < lines.length; index++) {
      var line = lines[index];
      if (line.trim().isEmpty) continue;
      if (!line.startsWith('#')) {
        if (referenceIndex >= 2000) throw const SourceException(SourceFailure.invalidData);
        line = await _registerManifestUri(
          base,
          line,
          headers,
          parentId: parentId,
          parentRenew: parentRenew,
          referenceIndex: referenceIndex++,
        );
        rewrittenUris++;
      } else {
        final matches = attributeUri.allMatches(line).toList();
        if (referenceIndex + matches.length > 2000) throw const SourceException(SourceFailure.invalidData);
        for (var matchIndex = matches.length - 1; matchIndex >= 0; matchIndex--) {
          final match = matches[matchIndex];
          final local = await _registerManifestUri(
            base,
            match.group(1)!,
            headers,
            parentId: parentId,
            parentRenew: parentRenew,
            referenceIndex: referenceIndex + matchIndex,
          );
          line = line.replaceRange(match.start, match.end, 'URI="$local"');
          rewrittenUris++;
        }
        referenceIndex += matches.length;
      }
      if (rewrittenUris > 2000) throw const SourceException(SourceFailure.invalidData);
      lines[index] = line;
    }
    return lines.join('\n');
  }

  List<Uri> _hlsReferences(String manifest, Uri base) {
    final references = <Uri>[];
    final attributeUri = RegExp(r'URI="([^"]+)"');
    for (final rawLine in manifest.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (!line.startsWith('#')) {
        references.add(base.resolve(line));
        if (references.length > 2000) throw const SourceException(SourceFailure.invalidData);
        continue;
      }
      for (final match in attributeUri.allMatches(line)) {
        references.add(base.resolve(match.group(1)!));
        if (references.length > 2000) throw const SourceException(SourceFailure.invalidData);
      }
    }
    return references;
  }

  Future<({Uri base, Map<String, String> headers, String manifest})> _readRenewedManifest(
    String parentId, {
    required SourceUriRenewal parentRenew,
  }) async {
    var parent = _directUris[parentId];
    if (parent == null) throw const SourceException(SourceFailure.cancelled);
    final transport = SourceTransport(allowHttp: parent.uri.scheme == 'http');
    try {
      var response = await transport.send(
        'GET',
        parent.uri,
        headers: parent.headers,
        redirects: true,
        abort: _abort.future,
      );
      if (const {HttpStatus.unauthorized, HttpStatus.forbidden, HttpStatus.gone}.contains(response.statusCode)) {
        await response.stream.drain<void>();
        if (!valid()) throw const SourceException(SourceFailure.cancelled);
        parent = await _renewDirectUri(
          parentId,
          expiredUri: parent.uri,
          expiredHeaders: parent.headers,
          renew: parentRenew,
        );
        transport.validate(parent.uri);
        response = await transport.send(
          'GET',
          parent.uri,
          headers: parent.headers,
          redirects: true,
          abort: _abort.future,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.stream.drain<void>();
        throw SourceException(
          response.statusCode == HttpStatus.notFound ? SourceFailure.unavailable : SourceFailure.authentication,
          status: response.statusCode,
        );
      }
      const maxManifestBytes = 2 * 1024 * 1024;
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
        if (!valid()) throw const SourceException(SourceFailure.cancelled);
        if (bytes.length + chunk.length > maxManifestBytes) throw const SourceException(SourceFailure.invalidData);
        bytes.addAll(chunk);
      }
      final base = response.request?.url ?? parent.uri;
      final headers = sameSourceOrigin(parent.uri, base) ? parent.headers : const <String, String>{};
      final manifest = utf8.decode(bytes, allowMalformed: true);
      if (!manifest.trimLeft().startsWith('#EXTM3U')) throw const SourceException(SourceFailure.invalidData);
      return (base: base, headers: headers, manifest: manifest);
    } finally {
      transport.close();
    }
  }

  Future<({Uri uri, Map<String, String> headers})> _renewManifestChildUri(
    String parentId, {
    required SourceUriRenewal parentRenew,
    required int referenceIndex,
    required String expectedPath,
  }) async {
    if (!valid()) throw const SourceException(SourceFailure.cancelled);
    final refreshed = await _readRenewedManifest(parentId, parentRenew: parentRenew);
    final references = _hlsReferences(refreshed.manifest, refreshed.base);
    if (referenceIndex < 0 || referenceIndex >= references.length) {
      throw const SourceException(SourceFailure.conflict);
    }
    final uri = references[referenceIndex];
    final scheme = uri.scheme.toLowerCase();
    if (!const {'http', 'https'}.contains(scheme) ||
        (refreshed.base.scheme == 'https' && scheme != 'https') ||
        uri.path != expectedPath) {
      // A live playlist may roll forward or a provider may replace the file.
      // Refuse to splice a different segment into the current playback.
      throw const SourceException(SourceFailure.conflict);
    }
    if (uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment) {
      throw const SourceException(SourceFailure.permission);
    }
    return (uri: uri, headers: sameSourceOrigin(refreshed.base, uri) ? refreshed.headers : const <String, String>{});
  }

  Future<void> _serveDirect(
    HttpRequest request, {
    required String id,
    required Uri uri,
    Map<String, String> headers = const {},
    SourceUriRenewal? renew,
  }) async {
    final range = request.headers.value(HttpHeaders.rangeHeader);
    if (range != null && !RegExp(r'^bytes=(\d+-\d*|-\d+)$').hasMatch(range)) {
      request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      return;
    }
    final transport = SourceTransport(allowHttp: uri.scheme == 'http');
    try {
      var currentUri = uri;
      var currentHeaders = headers;
      var upstream = await transport.send(
        request.method,
        currentUri,
        headers: {...currentHeaders, HttpHeaders.rangeHeader: ?range},
        redirects: true,
        abort: _abort.future,
      );
      if (const {HttpStatus.unauthorized, HttpStatus.forbidden, HttpStatus.gone}.contains(upstream.statusCode) &&
          renew != null) {
        await upstream.stream.drain<void>();
        if (!valid()) throw const SourceException(SourceFailure.cancelled);
        final refreshed = await _renewDirectUri(
          id,
          expiredUri: currentUri,
          expiredHeaders: currentHeaders,
          renew: renew,
        );
        currentUri = refreshed.uri;
        currentHeaders = refreshed.headers;
        transport.validate(currentUri);
        upstream = await transport.send(
          request.method,
          currentUri,
          headers: {...currentHeaders, HttpHeaders.rangeHeader: ?range},
          redirects: true,
          abort: _abort.future,
        );
      }
      request.response.statusCode = upstream.statusCode;
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      for (final name in [
        HttpHeaders.contentTypeHeader,
        HttpHeaders.contentLengthHeader,
        HttpHeaders.contentRangeHeader,
        HttpHeaders.acceptRangesHeader,
        'etag',
        'last-modified',
      ]) {
        final value = upstream.headers[name];
        if (value != null) request.response.headers.set(name, value);
      }
      if (request.method == 'HEAD') {
        await upstream.stream.listen(null).cancel();
        return;
      }

      final contentType = upstream.headers[HttpHeaders.contentTypeHeader]?.toLowerCase() ?? '';
      final isHls = currentUri.path.toLowerCase().endsWith('.m3u8') || contentType.contains('mpegurl');
      if (!isHls || upstream.statusCode < 200 || upstream.statusCode >= 300) {
        await request.response.addStream(
          upstream.stream.timeout(const Duration(seconds: 45)).map((bytes) {
            if (!valid()) throw const SourceException(SourceFailure.cancelled);
            return bytes;
          }),
        );
        return;
      }

      const maxManifestBytes = 2 * 1024 * 1024;
      final bytes = <int>[];
      await for (final chunk in upstream.stream.timeout(const Duration(seconds: 30))) {
        if (bytes.length + chunk.length > maxManifestBytes) throw const SourceException(SourceFailure.invalidData);
        bytes.addAll(chunk);
      }
      final manifest = utf8.decode(bytes, allowMalformed: true);
      final manifestBase = upstream.request?.url ?? currentUri;
      final manifestHeaders = sameSourceOrigin(currentUri, manifestBase) ? currentHeaders : const <String, String>{};
      final rewritten = utf8.encode(
        await _rewriteHlsManifest(
          manifest,
          manifestBase,
          manifestHeaders,
          parentId: id,
          parentRenew: renew,
        ),
      );
      request.response.headers.set(HttpHeaders.contentLengthHeader, rewritten.length);
      await request.response.addStream(Stream<List<int>>.value(rewritten));
    } finally {
      transport.close();
    }
  }

  Future<void> close() async {
    _files.clear();
    _leases.clear();
    _directUris.clear();
    _directIdsByUri.clear();
    _nonDeduplicatedDirectIds.clear();
    _directRenewals.clear();
    if (!_abort.isCompleted) _abort.complete();
    await _server?.close(force: true);
    _server = null;
  }
}
