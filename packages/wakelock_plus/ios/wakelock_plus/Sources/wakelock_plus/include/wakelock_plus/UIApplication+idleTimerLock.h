//
//  UIApplication+idleTimerLock.h
//  wakelock
//
//  Created by suyao on 2021/12/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (idleTimerLock)

- (void)lock_idleTimerlockEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
