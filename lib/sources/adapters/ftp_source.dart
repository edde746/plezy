import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../source_models.dart';
import '../source_transport.dart';

/// Read-only passive FTP/explicit-FTPS adapter. Each metadata or range request
/// gets a short-lived control connection so canceled player seeks cannot leave
/// a stale transfer or authenticated socket behind.
class FtpSourceAdapter extends SourceAdapter {
  FtpSourceAdapter(super.source, super.transport, this.credentials);

  final Future<Map<String, String>> Function() credentials;
  final Set<_FtpSession> _sessions = {};
  bool _closed = false;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(rangeRequests: true);

  Uri get _endpoint {
    final uri = Uri.tryParse(source.endpoint.trim());
    if (uri == null ||
        !const {'ftp', 'ftpes', 'ftps'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const SourceException(SourceFailure.permission);
    }
    return uri;
  }

  int get _port {
    final endpoint = _endpoint;
    return endpoint.hasPort ? endpoint.port : 21;
  }

  String _cleanPath(String value) {
    final input = value.replaceAll('\\', '/');
    if (input.contains('\u0000') || input.contains('\r') || input.contains('\n')) {
      throw const SourceException(SourceFailure.permission);
    }
    final absolute = input.startsWith('/');
    final segments = input.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.any((segment) => segment == '.' || segment == '..')) {
      throw const SourceException(SourceFailure.permission);
    }
    return segments.isEmpty ? (absolute ? '/' : '') : '${absolute ? '/' : ''}${segments.join('/')}';
  }

  String get _root {
    final configured = source.root.trim();
    return _cleanPath(configured.isEmpty ? _endpoint.path : configured);
  }

  String _path(String value) {
    final path = _cleanPath(value);
    final root = _root;
    if (root.isNotEmpty && path != root && !path.startsWith(root.endsWith('/') ? root : '$root/')) {
      throw const SourceException(SourceFailure.permission);
    }
    return path;
  }

  String _child(String parent, String name) {
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains('\\') ||
        name.contains('\u0000') ||
        name.contains('\r') ||
        name.contains('\n')) {
      throw const SourceException(SourceFailure.permission);
    }
    final base = _path(parent);
    if (base.isEmpty) return name;
    return base.endsWith('/') ? '$base$name' : '$base/$name';
  }

  Future<_FtpSession> _connect() async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    final endpoint = _endpoint;
    final session = _FtpSession(
      host: endpoint.host,
      port: _port,
      tls: endpoint.scheme != 'ftp',
      implicitTls: endpoint.scheme == 'ftps' && _port == 990,
    );
    _sessions.add(session);
    try {
      await session.open(await credentials());
      if (_closed) throw const SourceException(SourceFailure.cancelled);
      return session;
    } catch (error) {
      _sessions.remove(session);
      await session.close();
      throw error is SourceException ? error : const SourceException(SourceFailure.unavailable);
    }
  }

  Future<void> _release(_FtpSession session) async {
    _sessions.remove(session);
    await session.close();
  }

  Future<_FtpStat> _stat(String value) async {
    final path = _path(value);
    final session = await _connect();
    try {
      final sizeReply = await session.command('SIZE $path');
      if (sizeReply.code != 213) throw session.failure(sizeReply);
      final size = int.tryParse(sizeReply.message.trim());
      if (size == null || size < 0) throw const SourceException(SourceFailure.invalidData);
      final modified = await session.command('MDTM $path');
      final timestamp = modified.code == 213 ? modified.message.trim() : null;
      return _FtpStat(size, timestamp == null ? null : '$size:$timestamp');
    } finally {
      await _release(session);
    }
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final directory = _path(parent ?? _root);
    var text = '';
    var facts = true;
    var session = await _connect();
    try {
      try {
        text = await session.readTransfer('MLSD $directory', limit: 8 * 1024 * 1024);
      } on SourceException catch (error) {
        if (error.reason != SourceFailure.unsupported) rethrow;
        facts = false;
      }
    } finally {
      await _release(session);
    }
    if (!facts) {
      session = await _connect();
      try {
        text = await session.readTransfer('LIST $directory', limit: 8 * 1024 * 1024);
      } finally {
        await _release(session);
      }
    }

    final entries = <SourceEntry>[];
    for (final line in const LineSplitter().convert(text)) {
      final row = facts ? _parseMlsd(line) : _parseList(line);
      if (row == null || row.name.startsWith('.') || row.name == '.' || row.name == '..') continue;
      if (query != null && !row.name.toLowerCase().contains(query.toLowerCase())) continue;
      if (!row.directory && row.size == null) continue;
      final id = _child(directory, row.name);
      final kind = row.directory
          ? SourceItemKind.folder
          : classifySourceFile(row.name, lookupMimeType(row.name) ?? '');
      if (kind == SourceItemKind.unknown) continue;
      final mime = row.directory ? '' : lookupMimeType(row.name) ?? '';
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: row.name,
          kind: kind,
          parentId: directory.isEmpty ? null : directory,
          files: row.directory
              ? const []
              : [
                  PublicationFile(
                    id: id,
                    name: row.name,
                    mimeType: mime,
                    size: row.size,
                    revision: row.modify == null || row.size == null ? null : '${row.size}:${row.modify}',
                  ),
                ],
        ),
      );
    }
    entries.sort((a, b) => a.isFolder == b.isFolder
        ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
        : a.isFolder
        ? -1
        : 1);
    return SourcePage(entries);
  }

  ({String name, bool directory, int? size, String? modify})? _parseMlsd(String line) {
    final split = line.indexOf(' ');
    if (split <= 0 || split == line.length - 1) return null;
    final name = line.substring(split + 1);
    final fields = <String, String>{};
    for (final fact in line.substring(0, split).split(';')) {
      final equals = fact.indexOf('=');
      if (equals > 0) fields[fact.substring(0, equals).toLowerCase()] = fact.substring(equals + 1);
    }
    final type = fields['type']?.toLowerCase();
    if (type == null || const {'cdir', 'pdir'}.contains(type)) return null;
    if (type != 'file' && type != 'dir' && type != 'directory') return null;
    return (
      name: name,
      directory: type != 'file',
      size: int.tryParse(fields['size'] ?? ''),
      modify: fields['modify'],
    );
  }

  ({String name, bool directory, int? size, String? modify})? _parseList(String line) {
    final unix = RegExp(r'^([bcdlps-][rwxStTs-]{9})\s+\d+\s+\S+\s+\S+\s+(\d+)\s+\w{3}\s+\d{1,2}\s+\S+\s+(.+)$')
        .firstMatch(line);
    if (unix != null) {
      final mode = unix[1]!;
      if (mode.startsWith('l')) return null;
      return (name: unix[3]!, directory: mode.startsWith('d'), size: int.tryParse(unix[2]!), modify: null);
    }
    final dos = RegExp(r'^(\d{2}-\d{2}-\d{2,4}\s+\d{1,2}:\d{2}[AP]M)\s+(<DIR>|\d+)\s+(.+)$', caseSensitive: false)
        .firstMatch(line);
    if (dos == null) return null;
    return (
      name: dos[3]!,
      directory: dos[2]!.toUpperCase() == '<DIR>',
      size: int.tryParse(dos[2]!),
      modify: dos[1],
    );
  }

  @override
  Future<int?> contentSize(PublicationFile file) async => file.size ?? (await _stat(file.id)).size;

  @override
  Future<ContentLease> resolve(PublicationFile file) async =>
      throw const SourceException(SourceFailure.unsupported);

  @override
  Future<SourceByteStream?> openContent(
    PublicationFile file, {
    required int offset,
    required int length,
  }) async {
    final current = await _stat(file.id);
    if (file.size != null && current.size != file.size ||
        file.revision != null && current.revision != null && file.revision != current.revision) {
      throw const SourceException(SourceFailure.conflict);
    }
    if (offset < 0 || length < 0 || offset > current.size || length > current.size - offset) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return SourceByteStream(
      stream: _readRange(file.id, current.size, offset, length),
      size: current.size,
      offset: offset,
      length: length,
    );
  }

  Stream<List<int>> _readRange(String value, int size, int offset, int length) async* {
    if (length == 0) return;
    final path = _path(value);
    final session = await _connect();
    try {
      final current = await session.command('SIZE $path');
      if (current.code != 213 || int.tryParse(current.message.trim()) != size) {
        throw const SourceException(SourceFailure.conflict);
      }
      if (offset > 0) {
        final restart = await session.command('REST $offset');
        if (restart.code != 350) throw session.failure(restart);
      }
      final data = await session.openData('RETR $path');
      var remaining = length;
      await for (final chunk in data.timeout(const Duration(seconds: 45))) {
        if (remaining <= 0) break;
        final take = math.min(remaining, chunk.length).toInt();
        if (take > 0) {
          yield take == chunk.length ? chunk : chunk.sublist(0, take);
          remaining -= take;
        }
        if (remaining == 0) break;
      }
      if (remaining != 0) throw const SourceException(SourceFailure.invalidData);
    } finally {
      await _release(session);
    }
  }

  @override
  void close() {
    _closed = true;
    for (final session in _sessions.toList()) {
      unawaited(_release(session));
    }
    super.close();
  }
}

class _FtpStat {
  const _FtpStat(this.size, this.revision);
  final int size;
  final String? revision;
}

class _FtpReply {
  const _FtpReply(this.code, this.message);
  final int code;
  final String message;
}

class _FtpSession {
  _FtpSession({required this.host, required this.port, required this.tls, required this.implicitTls});

  final String host;
  final int port;
  final bool tls;
  final bool implicitTls;
  Socket? _control;
  Socket? _data;
  StreamIterator<String>? _lines;
  bool _closed = false;

  Future<void> open(Map<String, String> credentials) async {
    Socket control;
    try {
      control = implicitTls
          ? await SecureSocket.connect(host, port, timeout: const Duration(seconds: 20))
          : await Socket.connect(host, port, timeout: const Duration(seconds: 20));
    } catch (_) {
      throw const SourceException(SourceFailure.unavailable);
    }
    _control = control;
    _lines = _lineReader(control);
    var greeting = await _reply();
    if (greeting.code == 120) greeting = await _reply();
    if (greeting.code != 220) throw failure(greeting);

    if (tls && !implicitTls) {
      final startTls = await command('AUTH TLS');
      if (startTls.code != 234) throw failure(startTls);
      await _lines?.cancel();
      final secure = await SecureSocket.secure(control, host: host);
      _control = secure;
      _lines = _lineReader(secure);
    }
    if (tls) {
      final pbsz = await command('PBSZ 0');
      if (pbsz.code != 200) throw failure(pbsz);
      final prot = await command('PROT P');
      if (prot.code != 200) throw failure(prot);
    }

    final username = credentials['username']?.trim().isNotEmpty == true
        ? credentials['username']!.trim()
        : 'anonymous';
    final password = credentials['password'] ?? (username == 'anonymous' ? 'anonymous@' : '');
    final user = await command('USER $username');
    if (user.code == 331 || user.code == 332) {
      final pass = await command('PASS $password');
      if (pass.code != 230 && pass.code != 202) throw failure(pass);
    } else if (user.code != 230) {
      throw failure(user);
    }
    final binary = await command('TYPE I');
    if (binary.code != 200) throw failure(binary);
  }

  StreamIterator<String> _lineReader(Socket socket) =>
      StreamIterator<String>(socket.transform(utf8.decoder).transform(const LineSplitter()));

  Future<String> _nextLine() async {
    final lines = _lines;
    if (lines == null || !await lines.moveNext().timeout(const Duration(seconds: 30))) {
      throw const SourceException(SourceFailure.unavailable);
    }
    final line = lines.current;
    if (line.length > 8192) throw const SourceException(SourceFailure.invalidData);
    return line;
  }

  Future<_FtpReply> _reply() async {
    final first = await _nextLine();
    if (first.length < 3) throw const SourceException(SourceFailure.invalidData);
    final code = int.tryParse(first.substring(0, 3));
    if (code == null) throw const SourceException(SourceFailure.invalidData);
    final lines = <String>[first];
    if (first.length >= 4 && first[3] == '-') {
      final ending = '$code ';
      for (var i = 0; i < 256; i++) {
        final line = await _nextLine();
        lines.add(line);
        if (line.startsWith(ending)) break;
        if (i == 255) throw const SourceException(SourceFailure.invalidData);
      }
    }
    return _FtpReply(code, lines.join('\n'));
  }

  Future<_FtpReply> command(String value) async {
    if (_closed || value.contains('\r') || value.contains('\n') || value.contains('\u0000')) {
      throw const SourceException(SourceFailure.cancelled);
    }
    final socket = _control;
    if (socket == null) throw const SourceException(SourceFailure.cancelled);
    socket.add(utf8.encode('$value\r\n'));
    await socket.flush();
    return _reply();
  }

  SourceException failure(_FtpReply reply) => SourceException(
    switch (reply.code) {
      530 || 532 => SourceFailure.authentication,
      550 || 553 => SourceFailure.permission,
      500 || 501 || 502 || 504 => SourceFailure.unsupported,
      421 || 425 || 426 => SourceFailure.unavailable,
      _ => SourceFailure.unavailable,
    },
    status: reply.code,
  );

  Future<Socket> _passiveSocket() async {
    final extended = await command('EPSV');
    int? portNumber;
    if (extended.code == 229) {
      final match = RegExp(r'\((.)(?:\1){2}(\d+)\1\)').firstMatch(extended.message);
      portNumber = match == null ? null : int.tryParse(match[2]!);
    }
    if (portNumber == null) {
      final passive = await command('PASV');
      if (passive.code != 227) throw failure(passive);
      final match = RegExp(r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)').firstMatch(passive.message);
      if (match == null) throw const SourceException(SourceFailure.invalidData);
      final p1 = int.parse(match[5]!);
      final p2 = int.parse(match[6]!);
      portNumber = p1 * 256 + p2;
    }
    if (portNumber < 1 || portNumber > 65535) throw const SourceException(SourceFailure.invalidData);
    try {
      final raw = await Socket.connect(host, portNumber, timeout: const Duration(seconds: 20));
      return tls ? await SecureSocket.secure(raw, host: host) : raw;
    } catch (_) {
      throw const SourceException(SourceFailure.unavailable);
    }
  }

  Future<Socket> openData(String commandText) async {
    final data = await _passiveSocket();
    _data = data;
    final reply = await command(commandText);
    if (reply.code != 125 && reply.code != 150) {
      data.destroy();
      _data = null;
      throw failure(reply);
    }
    return data;
  }

  Future<String> readTransfer(String commandText, {required int limit}) async {
    final data = await openData(commandText);
    final bytes = BytesBuilder(copy: false);
    var total = 0;
    try {
      await for (final chunk in data.timeout(const Duration(seconds: 45))) {
        total += chunk.length;
        if (total > limit) throw const SourceException(SourceFailure.invalidData);
        bytes.add(chunk);
      }
      final finalReply = await _reply();
      if (finalReply.code != 226 && finalReply.code != 250) throw failure(finalReply);
      return utf8.decode(bytes.takeBytes(), allowMalformed: true);
    } finally {
      _data = null;
      await data.close();
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _data?.destroy();
    _data = null;
    final control = _control;
    _control = null;
    await _lines?.cancel();
    _lines = null;
    control?.destroy();
  }
}
