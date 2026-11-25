package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.seerr.SeerrCatalogPerson
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.detail.InfoRowUi
import com.edde746.plezy.presentation.detail.PagedGridUi
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.presentation.detail.personFacts
import com.edde746.plezy.presentation.explore.toCatalogCard
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * A person's Seerr page ([Route.SeerrPerson]): who they are, as the library's person page shows it, and their titles as
 * catalog cards.
 *
 * @param department what they are known for, as Seerr gives it (`Acting`).
 * @param facts born (with their age), died, birthplace.
 * @param titleCount "N titles" once their titles are in.
 * @param load [SectionLoad.LOADING] while the page loads, [SectionLoad.ERROR] with [error] when it failed
 *   ([SeerrPersonStore.retry]), else whether they have titles.
 * @param titles their titles as catalog stand-ins ([CatalogItem.toMediaItem]): each once, newest first, undated last.
 * @param settled the first load has ended, loaded or failed: the page shows, its spinner alone before.
 */
data class SeerrPersonUiState(
    val name: String,
    val image: Artwork?,
    val department: String?,
    val facts: List<InfoRowUi>,
    val biography: String?,
    val titleCount: String?,
    val load: SectionLoad,
    val error: String?,
    val titles: List<MediaItem>,
    val settled: Boolean,
) {
    /** The titles as the grid of Explore's catalog cards ([toCatalogCard]), each poster the variant nearest [posterPx] wide. */
    fun grid(posterPx: Int): PagedGridUi {
        val now = Clock.System.now()
        val cards = titles.mapNotNull { it.toCatalogCard(now, posterPx, 0) }
        return PagedGridUi(load, error, cards, cards.size)
    }
}

/**
 * Loads a person's Seerr page ([fetchPerson]: their details and titles at once) and keeps it; until it is in, the name
 * and photo of the cast entry it was opened from show. A card opens the title's catalog detail ([routeFor]). Call
 * everything on the main thread; [release] ends it.
 */
class SeerrPersonStore(
    private val route: Route.SeerrPerson,
    private val fetchPerson: suspend (personId: Int) -> SeerrCatalogPerson,
    private val today: () -> CalendarDate,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var person: SeerrCatalogPerson? = null
    private var titles: List<CatalogItem> = emptyList()
    private var items: List<MediaItem> = emptyList()
    private var load = SectionLoad.LOADING
    private var error: String? = null
    private var settled = false
    private var job: Job? = null
    private val mutableState = MutableStateFlow(state())

    val state: StateFlow<SeerrPersonUiState> = mutableState.asStateFlow()

    init {
        fetch()
    }

    /** Loads the page again after it failed. */
    fun retry() {
        if (load == SectionLoad.ERROR) fetch()
    }

    /** The catalog detail of the title whose card is [cardId]. */
    fun routeFor(cardId: String): Route? {
        val index = items.indexOfFirst { it.id == cardId }
        return if (index < 0) null else Route.CatalogDetail(titles[index])
    }

    fun release() {
        scope.cancel()
    }

    private fun fetch() {
        if (job?.isActive == true) return
        load = SectionLoad.LOADING
        error = null
        publish()
        job = scope.launch {
            try {
                val loaded = fetchPerson(route.personId)
                person = loaded
                titles = loaded.titles.distinctBy { it.identityKey }.sortedByDescending { it.releaseDate }
                items = titles.map { it.toMediaItem() }
                load = if (titles.isEmpty()) SectionLoad.EMPTY else SectionLoad.CONTENT
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Seerr person ${route.personId} failed to load" }
                load = SectionLoad.ERROR
                error = T.errors.unableToLoad(isolate(route.name))
            }
            settled = true
            publish()
        }
    }

    private fun publish() {
        mutableState.value = state()
    }

    private fun state(): SeerrPersonUiState {
        val person = person
        return SeerrPersonUiState(
            name = person?.name ?: route.name,
            image = Artwork.fixed(person?.imageUrl ?: route.imageUrl),
            department = person?.department,
            facts = person?.let { personFacts(it.details, today()) }.orEmpty(),
            biography = person?.details?.biography,
            titleCount = if (load == SectionLoad.CONTENT || load == SectionLoad.EMPTY) T.discover.titleCount(titles.size) else null,
            load = load,
            error = error,
            titles = items,
            settled = settled,
        )
    }

    private companion object {
        const val TAG = "SeerrPerson"
    }
}
