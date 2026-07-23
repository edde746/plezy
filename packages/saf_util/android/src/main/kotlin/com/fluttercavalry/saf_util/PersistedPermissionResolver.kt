package com.fluttercavalry.saf_util

import android.content.ContentResolver
import android.content.Intent
import android.content.UriPermission
import android.net.Uri
import android.provider.DocumentsContract

/** Resolves document-tree URIs to the exact URI held by Android's permission store. */
internal object PersistedPermissionResolver {
  fun resolve(
    contentResolver: ContentResolver,
    requestedUri: Uri
  ): UriPermission? {
    val permissions = contentResolver.persistedUriPermissions

    permissions.firstOrNull { it.uri == requestedUri }?.let { return it }

    val requestedIdentity = treeIdentity(requestedUri) ?: return null
    return permissions.firstOrNull { permission ->
      treeIdentity(permission.uri) == requestedIdentity
    }
  }

  fun hasPermission(
    contentResolver: ContentResolver,
    requestedUri: Uri,
    checkRead: Boolean,
    checkWrite: Boolean
  ): Boolean {
    val permission = resolve(contentResolver, requestedUri) ?: return false
    return (!checkRead || permission.isReadPermission) &&
      (!checkWrite || permission.isWritePermission)
  }

  fun release(
    contentResolver: ContentResolver,
    requestedUri: Uri,
    read: Boolean,
    write: Boolean
  ) {
    val permission = resolve(contentResolver, requestedUri) ?: return
    var flags = 0
    if (read && permission.isReadPermission) {
      flags = flags or Intent.FLAG_GRANT_READ_URI_PERMISSION
    }
    if (write && permission.isWritePermission) {
      flags = flags or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    }
    if (flags == 0) return

    contentResolver.releasePersistableUriPermission(permission.uri, flags)
  }

  fun resolveUri(
    contentResolver: ContentResolver,
    requestedUri: Uri
  ): Uri? = resolve(contentResolver, requestedUri)?.uri

  fun getPersistedUris(contentResolver: ContentResolver): List<Uri> = contentResolver.persistedUriPermissions.map { it.uri }

  private fun treeIdentity(uri: Uri): TreeIdentity? {
    try {
      if (!DocumentsContract.isTreeUri(uri)) return null
      val scheme = uri.scheme ?: return null
      val authority = uri.authority ?: return null
      val rootDocumentId = DocumentsContract.getTreeDocumentId(uri)
      return TreeIdentity(scheme, authority, rootDocumentId)
    } catch (_: IllegalArgumentException) {
      return null
    }
  }

  private data class TreeIdentity(
    val scheme: String,
    val authority: String,
    val rootDocumentId: String
  )
}
