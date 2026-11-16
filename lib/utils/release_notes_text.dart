/// One display line of a release's notes.
class ReleaseNotesLine {
  const ReleaseNotesLine(this.text, {this.isHeading = false});

  final String text;
  final bool isHeading;

  @override
  bool operator ==(Object other) => other is ReleaseNotesLine && other.text == text && other.isHeading == isHeading;

  @override
  int get hashCode => Object.hash(text, isHeading);

  @override
  String toString() => isHeading ? '# $text' : text;
}

final _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$');
final _bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$');
final _image = RegExp(r'!\[[^\]]*\]\([^)]*\)');
final _link = RegExp(r'\[([^\]]+)\]\([^)]*\)');
final _strong = RegExp(r'(\*\*|__)(.+?)\1');
final _emphasis = RegExp(r'(?<![\w*])([*_])(?!\s)(.+?)(?<!\s)\1(?![\w*])');
final _code = RegExp(r'`([^`]*)`');
final _htmlComment = RegExp(r'<!--.*?-->', dotAll: true);
final _htmlTag = RegExp(r'</?[a-zA-Z][^>]*>');
// GitHub's generated notes: "* Fix thing by @someone in https://github.com/o/r/pull/123".
final _generatedCredit = RegExp(r'\s+by @[\w-]+(?:\[bot\])? in https://github\.com/\S+/pull/(\d+)\s*$');
final _horizontalRule = RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$');

/// GitHub release notes (Markdown) as plain lines for a dialog: headings marked, list items as
/// bullets, inline markup, images, HTML and GitHub's "by @user in PR-URL" credits removed, and
/// runs of blank lines collapsed. The "Full Changelog" compare link is dropped: it is a URL to
/// open, which the dialog cannot do on most TVs.
List<ReleaseNotesLine> releaseNotesLines(String markdown) {
  final lines = <ReleaseNotesLine>[];
  var blank = false;
  var inFence = false;
  for (final raw in markdown.replaceAll(_htmlComment, '').replaceAll('\r', '').split('\n')) {
    if (raw.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence && _horizontalRule.hasMatch(raw)) continue;

    var isHeading = false;
    var text = raw;
    if (!inFence) {
      if (_heading.firstMatch(text) case final m?) {
        text = m.group(1)!;
        isHeading = true;
      } else if (_bullet.firstMatch(text) case final m?) {
        final depth = m.group(1)!.replaceAll('\t', '  ').length ~/ 2;
        text = '${'    ' * depth}• ${m.group(2)}';
      }
      text = _inline(text);
      if (text.trimLeft().toLowerCase().startsWith('full changelog')) continue;
    }

    if (text.trim().isEmpty) {
      blank = lines.isNotEmpty;
      continue;
    }
    if (blank) lines.add(const ReleaseNotesLine(''));
    blank = false;
    lines.add(ReleaseNotesLine(text.trimRight(), isHeading: isHeading));
  }
  return lines;
}

String _inline(String text) => text
    .replaceAll(_image, '')
    .replaceAllMapped(_link, (m) => m.group(1)!)
    .replaceAllMapped(_generatedCredit, (m) => ' (#${m.group(1)})')
    .replaceAllMapped(_strong, (m) => m.group(2)!)
    .replaceAllMapped(_emphasis, (m) => m.group(2)!)
    .replaceAllMapped(_code, (m) => m.group(1)!)
    .replaceAll(_htmlTag, '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
