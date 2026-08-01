import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/data/ducet_order.dart';

void main() {
  test('applies CLDR kana ordering', () {
    expect(ducetCompare('ア', 'あ'), isNegative);
    expect(ducetCompare('カ', 'か'), isNegative);
  });

  test('orders representative scripts by DUCET rank', () {
    expect(ducetCompare('A', 'α'), isNegative);
    expect(ducetCompare('α', 'Ж'), isNegative);
    expect(ducetCompare('Ж', '一'), isNegative);
  });

  test('decomposes Kangxi radicals to their unified equivalents', () {
    expect(ducetCompare('⼀', '一'), 0);
    expect(ducetCompare('⿕', '龠'), 0);
  });

  test('uses codepoint fallback for missing BMP and supplementary characters', () {
    expect(ducetCompare('\u0378', '\u0379'), isNegative);
    expect(ducetCompare('\u0378', 'A'), isPositive);
    expect(ducetCompare('😀', '😁'), isNegative);
    expect(ducetCompare('😀', 'A'), isPositive);
  });

  test('preserves apostrophe, backslash, and dollar ranks in generated literal', () {
    expect(ducetCompare("'", r'$'), isNegative);
    expect(ducetCompare(r'$', r'\'), isPositive);
  });

  test('compares only the first rune', () {
    expect(ducetCompare('A trailing text', 'A different text'), 0);
    expect(ducetCompare('😀 trailing text', '😀 different text'), 0);
  });

  test('preserves empty-input failure', () {
    expect(() => ducetCompare('', 'A'), throwsStateError);
    expect(() => ducetCompare('A', ''), throwsStateError);
  });
}
