package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.data.downloads.SyncRule
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.MultiServerState
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

/** A rule's symbol: a show or season, a collection, a playlist. */
enum class SyncRuleIcon { SHOW, COLLECTION, PLAYLIST }

/**
 * One rule of the Sync rules screen. [title] is its item's (the rating key until known); [subtitle] what it keeps;
 * [serverLine] its server and whether that server is available to the active profile.
 */
data class SyncRuleRow(
    val globalKey: String,
    val icon: SyncRuleIcon,
    val title: String,
    val subtitle: String,
    val serverLine: String,
    val enabled: Boolean,
    val isListRule: Boolean,
)

data class SyncRulesUiState(val rules: List<SyncRuleRow> = emptyList(), val message: DownloadFeedback? = null) {
    val title: String get() = T.downloads.activeSyncRules
    val empty: String get() = T.downloads.noSyncRules
    val removeLabel: String get() = T.downloads.removeSyncRule
}

/**
 * The Sync rules screen: the active profile's rules with their server's status, the enabled switch ([setEnabled]),
 * the edit on a press ([edit]: a list rule's filter, a show's or season's episode count, 0 offering removal) and the
 * removal ([remove], asking first; a list rule may also delete the downloads only it holds).
 *
 * @param servers the servers' state: which the profile reaches, which are online, which refuse it.
 * @param activeServerName a connected server's name, null when not connected.
 * @param knownServerName a server's name from the saved connections, null when unknown.
 *
 * Main thread only; [release] when the screen goes.
 */
class SyncRulesStore(
    private val controller: DownloadsController,
    private val actions: DownloadActions,
    private val servers: StateFlow<MultiServerState>,
    private val activeServerName: (ServerId) -> String?,
    private val knownServerName: (String) -> String?,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var message: DownloadFeedback? = null
    private val mutableState = MutableStateFlow(SyncRulesUiState())
    val state: StateFlow<SyncRulesUiState> = mutableState.asStateFlow()

    init {
        scope.launch { combine(controller.changes, servers) { _, _ -> }.collect { publish() } }
    }

    fun setEnabled(globalKey: String, enabled: Boolean) = run { controller.updateSyncRuleOptions(globalKey, enabled = enabled); null }

    fun edit(globalKey: String) = run { actions.manageSyncRule(globalKey, titleOf(globalKey)) }

    fun remove(globalKey: String) = run { actions.confirmAndRemoveSyncRule(globalKey, titleOf(globalKey)) }

    fun messageShown() {
        message = null
        publish()
    }

    fun release() = scope.cancel()

    private fun run(block: suspend () -> DownloadFeedback?) {
        scope.launch {
            val feedback = try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Sync rule change failed" }
                DownloadFeedback(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
            }
            if (feedback != null) {
                message = feedback
                publish()
            }
        }
    }

    private fun ruleMetadata(rule: SyncRule) =
        controller.metadata[rule.globalKey] ?: ServerId.tryParse(rule.serverId)?.let { controller.metadata[buildGlobalKey(it, rule.ratingKey)] }

    private fun titleOf(globalKey: String): String {
        val rule = controller.getSyncRule(globalKey) ?: return globalKey
        return ruleMetadata(rule)?.title ?: rule.ratingKey
    }

    private fun publish() {
        val state = servers.value
        mutableState.value = SyncRulesUiState(controller.syncRules.values.map { row(it, state) }, message)
    }

    private fun row(rule: SyncRule, state: MultiServerState): SyncRuleRow {
        val meta = ruleMetadata(rule)
        val serverId = ServerId.tryParse(rule.serverId)
        val name = serverId?.let(activeServerName)?.takeIf { it.isNotEmpty() }
            ?: meta?.serverName?.takeIf { it.isNotEmpty() }
            ?: knownServerName(rule.serverId)?.takeIf { it.isNotEmpty() }
        val status = when {
            name == null -> T.downloads.syncRuleUnknownServer
            serverId in state.authErrorServerIds -> T.downloads.syncRuleSignInRequired
            state.accessDeniedServers.any { it.serverId == serverId } -> T.downloads.syncRuleAccessDenied
            serverId !in state.serverIds -> T.downloads.syncRuleNotAvailableForProfile
            serverId in state.onlineServerIds -> T.downloads.syncRuleAvailable
            else -> T.downloads.syncRuleOffline
        }
        return SyncRuleRow(
            globalKey = rule.globalKey,
            icon = when (rule.target) {
                SyncRuleTarget.PLAYLIST -> SyncRuleIcon.PLAYLIST
                SyncRuleTarget.COLLECTION -> SyncRuleIcon.COLLECTION
                SyncRuleTarget.SHOW, SyncRuleTarget.SEASON -> SyncRuleIcon.SHOW
            },
            title = meta?.title ?: rule.ratingKey,
            subtitle = when {
                !rule.isListRule -> T.downloads.keepNUnwatched(count = rule.episodeCount.toString())
                rule.downloadFilter == SyncRuleFilter.ALL -> T.downloads.syncAllItems
                else -> T.downloads.syncUnwatchedItems
            },
            serverLine = T.downloads.syncRuleServerContext(server = name ?: rule.serverId, status = status),
            enabled = rule.enabled,
            isListRule = rule.isListRule,
        )
    }

    private companion object {
        const val TAG = "SyncRules"
    }
}
