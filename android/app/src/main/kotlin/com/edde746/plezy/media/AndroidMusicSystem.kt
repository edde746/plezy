package com.edde746.plezy.media

import android.content.Context
import android.content.pm.PackageManager
import android.view.KeyEvent
import com.edde746.plezy.car.CarRestrictionsMonitor
import com.edde746.plezy.music.KeyPhase
import com.edde746.plezy.music.MusicKey
import com.edde746.plezy.music.MusicSystem

/**
 * Music's OS glue on Android: Android Automotive's car service ([CarRestrictionsMonitor], only on an Automotive
 * device) and the hardware media keys the activity's window receives ([dispatch]): a HID remote's or a keyboard's
 * transport keys reach the window, not the media session, while the app is in front, so the music session's handler
 * takes them there. Main thread.
 */
internal class AndroidMusicSystem(context: Context) : MusicSystem {
    private val context = context.applicationContext
    private var keyHandler: ((MusicKey, KeyPhase) -> Boolean)? = null

    override val car: CarRestrictionsMonitor? =
        if (this.context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)) CarRestrictionsMonitor(this.context) else null

    override fun setHardwareKeyHandler(handler: ((MusicKey, KeyPhase) -> Boolean)?) {
        keyHandler = handler
    }

    /** The activity's key [event] ([com.edde746.plezy.PlezyActivity.dispatchKeyEvent]): true when the handler consumed it. */
    fun dispatch(event: KeyEvent): Boolean {
        val handler = keyHandler ?: return false
        val key = musicKey(event.keyCode) ?: return false
        val phase = keyPhase(event.action, event.repeatCount) ?: return false
        return handler(key, phase)
    }
}

/** The music transport key [keyCode] is, or null for any other key. */
internal fun musicKey(keyCode: Int): MusicKey? = when (keyCode) {
    KeyEvent.KEYCODE_MEDIA_PLAY -> MusicKey.PLAY
    KeyEvent.KEYCODE_MEDIA_PAUSE -> MusicKey.PAUSE
    KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> MusicKey.PLAY_PAUSE
    KeyEvent.KEYCODE_MEDIA_NEXT -> MusicKey.NEXT
    KeyEvent.KEYCODE_MEDIA_PREVIOUS -> MusicKey.PREVIOUS
    KeyEvent.KEYCODE_MEDIA_STOP -> MusicKey.STOP
    KeyEvent.KEYCODE_MEDIA_FAST_FORWARD, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD -> MusicKey.FAST_FORWARD
    KeyEvent.KEYCODE_MEDIA_REWIND, KeyEvent.KEYCODE_MEDIA_SKIP_BACKWARD -> MusicKey.REWIND
    else -> null
}

/** A key event's phase: the first down, a held key's repeats, the release; null for any other action. */
internal fun keyPhase(action: Int, repeatCount: Int): KeyPhase? = when (action) {
    KeyEvent.ACTION_DOWN -> if (repeatCount == 0) KeyPhase.DOWN else KeyPhase.REPEAT
    KeyEvent.ACTION_UP -> KeyPhase.UP
    else -> null
}
