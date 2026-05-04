import 'package:flutter/material.dart';

import '../../exceptions/media_server_exceptions.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_server_client.dart';
import '../../models/livetv_program.dart';
import '../../models/media_grab_operation.dart';
import '../../models/media_subscription.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import 'record_options_sheet.dart';

/// Outcome of an attempted recording rule create or edit. Returned by
/// [RecordOptionsSheet.push] / [RecordOptionsSheet.pushEdit] so callers can
/// show the right user feedback.
enum RecordOutcome { scheduled, updated, alreadyScheduled, adminRequired, targetMissing, failed, cancelled }

/// Fetch the recording template for [program] and push the options sheet so
/// the user can review prefs and create a recording rule.
///
/// Returns the outcome so callers can decide whether to dismiss the parent
/// sheet (e.g. close the program details sheet on a successful schedule).
///
/// Handles the standard error envelope:
/// - 403: surface "DVR settings require an admin account".
/// - 409 (duplicate): surface "Already scheduled" via info snackbar.
/// - Other: generic failure snackbar.
Future<RecordOutcome?> recordProgram(BuildContext context, MediaServerClient client, LiveTvProgram program) async {
  final guid = program.guid;
  if (guid == null || guid.isEmpty) {
    if (!context.mounted) return null;
    showSnackBar(context, t.liveTv.recordNotAvailable, type: SnackBarType.error);
    return RecordOutcome.failed;
  }

  List<SubscriptionTemplate> templates;
  try {
    templates = await client.liveTv.getSubscriptionTemplate(guid);
  } catch (e) {
    appLogger.e('Failed to fetch recording template', error: e);
    if (!context.mounted) return null;
    if (_statusCode(e) == 403) {
      showSnackBar(context, t.liveTv.dvrAdminRequired, type: SnackBarType.error);
      return RecordOutcome.adminRequired;
    }
    showSnackBar(context, t.liveTv.recordingFailed, type: SnackBarType.error);
    return RecordOutcome.failed;
  }

  final entries = <MediaSubscription>[for (final template in templates) ...template.subscriptions];
  if (entries.isEmpty) {
    if (!context.mounted) return null;
    showSnackBar(context, t.liveTv.recordNotAvailable, type: SnackBarType.error);
    return RecordOutcome.failed;
  }

  if (!context.mounted) return null;
  final outcome = await RecordOptionsSheet.push(context, client: client, program: program, entries: entries);
  if (!context.mounted) return outcome;
  switch (outcome) {
    case RecordOutcome.scheduled:
      showSnackBar(context, t.liveTv.recordingScheduled, type: SnackBarType.success);
    case RecordOutcome.alreadyScheduled:
      showSnackBar(context, t.liveTv.alreadyScheduled);
    case RecordOutcome.adminRequired:
      showSnackBar(context, t.liveTv.dvrAdminRequired, type: SnackBarType.error);
    case RecordOutcome.targetMissing:
      showSnackBar(context, t.liveTv.recordingTargetMissing, type: SnackBarType.error);
    case RecordOutcome.failed:
      showSnackBar(context, t.liveTv.recordingFailed, type: SnackBarType.error);
    case RecordOutcome.updated:
    case RecordOutcome.cancelled:
    case null:
      // user dismissed without creating
      break;
  }
  return outcome;
}

/// Push the [RecordOptionsSheet] in edit mode against an existing rule, then
/// surface a success / error snackbar.
Future<RecordOutcome?> editRecordingRule(BuildContext context, MediaServerClient client, MediaSubscription rule) async {
  final outcome = await RecordOptionsSheet.pushEdit(context, client: client, rule: rule);
  if (!context.mounted) return outcome;
  switch (outcome) {
    case RecordOutcome.updated:
      showSnackBar(context, t.liveTv.recordingRuleUpdated, type: SnackBarType.success);
    case RecordOutcome.adminRequired:
      showSnackBar(context, t.liveTv.dvrAdminRequired, type: SnackBarType.error);
    case RecordOutcome.failed:
      showSnackBar(context, t.liveTv.recordingFailed, type: SnackBarType.error);
    case RecordOutcome.scheduled:
    case RecordOutcome.alreadyScheduled:
    case RecordOutcome.targetMissing:
    case RecordOutcome.cancelled:
    case null:
      break;
  }
  return outcome;
}

Future<bool> confirmCancelGrab(BuildContext context, MediaServerClient client, MediaGrabOperation op) async {
  final operationKey = op.operationKey;
  if (operationKey.isEmpty) {
    showSnackBar(context, t.liveTv.recordingFailed, type: SnackBarType.error);
    return false;
  }
  final title = op.program?.displayTitle ?? '';
  final confirmed = await showConfirmDialog(
    context,
    title: t.liveTv.cancelRecordingTitle,
    message: t.liveTv.cancelRecordingMessage(title: title),
    confirmText: t.liveTv.cancelRecording,
    isDestructive: true,
  );
  if (!confirmed) return false;
  try {
    await client.liveTv.cancelGrab(operationKey);
    if (context.mounted) {
      showSnackBar(context, t.liveTv.recordingCancelled, type: SnackBarType.success);
    }
    return true;
  } catch (e) {
    appLogger.e('Failed to cancel grab', error: e);
    if (context.mounted) {
      showSnackBar(context, t.liveTv.recordingFailed, type: SnackBarType.error);
    }
    return false;
  }
}

Future<bool> confirmDeleteRule(BuildContext context, MediaServerClient client, MediaSubscription rule) async {
  final confirmed = await showConfirmDialog(
    context,
    title: t.liveTv.deleteRuleTitle,
    message: t.liveTv.deleteRuleMessage(title: rule.title ?? ''),
    confirmText: t.liveTv.deleteRule,
    isDestructive: true,
  );
  if (!confirmed) return false;
  try {
    await client.liveTv.deleteRecordingRule(rule.key);
    if (context.mounted) {
      showSnackBar(context, t.liveTv.recordingRuleDeleted, type: SnackBarType.success);
    }
    return true;
  } catch (e) {
    appLogger.e('Failed to delete recording rule', error: e);
    if (context.mounted) {
      showSnackBar(context, t.liveTv.recordingFailed, type: SnackBarType.error);
    }
    return false;
  }
}

int? _statusCode(Object e) {
  if (e is MediaServerHttpException) return e.statusCode;
  return null;
}
