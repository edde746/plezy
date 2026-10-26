import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'source_models.dart';

/// Bounded output guards dishonest ZIP size fields as well as zip bombs.
class _BoundedOutput extends OutputStream {
  _BoundedOutput(this.output, this.limit) : super(byteOrder: ByteOrder.littleEndian);
  final OutputFileStream output;
  final int limit;
  @override
  int get length => output.length;
  void check(int count) {
    if (count < 0 || length + count > limit) throw const SourceException(SourceFailure.invalidData);
  }

  @override
  void writeByte(int value) {
    check(1);
    output.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    check(length ?? bytes.length);
    output.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    while (!stream.isEOS) {
      writeBytes(stream.readBytes(min(65536, stream.length)).toUint8List());
    }
  }

  @override
  Uint8List subset(int start, [int? end]) => output.subset(start, end);
  @override
  void clear() => output.clear();
  @override
  void flush() => output.flush();
  @override
  Future<void> close() => output.close();
  @override
  void closeSync() => output.closeSync();
}

/// Only files from a validated archive are exposed; no arbitrary path access.
class PublicationArchive {
  PublicationArchive._(this.directory, this.files, this.comic);
  final Directory directory;
  final Map<String, int> files;
  final bool comic;
  static String safePath(String value) {
    if (value.isEmpty ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.contains(':') ||
        value.contains('\x00') ||
        value.split('/').any((s) => s == '..' || s == '.')) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return value;
  }

  static Future<PublicationArchive> open(File file, Directory temporary, {bool comic = false}) async {
    final folder = await temporary.createTemp('publication-');
    try {
      final files = await Isolate.run(() => extract(file.path, folder.path, comic: comic));
      return PublicationArchive._(folder, files, comic);
    } catch (error) {
      await folder.delete(recursive: true);
      if (error is SourceException) rethrow;
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  static Map<String, int> extract(String path, String destination, {bool comic = false}) {
    final input = InputFileStream(path);
    try {
      // Read the central directory before the decoder materializes symlinks.
      final directory = ZipDirectory()..read(input);
      if (directory.fileHeaders.isEmpty || directory.fileHeaders.length > 10000) {
        throw const SourceException(SourceFailure.invalidData);
      }
      var total = 0;
      final names = <String>{};
      for (final header in directory.fileHeaders) {
        final file = header.file!;
        final name = safePath(file.filename);
        if (safePath(header.filename) != name ||
            !names.add(name) ||
            file.uncompressedSize > 256 * 1024 * 1024 ||
            file.uncompressedSize < 0 ||
            ((header.externalFileAttributes >> 16) & 0xf000) == 0xa000) {
          throw const SourceException(SourceFailure.invalidData);
        }
        total += file.uncompressedSize;
        if (total > 1024 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
      }
      final archive = ZipDecoder().decodeStream(input);
      final files = <String, int>{};
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = safePath(entry.name);
        if (entry.isSymbolicLink) throw const SourceException(SourceFailure.invalidData);
        final file = File(p.joinAll([destination, ...name.split('/')]));
        file.parent.createSync(recursive: true);
        final output = _BoundedOutput(OutputFileStream(file.path), entry.size);
        try {
          entry.writeContent(output);
          if (output.length != entry.size) throw const SourceException(SourceFailure.invalidData);
        } finally {
          output.closeSync();
        }
        files[name] = entry.size;
      }
      if (!comic && !files.containsKey('META-INF/container.xml')) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final encryption = File(p.join(destination, 'META-INF', 'encryption.xml'));
      if (encryption.existsSync()) {
        if (encryption.lengthSync() > 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
        final xml = XmlDocument.parse(encryption.readAsStringSync());
        for (final e in xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'EncryptionMethod')) {
          if (!const {
            'http://www.idpf.org/2008/embedding',
            'http://ns.adobe.com/pdf/enc#RC',
          }.contains(e.getAttribute('Algorithm'))) {
            throw const SourceException(SourceFailure.unsupported);
          }
        }
      }
      return files;
    } finally {
      input.closeSync();
    }
  }

  Future<void> close() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

/// A session capability, independent of every provider's token or cookies.
/// CSP is inherited by the reader's blob frames. Only nonce-bearing engine
/// scripts execute, including on WebKit where iframe sandboxing alone fails.
class PublicationServer {
  PublicationServer(this.archive, {required this.valid, this.onEvent});
  final PublicationArchive archive;
  final bool Function() valid;
  final Future<void> Function(List<dynamic>)? onEvent;
  WebSocket? _browser;
  int _sequence = 0;
  final _commands = <int, Completer<dynamic>>{};
  Future<dynamic> execute(String method, Object? argument) async {
    if (_browser == null || !valid() || _commands.length >= 16) throw const SourceException(SourceFailure.unavailable);
    final id = ++_sequence, result = Completer<dynamic>();
    _commands[id] = result;
    try {
      _browser!.add(jsonEncode({'id': id, 'method': method, 'argument': argument}));
      return await result.future.timeout(const Duration(seconds: 30));
    } finally {
      _commands.remove(id);
    }
  }

  HttpServer? _server;
  late Uri origin;
  late String _secret;
  late String _nonce;
  static const assets = {
    'view.js',
    'epub.js',
    'epubcfi.js',
    'paginator.js',
    'fixed-layout.js',
    'progress.js',
    'overlayer.js',
    'text-walker.js',
    'search.js',
    'tts.js',
    'comic-book.js',
  };
  String get policy =>
      "default-src 'none'; script-src 'nonce-$_nonce' 'strict-dynamic'; style-src 'self' blob: 'unsafe-inline'; img-src 'self' blob: data:; font-src 'self' blob: data:; media-src 'self' blob:; connect-src 'self' blob: ws://${origin.authority}; frame-src blob:; object-src 'none'; base-uri 'none'; form-action 'none'";
  Future<Uri> start() async {
    final random = Random.secure();
    _secret = base64Url.encode(List.generate(32, (_) => random.nextInt(256))).replaceAll('=', '');
    _nonce = base64.encode(List.generate(24, (_) => random.nextInt(256)));
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/');
    _server!.listen((request) {
      unawaited(_serve(request));
    });
    return origin.resolve('index.html');
  }

  Future<void> _serve(HttpRequest request) async {
    final response = request.response;
    var upgraded = false;
    try {
      response.headers.set('Cache-Control', 'no-store');
      response.headers.set('X-Content-Type-Options', 'nosniff');
      response.headers.set('Referrer-Policy', 'no-referrer');
      response.headers.set('Content-Security-Policy', policy);
      final browserOrigin = request.headers.value('origin');
      if (!valid() ||
          request.headers.value('host') != origin.authority ||
          (browserOrigin != null && browserOrigin != '${origin.scheme}://${origin.authority}') ||
          !const {'GET', 'HEAD'}.contains(request.method) ||
          !request.uri.path.startsWith('/$_secret/')) {
        response.statusCode = 403;
        return;
      }
      final route = request.uri.path.substring(_secret.length + 2);
      if (route == 'bridge' && onEvent != null && WebSocketTransformer.isUpgradeRequest(request)) {
        if (browserOrigin != '${origin.scheme}://${origin.authority}' || _browser != null) {
          response.statusCode = 403;
          return;
        }
        final socket = await WebSocketTransformer.upgrade(request);
        upgraded = true;
        _browser = socket;
        socket.listen(
          (message) async {
            try {
              if (!valid() || message is! String || message.length > 6 * 1024 * 1024) {
                await socket.close();
                return;
              }
              final value = sourceMap(jsonDecode(message));
              if (value.containsKey('reply')) {
                final command = _commands.remove(sourceInt(value['reply']));
                if (command != null && !command.isCompleted) {
                  value['error'] == true
                      ? command.completeError(const SourceException(SourceFailure.invalidData))
                      : command.complete(value['value']);
                }
              } else {
                await onEvent!([value]);
              }
            } catch (_) {
              if (socket.readyState == WebSocket.open) socket.add(jsonEncode({'error': true}));
            }
          },
          onError: (Object _) {
            unawaited(socket.close());
          },
          onDone: () {
            if (_browser == socket) _browser = null;
            for (final command in _commands.values) {
              if (!command.isCompleted) command.completeError(const SourceException(SourceFailure.cancelled));
            }
            _commands.clear();
          },
        );
        return;
      }
      if (route == 'index.html' ||
          route == 'reader.js' ||
          route == 'browser.js' ||
          route.startsWith('foliate/') && assets.contains(route.substring(8))) {
        var value = await rootBundle.loadString('assets/reader/$route');
        if (route == 'index.html') value = value.replaceAll('READER_NONCE', _nonce);
        response.headers.contentType = ContentType(
          route.endsWith('.js') ? 'application' : 'text',
          route.endsWith('.js') ? 'javascript' : 'html',
          charset: 'utf-8',
        );
        if (request.method != 'HEAD') response.write(value);
      } else if (route == 'material-symbols.ttf') {
        final font = await rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf');
        response.headers.contentType = ContentType('font', 'ttf');
        response.contentLength = font.lengthInBytes;
        if (request.method != 'HEAD') response.add(font.buffer.asUint8List(font.offsetInBytes, font.lengthInBytes));
      } else if (route == 'manifest.json') {
        response.headers.contentType = ContentType.json;
        if (request.method != 'HEAD') response.write(jsonEncode({'files': archive.files, 'comic': archive.comic}));
      } else if (route.startsWith('book/')) {
        final name = PublicationArchive.safePath(Uri.decodeComponent(route.substring(5)));
        final size = archive.files[name];
        if (size == null) {
          response.statusCode = 404;
          return;
        }
        final file = File(p.joinAll([archive.directory.path, ...name.split('/')]));
        response.headers.set('Content-Type', lookupMimeType(name) ?? 'application/octet-stream');
        response.headers.set('Accept-Ranges', 'bytes');
        var start = 0, end = size;
        final range = request.headers.value('range');
        if (range != null) {
          final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(range);
          if (match == null) {
            response.statusCode = 416;
            return;
          }
          start = int.parse(match[1]!);
          end = match[2]!.isEmpty ? size : min(size, int.parse(match[2]!) + 1);
          if (start < 0 || start >= end) {
            response.statusCode = 416;
            return;
          }
          response.statusCode = 206;
          response.headers.set('Content-Range', 'bytes $start-${end - 1}/$size');
        }
        response.contentLength = end - start;
        if (request.method != 'HEAD') await response.addStream(file.openRead(start, end));
      } else {
        response.statusCode = 404;
      }
    } catch (_) {
      response.statusCode = 400;
    } finally {
      if (!upgraded) await response.close();
    }
  }

  Future<void> close() async {
    await _browser?.close();
    _browser = null;
    await _server?.close(force: true);
    await archive.close();
  }
}
