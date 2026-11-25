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
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.intercept.Interceptor
import coil3.request.ErrorResult
import coil3.request.ImageResult
import coil3.request.transformations
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.detail.EpisodeDownloadUi
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.image.SizedArtwork
import com.edde746.plezy.ui.image.StillBlur
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * What a phone's detail page shows: the download button only online, an episode's still blurred while it would spoil
 * the episode, an episode's download state said to screen readers, and an offline episode's menu on a long press.
 */
@OptIn(ExperimentalTestApi::class)
class DetailPageContentTest {
    /** Each artwork path the page asked an image for, and whether it asked for it blurred. */
    private val requested = ConcurrentHashMap<String, Boolean>()

    @AfterTest
    fun resetImages() {
        SingletonImageLoader.reset()
    }

    @Test
    fun `an online detail has a download button`() = runComposeUiTest {
        detail(DetailFixture.movie(tv = false))
        onAllNodesWithContentDescription(T.downloads.downloadNow).assertCountEquals(1)
    }

    @Test
    fun `an offline detail has no download button`() = runComposeUiTest {
        detail(DetailFixture.movie(tv = false, offline = true))
        onAllNodesWithText("Arrival").onFirst().assertExists()
        onAllNodesWithContentDescription(T.downloads.downloadNow).assertCountEquals(0)
    }

    @Test
    fun `with spoilers hidden only the unwatched episode still is blurred`() = runComposeUiTest {
        recordImages()
        detail(season(hideSpoilers = true))
        waitUntil { requested.keys.containsAll(STILLS) }
        assertEquals(mapOf("/still/e1" to false, "/still/e2" to true), requested.filterKeys { it in STILLS })
    }

    @Test
    fun `with spoilers shown no episode still is blurred`() = runComposeUiTest {
        recordImages()
        detail(season(hideSpoilers = false))
        waitUntil { requested.keys.containsAll(STILLS) }
        assertEquals(mapOf("/still/e1" to false, "/still/e2" to false), requested.filterKeys { it in STILLS })
    }

    @Test
    fun `an episode row says its download state to screen readers`() = runComposeUiTest {
        detail(season(hideSpoilers = false, download = EpisodeDownloadUi(DownloadedMediaStatus.COMPLETED, progress = null, queueing = false)))
        onNode(hasText("1. Episode 1") and hasClickAction()).assert(hasContentDescription(T.downloads.notificationComplete))
    }

    @Test
    fun `a long press on an offline episode row opens its menu`() = runComposeUiTest {
        val fixture = season(hideSpoilers = false, offline = true)
        detail(fixture)
        onNode(hasText("2. Episode 2") and hasClickAction()).performTouchInput { longClick() }
        waitForIdle()
        assertEquals("Episode 2", fixture.menu.menu.value?.title)
        assertEquals(emptyList(), fixture.plays)
    }

    /** A show's only season: episode 1 watched, episode 2 not, each with its still and [download]. */
    private fun season(hideSpoilers: Boolean, offline: Boolean = false, download: EpisodeDownloadUi? = null): DetailFixture {
        val season = DetailFixture.item("s1", MediaKind.SEASON, "Season 1") { copy(index = 1, parentId = "show") }
        val episodes = (1..2).map { n ->
            DetailFixture.item("e$n", MediaKind.EPISODE, "Episode $n") {
                copy(index = n, parentIndex = 1, parentId = "s1", grandparentId = "show", thumbPath = "/still/e$n", viewCount = if (n == 1) 1 else 0)
            }
        }
        return DetailFixture(
            DetailFixture.item("show", MediaKind.SHOW, "Severance"),
            children = mapOf("show" to listOf(season), "s1" to episodes),
            tv = false,
            downloads = download != null,
            cards = CardOptions(hideSpoilers = hideSpoilers),
            offline = offline,
            episodeDownload = download,
        )
    }

    /** Images load through a loader that notes each request ([requested]) and loads none. */
    private fun recordImages() {
        val recorder = object : Interceptor {
            override suspend fun intercept(chain: Interceptor.Chain): ImageResult {
                val data = chain.request.data
                if (data is SizedArtwork) requested[data.artwork.path] = StillBlur in chain.request.transformations
                return ErrorResult(null, chain.request, IllegalStateException("no images load in these tests"))
            }
        }
        SingletonImageLoader.setUnsafe(ImageLoader.Builder(PlatformContext.INSTANCE).components { add(recorder) }.build())
    }

    private fun ComposeUiTest.detail(fixture: DetailFixture) {
        setContent {
            val owner = remember {
                object : NavigationEventDispatcherOwner {
                    override val navigationEventDispatcher = NavigationEventDispatcher()
                }
            }
            CompositionLocalProvider(
                LocalNavigationEventDispatcherOwner provides owner,
                LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false),
            ) {
                PlezyTheme {
                    Box(Modifier.size(411.dp, 2000.dp)) {
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
        waitForIdle()
    }

    private companion object {
        val STILLS = setOf("/still/e1", "/still/e2")
    }
}
