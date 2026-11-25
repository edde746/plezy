package com.edde746.plezy.plex.tv

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.log.Log
import com.edde746.plezy.plex.flexInt
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject

/**
 * How a Plex Home user switch ended. [AUTH_REJECTED]: plex.tv answered 401 to the account token, normally because it
 * expired or was revoked; signing in to the account again mints a new one.
 */
enum class PlexHomeSwitchStatus { SUCCESS, CANCELLED, FAILED, AUTH_REJECTED }

/** The outcome of a switch and, on success, the Home user's freshly minted token. */
data class PlexHomeSwitchResult(val status: PlexHomeSwitchStatus, val userToken: String? = null) {
    val succeeded: Boolean get() = status == PlexHomeSwitchStatus.SUCCESS
}

/**
 * Switches into a Home user and returns its token. [switchToUser] is one `/home/users/{uuid}/switch` call with the
 * given PIN (null: none). [promptForPin] asks the user for the PIN, told whether the last one was wrong, and returns
 * null when the user cancels.
 *
 * With [requiresPin] (the user is `protected`) the PIN is asked first; otherwise the switch is tried without one. A 403
 * carrying Plex error 1041 (wrong PIN) asks again, also when no PIN was expected, as plex.tv decides. A 401 is
 * [PlexHomeSwitchStatus.AUTH_REJECTED]; any other failure, a response without a token included, is
 * [PlexHomeSwitchStatus.FAILED].
 */
suspend fun switchPlexHomeUserWithPin(
    requiresPin: Boolean,
    promptForPin: suspend (incorrectPin: Boolean) -> String?,
    switchToUser: suspend (pin: String?) -> String,
    logLabel: String? = null,
): PlexHomeSwitchResult {
    var askPin = requiresPin
    var incorrectPin = false
    while (true) {
        val pin = if (askPin) promptForPin(incorrectPin) ?: return PlexHomeSwitchResult(PlexHomeSwitchStatus.CANCELLED) else null
        try {
            return PlexHomeSwitchResult(PlexHomeSwitchStatus.SUCCESS, switchToUser(pin))
        } catch (e: CancellationException) {
            throw e
        } catch (e: MediaServerHttpException) {
            if (e.statusCode == 403 && isInvalidPin(e)) {
                incorrectPin = true
                askPin = true
                continue
            }
            Log.e(TAG, e) { "Plex Home switch failed${logLabel?.let { " for $it" }.orEmpty()}" }
            val status = if (e.statusCode == 401) PlexHomeSwitchStatus.AUTH_REJECTED else PlexHomeSwitchStatus.FAILED
            return PlexHomeSwitchResult(status)
        } catch (e: Exception) {
            Log.e(TAG, e) { "Plex Home switch failed${logLabel?.let { " for $it" }.orEmpty()}" }
            return PlexHomeSwitchResult(PlexHomeSwitchStatus.FAILED)
        }
    }
}

/** plex.tv's wrong-PIN answer: `errors[0].code` 1041. */
private fun isInvalidPin(e: MediaServerHttpException): Boolean {
    val errors = (e.responseData as? JsonObject)?.get("errors") as? JsonArray
    return (errors?.firstOrNull() as? JsonObject)?.get("code").flexInt() == INVALID_PIN_CODE
}

private const val INVALID_PIN_CODE = 1041
private const val TAG = "PlexHomeSwitch"
