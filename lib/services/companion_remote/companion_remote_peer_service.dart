/// Conditional export for CompanionRemotePeerService.
///
/// On native platforms, uses dart:io HttpServer/WebSocket for hosting + IOWebSocketChannel for joining.
/// On web, uses WebSocketChannel for joining only (hosting not supported in browsers).
export 'companion_remote_peer_service_native.dart'
    if (dart.library.js_interop) 'companion_remote_peer_service_web.dart';
