package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.test.hasText
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.music.MusicPlayback
import com.edde746.plezy.music.MusicState
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.catalog.CatalogDetailUiState
import com.edde746.plezy.presentation.catalog.CatalogLibrarySection
import com.edde746.plezy.presentation.catalog.CatalogRequestAction
import com.edde746.plezy.presentation.catalog.CatalogWatchlistAction
import com.edde746.plezy.presentation.detail.CollectionStore
import com.edde746.plezy.presentation.detail.OfflineCollectionSource
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.DownloadMenuEntry
import com.edde746.plezy.presentation.music.MusicDownloads
import com.edde746.plezy.presentation.music.MusicScreens
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.playlists.PlaylistDetailStore
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.catalog.CatalogDetailContent
import com.edde746.plezy.ui.catalog.CatalogDetailIntents
import com.edde746.plezy.ui.detail.CollectionPage
import com.edde746.plezy.ui.detail.DetailContent
import com.edde746.plezy.ui.detail.DetailFixture
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.home.ViewAllSort
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.music.AlbumScreen
import com.edde746.plezy.ui.music.ArtistScreen
import com.edde746.plezy.ui.music.MusicPlaylistScreen
import com.edde746.plezy.ui.playlists.PlaylistPage
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import java.lang.reflect.Proxy
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertTrue
import kotlin.time.Duration

/**
 * Every page header's action row (a primary pill and round icon buttons) measured from its buttons' bounds, on a phone
 * and on TV, at the default text size and at twice it: every button is the row's height and on its vertical centre,
 * the round ones stay round, the row is the platform's control height at the default size and grows with large text.
 */
@OptIn(ExperimentalTestApi::class)
class ActionRowTest {
    @Test
    fun `a movies detail row keeps one height`() = assertRow("movie detail", PHONE_AND_TV, DETAIL, DETAIL_PILLS, label = null) { tv ->
        DetailPage(remember { DetailFixture.movie(tv) })
    }

    @Test
    fun `a shows detail row keeps one height`() = assertRow("show detail", PHONE_AND_TV, DETAIL, DETAIL_PILLS, upOnTv = 2, label = null) { tv ->
        DetailPage(remember { DetailFixture.show(tv) })
    }

    @Test
    fun `a collections row keeps one height`() = assertRow("collection", PHONE_AND_TV, COLLECTION, setOf("collection.play"), upOnTv = 1) {
        CollectionPage(remember { collection(offline = false) }, onBack = {}, onOpen = {}, onMenu = {})
    }

    @Test
    fun `a downloaded collections row keeps one height`() =
        assertRow("downloaded collection", PHONE_AND_TV, COLLECTION, setOf("collection.watched"), upOnTv = 1, label = T.mediaMenu.markAsWatched) {
            CollectionPage(remember { collection(offline = true) }, onBack = {}, onOpen = {}, onMenu = {})
        }

    @Test
    fun `an albums row keeps one height`() = assertRow("album", PHONE_AND_TV, MUSIC + listOf("music.album.download", "music.album.more"), setOf("music.play")) { tv ->
        val store = remember { musicScreens(tv).album(Route.MusicAlbum(SERVER, ALBUM)) }
        AlbumScreen(store, remember { DetailFixture.movie(tv).menu }, onBack = {})
    }

    @Test
    fun `an artists row keeps one height`() = assertRow("artist", PHONE_AND_TV, MUSIC, setOf("music.play")) { tv ->
        val store = remember { musicScreens(tv).artist(Route.MusicArtist(SERVER, ARTIST)) }
        ArtistScreen(store, remember { DetailFixture.movie(tv).menu }, onBack = {})
    }

    @Test
    fun `a music playlists row keeps one height`() =
        assertRow("music playlist", PHONE_AND_TV, MUSIC + listOf("music.playlist.${DownloadMenuEntry.DOWNLOAD_PLAYLIST.id}", "music.playlist.edit", "music.playlist.delete"), setOf("music.play")) { tv ->
            val store = remember { musicScreens(tv).playlist(Route.MusicPlaylist(SERVER, PLAYLIST)) { _, _ -> } }
            MusicPlaylistScreen(store, remember { DetailFixture.movie(tv).menu }, onBack = {})
        }

    @Test
    fun `a playlists row keeps one height`() = assertRow("playlist", PHONE_AND_TV, PLAYLIST_ROW, setOf("playlist.play")) {
        PlaylistPage(remember { playlist() }, onBack = {})
    }

    @Test
    fun `a catalog titles row keeps one height`() = assertRow("catalog title", PHONE_AND_TV, CATALOG, setOf("catalogDetail.watchlist", "catalogDetail.request"), label = T.seerr.request) {
        CatalogDetailContent(remember { catalogState() }, remember { catalogIntents() })
    }

    /**
     * A View all's sort chip and Libraries' sort chip are one control in two headers: on a phone, the desktop and TV
     * both are the header chips' height, as Libraries' round header actions are, and share their centre.
     */
    @Test
    fun `a View alls sort chip is the header chips height`() {
        val findings = mutableListOf<String>()
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.DESKTOP, FormFactor.TV)) {
            var chipHeight = 0f
            val row = measure(formFactor, 1f, HEADER_CHIPS, up = 0, label = null) {
                chipHeight = LocalPlezyDimens.current.chipHeight.value
                Row(verticalAlignment = Alignment.CenterVertically) {
                    ViewAllSort(emptyList(), MediaSort("titleSort", "Title"), descending = false, onPick = {}, probe = "hubDetail.sort")
                    // Libraries' sort chip as its header draws it, and its round header action.
                    PlezyChip("Title", selected = false, onClick = {}, dropdown = true, leadingIcon = PlezyIcons.ArrowUpward, modifier = Modifier.layoutProbe("libraries.chip.sort"))
                    HeaderAction(PlezyIcons.Shuffle, T.libraries.shuffleLibrary, {}, "libraries.shuffle")
                }
            }
            val problems = problems(row.buttons, pills = setOf("hubDetail.sort", "libraries.chip.sort"), height = chipHeight)
            if (problems.isNotEmpty()) {
                findings += "${formFactor.name.lowercase()}: ${problems.joinToString("; ")} [${row.buttons.joinToString { "${it.name} h=${it.height.fmt()} cy=${it.centre.fmt()}" }}]"
            }
        }
        assertTrue(findings.isEmpty(), findings.joinToString("\n"))
    }

    /**
     * Opens [screen] ([content], given whether it is on TV) on each of [formFactors] at each text size and checks the
     * row of the buttons named [buttons] (those it shows); [pills] are its pills, the rest round. [upOnTv]: the presses
     * of Up that bring a TV screen's row into view from where its focus starts. Every finding of every run fails the
     * test together, with each button's measured height and centre.
     */
    private fun assertRow(
        screen: String,
        formFactors: List<FormFactor>,
        buttons: List<String>,
        pills: Set<String>,
        upOnTv: Int = 0,
        label: String? = T.common.play,
        content: @Composable (tv: Boolean) -> Unit,
    ) {
        val findings = mutableListOf<String>()
        for (formFactor in formFactors) {
            val up = if (formFactor == FormFactor.TV) upOnTv else 0
            val rows = TEXT_SCALES.associateWith { scale -> measure(formFactor, scale, buttons, up, label) { content(formFactor == FormFactor.TV) } }
            for ((scale, row) in rows) {
                val at = "$screen on ${formFactor.name.lowercase()} at text x$scale"
                val measured = row.buttons.joinToString { "${it.name} h=${it.height.fmt()} cy=${it.centre.fmt()}" }
                val problems = problems(row.buttons, pills, if (scale == 1f) controlHeight(formFactor) else null) +
                    listOfNotNull("its label \"$label\" is cut or missing".takeIf { label != null && !row.labelWhole })
                if (problems.isNotEmpty()) findings += "$at: ${problems.joinToString("; ")} [$measured]"
            }
            val small = rows.getValue(1f).buttons.maxOfOrNull { it.height } ?: 0f
            val large = rows.getValue(2f).buttons.minOfOrNull { it.height } ?: 0f
            if (large <= small + TOLERANCE) {
                findings += "$screen on ${formFactor.name.lowercase()}: the row doesn't grow with large text (${small.fmt()} at x1, ${large.fmt()} at x2)"
            }
        }
        assertTrue(findings.isEmpty(), findings.joinToString("\n"))
    }

    /** What is wrong with [row]: its buttons' heights, centres and shapes, and at the default size its [height]. */
    private fun problems(row: List<Measured>, pills: Set<String>, height: Float?): List<String> {
        if (row.size < 2) return listOf("the row shows ${row.size} of its buttons")
        val problems = mutableListOf<String>()
        val offScreen = row.filter { !it.whole }
        if (offScreen.isNotEmpty()) problems += "off screen: ${offScreen.joinToString { it.name }}"
        if (row.maxOf { it.height } - row.minOf { it.height } > TOLERANCE) problems += "heights differ"
        for (line in lines(row)) {
            if (line.maxOf { it.centre } - line.minOf { it.centre } > TOLERANCE) problems += "centres differ along ${line.joinToString { it.name }}"
        }
        row.filter { it.name in pills && it.name != "detail.versions" && it.width < it.height * 1.5f }.forEach { problems += "${it.name} lost its label (${it.width.fmt()} × ${it.height.fmt()})" }
        row.filter { it.name !in pills && abs(it.width - it.height) > TOLERANCE }.forEach { problems += "${it.name} isn't round (${it.width.fmt()} × ${it.height.fmt()})" }
        if (height != null) row.filter { abs(it.height - height) > TOLERANCE }.forEach { problems += "${it.name} isn't the control height ${height.fmt()}" }
        return problems
    }

    /** [row]'s lines where it wraps: buttons whose spans overlap one another's, top to bottom. */
    private fun lines(row: List<Measured>): List<List<Measured>> {
        val lines = mutableListOf<MutableList<Measured>>()
        var bottom = Float.NEGATIVE_INFINITY
        for (button in row.sortedBy { it.top }) {
            if (button.top >= bottom - TOLERANCE) lines += mutableListOf<Measured>().also { bottom = Float.NEGATIVE_INFINITY }
            lines.last() += button
            bottom = maxOf(bottom, button.top + button.height)
        }
        return lines
    }

    /**
     * The bounds, in dp, of each of [buttons] the screen shows, in a window of [formFactor] at text scale [scale]; after
     * [up] presses of Up (a screen whose focus starts below its row, which then scrolls into view).
     */
    private fun measure(formFactor: FormFactor, scale: Float, buttons: List<String>, up: Int, label: String?, content: @Composable () -> Unit): MeasuredRow {
        val probe = Placements()
        var density = 1f
        // Leaving the composition takes every element away: what was placed is read before that.
        var placed = emptyMap<String, Rect>()
        var labelWhole = true
        val window = if (formFactor == FormFactor.TV) DpSize(960.dp, 540.dp) else DpSize(411.dp, 1600.dp)
        runComposeUiTest {
            setContent {
                density = LocalDensity.current.density
                val owner = remember {
                    object : NavigationEventDispatcherOwner {
                        override val navigationEventDispatcher = NavigationEventDispatcher()
                    }
                }
                CompositionLocalProvider(
                    LocalDensity provides Density(LocalDensity.current.density, scale),
                    LocalNavigationEventDispatcherOwner provides owner,
                    LocalAppearance provides Appearance.of(AppearanceSettings(), formFactor, supporterUnlocked = false),
                    LocalLayoutProbe provides probe,
                ) {
                    PlezyTheme {
                        Box(Modifier.size(window)) {
                            AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) { OverlayHostBox { content() } }
                        }
                    }
                }
            }
            waitForIdle()
            repeat(up) {
                onRoot().performKeyInput { pressKey(Key.DirectionUp) }
                waitForIdle()
            }
            placed = runOnIdle { probe.placed.toMap() }
            if (label != null) {
                // The label's text, laid out whole on its one line: not cut short, not shrunk away.
                val texts = onAllNodes(hasText(label), useUnmergedTree = true).fetchSemanticsNodes().mapNotNull { node ->
                    node.config.getOrNull(SemanticsActions.GetTextLayoutResult)?.action?.let { get -> mutableListOf<TextLayoutResult>().also { get(it) } }
                }.flatten()
                labelWhole = texts.isNotEmpty() && texts.none { it.hasVisualOverflow }
            }
        }
        return MeasuredRow(labelWhole, buttons.mapNotNull { name ->
            placed[name]?.let { px ->
                val rect = Rect(px.left / density, px.top / density, px.right / density, px.bottom / density)
                Measured(name, rect.top, rect.width, rect.height, whole = rect.top >= 0f && rect.bottom <= window.height.value && rect.left >= 0f && rect.right <= window.width.value)
            }
        })
    }

    /** The platform's control height: a phone's and a desktop's, or a TV's. */
    private fun controlHeight(formFactor: FormFactor): Float = if (formFactor == FormFactor.TV) 48f else 40f

    @Composable
    private fun DetailPage(fixture: DetailFixture) {
        val state by fixture.store.state.collectAsState()
        DetailContent(state, fixture.intents)
    }

    /** The row's buttons, and whether its pill's label showed whole. */
    private class MeasuredRow(val labelWhole: Boolean, val buttons: List<Measured>)

    /** A button's place in dp: its top, width and height, and whether it is whole on screen. */
    private class Measured(val name: String, val top: Float, val width: Float, val height: Float, val whole: Boolean) {
        val centre: Float get() = top + height / 2
    }

    /** Where each named element was last placed, in window pixels. */
    private class Placements : LayoutProbe {
        val placed = mutableMapOf<String, Rect>()

        override fun place(name: String, bounds: Rect?) {
            if (bounds == null) placed.remove(name) else placed[name] = bounds
        }
    }

    private fun Float.fmt(): String = "%.1f".format(this)

    private companion object {
        const val SERVER = "jf"
        const val ALBUM = "album"
        const val ARTIST = "artist"
        const val PLAYLIST = "playlist"
        const val COLLECTION_ID = "collection"

        /** A spread up to this many dp is the rounding of the layout. */
        const val TOLERANCE = 1f

        val TEXT_SCALES = listOf(1f, 2f)
        val PHONE_AND_TV = listOf(FormFactor.HANDHELD, FormFactor.TV)

        val DETAIL = listOf(
            "detail.play", "detail.versions", "cast.button", "detail.trailer", "detail.shuffle", "detail.download",
            "detail.watched", "detail.watchlist", "detail.more",
        )

        /** Play and its chevron: the two segments of Play's split capsule, not circles. */
        val DETAIL_PILLS = setOf("detail.play", "detail.versions")
        val COLLECTION = listOf("collection.play", "collection.shuffle", "collection.watched", "collection.deleteDownloads", "collection.more")
        val MUSIC = listOf("music.play", "cast.button", "music.shuffle", "music.instantMix", "music.more")
        val PLAYLIST_ROW = listOf("playlist.play", "cast.button", "playlist.shuffle", "playlist.edit", "playlist.delete", "playlist.more")
        val CATALOG = listOf("catalogDetail.watchlist", "catalogDetail.request", "catalogDetail.trailer", "catalogDetail.more")

        /** A View all's sort chip, Libraries' sort chip and a round header action of Libraries'. */
        val HEADER_CHIPS = listOf("hubDetail.sort", "libraries.chip.sort", "libraries.shuffle")

        fun item(id: String, kind: MediaKind, title: String, block: MediaItem.() -> MediaItem = { this }) =
            MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = title, serverId = SERVER).block()

        val TRACKS = (1..3).map { item("t$it", MediaKind.TRACK, "Track $it") { copy(index = it, parentId = ALBUM) } }
        val MOVIES = (1..6).map { item("m$it", MediaKind.MOVIE, "Movie $it") }

        /** A collection of six movies, from the server or ([offline]) the downloads. */
        fun collection(offline: Boolean): CollectionStore {
            val folder = item(COLLECTION_ID, MediaKind.COLLECTION, "Saga") { copy(childCount = MOVIES.size) }
            val server = proxy<MediaBackend>("CollectionServer") { name, _ ->
                when (name) {
                    "fetchItem" -> folder
                    "fetchCollectionPage" -> LibraryPage(MOVIES, totalCount = MOVIES.size)
                    "getServerId" -> SERVER
                    else -> null
                }
            }
            val downloads = proxy<OfflineCollectionSource>("Downloads") { name, _ ->
                when (name) {
                    "getChanges" -> emptyFlow<Any?>()
                    "items" -> MOVIES
                    // Named with a suffix: it takes a ServerId.
                    else -> if (name.startsWith("metadata")) folder else null
                }
            }
            return CollectionStore(
                Route.CollectionDetail(ServerId(SERVER), COLLECTION_ID, offline = offline),
                server,
                { CardOptions() },
                launchQueue = { _, _ -> error("not played") },
                collectionsChanged = emptyFlow(),
                parentScope = CoroutineScope(Dispatchers.Unconfined),
                offline = downloads,
            )
        }

        /** An editable video playlist of six movies. */
        fun playlist() = PlaylistDetailStore(
            client = proxy<MediaBackend>("PlaylistServer") { name, _ ->
                when (name) {
                    "fetchPlaylistMetadata" -> MediaPlaylist(id = PLAYLIST, backend = BackendKind.JELLYFIN, title = "Binge", playlistType = "video")
                    "fetchPlaylistPage" -> LibraryPage(MOVIES, totalCount = MOVIES.size)
                    "getServerId" -> SERVER
                    else -> null
                }
            },
            playlistId = PLAYLIST,
            cardOptions = { CardOptions() },
            play = { _, _, _ -> },
            delete = { _, _ -> },
            openMenu = {},
            back = {},
            message = { _, _ -> },
            parentScope = CoroutineScope(Dispatchers.Unconfined),
        )

        /** The music screens over a server with an album, its artist and an audio playlist, which offers Instant Mix. */
        fun musicScreens(tv: Boolean): MusicScreens {
            val album = item(ALBUM, MediaKind.ALBUM, "Sine Album") { copy(parentId = ARTIST, parentTitle = "Plezy Test Artist") }
            val artist = item(ARTIST, MediaKind.ARTIST, "Plezy Test Artist")
            val server = proxy<MediaBackend>("MusicServer") { name, args ->
                when (name) {
                    "fetchItem" -> if (args?.firstOrNull() == ARTIST) artist else album
                    "fetchAlbumTracks" -> TRACKS
                    "fetchArtistDiscography" -> listOf(ArtistDiscographyGroup(DiscographyGroupKind.ALBUMS, listOf(album)))
                    "fetchPlaylistMetadata" -> MediaPlaylist(id = PLAYLIST, backend = BackendKind.JELLYFIN, title = "Plezy Mix", playlistType = "audio")
                    "fetchPlaylistPage" -> LibraryPage(TRACKS, totalCount = TRACKS.size)
                    "getCapabilities" -> ServerCapabilities(instantMix = true)
                    "getServerId" -> SERVER
                    "getBackend" -> BackendKind.JELLYFIN
                    else -> null
                }
            }
            val playback = proxy<MusicPlayback>("Playback") { name, _ ->
                when (name) {
                    "getState" -> MutableStateFlow(MusicState())
                    "getPosition" -> MutableStateFlow(Duration.ZERO)
                    else -> null
                }
            }
            val downloads = proxy<MusicDownloads>("MusicDownloads") { name, _ ->
                when (name) {
                    "getChanges" -> MutableStateFlow(0L)
                    "buttonSpec" -> DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, tooltip = null)
                    "playlistActions" -> listOf(DownloadMenuEntry.DOWNLOAD_PLAYLIST)
                    "albumTracks", "artistTracks" -> emptyList<MediaItem>()
                    else -> null
                }
            }
            return MusicScreens(
                playback,
                PlezyNavigator(Route.Home),
                clients = { if (it.value == SERVER) server else null },
                serverOnline = { true },
                tv = tv,
                offline = MutableStateFlow(false),
                sleepTimerMinutes = MutableStateFlow(30),
                parentScope = CoroutineScope(Dispatchers.Unconfined),
                downloads = downloads,
            )
        }

        fun catalogState() = CatalogDetailUiState(
            item = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Arrival", CatalogItemIds(tmdb = 329865)),
            tagline = null,
            title = "Arrival",
            metaLine = "2016 • 1h 56m",
            genres = "Drama • Science Fiction",
            watchlist = CatalogWatchlistAction(onWatchlist = false, label = T.explore.addToWatchlist),
            request = CatalogRequestAction(329865, "Arrival"),
            hasTrailer = true,
            settled = true,
            stats = emptyList(),
            overview = "Linguist Louise Banks leads an elite team.",
            background = null,
            facts = emptyList(),
            recommenders = emptyList(),
            ratings = emptyList(),
            communityRatings = emptyList(),
            schedule = emptyList(),
            crew = emptyList(),
            tags = null,
            watchOnLinks = emptyList(),
            links = emptyList(),
            library = CatalogLibrarySection.NotInLibrary,
            castTitle = T.explore.cast,
            cast = emptyList(),
            relations = emptyList(),
            related = emptyList(),
            message = null,
        )

        fun catalogIntents() = CatalogDetailIntents(
            toggleWatchlist = {},
            request = {},
            playTrailer = {},
            openLink = {},
            revealSpoilerTags = {},
            messageShown = {},
            openItem = {},
            openCopy = {},
            openPerson = {},
            back = null,
        )

        /** An [I] answering through [answer] (a method's name and arguments), with an identity of its own. */
        inline fun <reified I : Any> proxy(label: String, crossinline answer: (String, Array<out Any?>?) -> Any?): I =
            Proxy.newProxyInstance(I::class.java.classLoader, arrayOf(I::class.java)) { proxy, method, args ->
                when (method.name) {
                    "toString" -> label
                    "hashCode" -> 0
                    "equals" -> proxy === args?.get(0)
                    else -> answer(method.name, args)
                }
            } as I
    }
}
