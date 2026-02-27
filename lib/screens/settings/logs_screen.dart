import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../focus/focusable_button.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/desktop_app_bar.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  late final FocusNode _refreshFocusNode;
  late final FocusNode _uploadFocusNode;
  late final FocusNode _copyFocusNode;
  late final FocusNode _clearFocusNode;
  bool _isRefreshFocused = false;
  bool _isUploadFocused = false;
  bool _isCopyFocused = false;
  bool _isClearFocused = false;

  @override
  void initState() {
    super.initState();
    _logs = MemoryLogOutput.getLogs();
    _refreshFocusNode = FocusNode(debugLabel: 'RefreshLogs');
    _uploadFocusNode = FocusNode(debugLabel: 'UploadLogs');
    _copyFocusNode = FocusNode(debugLabel: 'CopyLogs');
    _clearFocusNode = FocusNode(debugLabel: 'ClearLogs');
    _refreshFocusNode.addListener(() => setState(() => _isRefreshFocused = _refreshFocusNode.hasFocus));
    _uploadFocusNode.addListener(() => setState(() => _isUploadFocused = _uploadFocusNode.hasFocus));
    _copyFocusNode.addListener(() => setState(() => _isCopyFocused = _copyFocusNode.hasFocus));
    _clearFocusNode.addListener(() => setState(() => _isClearFocused = _clearFocusNode.hasFocus));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshFocusNode.dispose();
    _uploadFocusNode.dispose();
    _copyFocusNode.dispose();
    _clearFocusNode.dispose();
    super.dispose();
  }

  void _loadLogs() {
    setState(() {
      _logs = MemoryLogOutput.getLogs();
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final millisecond = time.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$millisecond';
  }

  void _clearLogs() {
    setState(() {
      MemoryLogOutput.clearLogs();
      _logs = [];
    });
    showSuccessSnackBar(context, t.messages.logsCleared);
  }

  String _formatAllLogs() {
    final buffer = StringBuffer();
    bool isFirst = true;
    for (final log in _logs.reversed) {
      if (!isFirst) {
        buffer.write('\n');
      }
      isFirst = false;

      buffer.write('[${_formatTime(log.timestamp)}] [${log.level.name.toUpperCase()}] ${log.message}');
      if (log.error != null) {
        buffer.write('\nError: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.write('\nStack trace:\n${log.stackTrace}');
      }
    }
    return buffer.toString();
  }

  void _copyAllLogs() {
    Clipboard.setData(ClipboardData(text: _formatAllLogs()));
    showSuccessSnackBar(context, t.messages.logsCopied);
  }

  Future<void> _uploadLogs() async {
    final logText = _formatAllLogs();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await Dio().post(
        'https://ice.plezy.app/logs',
        data: logText,
        options: Options(contentType: 'text/plain'),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      final id =
          (jsonDecode(response.data is String ? response.data : jsonEncode(response.data))
                  as Map<String, dynamic>)['id']
              as String;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.messages.logsUploaded),
          content: Row(
            children: [
              Text('${t.messages.logId}: '),
              SelectableText(
                id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 18),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: id));
                  showSuccessSnackBar(ctx, t.messages.logsCopied);
                },
              ),
            ],
          ),
          actions: [
            FocusableButton(
              autofocus: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(t.common.close),
              ),
            ),
          ],
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
    for (var i = 0; i < _logs.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      final log = _logs[i];
      final color = _getLevelColor(log.level);
      spans.add(TextSpan(
        text: '[${_formatTime(log.timestamp)}] ',
        style: TextStyle(color: color.withValues(alpha: 0.6)),
      ));
      spans.add(TextSpan(
        text: '[${log.level.name.toUpperCase()}] ',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: log.message));
      if (log.error != null) {
        spans.add(TextSpan(
          text: '\n  Error: ${log.error}',
          style: TextStyle(color: color),
        ));
      }
      if (log.stackTrace != null) {
        spans.add(TextSpan(
          text: '\n  ${log.stackTrace.toString().replaceAll('\n', '\n  ')}',
          style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
        ));
      }
    }
    return spans;
  }

  Widget _buildActionButton({
    required FocusNode focusNode,
    required bool isFocused,
    required FocusOnKeyEventCallback onKeyEvent,
    required IconData icon,
    required String? tooltip,
    required VoidCallback? onPressed,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: isFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: IconButton(
          icon: AppIcon(icon, fill: 1),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
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
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            CustomAppBar(
              title: Text(t.screens.logs),
              pinned: true,
              actions: [
                _buildActionButton(
                  focusNode: _refreshFocusNode,
                  isFocused: _isRefreshFocused,
                  onKeyEvent: dpadKeyHandler(
                    onSelect: _loadLogs,
                    onRight: () => _uploadFocusNode.requestFocus(),
                  ),
                  icon: Symbols.refresh_rounded,
                  tooltip: t.common.refresh,
                  onPressed: _loadLogs,
                ),
                _buildActionButton(
                  focusNode: _uploadFocusNode,
                  isFocused: _isUploadFocused,
                  onKeyEvent: dpadKeyHandler(
                    onSelect: _logs.isNotEmpty ? _uploadLogs : null,
                    onLeft: () => _refreshFocusNode.requestFocus(),
                    onRight: () => _copyFocusNode.requestFocus(),
                  ),
                  icon: Symbols.upload_rounded,
                  tooltip: t.logs.uploadLogs,
                  onPressed: _logs.isNotEmpty ? _uploadLogs : null,
                ),
                _buildActionButton(
                  focusNode: _copyFocusNode,
                  isFocused: _isCopyFocused,
                  onKeyEvent: dpadKeyHandler(
                    onSelect: _logs.isNotEmpty ? _copyAllLogs : null,
                    onLeft: () => _uploadFocusNode.requestFocus(),
                    onRight: () => _clearFocusNode.requestFocus(),
                  ),
                  icon: Symbols.content_copy_rounded,
                  tooltip: t.logs.copyLogs,
                  onPressed: _logs.isNotEmpty ? _copyAllLogs : null,
                ),
                _buildActionButton(
                  focusNode: _clearFocusNode,
                  isFocused: _isClearFocused,
                  onKeyEvent: dpadKeyHandler(
                    onSelect: _logs.isNotEmpty ? _clearLogs : null,
                    onLeft: () => _copyFocusNode.requestFocus(),
                  ),
                  icon: Symbols.delete_outline_rounded,
                  tooltip: t.logs.clearLogs,
                  onPressed: _logs.isNotEmpty ? _clearLogs : null,
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
    );
  }
}
