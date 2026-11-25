package com.edde746.plezy.model

/** [value] in Unicode Normalization Form KC (compatibility decomposition, then canonical composition). */
internal expect fun normalizeNfkc(value: String): String
