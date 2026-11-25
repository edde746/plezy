package com.edde746.plezy.model

/** The kind of device the app runs on, as the platform knows it (a phone and a tablet are both [HANDHELD]). */
enum class FormFactor {
    /** Phones and tablets: touch first. */
    HANDHELD,

    /** Windows and Linux windows: keyboard and mouse. */
    DESKTOP,

    /** Android TV and Fire TV: a D-pad remote, viewed from the couch. */
    TV,
}
