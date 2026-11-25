package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.BrowserMode
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.onboarding.AccountsHost
import com.edde746.plezy.presentation.onboarding.PlexPinFlow
import com.edde746.plezy.presentation.onboarding.PlexPinPhase
import com.edde746.plezy.presentation.onboarding.PlexPinUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Plex's QR sign-in page on a TV and on a phone: the QR code, "plex.tv/link" and the code to enter there, the waiting
 * line and Retry, each on screen; once the code expired, the expiry and Retry under it alone. On a TV Retry holds the
 * focus throughout, so a remote always shows where it is.
 */
@OptIn(ExperimentalTestApi::class)
class PlexPinPageTest {
    private val probed = mutableMapOf<String, Rect>()
    private val scope = CoroutineScope(Job())
    private val flow = PlexPinFlow({ awaitCancellation() }, NoHost, {}, scope)
    private val waiting = PlexPinUiState(phase = PlexPinPhase.QR, qrUrl = "https://www.plex.tv/link/?pin=6TWW", code = "6TWW", ready = true)
    private val expired = PlexPinUiState(phase = PlexPinPhase.QR, expired = true, error = T.auth.codeExpired, ready = true)
    private val shown = mutableStateOf(waiting)

    @AfterTest
    fun stop() = scope.coroutineContext[Job]!!.cancel()

    @Test
    fun onTvTheCodeAndWhereToEnterItShowBesideTheQrCode() = runComposeUiTest {
        page(FormFactor.TV, 960.dp, 540.dp, waiting)
        assertShown(960.dp, 540.dp, "signin.qr.code", "signin.link", "signin.code", "signin.waiting", "signin.retry")
        val qr = probed.getValue("signin.qr.code")
        assertTrue(probed.getValue("signin.code").right <= qr.left, "the code left of the QR code")
    }

    @Test
    fun onAPhoneTheCodeShowsUnderTheQrCode() = runComposeUiTest {
        page(FormFactor.HANDHELD, 412.dp, 915.dp, waiting)
        assertShown(412.dp, 915.dp, "signin.qr.code", "signin.link", "signin.code", "signin.waiting", "signin.retry")
        assertTrue(probed.getValue("signin.code").top >= probed.getValue("signin.qr.code").bottom, "the code under the QR code")
    }

    @Test
    fun anExpiredCodeLeavesTheExpiryAndRetryUnderIt() = runComposeUiTest {
        page(FormFactor.TV, 960.dp, 540.dp, expired)
        onNodeWithText(T.auth.codeExpired).assertIsDisplayed()
        assertShown(960.dp, 540.dp, "signin.error", "signin.retry")
        for (gone in listOf("signin.qr.code", "signin.link", "signin.code", "signin.waiting")) {
            assertFalse(gone in probed, "$gone shows on an expired code")
        }
        assertTrue(probed.getValue("signin.error").bottom <= probed.getValue("signin.retry").top, "the expiry before Retry")
    }

    @Test
    fun onTvRetryHoldsTheFocusWhileWaitingAndOnceTheCodeExpired() = runComposeUiTest {
        page(FormFactor.TV, 960.dp, 540.dp, waiting)
        onNodeWithText(T.common.retry).assertIsFocused()
        shown.value = expired
        waitForIdle()
        onNodeWithText(T.common.retry).assertIsFocused()
    }

    private fun ComposeUiTest.page(formFactor: FormFactor, width: Dp, height: Dp, state: PlexPinUiState) {
        shown.value = state
        setContent {
            PlezyTheme {
                Box(Modifier.size(width, height)) {
                    AdaptiveLayout(formFactor) {
                        CompositionLocalProvider(LocalLayoutProbe provides LayoutProbe { name, bounds -> if (bounds != null) probed[name] = bounds }) {
                            PlexPinPage(T.app.title, shown.value, flow) {}
                        }
                    }
                }
            }
        }
        waitForIdle()
    }

    private fun ComposeUiTest.assertShown(width: Dp, height: Dp, vararg names: String) {
        val window = with(density) { Rect(0f, 0f, width.toPx(), height.toPx()) }
        for (name in names) {
            val bounds = assertNotNull(probed[name], "$name doesn't show")
            assertTrue(bounds.left >= window.left && bounds.right <= window.right && bounds.top >= window.top && bounds.bottom <= window.bottom, "$name at $bounds is off the $window window")
        }
    }

    private object NoHost : AccountsHost {
        override val tv = false
        override fun open(route: Route) = Unit
        override fun back() = Unit
        override fun connectionAdded(from: Route, pickProfile: Boolean) = Unit
        override fun profileChosen(from: Route) = Unit
        override fun leavePicker(from: Route) = Unit
        override fun signedOut() = Unit
        override fun pickRequired() = Unit
        override suspend fun pickProfile() = false
        override suspend fun borrowInto(profileId: String) = false
        override fun openUrl(url: String, mode: BrowserMode) = false
        override fun closeBrowser() = Unit
        override fun exit() = Unit
    }
}
