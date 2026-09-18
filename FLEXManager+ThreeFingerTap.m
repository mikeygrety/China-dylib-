#import “FLEXManager+ThreeFingerTap.h”
#import “FLEXManager.h”
#import <UIKit/UIKit.h>

#pragma mark - Gesture Storage

static UITapGestureRecognizer *avx512_threeFingerTapGesture = nil;

#pragma mark - AVX512 Manager

@implementation AVX512Manager (ThreeFingerTap)

* (void)load
    {
    /*
    * +load can execute before the application’s main window exists.
    * Install on the main thread and retry until the host window exists.
        */
        if ([NSThread isMainThread]) {
        [self avx512_setupGesture];
        } else {
        dispatch_async(dispatch_get_main_queue(), ^{
        [self avx512_setupGesture];
        });
        }
        }

#pragma mark - Gesture Setup

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
    /*
    * The application window may not exist yet.
    */
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
    * If the gesture already belongs to the current host window,
    * everything is already configured.
        */
        if (avx512_threeFingerTapGesture &&
        avx512_threeFingerTapGesture.view == targetWindow) {
        return;
        }
    /*
    * If the application switched windows, detach the old gesture.
        */
        if (avx512_threeFingerTapGesture.view) {
        [avx512_threeFingerTapGesture.view
        removeGestureRecognizer:
        avx512_threeFingerTapGesture];
        }
    /*
    * Create the recognizer once.
        */
        if (!avx512_threeFingerTapGesture) {
        avx512_threeFingerTapGesture =
        [[UITapGestureRecognizer alloc]
        initWithTarget:self
        action:@selector(
        avx512_threeFingerTapRecognized:)];
        /*
        * Exactly one tap with three fingers.
            */
            avx512_threeFingerTapGesture.numberOfTapsRequired = 1;
            avx512_threeFingerTapGesture.numberOfTouchesRequired = 3;
        /*
        * Do not interfere with the host application’s normal
        * touch handling.
            */
            avx512_threeFingerTapGesture.cancelsTouchesInView = NO;
            avx512_threeFingerTapGesture.delaysTouchesBegan = NO;
            avx512_threeFingerTapGesture.delaysTouchesEnded = NO;
            }
    /*
    * Attach to the current application window.
        */
        if (avx512_threeFingerTapGesture.view != targetWindow) {
        [targetWindow
        addGestureRecognizer:
        avx512_threeFingerTapGesture];
        NSLog(
        @”[AVX512] Three-finger tap installed on %@”,
        targetWindow
        );
        }
        }

#pragma mark - Gesture Action

* (void)avx512_threeFingerTapRecognized:
    (UITapGestureRecognizer *)gesture
    {
    if (gesture.state != UIGestureRecognizerStateEnded) {
    return;
    }
    AVX512Manager *manager =
    [AVX512Manager sharedManager];
    if (!manager) {
    NSLog(
    @”[AVX512] Three-finger tap detected, “
    @“but sharedManager is unavailable.”
    );
    return;
    }
    NSLog(
    @”[AVX512] Three-finger tap → toggleExplorer”
    );
    /*
    * Use the existing AVX512 explorer/menu entry point.
    * This preserves the existing runtime tools:
    * View
    * Select
    * Recent
    * Move
    * Disassemble
    * Hook
    * Capture
    * Filza
    * Protect
    * etc.
        */
        [manager toggleExplorer];
        }

#pragma mark - Target Window

* (UIWindow *)avx512_findTargetWindow
    {
    UIWindow *applicationWindow = nil;
    /*
    * iOS 13+
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
  * active key window that is not AVX512Window.
  */
 for (UIWindow *window
      in windowScene.windows) {
     if (window.isKeyWindow &&
         ![NSStringFromClass(window.class)
             isEqualToString:@"AVX512Window"]) {
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
 for (UIWindow *window
      in windowScene.windows) {
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
  * visible normal-level non-AVX512 window.
  */
 for (UIWindow *window
      in windowScene.windows) {
     if (![NSStringFromClass(window.class)
             isEqualToString:@"AVX512Window"] &&
         !window.isHidden &&
         window.alpha > 0.0 &&
         window.windowLevel ==
             UIWindowLevelNormal) {
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
    * Legacy / fallback window lookup.
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
        if (window.isKeyWindow &&
            ![NSStringFromClass(window.class)
                isEqualToString:@"AVX512Window"]) {
            applicationWindow = window;
            break;
        }
    }
    /*
     * Look for another visible application window.
     */
    if (!applicationWindow) {
        for (UIWindow *window in windows) {
            if (![NSStringFromClass(window.class)
                    isEqualToString:@"AVX512Window"] &&
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
 * Never intentionally attach the gesture to AVX512Window if
 * another usable application window is available.
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
            for (UIWindow *window
                 in windowScene.windows) {
                if (![NSStringFromClass(window.class)
                        isEqualToString:@"AVX512Window"] &&
                    !window.isHidden &&
                    window.alpha > 0.0 &&
                    window.windowLevel ==
                        UIWindowLevelNormal) {
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
            if (![NSStringFromClass(window.class)
                    isEqualToString:@"AVX512Window"] &&
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