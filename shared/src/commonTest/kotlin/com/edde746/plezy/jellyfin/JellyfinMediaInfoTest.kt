package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaDisplayColorTags
import com.edde746.plezy.model.MediaDisplayColorType
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.model.MediaVideoRange
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

private fun obj(json: String): JsonObject = Json.parseToJsonElement(json).jsonObject
private fun arr(json: String): JsonArray = Json.parseToJsonElement(json).jsonArray
private fun ticks(ms: Long) = ms * 10_000
private fun assertClose(expected: Double, actual: Double?, tolerance: Double = 0.001) =
    assertTrue(actual != null && abs(expected - actual) <= tolerance, "expected $expected, got $actual")

private fun trickplayInfo(width: Int, height: Int, tw: Int, th: Int, count: Int, interval: Int) =
    """{"Width":$width,"Height":$height,"TileWidth":$tw,"TileHeight":$th,"ThumbnailCount":$count,"Interval":$interval,"Bandwidth":0}"""

class JellyfinMediaInfoTest {
    private fun info(source: String, trickplay: String? = null) =
        JellyfinMediaInfo.mediaSourceInfo(obj(source), trickplay = trickplay?.let { Json.parseToJsonElement(it) })

    // Track fields and default-selection hints.

    @Test fun mapsAudioAndSubtitleStreamsWithJellyfinDefaultHints() {
        val info = info(
            """
            {"Id":"src-1","Container":"mkv","MediaStreams":[
              {"Index":0,"Type":"Video","Codec":"h264","RealFrameRate":23.976},
              {"Index":1,"Type":"Audio","Codec":"eac3","Language":"eng","DisplayLanguage":"English","Title":"Surround 5.1",
               "DisplayTitle":"English (EAC3 5.1)","Channels":6,"IsDefault":true},
              {"Index":2,"Type":"Audio","Codec":"aac","Language":"jpn","DisplayLanguage":"Japanese","Channels":2,"IsDefault":false},
              {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayLanguage":"English","IsDefault":false,"IsForced":true,
               "IsExternal":true,"DeliveryUrl":"/Videos/src-1/Subtitles/3/Stream.srt"}
            ]}
            """,
        )
        assertEquals(2, info.audioTracks.size)
        assertEquals(1, info.subtitleTracks.size)
        assertClose(23.976, info.displayCriteria?.fps)
        assertNull(info.partId)

        val eng = info.audioTracks[0]
        assertEquals(1, eng.id)
        assertEquals(1, eng.index)
        assertEquals("eac3", eng.codec)
        assertEquals("English", eng.language)
        assertEquals("eng", eng.languageCode)
        assertEquals("Surround 5.1", eng.title)
        assertEquals("English (EAC3 5.1)", eng.displayTitle)
        assertEquals(6, eng.channels)
        assertTrue(eng.selected)
        assertEquals(2, info.audioTracks[1].id)
        assertFalse(info.audioTracks[1].selected)

        // Forced describes the row; without DefaultSubtitleStreamIndex nothing is server-selected.
        val sub = info.subtitleTracks.single()
        assertEquals(3, sub.id)
        assertEquals("srt", sub.codec)
        assertEquals("eng", sub.languageCode)
        assertTrue(sub.forced)
        assertFalse(sub.selected)
        assertTrue(sub.isExternal)
        assertEquals("/Videos/src-1/Subtitles/3/Stream.srt", sub.key)
    }

    @Test fun noDefaultSubtitleStreamIndexMeansNoServerSelectedSubtitle() {
        // SubtitleMode None: container default/forced flags must not become a selection.
        val info = info(
            """
            {"Id":"src-1","DefaultSubtitleStreamIndex":null,"MediaStreams":[
              {"Index":1,"Type":"Audio","Language":"eng","IsDefault":true},
              {"Index":3,"Type":"Subtitle","Language":"eng","IsDefault":true,"IsForced":true},
              {"Index":4,"Type":"Subtitle","Language":"eng"}
            ]}
            """,
        )
        assertNull(info.defaultSubtitleStreamIndex)
        assertEquals(listOf(false, false), info.subtitleTracks.map { it.selected })
        assertTrue(info.subtitleTracks.first().forced)
        assertTrue(info.audioTracks.single().selected)
    }

    @Test fun usesDefaultStreamIndexesOverPerStreamFlags() {
        val info = info(
            """
            {"Id":"src-1","DefaultAudioStreamIndex":2,"DefaultSubtitleStreamIndex":-1,"MediaStreams":[
              {"Index":0,"Type":"Video"},
              {"Index":1,"Type":"Audio","Language":"eng","IsDefault":true},
              {"Index":2,"Type":"Audio","Language":"jpn","IsDefault":false},
              {"Index":3,"Type":"Subtitle","Language":"eng","IsDefault":true}
            ]}
            """,
        )
        assertEquals(listOf(false, true), info.audioTracks.map { it.selected })
        assertFalse(info.subtitleTracks.single().selected)
        assertEquals(2, info.defaultAudioStreamIndex)
        assertEquals(-1, info.defaultSubtitleStreamIndex)
    }

    @Test fun selectsSubtitleMatchingDefaultStreamIndex() {
        val info = info(
            """
            {"Id":"src-1","DefaultSubtitleStreamIndex":4,"MediaStreams":[
              {"Index":3,"Type":"Subtitle","Language":"eng","IsDefault":true},
              {"Index":4,"Type":"Subtitle","Language":"jpn","IsDefault":false}
            ]}
            """,
        )
        assertEquals(listOf(false, true), info.subtitleTracks.map { it.selected })
        assertEquals(4, info.defaultSubtitleStreamIndex)
    }

    @Test fun coercesStringAndNumericStreamScalars() {
        val info = info(
            """
            {"Id":"src-flexible","DefaultAudioStreamIndex":"2","DefaultSubtitleStreamIndex":3.0,"MediaStreams":[
              {"Index":"2","Type":"Audio","Channels":"6"},
              {"Index":3.0,"Type":"Subtitle"}
            ]}
            """,
        )
        assertEquals(2, info.defaultAudioStreamIndex)
        assertEquals(3, info.defaultSubtitleStreamIndex)
        assertEquals(2, info.audioTracks.single().id)
        assertEquals(6, info.audioTracks.single().channels)
        assertTrue(info.audioTracks.single().selected)
        assertEquals(3, info.subtitleTracks.single().id)
        assertTrue(info.subtitleTracks.single().selected)
    }

    @Test fun fallsBackToLanguageWhenDisplayLanguageAbsent() {
        val audio = info("""{"MediaStreams":[{"Index":0,"Type":"Audio","Language":"fra"}]}""").audioTracks.single()
        assertEquals("fra", audio.language)
        assertEquals("fra", audio.languageCode)
    }

    @Test fun embeddedSubtitleLeavesKeyNull() {
        val sub = info("""{"MediaStreams":[{"Index":0,"Type":"Subtitle","IsExternal":false,"DeliveryUrl":"/should-be-ignored"}]}""").subtitleTracks.single()
        assertNull(sub.key)
        assertFalse(sub.isExternal)
    }

    @Test fun externalDeliveryMarksNegotiatedSubtitlesExternal() {
        val sub = info(
            """{"MediaStreams":[{"Index":2,"Type":"Subtitle","Codec":"srt","DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/2/Stream.srt"}]}""",
        ).subtitleTracks.single()
        assertEquals("/Videos/item-1/src-1/Subtitles/2/Stream.srt", sub.key)
        assertTrue(sub.isExternal)
        assertFalse(sub.isExternalFile)
        assertTrue(sub.usesExternalDelivery)
    }

    @Test fun externalSubtitleWithoutDeliveryUrlStaysExternalForUrlFallback() {
        val sub = info("""{"MediaStreams":[{"Index":3,"Type":"Subtitle","Codec":"srt","IsExternal":true}]}""").subtitleTracks.single()
        assertNull(sub.key)
        assertTrue(sub.isExternal)
        assertTrue(sub.isExternalFile)
        assertFalse(sub.usesExternalDelivery)
    }

    @Test fun preservesExternalAudioStreams() {
        val info = info(
            """
            {"MediaStreams":[
              {"Index":1,"Type":"Audio","Codec":"aac","Language":"eng"},
              {"Index":2,"Type":"Audio","Codec":"flac","Language":"jpn","DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Audio/2/Stream.flac"},
              {"Index":3,"Type":"Audio","Codec":"aac","Language":"spa","IsExternal":true}
            ]}
            """,
        )
        assertEquals(listOf(false, true, true), info.audioTracks.map { it.isExternal })
        assertEquals(2, info.audioTracks[1].id)
        assertEquals("flac", info.audioTracks[1].codec)
        assertEquals(3, info.audioTracks[2].id)
    }

    @Test fun handlesMissingMediaStreams() {
        val info = info("""{"Id":"x"}""")
        assertTrue(info.audioTracks.isEmpty())
        assertTrue(info.subtitleTracks.isEmpty())
        assertNull(info.displayCriteria)
    }

    @Test fun capturesMediaSourceIdFromSourceId() = assertEquals("src-abc", info("""{"Id":"src-abc","MediaStreams":[]}""").mediaSourceId)

    @Test fun derivesVideoAspectRatioFromVideoStreamDimensions() {
        assertClose(16.0 / 9, info("""{"MediaStreams":[{"Index":0,"Type":"Video","Width":1920,"Height":1080}]}""").videoAspectRatio)
        assertNull(info("""{"MediaStreams":[{"Index":0,"Type":"Audio","Codec":"aac"}]}""").videoAspectRatio)
    }

    // Display criteria.

    @Test fun mapsDisplayCriteriaFromVideoStreamMetadata() {
        val criteria = info(
            """
            {"Id":"src-1","MediaStreams":[{"Index":0,"Type":"Video","RealFrameRate":23.976025,"Width":3840,"Height":2160,
              "VideoRangeType":"DOVIWithHDR10Plus","DvProfile":8,"DvLevel":10,"DvBlSignalCompatibilityId":1}]}
            """,
        ).displayCriteria
        assertNotNull(criteria)
        assertClose(23.976, criteria.fps)
        assertEquals(3840, criteria.width)
        assertEquals(2160, criteria.height)
        assertEquals(8, criteria.doviProfile)
        assertEquals(10, criteria.doviLevel)
        assertEquals(1, criteria.doviCompatibilityId)
        assertEquals(MediaDisplayColorTags("smpte2084", "bt2020", "bt2020nc"), MediaDisplayColorTags(criteria.transfer, criteria.primaries, criteria.matrix))
    }

    @Test fun fillsMissingHdrColorTagsFromPartialTransferMetadata() {
        val criteria = info(
            """{"Id":"src-1","MediaStreams":[{"Index":0,"Type":"Video","RealFrameRate":23.976,"Width":3840,"Height":2160,"ColorTransfer":"smpte2084"}]}""",
        ).displayCriteria!!
        assertEquals(MediaDisplayColorTags("smpte2084", "bt2020", "bt2020nc"), MediaDisplayColorTags(criteria.transfer, criteria.primaries, criteria.matrix))
    }

    @Test fun mapsEachColorMetadataClass() {
        val cases = listOf(
            Triple(""""VideoRangeType":"DOVI","DvProfile":5""", MediaDisplayColorType.DOLBY_VISION, MediaDisplayColorTags(null, null, null)),
            Triple(""""VideoRangeType":"HLG"""", MediaDisplayColorType.HLG, MediaDisplayColorTags("arib-std-b67", "bt2020", "bt2020nc")),
            Triple(""""VideoRangeType":"HDR10"""", MediaDisplayColorType.PQ, MediaDisplayColorTags("smpte2084", "bt2020", "bt2020nc")),
            Triple(""""VideoRange":"SDR"""", MediaDisplayColorType.SDR, MediaDisplayColorTags("bt709", "bt709", "bt709")),
            Triple(""""VideoRangeType":"Unknown"""", MediaDisplayColorType.UNKNOWN, MediaDisplayColorTags(null, null, null)),
        )
        for ((stream, type, tags) in cases) {
            val criteria = info("""{"Id":"src-1","Width":1920,"Height":1080,"MediaStreams":[{"Index":0,"Type":"Video","RealFrameRate":24,$stream}]}""").displayCriteria
            assertNotNull(criteria, stream)
            assertEquals(type, criteria.colorType, stream)
            assertEquals(tags, MediaDisplayColorTags(criteria.transfer, criteria.primaries, criteria.matrix), stream)
        }
    }

    // Trickplay manifest.

    @Test fun parsesFlatTrickplayManifest() {
        val t = info(
            """{"Id":"src-1","MediaStreams":[]}""",
            """{"320":{"Width":320,"Height":180,"TileWidth":10,"TileHeight":10,"ThumbnailCount":250,"Interval":10000,"Bandwidth":500000}}""",
        ).trickplayByWidth?.get(320)
        assertNotNull(t)
        assertEquals(listOf(320, 180, 10, 10, 250, 10000, 500000), listOf(t.width, t.height, t.tileWidth, t.tileHeight, t.thumbnailCount, t.interval, t.bandwidth))
    }

    @Test fun parsesNestedBySourceManifestForTheSelectedSource() {
        val info = info(
            """{"Id":"src-2","MediaStreams":[]}""",
            """{"src-1":{"160":${trickplayInfo(160, 90, 8, 8, 64, 10000)}},"src-2":{"320":${trickplayInfo(320, 180, 8, 8, 64, 10000)}}}""",
        )
        assertEquals(listOf(320), info.trickplayByWidth?.keys?.toList())
        assertEquals(320, info.trickplayByWidth!![320]!!.width)
    }

    @Test fun neverAttachesAnotherSourcesTrickplay() {
        val info = info("""{"Id":"unknown","MediaStreams":[]}""", """{"src-1":{"160":${trickplayInfo(160, 90, 4, 4, 16, 10000)}}}""")
        assertEquals("unknown", info.mediaSourceId)
        assertNull(info.trickplayByWidth)
    }

    @Test fun sourcelessMediaAcceptsExactlyOneNestedCandidate() {
        val single = info("""{"MediaStreams":[]}""", """{"src-1":{"160":${trickplayInfo(160, 90, 4, 4, 16, 10000)}}}""")
        assertEquals(160, single.trickplayByWidth?.keys?.single())
        assertEquals(10000, single.trickplayByWidth?.get(160)?.interval)
        val ambiguous = info(
            """{"MediaStreams":[]}""",
            """{"src-1":{"160":${trickplayInfo(160, 90, 4, 4, 16, 10000)}},"src-2":{"320":${trickplayInfo(320, 180, 4, 4, 16, 10000)}}}""",
        )
        assertNull(ambiguous.trickplayByWidth)
    }

    @Test fun missingManifestIsNull() = assertNull(info("""{"Id":"x","MediaStreams":[]}""").trickplayByWidth)

    @Test fun skipsEntriesMissingRequiredInts() {
        val info = info(
            """{"Id":"x","MediaStreams":[]}""",
            """{"320":{"Width":320,"TileWidth":10,"TileHeight":10,"ThumbnailCount":50,"Interval":10000},"160":${trickplayInfo(160, 90, 4, 4, 16, 10000)}}""",
        )
        assertEquals(listOf(160), info.trickplayByWidth?.keys?.toList())
    }

    // Versions.

    @Test fun versionReadsResolutionAndCodecFromVideoStream() {
        val v = JellyfinMediaInfo.sourcesToVersions(
            arr(
                """[{"Id":"src-1","Name":"Movie (2024)","Container":"mkv","Bitrate":5000000,"MediaStreams":[
                  {"Type":"Video","Codec":"hevc","Width":3840,"Height":2160},{"Type":"Audio","Codec":"eac3"}]}]""",
            ),
        ).single()
        assertEquals("src-1", v.id)
        assertEquals("src-1", v.parts.single().streamPath)
        assertEquals("4k", v.videoResolution)
        assertEquals("hevc", v.videoCodec)
        assertEquals("mkv", v.container)
        assertEquals(3840, v.width)
        assertEquals(2160, v.height)
        // A single source's Name is the item title: suppressed.
        assertNull(v.name)
    }

    @Test fun distinctNamesDisambiguateEqualSpecVersions() {
        val versions = JellyfinMediaInfo.sourcesToVersions(
            arr(
                """[
                  {"Id":"src-theatrical","Name":"Theatrical Cut","Container":"mkv","Bitrate":8000000,"MediaStreams":[{"Type":"Video","Codec":"h264","Height":1080,"Width":1920}]},
                  {"Id":"src-directors","Name":"Director's Cut","Container":"mkv","Bitrate":12000000,"MediaStreams":[{"Type":"Video","Codec":"h264","Height":1080,"Width":1920}]}
                ]""",
            ),
        )
        assertEquals(listOf("Theatrical Cut", "Director's Cut"), versions.map { it.name })
        assertEquals(listOf("src-theatrical", "src-directors"), versions.map { it.id })
        assertEquals(listOf("src-theatrical", "src-directors"), versions.map { it.parts.single().streamPath })
        assertTrue("Theatrical Cut" in versions[0].displayLabel)
        assertTrue("1080" in versions[0].displayLabel)
    }

    @Test fun eachVersionCarriesItsOwnLength() {
        val versions = JellyfinMediaInfo.sourcesToVersions(
            arr(
                """[{"Id":"theatrical","Name":"Theatrical Cut","Container":"mkv","RunTimeTicks":${ticks(7_020_000)}},
                   {"Id":"directors","Name":"Director's Cut","Container":"mkv","RunTimeTicks":${ticks(8_160_000)}},
                   {"Id":"unknown","Name":"Workprint","Container":"mkv"}]""",
            ),
        )
        assertEquals(listOf(7_020_000L, 8_160_000L, null), versions.map { it.parts.single().durationMs })
    }

    @Test fun dropsNameWhenAllSourcesShareIt() {
        val versions = JellyfinMediaInfo.sourcesToVersions(
            arr(
                """[{"Id":"a","Name":"Movie (2024)","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"h264","Height":720,"Width":1280}]},
                   {"Id":"b","Name":"Movie (2024)","Container":"mp4","MediaStreams":[{"Type":"Video","Codec":"hevc","Height":1080,"Width":1920}]}]""",
            ),
        )
        assertEquals(listOf(null, null), versions.map { it.name })
        assertEquals(listOf("720", "1080"), versions.map { it.videoResolution })
    }

    @Test fun usesWidthForScopeCroppedLabels() {
        val versions = JellyfinMediaInfo.sourcesToVersions(
            arr(
                """[{"Id":"scope-4k","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"hevc","Height":1608,"Width":3840}]},
                   {"Id":"scope-1080","Container":"mkv","MediaStreams":[{"Type":"Video","Codec":"h264","Height":804,"Width":1920}]}]""",
            ),
        )
        assertEquals(listOf("4k", "1080"), versions.map { it.videoResolution })
    }

    @Test fun coercesSourceScalarsAndRoundsBpsWithoutZeroSentinels() {
        val versions = JellyfinMediaInfo.sourcesToVersions(
            arr(
                """[{"Id":"rounded","Width":"1920","Height":1080.9,"Bitrate":"1500","Size":"987654321","MediaStreams":[{"Type":"Video","Codec":"h264"}]},
                   {"Id":"missing-bitrate"},{"Id":"zero-bitrate","Bitrate":0},{"Id":"negative-bitrate","Bitrate":-1000}]""",
            ),
        )
        assertEquals(1920, versions[0].width)
        assertEquals(1080, versions[0].height)
        assertEquals(2, versions[0].bitrate)
        assertEquals(987654321L, versions[0].parts.single().sizeBytes)
        assertEquals(listOf(null, null, null), versions.drop(1).map { it.bitrate })
    }

    @Test fun versionWithoutStreamsOrHeight() {
        val v = JellyfinMediaInfo.sourcesToVersions(arr("""[{"Id":"x","Name":"X","Container":"mkv"}]""")).single()
        assertNull(v.videoResolution)
        assertNull(v.videoCodec)
        assertNull(v.height)
    }

    // Chapters and markers.

    @Test fun pathEncodesChapterThumbnailItemIdAndTag() {
        val extras = JellyfinMediaInfo.playbackExtras(obj("""{"Chapters":[{"StartPositionTicks":0,"ImageTag":"chapter/tag ?x"}]}"""), "folder/item #1?x")
        assertEquals("/Items/folder%2Fitem%20%231%3Fx/Images/Chapter/0?tag=chapter%2Ftag%20%3Fx", extras.chapters.single().thumb)
    }

    @Test fun backfillsChapterEndsToNextStartAndRuntime() {
        val extras = JellyfinMediaInfo.playbackExtras(
            obj("""{"RunTimeTicks":${ticks(150_000)},"Chapters":[{"Name":"A","StartPositionTicks":0},{"Name":"B","StartPositionTicks":${ticks(60_000)}}]}"""),
            "item-1",
        )
        assertEquals(listOf(0L to 60_000L, 60_000L to 150_000L), extras.chapters.map { it.startTimeOffset to it.endTimeOffset })
        assertNull(extras.chapters[0].thumb)
    }

    @Test fun defaultOpAndEdChapterNamesBecomeSkipMarkers() {
        val extras = JellyfinMediaInfo.playbackExtras(
            obj(
                """{"RunTimeTicks":${ticks(150_000)},"Chapters":[
                  {"Name":"Prologue","StartPositionTicks":${ticks(0)}},{"Name":"OP","StartPositionTicks":${ticks(10_000)}},
                  {"Name":"Part A","StartPositionTicks":${ticks(90_000)}},{"Name":"ED","StartPositionTicks":${ticks(120_000)}}]}""",
            ),
            "item-1",
        )
        assertEquals(listOf("intro", "credits"), extras.markers.map { it.type })
        assertEquals(10_000L to 90_000L, extras.markers[0].startTimeOffset to extras.markers[0].endTimeOffset)
        assertEquals(120_000L to 150_000L, extras.markers[1].startTimeOffset to extras.markers[1].endTimeOffset)
    }

    @Test fun parsesNativeMediaSegmentsIntoSkipMarkers() {
        val markers = JellyfinMediaInfo.segmentMarkers(
            obj(
                """{"Items":[{"Type":"Intro","StartTicks":${ticks(5000)},"EndTicks":${ticks(45_000)}},
                  {"Type":"Outro","StartTicks":${ticks(90_000)},"EndTicks":${ticks(100_000)}},
                  {"Type":"Recap","StartTicks":${ticks(0)},"EndTicks":${ticks(4000)}},
                  {"Type":"Credits","StartTicks":${ticks(110_000)},"EndTicks":${ticks(110_000)}}]}""",
            ),
        )
        assertEquals(listOf("intro", "credits"), markers.map { it.type })
        assertEquals(5000L to 45_000L, markers[0].startTimeOffset to markers[0].endTimeOffset)
        assertEquals(90_000L to 100_000L, markers[1].startTimeOffset to markers[1].endTimeOffset)
    }

    @Test fun keepsNativeSegmentsAndFillsMissingTypesFromChapters() {
        val extras = JellyfinMediaInfo.playbackExtras(
            obj("""{"RunTimeTicks":${ticks(120_000)},"Chapters":[{"Name":"Episode","StartPositionTicks":0},{"Name":"ED","StartPositionTicks":${ticks(90_000)}}]}"""),
            "item-1",
            markers = JellyfinMediaInfo.segmentMarkers(obj("""{"Items":[{"Type":"Intro","StartTicks":${ticks(10_000)},"EndTicks":${ticks(30_000)}}]}""")),
        )
        assertEquals(listOf("intro", "credits"), extras.markers.map { it.type })
        assertEquals(10_000L to 30_000L, extras.markers[0].startTimeOffset to extras.markers[0].endTimeOffset)
        assertEquals(90_000L to 120_000L, extras.markers[1].startTimeOffset to extras.markers[1].endTimeOffset)
    }

    // File info.

    @Test fun fileInfoMapsEverySourceAsOneVersionWithOnePart() {
        val info = JellyfinMediaInfo.fileInfo(
            obj(
                """
                {"MediaSources":[
                  {"Id":"src-1","Name":"Main","Container":"mkv","Bitrate":8000000,"RunTimeTicks":${ticks(6_000_000)},"Path":"/media/movie.mkv",
                   "Size":"10737418240","Protocol":"File","VideoType":"VideoFile","Type":"Default","IsRemote":false,"SupportsDirectPlay":true,
                   "SupportsTranscoding":"true","ETag":"etag-1","DefaultAudioStreamIndex":1,"DefaultSubtitleStreamIndex":-1,
                   "MediaStreams":[
                     {"Index":0,"Type":"Video","Codec":"hevc","Profile":"Main 10","Width":3840,"Height":1608,"AspectRatio":"2.35:1",
                      "RealFrameRate":23.976,"IsInterlaced":false,"VideoRangeType":"DOVIWithHDR10","DvProfile":8,"DvBlSignalCompatibilityId":1,
                      "DvVersionMajor":1},
                     {"Index":1,"Type":"Audio","Codec":"truehd","Profile":"Dolby TrueHD + Dolby Atmos","Channels":8,"BitRate":4000000},
                     {"Index":2,"Type":"Audio","Codec":"aac","Channels":2},
                     {"Index":3,"Type":"Subtitle","Codec":"subrip","Language":"eng","IsExternal":true,"DeliveryUrl":"/sub.srt"},
                     {"Index":4,"Type":"EmbeddedImage","Codec":"mjpeg"}
                   ],
                   "MediaAttachments":[{"Index":5,"FileName":"font.ttf","MimeType":"font/ttf","CodecTag":"ttf"}]},
                  {"Id":"src-2","Container":"mp4"}
                ]}
                """,
            ),
        )
        assertNotNull(info)
        assertEquals(listOf("src-1", "src-2"), info.versions.map { it.id })
        val v = info.versions[0]
        assertEquals("Main", v.title)
        assertEquals(8000, v.bitrateKbps)
        assertEquals(6_000_000, v.durationMs)
        assertEquals(3840 to 1608, v.width to v.height)
        assertClose(2.35, v.aspectRatio)
        assertEquals("hevc", v.videoCodec)
        assertEquals("Main 10", v.videoProfile)
        assertEquals("truehd", v.audioCodec)
        assertEquals(8, v.audioChannels)
        assertEquals("File", v.protocol)
        assertEquals("VideoFile", v.videoType)
        assertEquals("Default", v.sourceType)
        assertEquals(false, v.isRemote)
        assertEquals(true, v.supportsDirectPlay)
        assertEquals(true, v.supportsTranscoding)
        assertNull(v.supportsDirectStream)
        assertEquals("etag-1", v.eTag)
        assertEquals(1, v.defaultAudioStreamIndex)
        assertEquals(-1, v.defaultSubtitleStreamIndex)
        val part = v.parts.single()
        assertEquals("/media/movie.mkv", part.filePath)
        assertEquals(10737418240L, part.fileSize)
        assertEquals(listOf(1, 1, 2, 1, 1), part.streams.map { it.ordinal })
        assertEquals(
            listOf(MediaStreamKind.VIDEO, MediaStreamKind.AUDIO, MediaStreamKind.AUDIO, MediaStreamKind.SUBTITLE, MediaStreamKind.IMAGE),
            part.streams.map { it.kind },
        )
        val video = part.streams[0]
        assertEquals("progressive", video.scanType)
        assertEquals(MediaVideoRange.DOLBY_VISION_HDR10, video.videoRange)
        assertEquals(8, video.dolbyVision?.profile)
        assertEquals("1.0", video.dolbyVision?.version)
        assertEquals(4000, part.streams[1].bitrateKbps)
        assertEquals("/sub.srt", part.streams[3].externalKey)
        assertEquals(true, part.streams[3].isExternal)
        val attachment = v.attachments.single()
        assertEquals("font.ttf", attachment.fileName)
        assertEquals("ttf", attachment.codec)
    }

    @Test fun fileInfoAspectFallsBackToDimensionsAndIsNullWithoutSources() {
        val info = JellyfinMediaInfo.fileInfo(obj("""{"MediaSources":[{"Id":"a","MediaStreams":[{"Type":"Video","Width":1920,"Height":1080}]}]}"""))!!
        assertClose(16.0 / 9, info.versions.single().aspectRatio)
        assertNull(JellyfinMediaInfo.fileInfo(obj("""{"MediaSources":[]}""")))
        assertNull(JellyfinMediaInfo.fileInfo(obj("""{"Id":"x"}""")))
    }
}
