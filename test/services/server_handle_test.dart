import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/server_handle.dart';

/// A registry whose answer can change between calls, which is the whole point
/// of the type under test.
class _MutableRegistry implements MediaServerRegistry {
  final Map<String, MediaServerClient?> clients = {};
  int lookups = 0;

  @override
  MediaServerClient? getClient(ServerId serverId) {
    lookups++;
    return clients[serverId.value];
  }
}

class _FakeClient implements MediaServerClient {
  _FakeClient(this.label);
  final String label;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MutableRegistry registry;

  setUp(() => registry = _MutableRegistry());

  ServerHandle handle([String id = 'srv-1']) => ServerHandle(serverId: id, registry: registry);

  test('resolves through the registry on every read, never caching', () {
    final first = _FakeClient('first');
    registry.clients['srv-1'] = first;
    final subject = handle();

    expect(subject.client, same(first));

    final second = _FakeClient('second');
    registry.clients['srv-1'] = second;

    expect(subject.client, same(second), reason: 'a handle must follow the swap, not hold the old instance');
    expect(registry.lookups, 2);
  });
}
