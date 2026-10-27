package com.edde746.plezy.exoplayer

/** Requests the existing in-app mpv handoff when a native surface cannot
 * honor an explicit output preference. Never strips Profile 5 metadata. */
internal object DvOutputPolicy {
  fun needsClientConversion(
    profile: Int?,
    isDolbyVisionFormat: Boolean,
    dolbyVisionAllowed: Boolean,
    isHdr: Boolean,
    displaySupportsHdr: Boolean,
    hdrConversionMode: String
  ): Boolean = (!dolbyVisionAllowed && (isDolbyVisionFormat || profile == 5)) ||
    (isHdr && !displaySupportsHdr && hdrConversionMode == "player")
}
