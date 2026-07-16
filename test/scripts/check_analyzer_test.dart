import 'package:flutter_test/flutter_test.dart';

import '../../scripts/check_analyzer.dart';

const _root = r'C:\repo';
const _allowedInfo =
    r"INFO|LINT|UNAWAITED_FUTURES|C:\\repo\\test\\navigation\\profile_navigation_scope_test.dart|21|28|4|Missing an 'await' for the 'Future' computed by this expression.";

void main() {
  test('accepts a clean analyzer success', () {
    expect(
      validateAnalyzerResult(analyzerExitCode: 0, analyzerStdout: '', analyzerStderr: '', rootPath: _root),
      isNull,
    );
  });

  test('accepts a nonzero exit caused only by an allowed info', () {
    expect(
      validateAnalyzerResult(
        analyzerExitCode: 1,
        analyzerStdout: '$_allowedInfo\n',
        analyzerStderr: '',
        rootPath: _root,
      ),
      isNull,
    );
  });

  test('rejects a crash after an allowed info', () {
    expect(
      validateAnalyzerResult(
        analyzerExitCode: 1,
        analyzerStdout: '$_allowedInfo\n',
        analyzerStderr: 'Analyzer crash\nstack trace\n',
        rootPath: _root,
      ),
      contains('unexpected stderr'),
    );
  });

  test('rejects a crash exit code even after an allowed info', () {
    expect(
      validateAnalyzerResult(
        analyzerExitCode: 255,
        analyzerStdout: '$_allowedInfo\n',
        analyzerStderr: '',
        rootPath: _root,
      ),
      contains('exited 255'),
    );
  });

  test('rejects unexpected output after an allowed info', () {
    expect(
      validateAnalyzerResult(
        analyzerExitCode: 1,
        analyzerStdout: '$_allowedInfo\nAnalyzer crash\n',
        analyzerStderr: '',
        rootPath: _root,
      ),
      contains('malformed machine output'),
    );
  });

  test('rejects warnings and unapproved infos', () {
    const warning = 'WARNING|STATIC_WARNING|UNUSED_LOCAL_VARIABLE|/repo/lib/a.dart|1|1|1|Unused.';
    const newInfo = 'INFO|LINT|AVOID_PRINT|/repo/lib/a.dart|1|1|5|Avoid print calls.';

    expect(
      validateAnalyzerResult(analyzerExitCode: 1, analyzerStdout: '$warning\n', analyzerStderr: '', rootPath: '/repo'),
      contains('unexpected WARNING'),
    );
    expect(
      validateAnalyzerResult(analyzerExitCode: 1, analyzerStdout: '$newInfo\n', analyzerStderr: '', rootPath: '/repo'),
      contains('not explicitly allowed'),
    );
  });

  test('rejects a nonzero exit without diagnostics', () {
    expect(
      validateAnalyzerResult(analyzerExitCode: 1, analyzerStdout: '', analyzerStderr: '', rootPath: '/repo'),
      contains('exited 1'),
    );
  });
}
