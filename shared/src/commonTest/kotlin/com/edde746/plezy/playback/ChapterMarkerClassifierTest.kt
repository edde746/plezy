package com.edde746.plezy.playback

import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ChapterMarkerClassifierTest {
    @Test
    fun theBundledModelMatchesTheTrainingScriptOnEveryReferenceCase() {
        val classifier = ChapterMarkerClassifier.bundled
        chapterMarkerModelCases.forEachIndexed { i, case ->
            val probabilities = classifier.probabilities(case.spans)
            case.spans.indices.forEach { j ->
                for (k in 0..2) {
                    val expected = case.probabilities[j][k]
                    val actual = probabilities[j][k]
                    assertTrue(abs(expected - actual) <= 1e-9, "case $i chapter $j class $k: $actual, the script's $expected")
                }
            }
            val picks = classifier.pick(case.spans)
            assertEquals(case.intro to case.credits, picks.intro to picks.credits, "case $i")
        }
    }
}
