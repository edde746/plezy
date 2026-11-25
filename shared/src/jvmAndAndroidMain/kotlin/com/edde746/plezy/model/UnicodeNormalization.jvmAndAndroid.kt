package com.edde746.plezy.model

import java.text.Normalizer

internal actual fun normalizeNfkc(value: String): String = Normalizer.normalize(value, Normalizer.Form.NFKC)
