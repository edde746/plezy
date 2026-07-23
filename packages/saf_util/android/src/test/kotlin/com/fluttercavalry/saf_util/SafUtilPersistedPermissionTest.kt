package com.fluttercavalry.saf_util

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.UriPermission
import android.net.Uri
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
internal class SafUtilPersistedPermissionTest {
  private val context: Context = RuntimeEnvironment.getApplication()

  @Test
  fun pickerReturnedRootAndDescendantResolveToPersistedTreeUri() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val pickerReturnedUri = DocumentFile.fromTreeUri(context, treeUri)!!.uri
    val descendantUri =
      DocumentsContract.buildDocumentUriUsingTree(treeUri, "$ROOT_ID/Season 1/video.mkv")
    val permission = permission(treeUri, read = true, write = true)
    val resolver = resolverWith(permission)

    assertNotEquals(treeUri, pickerReturnedUri)
    assertSame(permission, PersistedPermissionResolver.resolve(resolver, pickerReturnedUri))
    assertSame(permission, PersistedPermissionResolver.resolve(resolver, descendantUri))

    PersistedPermissionResolver.release(
      resolver,
      pickerReturnedUri,
      read = true,
      write = true
    )
    verify(resolver).releasePersistableUriPermission(
      treeUri,
      Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    )
  }

  @Test
  fun providerAuthorityIsPartOfTreeIdentity() {
    val treeA = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val treeB = DocumentsContract.buildTreeDocumentUri(AUTHORITY_B, ROOT_ID)
    val permissionA = permission(treeA, read = true, write = false)
    val permissionB = permission(treeB, read = true, write = false)
    val resolver = resolverWith(permissionB, permissionA)
    val requestedA = DocumentFile.fromTreeUri(context, treeA)!!.uri

    PersistedPermissionResolver.release(resolver, requestedA, read = true, write = false)

    verify(resolver).releasePersistableUriPermission(
      treeA,
      Intent.FLAG_GRANT_READ_URI_PERMISSION
    )
    verify(resolver, never()).releasePersistableUriPermission(
      treeB,
      Intent.FLAG_GRANT_READ_URI_PERMISSION
    )
  }

  @Test
  fun exactUrisResolveWhileUnrelatedMalformedUriDoesNot() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val singleDocumentUri = DocumentsContract.buildDocumentUri(AUTHORITY_A, "single:item")
    val malformedPersistedUri = Uri.parse("content://$AUTHORITY_A/not-a-document/value")
    val treePermission = permission(treeUri, read = true, write = false)
    val singlePermission = permission(singleDocumentUri, read = true, write = false)
    val malformedPermission = permission(malformedPersistedUri, read = true, write = false)
    val resolver = resolverWith(treePermission, singlePermission, malformedPermission)

    assertSame(treePermission, PersistedPermissionResolver.resolve(resolver, treeUri))
    assertSame(
      singlePermission,
      PersistedPermissionResolver.resolve(resolver, singleDocumentUri)
    )
    assertSame(
      malformedPermission,
      PersistedPermissionResolver.resolve(resolver, malformedPersistedUri)
    )
    assertNull(
      PersistedPermissionResolver.resolve(
        resolver,
        Uri.parse("content://$AUTHORITY_A/not-a-document/other")
      )
    )
  }

  @Test
  fun queryAndReleaseIntersectRequestedModesWithHeldModes() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val requested = DocumentFile.fromTreeUri(context, treeUri)!!.uri
    val readOnlyResolver = resolverWith(permission(treeUri, read = true, write = false))

    assertTrue(
      PersistedPermissionResolver.hasPermission(
        readOnlyResolver,
        requested,
        checkRead = true,
        checkWrite = false
      )
    )
    assertFalse(
      PersistedPermissionResolver.hasPermission(
        readOnlyResolver,
        requested,
        checkRead = false,
        checkWrite = true
      )
    )
    assertFalse(
      PersistedPermissionResolver.hasPermission(
        readOnlyResolver,
        requested,
        checkRead = true,
        checkWrite = true
      )
    )
    PersistedPermissionResolver.release(
      readOnlyResolver,
      requested,
      read = true,
      write = true
    )
    verify(readOnlyResolver).releasePersistableUriPermission(
      treeUri,
      Intent.FLAG_GRANT_READ_URI_PERMISSION
    )

    val readWriteResolver = resolverWith(permission(treeUri, read = true, write = true))
    PersistedPermissionResolver.release(
      readWriteResolver,
      requested,
      read = true,
      write = true
    )
    verify(readWriteResolver).releasePersistableUriPermission(
      treeUri,
      Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    )

    val writeOnlyResolver = resolverWith(permission(treeUri, read = false, write = true))
    PersistedPermissionResolver.release(
      writeOnlyResolver,
      requested,
      read = false,
      write = true
    )
    verify(writeOnlyResolver).releasePersistableUriPermission(
      treeUri,
      Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    )
  }

  @Test
  fun noRequestedModesMakesNoPlatformReleaseCall() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val resolver = resolverWith(permission(treeUri, read = true, write = true))

    PersistedPermissionResolver.release(resolver, treeUri, read = false, write = false)

    verify(resolver, never()).releasePersistableUriPermission(any(Uri::class.java), anyInt())
  }

  @Test
  fun repeatedAndMissingReleaseAreIdempotent() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val requested = DocumentFile.fromTreeUri(context, treeUri)!!.uri
    val permission = permission(treeUri, read = true, write = false)
    val resolver = mock(ContentResolver::class.java)
    `when`(resolver.persistedUriPermissions).thenReturn(
      listOf(permission),
      emptyList(),
      emptyList()
    )

    PersistedPermissionResolver.release(resolver, requested, read = true, write = true)
    PersistedPermissionResolver.release(resolver, requested, read = true, write = true)
    PersistedPermissionResolver.release(
      resolver,
      Uri.parse("content://$AUTHORITY_A/not-a-document/missing"),
      read = true,
      write = true
    )

    verify(resolver, times(1)).releasePersistableUriPermission(
      treeUri,
      Intent.FLAG_GRANT_READ_URI_PERMISSION
    )
  }

  @Test
  fun matchedPlatformReleaseErrorPropagates() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val resolver = resolverWith(permission(treeUri, read = true, write = false))
    val failure = SecurityException("platform rejected release")
    doThrow(failure).`when`(resolver).releasePersistableUriPermission(
      treeUri,
      Intent.FLAG_GRANT_READ_URI_PERMISSION
    )

    val thrown =
      assertFailsWith<SecurityException> {
        PersistedPermissionResolver.release(resolver, treeUri, read = true, write = false)
      }

    assertSame(failure, thrown)
  }

  @Test
  fun canonicalLookupAndEnumerationReturnExactPersistedUris() {
    val treeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_A, ROOT_ID)
    val otherTreeUri = DocumentsContract.buildTreeDocumentUri(AUTHORITY_B, "other:root")
    val permission = permission(treeUri, read = true, write = true)
    val otherPermission = permission(otherTreeUri, read = true, write = false)
    val resolver = resolverWith(permission, otherPermission)
    val descendant =
      DocumentsContract.buildDocumentUriUsingTree(treeUri, "$ROOT_ID/child/file")

    assertEquals(treeUri, PersistedPermissionResolver.resolveUri(resolver, descendant))
    assertEquals(
      listOf(treeUri, otherTreeUri),
      PersistedPermissionResolver.getPersistedUris(resolver)
    )
  }

  private fun resolverWith(vararg permissions: UriPermission): ContentResolver = mock(ContentResolver::class.java).also { resolver ->
    `when`(resolver.persistedUriPermissions).thenReturn(permissions.toList())
  }

  private fun permission(
    uri: Uri,
    read: Boolean,
    write: Boolean
  ): UriPermission = mock(UriPermission::class.java).also { permission ->
    `when`(permission.uri).thenReturn(uri)
    `when`(permission.isReadPermission).thenReturn(read)
    `when`(permission.isWritePermission).thenReturn(write)
  }

  private companion object {
    const val AUTHORITY_A = "provider.a.documents"
    const val AUTHORITY_B = "provider.b.documents"
    const val ROOT_ID = "primary:Movies"
  }
}
