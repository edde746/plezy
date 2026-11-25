package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine

/**
 * A 4-digit PIN the app is asking for: [title] (the profile's name, or Set PIN / Confirm PIN) and [error] (the last
 * one was wrong). The UIs draw it as a dialog over everything (a hidden field on phones, a keypad on TV and desktop)
 * and answer with [PinPrompter.submit] or [PinPrompter.cancel].
 */
data class PinRequest(val title: String, val error: String?, val id: Int)

/** Asks for PINs one at a time ([request]); a new ask cancels the one shown. Main thread only. */
class PinPrompter {
    private val mutableRequest = MutableStateFlow<PinRequest?>(null)
    private var answer: CompletableDeferred<String?>? = null
    private var next = 0

    val request: StateFlow<PinRequest?> = mutableRequest.asStateFlow()

    /** [profile]'s PIN; [incorrectPin]: the last one was wrong. Null when cancelled. */
    suspend fun ask(profile: Profile, incorrectPin: Boolean): String? =
        ask(profile.displayName, if (incorrectPin) T.profiles.incorrectPinTryAgain else null)

    /** A new PIN, typed twice: null when cancelled or when the two differ ([mismatch] says so). */
    suspend fun askNew(mismatch: () -> Unit): String? {
        val pin = ask(T.profiles.setPinTitle, null) ?: return null
        val again = ask(T.profiles.confirmPinTitle, null) ?: return null
        if (pin != again) {
            mismatch()
            return null
        }
        return pin
    }

    suspend fun ask(title: String, error: String?): String? {
        answer?.complete(null)
        val pending = CompletableDeferred<String?>()
        answer = pending
        mutableRequest.value = PinRequest(title, error, ++next)
        try {
            return pending.await()
        } finally {
            if (answer === pending) {
                answer = null
                mutableRequest.value = null
            }
        }
    }

    /** Answers the request shown with [pin] (4 digits). */
    fun submit(pin: String) {
        answer?.complete(pin)
    }

    fun cancel() {
        answer?.complete(null)
    }
}

/**
 * Whether a screen's "Switching profile…" shows: its own switch is [running], past its PIN ([ProfileServices.switching]),
 * and no PIN is being asked (a bind may ask one), so it never covers the keypad.
 */
fun profileSwitchBusy(running: Flow<Boolean>, profiles: ProfileServices, pins: PinPrompter): Flow<Boolean> =
    combine(running, profiles.switching, pins.request) { running, switching, asked -> running && switching && asked == null }
