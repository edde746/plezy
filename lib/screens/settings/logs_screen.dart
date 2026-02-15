import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
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

  @override
  void initState() {
    super.initState();
    _logs = MemoryLogOutput.getLogs();
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
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.common.close))],
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

  IconData _getLevelIcon(Level level) {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return Symbols.error_rounded;
      case Level.warning:
        return Symbols.warning_rounded;
      case Level.info:
        return Symbols.info_rounded;
      case Level.debug:
      case Level.trace:
        return Symbols.bug_report_rounded;
      default:
        return Symbols.circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(t.screens.logs),
            pinned: true,
            actions: [
              IconButton(
                icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
                onPressed: _loadLogs,
                tooltip: t.common.refresh,
              ),
              IconButton(
                icon: const AppIcon(Symbols.upload_rounded, fill: 1),
                onPressed: _logs.isNotEmpty ? _uploadLogs : null,
                tooltip: t.logs.uploadLogs,
              ),
              IconButton(
                icon: const AppIcon(Symbols.content_copy_rounded, fill: 1),
                onPressed: _logs.isNotEmpty ? _copyAllLogs : null,
                tooltip: t.logs.copyLogs,
              ),
              IconButton(
                icon: const AppIcon(Symbols.delete_outline_rounded, fill: 1),
                onPressed: _logs.isNotEmpty ? _clearLogs : null,
                tooltip: t.logs.clearLogs,
              ),
            ],
          ),
          if (_logs.isEmpty)
            SliverFillRemaining(child: Center(child: Text(t.messages.noLogsAvailable)))
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final log = _logs[index];
                  return _LogEntryCard(
                    log: log,
                    formatTime: _formatTime,
                    levelColor: _getLevelColor(log.level),
                    levelIcon: _getLevelIcon(log.level),
                  );
                }, childCount: _logs.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogEntryCard extends StatefulWidget {
  final LogEntry log;
  final String Function(DateTime) formatTime;
  final Color levelColor;
  final IconData levelIcon;

  const _LogEntryCard({required this.log, required this.formatTime, required this.levelColor, required this.levelIcon});

  @override
  State<_LogEntryCard> createState() => _LogEntryCardState();
}

class _LogEntryCardState extends State<_LogEntryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasErrorOrStackTrace = widget.log.error != null || widget.log.stackTrace != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: hasErrorOrStackTrace ? () => setState(() => _isExpanded = !_isExpanded) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(widget.levelIcon, fill: 1, color: widget.levelColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.log.level.name.toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, color: widget.levelColor, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.formatTime(widget.log.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.log.message, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (hasErrorOrStackTrace)
                    AppIcon(
                      _isExpanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                      fill: 1,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                    ),
                ],
              ),
              if (_isExpanded && hasErrorOrStackTrace) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (widget.log.error != null)
                  _buildDetailSection(title: t.logs.error, content: widget.log.error.toString()),
                if (widget.log.stackTrace != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailSection(title: t.logs.stackTrace, content: widget.log.stackTrace.toString()),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: widget.levelColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: SelectableText(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
