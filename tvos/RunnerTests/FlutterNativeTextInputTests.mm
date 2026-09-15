#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface FlutterTextInputView : UIView
@property(nonatomic, readonly) UITextField* tvosTextInputProxy;
@end

@interface FlutterTextInputPlugin : NSObject
@property(nonatomic, weak) UIViewController* viewController;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (UIView<UITextInput>*)textInputView;
@end

@interface FlutterEngine (NativeTextInputTests)
- (FlutterTextInputPlugin*)textInputPlugin;
@end

@interface FlutterViewController (NativeTextInputTests)
@property(nonatomic, assign, getter=isTvosNativeTextInputActive) BOOL tvosNativeTextInputActive;
@end

@interface FlutterNativeTextInputTests : XCTestCase
@end

@implementation FlutterNativeTextInputTests {
  FlutterEngine* _engine;
  FlutterViewController* _flutterViewController;
  UIWindow* _window;
  FlutterTextInputPlugin* _textInputPlugin;
}

- (void)setUp {
  [super setUp];
  _window = [self windowContainingFlutterViewController];
  _flutterViewController = (FlutterViewController*)_window.rootViewController;
  XCTAssertTrue([_flutterViewController isKindOfClass:[FlutterViewController class]]);
  _engine = _flutterViewController.engine;
  _textInputPlugin = [_engine textInputPlugin];
  XCTAssertNotNil(_textInputPlugin);
}
- (void)tearDown {
  [self invokeTextInput:@"TextInput.hide" arguments:nil];
  [self invokeTextInput:@"TextInput.clearClient" arguments:nil];
  _textInputPlugin = nil;
  _engine = nil;
  _flutterViewController = nil;
  _window = nil;
  [super tearDown];
}

- (UIWindow*)windowContainingFlutterViewController {
  id<UIApplicationDelegate> appDelegate = UIApplication.sharedApplication.delegate;
  if ([appDelegate.window.rootViewController isKindOfClass:[FlutterViewController class]]) {
    return appDelegate.window;
  }

  for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
      continue;
    }
    for (UIWindow* window in ((UIWindowScene*)scene).windows) {
      if ([window.rootViewController isKindOfClass:[FlutterViewController class]]) {
        return window;
      }
    }
  }
  return nil;
}

- (void)testPackagedEngineUsesRealUITextFieldProxyAndNativeSessionRouting {
  [self invokeTextInput:@"TextInput.setClient"
              arguments:@[
                @123,
                @{
                  @"inputType" : @{@"name" : @"TextInputType.url"},
                  @"keyboardAppearance" : @"Brightness.dark",
                  @"obscureText" : @NO,
                  @"inputAction" : @"TextInputAction.done",
                  @"smartDashesType" : @"0",
                  @"smartQuotesType" : @"0",
                  @"autocorrect" : @NO,
                  @"enableInteractiveSelection" : @YES,
                },
              ]];
  [self invokeTextInput:@"TextInput.setEditingState"
              arguments:@{
                @"text" : @"plezy.local",
                @"selectionBase" : @2,
                @"selectionExtent" : @7,
                @"selectionAffinity" : @"TextAffinity.downstream",
                @"composingBase" : @(-1),
                @"composingExtent" : @(-1),
              }];

  FlutterTextInputView* inputView = (FlutterTextInputView*)[_textInputPlugin textInputView];
  UITextField* proxy = inputView.tvosTextInputProxy;
  XCTAssertNotNil(proxy);
  XCTAssertEqualObjects(proxy.text, @"plezy.local");
  XCTAssertEqual(proxy.keyboardType, UIKeyboardTypeURL);
  XCTAssertEqual(proxy.returnKeyType, UIReturnKeyDone);
  XCTAssertEqual(proxy.autocorrectionType, UITextAutocorrectionTypeNo);
  XCTAssertEqual([proxy offsetFromPosition:proxy.beginningOfDocument toPosition:proxy.selectedTextRange.start], 2);
  XCTAssertEqual([proxy offsetFromPosition:proxy.beginningOfDocument toPosition:proxy.selectedTextRange.end], 7);

  [self invokeTextInput:@"TextInput.show" arguments:nil];
  [self waitForMainRunLoop];
  XCTAssertTrue(proxy.isFirstResponder);
  XCTAssertTrue(_flutterViewController.tvosNativeTextInputActive);

  [self invokeTextInput:@"TextInput.hide" arguments:nil];
  [self waitForMainRunLoop];
  XCTAssertFalse(proxy.isFirstResponder);
  XCTAssertFalse(_flutterViewController.tvosNativeTextInputActive);
}

- (void)invokeTextInput:(NSString*)method arguments:(id)arguments {
  FlutterMethodCall* call = [FlutterMethodCall methodCallWithMethodName:method arguments:arguments];
  [_textInputPlugin handleMethodCall:call
                              result:^(id result){
                              }];
}

- (void)waitForMainRunLoop {
  XCTestExpectation* expectation = [self expectationWithDescription:@"main run loop"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:2];
}

@end
