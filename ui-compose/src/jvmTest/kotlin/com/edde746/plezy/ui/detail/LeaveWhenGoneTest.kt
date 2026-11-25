package com.edde746.plezy.ui.detail

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import kotlin.test.Test
import kotlin.test.assertEquals

/** A deleted title's page leaves only while it is the top screen, never closing what lies over it in its place. */
@OptIn(ExperimentalTestApi::class)
class LeaveWhenGoneTest {
    private val detail = Route.MediaDetail(ServerId("srv"), "m")

    @Test
    fun `a deleted title under a sheet stays until the sheet closes and then leaves`() = runComposeUiTest {
        val sheet = Route.SeerrRequest(1, MediaKind.MOVIE, "Request")
        val navigator = PlezyNavigator(Route.Home).apply {
            navigate(detail)
            navigate(sheet)
        }
        setContent { LeaveWhenGone(gone = true, detail, navigator) }
        waitForIdle()
        assertEquals(listOf(Route.Home, detail, sheet), navigator.backStack.value, "the sheet stays open over the page")
        runOnIdle { navigator.back() }
        waitForIdle()
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value, "the page left once the sheet closed")
    }
}
