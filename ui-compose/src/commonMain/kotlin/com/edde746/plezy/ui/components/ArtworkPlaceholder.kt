package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * What stands in for missing artwork, filling [modifier]'s bounds: the raised surface with [kind]'s icon in the middle,
 * a third of the frame's shorter side, faint; a circle for a person or an artist, the frame's own shape otherwise. No
 * kind's icon is a control's (an episode's is a TV, not a play button), so a placeholder never reads as one.
 */
@Composable
fun ArtworkPlaceholder(kind: PlaceholderKind, modifier: Modifier = Modifier) {
    Box(
        modifier.fillMaxSize().then(if (kind.circular) Modifier.clip(CircleShape) else Modifier).background(PlezyColors.SurfaceHigh),
        contentAlignment = Alignment.Center,
    ) {
        // The icon fits the box's shorter side.
        Icon(kind.vector, contentDescription = null, Modifier.fillMaxSize(1f / 3), tint = PlezyColors.TextFaint)
    }
}

private val PlaceholderKind.vector: ImageVector
    get() = when (this) {
        PlaceholderKind.MOVIE -> PlezyIcons.Movie
        PlaceholderKind.SHOW, PlaceholderKind.EPISODE -> PlezyIcons.Tv
        PlaceholderKind.ALBUM -> PlezyIcons.Album
        PlaceholderKind.TRACK -> PlezyIcons.MusicNote
        PlaceholderKind.ARTIST -> PlezyIcons.Mic
        PlaceholderKind.PERSON -> PlezyIcons.Person
        PlaceholderKind.PLAYLIST -> PlezyIcons.PlaylistPlay
        PlaceholderKind.COLLECTION -> PlezyIcons.VideoLibrary
        PlaceholderKind.CHANNEL -> PlezyIcons.LiveTv
    }
