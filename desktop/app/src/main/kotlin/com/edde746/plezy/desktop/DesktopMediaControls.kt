package com.edde746.plezy.desktop

import com.edde746.plezy.presentation.player.MediaControlsHost

/** The OS media controls on a desktop (SMTC on Windows, MPRIS on Linux), released when the app closes. */
internal interface DesktopMediaControls : MediaControlsHost, AutoCloseable
