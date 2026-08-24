import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/hotkey_model.dart';

void main() {
  test('physicalKeyLabel uses the catalog and formats an unknown HID fallback', () {
    expect(physicalKeyLabel(PhysicalKeyboardKey.keyA), 'A');
    expect(physicalKeyLabel(const PhysicalKeyboardKey(0xffffffff)), 'Key 0xffffffff');
  });
}
