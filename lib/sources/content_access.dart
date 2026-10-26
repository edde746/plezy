import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import 'source_database.dart';
import 'source_models.dart';
import 'source_oauth.dart';
import 'source_transport.dart';

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
  final SourceRepository repository;
  final Directory directory;
  final Map<String, Future<File>> _pending = {};
  final Map<String, TransferCancellation> _cancellations = {};
  String key(String sourceId, PublicationFile file) => sourceKey(sourceId, file.id);
  Future<File?> local(String profile, String sourceId, PublicationFile file) async {
    final record = await repository.download(profile, key(sourceId, file));
    if (record == null || record['complete'] != 1 || record['fingerprint'] != file.fingerprint) return null;
    final value = File(record['path'] as String);
    final expected = p.join(directory.path, sourceDigest(profile));
    if (!p.isWithin(expected, value.path)) throw const SourceException(SourceFailure.permission);
    if (!await value.exists() || await value.length() != record['bytes']) return null;
    return value;
  }

  Future<File> download(
    String profile,
    SourceAdapter adapter,
    PublicationFile file, {
    void Function(int, int?)? onProgress,
  }) {
    final transferKey = sourceKey(profile, key(adapter.source.id, file));
    return _pending.putIfAbsent(
      transferKey,
      () => _download(profile, adapter, file, transferKey, onProgress).whenComplete(() {
        _pending.remove(transferKey);
        _cancellations.remove(transferKey);
      }),
    );
  }

  Future<File> _download(
    String profile,
    SourceAdapter adapter,
    PublicationFile file,
    String transferKey,
    void Function(int, int?)? onProgress,
  ) async {
    final cancel = TransferCancellation();
    _cancellations[transferKey] = cancel;
    final cached = await local(profile, adapter.source.id, file);
    cancel.check();
    if (cached != null) return cached;
    final folder = Directory(p.join(directory.path, sourceDigest(profile)));
    await folder.create(recursive: true);
    cancel.check();
    final extension = p.extension(file.name).toLowerCase();
    final target = File(
      p.join(
        folder.path,
        '${sourceDigest(key(adapter.source.id, file))}-${file.fingerprint}${RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension) ? extension : ''}',
      ),
    );
    final partial = File('${target.path}.partial');
    final validatorFile = File('${target.path}.validator');
    var offset = await partial.exists() ? await partial.length() : 0;
    final validator = await validatorFile.exists() ? await validatorFile.readAsString() : null;
    // A byte range is safe to append only when the server can condition it on
    // the exact representation previously received. Otherwise restart.
    if (offset > 0 && validator == null) offset = 0;
    var expectedSize = file.size ?? await adapter.contentSize(file);
    final directStream = await adapter.openContent(file, offset: 0, length: expectedSize ?? 0);
    cancel.check();
    if (directStream != null) {
      expectedSize = directStream.size;
      if (directStream.offset != 0 || directStream.length != directStream.size) {
        throw const SourceException(SourceFailure.invalidData);
      }
      var received = 0;
      final sink = partial.openWrite();
      try {
        await sink.addStream(
          directStream.stream.timeout(const Duration(seconds: 45)).map((bytes) {
            cancel.check();
            received += bytes.length;
            if (received > directStream.size) throw const SourceException(SourceFailure.invalidData);
            onProgress?.call(received, directStream.size);
            return bytes;
          }),
        );
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (received != directStream.size) throw const SourceException(SourceFailure.invalidData);
    } else {
      var lease = await adapter.resolve(file);
      expectedSize ??= lease.size;
      cancel.check();
      if (lease.uri.scheme == 'file') {
        final input = File.fromUri(lease.uri);
        await input.copy(partial.path);
        cancel.check();
      } else {
        var response = await adapter.transport.send(
          'GET',
          lease.uri,
          headers: {...lease.headers, if (offset > 0) 'Range': 'bytes=$offset-', if (offset > 0) 'If-Range': validator!},
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
        final etag = response.headers['etag'];
        final freshValidator = etag != null && !etag.startsWith('W/') ? etag : response.headers['last-modified'];
        if (offset > 0 && freshValidator != null && validator != freshValidator) {
          await response.stream.listen(null).cancel();
          await partial.delete();
          throw const SourceException(SourceFailure.conflict);
        }
        if (response.statusCode == 206) {
          final match = RegExp(r'^bytes (\d+)-(\d+)/(\d+|\*)$')
              .firstMatch(response.headers['content-range'] ?? '');
          if (match == null ||
              int.parse(match[1]!) != offset ||
              expectedSize != null && match[3] != '$expectedSize') {
            await response.stream.listen(null).cancel();
            throw const SourceException(SourceFailure.invalidData);
          }
        }
        if (freshValidator != null) {
          await validatorFile.writeAsString(freshValidator);
        } else if (await validatorFile.exists()) {
          await validatorFile.delete();
        }
        final sink = partial.openWrite(mode: offset > 0 ? FileMode.append : FileMode.write);
        try {
          await sink.addStream(
            response.stream.timeout(const Duration(seconds: 45)).map((bytes) {
              cancel.check();
              offset += bytes.length;
              if (expectedSize != null && offset > expectedSize!) {
                throw const SourceException(SourceFailure.invalidData);
              }
              onProgress?.call(offset, expectedSize);
              return bytes;
            }),
          );
          await sink.flush();
        } finally {
          await sink.close();
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
      await repository.recordDownload(profile, key(adapter.source.id, file), target.path, file.fingerprint, size);
      cancel.check();
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
    return target;
  }

  void cancelAll() {
    for (final cancellation in _cancellations.values) {
      cancellation.cancel();
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
class SourceStreamGateway {
  SourceStreamGateway({required this.valid});
  final bool Function() valid;
  HttpServer? _server;
  final _secret = SourceOAuthService.randomSecret();
  final Map<String, ({SourceAdapter adapter, PublicationFile file})> _files = {};
  final Map<String, ContentLease> _leases = {};
  final _abort = Completer<void>();
  Future<Uri> register(SourceAdapter adapter, PublicationFile file) async {
    if (!valid()) throw const SourceException(SourceFailure.cancelled);
    if (_server == null) {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen((request) => unawaited(_serve(request)));
    }
    final id = sourceDigest(sourceKey(adapter.source.id, file.id));
    _files[id] = (adapter: adapter, file: file);
    return Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/$id');
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
        request.response.statusCode = 404;
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
        final content = await ref.adapter.openContent(
          ref.file,
          offset: requested.offset,
          length: requested.length,
        );
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

  Future<void> close() async {
    _files.clear();
    _leases.clear();
    if (!_abort.isCompleted) _abort.complete();
    await _server?.close(force: true);
    _server = null;
  }
}
).firstMatch(value);
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
class SourceStreamGateway {
  SourceStreamGateway({required this.valid});
  final bool Function() valid;
  HttpServer? _server;
  final _secret = SourceOAuthService.randomSecret();
  final Map<String, ({SourceAdapter adapter, PublicationFile file})> _files = {};
  final Map<String, ContentLease> _leases = {};
  final _abort = Completer<void>();
  Future<Uri> register(SourceAdapter adapter, PublicationFile file) async {
    if (!valid()) throw const SourceException(SourceFailure.cancelled);
    if (_server == null) {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen((request) => unawaited(_serve(request)));
    }
    final id = sourceDigest(sourceKey(adapter.source.id, file.id));
    _files[id] = (adapter: adapter, file: file);
    return Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/$id');
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
        request.response.statusCode = 404;
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null && !RegExp(r'^bytes=(\d+-\d*|-\d+)$').hasMatch(range)) {
        request.response.statusCode = 416;
        return;
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

  Future<void> close() async {
    _files.clear();
    _leases.clear();
    if (!_abort.isCompleted) _abort.complete();
    await _server?.close(force: true);
    _server = null;
  }
}
