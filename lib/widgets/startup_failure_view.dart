import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../services/log_upload_service.dart';
import '../services/startup_diagnostics.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';

const startupBootstrapFailureKey = Key('startup-bootstrap-failure');
const startupBootstrapRetryKey = Key('startup-bootstrap-retry');
const startupFailureDetailsKey = Key('startup-failure-details');
const startupFailureCopyKey = Key('startup-failure-copy');
const startupFailureUploadKey = Key('startup-failure-upload');
const startupFailureRepairKey = Key('startup-failure-repair');

/// Everything the startup gate can show when initialization fails.
///
/// Before #1732 this was an icon, the word "Error" and a Retry button: the
/// error object was captured and then discarded, and the only log viewer sat
/// behind the gate that had just failed. On Windows that left literally no way
/// to find out what went wrong — no log file, and no console for a
/// double-clicked release build.
///
/// Everything rendered here comes from [StartupFailureRecord], which is an
/// allowlist of already-redacted fields. Raw preference, database or file
/// contents never reach this widget.
class StartupFailureView extends StatefulWidget {
  const StartupFailureView({super.key, required this.failure, required this.onRetry, this.onRepair, this.busy = false});

  final StartupFailureRecord failure;
  final VoidCallback? onRetry;

  /// Runs the consented storage repair. Null when the failure is not one an
  /// in-app repair can address.
  final Future<void> Function()? onRepair;

  final bool busy;

  @override
  State<StartupFailureView> createState() => _StartupFailureViewState();
}

class _StartupFailureViewState extends State<StartupFailureView> {
  late final FocusNode _retryFocusNode = FocusNode(debugLabel: 'startup-failure-retry');
  bool _detailsExpanded = false;
  bool _uploading = false;

  @override
  void dispose() {
    _retryFocusNode.dispose();
    super.dispose();
  }

  void _copyDetails() {
    Clipboard.setData(ClipboardData(text: widget.failure.describe()));
    showSuccessSnackBar(context, t.startup.detailsCopied);
  }

  Future<void> _uploadDetails() async {
    setState(() => _uploading = true);
    try {
      final id = await uploadDiagnosticText(widget.failure.describe());
      if (!mounted) return;
      await showScopedDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.messages.logsUploaded),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.messages.logId}:'),
              const SizedBox(height: 8),
              SelectableText(
                id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 18),
              ),
            ],
          ),
          actions: [
            DialogActionButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              label: t.common.close,
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      appLogger.w('Startup diagnostics upload failed', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.messages.logsUploadFailed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = widget.failure;
    final enabled = !widget.busy && !_uploading;
    final repair = widget.onRepair;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            key: startupBootstrapFailureKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(Symbols.error_rounded, size: 48),
              const SizedBox(height: 16),
              Text(t.startup.failedTitle, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(t.startup.failedBody, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                '${t.startup.phaseLabel}: ${failure.phaseId} · ${failure.errorType}',
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildDetails(theme, failure),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  FocusableButton(
                    focusNode: _retryFocusNode,
                    autofocus: true,
                    onPressed: enabled ? widget.onRetry : null,
                    child: FilledButton(
                      key: startupBootstrapRetryKey,
                      onPressed: enabled ? widget.onRetry : null,
                      child: Text(t.common.retry),
                    ),
                  ),
                  if (repair != null)
                    FocusableButton(
                      onPressed: enabled ? () => repair() : null,
                      child: FilledButton.tonal(
                        key: startupFailureRepairKey,
                        onPressed: enabled ? () => repair() : null,
                        child: Text(t.startup.repairStorage),
                      ),
                    ),
                  FocusableButton(
                    onPressed: enabled ? _copyDetails : null,
                    child: OutlinedButton(
                      key: startupFailureCopyKey,
                      onPressed: enabled ? _copyDetails : null,
                      child: Text(t.startup.copyDetails),
                    ),
                  ),
                  FocusableButton(
                    onPressed: enabled ? () => _uploadDetails() : null,
                    child: OutlinedButton(
                      key: startupFailureUploadKey,
                      onPressed: enabled ? () => _uploadDetails() : null,
                      child: Text(t.startup.uploadDetails),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme, StartupFailureRecord failure) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FocusableButton(
          onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
          child: TextButton(
            onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
            child: Text(_detailsExpanded ? t.startup.hideDetails : t.startup.showDetails),
          ),
        ),
        if (_detailsExpanded)
          Container(
            key: startupFailureDetailsKey,
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                failure.describe(),
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
