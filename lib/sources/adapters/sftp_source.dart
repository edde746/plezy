import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../source_models.dart';
import '../source_transport.dart';
import '../video_nfo.dart';

class SftpSourceAdapter extends SourceAdapter {
  SftpSourceAdapter(super.source, super.transport, this.credentials);

  final Future<Map<String, String>> Function() credentials;
  SSHClient? _ssh;
  SftpClient? _sftp;
  Future<SftpClient>? _pending;
  bool _closed = false;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(rangeRequests: true);

  Uri get _endpoint {
    final uri = Uri.tryParse(source.endpoint.trim());
    if (uri == null ||
        uri.scheme != 'sftp' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
      throw const SourceException(SourceFailure.permission);
    }
    return uri;
  }

  int get _port => _endpoint.hasPort ? _endpoint.port : 22;

  String get _root {
    final configured = source.root.trim().isEmpty ? _endpoint.path : source.root.trim();
    if (configured.contains('\u0000') || configured.contains('\r') || configured.contains('\n')) {
      throw const SourceException(SourceFailure.permission);
    }
    if (configured.split('/').contains('..')) throw const SourceException(SourceFailure.permission);
    final normalized = p.posix.normalize(configured.startsWith('/') ? configured : '/$configured');
    if (normalized.split('/').contains('..')) throw const SourceException(SourceFailure.permission);
    return normalized == '.' ? '/' : normalized;
  }

  String _path(String value) {
    if (value.contains('\u0000') || value.contains('\r') || value.contains('\n')) {
      throw const SourceException(SourceFailure.permission);
    }
    final raw = value.startsWith('/') ? value : p.posix.join(_root, value);
    if (raw.split('/').contains('..')) throw const SourceException(SourceFailure.permission);
    final normalized = p.posix.normalize(raw);
    final root = _root;
    if (root != '/' && normalized != root && !normalized.startsWith(root.endsWith('/') ? root : '$root/')) {
      throw const SourceException(SourceFailure.permission);
    }
    return normalized;
  }

  String _child(String parent, String name) {
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains('\u0000') ||
        name.contains('\r') ||
        name.contains('\n')) {
      throw const SourceException(SourceFailure.permission);
    }
    return _path(p.posix.join(_path(parent), name));
  }

  Future<SftpClient> _connection() async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    final current = _sftp;
    if (current != null) return current;
    final pending = _pending;
    if (pending != null) return pending;
    final future = _open();
    _pending = future;
    try {
      return await future;
    } finally {
      if (identical(_pending, future)) _pending = null;
    }
  }

  Future<SftpClient> _open() async {
    final endpoint = _endpoint;
    final values = await credentials();
    final username = values['username']?.trim() ?? '';
    final password = values['password'] ?? '';
    final fingerprint = values['hostKeyFingerprint']?.trim() ?? '';
    if (username.isEmpty || fingerprint.isEmpty || !fingerprint.startsWith('SHA256:')) {
      throw const SourceException(SourceFailure.authentication);
    }

    SSHClient? ssh;
    try {
      final socket = await SSHSocket.connect(endpoint.host, _port).timeout(const Duration(seconds: 20));
      final pem = values['privateKey']?.trim() ?? '';
      final identities = pem.isEmpty
          ? const <SSHKeyPair>[]
          : SSHKeyPair.fromPem(pem, values['privateKeyPassphrase'] ?? '');
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
        identities: identities,
        handshakeTimeout: const Duration(seconds: 20),
        authTimeout: const Duration(seconds: 20),
        onVerifyHostKey: (type, received) => utf8.decode(received).trim() == fingerprint,
      );
      ssh = client;
      await client.authenticated.timeout(const Duration(seconds: 25));
      final sftp = await client.sftp().timeout(const Duration(seconds: 20));
      if (_closed) {
        await client.close();
        throw const SourceException(SourceFailure.cancelled);
      }
      _ssh = client;
      _sftp = sftp;
      return sftp;
    } on SourceException {
      await ssh?.close();
      rethrow;
    } on Object {
      await ssh?.close();
      throw const SourceException(SourceFailure.unavailable);
    }
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final directory = _path(parent ?? _root);
    try {
      final rows = await (await _connection()).listdir(directory);
      final entries = <SourceEntry>[];
      for (final row in rows) {
        final name = row.filename;
        if (name == '.' || name == '..' || name.startsWith('.')) continue;
        final path = _child(directory, name);
        final isDirectory = row.attr.isDirectory;
        if (!isDirectory && !row.attr.isFile) continue;
        if (query != null && !name.toLowerCase().contains(query.toLowerCase())) continue;
        final kind = isDirectory ? SourceItemKind.folder : classifySourceFile(name, lookupMimeType(name) ?? '');
        if (kind == SourceItemKind.unknown) continue;
        final size = row.attr.size;
        final modified = row.attr.modifyTime;
        entries.add(
          SourceEntry(
            sourceId: source.id,
            id: path,
            title: name,
            kind: kind,
            parentId: directory,
            files: isDirectory
                ? const []
                : [
                    PublicationFile(
                      id: path,
                      name: name,
                      mimeType: lookupMimeType(name) ?? '',
                      size: size,
                      revision: size == null && modified == null
                          ? null
                          : '${size?.toString() ?? ''}:${modified?.toString() ?? ''}',
                    ),
                  ],
          ),
        );
      }
      entries.sort(
        (a, b) => a.isFolder == b.isFolder
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : a.isFolder
            ? -1
            : 1,
      );
      return SourcePage(entries);
    } on SourceException {
      rethrow;
    } on Object {
      throw const SourceException(SourceFailure.unavailable);
    }
  }

  Future<Uint8List?> _readBounded(SftpClient sftp, String path, int? size, int limit) async {
    if (size == null || size <= 0 || size > limit) return null;
    final file = await sftp.open(path);
    try {
      return await file.readBytes(length: size, offset: 0);
    } finally {
      await file.close();
    }
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async {
    if (entry.kind != SourceItemKind.video) return entry;
    try {
      final path = _path(entry.id);
      final directory = p.posix.dirname(path);
      final filename = p.posix.basename(path);
      final dot = filename.lastIndexOf('.');
      final stem = dot > 0 ? filename.substring(0, dot) : filename;
      final sftp = await _connection();
      final rows = await sftp.listdir(directory);
      final siblings = {for (final row in rows) row.filename.toLowerCase(): row};
      VideoNfoMetadata? metadata;
      for (final name in ['${stem.toLowerCase()}.nfo', '${filename.toLowerCase()}.nfo']) {
        final row = siblings[name];
        if (row == null || !row.attr.isFile) continue;
        final bytes = await _readBounded(sftp, _child(directory, row.filename), row.attr.size, 1024 * 1024);
        if (bytes == null) continue;
        metadata = parseVideoNfo(utf8.decode(bytes, allowMalformed: true));
        if (metadata != null) break;
      }
      String? poster;
      const extensions = ['jpg', 'jpeg', 'png', 'webp'];
      final names = <String>[
        for (final ext in extensions) '${stem.toLowerCase()}-poster.$ext',
        for (final ext in extensions) '${stem.toLowerCase()}.$ext',
        for (final ext in extensions) 'poster.$ext',
        for (final ext in extensions) 'cover.$ext',
        for (final ext in extensions) 'folder.$ext',
      ];
      for (final name in names) {
        final row = siblings[name];
        if (row == null || !row.attr.isFile || (row.attr.size ?? 0) <= 0 || row.attr.size! > 8 * 1024 * 1024) continue;
        poster = _child(directory, row.filename);
        break;
      }
      var hydrated = metadata?.applyTo(entry) ?? entry;
      if (poster != null) hydrated = hydrated.copyWith(coverId: poster);
      return hydrated;
    } on Object {
      return entry;
    }
  }

  @override
  Future<List<int>?> coverBytes(SourceEntry entry) async {
    final cover = entry.coverId;
    if (cover == null) return null;
    final sftp = await _connection();
    final attrs = await sftp.stat(_path(cover));
    final bytes = await _readBounded(sftp, _path(cover), attrs.size, 8 * 1024 * 1024);
    return bytes;
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async => throw const SourceException(SourceFailure.unsupported);

  @override
  Future<int?> contentSize(PublicationFile file) async {
    if (file.size != null) return file.size;
    return (await (await _connection()).stat(_path(file.id))).size;
  }

  @override
  Future<SourceByteStream?> openContent(PublicationFile file, {required int offset, required int length}) async {
    final sftp = await _connection();
    final path = _path(file.id);
    final attrs = await sftp.stat(path);
    final size = attrs.size;
    if (size == null || size < 0 || offset < 0 || length < 0 || offset > size) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final actualLength = length > size - offset ? size - offset : length;
    Stream<List<int>> readRange() async* {
      final remote = await sftp.open(path);
      try {
        yield* remote.read(length: actualLength, offset: offset);
      } finally {
        await remote.close();
      }
    }

    return SourceByteStream(stream: readRange(), size: size, offset: offset, length: actualLength);
  }

  @override
  Future<void> refreshAuthorization() async {
    final ssh = _ssh;
    _ssh = null;
    _sftp = null;
    _pending = null;
    await ssh?.close();
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    final ssh = _ssh;
    _ssh = null;
    _sftp = null;
    _pending = null;
    if (ssh != null) unawaited(ssh.close());
    super.close();
  }
}
