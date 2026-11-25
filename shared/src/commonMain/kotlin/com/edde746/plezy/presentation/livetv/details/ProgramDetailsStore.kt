package com.edde746.plezy.presentation.livetv.details

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.presentation.livetv.liveTvDuration
import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.presentation.livetv.recordings.LiveTvConfirmation
import com.edde746.plezy.presentation.livetv.recordings.RecordEntries
import com.edde746.plezy.presentation.livetv.recordings.RecordOptionsMode
import com.edde746.plezy.presentation.livetv.recordings.RecordOptionsStore
import com.edde746.plezy.presentation.livetv.recordings.RecordOutcome
import com.edde746.plezy.presentation.livetv.recordings.deleteRecordingRule
import com.edde746.plezy.presentation.livetv.recordings.deleteRuleConfirmation
import com.edde746.plezy.presentation.livetv.recordings.recordEntriesFor
import com.edde746.plezy.presentation.livetv.recordings.recordOutcomeMessage
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ServerSettingsRepository
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.Instant

/** What the screen showing a program's details does for it. */
interface ProgramDetailsHost {
    /** Tunes [channel] (the sheet has closed). */
    fun tune(channel: LiveTvChannel)

    /** [program] was scheduled (true) or its rule deleted (false) from the sheet: the guide's recording dot follows. */
    fun recordingChanged(program: LiveTvProgram, scheduled: Boolean)

    /** Shows [message] as a snackbar on the screen, which outlives the sheet. */
    fun showMessage(message: LiveTvMessage)

    /** Closes the sheet ([ProgramDetailsStore.release] it). */
    fun closeDetails()
}

/**
 * A program's details sheet: the [poster] (80×120), [title] with the [premiereBadge] and [liveBadge] (airing) or
 * [endedBadge] (aired) pills, [info] ("{channel} · {start} - {end} · {duration}"), the collapsible [summary] (four
 * lines), the [actions] in a row. Over it: the Record Options page ([recordOptions]) and the delete-rule [confirmation].
 */
data class ProgramDetailsUiState(
    val poster: Artwork?,
    val title: String,
    val premiereBadge: String?,
    val liveBadge: String?,
    val endedBadge: String?,
    val info: String,
    val summary: String?,
    val actions: List<ProgramAction>,
    val recordOptions: RecordOptionsStore? = null,
    val confirmation: LiveTvConfirmation? = null,
)

/** A button of the sheet: [filled] or tonal. */
data class ProgramAction(val kind: ProgramActionKind, val label: String, val filled: Boolean)

enum class ProgramActionKind { PLAY, WATCH_CHANNEL, RECORD, MANAGE }

/**
 * The program details sheet's state. Play (airing now) or Watch channel shows when the program's [channel] is known.
 * Record or Manage recording shows when [client] records ([liveTvDvr]) and the program has a guid, once the sheet
 * knows which (Record only until the program ends): an airing tagged with its rule ([LiveTvProgram.recordingRuleKey])
 * is managed at once; otherwise the provider's subscription mapping for its ratingKey says (a failure means Record).
 * Manage deletes the rule after a confirmation; Record opens the Record Options page. Either reports the new recording
 * state to the [host] and closes.
 */
class ProgramDetailsStore(
    private val program: LiveTvProgram,
    private val channel: LiveTvChannel?,
    private val client: MediaBackend?,
    private val posterThumb: String?,
    private val serverSettings: ServerSettingsRepository,
    private val host: ProgramDetailsHost,
    use24HourClock: Boolean,
    parentScope: CoroutineScope,
    private val now: () -> Instant = { Clock.System.now() },
    private val utcOffset: (Long) -> Int = ::localUtcOffsetSeconds,
) {
    private val scope = parentScope.childScope()
    private val canRecord = client?.liveTvDvr != null && !program.guid.isNullOrEmpty()
    private var mappingChecked = !canRecord
    private var existing: MediaSubscription? = null
    private var pendingDelete: MediaSubscription? = null

    private val mutableState = MutableStateFlow(snapshot(use24HourClock))
    val state: StateFlow<ProgramDetailsUiState> = mutableState.asStateFlow()

    init {
        if (canRecord) scope.launch { checkMapping() }
    }

    fun act(kind: ProgramActionKind) {
        if (state.value.actions.none { it.kind == kind }) return
        when (kind) {
            ProgramActionKind.PLAY, ProgramActionKind.WATCH_CHANNEL -> channel?.let {
                host.closeDetails()
                host.tune(it)
            }
            ProgramActionKind.MANAGE -> existing?.let {
                pendingDelete = it
                mutableState.value = mutableState.value.copy(confirmation = deleteRuleConfirmation(it.title))
            }
            ProgramActionKind.RECORD -> scope.launch { record() }
        }
    }

    /** Deletes the rule the confirmation asked about. */
    fun confirm() {
        val rule = pendingDelete ?: return
        val client = client ?: return
        pendingDelete = null
        mutableState.value = mutableState.value.copy(confirmation = null)
        scope.launch {
            val change = deleteRecordingRule(client, rule.key)
            host.showMessage(change.message)
            if (change.done) {
                host.recordingChanged(program, false)
                host.closeDetails()
            }
        }
    }

    fun dismissConfirmation() {
        pendingDelete = null
        mutableState.value = mutableState.value.copy(confirmation = null)
    }

    fun release() {
        state.value.recordOptions?.release()
        scope.cancel()
    }

    private suspend fun record() {
        val client = client ?: return
        when (val entries = recordEntriesFor(client, program)) {
            is RecordEntries.Unavailable -> host.showMessage(entries.message)
            is RecordEntries.Ready -> {
                val options = RecordOptionsStore(client, serverSettings, RecordOptionsMode.Create(program.displayTitle, entries.entries), scope) { outcome ->
                    state.value.recordOptions?.release()
                    mutableState.value = mutableState.value.copy(recordOptions = null)
                    recordOutcomeMessage(outcome)?.let(host::showMessage)
                    if (outcome == RecordOutcome.SCHEDULED || outcome == RecordOutcome.ALREADY_SCHEDULED) {
                        host.recordingChanged(program, true)
                        host.closeDetails()
                    }
                }
                mutableState.value = mutableState.value.copy(recordOptions = options)
            }
        }
    }

    private suspend fun checkMapping() {
        val ruleKey = program.recordingRuleKey
        if (ruleKey != null) {
            existing = MediaSubscription(key = ruleKey, title = program.grandparentTitle ?: program.title)
        } else {
            val providerId = program.providerIdentifier
            val ratingKey = program.ratingKey
            val dvr = client?.liveTvDvr
            if (dvr != null && !providerId.isNullOrEmpty() && !ratingKey.isNullOrEmpty()) {
                existing = try {
                    dvr.fetchSubscriptionMapping(providerId, listOf(ratingKey)).firstOrNull { it.key.isNotEmpty() }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    // No DVR access or a transient failure: the airing reads as not scheduled.
                    Log.d(TAG, e) { "Subscription mapping failed" }
                    null
                }
            }
        }
        mappingChecked = true
        mutableState.value = mutableState.value.copy(actions = actions())
    }

    private fun actions(): List<ProgramAction> = buildList {
        if (channel != null) {
            if (program.isAiringAt(now().epochSeconds)) {
                add(ProgramAction(ProgramActionKind.PLAY, T.common.play, filled = true))
            } else {
                add(ProgramAction(ProgramActionKind.WATCH_CHANNEL, T.liveTv.watchChannel, filled = false))
            }
        }
        if (canRecord && mappingChecked) {
            if (existing != null) {
                add(ProgramAction(ProgramActionKind.MANAGE, T.liveTv.manageRecording, filled = true))
            } else if (!hasEnded()) {
                add(ProgramAction(ProgramActionKind.RECORD, T.liveTv.record, filled = true))
            }
        }
    }

    private fun hasEnded(): Boolean = program.endsAt?.let { it <= now().epochSeconds } == true

    private fun snapshot(use24HourClock: Boolean): ProgramDetailsUiState {
        val begins = program.beginsAt
        val ends = program.endsAt
        val info = listOfNotNull(
            channel?.displayName,
            if (begins != null && ends != null) "${clockTime(begins, use24HourClock, utcOffset)} - ${clockTime(ends, use24HourClock, utcOffset)}" else null,
            program.durationMinutes.takeIf { it > 0 }?.let(::liveTvDuration),
        ).joinToString(" · ")
        return ProgramDetailsUiState(
            poster = Artwork.of(client, posterThumb, ImageKind.POSTER),
            title = program.displayTitle,
            premiereBadge = if (program.premiere == true) T.liveTv.premiereBadge else null,
            liveBadge = if (program.isAiringAt(now().epochSeconds)) T.liveTv.live else null,
            endedBadge = if (hasEnded()) T.liveTv.endedBadge else null,
            info = info,
            summary = program.summary?.takeIf { it.isNotEmpty() },
            actions = actions(),
        )
    }

    private companion object {
        const val TAG = "ProgramDetailsStore"
    }
}
