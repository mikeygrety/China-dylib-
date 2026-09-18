//
//  AVX512Manager+ThreeFingerTap.h
//  AVX512
//
//  Three-finger press-and-hold gesture support.
//

#import <UIKit/UIKit.h>
#import "AVX512Manager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVX512Manager (ThreeFingerTap)

/// Installs or updates the three-finger press-and-hold gesture on the active window.
- (void)avx512_setupGesture;

/// Handles UIWindowDidBecomeKeyNotification.
- (void)avx512_windowDidBecomeKey:(NSNotification *)notification;

/// Handles UISceneDidActivateNotification.
- (void)avx512_sceneDidActivate:(NSNotification *)notification;

/// Finds the current foreground application window.
- (nullable UIWindow *)avx512_findTargetWindow;

@end

NS_ASSUME_NONNULL_END