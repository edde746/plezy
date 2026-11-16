import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/release_notes_text.dart';

void main() {
  test('GitHub generated notes become headings and bullets with PR numbers', () {
    const notes = '''
## What's Changed
* feat(player): **faster** seeking by @edde746 in https://github.com/edde746/plezy/pull/1234
* fix: `mpv` crash on [Fire TV](https://example.com) by @someone-else in https://github.com/edde746/plezy/pull/1240
  - nested detail

**Full Changelog**: https://github.com/edde746/plezy/compare/2.4.0...2.5.0
''';
    expect(releaseNotesLines(notes), const [
      ReleaseNotesLine("What's Changed", isHeading: true),
      ReleaseNotesLine('• feat(player): faster seeking (#1234)'),
      ReleaseNotesLine('• fix: mpv crash on Fire TV (#1240)'),
      ReleaseNotesLine('    • nested detail'),
    ]);
  });

  test('drops images, HTML, comments and rules, and collapses blank lines', () {
    const notes = '''
<!-- release-drafter -->
# 2.5.0 ##

![screenshot](https://example.com/a.png)
<details><summary>Android</summary>


Some _emphasis_ &amp; text

</details>
---
- last
''';
    expect(releaseNotesLines(notes), const [
      ReleaseNotesLine('2.5.0', isHeading: true),
      ReleaseNotesLine(''),
      ReleaseNotesLine('Android'),
      ReleaseNotesLine(''),
      ReleaseNotesLine('Some emphasis & text'),
      ReleaseNotesLine(''),
      ReleaseNotesLine('• last'),
    ]);
  });

  test('keeps code blocks as written and snake_case words intact', () {
    const notes = '''
Set gpu_dumb_mode:
```
gpu-dumb-mode=yes
# not a heading
```
''';
    expect(releaseNotesLines(notes), const [
      ReleaseNotesLine('Set gpu_dumb_mode:'),
      ReleaseNotesLine('gpu-dumb-mode=yes'),
      ReleaseNotesLine('# not a heading'),
    ]);
  });

  test('empty notes give no lines', () {
    expect(releaseNotesLines(''), isEmpty);
    expect(releaseNotesLines('\n\n  \n'), isEmpty);
  });
}
