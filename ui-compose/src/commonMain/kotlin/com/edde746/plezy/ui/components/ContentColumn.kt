package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.edde746.plezy.ui.theme.LocalPlezyDimens

/**
 * A narrow screen's column (a list, a form, a page of text): as wide as the space it is given up to the dimens'
 * `contentMaxWidth`, and centred in that space (the window beside the navigation, or Settings' pane beside its
 * sections). A pushed screen's [ScreenHeader] takes it too, so its back button and title line up with the column under
 * them. Modifiers after it (a layout probe, a background) get the column; before it, the whole width. Full-width
 * screens (Home's shelves, the Discover and Library grids, Detail, the player) don't use it.
 */
@Composable
fun Modifier.contentColumn(): Modifier =
    fillMaxWidth().wrapContentWidth(Alignment.CenterHorizontally).widthIn(max = LocalPlezyDimens.current.contentMaxWidth).fillMaxWidth()
