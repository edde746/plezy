package com.edde746.plezy.shared

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.util.Log

class AudioFocusManager(
    context: Context,
    private val handler: Handler,
    private val onPause: () -> Unit,
    private val onResume: () -> Unit,
    private val isPaused: () -> Boolean,
    private val log: (String) -> Unit = { Log.d(TAG, it) }
) {
    companion object {
        private const val TAG = "AudioFocusManager"
    }

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus: Boolean = false
    var wasPlayingBeforeFocusLoss: Boolean = false
        private set

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                log("Focus gained")
                hasAudioFocus = true
                if (wasPlayingBeforeFocusLoss) {
                    onResume()
                    wasPlayingBeforeFocusLoss = false
                }
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                log("Focus lost permanently")
                hasAudioFocus = false
                wasPlayingBeforeFocusLoss = !isPaused()
                onPause()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                log("Focus lost transiently")
                hasAudioFocus = false
                wasPlayingBeforeFocusLoss = !isPaused()
                onPause()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                log("Focus lost transiently (can duck)")
            }
        }
    }

    fun requestAudioFocus(): Boolean {
        Log.d(TAG, "Requesting audio focus")

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                        .build()
                )
                .setOnAudioFocusChangeListener(audioFocusChangeListener, handler)
                .build()

            audioFocusRequest = focusRequest
            audioManager.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }

        hasAudioFocus = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        Log.d(TAG, "Audio focus request result: $result, granted: $hasAudioFocus")
        return hasAudioFocus
    }

    fun abandonAudioFocus() {
        Log.d(TAG, "Abandoning audio focus")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(audioFocusChangeListener)
        }

        hasAudioFocus = false
        wasPlayingBeforeFocusLoss = false
    }

    fun release() {
        abandonAudioFocus()
    }
}
