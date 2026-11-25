package com.edde746.plezy.mpv

import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * mpv force-passes through every codec its `audio-spdif` names and has no decode fallback, so the list names a codec
 * only when the platform advertises it, the route opens a track the audiotrack output's ladder tries, and for DTS the
 * HDMI sink itself lists DTS.
 */
class MpvSpdifCodecsTest {

    @Test
    fun `spdif list names every codec a route with all shapes can carry`() {
        // The AO opens each burst at its own rate and channel mask, so a route that takes all three shapes and
        // advertises everything bitstreams the lossless codecs too. `dts-hd` supersedes plain `dts`: ad_spdif picks
        // the core burst per file for non-HD tracks.
        assertEquals("ac3,eac3,truehd,dts-hd", spdifCodecs(allEncodings, allShapes))
    }

    @Test
    fun `spdif list on a stereo 48k only route names the core codecs only`() {
        // E-AC3 (192kHz), TrueHD MAT and DTS-HD MA (192kHz/8ch) have no track to ride here.
        assertEquals("ac3,dts", spdifCodecs(allEncodings, setOf(MpvIecShape.STEREO_48K)))
    }

    @Test
    fun `dts hd falls back to the plain core without the carrier shape or a raw track`() {
        // Advertising ENCODING_DTS_HD says the receiver decodes it, not that the route takes the 192kHz/8ch carrier or
        // the raw 48kHz/7.1 track (#1988); naming `dts-hd` anyway strands playback.
        assertEquals(
            "dts",
            spdifCodecs(setOf(AudioFormat.ENCODING_DTS, AudioFormat.ENCODING_DTS_HD), setOf(MpvIecShape.STEREO_48K)),
        )
    }

    @Test
    fun `eac3 is not named without the 192k stereo shape`() {
        assertEquals("", spdifCodecs(setOf(AudioFormat.ENCODING_E_AC3), setOf(MpvIecShape.STEREO_48K)))
    }

    @Test
    fun `truehd is not named without the carrier shape or a raw track`() {
        assertEquals(
            "",
            spdifCodecs(setOf(AudioFormat.ENCODING_DOLBY_TRUEHD), setOf(MpvIecShape.STEREO_48K, MpvIecShape.STEREO_192K)),
        )
    }

    @Test
    fun `plain dts survives when the route does not advertise dts hd`() {
        assertEquals("dts", spdifCodecs(setOf(AudioFormat.ENCODING_DTS), allShapes))
    }

    @Test
    fun `spdif list drops codecs the route cannot bitstream`() {
        // Google TV Streamer over HDMI to a Dolby-only sink: AC3/E-AC3 bitstream, DTS does not (#1703).
        assertEquals("ac3,eac3", spdifCodecs(setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3), allShapes))
    }

    @Test
    fun `spdif list is empty for pcm only routes`() {
        assertEquals("", mpvSpdifCodecs({ false }, { false }))
    }

    @Test
    fun `spdif list is empty when the route takes no track at all`() {
        // Every encoding advertised, but no raw track and no IEC 61937 shape opens (#1991).
        assertEquals("", spdifCodecs(allEncodings, emptySet()))
    }

    @Test
    fun `raw capable route bitstreams the core codecs without any iec shape`() {
        // #2177's Shield: every mpv IEC track opens and drains into silence, while raw AC3/E-AC3/DTS tracks play. The
        // AO opens raw first, so raw support alone qualifies the core codecs.
        assertEquals(
            "ac3,eac3,dts",
            spdifCodecs(
                allEncodings,
                emptySet(),
                raw = setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3, AudioFormat.ENCODING_DTS),
            ),
        )
    }

    @Test
    fun `raw dts hd track qualifies dts hd without the carrier`() {
        // #2333's TCL C8K: no IEC 61937 profile at all, but a native DTS-HD port at 48kHz/7.1 and raw TrueHD. The AO
        // unwraps the burst into that track when the route refuses the carrier; `dts-hd` still supersedes `dts`.
        assertEquals("ac3,eac3,truehd,dts-hd", spdifCodecs(allEncodings, emptySet(), raw = allEncodings))
    }

    @Test
    fun `raw truehd track qualifies truehd without the carrier`() {
        val trueHd = setOf(AudioFormat.ENCODING_DOLBY_TRUEHD)
        assertEquals("truehd", spdifCodecs(trueHd, emptySet(), raw = trueHd))
    }

    @Test
    fun `raw probe is skipped for the carrier first codecs when the carrier qualifies them`() {
        val codecs = mpvSpdifCodecs(
            { true },
            { true },
            { encoding ->
                if (encoding == AudioFormat.ENCODING_DTS_HD || encoding == AudioFormat.ENCODING_DOLBY_TRUEHD) {
                    throw AssertionError("raw track probed for $encoding with the carrier present")
                }
                true
            },
        )
        assertEquals("ac3,eac3,truehd,dts-hd", codecs)
    }

    @Test
    fun `raw tracks are probed in the shape the AO opens`() {
        // DTS-HD MA raw is 48kHz/7.1 and TrueHD raw is Kodi's 192kHz/7.1: any other shape asks about a track the AO
        // never opens.
        assertEquals(AudioFormat.CHANNEL_OUT_7POINT1_SURROUND, mpvRawChannelMask(AudioFormat.ENCODING_DTS_HD))
        assertEquals(AudioFormat.CHANNEL_OUT_7POINT1_SURROUND, mpvRawChannelMask(AudioFormat.ENCODING_DOLBY_TRUEHD))
        assertEquals(AudioFormat.CHANNEL_OUT_STEREO, mpvRawChannelMask(AudioFormat.ENCODING_DTS))
        assertEquals(AudioFormat.CHANNEL_OUT_STEREO, mpvRawChannelMask(AudioFormat.ENCODING_E_AC3))
        assertEquals(192_000, mpvRawSampleRate(AudioFormat.ENCODING_DOLBY_TRUEHD))
        assertEquals(48_000, mpvRawSampleRate(AudioFormat.ENCODING_DTS_HD))
        assertEquals(48_000, mpvRawSampleRate(AudioFormat.ENCODING_AC3))
    }

    @Test
    fun `only raw first codecs open raw without a route oracle`() {
        // Below API 29 the AO cannot ask the route, so it keeps the carrier for TrueHD and DTS-HD.
        assertTrue(mpvRawTrackWithoutOracle(AudioFormat.ENCODING_AC3))
        assertTrue(mpvRawTrackWithoutOracle(AudioFormat.ENCODING_E_AC3))
        assertTrue(mpvRawTrackWithoutOracle(AudioFormat.ENCODING_DTS))
        assertFalse(mpvRawTrackWithoutOracle(AudioFormat.ENCODING_DTS_HD))
        assertFalse(mpvRawTrackWithoutOracle(AudioFormat.ENCODING_DOLBY_TRUEHD))
    }

    @Test
    fun `dts hd still supersedes plain dts when dts bitstreams raw`() {
        assertEquals("ac3,eac3,truehd,dts-hd", spdifCodecs(allEncodings, allShapes, raw = allEncodings))
    }

    @Test
    fun `iec route is never offered below api 24`() {
        assertFalse(iecRouteSupported(23, { true }, { true }, { true }, { true }))
    }

    @Test
    fun `iec route requires a sizable buffer on every tier`() {
        for (sdkInt in intArrayOf(25, 28, 29, 30, 32, 33, 34)) {
            assertFalse(iecRouteSupported(sdkInt, { false }, { true }, { true }, { true }), "api $sdkInt")
        }
    }

    @Test
    fun `route on api 24 to 28 follows the hdmi advertisement`() {
        // Shield Experience 8.x is API 28, and a flat false on this tier decoded TrueHD on routes that carry it (#1991).
        for (supported in booleanArrayOf(true, false)) {
            for (sdkInt in intArrayOf(25, 28)) {
                assertEquals(
                    supported,
                    iecRouteSupported(
                        sdkInt = sdkInt,
                        canSizeBuffer = { true },
                        bitstreamSupported = { throw AssertionError("getDirectPlaybackSupport does not exist below API 33") },
                        directPlaybackSupported = { throw AssertionError("isDirectPlaybackSupported does not exist below API 29") },
                        hdmiRouteAdvertised = { supported },
                    ),
                    "api $sdkInt supported $supported",
                )
            }
        }
    }

    @Test
    fun `route on api 29 to 32 follows the direct playback probe`() {
        // Fire OS 8 (API 30) bitstreams TrueHD over this route; an API 33 gate decoded it (#1863).
        for (supported in booleanArrayOf(true, false)) {
            for (sdkInt in intArrayOf(29, 30, 32)) {
                assertEquals(
                    supported,
                    iecRouteSupported(
                        sdkInt = sdkInt,
                        canSizeBuffer = { true },
                        bitstreamSupported = { throw AssertionError("getDirectPlaybackSupport does not exist below API 33") },
                        directPlaybackSupported = { supported },
                        hdmiRouteAdvertised = { throw AssertionError("the HDMI advertisement must not shadow the runtime probe") },
                    ),
                    "api $sdkInt supported $supported",
                )
            }
        }
    }

    @Test
    fun `route on api 33 uses the bitstream probe`() {
        for (supported in booleanArrayOf(true, false)) {
            assertEquals(
                supported,
                iecRouteSupported(
                    sdkInt = 33,
                    canSizeBuffer = { true },
                    bitstreamSupported = { supported },
                    directPlaybackSupported = { throw AssertionError("API 29 probe must not be consulted on API 33+") },
                    hdmiRouteAdvertised = { throw AssertionError("the HDMI advertisement must not shadow the runtime probe") },
                ),
                "supported $supported",
            )
        }
    }

    @Test
    fun `raw track accepts an offload flagged route where an iec shape does not`() {
        // #2333's TCL C8K declares its only encoded-format port DIRECT|COMPRESS_OFFLOAD, so getDirectPlaybackSupport
        // answers offload-only for the port that bitstreams E-AC3. The IEC shapes keep demanding the bitstream bit (raw
        // TrueHD behind #1804 reported offload-only and never drained).
        val offloadOnly = AudioManager.DIRECT_PLAYBACK_OFFLOAD_GAPLESS_SUPPORTED
        assertTrue(rawTrackDirectModeUsable(offloadOnly))
        assertFalse(iecShapeDirectModeUsable(offloadOnly))

        val bitstream = AudioManager.DIRECT_PLAYBACK_BITSTREAM_SUPPORTED or AudioManager.DIRECT_PLAYBACK_OFFLOAD_SUPPORTED
        assertTrue(rawTrackDirectModeUsable(bitstream))
        assertTrue(iecShapeDirectModeUsable(bitstream))

        assertFalse(rawTrackDirectModeUsable(AudioManager.DIRECT_PLAYBACK_NOT_SUPPORTED))
        assertFalse(iecShapeDirectModeUsable(AudioManager.DIRECT_PLAYBACK_NOT_SUPPORTED))
    }

    @Test
    fun `mi box route with a sink without dts decodes every dts track in mpv`() {
        assertEquals(
            "ac3,eac3,truehd",
            spdifCodecs(
                allEncodings,
                allShapes,
                raw = setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3, AudioFormat.ENCODING_DTS),
                sinkDecodes = noDtsSink,
            ),
        )
    }

    @Test
    fun `a sink without dts gets no dts codec on a raw only route either`() {
        assertEquals("ac3,eac3,truehd", spdifCodecs(allEncodings, emptySet(), raw = allEncodings, sinkDecodes = noDtsSink))
        val dts = setOf(AudioFormat.ENCODING_DTS)
        assertEquals("", spdifCodecs(dts, allShapes, raw = dts, sinkDecodes = noDtsSink))
    }

    @Test
    fun `sink without a dts descriptor does not advertise dts`() {
        val miBoxHdmiSink = intArrayOf(
            AudioFormat.ENCODING_PCM_16BIT,
            AudioFormat.ENCODING_AC3,
            AudioFormat.ENCODING_E_AC3,
            AudioFormat.ENCODING_IEC61937,
            AudioFormat.ENCODING_E_AC3_JOC,
        )

        assertFalse(sinkAdvertisesDts(listOf(miBoxHdmiSink)))
        assertTrue(sinkAdvertisesDts(listOf(miBoxHdmiSink + AudioFormat.ENCODING_DTS)))
        assertTrue(sinkAdvertisesDts(listOf(miBoxHdmiSink, intArrayOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_DTS_HD))))
        val encodingDtsHdMa = 29
        assertTrue(sinkAdvertisesDts(listOf(intArrayOf(AudioFormat.ENCODING_AC3, encodingDtsHdMa))))
    }

    @Test
    fun `sink whose capabilities are unknown leaves dts to the route probes`() {
        assertTrue(sinkAdvertisesDts(emptyList()))
        assertTrue(sinkAdvertisesDts(listOf(intArrayOf())))
        assertTrue(sinkAdvertisesDts(listOf(intArrayOf(AudioFormat.ENCODING_PCM_16BIT, AudioFormat.ENCODING_PCM_FLOAT))))
        assertTrue(sinkAdvertisesDts(listOf(intArrayOf(AudioFormat.ENCODING_PCM_16BIT, AudioFormat.ENCODING_IEC61937))))
        assertTrue(sinkAdvertisesDts(listOf(dolbyOnlyHdmiEncodings, intArrayOf(AudioFormat.ENCODING_PCM_16BIT))))
    }

    @Test
    fun `an active optical or usb output is not judged by an inactive hdmi sink`() {
        for (activeType in listOf(AudioDeviceInfo.TYPE_LINE_DIGITAL, AudioDeviceInfo.TYPE_USB_DEVICE)) {
            val active = AudioOutputRef(activeType, "active")
            val encodings = movieSinkEncodings(listOf(inactiveHdmiWithoutDts, active), activeRoute = listOf(active))

            assertEquals(emptyList<IntArray>(), encodings)
            assertTrue(sinkAdvertisesDts(encodings))
        }
    }

    @Test
    fun `the active hdmi output is the sink that is judged`() {
        val activeHdmiWithDts = AudioOutputRef(
            AudioDeviceInfo.TYPE_HDMI_ARC,
            "arc",
            intArrayOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_DTS),
        )
        val outputs = listOf(inactiveHdmiWithoutDts, activeHdmiWithDts)

        val encodings = movieSinkEncodings(outputs, activeRoute = listOf(AudioOutputRef(AudioDeviceInfo.TYPE_HDMI_ARC, "arc")))

        assertEquals(listOf(activeHdmiWithDts.encodings.toList()), encodings.map { it.toList() })
        assertTrue(sinkAdvertisesDts(encodings))
    }

    @Test
    fun `every hdmi output counts when the active route is unknown or unmatched`() {
        val outputs = listOf(inactiveHdmiWithoutDts)
        val expected = listOf(dolbyOnlyHdmiEncodings.toList())

        assertEquals(expected, movieSinkEncodings(outputs, activeRoute = null).map { it.toList() })
        assertEquals(expected, movieSinkEncodings(outputs, activeRoute = emptyList()).map { it.toList() })
        assertEquals(
            expected,
            movieSinkEncodings(outputs, activeRoute = listOf(AudioOutputRef(AudioDeviceInfo.TYPE_HDMI, "other"))).map { it.toList() },
        )
    }

    @Test
    fun `api 33 tv takes the direct profiles of the route and nothing else`() {
        val profiles = setOf(AudioFormat.ENCODING_PCM_16BIT, AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_DOLBY_TRUEHD)
        assertEquals(profiles, encodings(sdkInt = 33, tv = true, directProfiles = profiles, unconsultedBelowTier = true))
    }

    @Test
    fun `a bluetooth route advertises no bitstream encoding`() {
        assertEquals(
            emptySet<Int>(),
            encodings(sdkInt = 33, bluetooth = true, amazon = true, surroundSetting = true, hdmiPlug = allEncodings.toIntArray()),
        )
        assertEquals(emptySet<Int>(), encodings(sdkInt = 30, tv = true, bluetooth = true, direct = allEncodings))
    }

    @Test
    fun `api 29 to 32 tv asks the direct playback probe per encoding`() {
        val direct = setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_DTS)
        for (sdkInt in intArrayOf(29, 32)) {
            assertEquals(direct, encodings(sdkInt = sdkInt, tv = true, direct = direct, unconsultedBelowTier = true), "api $sdkInt")
        }
    }

    @Test
    fun `api 28 tv reads the hdmi plug broadcast`() {
        // #1991's Shield runs API 28: no direct playback probe there, only the sink the HDMI plug broadcast lists.
        val sink = intArrayOf(AudioFormat.ENCODING_PCM_16BIT, AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_DTS)
        assertEquals(sink.toSet(), encodings(sdkInt = 28, tv = true, direct = allEncodings, hdmiPlug = sink))
        assertEquals(emptySet<Int>(), encodings(sdkInt = 28, tv = true, direct = allEncodings, hdmiPlug = null))
    }

    @Test
    fun `fire tv external surround setting vouches for ac3 and eac3`() {
        val dolby = setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3)
        assertEquals(dolby, encodings(sdkInt = 28, amazon = true, surroundSetting = true))
        assertEquals(emptySet<Int>(), encodings(sdkInt = 28, amazon = true, surroundSetting = false))
        // Other manufacturers' setting counts only when the force flag is on.
        assertEquals(emptySet<Int>(), encodings(sdkInt = 28, surroundSetting = true))
        assertEquals(dolby, encodings(sdkInt = 28, surroundForced = true, surroundSetting = true))
    }

    @Test
    fun `the external surround force flag overrides the hdmi plug broadcast`() {
        val sink = intArrayOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_DTS)
        assertEquals(
            setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3, AudioFormat.ENCODING_DTS),
            encodings(sdkInt = 28, amazon = true, surroundSetting = true, hdmiPlug = sink),
        )
        assertEquals(
            setOf(AudioFormat.ENCODING_AC3, AudioFormat.ENCODING_E_AC3),
            encodings(sdkInt = 28, surroundForced = true, surroundSetting = true, hdmiPlug = sink),
        )
    }

    private fun encodings(
        sdkInt: Int,
        tv: Boolean = false,
        amazon: Boolean = false,
        directProfiles: Set<Int> = emptySet(),
        bluetooth: Boolean = false,
        direct: Set<Int> = emptySet(),
        surroundForced: Boolean = false,
        surroundSetting: Boolean = false,
        hdmiPlug: IntArray? = null,
        unconsultedBelowTier: Boolean = false,
    ): Set<Int> {
        fun <T> below(value: T): T = if (unconsultedBelowTier) throw AssertionError("a lower tier consulted") else value
        return routePassthroughEncodings(
            sdkInt = sdkInt,
            tvOrAutomotive = tv,
            manufacturerSetsExternalSurround = amazon,
            directProfileEncodings = { directProfiles },
            bluetoothRoute = { if (sdkInt >= 33 && tv) throw AssertionError("bluetooth consulted above the profiles") else bluetooth },
            directPlaybackSupported = { it in direct },
            externalSurroundForced = { below(surroundForced) },
            externalSurroundEnabled = { below(surroundSetting) },
            hdmiPlugEncodings = { below(hdmiPlug) },
        )
    }

    private val dolbyOnlyHdmiEncodings = intArrayOf(
        AudioFormat.ENCODING_PCM_16BIT,
        AudioFormat.ENCODING_AC3,
        AudioFormat.ENCODING_E_AC3,
        AudioFormat.ENCODING_IEC61937,
    )

    private val inactiveHdmiWithoutDts = AudioOutputRef(AudioDeviceInfo.TYPE_HDMI, "hdmi", dolbyOnlyHdmiEncodings)

    private val noDtsSink: (Int) -> Boolean = { !isDtsEncoding(it) }

    /** Every encoding the spdif table can ask for, i.e. a receiver that decodes all of them. */
    private val allEncodings = setOf(
        AudioFormat.ENCODING_AC3,
        AudioFormat.ENCODING_E_AC3,
        AudioFormat.ENCODING_DOLBY_TRUEHD,
        AudioFormat.ENCODING_DTS,
        AudioFormat.ENCODING_DTS_HD,
    )

    private val allShapes = MpvIecShape.entries.toSet()

    private fun spdifCodecs(
        encodings: Set<Int>,
        shapes: Set<MpvIecShape>,
        raw: Set<Int> = emptySet(),
        sinkDecodes: (Int) -> Boolean = { true },
    ): String = mpvSpdifCodecs({ it in encodings }, { it in shapes }, { it in raw }, sinkDecodes)
}
