package com.edde746.plezy.libmpv

sealed interface MpvEvent {
  val sourceId: Long?

  data class StartFile(override val sourceId: Long?) : MpvEvent
  data class EndFile(
    val reason: EndFileReason?,
    override val sourceId: Long?,
    /** mpv_error code when [reason] is [EndFileReason.Error]; null otherwise. */
    val error: MpvError? = null,
    /** `mpv_error_string` for that code; null unless [reason] is [EndFileReason.Error]. */
    val errorMessage: String? = null
  ) : MpvEvent
  data class FileLoaded(override val sourceId: Long?) : MpvEvent
  data class PlaybackRestart(
    override val sourceId: Long?,
    val positionSeconds: Double?
  ) : MpvEvent

  /**
   * One mpv log line. It travels in the same ordered stream as the lifecycle
   * events, so a line never reaches a collector after the end-file it
   * explains. mpv attributes log lines to no playlist entry.
   */
  data class LogMessage(
    val prefix: String,
    val level: LogLevel,
    val text: String
  ) : MpvEvent {
    override val sourceId: Long? get() = null
  }

  companion object {
    // Mirrors the ids event.cpp forwards; END_FILE and LOG_MESSAGE arrive via their own JNI paths.
    internal fun fromId(
      id: Int,
      sourceId: Long?,
      positionSeconds: Double?
    ): MpvEvent? = when (id) {
      6 -> StartFile(sourceId)
      8 -> FileLoaded(sourceId)
      21 -> PlaybackRestart(sourceId, positionSeconds)
      else -> null
    }
  }
}
