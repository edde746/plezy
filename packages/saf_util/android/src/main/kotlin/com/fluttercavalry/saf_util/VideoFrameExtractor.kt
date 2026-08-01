package com.fluttercavalry.saf_util

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC
import android.net.Uri
import android.os.Build

internal fun extractVideoFrame(
  context: Context,
  uri: Uri,
  width: Int,
  height: Int,
  retriever: MediaMetadataRetriever = MediaMetadataRetriever()
): Bitmap? = try {
  retriever.setDataSource(context, uri)
  if (Build.VERSION.SDK_INT >= 27) {
    retriever.getScaledFrameAtTime(-1, OPTION_CLOSEST_SYNC, width, height)
  } else {
    retriever.frameAtTime
  }
} finally {
  retriever.release()
}
