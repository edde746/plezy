import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_person.dart';

void main() {
  group('MediaPersonDetails.ageOn', () {
    final born = DateTime.utc(1992, 3, 13);

    test('counts a year only once the birthday has come round', () {
      final details = MediaPersonDetails(birthDate: born);

      expect(details.ageOn(DateTime(2026, 3, 12)), 33);
      expect(details.ageOn(DateTime(2026, 3, 13)), 34);
    });

    test('stops at the death date', () {
      final details = MediaPersonDetails(birthDate: DateTime.utc(1979, 4, 4), deathDate: DateTime.utc(2008, 1, 22));

      expect(details.ageOn(DateTime(2026, 10, 14)), 28);
    });

    test('has no age without a birth date or with a death before the birth', () {
      expect(MediaPersonDetails(deathDate: born).ageOn(DateTime(2026)), isNull);
      expect(MediaPersonDetails(birthDate: born, deathDate: DateTime.utc(1990)).ageOn(DateTime(2026)), isNull);
    });
  });

  test('parseDate keeps the calendar day of both wire shapes', () {
    expect(MediaPersonDetails.parseDate('1992-03-13'), DateTime.utc(1992, 3, 13));
    expect(MediaPersonDetails.parseDate('1976-06-06T00:00:00.0000000Z'), DateTime.utc(1976, 6, 6));
    expect(MediaPersonDetails.parseDate(''), isNull);
    expect(MediaPersonDetails.parseDate(19920313), isNull);
  });
}
