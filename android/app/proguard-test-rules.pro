# The harness build's test APK (testBuildType harness). R8 runs on it because it runs on the app; without these rules
# it strips the instrumentation runner and the tests, which the runner finds by name. The test APK ships nowhere.
-dontshrink
-dontoptimize
-dontobfuscate
# androidx.test's compile-time annotations, absent at runtime.
-dontwarn com.google.errorprone.annotations.**
