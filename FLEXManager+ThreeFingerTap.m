//
//  AVX512Manager+ThreeFingerTap.m
//  AVX512
//
//  Three-finger press-and-hold gesture support.
//

#import "AVX512Manager+ThreeFingerTap.h"
#import <UIKit/UIKit.h>

static UILongPressGestureRecognizer *avx512_threeFingerHoldGesture = nil;

@implementation AVX512Manager (ThreeFingerTap)

+ (void)load
{
    /*
     * +load runs before the application has finished creating its
     * windows/scenes.  Do not send instance-category messages to the
     * AVX512Manager class object here.  Instead, obtain the singleton
     * and use it as the notification observer.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        AVX512Manager *manager = [AVX512Manager sharedManager];

        [manager avx512_setupGesture];

        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;

        [center addObserver:manager
                   selector:@selector(avx512_windowDidBecomeKey:)
                       name:UIWindowDidBecomeKeyNotification
                     object:nil];

        if (@available(iOS 13.0, *)) {
            [center addObserver:manager
                       selector:@selector(avx512_sceneDidActivate:)
                           name:UISceneDidActivateNotification
                         object:nil];
        }
    });
}

- (void)avx512_windowDidBecomeKey:(NSNotification *)notification
{
    (void)notification;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self avx512_setupGesture];
    });
}

- (void)avx512_sceneDidActivate:(NSNotification *)notification
{
    (void)notification;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self avx512_setupGesture];
    });
}

- (void)avx512_setupGesture
{
    NSAssert(
        NSThread.isMainThread,
        @"Three-finger gesture setup must run on the main thread."
    );

    UIWindow *targetWindow = [self avx512_findTargetWindow];

    if (!targetWindow) {
        /*
         * The application may not have created its foreground window yet.
         * Retry briefly instead of installing the gesture on the wrong
         * window or failing permanently.
         */
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(0.5 * NSEC_PER_SEC)
            ),
            dispatch_get_main_queue(),
            ^{
                [self avx512_setupGesture];
            }
        );
        return;
    }

    /*
     * If the recognizer is already attached to the active window, leave it
     * alone.  This also avoids accumulating duplicate recognizers after
     * scene/window activation notifications.
     */
    if (avx512_threeFingerHoldGesture &&
        avx512_threeFingerHoldGesture.view == targetWindow) {
        return;
    }

    /*
     * The active application window can change with scenes or window
     * transitions.  Move the existing recognizer instead of creating
     * another one.
     */
    if (avx512_threeFingerHoldGesture &&
        avx512_threeFingerHoldGesture.view != targetWindow) {
        [avx512_threeFingerHoldGesture.view
            removeGestureRecognizer:avx512_threeFingerHoldGesture];
    }

    if (!avx512_threeFingerHoldGesture) {
        avx512_threeFingerHoldGesture =
            [UILongPressGestureRecognizer avx512_action:
                ^(UIGestureRecognizer *gesture) {

            /*
             * UILongPressGestureRecognizer enters Began once the required
             * three fingers have remained down for minimumPressDuration.
             * Fire exactly once per hold.
             */
            if (gesture.state != UIGestureRecognizerStateBegan) {
                return;
            }

            AVX512Manager *manager =
                [AVX512Manager sharedManager];

            if (!manager) {
                NSLog(
                    @"[AVX512] Three-finger hold: manager unavailable"
                );
                return;
            }

            NSLog(@"[AVX512] Three-finger hold detected");
            [manager toggleExplorer];
        }];

        /*
         * "Three-finger tap and hold":
         * - exactly three fingers
         * - a short hold instead of an accidental single-frame tap
         */
        avx512_threeFingerHoldGesture.numberOfTouchesRequired = 3;
        avx512_threeFingerHoldGesture.minimumPressDuration = 0.45;
        avx512_threeFingerHoldGesture.allowableMovement = 12.0;

        /*
         * Do not cancel the application's normal touch delivery when the
         * inspector gesture recognizes.
         */
        avx512_threeFingerHoldGesture.cancelsTouchesInView = NO;
    }

    if (avx512_threeFingerHoldGesture.view != targetWindow) {
        [targetWindow
            addGestureRecognizer:avx512_threeFingerHoldGesture];
    }

    NSLog(
        @"[AVX512] Three-finger hold gesture installed on %@",
        targetWindow
    );
}

- (UIWindow *)avx512_findTargetWindow
{
    UIApplication *application =
        UIApplication.sharedApplication;

    /*
     * iOS 13+ scene-based lookup.  Only inspect foreground-active
     * application scenes and prefer the normal-level key window.
     */
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
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
                if (!window.isHidden &&
                    window.alpha > 0.0 &&
                    window.windowLevel == UIWindowLevelNormal &&
                    window.isKeyWindow) {
                    return window;
                }
            }

            for (UIWindow *window in windowScene.windows) {
                if (!window.isHidden &&
                    window.alpha > 0.0 &&
                    window.windowLevel == UIWindowLevelNormal) {
                    return window;
                }
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    /*
     * Legacy fallback for pre-scene applications.
     */
    for (UIWindow *window in application.windows) {
        if (!window.isHidden &&
            window.alpha > 0.0 &&
            window.windowLevel == UIWindowLevelNormal &&
            window.isKeyWindow) {
            return window;
        }
    }

    for (UIWindow *window in application.windows) {
        if (!window.isHidden &&
            window.alpha > 0.0 &&
            window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }

#pragma clang diagnostic pop

    return nil;
}

@end