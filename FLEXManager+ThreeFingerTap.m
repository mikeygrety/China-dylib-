#import "FLEXManager+ThreeFingerTap.h"
#import "AVX512Manager.h"
#import "UIGestureRecognizer+Blocks.h"
#import <UIKit/UIKit.h>
static UITapGestureRecognizer *avx512_threeFingerTapGesture = nil;
@implementation AVX512Manager (ThreeFingerTap)
+ (void)load
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self avx512_setupGesture];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(avx512_windowDidBecomeKey:)
                   name:UIWindowDidBecomeKeyNotification
                 object:nil];
        if (@available(iOS 13.0, *)) {
            [[NSNotificationCenter defaultCenter]
                addObserver:self
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
    UIWindow *targetWindow = [self avx512_findTargetWindow];
    if (!targetWindow) {
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
     * If the gesture already exists on the correct window,
     * there is nothing else to do.
     */
    if (avx512_threeFingerTapGesture &&
        avx512_threeFingerTapGesture.view == targetWindow) {
        return;
    }
    /*
     * Remove it from an old window if the active application
     * window changed.
     */
    if (avx512_threeFingerTapGesture &&
        avx512_threeFingerTapGesture.view != targetWindow) {
        [avx512_threeFingerTapGesture.view
            removeGestureRecognizer:avx512_threeFingerTapGesture];
    }
    /*
     * Create the gesture once.
     */
    if (!avx512_threeFingerTapGesture) {
        avx512_threeFingerTapGesture =
            [UITapGestureRecognizer avx512_action:
                ^(UIGestureRecognizer *gesture) {
            if (gesture.state != UIGestureRecognizerStateEnded) {
                return;
            }
            AVX512Manager *manager =
                [AVX512Manager sharedManager];
            if (!manager) {
                NSLog(
                    @"[AVX512] Three-finger tap: manager unavailable"
                );
                return;
            }
            NSLog(@"[AVX512] Three-finger tap detected");
            [manager toggleExplorer];
        }];
        avx512_threeFingerTapGesture.numberOfTouchesRequired = 3;
        avx512_threeFingerTapGesture.numberOfTapsRequired = 1;
        /*
         * Do not prevent normal application gestures unnecessarily.
         */
        avx512_threeFingerTapGesture.cancelsTouchesInView = NO;
    }
    if (avx512_threeFingerTapGesture.view != targetWindow) {
        [targetWindow
            addGestureRecognizer:avx512_threeFingerTapGesture];
    }
    NSLog(
        @"[AVX512] Three-finger gesture installed on %@",
        targetWindow
    );
}
- (UIWindow *)avx512_findTargetWindow
{
    UIApplication *application =
        UIApplication.sharedApplication;
    /*
     * iOS 13+ scene-based window lookup.
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
            /*
             * Prefer the key window that belongs to the
             * foreground application.
             */
            for (UIWindow *window in windowScene.windows) {
                if (!window.isHidden &&
                    window.alpha > 0.0 &&
                    window.windowLevel == UIWindowLevelNormal &&
                    window.isKeyWindow) {
                    return window;
                }
            }
            /*
             * Fall back to a visible normal-level window.
             */
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
     * Legacy fallback for older iOS versions.
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