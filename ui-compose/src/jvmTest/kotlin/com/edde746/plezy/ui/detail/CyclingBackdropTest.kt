package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import coil3.SingletonImageLoader
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.BackdropRotation
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.detail.CollectionStore
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.BLUE_ART
import com.edde746.plezy.ui.BROKEN_ART
import com.edde746.plezy.ui.GREEN_ART
import com.edde746.plezy.ui.RED_ART
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.app.LaunchFocusTest.TestPlatform
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.colourAt
import com.edde746.plezy.ui.colourImages
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.emptyFlow
import java.lang.reflect.Proxy
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A detail's and a collection's backdrop turn through their backgrounds every 10 s, skip one that fails and show the
 * poster once every one has failed. Each background is one plain colour ([colourImages]).
 */
@OptIn(ExperimentalTestApi::class)
class CyclingBackdropTest {
    /** Each artwork path asked for, in order. */
    private val requested = CopyOnWriteArrayList<String>()

    @AfterTest
    fun resetImages() {
        SingletonImageLoader.reset()
    }

    @Test
    fun `the detail backdrop turns to its second backdrop after ten seconds`() = runComposeUiTest {
        detail(listOf(RED_ART, BLUE_ART))
        waitUntil { detailColour() == "red" }
        mainClock.advanceTimeBy(BackdropRotation.ROTATION_MILLIS / 2)
        assertEquals("red", detailColour(), "the backdrop turned before 10 s")
        mainClock.advanceTimeBy(BackdropRotation.ROTATION_MILLIS / 2)
        waitUntil { detailColour() == "blue" }
    }

    /** The turn after red lands on a backdrop that fails: blue comes in its place at once, not 10 s later. */
    @Test
    fun `a backdrop that fails is skipped at once`() = runComposeUiTest {
        detail(listOf(RED_ART, BROKEN_ART, BLUE_ART))
        waitUntil { detailColour() == "red" }
        mainClock.advanceTimeBy(BackdropRotation.ROTATION_MILLIS)
        waitUntil { detailColour() == "blue" }
        assertTrue(BROKEN_ART in requested, "the failing backdrop was never tried")
    }

    @Test
    fun `with every backdrop failed the detail shows its poster`() = runComposeUiTest {
        detail(listOf(BROKEN_ART), poster = GREEN_ART)
        waitUntil { detailColour() == "green" }
        assertTrue(BROKEN_ART in requested, "the backdrop was never tried")
    }

    @Test
    fun `the collection backdrop turns to its second backdrop after ten seconds`() = runComposeUiTest {
        colourImages(requested)
        val store = CollectionStore(
            Route.CollectionDetail(ServerId(SERVER), COLLECTION),
            collectionServer(listOf(RED_ART, BLUE_ART)),
            { CardOptions() },
            launchQueue = { _, _ -> error("not played") },
            collectionsChanged = emptyFlow(),
            parentScope = CoroutineScope(Dispatchers.Unconfined),
        )
        setContent {
            CompositionLocalProvider(LocalPlezyPlatform provides TestPlatform(FormFactor.TV)) {
                TvFrame { CollectionPage(store, onBack = {}, onOpen = {}, onMenu = {}) }
            }
        }
        waitUntil { colourAt(900, 40) == "red" }
        mainClock.advanceTimeBy(BackdropRotation.ROTATION_MILLIS)
        waitUntil { colourAt(900, 40) == "blue" }
    }

    /** A phone's movie detail with [backdrops] and [poster] on a platform without reduced motion. */
    private fun ComposeUiTest.detail(backdrops: List<String>, poster: String? = null) {
        colourImages(requested)
        val fixture = DetailFixture(DetailFixture.item("movie", MediaKind.MOVIE, "Arrival") { copy(backdropPaths = backdrops, thumbPath = poster) }, tv = false)
        setContent {
            val owner = remember {
                object : NavigationEventDispatcherOwner {
                    override val navigationEventDispatcher = NavigationEventDispatcher()
                }
            }
            CompositionLocalProvider(
                LocalNavigationEventDispatcherOwner provides owner,
                LocalPlezyPlatform provides TestPlatform(FormFactor.HANDHELD),
                LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false),
            ) {
                PlezyTheme {
                    Box(Modifier.size(411.dp, 800.dp)) {
                        AdaptiveLayout(FormFactor.HANDHELD) {
                            OverlayHostBox {
                                val state by fixture.store.state.collectAsState()
                                DetailContent(state, fixture.intents)
                            }
                        }
                    }
                }
            }
        }
    }

    /** The detail's backdrop between the back button's room and the title. */
    private fun ComposeUiTest.detailColour() = colourAt(20, 90)

    private companion object {
        const val SERVER = "server-1"
        const val COLLECTION = "collection-1"

        /** A server holding one collection with [backdrops] and a movie in it. */
        fun collectionServer(backdrops: List<String>): MediaBackend =
            Proxy.newProxyInstance(MediaBackend::class.java.classLoader, arrayOf(MediaBackend::class.java)) { _, method, _ ->
                when (method.name) {
                    "fetchItem" -> MediaItem(
                        id = COLLECTION, backend = BackendKind.JELLYFIN, kind = MediaKind.COLLECTION, title = "Saga", serverId = SERVER, childCount = 1,
                        backdropPaths = backdrops,
                    )
                    "fetchCollectionPage" -> LibraryPage(listOf(MediaItem(id = "m1", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Movie", serverId = SERVER)), totalCount = 1)
                    "getServerId" -> SERVER
                    "toString" -> "CollectionServer"
                    "hashCode" -> 0
                    else -> null
                }
            } as MediaBackend
    }
}
