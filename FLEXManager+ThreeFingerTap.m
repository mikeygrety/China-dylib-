#import “FLEXManager+ThreeFingerTap.h”
#import “FLEXManager.h”
#import “UIGestureRecognizer+Blocks.h”
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - Gesture Storage

static UITapGestureRecognizer *avx512_threeFingerTapGesture = nil;

#pragma mark - AVX512 Manager

@implementation AVX512Manager (ThreeFingerTap)

* (void)load
    {
    /*
    * +load can execute before the application’s main window exists.
    * Always install the gesture on the main thread and retry if the
    * host application’s window has not been created yet.
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
    * The host application may not have created its window yet.
    * Retry shortly instead of permanently failing during +load.
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
    * If the existing gesture is already attached to the correct
    * application window, there is nothing else to do.
        */
        if (avx512_threeFingerTapGesture) {
        if (avx512_threeFingerTapGesture.view == targetWindow) {
        return;
        }
        /*
        * The active application window changed.
        * Move the recognizer to the new host window.
            */
            UIView *oldView = avx512_threeFingerTapGesture.view;
        if (oldView) {
        [oldView removeGestureRecognizer:
        avx512_threeFingerTapGesture];
        }
        }
    /*
    * Create the gesture once.
        */
        if (!avx512_threeFingerTapGesture) {
        __weak typeof(self) weakSelf = self;
        avx512_threeFingerTapGesture =
        [UITapGestureRecognizer avx512_action:
        ^(UIGestureRecognizer *gesture) {

 __strong typeof(weakSelf) strongSelf = weakSelf;
 if (!strongSelf) {
     return;
 }
 if (gesture.state !=
     UIGestureRecognizerStateEnded) {
     return;
 }
 AVX512Manager *manager =
     [AVX512Manager sharedManager];
 if (!manager) {
     NSLog(
         @"[AVX512] Three-finger tap detected, "
         @"but AVX512Manager is unavailable."
     );
     return;
 }
 NSLog(
     @"[AVX512] Three-finger tap → toggleExplorer"
 );
 /*
  * This is the existing AVX512/FLEX explorer entry
  * point. It preserves the existing menu and tools,
  * including the runtime View/Select/Disassemble/Hook
  * workflow.
  */
 [manager toggleExplorer];

        }];
        avx512_threeFingerTapGesture.numberOfTouchesRequired = 3;
        avx512_threeFingerTapGesture.numberOfTapsRequired = 1;
        /*
        * Do not swallow the application’s normal touches.
            */
            avx512_threeFingerTapGesture.cancelsTouchesInView = NO;
            avx512_threeFingerTapGesture.delaysTouchesBegan = NO;
            avx512_threeFingerTapGesture.delaysTouchesEnded = NO;
            }
    /*
    * Make absolutely sure the recognizer is not attached to an old
    * window before attaching it to the current host application window.
        */
        if (avx512_threeFingerTapGesture.view &&
        avx512_threeFingerTapGesture.view != targetWindow) {
        [avx512_threeFingerTapGesture.view
        removeGestureRecognizer:
        avx512_threeFingerTapGesture];
        }
    if (avx512_threeFingerTapGesture.view != targetWindow) {
    [targetWindow
    addGestureRecognizer:
    avx512_threeFingerTapGesture];

  NSLog(
      @"[AVX512] Installed three-finger tap on %@",
      targetWindow
  );

    }
    }

#pragma mark - Target Window

* (UIWindow *)avx512_findTargetWindow
    {
    UIWindow *applicationWindow = nil;
    /*
    * iOS 13+
    * Prefer the foreground-active scene and its key window.
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
  * First priority:
  * key window that is not the AVX512 window.
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
  * Second priority:
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
  * Third priority:
  * visible non-AVX512 window.
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
    * iOS < 13 fallback.
        */
        if (!applicationWindow) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored “-Wdeprecated-declarations”

    NSArray<UIWindow *> *windows =
        [UIApplication sharedApplication].windows;
    /*
     * Prefer a visible key window that isn't AVX512Window.
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
     * Look for any visible non-AVX512 window if no key window
     * was found.
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
 * Never intentionally install the gesture on the AVX512
 * presentation window when another application window exists.
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
            if (applicationWindow !=
                nil &&
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