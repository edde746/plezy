package com.edde746.plezy.ui.detail

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.detail.CollectionStore
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.card
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.emptyFlow
import java.lang.reflect.Proxy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.coroutines.Continuation
import kotlin.coroutines.intrinsics.COROUTINE_SUSPENDED
import kotlin.coroutines.resume

/**
 * A collection's page on TV under the remote: focus starts on its first title, Up from the first row reaches Play, Back
 * from a title goes to Play, and each card tells its row and column. An empty collection says so. Until its first
 * page is in, the page is its loading indicator alone.
 */
@OptIn(ExperimentalTestApi::class)
class CollectionFocusTest {
    private val back = DirectNavigationEventInput()
    private val store = store((1..12).map { movie("m$it", "Movie $it") })

    private fun store(items: List<MediaItem>) = CollectionStore(
        Route.CollectionDetail(ServerId(SERVER), COLLECTION),
        collectionServer(items),
        { CardOptions() },
        launchQueue = { _, _ -> error("not played") },
        collectionsChanged = emptyFlow(),
        parentScope = CoroutineScope(Dispatchers.Unconfined),
    )

    @Test
    fun focusStartsOnTheFirstTitleAndUpReachesPlay() = runComposeUiTest {
        collection()
        onNode(card("Movie 1")).assertIsFocused()
        key(Key.DirectionUp)
        onNode(play).assertIsFocused()
    }

    @Test
    fun backFromATitleGoesToPlay() = runComposeUiTest {
        collection()
        key(Key.DirectionRight)
        onNode(card("Movie 2")).assertIsFocused()
        runOnIdle { back.backCompleted() }
        waitForIdle()
        onNode(play).assertIsFocused()
    }

    @Test
    fun aCardTellsItsRowAndColumn() = runComposeUiTest {
        collection()
        val cards = onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsProperties.StateDescription) and hasClickAction()).fetchSemanticsNodes()
        val columns = cards.count { it.boundsInRoot.top == cards.first().boundsInRoot.top }
        val rows = (12 + columns - 1) / columns
        val position = onNode(card("Movie 2")).fetchSemanticsNode().config[SemanticsProperties.StateDescription]
        assertEquals(T.accessibility.rowColumnPosition("1", "$rows", "2", "$columns"), position)
    }

    @Test
    fun anEmptyCollectionSaysItIsEmpty() = runComposeUiTest {
        val empty = store(emptyList())
        setContent { TvFrame(back) { CollectionPage(empty, onBack = {}, onOpen = {}, onMenu = {}) } }
        waitForIdle()
        onNode(hasText(T.collections.empty)).assertExists()
    }

    @Test
    fun theLoadingIndicatorShowsAloneUntilTheFirstPageIsIn() = runComposeUiTest {
        var pending: Continuation<Any?>? = null
        val items = (1..3).map { movie("m$it", "Movie $it") }
        val held = CollectionStore(
            Route.CollectionDetail(ServerId(SERVER), COLLECTION),
            collectionServer(items) { pending = it },
            { CardOptions() },
            launchQueue = { _, _ -> error("not played") },
            collectionsChanged = emptyFlow(),
            parentScope = CoroutineScope(Dispatchers.Unconfined),
        )
        setContent { TvFrame(back) { CollectionPage(held, onBack = {}, onOpen = {}, onMenu = {}) } }
        waitForIdle()
        onNode(loading).assertExists()
        onNode(play).assertDoesNotExist()
        onNode(card("Movie 1")).assertDoesNotExist()

        runOnIdle { checkNotNull(pending) { "the first page wasn't asked for" }.resume(LibraryPage(items, totalCount = items.size)) }
        waitForIdle()
        onNode(loading).assertDoesNotExist()
        onNode(play).assertExists()
        onNode(card("Movie 1")).assertExists()
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private fun ComposeUiTest.collection() {
        setContent { TvFrame(back) { CollectionPage(store, onBack = {}, onOpen = {}, onMenu = {}) } }
        waitForIdle()
    }

    /** The Play button: its text, and a click action. */
    private val play: SemanticsMatcher = hasText(T.common.play) and hasClickAction()

    /** A loading indicator. */
    private val loading: SemanticsMatcher = SemanticsMatcher.keyIsDefined(SemanticsProperties.ProgressBarRangeInfo)

    private companion object {
        const val SERVER = "server-1"
        const val COLLECTION = "collection-1"

        fun movie(id: String, title: String) = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = title, serverId = SERVER)

        /**
         * A server holding one collection of [items]; with [hold] its page request waits, handed over to resume with
         * the page.
         */
        fun collectionServer(items: List<MediaItem>, hold: ((Continuation<Any?>) -> Unit)? = null): MediaBackend =
            Proxy.newProxyInstance(MediaBackend::class.java.classLoader, arrayOf(MediaBackend::class.java)) { _, method, args ->
                when (method.name) {
                    "fetchItem" -> MediaItem(id = COLLECTION, backend = BackendKind.JELLYFIN, kind = MediaKind.COLLECTION, title = "Saga", serverId = SERVER, childCount = items.size)
                    "fetchCollectionPage" -> if (hold == null) {
                        LibraryPage(items, totalCount = items.size)
                    } else {
                        @Suppress("UNCHECKED_CAST")
                        hold(args.last() as Continuation<Any?>)
                        COROUTINE_SUSPENDED
                    }
                    "getServerId" -> SERVER
                    "toString" -> "CollectionServer"
                    "hashCode" -> 0
                    else -> null
                }
            } as MediaBackend
    }
}
