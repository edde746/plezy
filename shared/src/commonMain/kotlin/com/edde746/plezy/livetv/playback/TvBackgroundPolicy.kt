package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.LiveTvBackgroundPolicy

/**
 * Whether a TV app going to the background stops the live session ([LiveTvBackgroundPolicy.STOP_AND_EXIT]: Jellyfin
 * and Emby) and leaves the player on return. A kept session ([LiveTvBackgroundPolicy.RETAIN_SESSION]: Plex) stays
 * paused with its player open, as stopping it would drop its capture buffer and time-shift position.
 */
fun shouldStopLiveSessionForTvBackground(tv: Boolean, policy: LiveTvBackgroundPolicy?): Boolean =
    tv && policy == LiveTvBackgroundPolicy.STOP_AND_EXIT
