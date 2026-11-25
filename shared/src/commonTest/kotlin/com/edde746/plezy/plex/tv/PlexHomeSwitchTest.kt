package com.edde746.plezy.plex.tv

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.fail

/**
 * Plex once started sending profile language lists as CSV strings ("en,sv") instead of arrays; a parse failure on the
 * 201 /switch answer reported failure and dropped the freshly minted token, leaving the app offline for good.
 */
private const val DRIFTED_SWITCH_BODY = """{"id":312174832,"uuid":"uuid-1","title":"hi_phi","authToken":"minted-user-token",
"protected":true,"home":true,"profile":{"defaultAudioLanguage":"en","defaultAudioLanguages":"en,sv",
"defaultSubtitleLanguage":"en","defaultSubtitleLanguages":"en,sv","mediaReviewsLanguages":null,"mediaPostsVisibility":true}}"""

private const val INVALID_PIN_BODY = """{"errors":[{"code":1041,"message":"Invalid PIN","status":403}]}"""

class PlexHomeSwitchTest {
    @Test
    fun `succeeds and keeps the token when the 201 body has drifted field shapes`() = runTest {
        val (auth, http) = authWith { jsonResponse(DRIFTED_SWITCH_BODY, status = 201) }

        val result = switchPlexHomeUserWithPin(
            requiresPin = false,
            promptForPin = { fail("should not prompt") },
            switchToUser = { pin -> auth.switchToUser("uuid-1", "account-token", pin) },
        )

        assertEquals(PlexHomeSwitchStatus.SUCCESS, result.status)
        assertEquals("minted-user-token", result.userToken)
        assertEquals(HttpMethod.Post, http.requests.single().method)
        assertEquals("/api/v2/home/users/uuid-1/switch", http.requests.single().url.encodedPath)
    }

    @Test
    fun `re prompts on Plex error 1041 and succeeds with the corrected PIN`() = runTest {
        var attempts = 0
        val (auth, http) = authWith {
            attempts++
            if (attempts == 1) jsonResponse(INVALID_PIN_BODY, status = 403) else jsonResponse(DRIFTED_SWITCH_BODY, status = 201)
        }
        val prompts = mutableListOf<Boolean>()

        val result = switchPlexHomeUserWithPin(
            requiresPin = false,
            promptForPin = { incorrectPin ->
                prompts += incorrectPin
                "1234"
            },
            switchToUser = { pin -> auth.switchToUser("uuid-1", "account-token", pin) },
        )

        assertEquals(PlexHomeSwitchStatus.SUCCESS, result.status)
        assertEquals("minted-user-token", result.userToken)
        assertEquals(2, attempts)
        assertEquals(listOf(true), prompts)
        assertEquals("1234", http.requests.last().url.parameters["pin"])
    }

    @Test
    fun `a protected user is asked for the PIN before the first attempt`() = runTest {
        val (auth, http) = authWith { jsonResponse(DRIFTED_SWITCH_BODY, status = 201) }
        val prompts = mutableListOf<Boolean>()

        val result = switchPlexHomeUserWithPin(
            requiresPin = true,
            promptForPin = { incorrectPin ->
                prompts += incorrectPin
                "0000"
            },
            switchToUser = { pin -> auth.switchToUser("uuid-1", "account-token", pin) },
        )

        assertEquals(PlexHomeSwitchStatus.SUCCESS, result.status)
        assertEquals(listOf(false), prompts)
        assertEquals("0000", http.requests.single().url.parameters["pin"])
    }

    @Test
    fun `reports cancelled when the user dismisses the PIN prompt`() = runTest {
        val (auth, _) = authWith { jsonResponse(INVALID_PIN_BODY, status = 403) }

        val result = switchPlexHomeUserWithPin(
            requiresPin = false,
            promptForPin = { null },
            switchToUser = { pin -> auth.switchToUser("uuid-1", "account-token", pin) },
        )

        assertEquals(PlexHomeSwitchStatus.CANCELLED, result.status)
        assertNull(result.userToken)
    }

    @Test
    fun `reports failed when the response has no token`() = runTest {
        val (auth, _) = authWith { jsonResponse("""{"id":1,"uuid":"uuid-1"}""", status = 201) }

        val result = switchPlexHomeUserWithPin(
            requiresPin = false,
            promptForPin = { fail("should not prompt") },
            switchToUser = { pin -> auth.switchToUser("uuid-1", "account-token", pin) },
        )

        assertEquals(PlexHomeSwitchStatus.FAILED, result.status)
        assertNull(result.userToken)
    }

    @Test
    fun `a rejected account token is authRejected any other HTTP failure failed`() = runTest {
        var status = 401
        val (auth, _) = authWith { jsonResponse("""{"errors":[{"code":1001}]}""", status = status) }
        suspend fun attempt() = switchPlexHomeUserWithPin(
            requiresPin = false,
            promptForPin = { fail("should not prompt") },
            switchToUser = { pin -> auth.switchToUser("uuid-1", "account-token", pin) },
        ).status

        assertEquals(PlexHomeSwitchStatus.AUTH_REJECTED, attempt())
        status = 403
        assertEquals(PlexHomeSwitchStatus.FAILED, attempt())
        status = 500
        assertEquals(PlexHomeSwitchStatus.FAILED, attempt())
    }
}
