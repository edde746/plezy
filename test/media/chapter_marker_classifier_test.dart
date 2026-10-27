import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/chapter_marker_classifier.dart';

import 'chapter_marker_model_cases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled model matches the training script on every reference case', () async {
    final classifier = await ChapterMarkerClassifier.bundled;
    for (final (i, c) in chapterMarkerModelCases.indexed) {
      final probabilities = classifier.probabilities(c.spans);
      for (var j = 0; j < c.spans.length; j++) {
        for (var k = 0; k < 3; k++) {
          expect(probabilities[j][k], closeTo(c.probabilities[j][k], 1e-9), reason: 'case $i chapter $j class $k');
        }
      }
      expect(classifier.pick(c.spans), (intro: c.intro, credits: c.credits), reason: 'case $i');
    }
  });
}
