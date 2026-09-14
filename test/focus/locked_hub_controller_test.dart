import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/locked_hub_controller.dart';

void main() {
  test('focus memory and last-column hint are isolated per browse owner', () {
    final ownerA = HubFocusMemory();
    final ownerB = HubFocusMemory();

    ownerA.setForHub('detail_episodes', 7);

    expect(ownerA.getForHubOnly('detail_episodes', 5), 4);
    expect(ownerA.getForHub('detail_episodes', 3), 2);
    expect(ownerA.getForHub('detail_extras', 4), 3);

    expect(ownerB.getForHubOnly('detail_episodes', 5), 0);
    expect(ownerB.getForHub('detail_episodes', 5), 0);
    expect(ownerB.getForHub('detail_extras', 5), 0);
  });

  test('per-hub fallback and empty rows keep their existing clamping behavior', () {
    final memory = HubFocusMemory();

    expect(memory.getForHubOnly('unseen', 3, fallback: 9), 2);
    expect(memory.getForHubOnly('unseen', 0, fallback: 9), 0);
    expect(memory.getForHub('unseen', 0), 0);
  });

  test('remapForHub rewrites an existing entry without moving the column hint', () {
    final memory = HubFocusMemory();

    memory.setForHub('continue_watching', 3);
    memory.remapForHub('continue_watching', 0);

    expect(memory.getForHubOnly('continue_watching', 5), 0);
    // The cross-hub column hint still reflects the user's last navigation.
    expect(memory.getForHub('unseen_hub', 5), 3);
  });

  test('remapForHub is a no-op for hubs without memory', () {
    final memory = HubFocusMemory();

    memory.remapForHub('unseen_hub', 4);

    expect(memory.getForHubOnly('unseen_hub', 5, fallback: 1), 1);
  });
}
