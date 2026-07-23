import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/data/hid_key_labels.dart';
import 'package:plezy/models/hotkey_model.dart';

void main() {
  test('catalog preserves all 325 unique keys in canonical numeric order', () {
    final ids = hidKeyLabels.keys.toList();
    final sortedIds = [...ids]..sort();

    expect(hidKeyLabels, hasLength(325));
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, sortedIds);
    expect(ids.every((id) => id >= 0 && id <= 0xffffffff), isTrue);
    expect(hidKeyLabels.values.every((label) => label.trim().isNotEmpty), isTrue);
  });

  test('catalog preserves representative labels across usage groups', () {
    expect(hidKeyLabels[0x00000012], 'Fn');
    expect(hidKeyLabels[0x000100b5], 'Display Toggle');
    expect(hidKeyLabels[0x0005ff1f], 'Game Button Z');
    expect(hidKeyLabels[0x00070031], r'\');
    expect(hidKeyLabels[0x000c00cd], 'Play/Pause');
    expect(hidKeyLabels[0x000c029f], 'Show All Windows');
  });

  test('physicalKeyLabel uses the catalog and formats an unknown HID fallback', () {
    expect(physicalKeyLabel(PhysicalKeyboardKey.keyA), 'A');
    expect(physicalKeyLabel(const PhysicalKeyboardKey(0xffffffff)), 'Key 0xffffffff');
  });
}
