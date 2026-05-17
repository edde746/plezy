import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_first_character.dart';
import 'package:plezy/screens/libraries/alpha_jump_helper.dart';

void main() {
  const characters = [
    LibraryFirstCharacter(key: 'A', title: 'A', size: 3),
    LibraryFirstCharacter(key: 'B', title: 'B', size: 4),
    LibraryFirstCharacter(key: 'C', title: 'C', size: 2),
  ];

  test('maps title-ascending letters to cumulative offsets', () {
    final helper = AlphaJumpHelper(characters);

    expect(helper.letters, ['A', 'B', 'C']);
    expect(helper.indexForLetter('A'), 0);
    expect(helper.indexForLetter('B'), 3);
    expect(helper.indexForLetter('C'), 7);
    expect(helper.currentLetter(0), 'A');
    expect(helper.currentLetter(3), 'B');
    expect(helper.currentLetter(8), 'C');
  });

  test('maps title-descending letters to reversed cumulative offsets', () {
    final helper = AlphaJumpHelper(characters, descending: true);

    expect(helper.letters, ['C', 'B', 'A']);
    expect(helper.indexForLetter('C'), 0);
    expect(helper.indexForLetter('B'), 2);
    expect(helper.indexForLetter('A'), 6);
    expect(helper.currentLetter(0), 'C');
    expect(helper.currentLetter(2), 'B');
    expect(helper.currentLetter(8), 'A');
  });
}
