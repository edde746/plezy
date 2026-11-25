package com.edde746.plezy.playback.output

/**
 * What this device's screen and decoders take, as the platform detects them (`AppPlatform.videoCapabilities`).
 *
 * @param hdr the screen shows HDR video.
 * @param dolbyVision it shows Dolby Vision.
 * @param hardwareCodecs the video codecs decoded in hardware; empty where the platform can't tell.
 */
data class VideoCapabilities(val hdr: Boolean, val dolbyVision: Boolean, val hardwareCodecs: Set<VideoCodec>)

/** A video codec a device may decode in hardware ([VideoCapabilities.hardwareCodecs]). */
enum class VideoCodec { AVC, HEVC, AV1, VP9 }
