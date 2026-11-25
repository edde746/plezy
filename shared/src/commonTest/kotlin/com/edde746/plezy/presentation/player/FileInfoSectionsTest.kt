package com.edde746.plezy.presentation.player

import com.edde746.plezy.jellyfin.JellyfinMediaInfo
import com.edde746.plezy.model.MediaFileAttachment
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaStreamDetails
import com.edde746.plezy.model.MediaStreamKind
import com.edde746.plezy.plex.parsePlexFileInfoFromJson
import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

class FileInfoSectionsTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    @Test
    fun `a plex item shows every version with every file and stream`() {
        val page = FileInfoSections.page(assertNotNull(parsePlexFileInfoFromJson(json(PLEX_MOVIE))), "Example Movie", use24HourClock = true) { 0 }

        assertEquals("Example Movie", page.title)
        assertEquals(listOf("Version 1 of 2", "Version 2 of 2"), page.versions.map { it.heading })
        assertEquals(listOf("4K", "1080p Optimized"), page.versions.map { it.title })

        val uhd = page.versions[0]
        assertEquals(
            listOf(
                "Container" to "MKV", "Duration" to "2h 1m 5s", "Total Size" to "54.3 GB", "Overall Bitrate" to "62.6 Mbps",
                "Resolution" to "3840x2160", "Aspect Ratio" to "1.78", "Video" to "HEVC · main 10", "Frame Rate" to "24p",
                "Audio" to "TRUEHD · ma", "Channels" to "8 ch",
            ),
            assertNotNull(uhd.overview).pairs(),
        )
        assertEquals(
            listOf("Optimized for Streaming" to "No", "64-bit Offsets" to "Yes", "Version ID" to "101"),
            assertNotNull(uhd.delivery).pairs(),
        )
        assertNull(uhd.attachments, "Plex reports no attachments")

        val file = uhd.files.single()
        val fileCard = assertNotNull(file.card)
        assertEquals("File", fileCard.title)
        assertEquals("/media/movies/Example Movie (2026)/Example Movie.mkv", fileCard.path)
        assertEquals(
            listOf(
                "File Present" to "Yes", "Readable by Server" to "Yes", "File Name" to "Example Movie.mkv", "Size" to "54.3 GB",
                "Container" to "MKV", "Duration" to "2h 1m 5s", "Preview Thumbnails" to "Yes", "Preview Index" to "sd",
                "Stream Path" to "/library/parts/201/file.mkv", "File ID" to "201",
            ),
            fileCard.pairs(),
        )
        assertTrue(fileCard.fields.single { it.label == "Stream Path" }.monospace)
        assertFalse(file.noStreams)
        assertEquals(listOf("Video", "Audio 1", "Audio 2", "Subtitles 1", "Subtitles 2"), file.streams.map { it.title })

        val video = file.streams[0]
        assertEquals("4K DoVi/HDR10 (HEVC Main 10)", video.subtitle)
        assertEquals(listOf("Default"), video.chips)
        assertEquals(
            listOf(
                "Codec" to "HEVC", "Profile" to "main 10", "Level" to "153", "Bitrate" to "58.0 Mbps", "Resolution" to "3840x2160",
                "Coded Resolution" to "3840x2176", "Frame Rate" to "23.976 fps", "Dynamic Range" to "Dolby Vision (HDR10)",
                "Bit Depth" to "10 bit", "Color Space" to "bt2020nc", "Color Range" to "tv", "Color Primaries" to "bt2020",
                "Color Transfer" to "smpte2084", "Chroma Subsampling" to "4:2:0", "Chroma Location" to "topleft",
                "Scan Type" to "progressive", "Interlaced" to "No", "Reference Frames" to "1", "Dolby Vision" to "Profile 8.1",
                "Dolby Vision Level" to "6", "Dolby Vision Version" to "1.0", "Dolby Vision Layers" to "BL + RPU",
                "Base Layer Compatibility" to "1", "Codec Tag" to "V_MPEGH/ISO/HEVC", "Stream Index" to "0", "Stream ID" to "301",
            ),
            video.pairs(),
        )

        val (atmos, dub) = file.streams[1] to file.streams[2]
        assertEquals(listOf("Default", "Selected"), atmos.chips)
        assertEquals(
            listOf(
                "Codec" to "TRUEHD", "Profile" to "ma", "Language" to "English", "Language Code" to "eng", "Track Title" to "TrueHD Atmos",
                "Channels" to "7.1 (8 ch)", "Sample Rate" to "48 kHz", "Bit Depth" to "24 bit", "Stream Index" to "1", "Stream ID" to "302",
            ),
            atmos.pairs(),
            "level 0 is no level",
        )
        assertEquals(listOf("Dub"), dub.chips)
        assertEquals("5.1(side) (6 ch)", dub.value("Channels"))

        val (forced, sidecar) = file.streams[3] to file.streams[4]
        assertEquals(listOf("Forced"), forced.chips)
        assertEquals(listOf("External", "Hearing impaired"), sidecar.chips)
        assertEquals("srt", sidecar.value("Sidecar Format"))
        assertEquals("OpenSubtitles", sidecar.value("Provider"))
        assertEquals("92", sidecar.value("Match Score"))
        assertEquals("/library/streams/305", sidecar.value("Sidecar Path"))

        val optimized = page.versions[1]
        assertEquals(listOf("Container" to "MP4"), assertNotNull(optimized.overview).pairs())
        val delivery = assertNotNull(optimized.delivery)
        assertEquals(
            listOf("Optimized Version", "Optimization Target", "Deleted", "Display Offset", "Version ID"),
            delivery.fields.map { it.label },
        )
        assertEquals("Optimized for TV", delivery.value("Optimization Target"))
        assertEquals("0%", delivery.value("Display Offset"))
        // The platform's CLDR data words the date; the clock follows the 24-hour setting.
        val deleted = assertNotNull(delivery.value("Deleted"))
        assertTrue("2026" in deleted && deleted.endsWith("00:00"), deleted)
        val twelveHour = FileInfoSections.page(assertNotNull(parsePlexFileInfoFromJson(json(PLEX_MOVIE))), "", use24HourClock = false) { 0 }
        assertTrue("AM" in assertNotNull(twelveHour.versions[1].delivery?.value("Deleted")))
        assertEquals(listOf("File 1 of 2", "File 2 of 2"), optimized.files.map { it.card?.title })
        assertEquals(listOf("disc-1.mp4", "disc-2.mp4"), optimized.files.map { it.card?.value("File Name") })
        assertTrue(optimized.files.all { it.noStreams && it.streams.isEmpty() })
    }

    @Test
    fun `a jellyfin source shows its delivery attachments and stream detail`() {
        val page = FileInfoSections.page(assertNotNull(JellyfinMediaInfo.fileInfo(json(JELLYFIN_MOVIE))), "Example Movie", use24HourClock = false) { 0 }

        val version = page.versions.single()
        assertNull(version.heading, "one version has no counter")
        assertNull(version.title)
        assertEquals(
            listOf(
                "Protocol" to "File", "Media Type" to "VideoFile", "Source Kind" to "Default", "Direct Play" to "Yes",
                "Direct Stream" to "Yes", "Transcoding" to "No", "Transport Timestamp" to "None", "Remote Source" to "No",
                "Infinite Stream" to "No", "Default Audio Track" to "#1", "Default Subtitle Track" to "Off",
                "Version ID" to "abc123", "ETag" to "e7f1",
            ),
            assertNotNull(version.delivery).pairs(),
        )
        val attachments = assertNotNull(version.attachments)
        assertEquals("2", attachments.subtitle)
        assertEquals(listOf("OpenSans.ttf" to "font/ttf · ttf", "#3" to "application/x-truetype-font"), attachments.pairs())

        val file = version.files.single()
        assertEquals("/media/movies/Example Movie.mkv", file.card?.path)
        assertEquals(listOf("Video", "Audio", "Subtitles", "Embedded Images"), file.streams.map { it.title })

        val video = file.streams[0]
        assertEquals("Dolby Vision (HDR10) + HDR10+", video.value("Dynamic Range"))
        assertEquals("Profile 8.1", video.value("Dolby Vision"))
        assertEquals("BL + RPU", video.value("Dolby Vision Layers"))
        assertEquals("yuv420p10le", video.value("Pixel Format"))
        assertEquals("20.0 Mbps", video.value("Bitrate"))
        assertEquals("No", video.value("AVC Bitstream"))
        assertEquals("1/1000", video.value("Time Base"))
        assertEquals("90°", video.value("Rotation"))

        val audio = file.streams[1]
        assertEquals("Dolby Atmos", audio.value("Spatial Audio"))
        assertEquals("7.1 (8 ch)", audio.value("Channels"))

        val subtitle = file.streams[2]
        assertEquals(listOf("External"), subtitle.chips)
        assertEquals("eng", subtitle.value("Language"))
        assertNull(subtitle.value("Language Code"), "a code echoed as the language shows once")
        assertEquals("Yes", subtitle.value("Text Based"))
        assertEquals("Yes", subtitle.value("Can Be Served Separately"))
        assertEquals("/media/movies/Example Movie.en.srt", subtitle.value("Sidecar File"))
        assertEquals("cover.jpg", file.streams[3].subtitle)
    }

    @Test
    fun `absent fields and empty sections are left out`() {
        val page = FileInfoSections.page(MediaFileInfo(listOf(MediaFileVersion(parts = listOf(MediaFilePart(container = "mkv"))))), "", use24HourClock = true)

        val version = page.versions.single()
        assertNull(version.overview)
        assertNull(version.delivery)
        assertNull(version.attachments)
        val file = version.files.single()
        assertEquals(listOf("Container" to "MKV"), file.card?.pairs())
        assertNull(file.card?.path)
        assertTrue(file.noStreams)
    }

    @Test
    fun `a single stream of its kind is not numbered and a stream without fields has no card`() {
        val part = MediaFilePart(
            streams = listOf(
                MediaStreamDetails(MediaStreamKind.AUDIO, 1, codec = "aac"),
                MediaStreamDetails(MediaStreamKind.DATA, 1),
                MediaStreamDetails(MediaStreamKind.UNKNOWN, 1, codec = "bin_data"),
                MediaStreamDetails(MediaStreamKind.VIDEO, 1, codec = "h264", isDefault = false, isForced = false),
            ),
        )
        val file = FileInfoSections.page(MediaFileInfo(listOf(MediaFileVersion(parts = listOf(part)))), "Clip", use24HourClock = true)
            .versions.single().files.single()

        assertEquals(listOf("Video", "Audio", "Data Streams"), file.streams.map { it.title })
        assertEquals(emptyList(), file.streams[0].chips, "flags that are off show no chip")
        assertNull(file.card, "a file with no fields and no path has no card")
        assertFalse(file.noStreams)
    }

    @Test
    fun `an attachment without a name shows its index`() {
        val version = MediaFileVersion(attachments = listOf(MediaFileAttachment(fileName = "NotoSans.otf", codec = "otf"), MediaFileAttachment()))
        val attachments = assertNotNull(FileInfoSections.page(MediaFileInfo(listOf(version)), "", use24HourClock = true).versions.single().attachments)

        assertEquals(listOf("NotoSans.otf" to "otf", "#0" to ""), attachments.pairs())
    }

    @Test
    fun `the field grid uses two columns when wide and one when narrow and long values take a row`() {
        assertEquals(2, FileInfoGrid.columns(456f))
        assertEquals(1, FileInfoGrid.columns(455f))

        val short = (1..3).map { FileInfoField("L$it", "v") }
        val long = FileInfoField("Path", "x".repeat(43))
        assertTrue(long.fullWidth)
        assertFalse(FileInfoField("Path", "x".repeat(42)).fullWidth)
        assertEquals(listOf(listOf(short[0], short[1]), listOf(short[2]), listOf(long), listOf(short[0])), FileInfoGrid.rows(short + long + short[0], 2))
        assertEquals(listOf(listOf(short[0]), listOf(long), listOf(short[1])), FileInfoGrid.rows(listOf(short[0], long, short[1]), 1))
    }

    private fun FileInfoCard.pairs() = fields.map { it.label to it.value }

    private fun FileInfoCard.value(label: String) = fields.firstOrNull { it.label == label }?.value

    private fun json(text: String) = Json.parseToJsonElement(text).jsonObject

    private companion object {
        const val PLEX_MOVIE = """
{"ratingKey":"1","title":"Example Movie","Media":[
 {"id":101,"title":"4K","container":"mkv","bitrate":62600,"duration":7265000,"width":3840,"height":2160,"aspectRatio":1.78,
  "videoResolution":"4k","videoCodec":"hevc","videoProfile":"main 10","videoFrameRate":"24p","audioCodec":"truehd","audioProfile":"ma",
  "audioChannels":8,"optimizedForStreaming":0,"has64bitOffsets":1,
  "Part":[{"id":201,"key":"/library/parts/201/file.mkv","file":"/media/movies/Example Movie (2026)/Example Movie.mkv","size":58300000000,
   "container":"mkv","duration":7265000,"exists":1,"accessible":1,"hasThumbnail":"1","indexes":"sd",
   "Stream":[
    {"id":301,"streamType":1,"index":0,"codec":"hevc","codecID":"V_MPEGH/ISO/HEVC","profile":"main 10","level":153,"bitrate":58000,
     "width":3840,"height":2160,"codedWidth":3840,"codedHeight":2176,"frameRate":23.976,"scanType":"progressive","bitDepth":10,
     "refFrames":1,"colorSpace":"bt2020nc","colorRange":"tv","colorPrimaries":"bt2020","colorTrc":"smpte2084","chromaSubsampling":"4:2:0",
     "chromaLocation":"topleft","DOVIPresent":true,"DOVIProfile":8,"DOVILevel":6,"DOVIVersion":"1.0","DOVIBLCompatID":1,
     "DOVIBLPresent":true,"DOVIELPresent":false,"DOVIRPUPresent":true,"default":true,"extendedDisplayTitle":"4K DoVi/HDR10 (HEVC Main 10)"},
    {"id":302,"streamType":2,"index":1,"codec":"truehd","profile":"ma","level":0,"channels":8,"audioChannelLayout":"7.1","samplingRate":48000,
     "bitDepth":24,"language":"English","languageCode":"eng","title":"TrueHD Atmos","selected":true,"default":true,
     "extendedDisplayTitle":"TrueHD Atmos 7.1 (English)"},
    {"id":303,"streamType":2,"index":2,"codec":"ac3","channels":6,"audioChannelLayout":"5.1(side)","samplingRate":48000,
     "language":"English","languageCode":"eng","dub":"1","extendedDisplayTitle":"English (AC3 5.1)"},
    {"id":304,"streamType":3,"index":3,"codec":"pgs","language":"English","languageCode":"eng","forced":true,
     "extendedDisplayTitle":"English Forced (PGS)"},
    {"id":305,"streamType":3,"codec":"srt","key":"/library/streams/305","format":"srt","language":"English","languageCode":"eng",
     "hearingImpaired":true,"providerTitle":"OpenSubtitles","score":92,"extendedDisplayTitle":"English SDH (SRT External)"}
   ]}]},
 {"id":102,"title":"1080p Optimized","container":"mp4","proxyType":42,"target":"Optimized for TV","deletedAt":1767225600,"displayOffset":0,
  "Part":[{"file":"/media/optimized/disc-1.mp4","Stream":[]},{"file":"/media/optimized/disc-2.mp4"}]}
]}
"""

        const val JELLYFIN_MOVIE = """
{"Id":"item","Name":"Example Movie","MediaSources":[
 {"Id":"abc123","Name":"Example Movie","Path":"/media/movies/Example Movie.mkv","Protocol":"File","Type":"Default","Container":"mkv",
  "Size":4294967296,"Bitrate":25000000,"RunTimeTicks":36000000000,"VideoType":"VideoFile","IsRemote":false,"IsInfiniteStream":false,
  "SupportsDirectPlay":true,"SupportsDirectStream":true,"SupportsTranscoding":false,"ETag":"e7f1","Timestamp":"None",
  "DefaultAudioStreamIndex":1,"DefaultSubtitleStreamIndex":-1,
  "MediaStreams":[
   {"Type":"Video","Index":0,"Codec":"hevc","Profile":"Main 10","Level":150,"BitRate":20000000,"Width":3840,"Height":2160,
    "AspectRatio":"16:9","RealFrameRate":23.976,"IsInterlaced":false,"BitDepth":10,"PixelFormat":"yuv420p10le","ColorSpace":"bt2020nc",
    "ColorTransfer":"smpte2084","ColorPrimaries":"bt2020","VideoRange":"HDR","VideoRangeType":"DOVIWithHDR10","Hdr10PlusPresentFlag":true,
    "DvProfile":8,"DvLevel":6,"DvVersionMajor":1,"DvVersionMinor":0,"DvBlSignalCompatibilityId":1,"BlPresentFlag":true,
    "ElPresentFlag":false,"RpuPresentFlag":true,"IsAVC":false,"TimeBase":"1/1000","Rotation":90,"IsDefault":true,
    "DisplayTitle":"4K Dolby Vision HEVC"},
   {"Type":"Audio","Index":1,"Codec":"truehd","Language":"eng","DisplayLanguage":"English","Channels":8,"ChannelLayout":"7.1",
    "SampleRate":48000,"AudioSpatialFormat":"DolbyAtmos","IsDefault":true,"DisplayTitle":"English - TrueHD 7.1"},
   {"Type":"Subtitle","Index":2,"Codec":"subrip","Language":"eng","IsExternal":true,"IsTextSubtitleStream":true,
    "SupportsExternalStream":true,"Path":"/media/movies/Example Movie.en.srt","DisplayTitle":"Eng - SUBRIP - External"},
   {"Type":"EmbeddedImage","Index":3,"Codec":"mjpeg","Comment":"Cover (front)","Width":600,"Height":900,"DisplayTitle":"cover.jpg"}
  ],
  "MediaAttachments":[
   {"Index":0,"FileName":"OpenSans.ttf","MimeType":"font/ttf","CodecTag":"ttf"},
   {"Index":3,"MimeType":"application/x-truetype-font"}
  ]}
]}
"""
    }
}
