package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.rightClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.detail.PersonStore
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import java.lang.reflect.Proxy
import kotlin.test.Test
import kotlin.test.assertEquals

/** An actor's titles each open their item menu, as a collection's do: a long press on a phone, a right click with a pointer. */
@OptIn(ExperimentalTestApi::class)
class PersonMenuTest {
    private val titles = (1..3).map { MediaItem(id = "m$it", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = "Movie $it", serverId = SERVER) }
    private val opened = mutableListOf<MediaItem>()

    @Test
    fun aLongPressOnATitleOpensItsMenu() = runComposeUiTest {
        person(FormFactor.HANDHELD)
        onNode(card("Movie 2")).performTouchInput { longClick() }
        waitForIdle()
        assertEquals(listOf("m2"), opened.map { it.id })
    }

    @Test
    fun aRightClickOnATitleOpensItsMenu() = runComposeUiTest {
        person(FormFactor.DESKTOP)
        onNode(card("Movie 3")).performMouseInput { rightClick() }
        waitForIdle()
        assertEquals(listOf("m3"), opened.map { it.id })
    }

    private fun ComposeUiTest.person(formFactor: FormFactor) {
        val store = PersonStore(
            Route.Person(ServerId(SERVER), PERSON, "Maestro Actor"),
            personServer(titles),
            { CardOptions() },
            { CalendarDate(2026, 1, 1) },
            CoroutineScope(Dispatchers.Unconfined),
        )
        val dispatcher = NavigationEventDispatcher()
        setContent {
            val owner = remember { object : NavigationEventDispatcherOwner { override val navigationEventDispatcher = dispatcher } }
            CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
                PlezyTheme {
                    AdaptiveLayout(formFactor) {
                        OverlayHostBox(Modifier.fillMaxSize()) {
                            PersonPage(store, onBack = {}, onOpen = {}, onMenu = { opened += it })
                        }
                    }
                }
            }
        }
        waitForIdle()
    }

    private companion object {
        const val SERVER = "server-1"
        const val PERSON = "person-1"

        /** A server whose person [PERSON] has [titles] and no details. */
        fun personServer(titles: List<MediaItem>): MediaBackend =
            Proxy.newProxyInstance(MediaBackend::class.java.classLoader, arrayOf(MediaBackend::class.java)) { _, method, _ ->
                when (method.name) {
                    "fetchPersonMediaPage" -> LibraryPage(titles, totalCount = titles.size)
                    "fetchPersonDetails" -> MediaPersonDetails.EMPTY
                    "getServerId" -> SERVER
                    "toString" -> "PersonServer"
                    "hashCode" -> 0
                    else -> null
                }
            } as MediaBackend
    }
}
