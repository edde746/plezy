package com.edde746.plezy.presentation.metadata

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.PlexMatchResult
import com.edde746.plezy.plex.applyMatch
import com.edde746.plezy.plex.findMatches
import com.edde746.plezy.presentation.navigation.Route
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
 * Plex's match search for [route]'s movie or show, on the item's own server: the name and year (prefilled with the
 * item's) search the agents' candidates, once at the start, then on Search. A failed search says so and keeps the
 * results shown. Picking a candidate applies it; while it applies, the others wait. Success says so and leaves.
 */
class PlexMatchStore(
    private val route: Route.PlexMatch,
    private val deps: MetadataEditDeps,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val client get() = deps.client(route.serverId) as? PlexClient
    private var results: List<PlexMatchResult>? = null
    private val mutableState = MutableStateFlow(
        PlexMatchUiState(
            title = if (route.matched) T.matchScreen.fixMatch else T.matchScreen.match,
            name = route.title,
            year = route.year?.toString().orEmpty(),
        ),
    )

    val state: StateFlow<PlexMatchUiState> = mutableState.asStateFlow()

    init {
        search()
    }

    fun setName(name: String) = mutableState.update { it.copy(name = name) }

    /** Digits only, at most four. */
    fun setYear(year: String) = mutableState.update { it.copy(year = year.filter(Char::isDigit).take(4)) }

    /** Searches with the trimmed name and year, empty ones left out; ignored while a search runs. */
    fun search() {
        val shown = mutableState.value
        if (shown.searching) return
        mutableState.update { it.copy(searching = true) }
        scope.launch {
            val found = try {
                val client = client ?: throw IllegalStateException("No Plex server ${route.serverId}")
                client.findMatches(route.itemId, title = shown.name.trim(), year = shown.year.trim())
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to search for matches" }
                deps.notify(T.errors.searchFailed(localizedErrorReason(e)))
                null
            }
            results = found ?: results ?: emptyList()
            render(searching = false)
        }
    }

    /** Applies the candidate at [index]; ignored while one applies. */
    fun apply(index: Int) {
        val result = results?.getOrNull(index) ?: return
        if (mutableState.value.applyingGuid != null) return
        mutableState.update { it.copy(applyingGuid = result.guid) }
        render()
        scope.launch {
            val success = try {
                client?.applyMatch(route.itemId, result.guid, name = result.name, year = result.year?.toString()) == true
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to apply match" }
                false
            }
            mutableState.update { it.copy(applyingGuid = null) }
            render()
            if (success) {
                deps.notify(T.matchScreen.matchApplied)
                deps.close(route)
            } else {
                deps.notify(T.matchScreen.matchFailed)
            }
        }
    }

    /** The route left: whoever showed the item refreshes it. */
    fun close() {
        scope.cancel()
        deps.edited(route.serverId, route.itemId)
    }

    private fun render(searching: Boolean = mutableState.value.searching) {
        val client = client
        val applying = mutableState.value.applyingGuid
        mutableState.update { state ->
            state.copy(
                searching = searching,
                results = results?.map { result ->
                    MatchResultUi(
                        title = result.year?.let { "${result.name} ($it)" } ?: result.name,
                        summary = result.summary?.ifEmpty { null },
                        score = result.score?.toString(),
                        thumbUrl = client?.let { imageUrl(it, result.thumb, 96, 144) },
                        applying = applying == result.guid,
                    )
                },
            )
        }
    }

    private companion object {
        const val TAG = "PlexMatch"
    }
}

data class PlexMatchUiState(
    /** "Match…" for an unmatched item, else "Fix Match…". */
    val title: String,
    val name: String,
    val year: String,
    val searching: Boolean = false,
    /** Null before the first search ends: a spinner shows, as while [searching]. */
    val results: List<MatchResultUi>? = null,
    /** The candidate applying now; every candidate waits meanwhile. */
    val applyingGuid: String? = null,
    val titleHint: String = T.matchScreen.titleHint,
    val yearHint: String = T.matchScreen.yearHint,
    val searchLabel: String = T.matchScreen.search,
    val noMatchesText: String = T.matchScreen.noMatchesFound,
)

/** A candidate: "Name (Year)", its summary, its score chip, its 48×72 thumbnail. */
data class MatchResultUi(val title: String, val summary: String?, val score: String?, val thumbUrl: String?, val applying: Boolean)
