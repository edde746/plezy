package com.edde746.plezy.backend

import com.edde746.plezy.log.Log
import com.edde746.plezy.strings.T
import io.ktor.http.Url
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ErrorMessagesTest {
    private val originalSink = Log.sink
    private val logLevels = mutableListOf<Log.Level>()

    @BeforeTest
    fun setUp() {
        T.locale = "es"
        Log.sink = Log.Sink { level, _, _, _ -> logLevels += level }
    }

    @AfterTest
    fun tearDown() {
        T.locale = "en"
        Log.sink = originalSink
    }

    @Test
    fun loadErrorsTellTimeoutsFromConnectionFailures() {
        for (type in listOf(MediaServerHttpErrorType.CONNECTION_TIMEOUT, MediaServerHttpErrorType.RECEIVE_TIMEOUT)) {
            val message = localizedLoadErrorMessage(MediaServerHttpException(type, "private timeout detail"), "Biblioteca")

            assertEquals("Tiempo de conexión agotado al cargar Biblioteca", message)
        }

        val connection = localizedLoadErrorMessage(MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "private connection detail"), "Biblioteca")

        assertEquals("No se puede conectar al servidor multimedia", connection)
    }

    @Test
    fun anUnexpectedLoadFailureIsLoggedOnceAndShownOnlyAsTheLocalizedFallback() {
        val privateDetail = "token=super-secret"

        val message = localizedLoadErrorMessage(IllegalStateException(privateDetail), "Biblioteca")

        assertEquals("No se pudo cargar Biblioteca. Inténtalo de nuevo.", message)
        assertEquals(listOf(Log.Level.ERROR), logLevels)
    }

    @Test
    fun aLoadErrorNeverShowsServerStatusTextResponseDataOrExceptionMessages() {
        val serverText = "database failed for user@example.com"
        val error = MediaServerHttpException(
            MediaServerHttpErrorType.UNKNOWN,
            serverText,
            statusCode = 500,
            responseData = buildJsonObject { put("error", serverText) },
        )

        val message = localizedLoadErrorMessage(error, "Biblioteca")

        assertEquals("No se pudo cargar Biblioteca. Inténtalo de nuevo.", message)
        assertFalse("500" in message)
    }

    @Test
    fun theReasonPrefersTheExceptionsOwnDisplayText() {
        val error = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "socket closed", display = "El servidor rechazó la conexión")

        assertEquals("El servidor rechazó la conexión", localizedErrorReason(error))
    }

    @Test
    fun theReasonTellsApartTheFailureKindsACallerActsOnDifferently() {
        fun reason(type: MediaServerHttpErrorType, status: Int? = null) = localizedErrorReason(MediaServerHttpException(type, statusCode = status))

        val timedOut = reason(MediaServerHttpErrorType.CONNECTION_TIMEOUT)
        val unreachable = reason(MediaServerHttpErrorType.CONNECTION_ERROR)
        val refused = reason(MediaServerHttpErrorType.UNKNOWN, 403)
        val gone = reason(MediaServerHttpErrorType.UNKNOWN, 404)
        val serverSide = reason(MediaServerHttpErrorType.UNKNOWN, 503)
        val cancelled = reason(MediaServerHttpErrorType.CANCELLED)

        assertEquals(timedOut, reason(MediaServerHttpErrorType.RECEIVE_TIMEOUT))
        assertEquals(refused, reason(MediaServerHttpErrorType.UNKNOWN, 401))
        assertEquals(refused, localizedErrorReason(MediaServerAuthException("token refused")))
        val kinds = setOf(timedOut, unreachable, refused, gone, serverSide, cancelled)
        assertEquals(6, kinds.size)
        assertFalse(localizedErrorReason(IllegalStateException("boom")) in kinds)
    }

    @Test
    fun theReasonKeepsTheSpecificTextOfADisplaySafePlaybackFailure() {
        val error = PlaybackException("Stream selection is not available for this source")

        assertEquals("Stream selection is not available for this source", localizedErrorReason(error))
    }

    @Test
    fun theReasonNeverLeaksTheRequestHostPathStatusOrExceptionText() {
        val serverText = "Internal Server Error at /library/metadata/42"
        val error = MediaServerHttpException(
            MediaServerHttpErrorType.UNKNOWN,
            serverText,
            statusCode = 500,
            responseData = JsonPrimitive(serverText),
            requestUri = Url("https://media.example.test/library/metadata/42?X-Plex-Token=secret"),
        )

        val reason = localizedErrorReason(error)

        assertTrue(reason.isNotEmpty())
        for (leak in listOf("500", serverText, "media.example.test", "/library/metadata", "secret", "MediaServerHttpException")) {
            assertFalse(leak in reason, "reason leaks $leak: $reason")
        }
    }
}
