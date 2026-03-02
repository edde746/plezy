#import <Cocoa/Cocoa.h>

// MARK: - PIP.framework (Private Framework)

@protocol PIPViewControllerDelegate;

@interface PIPViewController : NSViewController

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, weak, nullable) id<PIPViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) NSWindow *replacementWindow;
@property (nonatomic) NSRect replacementRect;
@property (nonatomic) bool playing;
@property (nonatomic) NSSize aspectRatio;

- (void)presentViewControllerAsPictureInPicture:(NSViewController *)viewController;

@end

@protocol PIPViewControllerDelegate <NSObject>

@optional
// macOS 10.12-10.14
- (BOOL)pipShouldClose:(PIPViewController *)pip;
// macOS 10.15+
- (void)pipWillClose:(PIPViewController *)pip;
- (void)pipDidClose:(PIPViewController *)pip;
- (void)pipActionPlay:(PIPViewController *)pip;
- (void)pipActionPause:(PIPViewController *)pip;
- (void)pipActionStop:(PIPViewController *)pip;

@end
