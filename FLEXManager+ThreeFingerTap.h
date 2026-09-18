#import “FLEXManager+ThreeFingerTap.h”
#import “AVX512Manager.h”
#import “UIGestureRecognizer+Blocks.h”
#import <UIKit/UIKit.h>

static UITapGestureRecognizer *avx512_threeFingerTapGesture = nil;

@implementation AVX512Manager (ThreeFingerTap)

* (void)load
    {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self avx512_installThreeFingerGesture];
    });
    }

#pragma mark - Installation

* (void)avx512_installThreeFingerGesture
    {
    if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self avx512_installThreeFingerGesture];
    });
    return;
    }
    UIWindow *window = [self avx512_findTargetWindow];
    if (!window) {
    NSLog(@”[AVX512][3FT] No application window yet”);

  dispatch_after(
      dispatch_time(
          DISPATCH_TIME_NOW,
          (int64_t)(0.5 * NSEC_PER_SEC)
      ),
      dispatch_get_main_queue(),
      ^{
          [self avx512_installThreeFingerGesture];
      }
  );
  return;

    }
    NSLog(
    @”[AVX512][3FT] Target window: %@”,
    window
    );
    /*
    * Already installed.
        */
        if (avx512_threeFingerTapGesture &&
        avx512_threeFingerTapGesture.view == window) {
        NSLog(@”[AVX512][3FT] Gesture already installed”);
        return;
        }
    /*
    * Remove from a previous window.
        */
        if (avx512_threeFingerTapGesture.view) {
        NSLog(
        @”[AVX512][3FT] Removing gesture from old window: %@”,
        avx512_threeFingerTapGesture.view
        );
        [avx512_threeFingerTapGesture.view
        removeGestureRecognizer:
        avx512_threeFingerTapGesture];
        }
    /*
    * Create the recognizer using the same block-based
    * gesture infrastructure already present in AVX512.
        */
        if (!avx512_threeFingerTapGesture) {
        avx512_threeFingerTapGesture =
        [UITapGestureRecognizer
        avx512_action:
        ^(UIGestureRecognizer *gesture) {

 if (gesture.state != UIGestureRecognizerStateEnded) {
     return;
 }
 NSLog(
     @"[AVX512][3FT] THREE-FINGER TAP DETECTED"
 );
 AVX512Manager *manager =
     [AVX512Manager sharedManager];
 if (!manager) {
     NSLog(
         @"[AVX512][3FT] ERROR: sharedManager is nil"
     );
     return;
 }
 NSLog(
     @"[AVX512][3FT] Calling toggleExplorer"
 );
 [manager toggleExplorer];
 NSLog(
     @"[AVX512][3FT] toggleExplorer completed"
 );

        }];
        avx512_threeFingerTapGesture.numberOfTouchesRequired = 3;
        avx512_threeFingerTapGesture.numberOfTapsRequired = 1;
        /*
        * Do not block the application’s normal touch handling.
            */
            avx512_threeFingerTapGesture.cancelsTouchesInView = NO;
            avx512_threeFingerTapGesture.delaysTouchesBegan = NO;
            avx512_threeFingerTapGesture.delaysTouchesEnded = NO;
        /*
        * Allow other gestures to coexist.
            */
            avx512_threeFingerTapGesture.delegate = self;
        NSLog(
        @”[AVX512][3FT] Created three-finger tap recognizer”
        );
        }
    if (avx512_threeFingerTapGesture.view != window) {

  [window
      addGestureRecognizer:
          avx512_threeFingerTapGesture];
  NSLog(
      @"[AVX512][3FT] INSTALLED on %@",
      window
  );

    }
    }

#pragma mark - Gesture Delegate

* (BOOL)gestureRecognizer:
    (UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
    (UIGestureRecognizer *)otherGestureRecognizer
    {
    if (gestureRecognizer ==
    avx512_threeFingerTapGesture) {
    return YES;
    }
    return NO;
    }

#pragma mark - Window Notifications

* (void)avx512_windowDidBecomeKey:(NSNotification *)notification
    {
    NSLog(
    @”[AVX512][3FT] Window became key: %@”,
    notification.object
    );
    [self avx512_installThreeFingerGesture];
    }
* (void)avx512_sceneDidActivate:(NSNotification *)notification
    {
    NSLog(
    @”[AVX512][3FT] Scene activated”
    );
    [self avx512_installThreeFingerGesture];
    }

#pragma mark - Target Window

* (UIWindow *)avx512_findTargetWindow
    {
    UIApplication *application =
    [UIApplication sharedApplication];
    /*
    * Prefer the active scene’s key application window.
        */
        if (@available(iOS 13.0, *)) {
        for (UIScene *scene
        in application.connectedScenes) {

 if (scene.activationState !=
     UISceneActivationStateForegroundActive) {
     continue;
 }
 if (![scene isKindOfClass:[UIWindowScene class]]) {
     continue;
 }
 UIWindowScene *windowScene =
     (UIWindowScene *)scene;
 /*
  * First: key window that is not AVX512Window.
  */
 for (UIWindow *window
      in windowScene.windows) {
     NSString *className =
         NSStringFromClass(window.class);
     if (window.isKeyWindow &&
         !window.isHidden &&
         window.alpha > 0.0 &&
         ![className
             isEqualToString:@"AVX512Window"]) {
         return window;
     }
 }
 /*
  * Second: visible normal-level application window.
  */
 for (UIWindow *window
      in windowScene.windows) {
     NSString *className =
         NSStringFromClass(window.class);
     if (!window.isHidden &&
         window.alpha > 0.0 &&
         window.windowLevel ==
             UIWindowLevelNormal &&
         ![className
             isEqualToString:@"AVX512Window"]) {
         return window;
     }
 }

        }
        }
    /*
    * Legacy fallback.
        */
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored “-Wdeprecated-declarations”
    NSArray<UIWindow *> *windows =
    application.windows;
    for (UIWindow *window in windows) {

  NSString *className =
      NSStringFromClass(window.class);
  if (window.isKeyWindow &&
      !window.isHidden &&
      window.alpha > 0.0 &&
      ![className
          isEqualToString:@"AVX512Window"]) {
      return window;
  }

    }
    for (UIWindow *window in windows) {

  NSString *className =
      NSStringFromClass(window.class);
  if (!window.isHidden &&
      window.alpha > 0.0 &&
      ![className
          isEqualToString:@"AVX512Window"]) {
      return window;
  }

    }

#pragma clang diagnostic pop

return nil;

}

@end