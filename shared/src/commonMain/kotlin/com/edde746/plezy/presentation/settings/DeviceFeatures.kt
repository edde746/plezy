package com.edde746.plezy.presentation.settings

/**
 * Which device settings apply here, as the platform detects them (capabilities are reported to shared
 * code): HDR output, refresh-rate switching and passthrough depend on the display, the OS and the audio route, and
 * Discord's Rich Presence is offered where the app speaks to Discord (`AppPlatform.discordPresence`: the desktop and
 * the Mac).
 *
 * @param matchFrameRate the app can switch the display's mode for a video: Android (its MatchFrameRate setting), a
 *   Windows monitor or a Mac display with more than one refresh rate at its resolution (the match refresh rate
 *   setting). Where only the system switches (tvOS, iOS) there is nothing to switch, and no row.
 * @param passthroughTarget what passthrough hands the encoded audio to here, which its hint says.
 */
data class DeviceFeatures(
    val hardwareDecoding: Boolean,
    val hdr: Boolean,
    val matchFrameRate: Boolean,
    val audioPassthrough: Boolean,
    val discordPresence: Boolean = false,
    val passthroughTarget: PassthroughTarget = PassthroughTarget.RECEIVER,
)

/** What audio passthrough sends Dolby and DTS to, undecoded ([DeviceFeatures.passthroughTarget]). */
enum class PassthroughTarget {
    /** A receiver or TV over HDMI or optical, which must decode it (Android, the desktop). */
    RECEIVER,

    /** The system's Dolby decoder (Apple); DTS and TrueHD play as multichannel PCM. */
    SYSTEM_DECODER,

    /** The system's Dolby decoder, and TrueHD Atmos and DTS:X as spatial audio (iOS and tvOS 26 and later). */
    SYSTEM_SPATIAL,
}
