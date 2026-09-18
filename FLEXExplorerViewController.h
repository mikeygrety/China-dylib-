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

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

/// Temporarily hands live-view selection to the existing Explorer Select tool.
///
/// The currently presented tool, such as MRzefv UI Editor, may be dismissed
/// while the Explorer waits for the user to select a live UIView.
///
/// The completion is called exactly once:
///
///   selectedView != nil, cancelled == NO
///       User selected a UIView.
///
///   selectedView == nil, cancelled == YES
///       Selection was cancelled, for example by Close.
///
/// The Explorer remains the owner of hit-testing, outlines and Select mode.
- (void)beginLiveViewSelectionWithCompletion:
    (void (^)(UIView * _Nullable selectedView, BOOL cancelled))completion;

/// Cancels an outstanding live-view selection request.
///
/// This is safe to call even when no external selection is pending.
- (void)cancelPendingLiveViewSelection;

/// @brief Used to present (or dismiss) a modal view controller ("tool"),
/// typically triggered by pressing a button in the toolbar.
///
/// If a tool is already presented, this method simply dismisses it and calls the completion block.
/// If no tool is presented, @code future() @endcode is presented and the completion block is called.
- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^)(void))completion;

/// @brief Used to present (or dismiss) a modal view controller ("tool"),
/// typically triggered by pressing a button in the toolbar.
///
/// If a tool is already presented, this method simply dismisses the tool and presents the given tool.
/// The completion block is called once the tool has been presented.
- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion;

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