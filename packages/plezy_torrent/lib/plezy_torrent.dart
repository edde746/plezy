import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// One playback-owned native session. Closing it stops peer traffic, closes
/// active HTTP requests and removes its private spool. No seeding after play.
class TorrentLease {
  TorrentLease._(this.uri, this.fileName, this.size, this._control, this._messages, this._closed);
  final Uri uri;
  final String fileName;
  final int size;
  final SendPort _control;
  final ReceivePort _messages;
  final Future<void> _closed;
  Future<void>? _closing;
  bool get isClosed => _closing != null;

  Future<void> close() => _closing ??= () async {
    _control.send('close');
    await _closed;
    _messages.close();
  }();

  static bool get available {
    try {
      return _Bindings().version() == 1;
    } on Object {
      return false;
    }
  }

  static Future<TorrentLease> open({
    required String infoHash,
    required String cacheDirectory,
    int? fileIndex,
    List<String> trackers = const [],
    int quotaBytes = 4 * 1024 * 1024 * 1024,
    int uploadBytesPerSecond = 256 * 1024,
    bool Function()? shouldCancel,
  }) async {
    if (!RegExp(r'^[a-fA-F0-9]{40}$').hasMatch(infoHash) || (fileIndex != null && fileIndex < 0)) {
      throw const FormatException('Invalid torrent identity');
    }
    final messages = ReceivePort();
    final opened = Completer<TorrentLease>();
    final closed = Completer<void>();
    SendPort? control;
    Timer? cancellation;
    messages.listen((dynamic message) {
      if (message is SendPort) {
        control = message;
      } else if (message is List && message.first == 'ready') {
        opened.complete(
          TorrentLease._(
            Uri.parse(message[1] as String),
            message[2] as String,
            message[3] as int,
            control!,
            messages,
            closed.future,
          ),
        );
      } else if (message == 'closed' || message == null) {
        if (!opened.isCompleted) opened.completeError(StateError('Torrent preparation failed'));
        if (!closed.isCompleted) closed.complete();
        messages.close();
      } else if (message is List && message.first == 'error') {
        if (!opened.isCompleted) opened.completeError(StateError('Torrent preparation failed'));
      }
    });
    try {
      await Isolate.spawn(
        _serve,
        [
          messages.sendPort,
          infoHash.toLowerCase(),
          cacheDirectory,
          fileIndex ?? -1,
          quotaBytes,
          uploadBytesPerSecond,
          trackers.take(32).toList(),
        ],
        onExit: messages.sendPort,
        errorsAreFatal: true,
      );
      if (shouldCancel != null) {
        cancellation = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!opened.isCompleted && shouldCancel()) control?.send('close');
        });
      }
      return await opened.future.timeout(const Duration(minutes: 2));
    } on Object {
      control?.send('close');
      messages.close();
      rethrow;
    } finally {
      cancellation?.cancel();
    }
  }
}

/// Single HTTP range, inclusive. Multipart ranges are rejected rather than
/// accidentally returning the wrong bytes to a demuxer.
({int start, int end}) torrentRange(String? range, int size) {
  if (size <= 0) throw const FormatException('Empty media');
  if (range == null) return (start: 0, end: size - 1);
  final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range);
  if (match == null || (match[1]!.isEmpty && match[2]!.isEmpty)) throw const FormatException('Invalid range');
  if (match[1]!.isEmpty) {
    final count = int.tryParse(match[2]!);
    if (count == null || count <= 0) throw const FormatException('Invalid suffix');
    return (start: max(0, size - count), end: size - 1);
  }
  final start = int.tryParse(match[1]!);
  final end = match[2]!.isEmpty ? size - 1 : int.tryParse(match[2]!);
  if (start == null || end == null || start >= size || start > end) throw const FormatException('Unsatisfiable range');
  return (start: start, end: min(end, size - 1));
}

Future<void> _serve(List<Object> args) async {
  final reply = args[0] as SendPort;
  final control = ReceivePort();
  reply.send(control.sendPort);
  var stopped = false;
  control.listen((_) => stopped = true);
  final token = base64UrlEncode(List<int>.generate(24, (_) => Random.secure().nextInt(256))).replaceAll('=', '');
  final directory = Directory(p.join(args[2] as String, token));
  HttpServer? server;
  Pointer<Void> handle = nullptr;
  _Bindings? native;
  final requests = <Future<void>>{};
  try {
    await directory.create(recursive: true);
    native = _Bindings();
    if (native.version() != 1) throw StateError('Incompatible torrent engine');
    final trackers = (args[6] as List<String>).where((value) {
      final uri = Uri.tryParse(value);
      return uri != null &&
          const {'udp', 'http'}.contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          !value.contains('\n');
    });
    final trackerQuery = trackers.map((tracker) => '&tr=${Uri.encodeComponent(tracker)}').join();
    final magnet = 'magnet:?xt=urn:btih:${args[1]}$trackerQuery'.toNativeUtf8();
    final path = directory.path.toNativeUtf8();
    try {
      handle = native.open(magnet, path, args[3] as int, args[4] as int, args[5] as int);
    } finally {
      malloc.free(magnet);
      malloc.free(path);
    }
    if (handle == nullptr) throw StateError('Cannot start torrent');
    var size = -2;
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (!stopped && size == -2 && DateTime.now().isBefore(deadline)) {
      size = native.size(handle);
      if (size == -2) await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (size <= 0 || stopped) throw StateError('Torrent metadata unavailable');
    final nameBuffer = calloc<Uint8>(4096);
    late final String name;
    try {
      if (native.name(handle, nameBuffer.cast(), 4096) <= 0) throw StateError('Invalid torrent name');
      name = nameBuffer.cast<Utf8>().toDartString();
    } finally {
      calloc.free(nameBuffer);
    }
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: false);
    reply.send(['ready', 'http://127.0.0.1:${server.port}/$token/media', name, size]);
    final engine = native;
    Future<void> serve(HttpRequest request) async {
      final response = request.response;
      Pointer<Uint8> buffer = nullptr;
      try {
        if (request.uri.path != '/$token/media' || request.uri.hasQuery) {
          response.statusCode = 404;
          return;
        }
        if (request.method != 'GET' && request.method != 'HEAD') {
          response.statusCode = 405;
          return;
        }
        if (requests.length >= 4 || stopped) {
          response.statusCode = 503;
          return;
        }
        final raw = request.headers.value(HttpHeaders.rangeHeader);
        late final ({int start, int end}) range;
        try {
          range = torrentRange(raw, size);
        } on FormatException {
          response.statusCode = 416;
          response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$size');
          return;
        }
        response.statusCode = raw == null ? 200 : 206;
        response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
        response.headers.contentType = ContentType.binary;
        response.contentLength = range.end - range.start + 1;
        if (raw != null) {
          response.headers.set(HttpHeaders.contentRangeHeader, 'bytes ${range.start}-${range.end}/$size');
        }
        if (request.method == 'HEAD') return;
        buffer = calloc<Uint8>(64 * 1024);
        var offset = range.start;
        var stall = DateTime.now();
        while (!stopped && offset <= range.end) {
          final count = engine.read(handle, offset, buffer, min(64 * 1024, range.end - offset + 1));
          if (count == -2) {
            if (DateTime.now().difference(stall) > const Duration(seconds: 90)) throw StateError('Peer timeout');
            await Future<void>.delayed(const Duration(milliseconds: 100));
            continue;
          }
          if (count <= 0) throw StateError('Torrent read failed');
          response.add(buffer.asTypedList(count).toList(growable: false));
          await response.flush();
          offset += count;
          stall = DateTime.now();
        }
      } on Object {
        // Neither peer names nor capability URLs enter app/native logs.
      } finally {
        if (buffer != nullptr) calloc.free(buffer);
        try {
          await response.close();
        } on Object {
          /* disconnected player */
        }
      }
    }

    server.listen((request) {
      late Future<void> task;
      task = serve(request).whenComplete(() => requests.remove(task));
      requests.add(task);
    });
    while (!stopped) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  } on Object {
    reply.send(['error']);
  } finally {
    stopped = true;
    await server?.close(force: true);
    await Future.wait(requests.toList());
    if (handle != nullptr) native?.close(handle);
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on Object {
      /* next-launch cleanup */
    }
    control.close();
    reply.send('closed');
  }
}

class _Bindings {
  _Bindings()
    : library = Platform.isIOS || Platform.isMacOS
          ? DynamicLibrary.open('PlezyTorrent.framework/PlezyTorrent')
          : DynamicLibrary.open(Platform.isWindows ? 'plezy_torrent.dll' : 'libplezy_torrent.so');
  final DynamicLibrary library;
  late final version = library.lookupFunction<Int32 Function(), int Function()>('pt_abi_version');
  late final open = library
      .lookupFunction<
        Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>, Int32, Int64, Int32),
        Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>, int, int, int)
      >('pt_open');
  late final size = library.lookupFunction<Int64 Function(Pointer<Void>), int Function(Pointer<Void>)>('pt_size');
  late final name = library
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32),
        int Function(Pointer<Void>, Pointer<Utf8>, int)
      >('pt_name');
  late final read = library
      .lookupFunction<
        Int32 Function(Pointer<Void>, Int64, Pointer<Uint8>, Int32),
        int Function(Pointer<Void>, int, Pointer<Uint8>, int)
      >('pt_read');
  late final close = library.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('pt_close');
}
