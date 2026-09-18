//
//  AVX512ExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerToolbar.h"

@class AVX512Window;

@protocol AVX512ExplorerViewControllerDelegate;

FOUNDATION_EXPORT NSNotificationName const AVX512ExplorerSelectedViewDidChangeNotification;

/// A view controller that manages the FLEX toolbar.
@interface AVX512ExplorerViewController : UIViewController

@property (nonatomic, weak) id <AVX512ExplorerViewControllerDelegate> delegate;
@property (nonatomic, readonly) BOOL wantsWindowToBecomeKey;

@property (nonatomic, readonly) AVX512ExplorerToolbar *explorerToolbar;

/// The view currently selected by the existing AVX512/FLEX Select tool.
@property (nonatomic, readonly, nullable) UIView *selectedView;

/// Returns YES when the explorer should receive a touch at the supplied
/// window coordinate.
- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

/// Used to present (or dismiss) a modal tool.
///
/// If a tool is already presented, this method dismisses it and calls
/// the completion block. If no tool is presented, the supplied tool is
/// presented and the completion block is called.
- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^)(void))completion;

/// Presents the supplied tool, dismissing any currently presented tool.
///
/// The completion block is called after the supplied tool has been presented.
- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion;

/// Temporarily hands live-view selection back to the existing AVX512/FLEX
/// Select tool.
///
/// The currently presented tool is dismissed, Select mode is activated,
/// and the completion block is called when the user selects a real UIView
/// through the existing explorer selection system.
- (void)beginLiveViewSelectionWithCompletion:(void (^)(UIView *selectedView))completion;

// Keyboard shortcut helpers
- (void)toggleSelectTool;
- (void)toggleMoveTool;
- (void)toggleViewsTool;
- (void)toggleMenuTool;

- (BOOL)handleDownArrowKeyPressed;
- (BOOL)handleUpArrowKeyPressed;
- (BOOL)handleRightArrowKeyPressed;
- (BOOL)handleLeftArrowKeyPressed;

@end

@protocol AVX512ExplorerViewControllerDelegate <NSObject>

- (void)explorerViewControllerDidFinish:(AVX512ExplorerViewController *)explorerViewController;

@end