#import "./include/wakelock_plus/WakelockPlusPlugin.h"
#import "./include/wakelock_plus/messages.g.h"
#import "./include/wakelock_plus/UIApplication+idleTimerLock.h"

@interface WakelockPlusPlugin () <WAKELOCKPLUSWakelockPlusApi>

@property (nonatomic, assign) BOOL enable;

@end

@implementation WakelockPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  WakelockPlusPlugin* instance = [[WakelockPlusPlugin alloc] init];
  SetUpWAKELOCKPLUSWakelockPlusApi(registrar.messenger, instance);
}

- (void)toggleMsg:(WAKELOCKPLUSToggleMessage*)input error:(FlutterError**)error {
  BOOL enable = [input.enable boolValue];
  if (!enable) {
    [[UIApplication sharedApplication] lock_idleTimerlockEnable:enable];//should disable first
    [self setIdleTimerDisabled:enable];
  } else {
    [self setIdleTimerDisabled:enable];
    [[UIApplication sharedApplication] lock_idleTimerlockEnable:enable];
  }
  self.enable = enable;
}

- (void)setIdleTimerDisabled:(BOOL)enable {
  BOOL enabled = [[UIApplication sharedApplication] isIdleTimerDisabled];
  if (enable!= enabled) {
    [[UIApplication sharedApplication] setIdleTimerDisabled:enable];
  }
}


- (WAKELOCKPLUSIsEnabledMessage*)isEnabledWithError:(FlutterError* __autoreleasing *)error {
  NSNumber *enabled = [NSNumber numberWithBool:[[UIApplication sharedApplication] isIdleTimerDisabled]];
  WAKELOCKPLUSIsEnabledMessage* result = [[WAKELOCKPLUSIsEnabledMessage alloc] init];
  result.enabled = enabled;
  return result;
}

- (void)setEnable:(BOOL)enable {
  _enable = enable;
}

@end
