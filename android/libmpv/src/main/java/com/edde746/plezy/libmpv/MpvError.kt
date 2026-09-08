package com.edde746.plezy.libmpv

/** The `mpv_error` codes an end-file event can carry (client.h). */
enum class MpvError(val code: Int) {
  LoadingFailed(-13),
  AoInitFailed(-14),
  VoInitFailed(-15),
  NothingToPlay(-16),
  UnknownFormat(-17),
  Unsupported(-18),
  NotImplemented(-19),
  Generic(-20);

  companion object {
    /** Null for success (0) and for codes this enum does not model. */
    fun fromCode(code: Int): MpvError? = entries.find { it.code == code }
  }
}
