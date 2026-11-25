package com.edde746.plezy.appicon

import android.content.Context
import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.core.content.res.ResourcesCompat
import androidx.core.graphics.drawable.toBitmap
import com.edde746.plezy.R
import com.edde746.plezy.supporter.AppIconCatalog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * The picker's thumbnails as the launcher draws each icon: the alternates' bundled previews
 * (assets/app_icons/previews/<id>.webp); the default on Android TV as its dark banner plate (default-androidtv.webp),
 * on phones and tablets the launcher icon itself, its plate white or #1A1A1A with the system's night mode.
 */
internal class AppIconPreviews(private val context: Context, private val television: Boolean) {
    private val cache = mutableMapOf<String, ImageBitmap>()

    @Composable
    fun Preview(id: String, modifier: Modifier) {
        val image by produceState(cache[id], id) { value = withContext(Dispatchers.IO) { load(id) } }
        image?.let { Image(it, contentDescription = null, modifier = modifier, contentScale = ContentScale.Crop) }
    }

    private fun load(id: String): ImageBitmap? = synchronized(cache) {
        cache.getOrPut(id) {
            if (id == AppIconCatalog.DEFAULT_ID && !television) {
                val size = (PREVIEW_DP * context.resources.displayMetrics.density).toInt()
                val icon = ResourcesCompat.getDrawable(context.resources, R.mipmap.ic_launcher, context.theme) ?: return null
                return@getOrPut icon.toBitmap(size, size).asImageBitmap()
            }
            val name = if (id == AppIconCatalog.DEFAULT_ID) "default-androidtv" else id
            context.assets.open("app_icons/previews/$name.webp").use { BitmapFactory.decodeStream(it) }?.asImageBitmap() ?: return null
        }
    }

    private companion object {
        const val PREVIEW_DP = 96
    }
}
