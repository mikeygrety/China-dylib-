#import “FLEXManager+ThreeFingerTap.h”
#import “FLEXManager.h”
#import “UIGestureRecognizer+Blocks.h”
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static UILongPressGestureRecognizer *avx512_threeFingerLongPressGesture = nil;

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
    * If our gesture is already attached to the correct
    * application window, nothing else is required.
        */
        if (avx512_threeFingerLongPressGesture &&
        avx512_threeFingerLongPressGesture.view == targetWindow) {
        return;
        }
    /*
    * Remove the existing gesture from a previous window.
        */
        if (avx512_threeFingerLongPressGesture.view) {
        [avx512_threeFingerLongPressGesture.view
        removeGestureRecognizer:
        avx512_threeFingerLongPressGesture];
        avx512_threeFingerLongPressGesture = nil;
        }
    /*
    * Create the original AVX512 three-finger gesture.
        */
        if (!avx512_threeFingerLongPressGesture) {
        avx512_threeFingerLongPressGesture =
        [UILongPressGestureRecognizer
        avx512_action:
        ^(UIGestureRecognizer *gesture) {

 if (gesture.state != UIGestureRecognizerStateBegan) {
     return;
 }
 AVX512Manager *manager =
     [AVX512Manager sharedManager];
 if (!manager) {
     NSLog(
         @"[AVX512] Three-finger gesture fired, "
         @"but sharedManager is unavailable."
     );
     return;
 }
 NSLog(
     @"[AVX512] Three-finger gesture -> toggleExplorer"
 );
 [manager toggleExplorer];

        }];
        /*
        * Exactly three fingers.
            */
            avx512_threeFingerLongPressGesture.numberOfTouchesRequired = 3;
            }
    /*
    * Attach the gesture to the real application window.
        */
        if (avx512_threeFingerLongPressGesture.view != targetWindow) {
        [targetWindow
        addGestureRecognizer:
        avx512_threeFingerLongPressGesture];
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
  * First preference:
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
  * Second preference:
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
  * Third preference:
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
     * Find another visible application window.
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
     * Final legacy fallback.
     */
    if (!applicationWindow) {
        applicationWindow =
            [UIApplication sharedApplication].keyWindow;
    }

#pragma clang diagnostic pop
}

/*
 * If the selected window is AVX512Window, find the
 * underlying application window instead.
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