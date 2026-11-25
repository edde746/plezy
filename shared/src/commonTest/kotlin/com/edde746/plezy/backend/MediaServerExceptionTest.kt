package com.edde746.plezy.backend

import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.http.Url
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class MediaServerExceptionTest {
    private val uri = Url("http://example/api/thing")

    @Test
    fun anHttpExceptionIsReturnedAsItIs() {
        val original = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "boom", requestUri = uri)

        assertSame(original, MediaServerHttpException.from(original, uri))
    }

    @Test
    fun timeoutsMapToConnectionTimeout() = runTest {
        val coroutineTimeout = assertFailsWith<TimeoutCancellationException> { withTimeout(1) { awaitCancellation() } }
        val failures = listOf(coroutineTimeout, HttpRequestTimeoutException("http://example/api/thing", 1000), ConnectTimeoutException("took too long"))

        for (failure in failures) {
            val result = MediaServerHttpException.from(failure, uri)
            assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, result.type, failure.toString())
            assertEquals(uri, result.requestUri)
        }
        assertEquals("took too long", MediaServerHttpException.from(ConnectTimeoutException("took too long"), uri).message)
    }

    @Test
    fun aSocketTimeoutMapsToReceiveTimeout() {
        val result = MediaServerHttpException.from(SocketTimeoutException("stalled body"), uri)

        assertEquals(MediaServerHttpErrorType.RECEIVE_TIMEOUT, result.type)
        assertEquals("stalled body", result.message)
        assertEquals(uri, result.requestUri)
    }

    @Test
    fun anIoFailureMapsToConnectionError() {
        val result = MediaServerHttpException.from(IOException("refused"), uri)

        assertEquals(MediaServerHttpErrorType.CONNECTION_ERROR, result.type)
        assertEquals("refused", result.message)
        assertEquals(uri, result.requestUri)
    }

    @Test
    fun anyOtherErrorIsUnknownWithItsText() {
        val result = MediaServerHttpException.from(IllegalStateException("weird"), uri)

        assertEquals(MediaServerHttpErrorType.UNKNOWN, result.type)
        assertTrue("weird" in result.message.orEmpty())
        assertEquals(uri, result.requestUri)
    }

    @Test
    fun withoutAUriTheRequestUriIsNull() {
        assertNull(MediaServerHttpException.from(ConnectTimeoutException("t")).requestUri)
    }

    @Test
    fun toStringShowsTypeAndMessage() {
        assertEquals("MediaServerHttpException(cancelled: halt)", MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "halt").toString())
    }

    @Test
    fun toStringShowsHostAndPathWithoutTheQuery() {
        val error = MediaServerHttpException(
            MediaServerHttpErrorType.CONNECTION_ERROR,
            "dns failed",
            requestUri = Url("https://clients.plex.tv/api/v2/resources?X-Plex-Token=secret"),
        )

        assertEquals("MediaServerHttpException(connectionError: dns failed: clients.plex.tv/api/v2/resources)", error.toString())
    }

    @Test
    fun toStringShowsTheStatusOfARejectedAnswer() {
        val error = MediaServerHttpException(
            MediaServerHttpErrorType.UNKNOWN,
            "HTTP 500",
            statusCode = 500,
            requestUri = Url("https://media.example.test/library/metadata/42?X-Plex-Token=secret"),
        )

        assertEquals("MediaServerHttpException(unknown: HTTP 500: HTTP 500: media.example.test/library/metadata/42)", error.toString())
    }

    @Test
    fun onlyTimeoutsAndConnectionErrorsAreTransient() {
        fun transient(type: MediaServerHttpErrorType) = MediaServerHttpException(type).isTransient

        assertTrue(transient(MediaServerHttpErrorType.CONNECTION_TIMEOUT))
        assertTrue(transient(MediaServerHttpErrorType.RECEIVE_TIMEOUT))
        assertTrue(transient(MediaServerHttpErrorType.CONNECTION_ERROR))
        assertFalse(transient(MediaServerHttpErrorType.CANCELLED), "a cancellation is user-driven")
        assertFalse(transient(MediaServerHttpErrorType.UNKNOWN))
    }

    @Test
    fun onlyACancelledFailureIsACancellation() {
        for (type in MediaServerHttpErrorType.entries) {
            assertEquals(type == MediaServerHttpErrorType.CANCELLED, MediaServerHttpException(type).isCancellation, type.name)
        }
    }

    @Test
    fun anExpiredPinIsAnAuthFailure() {
        val error: MediaServerException = MediaServerPinExpiredException()

        assertIs<MediaServerAuthException>(error)
        assertEquals("PIN expired before sign-in", error.message)
    }

    @Test
    fun aTerminatedSessionCarriesTheServersCodeAndReason() {
        val error = PlaybackSessionTerminatedException(2006, "Stopped by the server owner")

        assertEquals(2006, error.code)
        assertEquals("Stopped by the server owner", error.reason)
        assertTrue("2006" in error.message.orEmpty())
    }
}
