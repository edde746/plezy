//
//  UIApplication+idleTimerLock.m
//  wakelock
//
//  Created by suyao on 2021/12/17.
//

#import "./include/wakelock_plus/UIApplication+idleTimerLock.h"
#import <objc/runtime.h>

static NSString *idleTimerLockKey = @"idleTimerLockKey";


@implementation UIApplication (idleTimerLock)

+ (void)load {
  Method setIdleTimerDisabled = class_getInstanceMethod(self, @selector(setIdleTimerDisabled:));

  Method lock_setIdleTimerDisabled = class_getInstanceMethod(self, @selector(lock_setIdleTimerDisabled:));

  method_exchangeImplementations(setIdleTimerDisabled, lock_setIdleTimerDisabled);
}

- (void)lock_setIdleTimerDisabled:(BOOL)enable {
  if ([self lock_idleTimerlockEnable]) {
      return;
  }
  [self lock_setIdleTimerDisabled:enable];
}

- (void)lock_idleTimerlockEnable:(BOOL)enable {
  objc_setAssociatedObject(self, &idleTimerLockKey, @(enable), OBJC_ASSOCIATION_COPY);
}

- (BOOL)lock_idleTimerlockEnable
{
  return [objc_getAssociatedObject(self, &idleTimerLockKey) boolValue];
}

@end
