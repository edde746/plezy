package com.edde746.plezy.mpv

import com.edde746.plezy.libmpv.EndFileReason
import com.edde746.plezy.libmpv.LogLevel
import com.edde746.plezy.libmpv.LogMessage
import com.edde746.plezy.libmpv.MpvEvent

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
    val data = mutableMapOf<String, Any>()
    event.sourceId?.let { data["sourceId"] = it }
    event.reason?.let { reason ->
      data["reason"] = reason.id
      if (reason == EndFileReason.Error) {
        errorMessage?.let { data["message"] = it }
      }
    }
    errorMessage = null
    return data.takeIf { it.isNotEmpty() }
  }
}
