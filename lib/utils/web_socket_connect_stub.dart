import 'package:web_socket_channel/web_socket_channel.dart';

/// Web fallback: the browser owns the transport, so there is no client to
/// bound or cancel; selected via conditional import next to
/// `web_socket_connect.dart`.
WebSocketChannel connectWebSocketChannel(Uri uri, {required Duration connectTimeout}) => WebSocketChannel.connect(uri);
