# Shrinker rules for the instrumentation APK of the `minified` variant.
#
# That variant exists to run R8 over the app under test, not over the harness. AGP
# applies the app's rules to the test APK too, which deletes the instrumentation runner
# and every test class the runner resolves by name — the run then dies with
# ClassNotFoundException before a single test starts. The harness is never shipped, so
# it has nothing to gain from shrinking.
-dontshrink
-dontoptimize
# The runner resolves the instrumentation class and every -e class filter by name.
-dontobfuscate
