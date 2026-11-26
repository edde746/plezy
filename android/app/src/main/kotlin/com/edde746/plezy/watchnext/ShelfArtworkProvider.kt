package com.edde746.plezy.watchnext

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.FileNotFoundException

/**
 * The Watch Next posters ([ShelfArtwork]) to the launchers: exported, readable by any app that may read the TV
 * provider's rows (`READ_EPG_DATA`), as a launcher that isn't the home app has no other way in. Read-only, and only
 * files of the artwork folder by the confined `art/<owner key>/<key>.art` path; everything else is not found. Nothing
 * can be queried, inserted, updated or deleted.
 */
class ShelfArtworkProvider : ContentProvider() {
    private lateinit var artwork: ShelfArtwork

    override fun onCreate(): Boolean {
        artwork = ShelfArtwork(context!!)
        return true
    }

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("Read only")
        val file = artwork.file(uri)?.takeIf { it.isFile } ?: throw FileNotFoundException("No such poster")
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = "image/*"

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
