package com.edde746.plezy.presentation.metadata

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.metadata.MetadataDraft
import com.edde746.plezy.metadata.MetadataEditAdapter
import com.edde746.plezy.metadata.metadataStringListEquals
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.PlexMappers
import com.edde746.plezy.plex.unmatchItem
import com.edde746.plezy.presentation.browse.isAdminActionAllowed
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.settings.json.RecentTags
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** What the metadata screens need from the app. */
class MetadataEditDeps(
    /** The client of a server, online or not. */
    val client: (ServerId) -> MediaBackend?,
    /** The active profile's recent tags of a field on a server ([RecentTags]); none without a profile. */
    val recentTags: suspend (serverId: String, fieldId: String) -> List<String>,
    /** Records tags just applied to a field on a server for the active profile; nothing without a profile. */
    val addRecentTags: suspend (tags: List<String>, serverId: String, fieldId: String) -> Unit,
    /** Shows a message over the app, which outlives the screen that shows it. */
    val notify: (String) -> Unit,
    /** Leaves a screen. */
    val close: (Route) -> Unit,
    /** An item was edited or its editor closed: who shows it refreshes it. */
    val edited: (ServerId, String) -> Unit,
) {
    internal fun client(route: Route.MetadataEdit) = client(route.serverId)
}

/** A metadata entry of an item's menu, in the order a menu lists them. */
enum class MetadataAction { EDIT, QUICK_TAG, MATCH, UNMATCH }

/** [label]: "Edit…", "Quick Tag…", "Match…" or "Fix Match…", "Unmatch". */
data class MetadataMenuEntry(val action: MetadataAction, val label: String)

object MetadataMenu {
    /**
     * [item]'s metadata entries for an admin ([admin]): Edit where [client]'s editor takes the item's kind, Quick Tag on
     * movies and shows, and on Plex movies and shows Match ("Fix Match…" once matched) and, once matched, Unmatch.
     */
    fun entries(item: MediaItem, client: MediaBackend?, admin: Boolean): List<MetadataMenuEntry> {
        if (!admin) return emptyList()
        val movieOrShow = item.kind == MediaKind.MOVIE || item.kind == MediaKind.SHOW
        val canEdit = MetadataEditAdapter.supports(client, item.kind)
        val unmatched = PlexMappers.isUnmatched(item.guid)
        return listOfNotNull(
            MetadataMenuEntry(MetadataAction.EDIT, T.metadataEdit.editMetadata).takeIf { canEdit },
            MetadataMenuEntry(MetadataAction.QUICK_TAG, T.metadataEdit.quickTag).takeIf { canEdit && movieOrShow },
            if (item.backend == BackendKind.PLEX && movieOrShow) {
                MetadataMenuEntry(MetadataAction.MATCH, if (unmatched) T.matchScreen.match else T.matchScreen.fixMatch)
            } else {
                null
            },
            MetadataMenuEntry(MetadataAction.UNMATCH, T.matchScreen.unmatch).takeIf { item.backend == BackendKind.PLEX && movieOrShow && !unmatched },
        )
    }
}

/**
 * Metadata editing in the app: the menu entries of an item, the editor's and the match screen's stores, Quick Tag and
 * Unmatch. [isOwnerOrAdmin] and [activeProfile] gate the entries ([isAdminActionAllowed]).
 */
class MetadataEditing(
    private val deps: MetadataEditDeps,
    private val navigator: PlezyNavigator,
    private val isOwnerOrAdmin: (ServerId) -> Boolean,
    private val activeProfile: () -> Profile?,
    private val scope: CoroutineScope,
) {
    private val mutableEdited = MutableSharedFlow<EditedItem>(extraBufferCapacity = 16)

    /** Items edited (or whose editor closed): a screen showing one refreshes it. */
    val edited: SharedFlow<EditedItem> = mutableEdited.asSharedFlow()

    private val mutableQuickTag = MutableStateFlow<QuickTagStore?>(null)
    private val mutableUnmatchPrompt = MutableStateFlow<MediaItem?>(null)

    /** The Quick Tag an item's menu started ([startQuickTag]), which the app draws over every screen; null for none. */
    val quickTag: StateFlow<QuickTagStore?> = mutableQuickTag.asStateFlow()

    /** The item an item's menu asked to unmatch ([askUnmatch]), whose confirmation the app draws; null for none. */
    val unmatchPrompt: StateFlow<MediaItem?> = mutableUnmatchPrompt.asStateFlow()

    internal fun onEdited(serverId: ServerId, itemId: String) {
        mutableEdited.tryEmit(EditedItem(serverId, itemId))
    }

    /** Starts Quick Tag on [item] in place of one still open. */
    fun startQuickTag(item: MediaItem) {
        mutableQuickTag.value?.cancel()
        mutableQuickTag.value = open(MetadataAction.QUICK_TAG, item)
    }

    /** The Quick Tag the app draws is over ([QuickTagUiState.done]): it goes. */
    fun quickTagDone() {
        mutableQuickTag.value = null
    }

    /** Asks to confirm unmatching [item] ([unmatchPrompt]). */
    fun askUnmatch(item: MediaItem) {
        mutableUnmatchPrompt.value = item
    }

    /** The confirmation is gone, answered either way; confirming also calls [unmatch] with its item. */
    fun dismissUnmatch() {
        mutableUnmatchPrompt.value = null
    }

    /** [item]'s metadata entries for the signed-in user. */
    fun menu(item: MediaItem): List<MetadataMenuEntry> {
        val serverId = item.serverId?.let(::ServerId) ?: return emptyList()
        val admin = isAdminActionAllowed(isOwnerOrAdmin(serverId), item.backend, activeProfile())
        return MetadataMenu.entries(item, deps.client(serverId), admin)
    }

    /** Opens the editor or the match screen of [item]; for [MetadataAction.QUICK_TAG] the store its dialog shows. */
    fun open(action: MetadataAction, item: MediaItem): QuickTagStore? {
        val serverId = item.serverId?.let(::ServerId) ?: return null
        when (action) {
            MetadataAction.EDIT -> navigator.navigate(Route.MetadataEdit(serverId, item.id))
            MetadataAction.MATCH -> navigator.navigate(
                Route.PlexMatch(serverId, item.id, item.title.orEmpty(), item.year, matched = !PlexMappers.isUnmatched(item.guid)),
            )
            MetadataAction.QUICK_TAG -> return QuickTagStore(item, serverId, deps, scope)
            MetadataAction.UNMATCH -> Unit
        }
        return null
    }

    /** The editor's store of [route], kept while the route is on a stack. */
    fun editor(route: Route.MetadataEdit): MetadataEditStore? =
        navigator.retain(route, KEY, { MetadataEditStore(route, deps, scope) }, MetadataEditStore::close)

    /** The match screen's store of [route], kept while the route is on a stack. */
    fun match(route: Route.PlexMatch): PlexMatchStore? =
        navigator.retain(route, KEY, { PlexMatchStore(route, deps, scope) }, PlexMatchStore::close)

    /** Clears [item]'s Plex match, after the user confirmed ([UnmatchConfirm]); says how it went. */
    fun unmatch(item: MediaItem) {
        val serverId = item.serverId?.let(::ServerId) ?: return
        scope.launch {
            try {
                val client = deps.client(serverId) as? PlexClient ?: throw IllegalStateException("No Plex server $serverId")
                if (client.unmatchItem(item.id)) {
                    deps.notify(T.matchScreen.unmatchSuccess)
                    deps.edited(serverId, item.id)
                } else {
                    deps.notify(T.matchScreen.unmatchFailed)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Unmatch failed" }
                deps.notify(T.messages.errorLoading(localizedErrorReason(e)))
            }
        }
    }

    private companion object {
        const val KEY = "metadata"
        const val TAG = "MetadataEditing"
    }
}

data class EditedItem(val serverId: ServerId, val itemId: String)

/** Unmatch's destructive confirmation: its title and button "Unmatch". */
object UnmatchConfirm {
    val title: String get() = T.matchScreen.unmatch
    val message: String get() = T.matchScreen.unmatchConfirm
    val confirm: String get() = T.matchScreen.unmatch
    val cancel: String get() = T.common.cancel
}

/**
 * Quick Tag on a movie or show: a spinner while the item loads, then the Label tag dialog with recent and server tags;
 * Save writes the labels unless they are the same set, with the spinner again, and says how it went. [done] once
 * it is over: the UI drops it.
 */
class QuickTagStore internal constructor(
    private val item: MediaItem,
    private val serverId: ServerId,
    private val deps: MetadataEditDeps,
    private val scope: CoroutineScope,
) {
    private val adapter = MetadataEditAdapter.of(deps.client(serverId))
    private var draft: MetadataDraft? = null
    private val mutableState = MutableStateFlow(QuickTagUiState(busy = true))

    val state: StateFlow<QuickTagUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            try {
                val adapter = adapter ?: return@launch finish()
                val loaded = adapter.load(item)
                val field = adapter.schema(loaded).flatMap { it.fields }.firstOrNull { it.id == LABEL } ?: return@launch finish()
                draft = loaded
                val existing = loaded.list(LABEL)
                val tags = TagEditStore(field.label, existing, {
                    val recent = deps.recentTags(serverId.value, LABEL)
                    RecentTags.mergeSuggestions(recent, adapter.tagSuggestions(loaded, field), existing)
                }, scope)
                mutableState.value = QuickTagUiState(busy = false, tags = tags)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Quick tag load failed" }
                deps.notify(T.metadataEdit.metadataUpdateFailed)
                finish()
            }
        }
    }

    /** The dialog's Save: writes the labels unless they're the same set as before. */
    fun save() {
        val tags = mutableState.value.tags ?: return
        val adapter = adapter ?: return
        val loaded = draft ?: return
        val result = tags.tags
        tags.close()
        if (metadataStringListEquals(result, loaded.originalValues[LABEL])) return finish()
        mutableState.value = QuickTagUiState(busy = true)
        val added = loaded.with(LABEL, result).addedTags(adapter.schema(loaded).flatMap { it.fields }.filter { it.id == LABEL })
        scope.launch {
            val saved = try {
                adapter.save(loaded.with(LABEL, result))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Quick tag save failed" }
                null
            }
            if (saved != null) {
                added[LABEL]?.let { deps.addRecentTags(it, serverId.value, LABEL) }
                deps.notify(T.metadataEdit.metadataUpdated)
                deps.edited(serverId, item.id)
            } else {
                deps.notify(T.metadataEdit.metadataUpdateFailed)
            }
            finish()
        }
    }

    /** The dialog's Cancel (or Back): nothing is written. */
    fun cancel() {
        mutableState.value.tags?.close()
        finish()
    }

    private fun finish() {
        mutableState.value = QuickTagUiState(busy = false, done = true)
    }

    private companion object {
        const val LABEL = "label"
        const val TAG = "QuickTag"
    }
}

/** [busy]: the blocking spinner; [tags]: the Label dialog; [done]: over. */
data class QuickTagUiState(val busy: Boolean, val tags: TagEditStore? = null, val done: Boolean = false)
