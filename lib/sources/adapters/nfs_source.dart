import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../source_models.dart';
import '../source_transport.dart';
import '../video_nfo.dart';

/// Read-only NFSv3 over TCP. Implements MOUNT v3, LOOKUP, READDIRPLUS,
/// GETATTR, and READ with AUTH_SYS credentials. RPC-with-TLS can be required
/// for every NFS and mountd connection. No filesystem write procedure is exposed.
class NfsSourceAdapter extends SourceAdapter {
  NfsSourceAdapter(super.source, super.transport, this._loadCredentials);

  final Future<Map<String, String>> Function() _loadCredentials;
  Future<SecurityContext>? _rpcTlsSecurityContext;

  bool get _requiresRpcTls => source.options['rpcTls'] == 'required';

  Future<SecurityContext> _secureRpcContext() => _rpcTlsSecurityContext ??= _createRpcTlsContext();

  Future<SecurityContext> _createRpcTlsContext() async {
    final certificatePem = source.options['rpcTlsServerCertificatePem']?.trim() ?? '';
    final context = SecurityContext(withTrustedRoots: true)..minimumTlsProtocolVersion = TlsProtocolVersion.tls1_3;
    try {
      if (certificatePem.isNotEmpty) {
        if (!certificatePem.contains('-----BEGIN CERTIFICATE-----') || certificatePem.contains('PRIVATE KEY')) {
          throw const SourceException(SourceFailure.invalidData);
        }

        if (Platform.isIOS) {
          // Dart's iOS SecurityContext accepts custom trust anchors as DER,
          // while other targets accept PEM. Convert each PEM certificate so
          // the same source configuration works on Apple mobile and tvOS.
          final certificates = RegExp(
            r'-----BEGIN CERTIFICATE-----([\s\S]*?)-----END CERTIFICATE-----',
          ).allMatches(certificatePem);
          if (certificates.isEmpty) {
            throw const SourceException(SourceFailure.invalidData);
          }
          for (final certificate in certificates) {
            final encoded = certificate.group(1)!.replaceAll(RegExp(r'\s'), '');
            if (encoded.isEmpty) throw const SourceException(SourceFailure.invalidData);
            context.setTrustedCertificatesBytes(base64Decode(encoded));
          }
        } else {
          context.setTrustedCertificatesBytes(utf8.encode(certificatePem));
        }
      }

      final credentials = await _loadCredentials();
      final identity = credentials['nfsTlsClientIdentity']?.trim();
      if (identity?.isNotEmpty == true) {
        final bytes = base64Decode(identity!);
        final password = credentials['nfsTlsClientIdentityPassword'];
        // A PKCS#12 bundle carries the certificate chain and key together;
        // this format is also required by Dart's iOS TLS implementation.
        context.useCertificateChainBytes(bytes, password: password);
        context.usePrivateKeyBytes(bytes, password: password);
      }
    } on SourceException {
      rethrow;
    } on Object {
      throw const SourceException(SourceFailure.invalidData);
    }
    return context;
  }

  static const int _nfsProgram = 100003;
  static const int _mountProgram = 100005;
  static const int _rpcVersion = 2;
  static const int _nfsVersion = 3;
  static const int _mountVersion = 3;
  static const int _directory = 2;
  static const int _regularFile = 1;
  static const int _maxFileHandle = 64;
  static const int _maxRead = 256 * 1024;
  static const List<int> _emptyVerifier = [0, 0, 0, 0, 0, 0, 0, 0];

  final Map<String, List<int>> _handles = {};
  Future<List<int>>? _mount;
  bool _closed = false;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(rangeRequests: true);

  Uri get _endpoint {
    final uri = Uri.tryParse(source.endpoint.trim());
    if (uri == null ||
        uri.scheme != 'nfs' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
      throw const SourceException(SourceFailure.permission);
    }
    return uri;
  }

  int get _nfsPort => _endpoint.hasPort ? _endpoint.port : 2049;

  int get _mountPort {
    final value = int.tryParse(source.options['mountPort'] ?? '') ?? 20048;
    if (value < 1 || value > 65535) throw const SourceException(SourceFailure.invalidData);
    return value;
  }

  int _identity(String key) {
    final parsed = int.tryParse(source.options[key] ?? '') ?? 1000;
    if (parsed < 0 || parsed > 0xffffffff) throw const SourceException(SourceFailure.invalidData);
    return parsed;
  }

  String get _exportPath {
    final parts = _endpoint.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.any((part) => part == '.' || part == '..' || part.contains('\u0000'))) {
      throw const SourceException(SourceFailure.permission);
    }
    return parts.isEmpty ? '/' : '/${parts.join('/')}';
  }

  String get _root {
    final input = source.root.trim();
    if (input.contains('\u0000') || input.contains('\r') || input.contains('\n')) {
      throw const SourceException(SourceFailure.permission);
    }
    if (input.split('/').contains('..')) throw const SourceException(SourceFailure.permission);
    final normalized = p.posix.normalize(input.startsWith('/') ? input : '/$input');
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

  Future<List<int>> _rootHandle() async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    final pending = _mount;
    if (pending != null) return pending;
    final task = _mountExport();
    _mount = task;
    try {
      return await task;
    } on Object {
      if (identical(_mount, task)) _mount = null;
      rethrow;
    }
  }

  Future<List<int>> _mountExport() async {
    final endpoint = _endpoint;
    final args = _XdrWriter()..string(_exportPath);
    final response = await _rpc(endpoint.host, _mountPort, _mountProgram, _mountVersion, 1, args.take());
    final reader = _XdrReader(response);
    final status = reader.uint32();
    if (status != 0) throw _nfsError(status);
    final handle = reader.opaque(maxLength: _maxFileHandle);
    final flavors = reader.uint32();
    if (flavors > 64) throw const SourceException(SourceFailure.invalidData);
    for (var i = 0; i < flavors; i++) {
      reader.uint32();
    }
    if (handle.isEmpty) throw const SourceException(SourceFailure.invalidData);
    _handles['/'] = handle;
    return handle;
  }

  Future<Uint8List> _rpc(String host, int port, int program, int version, int procedure, Uint8List arguments) async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    Socket? socket;
    _RpcWireReader? wire;
    try {
      final securityContext = _requiresRpcTls ? await _secureRpcContext() : null;
      socket = await Socket.connect(host, port, timeout: const Duration(seconds: 15));
      if (securityContext != null) {
        socket = await _upgradeRpcTls(socket, host, program, version, securityContext);
      }
      final random = math.Random.secure();
      final xid = random.nextInt(0xffffffff);
      final auth = _XdrWriter()
        ..uint32(DateTime.now().millisecondsSinceEpoch ~/ 1000)
        ..string('plezyng')
        ..uint32(_identity('uid'))
        ..uint32(_identity('gid'))
        ..uint32(0);
      final request = _XdrWriter()
        ..uint32(xid)
        ..uint32(0)
        ..uint32(_rpcVersion)
        ..uint32(program)
        ..uint32(version)
        ..uint32(procedure)
        ..uint32(1)
        ..opaque(auth.take())
        ..uint32(0)
        ..opaque(const <int>[])
        ..raw(arguments);
      final payload = request.take();
      if (payload.length > 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
      final record = Uint8List(payload.length + 4);
      ByteData.sublistView(record).setUint32(0, 0x80000000 | payload.length, Endian.big);
      record.setRange(4, record.length, payload);
      socket.add(record);
      await socket.flush().timeout(const Duration(seconds: 15));
      wire = _RpcWireReader(socket);
      final responseBytes = await wire.record();
      final response = _XdrReader(responseBytes);
      if (response.uint32() != xid || response.uint32() != 1) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final replyStatus = response.uint32();
      if (replyStatus != 0) throw const SourceException(SourceFailure.unavailable);
      response.uint32();
      response.opaque(maxLength: 400);
      final acceptStatus = response.uint32();
      if (acceptStatus != 0) throw const SourceException(SourceFailure.unsupported);
      return response.remaining();
    } on SourceException {
      rethrow;
    } on Object {
      throw const SourceException(SourceFailure.unavailable);
    } finally {
      await wire?.cancel();
      socket?.destroy();
    }
  }

  Future<Socket> _upgradeRpcTls(Socket socket, String host, int program, int version, SecurityContext context) async {
    final xid = math.Random.secure().nextInt(0xffffffff);
    final probe = _XdrWriter()
      ..uint32(xid)
      ..uint32(0)
      ..uint32(_rpcVersion)
      ..uint32(program)
      ..uint32(version)
      ..uint32(0)
      ..uint32(7)
      ..opaque(const <int>[])
      ..uint32(0)
      ..opaque(const <int>[]);
    final payload = probe.take();
    final record = Uint8List(payload.length + 4);
    ByteData.sublistView(record).setUint32(0, 0x80000000 | payload.length, Endian.big);
    record.setRange(4, record.length, payload);
    socket.add(record);
    await socket.flush().timeout(const Duration(seconds: 15));

    final probeWire = _RpcWireReader(socket);
    var transferredToTls = false;
    try {
      final bytes = await probeWire.record();
      final reply = _XdrReader(bytes);
      if (reply.uint32() != xid || reply.uint32() != 1) {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (reply.uint32() != 0) throw const SourceException(SourceFailure.unsupported);
      final verifierFlavor = reply.uint32();
      final verifier = reply.opaque(maxLength: 400);
      if (verifierFlavor != 0 || utf8.decode(verifier, allowMalformed: true) != 'STARTTLS') {
        throw const SourceException(SourceFailure.unsupported);
      }
      // RFC 9289 permits starting TLS even when the NULL procedure itself is
      // rejected after the server has signaled STARTTLS in its verifier.
      reply.uint32();
      // Pause the stream before detaching the raw socket so no TLS handshake
      // bytes are consumed as if they were additional RPC records.
      probeWire.pause();
      // SecureSocket.secure takes ownership of the paused subscription.
      // Cancelling it afterwards would also stop reads from the TLS socket.
      transferredToTls = true;
      try {
        return await SecureSocket.secure(socket, host: host, context: context).timeout(const Duration(seconds: 15));
      } on SourceException {
        rethrow;
      } on Object {
        throw const SourceException(SourceFailure.unavailable);
      }
    } finally {
      if (!transferredToTls) await probeWire.cancel();
    }
  }

  SourceException _nfsError(int status) => SourceException(switch (status) {
    1 || 2 || 13 || 30 => SourceFailure.permission,
    5 || 6 || 70 || 71 || 10001 => SourceFailure.unavailable,
    22 || 10003 || 10005 => SourceFailure.invalidData,
    10004 => SourceFailure.unsupported,
    _ => SourceFailure.unavailable,
  }, status: status);

  Future<({List<int> handle, _NfsAttributes? attributes})> _lookup(List<int> directory, String name) async {
    if (name.isEmpty || name == '.' || name == '..' || name.contains('/') || name.contains('\u0000')) {
      throw const SourceException(SourceFailure.permission);
    }
    final args = _XdrWriter()
      ..opaque(directory)
      ..string(name);
    final response = await _rpc(_endpoint.host, _nfsPort, _nfsProgram, _nfsVersion, 3, args.take());
    final reader = _XdrReader(response);
    final status = reader.uint32();
    if (status != 0) throw _nfsError(status);
    final handle = reader.opaque(maxLength: _maxFileHandle);
    final attrs = _postAttributes(reader);
    _postAttributes(reader);
    if (handle.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return (handle: handle, attributes: attrs);
  }

  Future<List<int>> _handleForPath(String path) async {
    final normalized = _path(path);
    final cached = _handles[normalized];
    if (cached != null) return cached;
    var handle = await _rootHandle();
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    var current = '';
    for (final part in parts) {
      current = current.isEmpty ? '/$part' : '$current/$part';
      final existing = _handles[current];
      if (existing != null) {
        handle = existing;
        continue;
      }
      final found = await _lookup(handle, part);
      handle = found.handle;
      _handles[current] = handle;
    }
    return handle;
  }

  _NfsAttributes? _postAttributes(_XdrReader reader) {
    if (!reader.boolean()) return null;
    return _attributes(reader);
  }

  _NfsAttributes _attributes(_XdrReader reader) {
    final type = reader.uint32();
    reader.uint32();
    reader.uint32();
    reader.uint32();
    reader.uint32();
    final size = reader.uint64();
    reader.uint64();
    reader.uint32();
    reader.uint32();
    reader.uint64();
    reader.uint64();
    final atimeSec = reader.uint32();
    reader.uint32();
    final mtimeSec = reader.uint32();
    reader.uint32();
    reader.uint32();
    reader.uint32();
    return _NfsAttributes(type, size, mtimeSec == 0 ? atimeSec : mtimeSec);
  }

  Future<_NfsAttributes> _getAttributes(List<int> handle) async {
    final args = _XdrWriter()..opaque(handle);
    final response = await _rpc(_endpoint.host, _nfsPort, _nfsProgram, _nfsVersion, 1, args.take());
    final reader = _XdrReader(response);
    final status = reader.uint32();
    if (status != 0) throw _nfsError(status);
    final attributes = _postAttributes(reader);
    if (attributes == null) throw const SourceException(SourceFailure.invalidData);
    return attributes;
  }

  Future<_NfsDirectoryPage> _readDirectory(
    List<int> handle, {
    int cookie = 0,
    List<int> verifier = _emptyVerifier,
  }) async {
    try {
      return await _readDirectoryPlus(handle, cookie: cookie, verifier: verifier);
    } on SourceException catch (error) {
      if (error.reason != SourceFailure.unsupported && error.status != 10005) rethrow;
      return _readDirectorySimple(handle, cookie: cookie, verifier: verifier);
    }
  }

  Future<_NfsDirectoryPage> _readDirectorySimple(
    List<int> handle, {
    required int cookie,
    required List<int> verifier,
  }) async {
    final args = _XdrWriter()
      ..opaque(handle)
      ..uint64(cookie)
      ..fixed(verifier)
      ..uint32(64 * 1024);
    final response = await _rpc(_endpoint.host, _nfsPort, _nfsProgram, _nfsVersion, 16, args.take());
    final reader = _XdrReader(response);
    final status = reader.uint32();
    if (status != 0) throw _nfsError(status);
    _postAttributes(reader);
    final nextVerifier = reader.fixed(8);
    final rows = <_NfsDirectoryEntry>[];
    var lastCookie = cookie;
    while (reader.boolean()) {
      final fileId = reader.uint64();
      final name = reader.string(maxLength: 255);
      final nextCookie = reader.uint64();
      if (name.isNotEmpty && name != '.' && name != '..') {
        try {
          final found = await _lookup(handle, name);
          rows.add(_NfsDirectoryEntry(fileId, name, nextCookie, found.attributes, found.handle));
        } on Object {
          // READDIR may reveal a name that LOOKUP cannot read; omit that row.
        }
      }
      lastCookie = nextCookie;
    }
    final eof = reader.boolean();
    return _NfsDirectoryPage(rows, nextVerifier, eof, lastCookie);
  }

  Future<_NfsDirectoryPage> _readDirectoryPlus(
    List<int> handle, {
    int cookie = 0,
    List<int> verifier = _emptyVerifier,
  }) async {
    final args = _XdrWriter()
      ..opaque(handle)
      ..uint64(cookie)
      ..fixed(verifier)
      ..uint32(64 * 1024)
      ..uint32(256 * 1024);
    final response = await _rpc(_endpoint.host, _nfsPort, _nfsProgram, _nfsVersion, 17, args.take());
    final reader = _XdrReader(response);
    final status = reader.uint32();
    if (status != 0) throw _nfsError(status);
    _postAttributes(reader);
    final nextVerifier = reader.fixed(8);
    final rows = <_NfsDirectoryEntry>[];
    var lastCookie = cookie;
    while (reader.boolean()) {
      final fileId = reader.uint64();
      final name = reader.string(maxLength: 255);
      final nextCookie = reader.uint64();
      final attributes = _postAttributes(reader);
      final childHandle = reader.boolean() ? reader.opaque(maxLength: _maxFileHandle) : const <int>[];
      if (name.isNotEmpty && name != '.' && name != '..') {
        rows.add(_NfsDirectoryEntry(fileId, name, nextCookie, attributes, childHandle));
      }
      lastCookie = nextCookie;
    }
    final eof = reader.boolean();
    return _NfsDirectoryPage(rows, nextVerifier, eof, lastCookie);
  }

  Future<SourcePage> _browse(String directory, {String? cursor, String? query}) async {
    var cookie = 0;
    var verifier = _emptyVerifier;
    if (cursor != null && cursor.isNotEmpty) {
      final parts = cursor.split(':');
      if (parts.length != 2) throw const SourceException(SourceFailure.invalidData);
      cookie = int.tryParse(parts[0]) ?? -1;
      try {
        verifier = base64Url.decode(base64Url.normalize(parts[1]));
      } on Object {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (cookie < 0 || verifier.length != 8) throw const SourceException(SourceFailure.invalidData);
    }
    final handle = await _handleForPath(directory);
    final page = await _readDirectory(handle, cookie: cookie, verifier: verifier);
    final entries = <SourceEntry>[];
    for (final row in page.entries) {
      final path = _child(directory, row.name);
      if (row.handle.isNotEmpty) _handles[path] = row.handle;
      final isDirectory = row.attributes?.type == _directory;
      final isFile = row.attributes?.type == _regularFile;
      if (!isDirectory && !isFile) continue;
      if (query != null && !row.name.toLowerCase().contains(query.toLowerCase())) continue;
      final kind = isDirectory ? SourceItemKind.folder : classifySourceFile(row.name, lookupMimeType(row.name) ?? '');
      if (kind == SourceItemKind.unknown) continue;
      final size = row.attributes?.size;
      final revision = row.attributes == null ? null : '${size?.toString() ?? ''}:${row.attributes!.modifiedSeconds}';
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: path,
          title: row.name,
          kind: kind,
          parentId: directory,
          files: isDirectory
              ? const []
              : [
                  PublicationFile(
                    id: path,
                    name: row.name,
                    mimeType: lookupMimeType(row.name) ?? '',
                    size: size,
                    revision: revision,
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
    final next = page.eof || page.cookie == cookie ? null : '${page.cookie}:${base64Url.encode(page.verifier)}';
    return SourcePage(entries, next: next);
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) =>
      _browse(_path(parent ?? _root), cursor: cursor, query: query);

  Future<Uint8List?> _readWhole(List<int> handle, int size, int limit) async {
    if (size <= 0 || size > limit) return null;
    final bytes = BytesBuilder(copy: false);
    var offset = 0;
    while (offset < size) {
      final chunk = await _read(handle, offset, math.min(_maxRead, size - offset));
      if (chunk.isEmpty) break;
      bytes.add(chunk);
      offset += chunk.length;
    }
    final result = bytes.takeBytes();
    return result.length == size ? result : null;
  }

  Future<Uint8List> _read(List<int> handle, int offset, int count) async {
    final args = _XdrWriter()
      ..opaque(handle)
      ..uint64(offset)
      ..uint32(count);
    final response = await _rpc(_endpoint.host, _nfsPort, _nfsProgram, _nfsVersion, 6, args.take());
    final reader = _XdrReader(response);
    final status = reader.uint32();
    if (status != 0) throw _nfsError(status);
    _postAttributes(reader);
    final returned = reader.uint32();
    reader.boolean();
    final bytes = reader.opaque(maxLength: _maxRead);
    if (bytes.length > count || returned != bytes.length) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return bytes;
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
      final directoryHandle = await _handleForPath(directory);
      final siblings = <String, _NfsDirectoryEntry>{};
      var cookie = 0;
      var verifier = _emptyVerifier;
      for (var pageNumber = 0; pageNumber < 16; pageNumber++) {
        final page = await _readDirectory(directoryHandle, cookie: cookie, verifier: verifier);
        for (final row in page.entries) {
          siblings[row.name.toLowerCase()] = row;
          if (row.handle.isNotEmpty) _handles[_child(directory, row.name)] = row.handle;
        }
        if (page.eof || page.cookie == cookie) break;
        cookie = page.cookie;
        verifier = page.verifier;
      }
      VideoNfoMetadata? metadata;
      for (final name in ['${stem.toLowerCase()}.nfo', '${filename.toLowerCase()}.nfo']) {
        final row = siblings[name];
        if (row == null || row.attributes?.type != _regularFile || row.handle.isEmpty) continue;
        final bytes = await _readWhole(row.handle, row.attributes!.size, 1024 * 1024);
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
        if (row == null ||
            row.attributes?.type != _regularFile ||
            row.attributes!.size <= 0 ||
            row.attributes!.size > 8 * 1024 * 1024) {
          continue;
        }
        poster = _child(directory, row.name);
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
    final path = _path(cover);
    final handle = await _handleForPath(path);
    final attrs = await _getAttributes(handle);
    return _readWhole(handle, attrs.size, 8 * 1024 * 1024);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async => throw const SourceException(SourceFailure.unsupported);

  @override
  Future<int?> contentSize(PublicationFile file) async {
    if (file.size != null) return file.size;
    return (await _getAttributes(await _handleForPath(file.id))).size;
  }

  Stream<List<int>> _readRange(List<int> handle, int size, int offset, int length) async* {
    var position = offset;
    final end = offset + length;
    while (position < end) {
      final count = math.min(_maxRead, end - position);
      final bytes = await _read(handle, position, count);
      if (bytes.isEmpty) break;
      yield bytes;
      position += bytes.length;
    }
  }

  @override
  Future<SourceByteStream?> openContent(PublicationFile file, {required int offset, required int length}) async {
    if (offset < 0 || length < 0) throw const SourceException(SourceFailure.invalidData);
    final handle = await _handleForPath(file.id);
    final attributes = await _getAttributes(handle);
    final size = attributes.size;
    if (offset > size) throw const SourceException(SourceFailure.invalidData);
    final actualLength = length > size - offset ? size - offset : length;
    return SourceByteStream(
      stream: _readRange(handle, size, offset, actualLength),
      size: size,
      offset: offset,
      length: actualLength,
    );
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _handles.clear();
    super.close();
  }
}

class _NfsAttributes {
  const _NfsAttributes(this.type, this.size, this.modifiedSeconds);
  final int type;
  final int size;
  final int modifiedSeconds;
}

class _NfsDirectoryEntry {
  const _NfsDirectoryEntry(this.fileId, this.name, this.cookie, this.attributes, this.handle);
  final int fileId;
  final String name;
  final int cookie;
  final _NfsAttributes? attributes;
  final List<int> handle;
}

class _NfsDirectoryPage {
  const _NfsDirectoryPage(this.entries, this.verifier, this.eof, this.cookie);
  final List<_NfsDirectoryEntry> entries;
  final List<int> verifier;
  final bool eof;
  final int cookie;
}

class _XdrWriter {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  void uint32(int value) =>
      _builder.add([(value >> 24) & 0xff, (value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff]);

  void uint64(int value) {
    uint32((value >> 32) & 0xffffffff);
    uint32(value & 0xffffffff);
  }

  void boolean(bool value) => uint32(value ? 1 : 0);

  void fixed(List<int> bytes) {
    _builder.add(bytes);
    final padding = (4 - bytes.length % 4) % 4;
    if (padding > 0) _builder.add(List<int>.filled(padding, 0));
  }

  void opaque(List<int> bytes) {
    uint32(bytes.length);
    fixed(bytes);
  }

  void string(String value) => opaque(utf8.encode(value));
  void raw(List<int> bytes) => _builder.add(bytes);
  Uint8List take() => _builder.takeBytes();
}

class _XdrReader {
  _XdrReader(this._bytes);
  final Uint8List _bytes;
  int _offset = 0;

  void _need(int length) {
    if (length < 0 || _offset + length > _bytes.length) {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  int uint32() {
    _need(4);
    final result =
        (_bytes[_offset] << 24) | (_bytes[_offset + 1] << 16) | (_bytes[_offset + 2] << 8) | _bytes[_offset + 3];
    _offset += 4;
    return result;
  }

  int uint64() => (uint32() << 32) | uint32();
  bool boolean() => uint32() != 0;

  Uint8List fixed(int length) {
    _need(length);
    final result = Uint8List.fromList(_bytes.sublist(_offset, _offset + length));
    _offset += length;
    final padding = (4 - length % 4) % 4;
    _need(padding);
    _offset += padding;
    return result;
  }

  Uint8List opaque({required int maxLength}) {
    final length = uint32();
    if (length > maxLength) throw const SourceException(SourceFailure.invalidData);
    return fixed(length);
  }

  String string({required int maxLength}) => utf8.decode(opaque(maxLength: maxLength), allowMalformed: true);

  Uint8List remaining() {
    final result = Uint8List.fromList(_bytes.sublist(_offset));
    _offset = _bytes.length;
    return result;
  }
}

class _RpcWireReader {
  _RpcWireReader(Stream<List<int>> stream) {
    _subscription = stream.listen(
      _onData,
      onError: (Object error, StackTrace stackTrace) {
        _error = error;
        _signal();
      },
      onDone: () {
        _done = true;
        _signal();
      },
    );
  }

  StreamSubscription<List<int>>? _subscription;
  List<int> _buffer = [];
  int _offset = 0;
  Object? _error;
  bool _done = false;
  Completer<void>? _changed;

  void _onData(List<int> chunk) {
    if (chunk.isEmpty) return;
    final rest = _buffer.sublist(_offset);
    _buffer = [...rest, ...chunk];
    _offset = 0;
    _signal();
  }

  void _signal() {
    final changed = _changed;
    _changed = null;
    if (changed != null && !changed.isCompleted) changed.complete();
  }

  void pause() => _subscription?.pause();

  Future<void> cancel() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  Future<Uint8List> _readExact(int length) async {
    while (_buffer.length - _offset < length) {
      final error = _error;
      if (error != null) throw SourceException(SourceFailure.unavailable);
      if (_done) throw const SourceException(SourceFailure.unavailable);
      final changed = _changed ??= Completer<void>();
      try {
        await changed.future.timeout(const Duration(seconds: 20));
      } on TimeoutException {
        throw const SourceException(SourceFailure.unavailable);
      }
    }
    final result = Uint8List.fromList(_buffer.sublist(_offset, _offset + length));
    _offset += length;
    return result;
  }

  Future<Uint8List> record() async {
    final parts = BytesBuilder(copy: false);
    var finalFragment = false;
    var total = 0;
    while (!finalFragment) {
      final marker = ByteData.sublistView(await _readExact(4)).getUint32(0, Endian.big);
      finalFragment = (marker & 0x80000000) != 0;
      final length = marker & 0x7fffffff;
      total += length;
      if (total > 16 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
      parts.add(await _readExact(length));
    }
    return parts.takeBytes();
  }
}
