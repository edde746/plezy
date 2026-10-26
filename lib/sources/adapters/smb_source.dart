import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dart_smb2/dart_smb2.dart';
import 'package:mime/mime.dart';

import '../source_models.dart';
import '../source_transport.dart';
import '../video_nfo.dart';

class SmbSourceAdapter extends SourceAdapter {
  SmbSourceAdapter(super.source, super.transport, this.credentials);

  final Future<Map<String, String>> Function() credentials;
  Future<Smb2Pool>? _pool;
  bool _closed = false;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(rangeRequests: true);

  Future<Smb2Pool> _connection() {
    if (_closed) return Future.error(const SourceException(SourceFailure.cancelled));
    final current = _pool;
    if (current != null) return current;
    final opening = _open();
    _pool = opening;
    return opening.catchError((Object error) {
      if (identical(_pool, opening)) _pool = null;
      throw _translate(error);
    });
  }

  Future<Smb2Pool> _open() async {
    try {
      final endpoint = validateSmbSourceEndpoint(source.endpoint);
      final share = endpoint.pathSegments.where((segment) => segment.isNotEmpty).single;
      final values = await credentials();
      var username = values['username']?.trim();
      var domain = values['domain']?.trim();
      if (username?.isNotEmpty == true && domain?.isNotEmpty != true) {
        final separator = username!.indexOf('\\');
        if (separator > 0) {
          domain = username.substring(0, separator);
          username = username.substring(separator + 1);
        }
      }
      return await Smb2Pool.connect(
        host: endpoint.host,
        share: share,
        user: username?.isEmpty == true ? null : username,
        password: username?.isEmpty == true ? null : values['password'] ?? '',
        domain: domain?.isEmpty == true ? null : domain,
        workers: 2,
        seal: source.options['encryptSmb'] == 'true',
        version: source.options['encryptSmb'] == 'true' ? Smb2Version.any3 : Smb2Version.any,
        timeout: const Duration(seconds: 20),
      );
    } on Smb2Exception catch (error) {
      throw _translate(error);
    }
  }

  String _cleanPath(String value) {
    final segments = value.replaceAll('\\', '/').split('/').where((part) => part.isNotEmpty).toList();
    if (segments.any((part) => part == '.' || part == '..' || part.contains('\u0000'))) {
      throw const SourceException(SourceFailure.permission);
    }
    return segments.join('/');
  }

  String _sourcePath(String value) {
    final path = _cleanPath(value);
    final root = _cleanPath(source.root);
    if (root.isNotEmpty && path != root && !path.startsWith('$root/')) {
      throw const SourceException(SourceFailure.permission);
    }
    return path;
  }

  String _join(String parent, String name) {
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains('\\') ||
        name.contains('\u0000')) {
      throw const SourceException(SourceFailure.permission);
    }
    return parent.isEmpty ? name : '$parent/$name';
  }

  String _revision(Smb2Stat stat) => '${stat.size}:${stat.modified.microsecondsSinceEpoch}';

  Future<List<int>?> _readBounded(Smb2Pool pool, String path, int size, int limit) async {
    if (size < 0 || size > limit) return null;
    final bytes = await pool.withFile(
      path,
      (file) => file.read(offset: 0, length: size),
      knownSize: size,
    );
    return bytes.length == size ? bytes : null;
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    try {
      final directory = _sourcePath(parent ?? source.root);
      final rows = await (await _connection()).listDirectory(directory);
      final entries = <SourceEntry>[];
      for (final row in rows) {
        if (row.name.startsWith('.') || row.stat.isHidden) continue;
        if (!row.isDirectory && !row.isFile) continue;
        final id = _join(directory, row.name);
        final kind = row.isDirectory
            ? SourceItemKind.folder
            : classifySourceFile(row.name, lookupMimeType(row.name) ?? '');
        if (kind == SourceItemKind.unknown) continue;
        if (query != null && !row.name.toLowerCase().contains(query.toLowerCase())) continue;
        final mimeType = row.isDirectory ? '' : lookupMimeType(row.name) ?? '';
        entries.add(
          SourceEntry(
            sourceId: source.id,
            id: id,
            title: row.name,
            kind: kind,
            parentId: directory,
            files: row.isDirectory
                ? const []
                : [
                    PublicationFile(
                      id: id,
                      name: row.name,
                      mimeType: mimeType,
                      size: row.size,
                      revision: _revision(row.stat),
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
    } on Smb2Exception catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async {
    if (entry.kind != SourceItemKind.video) return entry;
    try {
      final path = _sourcePath(entry.id);
      final slash = path.lastIndexOf('/');
      final directory = slash < 0 ? '' : path.substring(0, slash);
      final filename = slash < 0 ? path : path.substring(slash + 1);
      final dot = filename.lastIndexOf('.');
      final stem = dot > 0 ? filename.substring(0, dot) : filename;
      final pool = await _connection();
      final rows = await pool.listDirectory(directory);
      final siblings = {for (final row in rows) row.name.toLowerCase(): row};
      final sidecarNames = ['${stem.toLowerCase()}.nfo', '${filename.toLowerCase()}.nfo'];
      VideoNfoMetadata? metadata;
      for (final name in sidecarNames) {
        final row = siblings[name];
        if (row == null || !row.isFile || row.size > 1024 * 1024) continue;
        final sidecarPath = _join(directory, row.name);
        final bytes = await _readBounded(pool, sidecarPath, row.size, 1024 * 1024);
        if (bytes == null) continue;
        metadata = parseVideoNfo(utf8.decode(bytes, allowMalformed: true));
        if (metadata != null) break;
      }

      String? poster;
      final posterNames = [
        '${stem.toLowerCase()}-poster.jpg',
        '${stem.toLowerCase()}-poster.png',
        '${stem.toLowerCase()}.jpg',
        '${stem.toLowerCase()}.png',
        'poster.jpg',
        'poster.png',
        'cover.jpg',
        'cover.png',
        'folder.jpg',
        'folder.png',
      ];
      for (final name in posterNames) {
        final row = siblings[name];
        if (row == null || !row.isFile || row.size <= 0 || row.size > 8 * 1024 * 1024) continue;
        poster = _join(directory, row.name);
        break;
      }

      var hydrated = metadata?.applyTo(entry) ?? entry;
      if (poster != null) hydrated = hydrated.copyWith(coverId: poster);
      return hydrated;
    } on Smb2Exception {
      // Video metadata is an enhancement; a NAS hiccup must not hide a playable file.
      return entry;
    }
  }

  @override
  Future<List<int>?> coverBytes(SourceEntry entry) async {
    final cover = entry.coverId;
    if (cover == null) return null;
    try {
      final path = _sourcePath(cover);
      final pool = await _connection();
      final stat = await pool.stat(path);
      if (!stat.isFile || stat.size <= 0 || stat.size > 8 * 1024 * 1024) return null;
      return _readBounded(pool, path, stat.size, 8 * 1024 * 1024);
    } on Smb2Exception catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async => throw const SourceException(SourceFailure.unsupported);

  @override
  Future<int?> contentSize(PublicationFile file) async {
    if (file.size != null) return file.size;
    try {
      return (await (await _connection()).stat(_sourcePath(file.id))).size;
    } on Smb2Exception catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<SourceByteStream?> openContent(
    PublicationFile file, {
    required int offset,
    required int length,
  }) async {
    final path = _sourcePath(file.id);
    try {
      final pool = await _connection();
      final stat = await pool.stat(path);
      if (!stat.isFile) throw const SourceException(SourceFailure.invalidData);
      if (file.revision != null && file.revision != _revision(stat)) {
        throw const SourceException(SourceFailure.conflict);
      }
      if (file.size != null && file.size != stat.size) {
        throw const SourceException(SourceFailure.conflict);
      }
      if (offset < 0 || length < 0 || offset > stat.size || length > stat.size - offset) {
        throw const SourceException(SourceFailure.invalidData);
      }
      return SourceByteStream(
        stream: _readRange(pool, path, stat.size, offset, length),
        size: stat.size,
        offset: offset,
        length: length,
      );
    } on Smb2Exception catch (error) {
      throw _translate(error);
    }
  }

  Stream<List<int>> _readRange(Smb2Pool pool, String path, int size, int offset, int length) {
    final token = Smb2CancelToken();
    late final StreamController<List<int>> controller;
    Future<void>? pumping;
    Completer<void>? resume;
    var cancelled = false;
    controller = StreamController<List<int>>(
      onListen: () {
        pumping = pool
            .withFile(
              path,
              (file) async {
                var position = offset;
                final end = offset + length;
                while (position < end && !cancelled) {
                  final requested = math.min(1024 * 1024, end - position).toInt();
                  final bytes = await file.read(offset: position, length: requested);
                  if (bytes.isEmpty || bytes.length > end - position) {
                    throw const SourceException(SourceFailure.invalidData);
                  }
                  position += bytes.length;
                  if (!cancelled) {
                    controller.add(bytes);
                    if (controller.isPaused) {
                      final waiting = Completer<void>();
                      resume = waiting;
                      await waiting.future;
                      resume = null;
                    }
                  }
                }
              },
              knownSize: size,
              cancelToken: token,
            )
            .then<void>(
              (_) async {
                if (!cancelled && !controller.isClosed) await controller.close();
              },
              onError: (Object error, StackTrace stack) async {
                if (!cancelled && !controller.isClosed) {
                  controller.addError(_translate(error), stack);
                  await controller.close();
                }
              },
            );
      },
      onResume: () {
        final waiting = resume;
        resume = null;
        if (waiting != null && !waiting.isCompleted) waiting.complete();
      },
      onCancel: () async {
        cancelled = true;
        token.cancel();
        final waiting = resume;
        resume = null;
        if (waiting != null && !waiting.isCompleted) waiting.complete();
        try {
          await pumping;
        } catch (_) {}
      },
    );
    return controller.stream;
  }

  SourceException _translate(Object error) {
    if (error is SourceException) return error;
    if (error is Smb2Exception) {
      return SourceException(switch (error.type.name) {
        'auth' => SourceFailure.authentication,
        'accessDenied' => SourceFailure.permission,
        'cancelled' => SourceFailure.cancelled,
        'notSupported' || 'invalidParam' => SourceFailure.unsupported,
        'notFound' || 'notADirectory' || 'isADirectory' => SourceFailure.unavailable,
        _ => SourceFailure.unavailable,
      });
    }
    return const SourceException(SourceFailure.unavailable);
  }

  @override
  void close() {
    _closed = true;
    final pool = _pool;
    _pool = null;
    if (pool != null) {
      unawaited(pool.then<void>((connection) => connection.disconnect(), onError: (Object _) {}));
    }
    super.close();
  }
}
