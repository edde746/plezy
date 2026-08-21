package com.edde746.plezy.shared

import android.content.ContentResolver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log

internal data class ResolvedMpvUri(
  val value: String,
  private val ownedFd: Int? = null
) {
  fun closeIfUnused() {
    val fd = ownedFd ?: return
    try {
      ParcelFileDescriptor.adoptFd(fd).close()
    } catch (error: Exception) {
      Log.w("MpvContentUriResolver", "Failed to close unused content FD $fd", error)
    }
  }
}

internal object MpvContentUriResolver {
  private const val TAG = "MpvContentUriResolver"

  fun resolve(
    uriString: String,
    resolver: ContentResolver,
    mainHandler: Handler,
    onResolved: (ResolvedMpvUri) -> Unit
  ) {
    resolve(uriString, mainHandler, opener = {
      val descriptor = resolver.openFileDescriptor(Uri.parse(uriString), "r") ?: return@resolve null
      descriptor.detachFd()
    }, onResolved = onResolved)
  }

  internal fun resolve(
    uriString: String,
    mainHandler: Handler,
    opener: () -> Int?,
    onResolved: (ResolvedMpvUri) -> Unit
  ) {
    if (!uriString.startsWith("content://")) {
      onResolved(ResolvedMpvUri(uriString))
      return
    }

    Thread {
      check(Looper.myLooper() != Looper.getMainLooper()) {
        "Content file descriptors must not be opened on the main thread"
      }
      val fd = try {
        opener()
      } catch (error: Exception) {
        Log.e(TAG, "Failed to open content FD for $uriString", error)
        null
      }
      val resolved = if (fd == null) {
        ResolvedMpvUri(uriString)
      } else {
        Log.d(TAG, "Opened content FD $fd for $uriString")
        ResolvedMpvUri("fdclose://$fd", fd)
      }
      mainHandler.post { onResolved(resolved) }
    }.start()
  }
}
