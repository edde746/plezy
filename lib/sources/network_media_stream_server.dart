import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

class NetworkMediaStreamPolicy {
  NetworkMediaStreamPolicy._();

  static String? safeAssetName(List<String> pathSegments, String? token) {
    if (token == null || pathSegments.length != 2 || pathSegments.first != token) return null;
    final name = pathSegments.last;
    if (name == 'index.m3u8' || RegExp(r'^segment[0-9]{5}\.ts$').hasMatch(name)) return name;
    return null;
  }

  static bool allowsHostAndPeer({
    required String? hostHeader,
    required Iterable<String> advertisedAddresses,
    required int port,
    required InternetAddress? peer,
  }) {
    if (hostHeader == null || peer == null || !isPrivateIPv4(peer)) return false;
    final host = hostHeader.toLowerCase();
    final allowedHosts = <String>{
      ...advertisedAddresses.map((address) => '$address:$port'),
      '127.0.0.1:$port',
      'localhost:$port',
    };
    return allowedHosts.contains(host);
  }

  static bool isPrivateIPv4(InternetAddress address) {
    if (address.type != InternetAddressType.IPv4) return false;
    final octets = address.rawAddress;
    if (octets.length != 4) return false;
    return octets[0] == 10 ||
        octets[0] == 127 ||
        octets[0] == 192 && octets[1] == 168 ||
        octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31 ||
        octets[0] == 169 && octets[1] == 254;
  }
}

class NetworkMediaStreamServer {
  NetworkMediaStreamServer({
    this.lifetime = const Duration(minutes: 60),
    this.onProgress,
    this.onFailure,
    this.onEnded,
  });

  final Duration lifetime;
  final MediaStreamValueChanged<String>? onProgress;
  final MediaStreamValueChanged<int>? onFailure;
  final void Function()? onEnded;

  HttpServer? _server;
  Process? _process;
  Directory? _directory;
  Timer? _expiryTimer;
  DateTime? _expiresAt;
  String? _token;
  List<String> _addresses = const [];
  bool _stopping = false;
  bool _starting = false;
  int _generation = 0;

  bool get isRunning => _server != null && _process != null;
  DateTime? get expiresAt => _expiresAt;

  List<String> get urls {
    final server = _server;
    final token = _token;
    if (server == null || token == null) return const [];
    return [
      for (final address in _addresses)
        Uri(scheme: 'http', host: address, port: server.port, pathSegments: [token, 'index.m3u8']).toString(),
    ];
  }

  Future<void> start(File input) async {
    if (isRunning || _starting) throw StateError('A network stream is already active');
    _starting = true;
    final generation = ++_generation;
    Directory? directory;
    HttpServer? server;
    Process? process;
    _stopping = false;
    try {
      if (!await input.exists() || await input.length() == 0) {
        throw const FileSystemException('Input file unavailable');
      }
      _ensureCurrent(generation);
      final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
      _ensureCurrent(generation);
      final addresses = <String>{
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (_isPrivateIPv4(address)) address.address,
      }.toList()..sort();
      if (addresses.isEmpty) throw const SocketException('No private IPv4 address is available');

      directory = await Directory.systemTemp.createTemp('plezy-stream-out-');
      _ensureCurrent(generation);
      final secureRandom = Random.secure();
      final token = base64Url.encode(List<int>.generate(32, (_) => secureRandom.nextInt(256))).replaceAll('=', '');
      server = await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: false);
      _ensureCurrent(generation);
      _addresses = addresses;
      _directory = directory;
      _token = token;
      _server = server;
      server.listen(_handle, onError: (_) {});
      _expiresAt = DateTime.now().add(lifetime);
      _expiryTimer = Timer(lifetime, () => unawaited(stop()));

      final segmentTemplate = p.join(directory.path, 'segment%05d.ts');
      final playlist = p.join(directory.path, 'index.m3u8');
      process = await Process.start('ffmpeg', [
        '-hide_banner',
        '-loglevel',
        'warning',
        '-re',
        '-i',
        input.absolute.path,
        '-map',
        '0:v:0?',
        '-map',
        '0:a:0?',
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-tune',
        'zerolatency',
        '-crf',
        '24',
        '-force_key_frames',
        'expr:gte(t,n_forced*4)',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        '-b:a',
        '128k',
        '-f',
        'hls',
        '-hls_time',
        '4',
        '-hls_list_size',
        '6',
        '-hls_flags',
        'delete_segments+independent_segments',
        '-hls_segment_filename',
        segmentTemplate,
        '-progress',
        'pipe:1',
        '-nostats',
        playlist,
      ], runInShell: false);
      _process = process;
      _ensureCurrent(generation);
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (_isCurrent(generation)) onProgress?.call(line);
      }, onError: (_) {});
      unawaited(process.stderr.drain<void>());
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      var playlistReady = false;
      while (DateTime.now().isBefore(deadline)) {
        _ensureCurrent(generation);
        if (await File(playlist).exists() && await File(playlist).length() > 0) {
          playlistReady = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!playlistReady) throw const SocketException('The stream encoder did not become ready');
      _ensureCurrent(generation);
      unawaited(
        process.exitCode.then((code) async {
          if (!_isCurrent(generation)) return;
          await stop();
          if (code == 0) {
            onEnded?.call();
          } else {
            onFailure?.call(code);
          }
        }),
      );
    } on Object {
      _expiryTimer?.cancel();
      _expiryTimer = null;
      final currentProcess = process ?? _process;
      if (identical(_process, currentProcess)) _process = null;
      currentProcess?.kill();
      final processStopped = await _waitForProcess(currentProcess);
      await server?.close(force: true);
      if (identical(_server, server)) _server = null;
      _token = null;
      _expiresAt = null;
      if (identical(_directory, directory)) _directory = null;
      _addresses = const [];
      await _removeDirectoryWhenSafe(directory, currentProcess, processStopped: processStopped);
      rethrow;
    } finally {
      _starting = false;
    }
  }

  bool _isCurrent(int generation) => generation == _generation && !_stopping;

  void _ensureCurrent(int generation) {
    if (!_isCurrent(generation)) throw StateError('The network stream start was cancelled');
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer')
      ..set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
    if (!_validRequest(request)) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      response.statusCode = HttpStatus.methodNotAllowed;
      response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
      await response.close();
      return;
    }
    final fileName = NetworkMediaStreamPolicy.safeAssetName(request.uri.pathSegments, _token);
    if (fileName == null) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    final isPlaylist = fileName == 'index.m3u8';
    final directory = _directory;
    if (directory == null) {
      response.statusCode = HttpStatus.gone;
      await response.close();
      return;
    }
    final file = File(p.join(directory.path, fileName));
    if (!await file.exists()) {
      response.statusCode = isPlaylist ? HttpStatus.serviceUnavailable : HttpStatus.notFound;
      if (isPlaylist) response.headers.set(HttpHeaders.retryAfterHeader, '2');
      await response.close();
      return;
    }
    final length = await file.length();
    response.statusCode = HttpStatus.ok;
    response.headers
      ..contentLength = length
      ..contentType = isPlaylist
          ? ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8')
          : ContentType('video', 'mp2t');
    if (request.method == 'HEAD') {
      await response.close();
      return;
    }
    await response.addStream(file.openRead());
    await response.close();
  }

  bool _validRequest(HttpRequest request) {
    final server = _server;
    final token = _token;
    final expiry = _expiresAt;
    if (server == null || token == null || expiry == null || DateTime.now().isAfter(expiry)) {
      return false;
    }
    return NetworkMediaStreamPolicy.allowsHostAndPeer(
      hostHeader: request.headers.value(HttpHeaders.hostHeader),
      advertisedAddresses: _addresses,
      port: server.port,
      peer: request.connectionInfo?.remoteAddress,
    );
  }

  static bool _isPrivateIPv4(InternetAddress address) => NetworkMediaStreamPolicy.isPrivateIPv4(address);

  Future<void> stop() async {
    if (_stopping) return;
    _stopping = true;
    _generation++;
    try {
      _expiryTimer?.cancel();
      _expiryTimer = null;
      final server = _server;
      _server = null;
      await server?.close(force: true);
      final process = _process;
      _process = null;
      var processStopped = true;
      if (process != null) {
        try {
          process.stdin.writeln('q');
        } on Object {
          // FFmpeg may already have exited; the bounded wait below confirms it.
        }
        processStopped = await _waitForProcess(process);
      }
      final directory = _directory;
      _directory = null;
      _token = null;
      _addresses = const [];
      _expiresAt = null;
      await _removeDirectoryWhenSafe(directory, process, processStopped: processStopped);
    } finally {
      _stopping = false;
    }
  }

  Future<bool> _waitForProcess(Process? process) async {
    if (process == null) return true;
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
      return true;
    } on Object {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
        return true;
      } on Object {
        return false;
      }
    }
  }

  Future<void> _removeDirectoryWhenSafe(Directory? directory, Process? process, {required bool processStopped}) async {
    final targetDirectory = directory;
    if (targetDirectory == null) return;
    Future<void> remove() async {
      try {
        if (await targetDirectory.exists()) await targetDirectory.delete(recursive: true);
      } on Object {
        // Temporary stream files are best-effort cleanup after stopping FFmpeg.
      }
    }

    if (processStopped || process == null) {
      await remove();
    } else {
      unawaited(process.exitCode.then((_) => remove()));
    }
  }
}

typedef MediaStreamValueChanged<T> = void Function(T value);
