# Applied only to the `minified` variant, which exists to run R8 over the app under test.
#
# The instrumentation runner is loaded through the tested app's class loader, and its
# supertypes resolve from the app APK. Shrinking androidx.test there leaves the harness
# with an AndroidJUnitRunner it cannot link, and the run dies with ClassNotFoundException
# before a single test starts — reported as `tests="0"`, which is easy to mistake for a
# passing gate. No shipped build includes this file.
-keep class androidx.test.** { *; }
-dontwarn androidx.test.**
