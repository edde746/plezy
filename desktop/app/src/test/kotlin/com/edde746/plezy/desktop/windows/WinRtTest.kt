package com.edde746.plezy.desktop.windows

import java.util.UUID
import kotlin.test.Test
import kotlin.test.assertEquals

class WinRtTest {
    @Test
    fun parameterizedInterfaceIdsMatchTheWindowsSdk() {
        // IVector<String> (windows.foundation.collections.h).
        assertEquals(
            UUID.fromString("98b9acc1-4b56-532e-ac73-03d5291cca90"),
            WinRt.parameterizedIid("pinterface({913337e9-11a1-4345-a3a2-4e7f956e222d};string)"),
        )
        // TypedEventHandler<SystemMediaTransportControls, SystemMediaTransportControlsButtonPressedEventArgs> (windows.media.h).
        assertEquals(
            UUID.fromString("0557e996-7b23-5bae-aa81-ea0d671143a4"),
            WinRt.parameterizedIid(
                "pinterface({9de1c534-6ae1-11e0-84e1-18a905bcc53f};" +
                    "rc(Windows.Media.SystemMediaTransportControls;{99fa3ff4-1742-42a6-902e-087d41f965ec});" +
                    "rc(Windows.Media.SystemMediaTransportControlsButtonPressedEventArgs;{b7f47116-a56f-4dc8-9e11-92031f4a87c2}))",
            ),
        )
    }
}
