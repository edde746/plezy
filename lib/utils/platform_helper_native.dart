/// Native platform implementation using dart:io.
library;

import 'dart:io' show Platform;

bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isMacOS => Platform.isMacOS;
bool get isWindows => Platform.isWindows;
bool get isLinux => Platform.isLinux;
bool get isFuchsia => Platform.isFuchsia;
bool get isWeb => false;
bool get isWebOS => false;
