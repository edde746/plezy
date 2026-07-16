import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/utils/active_client_scope.dart';

void main() {
  final serverId = ServerId('jf-machine');

  group('resolveActiveClientScopeId', () {
    test('returns null before a client is bound', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: null), isNull);
    });

    test('rejects an empty cache scope', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: ''), isNull);
    });

    test('rejects the bare server scope', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine'), isNull);
    });

    test('rejects empty and foreign compound scopes', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine/'), isNull);
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'other-machine/user-a'), isNull);
    });

    test('keeps users on the same server in distinct active scopes', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine/user-a'), 'jf-machine/user-a');
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine/user-b'), 'jf-machine/user-b');
    });
  });
}
