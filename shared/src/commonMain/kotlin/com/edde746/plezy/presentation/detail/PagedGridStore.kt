package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.format.DateLength
import com.edde746.plezy.format.formatDate
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.formatContentRating
import com.edde746.plezy.playback.queue.PlayQueueLaunch
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.search.itemRoute
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** A grid of a server's items loaded in pages: a person's titles, a collection's items. */
data class PagedGridUi(
    val load: SectionLoad,
    /** The first page's error, with Retry. */
    val error: String?,
    /** Loaded cards; the grid draws [total] − size skeletons after them, and reaching one loads the next page. */
    val items: List<MediaCardUi>,
    val total: Int,
    /** A later page failed: the loaded cards stay, and the grid's end shows this with Retry instead of skeletons. */
    val moreError: String? = null,
)

/** An actor's screen ([Route.Person]): who they are and their titles on that server. */
data class PersonUiState(
    val name: String,
    val image: Artwork?,
    val characterName: String?,
    /** "Born March 4, 1970 (age 55)", "Died …", "Birthplace …": label and value. */
    val facts: List<InfoRowUi>,
    val biography: String?,
    /** "N titles" once the count is known. */
    val titleCount: String?,
    val grid: PagedGridUi,
    /** The details and the first page of titles are in, or failed: the page shows, its spinner alone before. */
    val settled: Boolean,
)

class PersonStore(
    private val route: Route.Person,
    private val client: MediaBackend?,
    private val cardOptions: () -> CardOptions,
    private val today: () -> CalendarDate,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var details = MediaPersonDetails.EMPTY
    private var detailsSettled = client == null
    private val pages = AppendPager({ start ->
        val c = client ?: throw PlaybackException(T.messages.playbackServerUnavailable, PlaybackFailureReason.SERVER_UNAVAILABLE)
        val page = c.fetchPersonMediaPage(route.personId, start, AppendPager.PAGE_SIZE)
        LibraryPage(page.items.map { it.copy(serverId = it.serverId ?: route.serverId.value) }, page.totalCount, page.offset)
    }, ::render)
    private val mutableState = MutableStateFlow(state())
    val state: StateFlow<PersonUiState> = mutableState.asStateFlow()

    init {
        scope.launch { pages.loadFirst() }
        if (client != null) {
            scope.launch {
                details = try {
                    client.fetchPersonDetails(route.personId)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w("Person", e) { "details of ${route.personId} failed" }
                    MediaPersonDetails.EMPTY
                }
                detailsSettled = true
                render()
            }
        }
    }

    /** A skeleton at [index] shows: its page loads, unless the last one failed (Retry asks again). */
    fun ensureLoaded(index: Int) {
        if (index >= pages.items.size && pages.moreError == null) scope.launch { pages.loadMore() }
    }

    /** The grid's Retry: the failed page again. */
    fun retry() {
        scope.launch { pages.retry() }
    }

    /** Where the card [cardId] goes. */
    fun routeFor(cardId: String): Route? = pages.items.firstOrNull { it.globalKey == cardId }?.let { itemRoute(it, route.serverId) }

    /** The loaded item of card [cardId], for its menu. */
    fun item(cardId: String): MediaItem? = pages.items.firstOrNull { it.globalKey == cardId }

    fun close() = scope.cancel()

    private fun render() {
        mutableState.value = state()
    }

    private fun state(): PersonUiState {
        val options = cardOptions()
        return PersonUiState(
            name = route.name,
            image = Artwork.of(client, route.thumbPath, ImageKind.AVATAR),
            characterName = route.characterName?.takeIf { it.isNotBlank() },
            facts = personFacts(details, today()),
            biography = details.biography?.takeIf { it.isNotBlank() },
            titleCount = if (pages.load == SectionLoad.CONTENT || pages.load == SectionLoad.EMPTY) T.discover.titleCount(pages.total) else null,
            grid = PagedGridUi(pages.load, pages.error, pages.items.map { it.toCardUi(client, options) }, pages.total, pages.moreError),
            settled = detailsSettled && pages.settled,
        )
    }
}

/** A person's facts, label and value: born (with their age, while alive), died (with their age then), birthplace. */
internal fun personFacts(details: MediaPersonDetails, today: CalendarDate): List<InfoRowUi> {
    val age = details.ageOn(today)
    return listOfNotNull(
        details.birthDate?.let { birth ->
            val date = formatDate(birth.toString(), DateLength.LONG)
            InfoRowUi(T.discover.person.born, if (details.deathDate == null && age != null) T.discover.person.dateWithAge(date, age.toString()) else date)
        },
        details.deathDate?.let { death ->
            val date = formatDate(death.toString(), DateLength.LONG)
            InfoRowUi(T.discover.person.died, if (age != null) T.discover.person.dateWithAgeAtDeath(date, age.toString()) else date)
        },
        details.birthPlace?.takeIf { it.isNotBlank() }?.let { InfoRowUi(T.discover.person.birthplace, it) },
    )
}

/** A collection's screen ([Route.CollectionDetail]). */
data class CollectionUiState(
    val title: String,
    val poster: Artwork?,
    /**
     * The backgrounds the backdrop turns through ([com.edde746.plezy.presentation.browse.BackdropRotation]): the
     * collection's backdrops, else its art; offline only the stored ones. Empty: none to show.
     */
    val backdrops: List<Artwork>,
    /** All loaded items are music: square artwork. */
    val square: Boolean,
    /** "12 items  ·  1999–2021  ·  PG-13". */
    val metaLine: String?,
    val summary: String?,
    /** Play and Shuffle show. */
    val canPlay: Boolean,
    /** Play or Shuffle is loading its queue: the loading dialog's title, with Cancel ([CollectionStore.cancelLaunch]). */
    val launching: String? = null,
    val grid: PagedGridUi,
    /** The downloads folder's actions ([Route.CollectionDetail.offline]); null online. */
    val offline: OfflineCollectionUi? = null,
    /** The collection and the first page of its items are in, or failed: the page shows, its spinner alone before. */
    val settled: Boolean,
    /** A one-off message (a toast: a failed or empty play, a downloads folder's action) until shown ([CollectionStore.messageShown]). */
    val message: String? = null,
    /** A downloads folder's downloads were deleted: the screen leaves once it is the top screen, at once or when it shows again. */
    val gone: Boolean = false,
)

/**
 * A downloads folder's actions in place of Play and Shuffle: Mark as watched, or unwatched once every downloaded title
 * is watched ([allWatched]; shown while it has titles, [CollectionStore.toggleWatched]), and Delete collection
 * downloads ([CollectionStore.deleteDownloads], after [confirmingDelete]'s confirmation; the screen leaves once done).
 */
data class OfflineCollectionUi(val allWatched: Boolean, val confirmingDelete: Boolean = false)

/** What a downloads folder's screen reads from the downloads, nothing from the server. */
interface OfflineCollectionSource {
    /** Emits when the downloads change (a title deleted): the folder's titles are read again. */
    val changes: Flow<Any?>

    /** The folder's stored metadata. */
    suspend fun metadata(serverId: ServerId, collectionId: String): MediaItem?

    /** The folder's downloaded titles. */
    fun items(folder: MediaItem): List<MediaItem>

    /** The downloaded copy of [path]'s artwork, a local URL; null when there is none. */
    fun artwork(serverId: ServerId, path: String?): String?

    /** Marks every downloaded title watched or unwatched; the message to show. */
    suspend fun setWatched(folder: MediaItem, watched: Boolean): DownloadFeedback

    /** Deletes every downloaded title of the folder; the message to show. */
    suspend fun delete(folder: MediaItem): DownloadFeedback
}

class CollectionStore(
    private val route: Route.CollectionDetail,
    private val client: MediaBackend?,
    private val cardOptions: () -> CardOptions,
    /** Plays the collection, shuffled or in order, through the play-queue launcher. */
    private val launchQueue: (collection: MediaItem, shuffle: Boolean) -> PlayQueueLaunch,
    /** Emits when collections change (an item added or removed): the grid loads again. */
    private val collectionsChanged: Flow<Any?>,
    parentScope: CoroutineScope,
    /** The downloads, for [Route.CollectionDetail.offline]; null on a device without them. */
    private val offline: OfflineCollectionSource? = null,
) {
    private val offlineSource = offline?.takeIf { route.offline }
    private var confirmingDelete = false
    private var gone = false
    private var message: String? = null
    private val scope = parentScope.childScope()
    private var collection: MediaItem? = null
    private var launching: PlayQueueLaunch? = null

    private val pages = AppendPager({ start ->
        offlineSource?.let { source ->
            val all = collection?.let(source::items).orEmpty().map { it.copy(serverId = it.serverId ?: route.serverId.value) }
            return@AppendPager LibraryPage(all.drop(start).take(AppendPager.PAGE_SIZE), all.size, start)
        }
        val c = client ?: throw PlaybackException(T.messages.playbackServerUnavailable, PlaybackFailureReason.SERVER_UNAVAILABLE)
        val page = c.fetchCollectionPage(route.collectionId, start, AppendPager.PAGE_SIZE, collection?.libraryId, collection?.libraryTitle)
        LibraryPage(page.items.map { it.copy(serverId = it.serverId ?: route.serverId.value) }, page.totalCount, page.offset)
    }, ::render)
    private val mutableState = MutableStateFlow(state())
    val state: StateFlow<CollectionUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            collection = try {
                if (offlineSource != null) offlineSource.metadata(route.serverId, route.collectionId) else client?.fetchItem(route.collectionId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w("Collection", e) { "collection ${route.collectionId} failed" }
                null
            }
            render()
            reload()
            (offlineSource?.changes ?: collectionsChanged).collect { reload() }
        }
    }

    /** A skeleton at [index] shows: its page loads, unless the last one failed (Retry asks again). */
    fun ensureLoaded(index: Int) {
        if (index >= pages.items.size && pages.moreError == null) scope.launch { pages.loadMore() }
    }

    /** The grid's Retry: the failed page again. */
    fun retry() {
        scope.launch { pages.retry() }
    }

    /** The [CollectionUiState.message] has shown. */
    fun messageShown() {
        message = null
        render()
    }

    /** Loads the items from their first page (again: the list changed). */
    private fun reload() {
        scope.launch { pages.loadFirst() }
    }

    fun routeFor(cardId: String): Route? = pages.items.firstOrNull { it.globalKey == cardId }?.let { item ->
        if (offlineSource == null) return@let itemRoute(item, route.serverId)
        // A downloads folder's titles open their offline detail.
        Route.MediaDetail(ServerId.tryParse(item.serverId) ?: route.serverId, item.id, offline = true)
    }

    /** The loaded item of card [cardId], for its menu; none in a downloads folder. */
    fun item(cardId: String): MediaItem? = if (offlineSource != null) null else pages.items.firstOrNull { it.globalKey == cardId }

    /** A downloads folder's Mark as watched or unwatched: every downloaded title, unwatched once all are watched. */
    fun toggleWatched() {
        val source = offlineSource ?: return
        val folder = collection ?: return
        val watched = !allWatched()
        scope.launch {
            val feedback = source.setWatched(folder, watched)
            reload()
            show(feedback.message)
        }
    }

    /** A downloads folder's Delete collection downloads: asks first ([OfflineCollectionUi.confirmingDelete]). */
    fun deleteDownloads() {
        if (offlineSource == null || collection == null) return
        confirmingDelete = true
        render()
    }

    /** The deletion confirmed ([confirmed]) or not: deletes the folder's downloads and leaves once they are gone. */
    fun confirmDelete(confirmed: Boolean) {
        confirmingDelete = false
        render()
        if (!confirmed) return
        val source = offlineSource ?: return
        val folder = collection ?: return
        scope.launch {
            val feedback = source.delete(folder)
            message = feedback.message
            if (!feedback.isError) gone = true
            render()
        }
    }

    private fun allWatched(): Boolean = pages.items.isNotEmpty() && pages.items.all { it.isWatched }

    /** Plays the collection from its first item. */
    fun play() = launch(shuffle = false)

    /** Plays the collection shuffled. */
    fun shuffle() = launch(shuffle = true)

    /** Cancel on the loading dialog. */
    fun cancelLaunch() {
        launching?.cancel()
    }

    private fun launch(shuffle: Boolean) {
        val target = collection ?: return
        if (launching != null) return
        if (pages.load == SectionLoad.EMPTY) return show(T.messages.noItemsAvailable)
        val started = launchQueue(target, shuffle)
        launching = started
        render()
        scope.launch {
            val result = try {
                started.await()
            } finally {
                launching = null
                render()
            }
            result.message?.let(::show)
        }
    }

    fun close() = scope.cancel()

    private fun show(text: String) {
        message = text
        render()
    }

    private fun render() {
        mutableState.value = state()
    }

    private fun state(): CollectionUiState {
        val c = collection
        val options = cardOptions()
        val items = pages.items
        val count = if (pages.load == SectionLoad.LOADING) c?.childCount ?: c?.leafCount else pages.total
        val years = items.mapNotNull { it.year }
        val span = if (pages.complete && years.isNotEmpty()) {
            val lo = years.min()
            val hi = years.max()
            if (lo == hi) "$lo" else "$lo–$hi"
        } else {
            null
        }
        val meta = listOfNotNull(
            count?.let { if (it == 1) T.playlists.oneItem else T.playlists.itemCount(it.toString()) },
            span,
            c?.contentRating?.let(::formatContentRating)?.takeIf { it.isNotEmpty() },
        ).takeIf { it.isNotEmpty() }?.joinToString("  ·  ")
        val square = items.isNotEmpty() && items.all { it.kind.isMusic }
        return CollectionUiState(
            title = c?.title.orEmpty(),
            poster = offlineSource?.let { Artwork.fixed(it.artwork(route.serverId, c?.thumbPath)) }
                ?: Artwork.of(client, c?.thumbPath, if (square) ImageKind.SQUARE else ImageKind.POSTER),
            backdrops = offlineSource?.let { source ->
                (c?.heroBackdropPaths.orEmpty() + listOfNotNull(c?.artPath)).distinct().mapNotNull { Artwork.fixed(source.artwork(route.serverId, it)) }
            } ?: c?.heroBackdropPaths.orEmpty().ifEmpty { listOfNotNull(c?.artPath) }.mapNotNull { Artwork.of(client, it, ImageKind.ART) },
            square = square,
            metaLine = meta,
            summary = c?.summary?.takeIf { it.isNotBlank() },
            canPlay = offlineSource == null && items.isNotEmpty(),
            launching = launching?.title,
            grid = PagedGridUi(pages.load, pages.error, items.map { card(it, options) }, pages.total, pages.moreError),
            offline = offlineSource?.let { OfflineCollectionUi(allWatched(), confirmingDelete) },
            settled = pages.settled,
            message = message,
            gone = gone,
        )
    }

    /** [item]'s card; in a downloads folder with its downloaded artwork. */
    private fun card(item: MediaItem, options: CardOptions): MediaCardUi {
        val source = offlineSource ?: return item.toCardUi(client, options)
        val card = item.toCardUi(null, options)
        val server = ServerId.tryParse(item.serverId) ?: route.serverId
        return card.copy(artwork = Artwork.fixed(source.artwork(server, item.thumbPath)), backdrops = emptyList(), logo = null)
    }
}
