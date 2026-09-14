import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';

/// Wires [manager] into the provider widget tests read servers from. The caller
/// owns disposal of the returned provider.
MultiServerProvider testMultiServerProvider(MultiServerManager manager) {
  return MultiServerProvider(manager, DataAggregationService(manager));
}

/// Registers [clients] on a fresh manager and returns it with its provider,
/// disposing both when the test ends. Clients also named in [offline] are
/// registered as unreachable; [clients] fixes the registration order.
({MultiServerManager manager, MultiServerProvider provider}) testMultiServer({
  List<MediaServerClient> clients = const [],
  List<MediaServerClient> offline = const [],
}) {
  final manager = MultiServerManager();
  for (final client in clients) {
    manager.debugRegisterClientForTesting(client, online: !offline.contains(client));
  }
  final provider = testMultiServerProvider(manager);
  addTearDown(() {
    provider.dispose();
    manager.dispose();
  });
  return (manager: manager, provider: provider);
}
