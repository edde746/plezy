package com.edde746.plezy.desktop.linux

import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.mpv.WaylandSession
import com.edde746.plezy.playback.output.DisplayInfo
import com.edde746.plezy.playback.output.OutputPlan
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.playback.output.awaitHdrOutput

/**
 * A playback's output on Linux: the audio passthrough ([MpvPlayerEngine.setAudioPassthrough]), on every output, since
 * nothing here says which formats a device takes undecoded, and whether the video plane may present HDR
 * ([MpvPlayerEngine.setHdrOutput]). Linux switches neither the display's mode nor its HDR state: the compositor shows
 * an HDR plane in HDR where its output is in HDR mode, so the display reads as HDR-capable and HDR-enabled when the
 * compositor can show an HDR plane at all (the plane itself still checks the output), and there is nothing to restore.
 */
internal class LinuxPlaybackOutput(private val engine: MpvPlayerEngine) : PlaybackOutputHost {
    override suspend fun display(): DisplayInfo {
        val hdr = WaylandSession.compositorDescribesHdr
        return DisplayInfo(modes = emptyList(), current = null, hdrSupported = hdr, hdrEnabled = hdr)
    }

    override suspend fun apply(plan: OutputPlan): Boolean {
        engine.setAudioPassthrough(plan.audioPassthrough)
        return engine.awaitHdrOutput(plan.hdrOutput)
    }

    override fun restore() = Unit
}
