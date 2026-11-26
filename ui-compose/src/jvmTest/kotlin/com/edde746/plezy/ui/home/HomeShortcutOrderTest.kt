package com.edde746.plezy.ui.home

import com.edde746.plezy.ui.home.HomeShortcut.DOWNLOADS
import com.edde746.plezy.ui.home.HomeShortcut.LIBRARIES
import com.edde746.plezy.ui.home.HomeShortcut.LIVE_TV
import com.edde746.plezy.ui.home.HomeShortcut.REFRESH
import com.edde746.plezy.ui.home.HomeShortcut.SERVER_TASKS
import com.edde746.plezy.ui.home.HomeShortcut.USER_MENU
import com.edde746.plezy.ui.home.HomeShortcut.WATCH_TOGETHER
import kotlin.test.Test
import kotlin.test.assertEquals

/** Home's shortcut row: Live TV and the libraries lead, Refresh and the user menu end it. */
class HomeShortcutOrderTest {
    @Test
    fun onTvLiveTvAndTheLibrariesLeadAndRefreshEndsTheRow() {
        assertEquals(
            listOf(LIVE_TV, LIBRARIES, WATCH_TOGETHER, DOWNLOADS, SERVER_TASKS, REFRESH),
            homeShortcutOrder(tv = true, liveTv = true, downloads = true, bar = false),
        )
        assertEquals(
            listOf(LIBRARIES, WATCH_TOGETHER, SERVER_TASKS, REFRESH),
            homeShortcutOrder(tv = true, liveTv = false, downloads = false, bar = false),
        )
    }

    @Test
    fun onAPhoneTheUserMenuEndsTheRowAndThereIsNoRefresh() {
        assertEquals(
            listOf(LIVE_TV, LIBRARIES, WATCH_TOGETHER, DOWNLOADS, SERVER_TASKS, USER_MENU),
            homeShortcutOrder(tv = false, liveTv = true, downloads = true, bar = true),
        )
        assertEquals(
            listOf(LIBRARIES, WATCH_TOGETHER, DOWNLOADS, SERVER_TASKS),
            homeShortcutOrder(tv = false, liveTv = false, downloads = true, bar = false),
        )
    }
}
