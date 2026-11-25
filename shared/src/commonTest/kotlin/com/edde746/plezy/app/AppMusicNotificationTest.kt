package com.edde746.plezy.app

import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.track
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** Music's media notification needs no notification permission (Android 13+ exempts media sessions). */
class AppMusicNotificationTest {
    @Test
    fun startingAQueueShowsNoNotificationPrompt() = runTest {
        val platform = FakeAppPlatform()
        val app = AppSession(testGraph(), platform)
        app.music.playFromList(listOf(track("t1")), null, MusicPlayContext("Album", MusicPlayContextKind.ALBUM), false)
        runCurrent()

        assertEquals(0, platform.notificationAsks)
        app.close()
    }
}
