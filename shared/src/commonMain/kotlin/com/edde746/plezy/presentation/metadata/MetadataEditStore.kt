package com.edde746.plezy.presentation.metadata

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.metadata.ArtworkFit
import com.edde746.plezy.metadata.ArtworkOption
import com.edde746.plezy.metadata.MetadataDraft
import com.edde746.plezy.metadata.MetadataEditAdapter
import com.edde746.plezy.metadata.MetadataField
import com.edde746.plezy.metadata.MetadataFieldType
import com.edde746.plezy.metadata.MetadataSaveMode
import com.edde746.plezy.metadata.metadataDate
import com.edde746.plezy.metadata.metadataStringList
import com.edde746.plezy.metadata.parseMetadataDate
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.json.RecentTags
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * The metadata editor of [route]'s item: its sections of field tiles, each opening the dialog of its type, Save for the
 * fields that wait for it, and the immediate fields (artwork, Plex's preferences) saved as they are picked. One commit
 * at a time: while one runs, every tile, Save and Back wait ([MetadataEditUiState.committing]). A successful Save
 * leaves the screen; a failure says so and keeps every edit.
 */
class MetadataEditStore(
    private val route: Route.MetadataEdit,
    private val deps: MetadataEditDeps,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var adapter: MetadataEditAdapter? = null
    private var draft: MetadataDraft? = null
    private var committing = false
    private var dialog: EditorDialog? = null
    private var load = EditorLoad.LOADING
    private val mutableState = MutableStateFlow(MetadataEditUiState())

    val state: StateFlow<MetadataEditUiState> = mutableState.asStateFlow()

    init {
        scope.launch { load() }
    }

    private suspend fun load() {
        val client = deps.client(route)
        val adapter = MetadataEditAdapter.of(client)
        try {
            val item = client?.fetchItem(route.itemId) ?: throw IllegalStateException("Item ${route.itemId} is unavailable")
            if (adapter == null || !adapter.supportsKind(item.kind)) {
                load = EditorLoad.FAILED
                return render()
            }
            draft = adapter.load(item)
            this.adapter = adapter
            load = EditorLoad.READY
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Failed to load metadata editor" }
            load = EditorLoad.FAILED
            deps.notify(T.metadataEdit.metadataUpdateFailed)
        }
        render()
    }

    /** Opens [fieldId]'s dialog; nothing while a commit runs. */
    fun edit(fieldId: String) {
        val adapter = adapter ?: return
        val draft = draft ?: return
        if (committing || dialog != null) return
        val field = fields().firstOrNull { it.id == fieldId } ?: return
        dialog = when (field.type) {
            MetadataFieldType.TEXT, MetadataFieldType.MULTILINE_TEXT ->
                EditorDialog.Text(field.id, field.label, draft.text(field.id).orEmpty(), field.type == MetadataFieldType.MULTILINE_TEXT)
            MetadataFieldType.DATE -> {
                val date = parseMetadataDate(draft.text(field.id))
                EditorDialog.Date(field.id, field.label, date?.first, date?.second, date?.third)
            }
            MetadataFieldType.STRING_LIST -> EditorDialog.Tags(field.id, tagStore(adapter, draft, field))
            MetadataFieldType.CHOICE -> EditorDialog.Choice(
                field.id,
                field.label,
                field.options.map { ChoiceOptionUi(it.value, it.label) },
                draft.text(field.id).orEmpty(),
            )
            MetadataFieldType.ARTWORK -> EditorDialog.Artwork(
                field.id,
                ArtworkPickerStore(adapter, draft, field, deps.notify, { artworkApplied() }, scope),
            )
        }
        render()
    }

    /** The text dialog's value, untrimmed. */
    fun submitText(value: String) = submit<EditorDialog.Text> { value }

    /** The date picker's day, stored `YYYY-MM-DD`. */
    fun submitDate(year: Int, month: Int, day: Int) = submit<EditorDialog.Date> { metadataDate(year, month, day) }

    /** The tag dialog's Save: its list. */
    fun submitTags() = submit<EditorDialog.Tags> { it.store.tags }

    /** A choice's Select: a draft choice only changes; an immediate one saves now and rolls back if that fails. */
    fun choose(value: String) {
        val shown = dialog as? EditorDialog.Choice ?: return
        val field = fields().firstOrNull { it.id == shown.fieldId } ?: return
        if (field.saveMode == MetadataSaveMode.DRAFT) return submit<EditorDialog.Choice> { value }
        val adapter = adapter ?: return
        val before = draft ?: return
        closeDialog()
        val previous = before.values[field.id]
        draft = before.with(field.id, value)
        committing = true
        render()
        scope.launch {
            val saved = attempt("Failed to update metadata field") { adapter.saveImmediate(before, field, value) }
            committing = false
            val current = draft
            if (saved != null && current != null) {
                draft = current.copy(originalValues = current.originalValues + (field.id to value))
            } else {
                if (current != null && current.values[field.id] == value) draft = current.with(field.id, previous)
                deps.notify(T.metadataEdit.metadataUpdateFailed)
            }
            render()
        }
    }

    /** Cancel, Back or a click outside the dialog; not while its artwork applies. */
    fun dismissDialog() {
        val shown = dialog ?: return
        if (shown is EditorDialog.Artwork && shown.store.state.value.applying) return
        closeDialog()
        render()
    }

    /** Saves the changed fields; ignored without changes or while a commit runs. */
    fun save() {
        val adapter = adapter ?: return
        val draft = draft ?: return
        if (committing || !adapter.hasChanges(draft)) return
        committing = true
        render()
        // What each tag field gained, before the save accepts it: recent tags only once the save succeeds.
        val added = draft.addedTags(fields())
        scope.launch {
            val saved = attempt("Failed to update metadata") { adapter.save(draft) }
            committing = false
            if (saved != null) {
                this@MetadataEditStore.draft = saved
                for ((fieldId, tags) in added) scope.launch { deps.addRecentTags(tags, route.serverId.value, fieldId) }
                render()
                deps.notify(T.metadataEdit.metadataUpdated)
                deps.close(route)
            } else {
                render()
                deps.notify(T.metadataEdit.metadataUpdateFailed)
            }
        }
    }

    /** The route left: whoever showed the item refreshes it, whatever happened here. */
    fun close() {
        closeDialog()
        scope.cancel()
        deps.edited(route.serverId, route.itemId)
    }

    private inline fun <reified D : EditorDialog> submit(value: (D) -> Any?) {
        val shown = dialog as? D ?: return
        val current = draft ?: return
        if (committing) return
        draft = current.with(shown.fieldId, value(shown))
        closeDialog()
        render()
    }

    private fun artworkApplied() {
        closeDialog()
        render()
        val adapter = adapter ?: return
        val shown = draft ?: return
        scope.launch {
            // Only the artwork is replaced, so pending edits stay; the artwork is saved either way.
            val item = try {
                adapter.reloadItem(shown)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Artwork reload failed" }
                null
            } ?: return@launch
            draft = draft?.let { adapter.withReloadedArtwork(it, item) }
            render()
        }
    }

    private fun closeDialog() {
        when (val shown = dialog) {
            is EditorDialog.Tags -> shown.store.close()
            is EditorDialog.Artwork -> shown.store.close()
            else -> Unit
        }
        dialog = null
    }

    private fun tagStore(adapter: MetadataEditAdapter, draft: MetadataDraft, field: MetadataField): TagEditStore {
        val existing = draft.list(field.id)
        return TagEditStore(field.label, existing, { tagSuggestions(adapter, draft, field, existing) }, scope)
    }

    /** Recent tags, then the server's, without the item's; the recent ones alone when the server's fail. */
    private suspend fun tagSuggestions(adapter: MetadataEditAdapter, draft: MetadataDraft, field: MetadataField, existing: List<String>): List<String> {
        val recent = deps.recentTags(route.serverId.value, field.id)
        return try {
            RecentTags.mergeSuggestions(recent, adapter.tagSuggestions(draft, field), existing)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Server tag suggestions failed" }
            recent
        }
    }

    private fun fields(): List<MetadataField> {
        val adapter = adapter ?: return emptyList()
        val draft = draft ?: return emptyList()
        return adapter.schema(draft).flatMap { it.fields }
    }

    private fun render() {
        val adapter = adapter
        val draft = draft
        val sections = if (adapter == null || draft == null) {
            emptyList()
        } else {
            adapter.schema(draft).filter { it.fields.isNotEmpty() }.map { section ->
                EditSectionUi(section.id, section.title, section.fields.map { tile(adapter.client, draft, it) })
            }
        }
        mutableState.value = MetadataEditUiState(
            load = load,
            sections = sections,
            canSave = !committing && adapter != null && draft != null && adapter.hasChanges(draft),
            committing = committing,
            dialog = dialog,
        )
    }

    private fun tile(client: MediaBackend, draft: MetadataDraft, field: MetadataField): EditFieldUi {
        val artwork = field.artwork
        if (artwork != null) {
            val path = draft.text(field.id)
            return EditFieldUi(
                field.id, field.label, null,
                ArtworkPreviewUi(
                    imageUrl(client, path, artwork.previewWidth * 2, artwork.previewHeight * 2, artwork.fit),
                    artwork.previewWidth,
                    artwork.previewHeight,
                    artwork.fit == ArtworkFit.CONTAIN,
                ),
            )
        }
        val value = when (field.type) {
            MetadataFieldType.STRING_LIST -> metadataStringList(draft.values[field.id]).joinToString(", ")
            MetadataFieldType.CHOICE -> draft.text(field.id).let { v -> field.options.firstOrNull { it.value == v }?.label ?: v }
            else -> draft.text(field.id)
        }
        return EditFieldUi(field.id, field.label, value?.ifEmpty { null })
    }

    private suspend fun <T> attempt(what: String, block: suspend () -> T?): T? = try {
        block()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e(TAG, e) { what }
        null
    }

    private companion object {
        const val TAG = "MetadataEdit"
    }
}

/** An image of [client]'s server at [path], sized; an absolute URL (an image provider's) through its proxy if any. */
internal fun imageUrl(client: MediaBackend, path: String?, width: Int, height: Int, fit: ArtworkFit = ArtworkFit.COVER): String? {
    if (path.isNullOrEmpty()) return null
    val cover = fit == ArtworkFit.COVER
    return if (path.startsWith("http://") || path.startsWith("https://")) {
        client.externalImageUrl(path, width, height, cover)
    } else {
        client.thumbnailUrl(path, width, height, cover)
    }
}

enum class EditorLoad { LOADING, READY, FAILED }

data class MetadataEditUiState(
    val title: String = T.metadataEdit.screenTitle,
    val load: EditorLoad = EditorLoad.LOADING,
    /** The body's text when the item can't be edited. */
    val failedText: String = T.metadataEdit.metadataUpdateFailed,
    val sections: List<EditSectionUi> = emptyList(),
    /** Save is enabled: a field that waits for Save changed, and no commit runs. */
    val canSave: Boolean = false,
    /** A save runs: Save shows a spinner; tiles and Back wait. */
    val committing: Boolean = false,
    val dialog: EditorDialog? = null,
    val saveLabel: String = T.common.save,
)

data class EditSectionUi(val id: String, val title: String, val fields: List<EditFieldUi>)

/**
 * A field's tile: [label] over [value] (null: "Not set", [notSetLabel], dimmed), or an artwork tile with its preview.
 */
data class EditFieldUi(
    val id: String,
    val label: String,
    val value: String?,
    val artwork: ArtworkPreviewUi? = null,
    val notSetLabel: String = T.metadataEdit.notSet,
)

/** A tile's artwork, [width]×[height] dp, its corners rounded 4 dp; [contain] fits it rather than filling. */
data class ArtworkPreviewUi(val imageUrl: String?, val width: Int, val height: Int, val contain: Boolean)

data class ChoiceOptionUi(val value: String, val label: String)

/** The dialog a tile opened. */
sealed interface EditorDialog {
    val fieldId: String

    data class Text(
        override val fieldId: String,
        val title: String,
        val value: String,
        val multiline: Boolean,
        val cancelLabel: String = T.common.cancel,
        val saveLabel: String = T.common.save,
    ) : EditorDialog

    /** A date picker from 1800-01-01 to 2200-12-31, on the field's day, or today without one (null [year]). */
    data class Date(
        override val fieldId: String,
        val title: String,
        val year: Int?,
        val month: Int?,
        val day: Int?,
        val cancelLabel: String = T.common.cancel,
        val saveLabel: String = T.common.save,
    ) : EditorDialog

    data class Tags(override val fieldId: String, val store: TagEditStore) : EditorDialog

    /** Arrows move between [options]; only Select ([MetadataEditStore.choose]) commits. */
    data class Choice(override val fieldId: String, val title: String, val options: List<ChoiceOptionUi>, val selected: String) : EditorDialog

    data class Artwork(override val fieldId: String, val store: ArtworkPickerStore) : EditorDialog
}

/**
 * An artwork field's picker: the server's candidates as a grid (the field's columns and aspect ratio), From URL and
 * Upload File. Picking one applies it; while it applies everything waits, and duplicate picks are ignored. Success says
 * so and closes ([onApplied]); a failure says so and stays.
 */
class ArtworkPickerStore internal constructor(
    private val adapter: MetadataEditAdapter,
    private val draft: MetadataDraft,
    private val field: MetadataField,
    private val notify: (String) -> Unit,
    private val onApplied: () -> Unit,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val config = checkNotNull(field.artwork)
    private var options: List<ArtworkOption> = emptyList()
    private val mutableState = MutableStateFlow(
        ArtworkPickerUiState(title = config.selectTitle, columns = config.gridColumns, aspectRatio = config.gridAspectRatio, contain = config.fit == ArtworkFit.CONTAIN),
    )

    val state: StateFlow<ArtworkPickerUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            options = try {
                adapter.artwork(draft, field)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to load artwork" }
                emptyList()
            }
            val width = TILE_WIDTH
            val height = (TILE_WIDTH / config.gridAspectRatio).toInt()
            mutableState.update { state ->
                state.copy(
                    loading = false,
                    tiles = options.mapIndexed { i, option ->
                        ArtworkTileUi(
                            imageUrl(adapter.client, option.thumbnailPath, width, height, config.fit),
                            option.selected,
                            if (option.selected) T.metadataEdit.selectedArtworkOption("${i + 1}") else T.metadataEdit.artworkOption("${i + 1}"),
                        )
                    },
                )
            }
        }
    }

    fun select(index: Int) {
        val option = options.getOrNull(index) ?: return
        apply { adapter.applyArtworkFromUrl(draft, field, option.sourceUrl) }
    }

    /** From URL's text, trimmed; empty does nothing. */
    fun applyUrl(url: String) {
        if (url.isBlank()) return
        apply { adapter.applyArtworkFromUrl(draft, field, url.trim()) }
    }

    /** The picked file's bytes; empty bytes do nothing. */
    fun upload(bytes: ByteArray, fileName: String?) {
        if (bytes.isEmpty()) return
        apply { adapter.uploadArtwork(draft, field, bytes, fileName) }
    }

    fun close() = scope.cancel()

    private fun apply(action: suspend () -> Boolean) {
        if (mutableState.value.applying) return
        mutableState.update { it.copy(applying = true) }
        scope.launch {
            val success = try {
                action()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Artwork update failed" }
                false
            }
            mutableState.update { it.copy(applying = false) }
            if (success) {
                notify(T.metadataEdit.artworkUpdated)
                onApplied()
            } else {
                notify(T.metadataEdit.artworkUpdateFailed)
            }
        }
    }

    private companion object {
        const val TAG = "ArtworkPicker"
        const val TILE_WIDTH = 320
    }
}

data class ArtworkPickerUiState(
    val title: String,
    val columns: Int,
    /** A tile's width / height. */
    val aspectRatio: Double,
    val contain: Boolean,
    val loading: Boolean = true,
    val tiles: List<ArtworkTileUi> = emptyList(),
    /** Applying: a spinner shows, tiles and actions are disabled, Back waits. */
    val applying: Boolean = false,
    val emptyText: String = T.metadataEdit.noArtworkAvailable,
    val fromUrlLabel: String = T.metadataEdit.fromUrl,
    val uploadLabel: String = T.metadataEdit.uploadFile,
    val cancelLabel: String = T.common.cancel,
    val imageUrlHint: String = T.metadataEdit.enterImageUrl,
)

/** A candidate; [label] is its spoken name ("Artwork option 2, selected"). */
data class ArtworkTileUi(val imageUrl: String?, val selected: Boolean, val label: String)
