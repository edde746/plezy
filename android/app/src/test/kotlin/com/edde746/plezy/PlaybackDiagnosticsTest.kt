package com.edde746.plezy

import org.junit.Assert.*
import org.junit.Test
import java.io.IOException
import java.net.UnknownHostException
import javax.net.ssl.SSLHandshakeException

class PlaybackDiagnosticsTest {
    @Test fun nestedNetworkCauseIsPreservedWithoutLeakingCredentials() {
        val cause = SSLHandshakeException("https://private.test/?X-Plex-Token=secret")
        val error = IOException("secret header", cause)
        assertTrue(PlaybackDiagnostics.isConnectionFailure(error))
        assertEquals("IOException -> SSLHandshakeException", PlaybackDiagnostics.describe(error))
        assertFalse(PlaybackDiagnostics.describe(error).contains("secret"))
        assertTrue(PlaybackDiagnostics.isConnectionFailure(UnknownHostException("private.test")))
        assertFalse(PlaybackDiagnostics.isConnectionFailure(IllegalStateException("decoder")))
    }

    @Test fun historyIsBoundedAndSnapshotIsIndependent() {
        val log = PlaybackDiagnostics()
        repeat(100) { log.add("Event $it") }
        val snapshot = log.snapshot()
        assertEquals(32, snapshot.size)
        assertEquals("Event 68", snapshot.first())
        log.add("new event")
        assertEquals("Event 99", snapshot.last())
    }
}
