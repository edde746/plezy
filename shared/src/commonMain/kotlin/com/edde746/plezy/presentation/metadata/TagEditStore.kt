package com.edde746.plezy.presentation.metadata

import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
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
 * A tag list's editor (the editor's tag fields, Quick Tag): the [tags] so far, typed ones added, rows removed, and up to
 * [MAX_SUGGESTIONS] suggestion chips not yet applied that contain what is typed. [suggestions] load meanwhile; a
 * failure leaves the dialog without chips.
 */
class TagEditStore(title: String, initialTags: List<String>, suggestions: suspend () -> List<String>, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()
    private var all: List<String> = emptyList()
    private val mutableState = MutableStateFlow(TagEditUiState(title = title, tags = initialTags.toList()))

    val state: StateFlow<TagEditUiState> = mutableState.asStateFlow()

    val tags: List<String> get() = mutableState.value.tags

    init {
        scope.launch {
            all = try {
                suggestions()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Tag suggestions unavailable" }
                emptyList()
            }
            render()
        }
    }

    /** What is typed now: the chips filter by it. */
    fun setQuery(query: String) {
        mutableState.update { it.copy(query = query) }
        render()
    }

    /**
     * Adds [text] (what is typed, by default), trimmed; empty text, or a tag already there in any case, is ignored.
     * True when it was added: the field clears.
     */
    fun add(text: String = mutableState.value.query): Boolean {
        val tag = text.trim()
        val current = mutableState.value.tags
        if (tag.isEmpty() || current.any { it.equals(tag, ignoreCase = true) }) return false
        mutableState.update { it.copy(tags = current + tag, query = "") }
        render()
        return true
    }

    fun remove(index: Int) {
        val current = mutableState.value.tags
        if (index !in current.indices) return
        mutableState.update { it.copy(tags = current.filterIndexed { i, _ -> i != index }) }
        render()
    }

    fun close() = scope.cancel()

    private fun render() = mutableState.update { it.copy(suggestions = visibleSuggestions(all, it.tags, it.query)) }

    companion object {
        const val MAX_SUGGESTIONS = 12
        private const val TAG = "TagEdit"

        /** [suggestions] not yet in [tags] (any case) that contain [query] (any case), the first [MAX_SUGGESTIONS]. */
        fun visibleSuggestions(suggestions: List<String>, tags: List<String>, query: String): List<String> {
            val applied = tags.mapTo(HashSet()) { it.lowercase() }
            val q = query.trim().lowercase()
            return suggestions.filter { it.lowercase() !in applied && (q.isEmpty() || it.lowercase().contains(q)) }.take(MAX_SUGGESTIONS)
        }
    }
}

data class TagEditUiState(
    val title: String,
    val tags: List<String>,
    /** The chips: applied tags and ones not matching [query] left out. */
    val suggestions: List<String> = emptyList(),
    val query: String = "",
    val addTagLabel: String = T.metadataEdit.addTag,
    val cancelLabel: String = T.common.cancel,
    val saveLabel: String = T.common.save,
)
