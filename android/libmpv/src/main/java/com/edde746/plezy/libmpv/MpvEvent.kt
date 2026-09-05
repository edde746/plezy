package com.edde746.plezy.libmpv

sealed interface MpvEvent {
  val sourceId: Long?

  data class StartFile(override val sourceId: Long?) : MpvEvent
  data class EndFile(
    val reason: EndFileReason?,
    override val sourceId: Long?
  ) : MpvEvent
  data class FileLoaded(override val sourceId: Long?) : MpvEvent
  data class PlaybackRestart(
    override val sourceId: Long?,
    val positionSeconds: Double?
  ) : MpvEvent

  companion object {
    // Mirrors the ids event.cpp forwards; END_FILE arrives via its own JNI path.
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
