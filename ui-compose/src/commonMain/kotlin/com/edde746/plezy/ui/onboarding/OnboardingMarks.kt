package com.edde746.plezy.ui.onboarding

import com.edde746.plezy.presentation.avatarColorOf
import com.edde746.plezy.presentation.initialOf
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.icons.pathNodes
import com.edde746.plezy.ui.image.RemoteImage

/**
 * The marks the sign-in and connection screens draw: each backend's (one colour, tinted with the content around it, as
 * a button's icon), Plezy's own logo in its gradient, and the few Material icons only these screens use.
 */
internal object OnboardingMarks {
    /** Plex's chevron. */
    val Plex: ImageVector by lazy(LazyThreadSafetyMode.NONE) {
        ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 269.72f, viewportHeight = 269.72f)
            .addGroup(translationX = -636.71f, translationY = -89.58f)
            .addPath(pathNodes("M774.47 359.3H677.74L768.67 224.5L677.74 89.58H774.47L865.4 224.5L774.47 359.3Z"), fill = SolidColor(Color.Black))
            .clearGroup()
            .build()
    }

    /** Jellyfin's triangle in a triangle. */
    val Jellyfin: ImageVector by lazy(LazyThreadSafetyMode.NONE) {
        ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 72f, viewportHeight = 72f)
            .addPath(
                pathNodes("M24.2116 49.1581C22.6599 46.0424 32.8378 27.5879 35.9999 27.5879C39.1666 27.5895 49.3228 46.0764 47.7882 49.1581C46.2536 52.2398 25.7632 52.2738 24.2116 49.1581Z"),
                fill = SolidColor(Color.Black),
            )
            .addPath(
                pathNodes(
                    "M0.481861 64.9951C-4.19479 55.6047 26.4765 0 36 0C45.5328 0 76.153 55.713 71.5274 64.9951C66.9018 74.2773 5.15852 74.3856 0.481861 64.9951Z" +
                        "M12.7358 56.847C15.8005 62.9995 56.2536 62.9314 59.2843 56.847C62.3149 50.761 42.2515 14.2605 36.0093 14.2605C29.767 14.2605 9.67118 50.6944 12.7358 56.847Z",
                ),
                fill = SolidColor(Color.Black),
                pathFillType = PathFillType.EvenOdd,
            )
            .build()
    }

    /** Emby's play mark in its rotated square. */
    val Emby: ImageVector by lazy(LazyThreadSafetyMode.NONE) {
        ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 24f, viewportHeight = 24f)
            .addPath(
                pathNodes(
                    "M11.041 0c-.007 0-1.456 1.43-3.219 3.176L4.615 6.352l.512.513.512.512-2.819 2.791L0 12.961l1.83 1.848c1.006 1.016 2.438 2.46 3.182 3.209" +
                        "l1.351 1.359.508-.496c.28-.273.515-.498.524-.498.008 0 1.266 1.264 2.794 2.808L12.97 24l.187-.182c.23-.225 5.007-4.95 5.717-5.656" +
                        "l.52-.516-.502-.513c-.276-.282-.5-.52-.496-.53.003-.009 1.264-1.26 2.802-2.783 1.538-1.522 2.8-2.776 2.803-2.785.005-.012-3.617-3.684" +
                        "-6.107-6.193L17.65 4.6l-.505.505c-.279.278-.517.501-.53.497-.013-.005-1.27-1.267-2.793-2.805A449.655 449.655 0 0011.041 0z" +
                        "M9.223 7.367c.091.038 7.951 4.608 7.957 4.627.003.013-1.781 1.056-3.965 2.32a999.898 999.898 0 01-3.996 2.307" +
                        "c-.019.006-.026-1.266-.026-4.629 0-3.7.007-4.634.03-4.625Z",
                ),
                fill = SolidColor(Color.Black),
                pathFillType = PathFillType.EvenOdd,
            )
            .build()
    }

    /** Plezy's logo: the play triangle with its two waves, in its orange gradient (drawn in its own colours). */
    val Logo: ImageVector by lazy(LazyThreadSafetyMode.NONE) {
        ImageVector.Builder(defaultWidth = 108.dp, defaultHeight = 120.dp, viewportWidth = 358.32f, viewportHeight = 399.86f)
            .addGroup(translationY = -32f)
            .addPath(
                pathNodes(
                    "M335.65,192.66L68.01,38.14C37.78,20.69,0,42.5,0,77.41v309.04c0,34.91,37.78,56.72,68.01,39.27l267.64-154.52c30.23-17.45,30.23-61.08,0-78.54Z" +
                        "M255.53,276.8c-19.1,17.66-38.75,26.49-58.4,26.49s-39.29-8.83-58.39-26.49c-14.39-13.3-28.55-20.05-42.11-20.05s-27.72,6.75-42.1,20.05" +
                        "c-4.87,4.5-12.46,4.2-16.96-.67-4.5-4.86-4.2-12.45.67-16.95,38.2-35.33,78.59-35.33,116.79,0,14.38,13.3,28.55,20.04,42.1,20.04" +
                        "s27.72-6.74,42.11-20.04c4.86-4.5,12.46-4.21,16.95.66,4.5,4.87,4.21,12.46-.66,16.96Z" +
                        "M255.53,204.04c-19.1,17.67-38.75,26.5-58.4,26.5s-39.29-8.83-58.39-26.5c-14.39-13.3-28.55-20.04-42.11-20.04s-27.72,6.74-42.1,20.04" +
                        "c-4.87,4.5-12.46,4.21-16.96-.66s-4.2-12.46.67-16.96c38.2-35.32,78.59-35.32,116.79,0,14.38,13.3,28.55,20.05,42.1,20.05" +
                        "s27.72-6.75,42.11-20.05c4.86-4.5,12.46-4.2,16.95.67,4.5,4.86,4.21,12.45-.66,16.95Z",
                ),
                fill = Brush.linearGradient(
                    0f to Color(0xFFAB543A),
                    1f to Color(0xFFFF7E57),
                    start = Offset(22.67f, 425.72f),
                    end = Offset(201.83f, 115.4f),
                ),
                pathFillType = PathFillType.EvenOdd,
            )
            .clearGroup()
            .build()
    }

    val PersonAdd by icon(
        "M15,12c2.21,0 4,-1.79 4,-4s-1.79,-4 -4,-4 -4,1.79 -4,4 1.79,4 4,4zM6,10V7H4v3H1v2h3v3h2v-3h3v-2H6z" +
            "M15,14c-2.67,0 -8,1.34 -8,4v2h16v-2c0,-2.66 -5.33,-4 -8,-4z",
    )
    val QrCode by icon(
        "M3,11h8V3H3V11zM5,5h4v4H5V5zM3,21h8v-8H3V21zM5,15h4v4H5V15zM13,3v8h8V3H13zM19,9h-4V5h4V9zM19,19h2v2h-2V19z" +
            "M13,13h2v2h-2V13zM15,15h2v2h-2V15zM13,17h2v2h-2V17zM15,19h2v2h-2V19zM17,17h2v2h-2V17zM17,13h2v2h-2V13zM19,15h2v2h-2V15z",
    )

    /** [kind]'s mark. */
    fun backend(kind: BackendKind): ImageVector = when (kind) {
        BackendKind.PLEX -> Plex
        BackendKind.JELLYFIN -> Jellyfin
        BackendKind.EMBY -> Emby
    }

    private fun icon(pathData: String) = lazy(LazyThreadSafetyMode.NONE) {
        ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 24f, viewportHeight = 24f)
            .addPath(pathNodes(pathData), fill = SolidColor(Color.Black))
            .build()
    }
}

/** Plezy's logo, [size] tall. */
@Composable
internal fun PlezyLogo(size: Dp, modifier: Modifier = Modifier) {
    Image(OnboardingMarks.Logo, contentDescription = null, modifier.size(size * (358.32f / 399.86f), size))
}

/**
 * A profile's round avatar, [size] wide: its picture ([url]), else (none, loading or failed) its initial in white on a
 * colour picked from its name; a badge at its lower end: a check on the [current] profile, else a lock when [locked].
 * [imageModifier] applies to the round picture alone (a focus ring), which the badge stays above.
 */
@Composable
internal fun ProfileAvatar(
    name: String,
    url: String?,
    size: Dp,
    locked: Boolean,
    modifier: Modifier = Modifier,
    current: Boolean = false,
    imageModifier: Modifier = Modifier,
) {
    Box(modifier.size(size)) {
        val initial: @Composable () -> Unit = {
            Box(Modifier.size(size).background(avatarColorOf(name)?.let { Color(it) } ?: MaterialTheme.colorScheme.primary, CircleShape), contentAlignment = Alignment.Center) {
                val fontSize = with(LocalDensity.current) { (size * 0.42f).toSp() }
                Text(initialOf(name), color = Color.White, fontSize = fontSize, fontWeight = FontWeight.SemiBold)
            }
        }
        Box(imageModifier.size(size)) {
            RemoteImage(url, contentDescription = null, modifier = Modifier.size(size).clip(CircleShape), fallback = initial)
        }
        val badgeIcon = when {
            current -> PlezyIcons.Check
            locked -> PlezyIcons.Lock
            else -> null
        }
        if (badgeIcon != null) {
            val badge = size * 0.34f
            Box(
                Modifier.align(Alignment.BottomEnd).offset(2.dp, 2.dp).size(badge).background(MaterialTheme.colorScheme.surface, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(badgeIcon, contentDescription = null, Modifier.size(badge * 0.7f), tint = MaterialTheme.colorScheme.onSurface)
            }
        }
    }
}
