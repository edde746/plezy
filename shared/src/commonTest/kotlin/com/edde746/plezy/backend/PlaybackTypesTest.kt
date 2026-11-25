package com.edde746.plezy.backend

import com.edde746.plezy.backend.TranscodeQualityPreset.ORIGINAL
import com.edde746.plezy.backend.TranscodeQualityPreset.P1080_10MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P1080_12MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P1080_20MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P1080_8MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P240_320
import com.edde746.plezy.backend.TranscodeQualityPreset.P320_720
import com.edde746.plezy.backend.TranscodeQualityPreset.P480_1_5MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P720_2MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P720_3MBPS
import com.edde746.plezy.backend.TranscodeQualityPreset.P720_4MBPS
import com.edde746.plezy.strings.T
import io.ktor.http.Url
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonPrimitive
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlaybackTypesTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    @AfterTest
    fun restore() {
        T.locale = "en"
    }

    private fun http(type: MediaServerHttpErrorType, status: Int? = null, message: String = "") =
        MediaServerHttpException(type, message, statusCode = status, responseData = JsonPrimitive("body-canary"))

    private fun assertSafe(failure: PlaybackException, vararg canaries: String) {
        for (canary in canaries) {
            assertFalse(canary in failure.message.orEmpty(), "message leaks $canary")
            assertFalse(canary in failure.toString(), "text leaks $canary")
        }
    }

    // classifyPlaybackFailure.

    @Test
    fun a401OrARefusedSignInAsksForAuthentication() {
        val unauthorized = classifyPlaybackFailure(http(MediaServerHttpErrorType.UNKNOWN, 401))

        assertEquals(PlaybackFailureReason.AUTHENTICATION_REQUIRED, unauthorized.reason)
        assertSafe(unauthorized, "body-canary")
        assertEquals(PlaybackFailureReason.AUTHENTICATION_REQUIRED, classifyPlaybackFailure(MediaServerAuthException("token refused", 401)).reason)
    }

    // A user the server knows but refuses (remote access disabled): signing in again cannot help.
    @Test
    fun a403IsNotAllowedRatherThanAnAuthenticationFailure() {
        assertEquals(PlaybackFailureReason.PLAYBACK_NOT_ALLOWED, classifyPlaybackFailure(http(MediaServerHttpErrorType.UNKNOWN, 403)).reason)
    }

    @Test
    fun aTimeoutIsServerUnavailableWithoutItsDetailOrUri() {
        val error = MediaServerHttpException(
            MediaServerHttpErrorType.RECEIVE_TIMEOUT,
            "timeout-canary",
            requestUri = Url("https://private.invalid/library/metadata/42?secret=uri-canary"),
        )

        val failure = classifyPlaybackFailure(error)

        assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, failure.reason)
        assertSafe(failure, "timeout-canary", "private.invalid", "uri-canary")
    }

    @Test
    fun serverErrorsConnectionFailuresAndCancellationsKeepTheirOwnReasons() {
        val cases = listOf(
            http(MediaServerHttpErrorType.UNKNOWN, 500) to PlaybackFailureReason.SERVER_UNAVAILABLE,
            http(MediaServerHttpErrorType.CONNECTION_ERROR, message = "unavailable") to PlaybackFailureReason.SERVER_UNAVAILABLE,
            http(MediaServerHttpErrorType.CONNECTION_TIMEOUT) to PlaybackFailureReason.SERVER_UNAVAILABLE,
            http(MediaServerHttpErrorType.CANCELLED) to PlaybackFailureReason.CANCELLED,
        )

        for ((error, reason) in cases) assertEquals(reason, classifyPlaybackFailure(error).reason, error.toString())
    }

    @Test
    fun aMalformedAnswerIsInvalidPlaybackData() {
        val malformed = listOf(
            SerializationException("payload-canary"),
            IllegalArgumentException("payload-canary"),
            ClassCastException("payload-canary"),
            // A successful answer whose body failed to decode.
            http(MediaServerHttpErrorType.UNKNOWN, 200, "payload-canary"),
        )

        for (error in malformed) {
            val failure = classifyPlaybackFailure(error)
            assertEquals(PlaybackFailureReason.INVALID_PLAYBACK_DATA, failure.reason, error.toString())
            assertSafe(failure, "payload-canary")
        }
    }

    @Test
    fun anUnclassifiedFailureUsesTheSafeUnknownReasonAndMessage() {
        val failure = classifyPlaybackFailure(IllegalStateException("unknown-cause-canary"))

        assertEquals(PlaybackFailureReason.UNKNOWN, failure.reason)
        assertSafe(failure, "unknown-cause-canary")
    }

    @Test
    fun eachFailureKindHasItsOwnMessage() {
        val failures = listOf(
            http(MediaServerHttpErrorType.UNKNOWN, 401),
            http(MediaServerHttpErrorType.UNKNOWN, 403),
            http(MediaServerHttpErrorType.UNKNOWN, 500),
            http(MediaServerHttpErrorType.CANCELLED),
            SerializationException("bad"),
            IllegalStateException("other"),
        ).map(::classifyPlaybackFailure)

        assertEquals(failures.size, failures.map { it.reason }.toSet().size)
        assertEquals(failures.size, failures.map { it.message }.toSet().size)
    }

    // TranscodeQualityPreset.

    @Test
    fun aSourceUnderBothCapsIsCovered() {
        assertTrue(P1080_10MBPS.coversSource(bitrateKbps = 6206, heightPx = 1080))
    }

    @Test
    fun aSourceExactlyAtTheCapsIsCoveredBecauseAnEncodeCannotImproveOnIt() {
        assertTrue(P1080_10MBPS.coversSource(bitrateKbps = 10000, heightPx = 1080))
    }

    @Test
    fun aSourceOverTheBitrateCapIsNotCovered() {
        assertFalse(P1080_10MBPS.coversSource(bitrateKbps = 13137, heightPx = 1080))
    }

    @Test
    fun aSourceOverTheResolutionCapIsNotCoveredHoweverLowItsBitrate() {
        assertFalse(P1080_10MBPS.coversSource(bitrateKbps = 6534, heightPx = 2160))
        assertFalse(P480_1_5MBPS.coversSource(bitrateKbps = 179, heightPx = 1080))
    }

    @Test
    fun aMissingOrNonPositiveBitrateOrHeightLeavesTheTranscodeStanding() {
        assertFalse(P1080_10MBPS.coversSource(bitrateKbps = null, heightPx = 1080))
        assertFalse(P1080_10MBPS.coversSource(bitrateKbps = 6206, heightPx = null))
        assertFalse(P1080_10MBPS.coversSource(bitrateKbps = 0, heightPx = 1080))
        assertFalse(P1080_10MBPS.coversSource(bitrateKbps = 6206, heightPx = 0))
    }

    @Test
    fun originalHasNoCeilingToSitInside() {
        assertFalse(ORIGINAL.coversSource(bitrateKbps = 1, heightPx = 1))
    }

    @Test
    fun pickersListOriginalFirstThenTheCapsFromBestToWorst() {
        assertEquals(
            listOf(
                ORIGINAL, P1080_20MBPS, P1080_12MBPS, P1080_10MBPS, P1080_8MBPS,
                P720_4MBPS, P720_3MBPS, P720_2MBPS, P480_1_5MBPS, P320_720, P240_320,
            ),
            TranscodeQualityPreset.displayOrder,
        )
    }

    @Test
    fun aBackendWithoutTranscodingStartsAtOriginalRegardlessOfSavedDefaults() {
        val preset = TranscodeQualityPreset.resolveStartupDefault(
            serverSupportsTranscoding = false,
            onCellularOnly = true,
            cellularDefault = P720_2MBPS,
            generalDefault = P1080_8MBPS,
        )
        assertEquals(ORIGINAL, preset)
    }

    @Test
    fun cellularOnlyAppliesTheCellularDefaultWhenOneIsSet() {
        val preset = TranscodeQualityPreset.resolveStartupDefault(
            serverSupportsTranscoding = true,
            onCellularOnly = true,
            cellularDefault = P720_2MBPS,
            generalDefault = ORIGINAL,
        )
        assertEquals(P720_2MBPS, preset)
    }

    @Test
    fun cellularOnlyWithoutACellularDefaultFollowsTheGeneralDefault() {
        val preset = TranscodeQualityPreset.resolveStartupDefault(
            serverSupportsTranscoding = true,
            onCellularOnly = true,
            cellularDefault = null,
            generalDefault = P1080_8MBPS,
        )
        assertEquals(P1080_8MBPS, preset)
    }

    @Test
    fun offCellularTheCellularDefaultIsIgnored() {
        val preset = TranscodeQualityPreset.resolveStartupDefault(
            serverSupportsTranscoding = true,
            onCellularOnly = false,
            cellularDefault = P240_320,
            generalDefault = ORIGINAL,
        )
        assertEquals(ORIGINAL, preset)
    }
}
