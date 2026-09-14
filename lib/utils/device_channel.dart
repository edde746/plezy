import 'package:flutter/services.dart';

/// Native device bridge (TV detection, device name, performance signals,
/// process-exit diagnostics). Implemented per platform under `com.plezy/device`.
const MethodChannel deviceChannel = MethodChannel('com.plezy/device');
