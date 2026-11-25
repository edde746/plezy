package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.MultiServerState
import com.edde746.plezy.servers.NamedServer
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AuthErrorBannerTest {
    private fun named(name: String) = NamedServer(ServerId(name), name)

    @Test
    fun `no refusing server shows no banner`() {
        assertNull(authErrorBanner(MultiServerState()))
    }

    @Test
    fun `a server refusing the account is explained without a sign in that cannot help`() {
        val banner = authErrorBanner(MultiServerState(accessDeniedServers = listOf(named("denied"))))

        assertEquals(AuthErrorBannerUi(sessionExpired = null, accessDenied = T.connections.accessDeniedOne("denied")), banner)
    }

    @Test
    fun `a rejected token keeps its sign in prompt beside a refused account`() {
        val banner = authErrorBanner(MultiServerState(authErrorServers = listOf(named("expired")), accessDeniedServers = listOf(named("denied"))))

        assertEquals(T.connections.sessionExpiredOne("expired"), banner?.sessionExpired)
        assertEquals(T.connections.accessDeniedOne("denied"), banner?.accessDenied)
    }

    @Test
    fun `several refusing servers are counted`() {
        val banner = authErrorBanner(
            MultiServerState(authErrorServers = listOf(named("a"), named("b")), accessDeniedServers = listOf(named("c"), named("d"), named("e"))),
        )

        assertEquals(AuthErrorBannerUi(T.connections.sessionExpiredMany("2"), T.connections.accessDeniedMany("3")), banner)
    }

    @Test
    fun `sign in again is not offered again for the server whose sign in is open`() {
        val state = MultiServerState(authErrorServers = listOf(named("expired")))

        val open = authErrorBanner(state, reauthOpen = setOf(ServerId("expired")))
        assertEquals(T.connections.sessionExpiredOne("expired"), open?.sessionExpired)
        assertEquals(false, open?.signInAgain)
        assertEquals(true, authErrorBanner(state)?.signInAgain)
        // Another server's session expired too: its sign in is still offered.
        val two = MultiServerState(authErrorServers = listOf(named("expired"), named("other")))
        assertEquals(true, authErrorBanner(two, reauthOpen = setOf(ServerId("expired")))?.signInAgain)
    }
}
