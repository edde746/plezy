import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';

class WifiTransferScreen extends StatefulWidget {
  const WifiTransferScreen({super.key});

  static bool isSupported(BuildContext context) =>
      PlatformDetector.isDesktopOS() ||
      Platform.isAndroid && !PlatformDetector.isTV() && !PlatformDetector.isAutomotive();

  @override
  State<WifiTransferScreen> createState() => _WifiTransferScreenState();
}

class _WifiTransferScreenState extends State<WifiTransferScreen> with WidgetsBindingObserver {
  static const _lifetime = Duration(minutes: 15);
  static const _maxFileBytes = 4 * 1024 * 1024 * 1024;
  static const _maxSessionBytes = 10 * 1024 * 1024 * 1024;
  static const _maxFiles = 100;
  HttpServer? _server;
  Directory? _temporaryDirectory;
  Timer? _expiryTimer;
  Timer? _ticker;
  DateTime? _expiresAt;
  String? _token;
  List<String> _addresses = const [];
  Object? _failure;
  bool _starting = false;
  bool _uploading = false;
  String _languageTag = 'en';
  String _textDirection = 'ltr';
  int _uploadedFiles = 0;
  int _uploadedBytes = 0;
  SourceController? _sources;
  String? _profile;
  int _generation = 0;
  final Set<Future<void>> _requests = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = LocaleSettings.currentLocale;
    _languageTag = [
      locale.languageCode,
      if (locale.scriptCode != null) locale.scriptCode!,
      if (locale.countryCode != null) locale.countryCode!,
    ].join('-');
    _textDirection = Directionality.of(context) == TextDirection.rtl ? 'rtl' : 'ltr';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sources = context.read<SourceController>();
      _profile = _sources!.profileId;
      _generation = _sources!.generation;
      _sources!.addListener(_onSessionChanged);
      unawaited(_start());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sources?.removeListener(_onSessionChanged);
    _ticker?.cancel();
    unawaited(_close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_close());
    } else if (_server == null && mounted) {
      unawaited(_start());
    }
  }

  void _onSessionChanged() {
    final sources = _sources;
    if (sources == null || sources.generation != _generation || sources.profileId != _profile) {
      unawaited(_close());
    }
  }

  Future<void> _start() async {
    if (_starting || !mounted) return;
    setState(() {
      _starting = true;
      _failure = null;
    });
    try {
      final sources = _sources ?? context.read<SourceController>();
      await sources.ready;
      sources.requireSession(_generation);
      final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
      final addresses = <String>{
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (_isPrivateClient(address)) address.address,
      }.toList()..sort();
      if (addresses.isEmpty) throw const SourceException(SourceFailure.unavailable);

      final secureRandom = Random.secure();
      final tokenBytes = List<int>.generate(32, (_) => secureRandom.nextInt(256));
      final token = base64Url.encode(tokenBytes).replaceAll('=', '');
      final temp = await Directory.systemTemp.createTemp('plezy-wifi-');
      final HttpServer server;
      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: false);
      } on Object {
        await temp.delete(recursive: true);
        rethrow;
      }
      if (!mounted || !_sameSession(sources)) {
        await server.close(force: true);
        await temp.delete(recursive: true);
        return;
      }
      _server = server;
      _temporaryDirectory = temp;
      _token = token;
      _addresses = addresses;
      _uploadedFiles = 0;
      _uploadedBytes = 0;
      _expiresAt = DateTime.now().add(_lifetime);
      server.listen(_dispatch, onError: (_) {});
      _expiryTimer = Timer(_lifetime, () => unawaited(_close()));
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } on Object {
      if (mounted) setState(() => _failure = const SourceException(SourceFailure.unavailable));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  bool _sameSession(SourceController sources) =>
      sources.current(_generation) && sources.profileId == _profile && !sources.blocked;

  bool _isPrivateClient(InternetAddress address) {
    if (address.isLoopback) return true;
    if (address.type == InternetAddressType.IPv6) {
      final value = address.address.toLowerCase();
      return value.startsWith('fc') || value.startsWith('fd') || value.startsWith('fe80:');
    }
    final octets = address.rawAddress;
    if (octets.length != 4) return false;
    return octets[0] == 10 ||
        octets[0] == 127 ||
        octets[0] == 192 && octets[1] == 168 ||
        octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31 ||
        octets[0] == 169 && octets[1] == 254;
  }

  bool _validHost(HttpRequest request) {
    final host = request.headers.value(HttpHeaders.hostHeader)?.toLowerCase();
    if (host == null) return false;
    final allowed = <String>{
      ..._addresses.map((address) => '$address:${_server!.port}'),
      '127.0.0.1:${_server!.port}',
      'localhost:${_server!.port}',
    };
    return allowed.contains(host);
  }

  bool _validRequest(HttpRequest request) {
    final expires = _expiresAt;
    final token = _token;
    final server = _server;
    return server != null &&
        token != null &&
        expires != null &&
        DateTime.now().isBefore(expires) &&
        _validHost(request) &&
        request.connectionInfo != null &&
        _isPrivateClient(request.connectionInfo!.remoteAddress) &&
        request.uri.pathSegments.isNotEmpty &&
        request.uri.pathSegments.first == token;
  }

  void _dispatch(HttpRequest request) {
    late final Future<void> task;
    task = _handle(request).catchError((Object _) async {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } on Object {
        // The peer may have gone away while the transfer was closing.
      }
    });
    _requests.add(task);
    unawaited(task.whenComplete(() => _requests.remove(task)));
  }

  void _securityHeaders(HttpResponse response) {
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer')
      ..set(
        'Content-Security-Policy',
        "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
      );
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    _securityHeaders(response);
    if (!_validRequest(request)) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }
    final segments = request.uri.pathSegments;
    if (request.method == 'GET' && segments.length == 1) {
      response.headers.contentType = ContentType.html;
      response.write(_renderUploadPage());
      await response.close();
      return;
    }
    if (request.method != 'PUT' || segments.length != 2 || segments[1] != 'upload') {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    if (_uploading) {
      response.statusCode = HttpStatus.tooManyRequests;
      await response.close();
      return;
    }
    final originText = request.headers.value('origin');
    final host = request.headers.value(HttpHeaders.hostHeader);
    final origin = Uri.tryParse(originText ?? '');
    if (origin == null || host == null || origin.origin != 'http://$host') {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }
    final contentLength = request.headers.contentLength;
    if (_uploadedFiles >= _maxFiles ||
        contentLength > _maxFileBytes ||
        contentLength > 0 && contentLength + _uploadedBytes > _maxSessionBytes) {
      response.statusCode = HttpStatus.requestEntityTooLarge;
      await response.close();
      return;
    }
    final rawName = request.uri.queryParameters['name'] ?? '';
    final name = _safeFilename(rawName);
    if (name == null || classifySourceFile(name) == SourceItemKind.unknown) {
      response.statusCode = HttpStatus.badRequest;
      await response.close();
      return;
    }
    final sources = _sources;
    final temp = _temporaryDirectory;
    if (sources == null || temp == null || !_sameSession(sources)) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }

    _uploading = true;
    final uniqueName = '${const Uuid().v4()}-${p.basename(name)}';
    final file = File(p.join(temp.path, uniqueName));
    RandomAccessFile? output;
    var received = 0;
    try {
      output = await file.open(mode: FileMode.write);
      await for (final chunk in request) {
        received += chunk.length;
        if (received > _maxFileBytes || received + _uploadedBytes > _maxSessionBytes) {
          throw const SourceException(SourceFailure.quotaExceeded);
        }
        await output.writeFrom(chunk);
      }
      await output.flush();
      await output.close();
      output = null;
      sources.requireSession(_generation);
      if (received == 0) throw const SourceException(SourceFailure.invalidData);
      await sources.importFiles([
        PlatformFile(name: name, size: received, path: file.path),
      ], name: t.universalMedia.wifiImportedFiles);
      sources.requireSession(_generation);
      _uploadedFiles++;
      _uploadedBytes += received;
      if (mounted) setState(() {});
      response.statusCode = HttpStatus.created;
      response.headers.contentType = ContentType.text;
      response.write(t.universalMedia.uploadComplete);
    } on SourceException catch (error) {
      response.statusCode = error.reason == SourceFailure.quotaExceeded
          ? HttpStatus.requestEntityTooLarge
          : HttpStatus.badRequest;
      response.headers.contentType = ContentType.text;
      response.write(t.universalMedia.uploadFailed);
    } on Object {
      response.statusCode = HttpStatus.internalServerError;
      response.headers.contentType = ContentType.text;
      response.write(t.universalMedia.uploadFailed);
    } finally {
      try {
        await output?.close();
      } on Object {
        // Cleanup continues even when a client disconnects during a write.
      }
      try {
        if (await file.exists()) await file.delete();
      } on Object {
        // The temporary directory is also removed when the transfer closes.
      }
      _uploading = false;
      try {
        await response.close();
      } on Object {
        // The remote browser may close its request after showing an error.
      }
    }
  }

  String? _safeFilename(String value) {
    final normalized = value.replaceAll('\\', '/');
    final name = p.basename(normalized).replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (name.isEmpty || name == '.' || name == '..' || name.length > 180) return null;
    return name;
  }

  Future<void> _close() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _ticker?.cancel();
    _ticker = null;
    final server = _server;
    _server = null;
    _token = null;
    _expiresAt = null;
    _addresses = const [];
    if (server != null) await server.close(force: true);
    if (_requests.isNotEmpty) await Future.wait(_requests.toList(), eagerError: false);
    final temp = _temporaryDirectory;
    _temporaryDirectory = null;
    if (temp != null && await temp.exists()) await temp.delete(recursive: true);
    if (mounted) setState(() {});
  }

  String _formatRemaining() {
    final expires = _expiresAt;
    if (expires == null) return '';
    final seconds = expires.difference(DateTime.now()).inSeconds.clamp(0, _lifetime.inSeconds);
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) showSnackBar(context, t.universalMedia.addressCopied);
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.universalMedia.wifiTransfer),
    focusableAppBarActions: true,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.universalMedia.wifiTransferIntro, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Text(t.universalMedia.wifiTransferPrivacy),
                  const SizedBox(height: 20),
                  if (_starting) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(t.universalMedia.wifiTransferStarting, textAlign: TextAlign.center),
                  ] else if (_server != null && _token != null) ...[
                    Text(t.universalMedia.openThisAddress, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final address in _addresses)
                      Card(
                        child: ListTile(
                          title: SelectableText('http://$address:${_server!.port}/$_token'),
                          trailing: IconButton(
                            tooltip: t.universalMedia.copyAddress,
                            onPressed: () => _copy('http://$address:${_server!.port}/$_token'),
                            icon: const AppIcon(Symbols.content_copy_rounded),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(t.universalMedia.transferExpires(time: _formatRemaining())),
                    Text(t.universalMedia.uploadCount(n: _uploadedFiles, count: _uploadedFiles)),
                    Text(t.universalMedia.uploadedData(size: ByteFormatter.formatBytes(_uploadedBytes))),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => unawaited(_close()),
                      icon: const AppIcon(Symbols.stop_circle_rounded),
                      label: Text(t.universalMedia.stopTransfer),
                    ),
                  ] else ...[
                    if (_failure != null) Text(t.universalMedia.wifiTransferUnavailable, textAlign: TextAlign.center),
                    FilledButton.icon(
                      onPressed: _starting ? null : () => unawaited(_start()),
                      icon: const AppIcon(Symbols.wifi_tethering_rounded),
                      label: Text(t.universalMedia.startTransfer),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  String _renderUploadPage() {
    String escapeHtml(String value) => value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');

    final messages = jsonEncode({
      'selectFirst': t.universalMedia.uploadSelectFirst,
      'uploading': t.universalMedia.uploading,
      'uploadFailed': t.universalMedia.uploadFailed,
      'uploadComplete': t.universalMedia.uploadComplete,
    });
    return _uploadPageTemplate
        .replaceAll('@@LANG@@', _languageTag)
        .replaceAll('@@DIR@@', _textDirection)
        .replaceAll('@@TITLE@@', escapeHtml(t.universalMedia.wifiBrowserTitle))
        .replaceAll('@@INTRO@@', escapeHtml(t.universalMedia.wifiBrowserIntro))
        .replaceAll('@@FILES@@', escapeHtml(t.universalMedia.uploadFilesLabel))
        .replaceAll('@@ACTION@@', escapeHtml(t.universalMedia.uploadSelected))
        .replaceAll('@@MESSAGES@@', messages);
  }

  static const _uploadPageTemplate = r'''<!doctype html>
<html lang="@@LANG@@" dir="@@DIR@@">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="no-referrer">
<title>@@TITLE@@</title>
<style>
  :root{color-scheme:dark light;font:16px system-ui,sans-serif}
  body{max-width:42rem;margin:0 auto;padding:2rem;line-height:1.5}
  main{border:1px solid #7777;border-radius:1rem;padding:1.5rem}
  h1{font-size:1.5rem}label,button{display:block;margin-top:1rem}
  input,button{font:inherit}button{padding:.7rem 1rem}
  #status{min-height:3rem}
</style>
<main>
  <h1>@@TITLE@@</h1>
  <p>@@INTRO@@</p>
  <label for="files">@@FILES@@</label>
  <input id="files" type="file" accept="audio/*,video/*,.m4b,.epub,.pdf,.cbz" multiple>
  <button id="send" type="button">@@ACTION@@</button>
  <p id="status" role="status" aria-live="polite"></p>
</main>
<script>
const messages=@@MESSAGES@@,picker=document.querySelector('#files'),button=document.querySelector('#send'),status=document.querySelector('#status');
button.addEventListener('click',async()=>{
  if(!picker.files.length){status.textContent=messages.selectFirst;return;}
  button.disabled=true;
  try{
    for(const file of picker.files){
      status.textContent=messages.uploading+' '+file.name+'…';
      const response=await fetch(location.pathname.replace(/\/$/,'')+'/upload?name='+encodeURIComponent(file.name),{
        method:'PUT',headers:{'Content-Type':'application/octet-stream'},body:file
      });
      if(!response.ok)throw new Error(messages.uploadFailed+' '+file.name+' ('+response.status+').');
    }
    status.textContent=messages.uploadComplete;
    picker.value='';
  }catch(error){status.textContent=error.message||messages.uploadFailed;}
  finally{button.disabled=false;}
});
</script>
</html>''';
}
