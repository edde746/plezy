package com.edde746.plezy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.tv.TvContract.WatchNextPrograms
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * The test builds' answer to "which Watch Next rows does this app have": the TV provider lists an app's rows of
 * Android TV's Watch Next table ([WatchNextPrograms]) to that app and the launchers only, so the shell's `content query`
 * sees none of them. `am broadcast -n com.edde746.plezy.dev/com.edde746.plezy.WatchNextQuery` (the shell holds
 * DUMP, which guards it) answers in the broadcast's result data with a JSON array of this app's rows, each [COLUMNS]
 * as its strings (null where the row has none); "[]" where it has none, or where the device has no TV provider or is
 * older than Android 8, which has no Watch Next table.
 */
class WatchNextQuery : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val rows = JSONArray()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.contentResolver.query(WatchNextPrograms.CONTENT_URI, COLUMNS, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) rows.put(cursor.row())
            }
        }
        resultData = rows.toString()
    }

    private fun Cursor.row(): JSONObject = JSONObject().apply {
        COLUMNS.forEachIndexed { index, column -> put(column, if (isNull(index)) JSONObject.NULL else getString(index)) }
    }

    private companion object {
        val COLUMNS = arrayOf(
            WatchNextPrograms._ID,
            WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
            WatchNextPrograms.COLUMN_TYPE,
            WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE,
            WatchNextPrograms.COLUMN_TITLE,
            WatchNextPrograms.COLUMN_SEASON_DISPLAY_NUMBER,
            WatchNextPrograms.COLUMN_EPISODE_DISPLAY_NUMBER,
            WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS,
            WatchNextPrograms.COLUMN_DURATION_MILLIS,
            WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS,
            WatchNextPrograms.COLUMN_POSTER_ART_URI,
            WatchNextPrograms.COLUMN_POSTER_ART_ASPECT_RATIO,
            WatchNextPrograms.COLUMN_INTENT_URI,
            WatchNextPrograms.COLUMN_BROWSABLE,
        )
    }
}
