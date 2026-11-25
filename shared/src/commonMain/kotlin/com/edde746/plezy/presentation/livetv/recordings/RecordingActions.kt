package com.edde746.plezy.presentation.livetv.recordings

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException

/** How a Record Options sheet ended. */
enum class RecordOutcome { SCHEDULED, UPDATED, ALREADY_SCHEDULED, ADMIN_REQUIRED, TARGET_MISSING, FAILED, CANCELLED }

/**
 * A destructive confirmation the UI shows as a dialog: [title], [message], and [confirmText] on the destructive
 * button; the store's `confirm()` acts, its `dismissConfirmation()` drops it.
 */
data class LiveTvConfirmation(val title: String, val message: String, val confirmText: String)

/** The snackbar after creating a recording rule ended in [outcome]; null when there is nothing to say. */
fun recordOutcomeMessage(outcome: RecordOutcome): LiveTvMessage? = when (outcome) {
    RecordOutcome.SCHEDULED -> LiveTvMessage(T.liveTv.recordingScheduled)
    RecordOutcome.ALREADY_SCHEDULED -> LiveTvMessage(T.liveTv.alreadyScheduled)
    RecordOutcome.ADMIN_REQUIRED -> LiveTvMessage(T.liveTv.dvrAdminRequired, isError = true)
    RecordOutcome.TARGET_MISSING -> LiveTvMessage(T.liveTv.recordingTargetMissing, isError = true)
    RecordOutcome.FAILED -> LiveTvMessage(T.liveTv.recordingFailed, isError = true)
    RecordOutcome.UPDATED, RecordOutcome.CANCELLED -> null
}

/** The snackbar after editing a recording rule ended in [outcome]; null when there is nothing to say. */
fun editOutcomeMessage(outcome: RecordOutcome): LiveTvMessage? = when (outcome) {
    RecordOutcome.UPDATED -> LiveTvMessage(T.liveTv.recordingRuleUpdated)
    RecordOutcome.ADMIN_REQUIRED -> LiveTvMessage(T.liveTv.dvrAdminRequired, isError = true)
    RecordOutcome.FAILED -> LiveTvMessage(T.liveTv.recordingFailed, isError = true)
    RecordOutcome.SCHEDULED, RecordOutcome.ALREADY_SCHEDULED, RecordOutcome.TARGET_MISSING, RecordOutcome.CANCELLED -> null
}

/** What a failed save of a recording rule means: a duplicate (409 or a conflict) is already scheduled, 403 needs an admin. */
internal fun recordOutcomeOf(error: Exception): RecordOutcome = when {
    error is RecordingConflictException -> RecordOutcome.ALREADY_SCHEDULED
    error is MediaServerHttpException && error.statusCode == 403 -> RecordOutcome.ADMIN_REQUIRED
    error is MediaServerHttpException && error.statusCode == 409 -> RecordOutcome.ALREADY_SCHEDULED
    else -> RecordOutcome.FAILED
}

/** The rule entries [program] can be recorded with, or the message saying why it can't. */
sealed interface RecordEntries {
    data class Ready(val entries: List<MediaSubscription>) : RecordEntries

    data class Unavailable(val message: LiveTvMessage) : RecordEntries
}

/**
 * Asks [client] how [program] can be recorded (its subscription templates). Not recordable without a DVR or a guid, or
 * when the templates are empty; a 403 needs an admin; any other failure is a failed recording.
 */
suspend fun recordEntriesFor(client: MediaBackend, program: LiveTvProgram): RecordEntries {
    val dvr = client.liveTvDvr
    val guid = program.guid
    if (dvr == null || guid.isNullOrEmpty()) return RecordEntries.Unavailable(LiveTvMessage(T.liveTv.recordNotAvailable, isError = true))
    val templates = try {
        dvr.getSubscriptionTemplate(guid)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e(TAG, e) { "Recording template failed" }
        val text = if (e is MediaServerHttpException && e.statusCode == 403) T.liveTv.dvrAdminRequired else T.liveTv.recordingFailed
        return RecordEntries.Unavailable(LiveTvMessage(text, isError = true))
    }
    val entries = templates.flatMap { it.subscriptions }
    if (entries.isEmpty()) return RecordEntries.Unavailable(LiveTvMessage(T.liveTv.recordNotAvailable, isError = true))
    return RecordEntries.Ready(entries)
}

/** The confirmation before cancelling [grab]. */
fun cancelGrabConfirmation(grab: MediaGrabOperation): LiveTvConfirmation = LiveTvConfirmation(
    title = T.liveTv.cancelRecordingTitle,
    message = T.liveTv.cancelRecordingMessage(title = grab.program?.displayTitle.orEmpty()),
    confirmText = T.liveTv.cancelRecording,
)

/** The confirmation before deleting the rule titled [title]. */
fun deleteRuleConfirmation(title: String?): LiveTvConfirmation = LiveTvConfirmation(
    title = T.liveTv.deleteRuleTitle,
    message = T.liveTv.deleteRuleMessage(title = title.orEmpty()),
    confirmText = T.liveTv.deleteRule,
)

/** What a recording change did: whether it went through, and the snackbar saying so. */
data class RecordingChange(val done: Boolean, val message: LiveTvMessage)

/** Cancels [grab] on [client] by its operation key. */
suspend fun cancelGrab(client: MediaBackend, grab: MediaGrabOperation): RecordingChange {
    val dvr = client.liveTvDvr
    val operationKey = grab.operationKey
    if (dvr == null || operationKey.isEmpty()) return RecordingChange(false, LiveTvMessage(T.liveTv.recordingFailed, isError = true))
    return change("Cancelling recording failed", T.liveTv.recordingCancelled) { dvr.cancelGrab(operationKey) }
}

/** Deletes the rule [ruleKey] on [client]. */
suspend fun deleteRecordingRule(client: MediaBackend, ruleKey: String): RecordingChange {
    val dvr = client.liveTvDvr ?: return RecordingChange(false, LiveTvMessage(T.liveTv.recordingFailed, isError = true))
    return change("Deleting recording rule failed", T.liveTv.recordingRuleDeleted) { dvr.deleteRecordingRule(ruleKey) }
}

private suspend fun change(failure: String, success: String, action: suspend () -> Unit): RecordingChange = try {
    action()
    RecordingChange(true, LiveTvMessage(success))
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { failure }
    RecordingChange(false, LiveTvMessage(T.liveTv.recordingFailed, isError = true))
}

private const val TAG = "LiveTvRecordings"
