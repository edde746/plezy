import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../widgets/desktop_app_bar.dart';

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
    _loadLogs();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.messages.logsCleared)));
  }

  void _copyAllLogs() {
    final buffer = StringBuffer();
    bool isFirst = true;
    for (final log in _logs.reversed) {
      if (!isFirst) {
        buffer.write('\n');
      }
      isFirst = false;

      buffer.write(
        '[${_formatTime(log.timestamp)}] [${log.level.name.toUpperCase()}] ${log.message}',
      );
      if (log.error != null) {
        buffer.write('\nError: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.write('\nStack trace:\n${log.stackTrace}');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.messages.logsCopied)));
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
        return Icons.error;
      case Level.warning:
        return Icons.warning;
      case Level.info:
        return Icons.info;
      case Level.debug:
      case Level.trace:
        return Icons.bug_report;
      default:
        return Icons.circle;
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
                icon: const Icon(Icons.refresh),
                onPressed: _loadLogs,
                tooltip: t.common.refresh,
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _logs.isNotEmpty ? _copyAllLogs : null,
                tooltip: t.logs.copyLogs,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _logs.isNotEmpty ? _clearLogs : null,
                tooltip: t.logs.clearLogs,
              ),
            ],
          ),
          if (_logs.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(t.messages.noLogsAvailable)),
            )
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

  const _LogEntryCard({
    required this.log,
    required this.formatTime,
    required this.levelColor,
    required this.levelIcon,
  });

  @override
  State<_LogEntryCard> createState() => _LogEntryCardState();
}

class _LogEntryCardState extends State<_LogEntryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasErrorOrStackTrace =
        widget.log.error != null || widget.log.stackTrace != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: hasErrorOrStackTrace
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.levelIcon, color: widget.levelColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.log.level.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.levelColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.formatTime(widget.log.timestamp),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.log.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (hasErrorOrStackTrace)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.6),
                    ),
                ],
              ),
              if (_isExpanded && hasErrorOrStackTrace) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (widget.log.error != null) ...[
                  Text(
                    t.logs.error,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      widget.log.error.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
                if (widget.log.stackTrace != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    t.logs.stackTrace,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      widget.log.stackTrace.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
