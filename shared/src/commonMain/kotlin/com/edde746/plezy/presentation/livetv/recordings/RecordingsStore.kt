package com.edde746.plezy.presentation.livetv.recordings

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.liveTvDvr
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.LiveTvRecordingsTab
import com.edde746.plezy.presentation.livetv.LiveTvRefreshGate
import com.edde746.plezy.presentation.livetv.LiveTvRefreshResumeReason
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.presentation.livetv.liveTvDuration
import com.edde746.plezy.presentation.livetv.liveTvRelativeDay
import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.presentation.livetv.forEachLiveTvServer
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ServerSettingsRepository
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/**
 * The Scheduled tab ([com.edde746.plezy.presentation.livetv.LiveTvTab.RECORDINGS]): [body] is a spinner until the
 * first load, a message with the record icon when there is nothing to list, else the "Upcoming" group ([grabs]) and the
 * "Recording Rules" group ([rules]). Over it: the [ruleMenu] picker, a [confirmation] dialog, the Edit rule sheet
 * ([recordOptions]) and a snackbar ([message]).
 */
data class RecordingsUiState(
    val body: RecordingsBody = RecordingsBody.Loading,
    val scheduledTitle: String = T.liveTv.upcomingRecordings,
    val rulesTitle: String = T.liveTv.recordingRules,
    val ruleMenu: RuleMenu? = null,
    val confirmation: LiveTvConfirmation? = null,
    val recordOptions: RecordOptionsStore? = null,
    val message: LiveTvMessage? = null,
)

sealed interface RecordingsBody {
    data object Loading : RecordingsBody

    /** Nothing to list: "DVR admin required", "Recording failed" or "No scheduled recordings". */
    data class Empty(val text: String) : RecordingsBody

    /** Either list may be empty (its group is then hidden), not both. */
    data class Lists(val grabs: List<GrabRow>, val rules: List<RuleRow>) : RecordingsBody
}

/**
 * A scheduled or running recording: [subtitle] is "{day} · {time} · {duration} · {call sign}"; a running one
 * ([recording]) is tinted and carries the red [pill] "Recording now", a failed one the error [pill].
 */
data class GrabRow(val id: String, val title: String, val subtitle: String, val recording: Boolean, val failed: Boolean, val pill: String?)

/** A rule: [subtitle] is "Record series/episode · {airings} · {n} scheduled". */
data class RuleRow(val id: String, val title: String, val subtitle: String)

/** The Edit / Delete picker for the rule titled [title]. */
data class RuleMenu(val title: String, val actions: List<RuleMenuAction>)

data class RuleMenuAction(val action: RuleAction, val label: String)

enum class RuleAction { EDIT, DELETE }

/**
 * The Recordings tab's state: every Live TV server's scheduled recordings and recording rules, merged (each server
 * once). Recordings sort by start; rules series first, then by title.
 *
 * Loads run one at a time: one asked for during a load runs once after it ([reload] coalesces). A load commits only
 * the servers that answered; when none did, a 403 from any says the DVR needs an admin, else the load failed. The tab
 * refreshes every 30 s while [refresh] is open and reloads at once when the tab is selected again.
 *
 * Tapping a recording asks to cancel it; tapping a rule offers Edit (the Edit rule sheet) and Delete (after a
 * confirmation). Each change reloads the lists.
 */
class RecordingsStore(
    private val servers: LiveTvServers,
    private val serverSettings: ServerSettingsRepository,
    private var use24HourClock: Boolean,
    appForeground: StateFlow<Boolean>,
    parentScope: CoroutineScope,
    private val now: () -> Instant = { Clock.System.now() },
    private val utcOffset: (Long) -> Int = ::localUtcOffsetSeconds,
) : LiveTvRecordingsTab {
    private val scope = parentScope.childScope()

    private class Grab(val id: String, val client: MediaBackend, val operation: MediaGrabOperation)

    private class Rule(val id: String, val client: MediaBackend, val rule: MediaSubscription)

    private var grabs: List<Grab> = emptyList()
    private var rules: List<Rule> = emptyList()
    private var loading = true
    private var answered = false
    private var failure: String? = null
    private var loadJob: Job? = null
    private var loadPending = false
    private var pendingRule: Rule? = null
    private var pendingAction: (suspend () -> Unit)? = null

    private val mutableState = MutableStateFlow(RecordingsUiState())
    val state: StateFlow<RecordingsUiState> = mutableState.asStateFlow()

    override val refresh = LiveTvRefreshGate(
        parentScope = scope,
        interval = REFRESH_INTERVAL,
        appForeground = appForeground,
        onTick = { reload() },
        onResumed = { if (it == LiveTvRefreshResumeReason.TAB_SELECTED) reload() },
    )

    init {
        reload()
    }

    override fun reload() {
        if (loadJob?.isActive == true) {
            loadPending = true
            return
        }
        loadJob = scope.launch {
            do {
                loadPending = false
                loadOnce()
            } while (loadPending)
        }
    }

    /** Asks to cancel the recording [id] of [RecordingsBody.Lists.grabs]. */
    fun tapGrab(id: String) {
        val grab = grabs.firstOrNull { it.id == id } ?: return
        if (grab.client.liveTvDvr == null || grab.operation.operationKey.isEmpty()) {
            return update { it.copy(message = LiveTvMessage(T.liveTv.recordingFailed, isError = true)) }
        }
        ask(cancelGrabConfirmation(grab.operation)) {
            val change = cancelGrab(grab.client, grab.operation)
            update { it.copy(message = change.message) }
            if (change.done) reload()
        }
    }

    /** Offers Edit and Delete for the rule [id] of [RecordingsBody.Lists.rules]. */
    fun tapRule(id: String) {
        val rule = rules.firstOrNull { it.id == id } ?: return
        pendingRule = rule
        update {
            it.copy(
                ruleMenu = RuleMenu(
                    title = rule.rule.title.orEmpty(),
                    actions = listOf(RuleMenuAction(RuleAction.EDIT, T.liveTv.editRuleAction), RuleMenuAction(RuleAction.DELETE, T.common.delete)),
                ),
            )
        }
    }

    /** The rule picker's choice; null dismisses it. */
    fun chooseRuleAction(action: RuleAction?) {
        val rule = pendingRule ?: return
        pendingRule = null
        update { it.copy(ruleMenu = null) }
        when (action) {
            RuleAction.EDIT -> editRule(rule)
            RuleAction.DELETE -> ask(deleteRuleConfirmation(rule.rule.title)) {
                val change = deleteRecordingRule(rule.client, rule.rule.key)
                update { it.copy(message = change.message) }
                if (change.done) reload()
            }
            null -> Unit
        }
    }

    fun confirm() {
        val action = pendingAction ?: return
        pendingAction = null
        update { it.copy(confirmation = null) }
        scope.launch { action() }
    }

    fun dismissConfirmation() {
        pendingAction = null
        update { it.copy(confirmation = null) }
    }

    fun messageShown() = update { it.copy(message = null) }

    /** The system's clock format changed. */
    fun setUse24HourClock(value: Boolean) {
        if (use24HourClock == value) return
        use24HourClock = value
        publish()
    }

    fun release() {
        state.value.recordOptions?.release()
        refresh.close()
        scope.cancel()
    }

    private fun editRule(rule: Rule) {
        val options = RecordOptionsStore(rule.client, serverSettings, RecordOptionsMode.Edit(rule.rule), scope) { outcome ->
            state.value.recordOptions?.release()
            update { it.copy(recordOptions = null, message = editOutcomeMessage(outcome) ?: it.message) }
            if (outcome == RecordOutcome.UPDATED) reload()
        }
        update { it.copy(recordOptions = options) }
    }

    private fun ask(confirmation: LiveTvConfirmation, action: suspend () -> Unit) {
        pendingAction = action
        update { it.copy(confirmation = confirmation) }
    }

    private suspend fun loadOnce() {
        // The spinner shows while no server has answered yet.
        if (!answered) {
            loading = true
            publish()
        }
        val loadedGrabs = mutableListOf<Grab>()
        val loadedRules = mutableListOf<Rule>()
        var anyAnswered = false
        var adminError = false
        var otherError = false
        servers.forEachLiveTvServer(
            onError = { _, entry, error ->
                Log.e(TAG, error) { "Recordings failed for ${entry.serverId}" }
                if (error is MediaServerHttpException && error.statusCode == 403) adminError = true else otherError = true
            },
        ) { client, entry ->
            val dvr = client.liveTvDvr ?: return@forEachLiveTvServer
            val serverGrabs = dvr.fetchScheduledRecordings()
            val serverRules = dvr.fetchRecordingRules()
            anyAnswered = true
            serverGrabs.forEach { loadedGrabs += Grab("${entry.serverId}\u0000${it.id}\u0000${loadedGrabs.size}", client, it) }
            serverRules.forEach { loadedRules += Rule("${entry.serverId}\u0000${it.key}\u0000${loadedRules.size}", client, it) }
        }
        grabs = loadedGrabs.sortedBy { it.operation.program?.beginsAt ?: 0 }
        rules = loadedRules.sortedWith(compareBy<Rule> { it.rule.type ?: 0 }.thenBy { it.rule.title.orEmpty() })
        answered = anyAnswered
        loading = false
        failure = when {
            anyAnswered -> null
            adminError -> T.liveTv.dvrAdminRequired
            otherError -> T.liveTv.recordingFailed
            else -> null
        }
        publish()
    }

    private fun publish() {
        val failure = failure
        val body = when {
            loading -> RecordingsBody.Loading
            failure != null -> RecordingsBody.Empty(failure)
            grabs.isEmpty() && rules.isEmpty() -> RecordingsBody.Empty(T.liveTv.noScheduledRecordings)
            else -> RecordingsBody.Lists(grabs.map(::grabRow), rules.map(::ruleRow))
        }
        update { it.copy(body = body) }
    }

    private fun grabRow(grab: Grab): GrabRow {
        val operation = grab.operation
        val program = operation.program
        val status = operation.status ?: "scheduled"
        val recording = status == "grabbing"
        val failed = status == "error"
        val begins = program?.beginsAt
        val timeText = if (begins == null) {
            ""
        } else {
            listOfNotNull(
                liveTvRelativeDay(begins, now().epochSeconds, utcOffset),
                clockTime(begins, use24HourClock, utcOffset),
                program.endsAt?.let { liveTvDuration(((it - begins) / 60).toInt()) }?.takeIf { it.isNotEmpty() },
            ).joinToString(" · ")
        }
        return GrabRow(
            id = grab.id,
            title = program?.displayTitle ?: operation.key.orEmpty(),
            subtitle = listOfNotNull(timeText.takeIf { it.isNotEmpty() }, program?.channelCallSign?.takeIf { it.isNotEmpty() }).joinToString(" · "),
            recording = recording,
            failed = failed,
            pill = when {
                recording -> T.liveTv.recordingInProgress
                failed -> T.common.error
                else -> null
            },
        )
    }

    private fun ruleRow(rule: Rule): RuleRow {
        val subscription = rule.rule
        val parts = listOfNotNull(
            if (subscription.type == MediaSubscription.TYPE_SERIES) T.liveTv.recordSeries else T.liveTv.recordEpisode,
            subscription.airingsType?.takeIf { it.isNotEmpty() },
            subscription.grabOperations.size.takeIf { it > 0 }?.let { T.liveTv.recordingsCount(count = it.toString()) },
        )
        return RuleRow(rule.id, subscription.title.orEmpty(), parts.joinToString(" · "))
    }

    private inline fun update(change: (RecordingsUiState) -> RecordingsUiState) {
        mutableState.value = change(mutableState.value)
    }

    private companion object {
        const val TAG = "RecordingsStore"
        val REFRESH_INTERVAL = 30.seconds
    }
}
