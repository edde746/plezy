// SPDX-License-Identifier: GPL-3.0-or-later
#import <TargetConditionals.h>
#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif
@interface PlezySteamPlugin : NSObject <FlutterPlugin>
@end
