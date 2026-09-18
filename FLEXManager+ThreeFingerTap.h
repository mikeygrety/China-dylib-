//
//  FLEXManager+ThreeFingerTap.h
//  AVX512
//
#import <UIKit/UIKit.h>
@class AVX512Manager;
@interface AVX512Manager (ThreeFingerTap)
/// Installs or updates the three-finger gesture on the active window.
- (void)avx512_setupGesture;
/// Handles UIWindowDidBecomeKeyNotification.
- (void)avx512_windowDidBecomeKey:(NSNotification *)notification;
/// Handles UISceneDidActivateNotification.
- (void)avx512_sceneDidActivate:(NSNotification *)notification;
/// Finds the current foreground application window.
- (UIWindow *)avx512_findTargetWindow;
@end