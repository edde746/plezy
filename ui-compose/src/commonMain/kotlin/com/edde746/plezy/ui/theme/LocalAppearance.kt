package com.edde746.plezy.ui.theme

import androidx.compose.runtime.staticCompositionLocalOf
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings

/**
 * What the screens draw with (the running app's appearance: its card and layout settings and effective form factor),
 * provided by the app's frame; the defaults on a desktop where none is (tests).
 */
val LocalAppearance = staticCompositionLocalOf { Appearance.of(AppearanceSettings(), FormFactor.DESKTOP, supporterUnlocked = false) }
