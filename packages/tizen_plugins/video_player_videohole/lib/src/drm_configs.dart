// Copyright 2023 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// The DRM scheme for the video.
enum DrmType {
  /// None.
  none,

  /// PlayReady.
  playready,

  /// Widevine CDM.
  widevine,
}

/// Callback that returns a DRM license from the given [challenge] data.
typedef LicenseCallback = Future<Uint8List> Function(Uint8List challenge);

/// Configurations for playing DRM content.
class DrmConfigs {
  /// Creates a new [DrmConfigs].
  const DrmConfigs({
    this.type = DrmType.none,
    this.licenseServerUrl,
    this.licenseCallback,
  });

  /// The DRM type.
  final DrmType type;

  /// The URL of the DRM license server.
  ///
  /// This is optional. Either [licenseServerUrl] or [licenseCallback] can be
  /// specified.
  final String? licenseServerUrl;

  /// A callback to retrieve a DRM license.
  ///
  /// This is optional. Either [licenseServerUrl] or [licenseCallback] can be
  /// specified.
  ///
  /// This callback is called multiple times while the video is playing. Note
  /// that the platform thread (main thread) is blocked while this callback is
  /// running. If the execution of this callback is delayed, the program may
  /// hang or fail to process user input.
  final LicenseCallback? licenseCallback;

  /// Converts to a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'drmType': type.index,
      'licenseServerUrl': licenseServerUrl,
    };
  }
}
