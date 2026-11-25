package com.edde746.plezy.plex

import java.text.Normalizer

internal actual fun canonicalDecomposition(value: String): String = Normalizer.normalize(value, Normalizer.Form.NFD)
