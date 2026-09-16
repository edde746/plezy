package com.edde746.plezy.mpv

import com.edde746.plezy.libmpv.EndFileReason
import com.edde746.plezy.libmpv.LogLevel
import com.edde746.plezy.libmpv.LogMessage
import com.edde746.plezy.libmpv.MpvError
import com.edde746.plezy.libmpv.MpvEvent

/** Adds the native diagnostic that libmpv-android exposes separately via logFlow. */
internal class MpvEndFileDiagnostics {
  private var errorMessage: String? = null

  companion object {
    /**
     * The audio device stopped taking audio (or never could) and mpv gave up
     * on it. Keep in sync with PlayerError.audioOutputFailed in Dart: a device
     * fault, so no stream retry or backend switch can recover it.
     */
    const val CAUSE_AUDIO_OUTPUT_FAILED = "audio-output-failed"
  }

  fun onStartFile() {
    errorMessage = null
  }

  fun onLogMessage(message: LogMessage) {
    if (message.level == LogLevel.Fatal || message.level == LogLevel.Error) {
      errorMessage = message.text.takeIf { it.isNotBlank() }
    }
  }

  fun onEndFile(event: MpvEvent.EndFile): Map<String, Any>? {
    val data = mutableMapOf<String, Any>()
    event.sourceId?.let { data["sourceId"] = it }
    event.reason?.let { reason ->
      data["reason"] = reason.id
      if (reason == EndFileReason.Error) {
        event.error?.let { data["error"] = it.code }
        // The latched log line names the actual failure (an ffmpeg/demuxer
        // message); mpv's own error string only classifies it, so it is the
        // fallback for a failure nothing logged at error level.
        (errorMessage ?: event.errorMessage)?.let { data["message"] = it }
        if (event.error == MpvError.AoInitFailed) data["cause"] = CAUSE_AUDIO_OUTPUT_FAILED
      }
    }
    errorMessage = null
    return data.takeIf { it.isNotEmpty() }
  }
}
