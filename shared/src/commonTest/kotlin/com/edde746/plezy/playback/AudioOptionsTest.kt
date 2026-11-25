package com.edde746.plezy.playback

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AudioOptionsTest {
    private val desktopCodecs = "ac3,eac3,dts,dts-hd,truehd"

    /** mpv as the reconciler sees it: every write recorded, [reject] refusing the ones it matches. */
    private class FakeMpv {
        val writes = mutableListOf<Pair<String, String>>()
        val properties = mutableMapOf<String, String>()
        var reject: (String, String) -> Boolean = { _, _ -> false }
        val warnings = mutableListOf<String>()

        fun reconciler(exclusiveHint: Boolean = true, codecs: String = "ac3,eac3,dts,dts-hd,truehd") = AudioStateReconciler(
            normalizationFilter = LOUDNESS_NORMALIZATION_FILTER,
            exclusiveHint = exclusiveHint,
            codecs = { codecs },
            warn = { message, _ -> warnings += message },
        ) { name, value ->
            writes += name to value
            if (reject(name, value)) throw IllegalStateException("refused $name=$value")
            properties[name] = value
        }

        fun of(vararg names: String) = writes.filter { it.first in names }
    }

    @Test
    fun passthroughOnlyWhileNothingNeedsDecodedAudio() {
        fun state(normalization: Boolean = false, channels: AudioChannels = AudioChannels.ORIGINAL, rate: Double = 1.0) =
            AudioState(passthrough = true, normalization = normalization, channels = channels, rate = rate)
        assertTrue(state().passesThrough)
        assertTrue(state(channels = AudioChannels.SURROUND_51).passesThrough, "5.1 shapes decoded audio only")
        assertFalse(state(normalization = true).passesThrough, "a filter can't process a bitstream")
        assertFalse(state(channels = AudioChannels.STEREO).passesThrough, "stereo is a promise for everything")
        assertFalse(state(rate = 1.25).passesThrough, "no tempo change of a bitstream")
        assertFalse(AudioState().passesThrough, "the setting off")
    }

    @Test
    fun channelLimitWritesTheFoldBeforeTheLimit() {
        assertEquals(
            listOf("audio-channels" to "auto-safe", "audio-swresample-o" to "", "audio-normalize-downmix" to "no"),
            channelLimitWrites(AudioChannels.ORIGINAL, Downmix(centerBoostDb = 6, normalize = true)),
        )
        assertEquals(
            listOf(
                "audio-swresample-o" to "",
                "audio-normalize-downmix" to "yes",
                "audio-channels" to "auto-safe",
                "audio-channels" to "stereo,5.1",
            ),
            channelLimitWrites(AudioChannels.SURROUND_51, Downmix(centerBoostDb = 6, normalize = true)),
        )
        assertEquals(
            listOf(
                "audio-swresample-o" to "center_mix_level=0.7079",
                "audio-normalize-downmix" to "no",
                "audio-channels" to "auto-safe",
                "audio-channels" to "stereo",
            ),
            channelLimitWrites(AudioChannels.STEREO, Downmix(centerBoostDb = 0, normalize = false)),
        )
    }

    @Test
    fun centerMixLevelIsTheBoostOverMinusThreeDecibels() {
        assertEquals("0.7079", centerMixLevel(0))
        assertEquals("0.8913", centerMixLevel(2))
        assertEquals("1.4125", centerMixLevel(6))
        assertEquals("1.9953", centerMixLevel(9))
        assertEquals("2.8184", centerMixLevel(12))
        assertEquals("2.8184", centerMixLevel(20), "clamped to 12")
        assertEquals("0.7079", centerMixLevel(-4), "clamped to 0")
    }

    @Test
    fun lateDownmixFailureForceRestoresTheAcceptedFilterState() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        audio.reconcile(audio.requestChannels(AudioChannels.STEREO, Downmix(centerBoostDb = 2, normalize = false)))
        mpv.writes.clear()
        var rejectNextStereo = true
        mpv.reject = { name, value -> (rejectNextStereo && name == "audio-channels" && value == "stereo").also { if (it) rejectNextStereo = false } }

        assertFailsWith<IllegalStateException> {
            audio.reconcile(audio.requestChannels(AudioChannels.STEREO, Downmix(centerBoostDb = 9, normalize = true)))
        }

        assertEquals(
            listOf(
                "audio-swresample-o" to "center_mix_level=1.9953",
                "audio-normalize-downmix" to "yes",
                "audio-channels" to "auto-safe",
                "audio-channels" to "stereo",
                "audio-swresample-o" to "center_mix_level=0.8913",
                "audio-normalize-downmix" to "no",
                "audio-channels" to "auto-safe",
                "audio-channels" to "stereo",
                "af" to "",
            ),
            mpv.writes,
        )
        assertEquals("center_mix_level=0.8913", mpv.properties["audio-swresample-o"])
        assertEquals("no", mpv.properties["audio-normalize-downmix"])
        assertEquals("stereo", mpv.properties["audio-channels"])
        assertEquals(Downmix(centerBoostDb = 2, normalize = false), audio.requested.downmix, "the failed request reverts")
    }

    @Test
    fun failedOlderAudioFieldIsNotRevivedByAQueuedDifferentFieldUpdate() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        mpv.reject = { name, value -> name == "af" && value.isNotEmpty() }
        // Both recorded before either applies, as two calls queued on the engine's thread.
        val normalization = audio.requestNormalization(true)
        val rate = audio.requestRate(1.25)

        assertFailsWith<IllegalStateException> { audio.reconcile(normalization) }
        audio.reconcile(rate)

        assertEquals(1, mpv.writes.count { it.first == "af" && it.second.isNotEmpty() })
        assertEquals(listOf("speed" to "1.25"), mpv.of("speed"))
        assertFalse(audio.accepted.normalization)
        assertEquals(1.25, audio.accepted.rate)
    }

    @Test
    fun aNewerRequestForTheFailedFieldIsKept() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        mpv.reject = { name, _ -> name == "speed" }
        val first = audio.requestRate(1.5)
        audio.requestRate(2.0)

        assertFailsWith<IllegalStateException> { audio.reconcile(first) }

        assertEquals(2.0, audio.requested.rate, "the newer request is not rolled back")
    }

    @Test
    fun failedPassthroughWriteDoesNotPublishSpeculativeActiveState() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        mpv.reject = { name, _ -> name == "audio-spdif" }

        assertFailsWith<IllegalStateException> { audio.reconcile(audio.requestPassthrough(true)) }

        assertFalse(audio.passthroughActive)
        assertFalse(audio.requested.passthrough)
    }

    @Test
    fun normalizationTakesPrecedenceOverActivePassthroughAndHandsItBackWhenTurnedOff() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        audio.reconcile(audio.requestPassthrough(true))
        assertTrue(audio.passthroughActive)
        audio.reconcile(audio.requestNormalization(true))
        assertFalse(audio.passthroughActive)
        audio.reconcile(audio.requestNormalization(false))
        assertTrue(audio.passthroughActive)

        assertEquals(
            listOf(
                "audio-spdif" to desktopCodecs,
                "audio-spdif" to "",
                "af" to LOUDNESS_NORMALIZATION_FILTER,
                "af" to "",
                "audio-spdif" to desktopCodecs,
            ),
            mpv.of("af", "audio-spdif"),
        )
    }

    @Test
    fun aSurroundLimitKeepsPassthroughStereoTakesItOverAndOriginalHandsItBack() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        val downmix = Downmix(centerBoostDb = 6, normalize = true)
        audio.reconcile(audio.requestPassthrough(true))
        audio.reconcile(audio.requestChannels(AudioChannels.SURROUND_51, downmix))
        assertTrue(audio.passthroughActive, "the 5.1 limit only shapes decoded PCM")
        audio.reconcile(audio.requestChannels(AudioChannels.STEREO, downmix))
        assertFalse(audio.passthroughActive)
        audio.reconcile(audio.requestChannels(AudioChannels.ORIGINAL, downmix))
        assertTrue(audio.passthroughActive)

        assertEquals(
            listOf(
                "audio-spdif" to desktopCodecs,
                "audio-swresample-o" to "",
                "audio-channels" to "auto-safe",
                "audio-channels" to "stereo,5.1",
                "audio-spdif" to "",
                "audio-swresample-o" to "center_mix_level=1.4125",
                "audio-channels" to "auto-safe",
                "audio-channels" to "stereo",
                "audio-channels" to "auto-safe",
                "audio-swresample-o" to "",
                "audio-spdif" to desktopCodecs,
            ),
            mpv.of("audio-spdif", "audio-channels", "audio-swresample-o"),
        )
    }

    @Test
    fun passthroughRequestedWhileNormalizationIsOnStaysDecoded() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        audio.reconcile(audio.requestNormalization(true))
        audio.reconcile(audio.requestPassthrough(true))

        assertFalse(audio.passthroughActive)
        assertEquals(listOf("af" to LOUDNESS_NORMALIZATION_FILTER), mpv.of("af", "audio-spdif"))
    }

    @Test
    fun failedPassthroughReEntryRestoresNormalization() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        audio.reconcile(audio.requestPassthrough(true))
        audio.reconcile(audio.requestNormalization(true))
        mpv.reject = { name, _ -> name == "audio-spdif" }

        assertFailsWith<IllegalStateException> { audio.reconcile(audio.requestNormalization(false)) }

        assertEquals(
            listOf(LOUDNESS_NORMALIZATION_FILTER, "", LOUDNESS_NORMALIZATION_FILTER),
            mpv.of("af").map { it.second },
        )
        assertFalse(audio.passthroughActive)
        assertTrue(audio.requested.normalization)
    }

    @Test
    fun exclusiveAudioHintFailureDoesNotRejectAcceptedPassthrough() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        mpv.reject = { name, _ -> name == "audio-exclusive" }

        audio.reconcile(audio.requestPassthrough(true))

        assertTrue(audio.passthroughActive)
        assertEquals(listOf("could not set audio-exclusive"), mpv.warnings)
    }

    @Test
    fun desktopPassthroughClaimsTheDeviceAndAppleNever() {
        val desktop = FakeMpv()
        val d = desktop.reconciler()
        d.reconcile(d.requestPassthrough(true))
        d.reconcile(d.requestPassthrough(false))
        assertEquals(
            listOf("audio-spdif" to desktopCodecs, "audio-exclusive" to "yes", "audio-spdif" to "", "audio-exclusive" to "no"),
            desktop.of("audio-spdif", "audio-exclusive"),
        )

        val apple = FakeMpv()
        val a = apple.reconciler(exclusiveHint = false, codecs = "ac3,eac3")
        a.reconcile(a.requestPassthrough(true))
        a.reconcile(a.requestPassthrough(false))
        assertEquals(listOf("audio-spdif" to "ac3,eac3", "audio-spdif" to ""), apple.of("audio-spdif", "audio-exclusive"))
    }

    @Test
    fun failedRateWriteRestoresAcceptedPassthroughState() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        audio.reconcile(audio.requestPassthrough(true))
        mpv.reject = { name, _ -> name == "speed" }

        assertFailsWith<IllegalStateException> { audio.reconcile(audio.requestRate(1.25)) }

        assertTrue(audio.passthroughActive)
        assertEquals(listOf(desktopCodecs, "", desktopCodecs), mpv.of("audio-spdif").map { it.second })
        assertEquals(1.0, audio.requested.rate)
    }

    @Test
    fun anEmptyRouteDecodes() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler(codecs = "")
        audio.reconcile(audio.requestPassthrough(true))
        assertFalse(audio.passthroughActive)
        assertEquals(emptyList(), mpv.of("audio-spdif"))
    }

    @Test
    fun aNewCoreGetsEveryRequestedOption() {
        val mpv = FakeMpv()
        val audio = mpv.reconciler()
        // Requested before the core existed: nothing was applied.
        audio.requestNormalization(true)
        audio.requestChannels(AudioChannels.STEREO, Downmix(centerBoostDb = 0, normalize = true))
        audio.reconcile(audio.requestAll())
        assertEquals(LOUDNESS_NORMALIZATION_FILTER, mpv.properties["af"])
        assertEquals("stereo", mpv.properties["audio-channels"])
        assertEquals("center_mix_level=0.7079", mpv.properties["audio-swresample-o"])
    }
}
