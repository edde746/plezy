import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'source_database.dart';
import 'source_models.dart';
import 'source_transport.dart';

class SourceOAuthConfig {
  const SourceOAuthConfig({required this.clientId, required this.authorize, required this.token, required this.scopes});
  final String clientId;
  final Uri authorize;
  final Uri token;
  final List<String> scopes;
  static SourceOAuthConfig forSource(FileSource source) {
    final override = source.options['clientId'];
    return switch (source.kind) {
      FileSourceKind.googleDrive => SourceOAuthConfig(
        clientId: override ?? const String.fromEnvironment('GOOGLE_DRIVE_DESKTOP_CLIENT_ID'),
        authorize: Uri.https('accounts.google.com', '/o/oauth2/v2/auth'),
        token: Uri.https('oauth2.googleapis.com', '/token'),
        scopes: const ['https://www.googleapis.com/auth/drive.readonly'],
      ),
      FileSourceKind.oneDrive => SourceOAuthConfig(
        clientId: override ?? const String.fromEnvironment('ONEDRIVE_CLIENT_ID'),
        authorize: Uri.https('login.microsoftonline.com', '/common/oauth2/v2.0/authorize'),
        token: Uri.https('login.microsoftonline.com', '/common/oauth2/v2.0/token'),
        scopes: const ['Files.Read', 'offline_access'],
      ),
      FileSourceKind.dropbox => SourceOAuthConfig(
        clientId: override ?? const String.fromEnvironment('DROPBOX_CLIENT_ID'),
        authorize: Uri.https('www.dropbox.com', '/oauth2/authorize'),
        token: Uri.https('api.dropboxapi.com', '/oauth2/token'),
        scopes: const ['files.metadata.read', 'files.content.read'],
      ),
      _ => throw const SourceException(SourceFailure.unsupported),
    };
  }
}

class SourceOAuthService {
  SourceOAuthService(this.repository, {SourceTransport? transport, Future<bool> Function(Uri)? launch})
    : transport = transport ?? SourceTransport(),
      launch = launch ?? ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));
  final SourceRepository repository;
  final SourceTransport transport;
  final Future<bool> Function(Uri) launch;
  final Map<String, Future<String>> _refreshing = {};
  static Future<void>? _googleInitialization;
  static const _driveScopes = ['https://www.googleapis.com/auth/drive.readonly'];
  bool _disposed = false;
  void Function()? _cancel;

  static String randomSecret() {
    final rng = Random.secure();
    return base64UrlEncode(List.generate(32, (_) => rng.nextInt(256))).replaceAll('=', '');
  }

  static String challenge(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

  Future<void> _initializeGoogle() => _googleInitialization ??= GoogleSignIn.instance.initialize(
    clientId: Platform.isIOS && const String.fromEnvironment('GOOGLE_DRIVE_IOS_CLIENT_ID').isNotEmpty
        ? const String.fromEnvironment('GOOGLE_DRIVE_IOS_CLIENT_ID')
        : null,
    serverClientId: const String.fromEnvironment('GOOGLE_DRIVE_SERVER_CLIENT_ID').isEmpty
        ? null
        : const String.fromEnvironment('GOOGLE_DRIVE_SERVER_CLIENT_ID'),
  );

  Future<Map<String, String>> authorize(FileSource source, {String? clientSecret}) async {
    if (source.kind == FileSourceKind.googleDrive && (Platform.isAndroid || Platform.isIOS)) {
      await _initializeGoogle();
      final account = await GoogleSignIn.instance.authenticate(scopeHint: _driveScopes);
      final authorization = await account.authorizationClient.authorizeScopes(_driveScopes);
      return {
        'accessToken': authorization.accessToken,
        'accountId': account.id,
        'nativeGoogle': 'true',
        'expiresAt': '${DateTime.now().add(const Duration(minutes: 50)).millisecondsSinceEpoch}',
      };
    }
    final config = SourceOAuthConfig.forSource(source);
    if (config.clientId.isEmpty) throw const SourceException(SourceFailure.unsupported);
    final verifier = randomSecret(), state = randomSecret();
    final completer = Completer<Uri>();
    // Observe cancellation even while the external browser is being opened.
    unawaited(completer.future.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
    HttpServer? server;
    StreamSubscription<Uri>? subscription;
    final desktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    final Uri redirect;
    void receive(Uri uri) {
      if (uri.queryParameters['state'] != state || completer.isCompleted) return;
      completer.complete(uri);
    }

    if (desktop) {
      final port = source.kind == FileSourceKind.googleDrive ? 0 : 53682;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      redirect = Uri.parse('http://127.0.0.1:${server.port}/oauth/callback');
      server.listen((request) async {
        request.response.headers.set('Cache-Control', 'no-store');
        request.response.headers.set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
        if (request.method != 'GET' ||
            request.uri.path != redirect.path ||
            request.uri.queryParameters['state'] != state) {
          request.response.statusCode = 404;
        } else {
          receive(request.uri);
          request.response.headers.contentType = ContentType.text;
          request.response.write('You can return to PlezyNG.');
        }
        await request.response.close();
      });
    } else {
      redirect = Uri.parse('plezyng-source://oauth/callback');
      subscription = AppLinks().uriLinkStream.listen((uri) {
        if (uri.scheme == redirect.scheme && uri.host == redirect.host && uri.path == redirect.path) receive(uri);
      });
    }
    _cancel = () {
      if (!completer.isCompleted) completer.completeError(const SourceException(SourceFailure.cancelled));
    };
    try {
      final uri = config.authorize.replace(
        queryParameters: {
          'client_id': config.clientId,
          'response_type': 'code',
          'redirect_uri': redirect.toString(),
          'scope': config.scopes.join(' '),
          'state': state,
          'code_challenge': challenge(verifier),
          'code_challenge_method': 'S256',
          if (source.kind == FileSourceKind.googleDrive) ...{'access_type': 'offline', 'prompt': 'consent'},
          if (source.kind == FileSourceKind.dropbox) 'token_access_type': 'offline',
        },
      );
      if (!await launch(uri)) throw const SourceException(SourceFailure.unavailable);
      final response = await completer.future.timeout(const Duration(minutes: 5));
      final code = response.queryParameters['code'];
      if (code == null || _disposed) throw const SourceException(SourceFailure.cancelled);
      final data = await transport.json(
        'POST',
        config.token,
        body: <String, String>{
          'grant_type': 'authorization_code',
          'client_id': config.clientId,
          'code': code,
          'redirect_uri': redirect.toString(),
          'code_verifier': verifier,
          if (source.kind == FileSourceKind.googleDrive && clientSecret?.isNotEmpty == true)
            'client_secret': clientSecret!,
        },
      );
      return _tokens(data, previous: {if (clientSecret?.isNotEmpty == true) 'clientSecret': clientSecret!});
    } finally {
      _cancel = null;
      await subscription?.cancel();
      await server?.close(force: true);
    }
  }

  Map<String, String> _tokens(Map<String, dynamic> data, {Map<String, String> previous = const {}}) {
    final access = data['access_token'];
    if (access is! String || access.isEmpty) throw const SourceException(SourceFailure.authentication);
    final expires = sourceInt(data['expires_in']) ?? 3600;
    return {
      ...previous,
      'accessToken': access,
      if (data['refresh_token'] is String) 'refreshToken': data['refresh_token'] as String,
      'expiresAt': '${DateTime.now().add(Duration(seconds: expires)).millisecondsSinceEpoch}',
    };
  }

  Future<String> accessToken(FileSource source, {bool refresh = false}) async {
    if (_disposed) throw const SourceException(SourceFailure.cancelled);
    final credentials = await repository.credentials(source);
    final expiry = int.tryParse(credentials['expiresAt'] ?? '') ?? 0;
    if (!refresh &&
        expiry > DateTime.now().add(const Duration(seconds: 90)).millisecondsSinceEpoch &&
        credentials['accessToken']?.isNotEmpty == true) {
      return credentials['accessToken']!;
    }
    final key = sourceKey(source.profileId, source.id);
    return _refreshing.putIfAbsent(
      key,
      () => _refresh(source, credentials, force: refresh).whenComplete(() => _refreshing.remove(key)),
    );
  }

  Future<String> _refresh(FileSource source, Map<String, String> previous, {required bool force}) async {
    final Map<String, String> updated;
    if (previous['nativeGoogle'] == 'true') {
      await _initializeGoogle();
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account == null || account.id != previous['accountId']) {
        throw const SourceException(SourceFailure.authentication);
      }
      if (force && previous['accessToken'] != null) {
        await account.authorizationClient.clearAuthorizationToken(accessToken: previous['accessToken']!);
      }
      final authorization = await account.authorizationClient.authorizationForScopes(_driveScopes);
      if (authorization == null) throw const SourceException(SourceFailure.authentication);
      updated = {
        ...previous,
        'accessToken': authorization.accessToken,
        'expiresAt': '${DateTime.now().add(const Duration(minutes: 50)).millisecondsSinceEpoch}',
      };
    } else {
      final config = SourceOAuthConfig.forSource(source);
      final refresh = previous['refreshToken'];
      if (refresh == null) throw const SourceException(SourceFailure.authentication);
      final data = await transport.json(
        'POST',
        config.token,
        body: <String, String>{
          'grant_type': 'refresh_token',
          'refresh_token': refresh,
          'client_id': config.clientId,
          if (previous['clientSecret']?.isNotEmpty == true) 'client_secret': previous['clientSecret']!,
        },
      );
      updated = _tokens(data, previous: previous);
    }
    if (_disposed) throw const SourceException(SourceFailure.cancelled);
    await repository.updateCredentials(source, updated);
    return updated['accessToken']!;
  }

  void cancel() => _cancel?.call();
  void dispose() {
    _disposed = true;
    cancel();
    transport.close();
  }
}
