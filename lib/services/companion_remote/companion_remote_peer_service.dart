import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import '../../utils/future_extensions.dart';

import '../../i18n/strings.g.dart';
import '../../models/companion_remote/remote_command.dart';
import '../../models/companion_remote/remote_session.dart';
import '../../utils/app_logger.dart';
import '../../utils/happy_eyeballs.dart';
import '../../utils/serial_future_queue.dart';
import '../base_peer_service.dart';
import 'remote_auth_context.dart';
import 'remote_auth_service.dart';

// Re-export so callers that import from here get the types.
export '../base_peer_service.dart' show PeerError, PeerErrorType;

/// Backward-compatible aliases so existing callers that reference the
/// Remote-specific names keep compiling.
typedef RemotePeerErrorType = PeerErrorType;
typedef RemotePeerError = PeerError;

typedef _SessionKeyDeriver =
    Future<List<int>> Function(List<int> homeSecret, List<int> hostNonce, List<int> clientNonce);
typedef _RaceProbeConnection = ({Future<void> Function() close, Future<void> ready, Stream<dynamic> stream});

typedef _RaceProbeFactory = _RaceProbeConnection Function(Uri uri);

class CompanionRemotePeerService with KeepaliveMixin {
  static const int _productionMaxTotalHostConnections = 100;
  static const int _productionMaxHostConnectionsPerSource = 5;
  static const int _productionMaxPreAuthMessageBytes = 65536;
  static const Duration _productionAuthTimeout = Duration(seconds: 10);
  static const int _productionMaxFailedAuthAttempts = 5;
  static const Duration _productionAuthLockoutDuration = Duration(seconds: 30);
  static const Duration _productionRemoteConnectTimeout = Duration(seconds: 10);

  CompanionRemotePeerService()
    : this.forTesting(
        maxTotalHostConnections: _productionMaxTotalHostConnections,
        maxHostConnectionsPerSource: _productionMaxHostConnectionsPerSource,
        maxPreAuthMessageBytes: _productionMaxPreAuthMessageBytes,
        authTimeout: _productionAuthTimeout,
        maxFailedAuthAttempts: _productionMaxFailedAuthAttempts,
        authLockoutDuration: _productionAuthLockoutDuration,
        remoteConnectTimeout: _productionRemoteConnectTimeout,
      );

  CompanionRemotePeerService.forTesting({
    int maxTotalHostConnections = _productionMaxTotalHostConnections,
    int maxHostConnectionsPerSource = _productionMaxHostConnectionsPerSource,
    int maxPreAuthMessageBytes = _productionMaxPreAuthMessageBytes,
    Duration authTimeout = _productionAuthTimeout,
    int maxFailedAuthAttempts = _productionMaxFailedAuthAttempts,
    this._authLockoutDuration = _productionAuthLockoutDuration,
    Duration remoteConnectTimeout = _productionRemoteConnectTimeout,
    Future<List<int>> Function(List<int> homeSecret, List<int> hostNonce, List<int> clientNonce)? deriveSessionEncKey,
    ({Future<void> Function() close, Future<void> ready, Stream<dynamic> stream}) Function(Uri uri)? raceProbeFactory,
    this._afterHostUpgrade,
  }) : assert(maxTotalHostConnections > 0),
       assert(maxHostConnectionsPerSource > 0),
       assert(maxPreAuthMessageBytes > 0),
       assert(authTimeout > Duration.zero),
       assert(maxFailedAuthAttempts > 0),
       assert(remoteConnectTimeout > Duration.zero),
       _maxTotalHostConnections = maxTotalHostConnections,
       _maxHostConnectionsPerSource = maxHostConnectionsPerSource,
       _maxPreAuthMessageBytes = maxPreAuthMessageBytes,
       _authTimeout = authTimeout,
       _maxFailedAuthAttempts = maxFailedAuthAttempts,
       _remoteConnectTimeout = remoteConnectTimeout,
       _deriveSessionEncKey =
           deriveSessionEncKey ??
           ((homeSecret, hostNonce, clientNonce) {
             return RemoteAuthService.instance.deriveSessionEncKey(homeSecret, hostNonce, clientNonce);
           }),
       _raceProbeFactory = raceProbeFactory ?? _openRaceProbe;

  static _RaceProbeConnection _openRaceProbe(Uri uri) {
    final channel = IOWebSocketChannel.connect(
      uri,
      connectTimeout: const Duration(seconds: 5),
      customClient: happyEyeballsHttpClient,
    );
    var connected = false;
    unawaited(
      channel.ready.then((_) {
        connected = true;
      }, onError: (Object _) {}),
    );
    return (
      close: () async {
        if (connected) {
          await channel.sink.close();
          return;
        }
        // web_socket_channel 3.x never completes a pre-connection
        // `sink.close()`: its future waits on an internal stream listener
        // that only the connect-success path attaches. Awaiting it here
        // serialized race cleanup behind one unreachable candidate forever,
        // so the managed join after a won race never started (#2077). A
        // still-pending candidate holds no host admission slot, so defer its
        // close to whenever the connect settles instead of waiting.
        unawaited(channel.ready.then((_) => channel.sink.close(), onError: (Object _) {}));
      },
      ready: channel.ready,
      stream: channel.stream,
    );
  }

  final int _maxTotalHostConnections;
  final int _maxHostConnectionsPerSource;
  final int _maxPreAuthMessageBytes;
  final Duration _authTimeout;
  final int _maxFailedAuthAttempts;
  final Duration _authLockoutDuration;
  final Duration _remoteConnectTimeout;
  final _SessionKeyDeriver _deriveSessionEncKey;
  final _RaceProbeFactory _raceProbeFactory;
  final void Function()? _afterHostUpgrade;

  // Server-side (host) fields
  HttpServer? _server;
  // The socket is closed through its owning admission during disconnect/dispose.
  // ignore: close_sinks
  WebSocket? _clientSocket;
  _HostAdmission? _currentHostAdmission;
  final Set<_HostAdmission> _hostAdmissions = {};
  final Map<String, int> _hostAdmissionsBySource = {};
  int _hostAdmissionCount = 0;
  int _authenticationCommitGeneration = 0;
  Future<void> _hostAuthenticationCommitTail = Future<void>.value();
  bool _acceptingHostConnections = false;
  bool _isDisconnecting = false;
  Future<void>? _disconnectInProgress;
  Future<void>? _disposeInProgress;
  bool _disposed = false;

  // Client-side (remote) fields
  IOWebSocketChannel? _channel;
  // Whether the current [_channel]'s connection has been established; a
  // pre-connection `sink.close()` future never completes (see
  // [_closeManagedChannel]).
  bool _channelConnected = false;
  StreamSubscription<dynamic>? _channelSubscription;
  int _remoteConnectionGeneration = 0;

  String? _myPeerId;
  String? _hostAddress; // Format: "ip:port"
  RemoteSessionRole? _role;
  String? _selectedAuthContextId;
  String? _selectedHostClientId;

  // Encrypted channel state
  List<int>? _sessionEncKey;
  int _sendCounter = 0;
  int _recvCounter = 0;
  bool _isAuthenticated = false;

  final _commandReceivedController = StreamController<RemoteCommand>.broadcast();
  final _deviceConnectedController = StreamController<RemoteDevice>.broadcast();
  final _deviceDisconnectedController = StreamController<void>.broadcast();
  final _errorController = StreamController<RemotePeerError>.broadcast();
  final _connectionStateController = StreamController<RemoteSessionStatus>.broadcast();

  // Keepalive (via KeepaliveMixin)
  @override
  Duration get pingInterval => const Duration(seconds: 5);
  @override
  Duration get pongTimeout => Duration.zero; // No pong timeout; host just replies inline

  // Auth rate limiting (per source IP)
  final Map<String, int> _failedAuthAttempts = {};
  final Map<String, DateTime> _authLockouts = {};

  Stream<RemoteCommand> get onCommandReceived => _commandReceivedController.stream;
  Stream<RemoteDevice> get onDeviceConnected => _deviceConnectedController.stream;
  Stream<void> get onDeviceDisconnected => _deviceDisconnectedController.stream;
  Stream<RemotePeerError> get onError => _errorController.stream;
  Stream<RemoteSessionStatus> get onConnectionStateChanged => _connectionStateController.stream;

  String? get myPeerId => _myPeerId;
  String? get hostAddress => _hostAddress;
  RemoteSessionRole? get role => _role;
  String? get selectedAuthContextId => _selectedAuthContextId;
  String? get selectedHostClientId => _selectedHostClientId;
  bool get isHost => _role == RemoteSessionRole.host;
  bool get isConnected => _clientSocket != null || (_channel != null && _channel?.closeCode == null);

  Future<List<String>> _getAllLocalIpAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

      final preferred = <String>[];
      final others = <String>[];

      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('lo')) continue;

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final name = interface.name.toLowerCase();
            if (name.contains('en') || name.contains('wl') || name.contains('eth')) {
              preferred.add(addr.address);
            } else {
              others.add(addr.address);
            }
          }
        }
      }

      final all = [...preferred, ...others];
      if (all.isEmpty) {
        throw RemotePeerError(
          type: RemotePeerErrorType.networkError,
          message: t.companionRemote.errors.noNetworkInterface,
        );
      }
      return all;
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to get local IPs', error: e);
      rethrow;
    }
  }

  /// Create a host session that accepts any of the provided remote identities.
  Future<({List<String> addresses, int port})> createSessionForContexts(
    String deviceName,
    String platform,
    List<RemoteAuthContext> authContexts,
  ) async {
    if (_disposed) {
      throw StateError('CompanionRemotePeerService is disposed');
    }

    if (authContexts.isEmpty) {
      throw RemotePeerError(
        type: RemotePeerErrorType.authFailed,
        message: t.companionRemote.errors.authenticationFailed,
      );
    }

    if (_server != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.host;
    _myPeerId = 'host';

    try {
      const int preferredPort = 48632;
      late final HttpServer server;

      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
        appLogger.d('CompanionRemote: Server bound to port $preferredPort');
      } catch (e) {
        appLogger.w('CompanionRemote: Port $preferredPort occupied, using random port');
        server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      }

      _server = server;
      _acceptingHostConnections = true;

      final localIps = await _getAllLocalIpAddresses();
      final port = server.port;
      final addresses = localIps.map((ip) => '$ip:$port').toList();
      _hostAddress = addresses.first;

      appLogger.d('CompanionRemote: Host server started, addresses: $addresses');

      server.listen((request) {
        unawaited(_serveHostRequest(request, server, deviceName, platform, authContexts));
      });

      _connectionStateController.add(RemoteSessionStatus.connected);

      return (addresses: addresses, port: port);
    } catch (e) {
      _acceptingHostConnections = false;
      final failedServer = _server;
      _server = null;
      await _runDisconnectCleanup(failedServer?.close(force: true), 'failed server');
      appLogger.e('CompanionRemote: Failed to create server', error: e);
      _errorController.add(
        RemotePeerError(
          type: RemotePeerErrorType.serverError,
          message: t.companionRemote.errors.serverStartFailed(error: e.toString()),
          originalError: e,
        ),
      );
      rethrow;
    }
  }

  Future<void> _serveHostRequest(
    HttpRequest request,
    HttpServer server,
    String hostDeviceName,
    String hostPlatform,
    List<RemoteAuthContext> authContexts,
  ) async {
    if (request.uri.path != '/ws') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final sourceIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final admission = _tryReserveHostAdmission(sourceIp, server);
    if (admission == null) {
      request.response.statusCode = HttpStatus.tooManyRequests;
      request.response.headers.contentLength = 0;
      await request.response.close();
      return;
    }

    try {
      // Ownership transfers to the admission immediately after upgrade.
      // ignore: close_sinks
      final socket = await WebSocketTransformer.upgrade(request, compression: CompressionOptions.compressionOff);
      admission.socket = socket;
      admission.completeUpgrade();
      _afterHostUpgrade?.call();

      if (!_isHostAdmissionLive(admission, phase: _HostAdmissionPhase.upgrading)) {
        await _closeHostAdmissionSocket(admission);
        return;
      }

      _handleNewWebSocketConnection(admission, hostDeviceName, hostPlatform, authContexts);
    } catch (e) {
      admission.completeUpgrade();
      await _closeHostAdmissionSocket(admission);
      try {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      } catch (_) {
        // The upgrade path may already have committed and closed the response.
      }
      appLogger.d('CompanionRemote: WebSocket upgrade rejected', error: e);
    }
  }

  _HostAdmission? _tryReserveHostAdmission(String sourceIp, HttpServer server) {
    if (!_acceptingHostConnections || !identical(_server, server) || _isSourceLockedOut(sourceIp)) {
      return null;
    }

    final sourceCount = _hostAdmissionsBySource[sourceIp] ?? 0;
    if (_hostAdmissionCount >= _maxTotalHostConnections || sourceCount >= _maxHostConnectionsPerSource) {
      return null;
    }

    final admission = _HostAdmission(sourceIp: sourceIp, server: server);
    _hostAdmissions.add(admission);
    _hostAdmissionCount++;
    _hostAdmissionsBySource[sourceIp] = sourceCount + 1;
    return admission;
  }

  bool _isSourceLockedOut(String sourceIp) {
    final lockout = _authLockouts[sourceIp];
    if (lockout == null) return false;
    if (DateTime.now().isBefore(lockout)) return true;
    _authLockouts.remove(sourceIp);
    _failedAuthAttempts.remove(sourceIp);
    return false;
  }

  bool _isHostAdmissionLive(_HostAdmission admission, {required _HostAdmissionPhase phase, int? commitGeneration}) {
    // The admission owns and closes this socket.
    // ignore: close_sinks
    final socket = admission.socket;
    return !admission.released &&
        admission.phase == phase &&
        identical(_server, admission.server) &&
        _acceptingHostConnections &&
        socket != null &&
        socket.readyState == WebSocket.open &&
        (commitGeneration == null || commitGeneration == _authenticationCommitGeneration);
  }

  void _handleNewWebSocketConnection(
    _HostAdmission admission,
    String hostDeviceName,
    String hostPlatform,
    List<RemoteAuthContext> authContexts,
  ) {
    // The admission owns and closes this socket.
    // ignore: close_sinks
    final socket = admission.socket!;
    final auth = RemoteAuthService.instance;
    final hostNonce = auth.generateNonce();
    final primaryContext = authContexts.first;

    appLogger.d('CompanionRemote: New WebSocket connection from ${admission.sourceIp}');

    admission.phase = _HostAdmissionPhase.awaitingAuth;
    try {
      socket.add(
        jsonEncode({
          'type': 'challenge',
          'nonce': base64Encode(hostNonce),
          'hostClientId': primaryContext.clientIdentifier,
          'authContexts': [
            for (final context in authContexts) {'id': context.id, 'hostClientId': context.clientIdentifier},
          ],
        }),
      );
    } catch (e) {
      appLogger.d('CompanionRemote: Failed to send authentication challenge', error: e);
      unawaited(_closeHostAdmissionSocket(admission));
      return;
    }

    admission.authTimer = Timer(_authTimeout, () {
      if (admission.phase == _HostAdmissionPhase.awaitingAuth ||
          admission.phase == _HostAdmissionPhase.authenticating) {
        appLogger.w('CompanionRemote: Authentication timeout');
        unawaited(_closeHostAdmissionSocket(admission, code: 4001, reason: 'Authentication timeout'));
      }
    });

    // The subscription is assigned to and cancelled through the admission.
    // ignore: cancel_subscriptions
    late final StreamSubscription<dynamic> socketSubscription;
    socketSubscription = socket.listen(
      (data) {
        if (admission.phase == _HostAdmissionPhase.awaitingAuth) {
          // Claim the only pre-auth message before parsing or awaiting.
          admission.phase = _HostAdmissionPhase.authenticating;
          unawaited(
            _authenticateHostAdmission(
              admission,
              data,
              hostNonce,
              hostDeviceName,
              hostPlatform,
              authContexts,
              primaryContext,
            ),
          );
        } else if (admission.phase == _HostAdmissionPhase.authenticated) {
          unawaited(
            _handleEncryptedCommand(data).catchError((Object error, StackTrace stackTrace) {
              appLogger.e('CompanionRemote: Failed to process encrypted message', error: error, stackTrace: stackTrace);
            }),
          );
        }
      },
      onDone: () {
        appLogger.d('CompanionRemote: WebSocket connection closed');
        admission.phase = _HostAdmissionPhase.terminal;
        _releaseHostAdmission(admission);
      },
      onError: (Object error, StackTrace stackTrace) {
        admission.phase = _HostAdmissionPhase.terminal;
        admission.authTimer?.cancel();
        admission.authTimer = null;
        appLogger.e('CompanionRemote: WebSocket error', error: error, stackTrace: stackTrace);
        _errorController.add(
          RemotePeerError(
            type: RemotePeerErrorType.dataChannelError,
            message: t.companionRemote.pairing.failedToConnect(error: error.toString()),
            originalError: error,
          ),
        );
        unawaited(_closeHostAdmissionSocket(admission));
      },
      cancelOnError: true,
    );
    admission.subscription = socketSubscription;
  }

  Future<void> _authenticateHostAdmission(
    _HostAdmission admission,
    dynamic data,
    List<int> hostNonce,
    String hostDeviceName,
    String hostPlatform,
    List<RemoteAuthContext> authContexts,
    RemoteAuthContext primaryContext,
  ) async {
    // dart:io delivers an assembled WebSocket message. This bounds application
    // parsing and allocation after delivery, not the runtime's frame buffer.
    if (data is! String || data.length > _maxPreAuthMessageBytes) {
      _rejectHostAuthentication(admission);
      return;
    }

    late final Map<String, dynamic> message;
    try {
      if (utf8.encode(data).length > _maxPreAuthMessageBytes) {
        _rejectHostAuthentication(admission);
        return;
      }
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) {
        _rejectHostAuthentication(admission);
        return;
      }
      message = decoded;
    } catch (_) {
      _rejectHostAuthentication(admission);
      return;
    }

    if (message['type'] != 'auth') {
      _rejectHostAuthentication(admission, closeCode: 4002, closeReason: 'Authentication required');
      return;
    }

    final authTag = message['authTag'];
    final clientNonceB64 = message['clientNonce'];
    final userUuid = message['userUUID'];
    final clientIdentifier = message['clientIdentifier'];
    final deviceName = message['deviceName'];
    final platform = message['platform'];
    final authContextIdValue = message['authContextId'];
    if (authTag is! String ||
        clientNonceB64 is! String ||
        userUuid is! String ||
        clientIdentifier is! String ||
        deviceName is! String ||
        platform is! String ||
        (authContextIdValue != null && authContextIdValue is! String)) {
      _rejectHostAuthentication(admission);
      return;
    }

    late final List<int> clientNonce;
    try {
      clientNonce = base64Decode(clientNonceB64);
    } catch (_) {
      _rejectHostAuthentication(admission);
      return;
    }
    if (clientNonce.length != 32) {
      _rejectHostAuthentication(admission);
      return;
    }

    final authContextId = authContextIdValue as String?;
    RemoteAuthContext? selectedContext;
    if (authContextId != null && authContextId.isNotEmpty) {
      for (final context in authContexts) {
        if (context.id == authContextId) {
          selectedContext = context;
          break;
        }
      }
    } else if (authContexts.length == 1) {
      selectedContext = primaryContext;
    }

    if (selectedContext == null ||
        (selectedContext.allowedUserUuids.isNotEmpty && !selectedContext.allowedUserUuids.contains(userUuid))) {
      _rejectHostAuthentication(admission);
      return;
    }
    final authenticatedContext = selectedContext;

    final valid = RemoteAuthService.instance.verifyAuthTag(
      authTag: authTag,
      homeSecret: authenticatedContext.homeSecret,
      hostNonce: hostNonce,
      clientNonce: clientNonce,
      hostClientId: authenticatedContext.clientIdentifier,
      userUUID: userUuid,
      clientIdentifier: clientIdentifier,
      deviceName: deviceName,
      platform: platform,
    );
    if (!valid) {
      _rejectHostAuthentication(admission);
      return;
    }

    admission.authTimer?.cancel();
    admission.authTimer = null;
    _failedAuthAttempts.remove(admission.sourceIp);

    late final List<int> sessionEncKey;
    try {
      sessionEncKey = await _deriveSessionEncKey(authenticatedContext.homeSecret, hostNonce, clientNonce);
    } catch (e, stackTrace) {
      appLogger.e('CompanionRemote: Failed to derive session key', error: e, stackTrace: stackTrace);
      await _closeHostAdmissionSocket(admission, code: 4003, reason: 'Authentication failed');
      return;
    }

    await _serializeHostAuthenticationCommit(
      () => _commitAuthenticatedHostAdmission(
        admission: admission,
        sessionEncKey: sessionEncKey,
        selectedContext: authenticatedContext,
        deviceName: deviceName,
        platform: platform,
        hostDeviceName: hostDeviceName,
        hostPlatform: hostPlatform,
      ),
    );
  }

  Future<void> _serializeHostAuthenticationCommit(Future<void> Function() commit) {
    final operation = _hostAuthenticationCommitTail.then((_) => commit());
    _hostAuthenticationCommitTail = operation.catchError((Object _, StackTrace _) {});
    return operation;
  }

  Future<void> _commitAuthenticatedHostAdmission({
    required _HostAdmission admission,
    required List<int> sessionEncKey,
    required RemoteAuthContext selectedContext,
    required String deviceName,
    required String platform,
    required String hostDeviceName,
    required String hostPlatform,
  }) async {
    if (!_isHostAdmissionLive(admission, phase: _HostAdmissionPhase.authenticating)) {
      await _closeHostAdmissionSocket(admission);
      return;
    }

    final previousAdmission = _currentHostAdmission;
    if (previousAdmission != null && !identical(previousAdmission, admission)) {
      appLogger.d('CompanionRemote: Replacing existing client connection');
      await _retireReplacedHostAdmission(previousAdmission);
    }
    if (!_isHostAdmissionLive(admission, phase: _HostAdmissionPhase.authenticating)) {
      await _closeHostAdmissionSocket(admission);
      return;
    }

    final commitGeneration = ++_authenticationCommitGeneration;
    admission.commitGeneration = commitGeneration;
    admission.phase = _HostAdmissionPhase.authenticated;
    _currentHostAdmission = admission;
    _clientSocket = admission.socket;
    _sessionEncKey = sessionEncKey;
    _sendCounter = 0;
    _recvCounter = 0;
    _isAuthenticated = true;
    _selectedAuthContextId = selectedContext.id;
    _selectedHostClientId = selectedContext.clientIdentifier;

    appLogger.d('CompanionRemote: Client authenticated: $deviceName ($platform)');
    try {
      await _sendEncryptedToSocket(admission.socket!, jsonEncode({'type': 'authSuccess'}));
    } catch (e, stackTrace) {
      appLogger.e('CompanionRemote: Failed to send authentication result', error: e, stackTrace: stackTrace);
      await _closeHostAdmissionSocket(admission);
      return;
    }
    if (!_isHostAdmissionLive(
      admission,
      phase: _HostAdmissionPhase.authenticated,
      commitGeneration: commitGeneration,
    )) {
      await _closeHostAdmissionSocket(admission);
      return;
    }

    final device = RemoteDevice(id: 'remote-client', name: deviceName, platform: platform, connectedAt: DateTime.now());
    _deviceConnectedController.add(device);
    _connectionStateController.add(RemoteSessionStatus.connected);
    sendDeviceInfo(hostDeviceName, hostPlatform);
  }

  void _rejectHostAuthentication(
    _HostAdmission admission, {
    int closeCode = 4003,
    String closeReason = 'Authentication failed',
  }) {
    if (admission.phase != _HostAdmissionPhase.authenticating) return;
    admission.phase = _HostAdmissionPhase.terminal;
    admission.authTimer?.cancel();
    admission.authTimer = null;
    _recordFailedAuth(admission.sourceIp);

    // The admission owns and closes this socket.
    // ignore: close_sinks
    final socket = admission.socket;
    if (socket != null && socket.readyState == WebSocket.open) {
      try {
        socket.add(jsonEncode({'type': 'authFailed'}));
      } catch (_) {
        // The generic close below remains the terminal result.
      }
    }
    unawaited(_closeHostAdmissionSocket(admission, code: closeCode, reason: closeReason));
  }

  Future<void> _retireReplacedHostAdmission(_HostAdmission admission) async {
    admission.phase = _HostAdmissionPhase.terminal;
    admission.authTimer?.cancel();
    admission.authTimer = null;
    _clearHostSessionIfOwned(admission, notify: false);
    final subscription = admission.subscription;
    admission.subscription = null;
    await _runDisconnectCleanup(subscription?.cancel(), 'replaced client listener');
    unawaited(_closeHostAdmissionSocket(admission, code: 4004, reason: 'Replaced by new connection'));
  }

  Future<void> _closeHostAdmissionSocket(_HostAdmission admission, {int? code, String? reason}) {
    final existing = admission.closeFuture;
    if (existing != null) return existing;
    final closeFuture = _closeHostAdmissionSocketOnce(admission, code: code, reason: reason);
    admission.closeFuture = closeFuture;
    return closeFuture;
  }

  Future<void> _closeHostAdmissionSocketOnce(_HostAdmission admission, {int? code, String? reason}) async {
    admission.phase = _HostAdmissionPhase.terminal;
    admission.authTimer?.cancel();
    admission.authTimer = null;
    final socket = admission.socket;
    if (socket != null) {
      await _runDisconnectCleanup(socket.close(code, reason), 'host socket');
    }
    _releaseHostAdmission(admission);
  }

  void _releaseHostAdmission(_HostAdmission admission) {
    if (admission.released) return;
    admission.released = true;
    admission.phase = _HostAdmissionPhase.terminal;
    admission.authTimer?.cancel();
    admission.authTimer = null;

    final subscription = admission.subscription;
    admission.subscription = null;
    if (subscription != null) {
      unawaited(_runDisconnectCleanup(subscription.cancel(), 'host listener'));
    }

    if (_hostAdmissions.remove(admission)) {
      _hostAdmissionCount--;
      final sourceCount = (_hostAdmissionsBySource[admission.sourceIp] ?? 1) - 1;
      if (sourceCount <= 0) {
        _hostAdmissionsBySource.remove(admission.sourceIp);
      } else {
        _hostAdmissionsBySource[admission.sourceIp] = sourceCount;
      }
    }

    _clearHostSessionIfOwned(admission, notify: !_isDisconnecting);
    admission.completeTerminal();
  }

  void _clearHostSessionIfOwned(_HostAdmission admission, {required bool notify}) {
    if (!identical(_currentHostAdmission, admission)) return;
    _currentHostAdmission = null;
    _clientSocket = null;
    _sessionEncKey = null;
    _isAuthenticated = false;
    _selectedAuthContextId = null;
    _selectedHostClientId = null;
    stopKeepalive();
    if (notify) {
      _deviceDisconnectedController.add(null);
      _connectionStateController.add(RemoteSessionStatus.disconnected);
    }
  }

  void _recordFailedAuth(String sourceIp) {
    final attempts = (_failedAuthAttempts[sourceIp] ?? 0) + 1;
    _failedAuthAttempts[sourceIp] = attempts;
    if (attempts >= _maxFailedAuthAttempts) {
      _authLockouts[sourceIp] = DateTime.now().add(_authLockoutDuration);
      appLogger.w('CompanionRemote: IP $sourceIp locked out for ${_authLockoutDuration.inSeconds}s');
    }
  }

  bool _ownsRemoteChannel(IOWebSocketChannel channel, int generation) {
    return !_disposed && generation == _remoteConnectionGeneration && identical(_channel, channel);
  }

  /// Closes the managed channel without ever awaiting a `sink.close()` on a
  /// connection that never established. web_socket_channel 3.x completes that
  /// close future only after the connect-success path attaches the channel's
  /// internal stream listener; on a pending or failed connect it never
  /// completes, and awaiting it hung disconnects and join timeouts forever
  /// (#2077). An unestablished channel is instead closed whenever its
  /// connection settles, which also covers a connect that succeeds late.
  Future<void> _closeManagedChannel(IOWebSocketChannel channel) async {
    if (_channelConnected && identical(_channel, channel)) {
      await channel.sink.close();
      return;
    }
    unawaited(channel.ready.then((_) => channel.sink.close(), onError: (Object _) {}));
  }

  /// Join a host session with any local auth context that the host also supports.
  Future<void> joinSessionWithContexts(
    String deviceName,
    String platform,
    String hostAddress,
    List<RemoteAuthContext> authContexts, {
    String? authContextId,
    String expectedHostClientId = '',
  }) async {
    if (authContexts.isEmpty) {
      throw RemotePeerError(
        type: RemotePeerErrorType.authFailed,
        message: t.companionRemote.errors.authenticationFailed,
      );
    }

    if (_channel != null) {
      await disconnect();
    }
    final connectionGeneration = ++_remoteConnectionGeneration;

    _role = RemoteSessionRole.remote;
    _hostAddress = hostAddress;
    _myPeerId = 'remote-${Random.secure().nextInt(99999)}';

    final completer = Completer<void>();
    final auth = RemoteAuthService.instance;
    IOWebSocketChannel? attemptedChannel;

    try {
      final url = 'ws://$hostAddress/ws';
      appLogger.d('CompanionRemote: Connecting to $url');

      _connectionStateController.add(RemoteSessionStatus.connecting);

      final channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        connectTimeout: _remoteConnectTimeout,
        customClient: happyEyeballsHttpClient,
      );
      attemptedChannel = channel;
      _channel = channel;
      _channelConnected = false;
      try {
        await channel.ready;
      } on TimeoutException {
        throw RemotePeerError(type: RemotePeerErrorType.timeout, message: t.companionRemote.errors.joinTimedOut);
      }
      if (!_ownsRemoteChannel(channel, connectionGeneration)) {
        unawaited(channel.sink.close());
        throw StateError('Companion Remote connection attempt became stale');
      }
      _channelConnected = true;

      List<int>? hostNonce;
      List<int>? clientNonce;
      String? receivedHostClientId;

      _channelSubscription = channel.stream.listen(
        (data) async {
          if (!_ownsRemoteChannel(channel, connectionGeneration)) return;
          try {
            if (_isAuthenticated) {
              await _handleEncryptedCommand(data);
            } else if (_sessionEncKey != null) {
              // Keys derived, waiting for encrypted authSuccess
              final decrypted = await _decryptIncoming(data);
              if (decrypted == null || !_ownsRemoteChannel(channel, connectionGeneration)) return;

              final json = jsonDecode(decrypted) as Map<String, dynamic>;
              if (json['type'] == 'authSuccess') {
                _isAuthenticated = true;
                appLogger.d('CompanionRemote: Authentication successful');

                if (!completer.isCompleted) {
                  completer.complete();
                }

                final device = RemoteDevice(
                  id: 'host',
                  name: 'Desktop',
                  platform: 'desktop',
                  connectedAt: DateTime.now(),
                );
                _deviceConnectedController.add(device);
                _connectionStateController.add(RemoteSessionStatus.connected);

                sendDeviceInfo(deviceName, platform);
                startKeepalive();
              } else if (json['type'] == 'authFailed') {
                if (!completer.isCompleted) {
                  completer.completeError(
                    RemotePeerError(
                      type: RemotePeerErrorType.authFailed,
                      message: t.companionRemote.errors.authenticationFailed,
                    ),
                  );
                }
              }
            } else {
              // Pre-auth: plaintext handshake
              final json = jsonDecode(data as String) as Map<String, dynamic>;
              final messageType = json['type'] as String?;

              if (messageType == 'challenge') {
                hostNonce = base64Decode(json['nonce'] as String);
                final legacyHostClientId = json['hostClientId'] as String? ?? '';
                final challengeContextHostIds = <String, String>{};
                final challengeContexts = json['authContexts'] as List<dynamic>? ?? const [];
                for (final item in challengeContexts) {
                  if (item is! Map) continue;
                  final id = item['id'] as String?;
                  final hostClientId = item['hostClientId'] as String?;
                  if (id != null && id.isNotEmpty && hostClientId != null && hostClientId.isNotEmpty) {
                    challengeContextHostIds[id] = hostClientId;
                  }
                }

                RemoteAuthContext? selectedContext;
                if (authContextId != null && authContextId.isNotEmpty) {
                  for (final context in authContexts) {
                    if (context.id == authContextId) {
                      selectedContext = context;
                      break;
                    }
                  }
                } else if (challengeContextHostIds.isNotEmpty) {
                  for (final context in authContexts) {
                    if (challengeContextHostIds.containsKey(context.id)) {
                      selectedContext = context;
                      break;
                    }
                  }
                } else {
                  selectedContext = authContexts.first;
                }

                if (selectedContext == null ||
                    (challengeContextHostIds.isNotEmpty && !challengeContextHostIds.containsKey(selectedContext.id))) {
                  appLogger.w('CompanionRemote: No shared auth context with host');
                  if (!completer.isCompleted) {
                    completer.completeError(
                      RemotePeerError(
                        type: RemotePeerErrorType.authFailed,
                        message: t.companionRemote.errors.authenticationFailed,
                      ),
                    );
                  }
                  unawaited(channel.sink.close(4003, 'Authentication failed'));
                  return;
                }

                receivedHostClientId = challengeContextHostIds[selectedContext.id] ?? legacyHostClientId;
                clientNonce = auth.generateNonce();

                if (expectedHostClientId.isNotEmpty && receivedHostClientId != expectedHostClientId) {
                  appLogger.w('CompanionRemote: Host client ID mismatch');
                  if (!completer.isCompleted) {
                    completer.completeError(
                      RemotePeerError(
                        type: RemotePeerErrorType.authFailed,
                        message: t.companionRemote.errors.authenticationFailed,
                      ),
                    );
                  }
                  unawaited(channel.sink.close(4003, 'Authentication failed'));
                  return;
                }

                final authTag = auth.computeAuthTag(
                  homeSecret: selectedContext.homeSecret,
                  hostNonce: hostNonce!,
                  clientNonce: clientNonce!,
                  hostClientId: receivedHostClientId!,
                  userUUID: selectedContext.userUuid,
                  clientIdentifier: selectedContext.clientIdentifier,
                  deviceName: deviceName,
                  platform: platform,
                );

                channel.sink.add(
                  jsonEncode({
                    'type': 'auth',
                    'authContextId': selectedContext.id,
                    'clientNonce': base64Encode(clientNonce!),
                    'userUUID': selectedContext.userUuid,
                    'clientIdentifier': selectedContext.clientIdentifier,
                    'deviceName': deviceName,
                    'platform': platform,
                    'authTag': authTag,
                  }),
                );

                final sessionEncKey = await auth.deriveSessionEncKey(
                  selectedContext.homeSecret,
                  hostNonce!,
                  clientNonce!,
                );
                if (!_ownsRemoteChannel(channel, connectionGeneration)) return;
                _sessionEncKey = sessionEncKey;
                _sendCounter = 0;
                _recvCounter = 0;
                _selectedAuthContextId = selectedContext.id;
                _selectedHostClientId = receivedHostClientId;
              } else if (messageType == 'authFailed') {
                appLogger.w('CompanionRemote: Authentication failed');
                if (!completer.isCompleted) {
                  completer.completeError(
                    RemotePeerError(
                      type: RemotePeerErrorType.authFailed,
                      message: t.companionRemote.errors.authenticationFailed,
                    ),
                  );
                }
                _errorController.add(
                  RemotePeerError(
                    type: RemotePeerErrorType.authFailed,
                    message: t.companionRemote.errors.authenticationFailed,
                  ),
                );
                _connectionStateController.add(RemoteSessionStatus.error);
              }
            }
          } catch (e) {
            appLogger.e('CompanionRemote: Failed to parse message', error: e);
          }
        },
        onDone: () {
          if (!_ownsRemoteChannel(channel, connectionGeneration)) return;
          appLogger.d('CompanionRemote: Connection closed');
          if (!completer.isCompleted) {
            completer.completeError(
              RemotePeerError(
                type: RemotePeerErrorType.connectionFailed,
                message: t.companionRemote.pairing.failedToConnect(error: t.companionRemote.closedBeforeAuth),
              ),
            );
          }
          _deviceDisconnectedController.add(null);
          _connectionStateController.add(RemoteSessionStatus.disconnected);
          _isAuthenticated = false;
          _channel = null;
          _channelConnected = false;
          _channelSubscription = null;
          _sessionEncKey = null;
          _selectedAuthContextId = null;
          _selectedHostClientId = null;
          stopKeepalive();
        },
        onError: (error) {
          if (!_ownsRemoteChannel(channel, connectionGeneration)) return;
          appLogger.e('CompanionRemote: Connection error', error: error);

          final wasAuthenticated = _isAuthenticated;
          if (!completer.isCompleted) {
            completer.completeError(error);
          }

          _isAuthenticated = false;
          _channel = null;
          _channelConnected = false;
          _channelSubscription = null;
          _sessionEncKey = null;
          _selectedAuthContextId = null;
          _selectedHostClientId = null;
          stopKeepalive();

          if (wasAuthenticated) {
            // A socket error on an established session (connection reset after
            // Android backgrounding, Wi-Fi power save, network handoff) is a
            // disconnect, not a terminal failure: surface it exactly like
            // onDone so the owner runs its reconnect flow instead of dropping
            // the user back to discovery.
            _deviceDisconnectedController.add(null);
            _connectionStateController.add(RemoteSessionStatus.disconnected);
          } else {
            _errorController.add(
              RemotePeerError(
                type: RemotePeerErrorType.connectionFailed,
                message: t.companionRemote.pairing.failedToConnect(error: error.toString()),
                originalError: error,
              ),
            );
            _connectionStateController.add(RemoteSessionStatus.error);
          }
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      final channel = attemptedChannel;
      if (channel != null && _ownsRemoteChannel(channel, connectionGeneration)) {
        appLogger.e('CompanionRemote: Failed to connect', error: e);
        _errorController.add(
          RemotePeerError(
            type: RemotePeerErrorType.connectionFailed,
            message: t.companionRemote.pairing.failedToConnect(error: e.toString()),
            originalError: e,
          ),
        );
      }
    }

    final channel = attemptedChannel;
    if (channel == null) return completer.future;

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () async {
        if (_ownsRemoteChannel(channel, connectionGeneration)) {
          try {
            await _closeManagedChannel(channel);
          } catch (e) {
            appLogger.d('CompanionRemote: channel close on timeout failed', error: e);
          }
          if (_ownsRemoteChannel(channel, connectionGeneration)) {
            _channel = null;
            _channelConnected = false;
          }
        }
        throw RemotePeerError(type: RemotePeerErrorType.timeout, message: t.companionRemote.errors.joinTimedOut);
      },
    );
  }

  /// Race WebSocket connections and authenticate with the selected shared identity.
  Future<String> joinSessionRacingWithContexts(
    String deviceName,
    String platform,
    List<String> hostAddresses,
    List<RemoteAuthContext> authContexts, {
    String? authContextId,
    String expectedHostClientId = '',
  }) async {
    if (authContexts.isEmpty) {
      throw RemotePeerError(
        type: RemotePeerErrorType.authFailed,
        message: t.companionRemote.errors.authenticationFailed,
      );
    }

    if (hostAddresses.length == 1) {
      await joinSessionWithContexts(
        deviceName,
        platform,
        hostAddresses.first,
        authContexts,
        authContextId: authContextId,
        expectedHostClientId: expectedHostClientId,
      );
      return hostAddresses.first;
    }

    appLogger.d('CompanionRemote: Racing connections to ${hostAddresses.length} addresses');

    // Race: try to connect to all addresses, first one to get a challenge wins
    final completer = Completer<String>();
    final probes = <_RemoteAddressProbe>[];

    Future<void> cleanup() async {
      // A probe consumes a host admission slot until its WebSocket has fully
      // closed. Finish every cancellation and close before opening the managed
      // connection so probes cannot reject that connection at the per-source
      // limit. Cleanup errors are intentionally logged in address order and
      // never replace the race/authentication result.
      for (final probe in probes) {
        await probe.close();
      }
    }

    for (final address in hostAddresses) {
      _RaceProbeConnection? connection;
      try {
        final url = 'ws://$address/ws';
        connection = _raceProbeFactory(Uri.parse(url));

        // Losing candidates fail their `ready` future (connect timeout,
        // no route to host, …); nothing awaits it here — the stream's
        // onError below is the visible signal — so swallow it or every
        // unreachable address becomes an unhandled async error. Success is
        // tracked so cleanup can skip the terminal wait for a candidate
        // that never connected (it holds no host admission slot).
        var connected = false;
        unawaited(
          connection.ready.then(
            (_) {
              connected = true;
            },
            onError: (Object e) {
              appLogger.d('CompanionRemote: race candidate $address failed to connect', error: e);
            },
          ),
        );

        probes.add(
          _RemoteAddressProbe(
            requestClose: connection.close,
            isConnected: () => connected,
            stream: connection.stream,
            onData: (data) {
              try {
                final json = jsonDecode(data as String) as Map<String, dynamic>;
                // First address to send us a challenge wins the race
                if (json['type'] == 'challenge' && !completer.isCompleted) {
                  appLogger.d('CompanionRemote: Race winner: $address');
                  completer.complete(address);
                }
              } catch (e) {
                appLogger.d('CompanionRemote: race message parse skipped', error: e);
              }
            },
          ),
        );
      } catch (e) {
        appLogger.d('CompanionRemote: Race candidate $address failed to start: $e');
        if (connection != null) {
          try {
            await connection.close();
          } catch (closeError) {
            appLogger.d('CompanionRemote: failed race candidate close ignored', error: closeError);
          }
        }
      }
    }

    if (probes.isEmpty) {
      throw RemotePeerError(
        type: RemotePeerErrorType.connectionFailed,
        message: t.companionRemote.errors.failedToConnectAnyAddress,
      );
    }

    try {
      final winner = await completer.future.namedTimeout(
        const Duration(seconds: 10),
        operation: 'CompanionRemote race connect',
      );
      await cleanup();

      // Set up the proper managed connection on the winning address
      await joinSessionWithContexts(
        deviceName,
        platform,
        winner,
        authContexts,
        authContextId: authContextId,
        expectedHostClientId: expectedHostClientId,
      );
      return winner;
    } on TimeoutException {
      await cleanup();
      throw RemotePeerError(type: RemotePeerErrorType.timeout, message: t.companionRemote.errors.joinTimedOut);
    }
  }

  // ── Encrypted send/receive ──

  // Serialize cryptographic operations so implicit nonce counters cannot
  // interleave when stream callbacks overlap.
  final SerialFutureQueue _encryptQueue = SerialFutureQueue();
  final SerialFutureQueue _decryptQueue = SerialFutureQueue();
  final SerialFutureQueue _sendQueue = SerialFutureQueue();

  Future<List<int>> _encryptOutgoing(String plaintext) {
    return _encryptQueue.run(() async {
      final encrypted = await RemoteAuthService.instance.encrypt(
        _sessionEncKey!,
        utf8.encode(plaintext),
        isHost: _role == RemoteSessionRole.host,
        counter: _sendCounter,
      );
      _sendCounter++;
      return encrypted;
    });
  }

  Future<void> _sendEncryptedToSocket(WebSocket socket, String plaintext) async {
    if (_sessionEncKey == null) return;
    final encrypted = await _encryptOutgoing(plaintext);
    socket.add(encrypted);
  }

  Future<String?> _decryptIncoming(dynamic data) {
    if (_sessionEncKey == null) return Future<String?>.value();
    return _decryptQueue.run(() => _decryptIncomingNow(data));
  }

  Future<String?> _decryptIncomingNow(dynamic data) async {
    try {
      final bytes = data is List<int> ? data : utf8.encode(data as String);
      final decrypted = await RemoteAuthService.instance.decrypt(
        bytes,
        _sessionEncKey!,
        fromHost: _role == RemoteSessionRole.remote,
        expectedCounter: _recvCounter,
      );
      _recvCounter++;
      return utf8.decode(decrypted);
    } catch (e) {
      appLogger.e('CompanionRemote: Decryption failed (counter=$_recvCounter)', error: e);
      return null;
    }
  }

  Future<void> _handleEncryptedCommand(dynamic data) async {
    final decrypted = await _decryptIncoming(data);
    if (decrypted == null) return;

    final command = RemoteCommand.fromJson(jsonDecode(decrypted) as Map<String, dynamic>);
    appLogger.d('CompanionRemote: Received command: ${command.type}');

    if (_shouldSendAck(command)) {
      _sendAck(command);
    }
    _commandReceivedController.add(command);

    if (command.type == RemoteCommandType.ping) {
      _sendPong();
    }
  }

  // ── Commands ──

  @override
  void sendPing() {
    if (isConnected) {
      sendCommand(const RemoteCommand(type: RemoteCommandType.ping));
    }
  }

  @override
  void onPongTimeout() {
    // Not used — pong timeout is disabled for companion remote.
  }

  bool _shouldSendAck(RemoteCommand command) {
    return command.type != RemoteCommandType.ping &&
        command.type != RemoteCommandType.pong &&
        command.type != RemoteCommandType.ack &&
        command.type != RemoteCommandType.deviceInfo;
  }

  void _sendAck(RemoteCommand _) {
    sendCommand(const RemoteCommand(type: RemoteCommandType.ack));
  }

  void _sendPong() {
    sendCommand(const RemoteCommand(type: RemoteCommandType.pong));
  }

  void sendDeviceInfo(String deviceName, String platform) {
    sendCommand(
      RemoteCommand(
        type: RemoteCommandType.deviceInfo,
        data: {'id': _myPeerId, 'name': deviceName, 'platform': platform, 'role': _role?.name},
      ),
    );
  }

  void sendCommand(RemoteCommand command) {
    if (_sessionEncKey == null || !_isAuthenticated) {
      appLogger.w('CompanionRemote: No connection to send command');
      return;
    }

    // Chain sends to prevent counter interleaving from concurrent async encrypts
    _sendQueue.run(() async {
      try {
        final json = jsonEncode(command.toJson());
        final encrypted = await _encryptOutgoing(json);

        if (_role == RemoteSessionRole.host && _clientSocket != null) {
          _clientSocket!.add(encrypted);
        } else if (_role == RemoteSessionRole.remote && _channel != null) {
          _channel!.sink.add(encrypted);
        }
        appLogger.d('CompanionRemote: Sent command: ${command.type}');
      } catch (e) {
        appLogger.e('CompanionRemote: Failed to send command', error: e);
        _errorController.add(
          RemotePeerError(
            type: RemotePeerErrorType.dataChannelError,
            message: t.companionRemote.errors.commandFailed(error: e.toString()),
            originalError: e,
          ),
        );
      }
    });
  }

  Future<void> _runDisconnectCleanup(Future<dynamic>? operation, String name) async {
    if (operation == null) return;
    try {
      await operation;
    } catch (e) {
      appLogger.d('CompanionRemote: $name cleanup ignored', error: e);
    }
  }

  Future<void> disconnect() {
    if (_disposed) return Future<void>.value();
    final existing = _disconnectInProgress;
    if (existing != null) return existing;

    late final Future<void> tracked;
    tracked = _disconnect().whenComplete(() {
      if (identical(_disconnectInProgress, tracked)) {
        _disconnectInProgress = null;
      }
    });
    _disconnectInProgress = tracked;
    return tracked;
  }

  Future<void> _disconnect() async {
    appLogger.d('CompanionRemote: Disconnecting');
    _remoteConnectionGeneration++;

    _acceptingHostConnections = false;
    _isDisconnecting = true;
    _isAuthenticated = false;
    _authenticationCommitGeneration++;
    stopKeepalive();

    final channel = _channel;
    final server = _server;
    _server = null;
    final serverClose = server?.close(force: true);
    final admissions = List<_HostAdmission>.of(_hostAdmissions);

    try {
      await Future.wait(admissions.map(_shutdownHostAdmission));

      await _runDisconnectCleanup(_channelSubscription?.cancel(), 'channel listener');
      _channelSubscription = null;

      // Decrypted commands may enqueue acknowledgements, and sends enqueue
      // encryption, so drain in dependency order.
      await _decryptQueue.settled;
      await _sendQueue.settled;
      await _encryptQueue.settled;

      await _runDisconnectCleanup(channel == null ? null : _closeManagedChannel(channel), 'channel');
      await _runDisconnectCleanup(serverClose, 'server');
    } finally {
      for (final admission in List<_HostAdmission>.of(_hostAdmissions)) {
        _releaseHostAdmission(admission);
      }
      _hostAdmissions.clear();
      _hostAdmissionsBySource.clear();
      _hostAdmissionCount = 0;
      _currentHostAdmission = null;
      _clientSocket = null;
      _channel = null;
      _channelConnected = false;
      _myPeerId = null;
      _hostAddress = null;
      _role = null;
      _selectedAuthContextId = null;
      _selectedHostClientId = null;
      _sessionEncKey = null;
      _sendCounter = 0;
      _recvCounter = 0;
      _sendQueue.reset();
      _encryptQueue.reset();
      _decryptQueue.reset();
      _failedAuthAttempts.clear();
      _authLockouts.clear();
      _isDisconnecting = false;

      _connectionStateController.add(RemoteSessionStatus.disconnected);
    }
  }

  Future<void> _shutdownHostAdmission(_HostAdmission admission) async {
    admission.phase = _HostAdmissionPhase.terminal;
    admission.authTimer?.cancel();
    admission.authTimer = null;

    await admission.upgradeFinished.future;
    if (admission.released) return;

    final subscription = admission.subscription;
    final socketClose = _closeHostAdmissionSocket(admission);
    admission.subscription = null;
    await _runDisconnectCleanup(subscription?.cancel(), 'host listener');
    await socketClose;
    await admission.terminal.future;
  }

  /// Whether the HTTP server is currently running.
  bool get isServerRunning => _server != null;

  Future<void> dispose() {
    final existing = _disposeInProgress;
    if (existing != null) return existing;
    if (_disposed) return Future<void>.value();

    late final Future<void> tracked;
    tracked = _dispose().whenComplete(() {
      if (identical(_disposeInProgress, tracked)) {
        _disposeInProgress = null;
      }
    });
    _disposeInProgress = tracked;
    return tracked;
  }

  Future<void> _dispose() async {
    await disconnect();
    await _commandReceivedController.close();
    await _deviceConnectedController.close();
    await _deviceDisconnectedController.close();
    await _errorController.close();
    await _connectionStateController.close();
    _disposed = true;
  }
}

class _RemoteAddressProbe {
  _RemoteAddressProbe({
    required this._requestClose,
    required this._isConnected,
    required Stream<dynamic> stream,
    required void Function(dynamic data) onData,
  }) {
    _subscription = stream.listen(
      onData,
      onError: (Object _, StackTrace _) => _completeTerminal(),
      onDone: _completeTerminal,
    );
  }

  static const _terminalTimeout = Duration(seconds: 5);

  final Future<void> Function() _requestClose;
  final bool Function() _isConnected;
  final Completer<void> _terminal = Completer<void>();
  late final StreamSubscription<dynamic> _subscription;

  void _completeTerminal() {
    if (!_terminal.isCompleted) {
      _terminal.complete();
    }
  }

  Future<void> close() async {
    try {
      await _requestClose();
    } catch (error) {
      appLogger.d('CompanionRemote: race candidate close ignored', error: error);
    }
    // The terminal wait drains a connected probe's WebSocket so its host
    // admission slot is free before the managed connection opens. A candidate
    // that never connected holds no slot, and its stream only settles once
    // its connect timeout fires — waiting here would stall the managed join
    // for seconds per unreachable address (#2077).
    if (_isConnected()) {
      try {
        await _terminal.future.timeout(_terminalTimeout);
      } on TimeoutException catch (error) {
        appLogger.d('CompanionRemote: race candidate terminal close timed out', error: error);
      }
    }
    try {
      await _subscription.cancel();
    } catch (error) {
      appLogger.d('CompanionRemote: race candidate listener cleanup ignored', error: error);
    }
  }
}

enum _HostAdmissionPhase { upgrading, awaitingAuth, authenticating, authenticated, terminal }

class _HostAdmission {
  _HostAdmission({required this.sourceIp, required this.server});

  final String sourceIp;
  final HttpServer server;
  final Completer<void> upgradeFinished = Completer<void>();
  final Completer<void> terminal = Completer<void>();

  WebSocket? socket;
  StreamSubscription<dynamic>? subscription;
  Timer? authTimer;
  _HostAdmissionPhase phase = _HostAdmissionPhase.upgrading;
  int? commitGeneration;
  bool released = false;
  Future<void>? closeFuture;

  void completeUpgrade() {
    if (!upgradeFinished.isCompleted) {
      upgradeFinished.complete();
    }
  }

  void completeTerminal() {
    if (!terminal.isCompleted) {
      terminal.complete();
    }
  }
}
