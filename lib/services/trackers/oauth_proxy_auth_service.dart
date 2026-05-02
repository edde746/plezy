import 'oauth_proxy_client.dart';

abstract class OAuthProxyAuthServiceBase<T> {
  final OAuthProxyClient proxy;

  OAuthProxyAuthServiceBase({OAuthProxyClient? proxy}) : proxy = proxy ?? OAuthProxyClient();

  String get service;

  T buildSession(OAuthProxyResult result);

  void dispose() => proxy.dispose();

  Future<T?> authorize({
    required void Function(OAuthProxyStart) onCodeReady,
    bool Function()? shouldCancel,
    Future<void>? onCancel,
  }) async {
    final start = await proxy.start(service);
    onCodeReady(start);
    final result = await proxy.poll(start.session, shouldCancel: shouldCancel, onCancel: onCancel);
    if (result == null) return null;
    return buildSession(result);
  }
}
