# Third-Party Software Notices and Information

The Sentry Java SDK distribution includes software developed by third parties which carry their own copyright notices and license terms. These notices are provided below.

In the event that a required notice is missing or incorrect, please inform us by creating an issue [here](https://github.com/getsentry/sentry-java/issues).

---

## Google GSON (Apache 2.0)

**Source:** https://github.com/google/gson (Tag: gson-parent-2.8.7)<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2010 Google Inc.

### Scope

The Sentry Java SDK includes vendored JSON stream reading and writing classes extracted from the GSON library. The code resides in the `io.sentry.vendor.gson.stream` package and includes `JsonReader`, `JsonWriter`, `JsonScope`, `JsonToken`, and `MalformedJsonException`.

```
Copyright (C) 2010 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Google Guava — LongMath (Apache 2.0)

**Source:** https://github.com/google/guava/blob/v33.0.0/guava/src/com/google/common/math/LongMath.java<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2011 The Guava Authors

### Scope

The Sentry Java SDK includes adapted floor division logic from Guava's `LongMath` class to support older Android API levels. The code resides in `io.sentry.vendor.SentryMath`.

```
Copyright (C) 2011 The Guava Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## FasterXML Jackson — ISO8601Utils (Apache 2.0)

**Source:** https://github.com/FasterXML/jackson-databind<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2007-, Tatu Saloranta

### Scope

The Sentry Java SDK includes an adapted version of `ISO8601Utils` from the Jackson Databind library for ISO 8601 date/time parsing and formatting. The code resides in `io.sentry.vendor.gson.internal.bind.util.ISO8601Utils`.

```
Copyright (C) 2007-, Tatu Saloranta

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Howard Hinnant — Date Algorithms (Public Domain)

**Source:** https://howardhinnant.github.io/date_algorithms.html<br>
**License:** Public Domain<br>
**Copyright:** None; public domain dedication by Howard Hinnant

### Scope

The Sentry Java SDK includes adapted civil date conversion algorithms from Howard Hinnant's date algorithms for UTC ISO 8601 timestamp parsing and formatting. The code resides in `io.sentry.vendor.SentryIso8601Utils`.

```
Consider these donated to the public domain.
```

---

## Android Open Source Project — Base64 (Apache 2.0)

**Source:** https://cs.android.com/android/platform/superproject/main/+/main:frameworks/base/core/java/android/util/Base64.java<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2010 The Android Open Source Project

### Scope

The Sentry Java SDK includes an adapted version of the Android `Base64` class for Base64 encoding and decoding on non-Android platforms. The code resides in `io.sentry.vendor.Base64`.

```
Copyright (C) 2010 The Android Open Source Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Square — Tape (Apache 2.0)

**Source:** https://github.com/square/tape (Commit: 445cd3fd0a7b3ec48c9ea3e0e86663fe6d3735d8, archived 2024-10-25)<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2010 Square, Inc.

### Scope

The Sentry Java SDK includes an adapted version of Square's Tape library, a file-based FIFO queue implementation used for reliable event storage. The code resides in the `io.sentry.cache.tape` package and includes `QueueFile`, `FileObjectQueue`, and `ObjectQueue`.

Upstream was archived on 2024-10-25 and is no longer maintained. This copy is maintained in-tree and has diverged from the linked commit: it recovers from file corruption by recreating the file, bounds the queue to a maximum number of elements, and supports optional buffered writes flushed by an explicit `sync()`.

```
Copyright (C) 2010 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Square — Seismic (Apache 2.0)

**Source:** https://github.com/square/seismic<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright 2010 Square, Inc.

### Scope

The Sentry Java SDK includes an adapted version of Square's Seismic shake detection algorithm. The rolling sample window approach and `SampleQueue`/`SamplePool` data structures in `io.sentry.android.core.SentryShakeDetector` are based on Seismic's `ShakeDetector`.

```
Copyright 2010 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Square — Curtains (Apache 2.0)

**Source:** https://github.com/square/curtains (v1.2.5)<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright 2021 Square Inc.

### Scope

The Sentry Java SDK includes adapted versions of Square's Curtains library for null-safe `Window.Callback` handling and for tracking attached window roots. The code resides in `io.sentry.android.replay.util.FixedWindowCallback` and `io.sentry.android.replay.Windows`.

```
Copyright 2021 Square Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Apache Commons Collections (Apache 2.0)

**Source:** https://github.com/apache/commons-collections<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright The Apache Software Foundation

### Scope

The Sentry Java SDK includes adapted versions of `CircularFifoQueue`, `SynchronizedCollection`, and `SynchronizedQueue` from Apache Commons Collections. The code resides in `io.sentry.CircularFifoQueue`, `io.sentry.SynchronizedCollection`, and `io.sentry.SynchronizedQueue`.

```
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Matej Tymes — JavaFixes (Apache 2.0)

**Source:** https://github.com/MatejTymes/JavaFixes (Commit: 37e74b9d0a29f7a47485c6d1bb1307f01fb93634)<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2016 Matej Tymes

### Scope

The Sentry Java SDK includes an adapted version of `ReusableCountLatch` from the JavaFixes library for concurrent synchronization. The code resides in `io.sentry.transport.ReusableCountLatch`.

```
Copyright (C) 2016 Matej Tymes

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Baomidou — Dynamic-Datasource (Apache 2.0)

**Source:** https://github.com/baomidou/dynamic-datasource<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright © 2018 organization baomidou

### Scope

The Sentry Java SDK includes an adapted UUID generation implementation from the Dynamic-Datasource library. The code resides in `io.sentry.util.UUIDGenerator`.

```
Copyright © 2018 organization baomidou

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Google Firebase — Android SDK (Apache 2.0)

**Source:** https://github.com/firebase/firebase-android-sdk<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright 2022 Google LLC

### Scope

The Sentry Java SDK includes an adapted version of `FirstDrawDoneListener` from the Firebase Android SDK for detecting initial display time via `OnDrawListener`. The code resides in `io.sentry.android.core.internal.util.FirstDrawDoneListener`.

```
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Android Open Source Project — Thread Dump Parsing (Apache 2.0)

**Source:** https://cs.android.com/android/platform/superproject/+/master:development/tools/bugreport/src/com/android/bugreport/stacks/ThreadSnapshotParser.java<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2016 The Android Open Source Project

### Scope

The Sentry Java SDK includes adapted thread state and stack trace parsing code from the Android Open Source Project's bugreport tools. The code resides in the `io.sentry.android.core.internal.threaddump` package and includes `ThreadDumpParser`, `Line`, and `Lines`.

```
Copyright (C) 2016 The Android Open Source Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## Android Open Source Project — Jetpack Compose UI (Apache 2.0)

**Source:** https://github.com/androidx/androidx/blob/fc7df0dd68466ac3bb16b1c79b7a73dd0bfdd4c1/compose/ui/ui/src/commonMain/kotlin/androidx/compose/ui/layout/LayoutCoordinates.kt#L187<br>
**Source:** https://github.com/androidx/androidx/blob/androidx-main/compose/ui/ui-util/src/commonMain/kotlin/androidx/compose/ui/util/MathHelpers.kt<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright (C) 2019, 2020 The Android Open Source Project

### Scope

The Sentry Android Replay SDK includes code adapted from Jetpack Compose UI, used to compute Compose node bounds while traversing the view hierarchy for masking. The code resides in `io.sentry.android.replay.util.Nodes`: the `boundsInWindow` extension function (a faster copy of `LayoutCoordinates.boundsInWindow`) and the `fastMinOf`, `fastMaxOf`, `fastCoerceIn`, `fastCoerceAtLeast`, and `fastCoerceAtMost` numeric helpers (copied from `androidx.compose.ui.util.MathHelpers`).

```
Copyright (C) 2019, 2020 The Android Open Source Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## OpenTelemetry (Apache 2.0)

**Source:** https://github.com/open-telemetry/opentelemetry-java (Commit: 0aacc55d1e3f5cc6dbb4f8fa26bcb657b01a7bc9)<br>
**License:** Apache License 2.0<br>
**Copyright:** Copyright The OpenTelemetry Authors

### Scope

The Sentry Java SDK includes an adapted version of `ThreadLocalContextStorage` from the OpenTelemetry Java SDK for thread-local context storage. The code resides in `io.sentry.opentelemetry.SentryOtelThreadLocalStorage`.

```
Copyright The OpenTelemetry Authors
SPDX-License-Identifier: Apache-2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## SalomonBrys — ANR-WatchDog (MIT)

**Source:** https://github.com/SalomonBrys/ANR-WatchDog (Commit: 1969075f75f5980e9000eaffbaa13b0daf282dcb)<br>
**License:** MIT License<br>
**Copyright:** Copyright (c) 2016 Salomon BRYS

### Scope

The Sentry Java SDK includes an adapted version of the ANR-WatchDog library for Application Not Responding (ANR) detection on Android. The code resides in `io.sentry.android.core.ANRWatchDog`.

```
MIT License

Copyright (c) 2016 Salomon BRYS

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

---

## Breadwallet — Root Detection (MIT)

**Source:** https://github.com/Menwitz/ravencoin-android (adapted from breadwallet)<br>
**License:** MIT License<br>
**Copyright:** Copyright (c) 2016 breadwallet LLC

### Scope

The Sentry Java SDK includes an adapted root detection implementation from the Ravencoin Android wallet (originally from breadwallet). The code resides in `io.sentry.android.core.internal.util.RootChecker`.

```
MIT License

Copyright (c) 2016 breadwallet LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

---

## KilianB — PCG-Java (MIT)

**Source:** https://github.com/KilianB/pcg-java<br>
**License:** MIT License<br>
**Copyright:** Copyright (c) 2018

### Scope

The Sentry Java SDK includes an adapted PCG-based random number generator from the pcg-java library for fast sampling. The code resides in `io.sentry.util.Random`.

```
MIT License

Copyright (c) 2018

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Jon Chambers — UUID String Utils (MIT)

**Source:** Jon Chambers<br>
**License:** MIT License<br>
**Copyright:** Copyright (c) 2018 Jon Chambers

### Scope

The Sentry Java SDK includes adapted UUID string manipulation utilities. The code resides in `io.sentry.util.UUIDStringUtils`.

```
MIT License

Copyright (c) 2018 Jon Chambers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## fzyzcjy — Flutter Screen Recorder (MIT)

**Source:** https://github.com/fzyzcjy/flutter_screen_recorder (Commit: dce41cec25c66baf42c6bac4198e95874ce3eb9d)<br>
**License:** MIT License<br>
**Copyright:** Copyright (c) 2021 fzyzcjy

### Scope

The Sentry Android Replay SDK includes adapted versions of the video encoding and muxing classes from the flutter_screen_recorder library, used to encode and mux replay video frames into an MP4 file. The code resides in the `io.sentry.android.replay.video` package and includes `SimpleFrameMuxer`, `SimpleMp4FrameMuxer`, and `SimpleVideoEncoder`.

```
Copyright (c) 2021 fzyzcjy

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

In addition to the standard MIT license, this library requires the following: The recorder itself
only saves data on user's phone locally, thus it does not have any privacy problem. However, if
you are going to get the records out of the local storage (e.g. upload the records to your
server), please explicitly ask the user for permission, and promise to only use the records to
debug your app. This is a part of the license of this library.
```
