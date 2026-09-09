package com.edde746.plezy.mpv

import com.edde746.plezy.libmpv.EndFileReason
import com.edde746.plezy.libmpv.LogLevel
import com.edde746.plezy.libmpv.LogMessage
import com.edde746.plezy.libmpv.MpvError
import com.edde746.plezy.libmpv.MpvEvent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MpvEndFileDiagnosticsTest {
  private val diagnostics = MpvEndFileDiagnostics()

  @Test
  fun `an AO failure ends the file with the audio-output cause and the last error line`() {
    diagnostics.onStartFile()
    diagnostics.onLogMessage(LogMessage("cplayer", LogLevel.Error, "Audio output stopped responding; stopping playback."))
    val data = diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Error, 7, MpvError.AoInitFailed))
    assertEquals(
      mapOf(
        "sourceId" to 7L,
        "reason" to EndFileReason.Error.id,
        "message" to "Audio output stopped responding; stopping playback.",
        "cause" to MpvEndFileDiagnostics.CAUSE_AUDIO_OUTPUT_FAILED
      ),
      data
    )
  }

  @Test
  fun `other errors carry no cause so Dart keeps its generic handling`() {
    val data = diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Error, 7, MpvError.LoadingFailed))
    assertNull(data?.get("cause"))
  }

  @Test
  fun `a clean stop never reports a cause even after an earlier error line`() {
    diagnostics.onLogMessage(LogMessage("ao/audiotrack", LogLevel.Error, "AudioTrack.write failed with -32"))
    val data = diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Stop, 7))
    assertEquals(mapOf("sourceId" to 7L, "reason" to EndFileReason.Stop.id), data)
  }
}
