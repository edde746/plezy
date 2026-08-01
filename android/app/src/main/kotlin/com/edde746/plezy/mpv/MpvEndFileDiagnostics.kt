package com.edde746.plezy.mpv

import dev.jdtech.mpv.EndFileReason
import dev.jdtech.mpv.LogLevel
import dev.jdtech.mpv.LogMessage
import dev.jdtech.mpv.MpvEvent

/** Adds the native diagnostic that libmpv-android exposes separately via logFlow. */
internal class MpvEndFileDiagnostics {
  private var errorMessage: String? = null

  fun onStartFile() {
    errorMessage = null
  }

  fun onLogMessage(message: LogMessage) {
    if (message.level == LogLevel.Fatal || message.level == LogLevel.Error) {
      errorMessage = message.text.takeIf { it.isNotBlank() }
    }
  }

  fun onEndFile(event: MpvEvent.EndFile): Map<String, Any>? {
    val reason = event.reason
    if (reason == null) {
      errorMessage = null
      return null
    }
    val data = mutableMapOf<String, Any>("reason" to reason.id)
    if (reason == EndFileReason.Error) {
      errorMessage?.let { data["message"] = it }
    }
    errorMessage = null
    return data
  }
}
