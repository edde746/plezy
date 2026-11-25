// The Mac app's only Objective-C declarations: PIP.framework, the private framework behind the system's picture in
// picture window (the one Safari and QuickTime Player use).
// Over mpv's AVSampleBufferDisplayLayer AVKit's public controller mirrors the layer unscaled (PictureInPicture.swift).
// Private API is acceptable here because the Mac app ships as a Developer ID–signed, notarized DMG outside the Mac App
// Store. AppKit/PictureInPicture.swift is the only user; the framework is weakly linked (project.yml), and that file
// checks the class exists before using it.

#import <Cocoa/Cocoa.h>

@protocol PIPViewControllerDelegate;

@interface PIPViewController : NSViewController

@property(nonatomic, copy, nullable) NSString *name;
@property(nonatomic, weak, nullable) id<PIPViewControllerDelegate> delegate;
@property(nonatomic, weak, nullable) NSWindow *replacementWindow;
@property(nonatomic) NSRect replacementRect;
@property(nonatomic) bool playing;
@property(nonatomic) NSSize aspectRatio;

- (void)presentViewControllerAsPictureInPicture:(nonnull NSViewController *)viewController;

@end

@protocol PIPViewControllerDelegate <NSObject>

@optional
- (BOOL)pipShouldClose:(nonnull PIPViewController *)pip;
- (void)pipWillClose:(nonnull PIPViewController *)pip;
- (void)pipDidClose:(nonnull PIPViewController *)pip;
- (void)pipActionPlay:(nonnull PIPViewController *)pip;
- (void)pipActionPause:(nonnull PIPViewController *)pip;
- (void)pipActionStop:(nonnull PIPViewController *)pip;

@end
