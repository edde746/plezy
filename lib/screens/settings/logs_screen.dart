import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../focus/focusable_action_bar.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/app_icon.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../utils/dialogs.dart';
import '../../main.dart' show gitCommit;
import '../../services/device_performance.dart';
import '../../utils/app_logger.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/ios_status_bar_tap_scroll_to_top.dart';

/// Relay `/logs` accepts 1 MiB. The in-memory buffer intentionally remains
/// larger for local viewing and copying; uploads retain the device header and
/// newest log lines within this transport contract.
const int maxLogUploadBytes = 1 * 1024 * 1024;

String constrainLogUploadPayload({required String header, required String logs, int maxBytes = maxLogUploadBytes}) {
  if (maxBytes <= 0) return '';

  final headerBytes = utf8.encode(header);
  if (headerBytes.length >= maxBytes) {
    var end = maxBytes;
    while (end > 0 && end < headerBytes.length && (headerBytes[end] & 0xC0) == 0x80) {
      end--;
    }
    return utf8.decode(headerBytes.sublist(0, end));
  }

  final logBytes = utf8.encode(logs);
  final availableLogBytes = maxBytes - headerBytes.length;
  if (logBytes.length <= availableLogBytes) return '$header$logs';

  var start = logBytes.length - availableLogBytes;
  while (start < logBytes.length && (logBytes[start] & 0xC0) == 0x80) {
    start++;
  }
  final nextLine = logBytes.indexOf(0x0A, start);
  if (nextLine >= 0 && nextLine + 1 < logBytes.length) {
    start = nextLine + 1;
  }
  return header + utf8.decode(logBytes.sublist(start));
}

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with MountedSetStateMixin {
  List<LogEntry> _logs = [];
  String _deviceInfo = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logs = MemoryLogOutput.getLogs();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final buffer = StringBuffer();
    final commitSuffix = gitCommit.isNotEmpty ? ' ${gitCommit.substring(0, 7)}' : '';
    buffer.writeln('${t.app.title} v${packageInfo.version} (${packageInfo.buildNumber})$commitSuffix');

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      buffer.writeln('Android ${info.version.release} (API ${info.version.sdkInt})');
      buffer.writeln('${info.manufacturer} ${info.model}');
      if (TvDetectionService.isTVSync()) {
        final reasons = TvDetectionService.tvDetectionReasonsSync();
        final suffix = reasons.isEmpty ? '' : ' (${reasons.join(', ')})';
        buffer.writeln('TV mode: yes$suffix');
      }
      // Renderer + effects tier turn "did the reduced tier engage on this
      // device" into something answerable from any uploaded log (#1349).
      String renderer;
      try {
        renderer = await const MethodChannel('com.plezy/theme').invokeMethod<String>('getRenderer') ?? 'unknown';
      } catch (_) {
        renderer = 'unknown';
      }
      buffer.writeln('Renderer: $renderer');
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      buffer.writeln('iOS ${info.systemVersion}');
      buffer.writeln(info.utsname.machine);
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      buffer.writeln('macOS ${info.osRelease}');
      buffer.writeln(info.model);
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      buffer.writeln('Linux ${info.versionId ?? info.id}');
    }

    buffer.writeln('Effects: ${DevicePerformance.describeSync()}');

    setStateIfMounted(() => _deviceInfo = buffer.toString().trimRight());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    setState(() {
      _logs = MemoryLogOutput.getLogs();
    });
  }

  String _formatTime(DateTime time) {
    final hour = padNumber(time.hour, 2);
    final minute = padNumber(time.minute, 2);
    final second = padNumber(time.second, 2);
    final millisecond = padNumber(time.millisecond, 3);
    return '$hour:$minute:$second.$millisecond';
  }

  void _clearLogs() {
    setState(() {
      MemoryLogOutput.clearLogs();
      _logs = [];
    });
    showSuccessSnackBar(context, t.messages.logsCleared);
  }

  String _formatAllLogs({int? maxBytes}) {
    final header = _deviceInfo.isEmpty ? '' : '$_deviceInfo\n---\n';
    final logs = StringBuffer();
    var isFirst = true;
    for (final log in _logs.reversed) {
      if (!isFirst) {
        logs.write('\n');
      }
      isFirst = false;

      logs.write('[${_formatTime(log.timestamp)}] [${log.level.name.toUpperCase()}] ${log.message}');
      if (log.error != null) {
        logs.write('\nError: ${log.error}');
      }
      if (log.stackTrace != null) {
        logs.write('\nStack trace:\n${log.stackTrace}');
      }
    }
    final logText = logs.toString();
    return maxBytes == null
        ? '$header$logText'
        : constrainLogUploadPayload(header: header, logs: logText, maxBytes: maxBytes);
  }

  void _copyAllLogs() {
    Clipboard.setData(ClipboardData(text: _formatAllLogs()));
    showSuccessSnackBar(context, t.messages.logsCopied);
  }

  Future<void> _uploadLogs() async {
    final logText = _formatAllLogs(maxBytes: maxLogUploadBytes);

    showLoadingDialog(context);

    try {
      final response = await httpClient.post(
        'https://ice.plezy.app/logs',
        body: logText,
        headers: {'Content-Type': 'text/plain'},
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      final id = (data as Map<String, dynamic>)['id'] as String;

      unawaited(
        showScopedDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t.messages.logsUploaded),
            content: Row(
              children: [
                Text('${t.messages.logId}: '),
                SelectableText(
                  id,
                  style: const TextStyle(fontWeight: .bold, fontFamily: 'monospace', fontSize: 18),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const AppIcon(Symbols.content_copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: id));
                    showSuccessSnackBar(context, t.messages.logsCopied);
                  },
                ),
              ],
            ),
            actions: [
              DialogActionButton(autofocus: true, onPressed: () => Navigator.of(ctx).pop(), label: t.common.close),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      showErrorSnackBar(context, t.messages.logsUploadFailed);
    }
  }

  Color _getLevelColor(Level level) {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return Colors.red;
      case Level.warning:
        return Colors.orange;
      case Level.info:
        return Colors.blue;
      case Level.debug:
      case Level.trace:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _scroll(double delta) {
    final pos = _scrollController.position;
    _scrollController.animateTo(
      (pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  List<TextSpan> _buildLogSpans() {
    final spans = <TextSpan>[];
    if (_deviceInfo.isNotEmpty) {
      spans.add(
        TextSpan(
          text: '$_deviceInfo\n',
          style: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
        ),
      );
      spans.add(
        TextSpan(
          text: '---\n',
          style: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      );
    }
    for (var i = 0; i < _logs.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      final log = _logs[i];
      final color = _getLevelColor(log.level);
      spans.add(
        TextSpan(
          text: '[${_formatTime(log.timestamp)}] ',
          style: TextStyle(color: color.withValues(alpha: 0.6)),
        ),
      );
      spans.add(
        TextSpan(
          text: '[${log.level.name.toUpperCase()}] ',
          style: TextStyle(color: color, fontWeight: .bold),
        ),
      );
      spans.add(TextSpan(text: log.message));
      if (log.error != null) {
        spans.add(
          TextSpan(
            text: '\n  Error: ${log.error}',
            style: TextStyle(color: color),
          ),
        );
      }
      if (log.stackTrace != null) {
        spans.add(
          TextSpan(
            text: '\n  ${log.stackTrace.toString().replaceAll('\n', '\n  ')}',
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        final backResult = handleBackKeyNavigation(context, event);
        if (backResult != KeyEventResult.ignored) return backResult;
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _scroll(80);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _scroll(-80);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: PrimaryScrollController(
        controller: _scrollController,
        child: IosStatusBarTapScrollToTop(
          controller: _scrollController,
          child: Scaffold(
            body: CustomScrollView(
              primary: true,
              slivers: [
                CustomAppBar(
                  title: Text(t.screens.logs),
                  pinned: true,
                  actions: [
                    FocusableActionBar(
                      actions: [
                        FocusableAction(icon: Symbols.refresh_rounded, tooltip: t.common.refresh, onPressed: _loadLogs),
                        FocusableAction(
                          icon: Symbols.upload_rounded,
                          tooltip: t.logs.uploadLogs,
                          onPressed: _logs.isNotEmpty ? _uploadLogs : null,
                        ),
                        FocusableAction(
                          icon: Symbols.content_copy_rounded,
                          tooltip: t.logs.copyLogs,
                          onPressed: _logs.isNotEmpty ? _copyAllLogs : null,
                        ),
                        FocusableAction(
                          icon: Symbols.delete_outline_rounded,
                          tooltip: t.logs.clearLogs,
                          onPressed: _logs.isNotEmpty ? _clearLogs : null,
                        ),
                      ],
                    ),
                  ],
                ),
                if (_logs.isEmpty)
                  SliverFillRemaining(child: Center(child: Text(t.messages.noLogsAvailable)))
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverToBoxAdapter(
                      child: SelectableText.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.5,
                          ),
                          children: _buildLogSpans(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
