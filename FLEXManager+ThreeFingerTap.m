#import “FLEXManager+ThreeFingerTap.h”
#import “FLEXManager.h”
#import “UIGestureRecognizer+Blocks.h”
#import <UIKit/UIKit.h>

static UILongPressGestureRecognizer *avx512_threeFingerGesture = nil;

@implementation AVX512Manager (ThreeFingerTap)

* (void)load
    {
    if ([NSThread isMainThread]) {
    [self avx512_setupGesture];
    } else {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self avx512_setupGesture];
    });
    }
    }
* (void)avx512_setupGesture
    {
    if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self avx512_setupGesture];
    });
    return;
    }
    UIWindow *targetWindow = [self avx512_findTargetWindow];
    if (!targetWindow) {
    dispatch_after(
    dispatch_time(
    DISPATCH_TIME_NOW,
    (int64_t)(1.0 * NSEC_PER_SEC)
    ),
    dispatch_get_main_queue(),
    ^{
    [self avx512_setupGesture];
    }
    );

  return;

    }
    /*
    * Already installed on the correct application window.
        */
        if (avx512_threeFingerGesture &&
        avx512_threeFingerGesture.view == targetWindow) {
        return;
        }
    /*
    * Remove the recognizer from an old window if the
    * application’s active window changed.
        */
        if (avx512_threeFingerGesture.view) {
        [avx512_threeFingerGesture.view
        removeGestureRecognizer:avx512_threeFingerGesture];
        }
    /*
    * Preserve the original FLEX-style gesture implementation.
        */
        if (!avx512_threeFingerGesture) {
        avx512_threeFingerGesture =
        [UILongPressGestureRecognizer
        avx512_action:^(UIGestureRecognizer *gesture) {

 if (gesture.state != UIGestureRecognizerStateBegan) {
     return;
 }
 AVX512Manager *manager =
     [AVX512Manager sharedManager];
 if (!manager) {
     NSLog(
         @"[AVX512] Three-finger gesture detected, "
         @"but sharedManager is unavailable."
     );
     return;
 }
 NSLog(
     @"[AVX512] Three-finger tap -> toggleExplorer"
 );
 [manager toggleExplorer];

        }];
        /*
        * Three fingers.
            */
            avx512_threeFingerGesture.numberOfTouchesRequired = 3;
        /*
        * Short press duration makes this behave as a
        * three-finger tap while retaining the original
        * UILongPressGestureRecognizer implementation.
            */
            avx512_threeFingerGesture.minimumPressDuration = 0.05;
        /*
        * Allow normal small finger movement.
            */
            avx512_threeFingerGesture.allowableMovement = 100.0;
        /*
        * Do not consume normal application touches.
            */
            avx512_threeFingerGesture.cancelsTouchesInView = NO;
            avx512_threeFingerGesture.delaysTouchesBegan = NO;
            avx512_threeFingerGesture.delaysTouchesEnded = NO;
            }
    /*
    * Attach to the application’s real window.
        */
        if (avx512_threeFingerGesture.view != targetWindow) {
        [targetWindow addGestureRecognizer:avx512_threeFingerGesture];
        NSLog(
        @”[AVX512] Three-finger gesture installed on %@”,
        targetWindow
        );
        }
        }
* (UIWindow *)avx512_findTargetWindow
    {
    UIWindow *applicationWindow = nil;
    /*
    * iOS 13+ scene-aware lookup.
        */
        if (@available(iOS 13.0, *)) {
        for (UIScene *scene
        in [UIApplication sharedApplication].connectedScenes) {

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
  * First choice:
  * key application window, excluding AVX512Window.
  */
 for (UIWindow *window in windowScene.windows) {
     NSString *className =
         NSStringFromClass(window.class);
     if (window.isKeyWindow &&
         ![className isEqualToString:@"AVX512Window"]) {
         applicationWindow = window;
         break;
     }
 }
 if (applicationWindow) {
     break;
 }
 /*
  * Second choice:
  * any key window.
  */
 for (UIWindow *window in windowScene.windows) {
     if (window.isKeyWindow) {
         applicationWindow = window;
         break;
     }
 }
 if (applicationWindow) {
     break;
 }
 /*
  * Third choice:
  * visible normal-level application window.
  */
 for (UIWindow *window in windowScene.windows) {
     NSString *className =
         NSStringFromClass(window.class);
     if (![className isEqualToString:@"AVX512Window"] &&
         !window.isHidden &&
         window.alpha > 0.0 &&
         window.windowLevel == UIWindowLevelNormal) {
         applicationWindow = window;
         break;
     }
 }
 if (applicationWindow) {
     break;
 }

        }
        }
    /*
    * Legacy fallback.
        */
        if (!applicationWindow) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored “-Wdeprecated-declarations”

    NSArray<UIWindow *> *windows =
        [UIApplication sharedApplication].windows;
    /*
     * Prefer a key window that is not AVX512Window.
     */
    for (UIWindow *window in windows) {
        NSString *className =
            NSStringFromClass(window.class);
        if (window.isKeyWindow &&
            ![className isEqualToString:@"AVX512Window"]) {
            applicationWindow = window;
            break;
        }
    }
    /*
     * Find a visible application window.
     */
    if (!applicationWindow) {
        for (UIWindow *window in windows) {
            NSString *className =
                NSStringFromClass(window.class);
            if (![className isEqualToString:@"AVX512Window"] &&
                !window.isHidden &&
                window.alpha > 0.0) {
                applicationWindow = window;
                break;
            }
        }
    }
    /*
     * Final fallback.
     */
    if (!applicationWindow) {
        applicationWindow =
            [UIApplication sharedApplication].keyWindow;
    }

#pragma clang diagnostic pop
}

/*
 * Never intentionally leave the gesture on the AVX512
 * overlay window if another application window exists.
 */
if (applicationWindow &&
    [NSStringFromClass(applicationWindow.class)
        isEqualToString:@"AVX512Window"]) {
    UIWindow *fallbackWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene
             in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState !=
                UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene =
                (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                NSString *className =
                    NSStringFromClass(window.class);
                if (![className isEqualToString:@"AVX512Window"] &&
                    !window.isHidden &&
                    window.alpha > 0.0 &&
                    window.windowLevel == UIWindowLevelNormal) {
                    fallbackWindow = window;
                    if (window.isKeyWindow) {
                        applicationWindow = window;
                        break;
                    }
                }
            }
            if (applicationWindow &&
                ![NSStringFromClass(applicationWindow.class)
                    isEqualToString:@"AVX512Window"]) {
                break;
            }
        }
    } else {

#pragma clang diagnostic push
#pragma clang diagnostic ignored “-Wdeprecated-declarations”

        for (UIWindow *window
             in [UIApplication sharedApplication].windows) {
            NSString *className =
                NSStringFromClass(window.class);
            if (![className isEqualToString:@"AVX512Window"] &&
                !window.isHidden &&
                window.alpha > 0.0) {
                fallbackWindow = window;
                if (window.isKeyWindow) {
                    applicationWindow = window;
                    break;
                }
            }
        }

#pragma clang diagnostic pop
}

    if ([NSStringFromClass(applicationWindow.class)
            isEqualToString:@"AVX512Window"] &&
        fallbackWindow) {
        applicationWindow = fallbackWindow;
    }
}
return applicationWindow;

}

@end