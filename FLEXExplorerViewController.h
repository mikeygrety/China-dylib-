//
//  AVX512ExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXExplorerToolbar.h"

@class AVX512Window;

@protocol AVX512ExplorerViewControllerDelegate;

FOUNDATION_EXPORT NSNotificationName const AVX512ExplorerSelectedViewDidChangeNotification;

/// A view controller that manages the AVX512/FLEX explorer toolbar
/// and remains the canonical owner of live-view selection.
@interface AVX512ExplorerViewController : UIViewController

@property (nonatomic, weak)
    id <AVX512ExplorerViewControllerDelegate> delegate;

@property (nonatomic, readonly)
    BOOL wantsWindowToBecomeKey;

@property (nonatomic, readonly)
    AVX512ExplorerToolbar *explorerToolbar;

/// The UIView currently selected by the existing AVX512/FLEX
/// Select tool.
@property (nonatomic, readonly, nullable)
    UIView *selectedView;

/// Determines whether the Explorer should receive a touch at a
/// particular point in window coordinates.
- (BOOL)shouldReceiveTouchAtWindowPoint:
    (CGPoint)pointInWindowCoordinates;

#pragma mark - MRzefv Live Selection

/// Temporarily hands live-view selection to the existing
/// AVX512/FLEX Select system.
///
/// The currently presented tool, such as the MRzefv UI Editor,
/// may be dismissed while the Explorer waits for the user to
/// select a live UIView.
///
/// The completion receives the exact UIView selected by the
/// existing Explorer hit-testing system.
///
/// The completion is called at most once for a successful
/// selection. Cancelling the request clears the pending callback.
///
/// MRzefv does not perform its own hit-testing; the Explorer
/// remains the sole owner of selection, outlines, and Select mode.
- (void)beginLiveViewSelectionWithCompletion:
    (void (^)(UIView * _Nullable selectedView))completion;

/// Cancels an outstanding MRzefv live-view selection request.
///
/// Safe to call when there is no pending request.
- (void)cancelPendingLiveViewSelection;

#pragma mark - Tool Presentation

/// Used to present or dismiss a modal tool.
///
/// If a tool is already presented, it is dismissed and the
/// completion is called.
///
/// If no tool is presented, future() is presented and the
/// completion is called afterward.
- (void)toggleToolWithViewControllerProvider:
    (UINavigationController *(^)(void))future
    completion:(void (^)(void))completion;

/// Used to present a modal tool.
///
/// If a tool is already presented, it is dismissed first and
/// the new tool is then presented.
///
/// The completion is called once the tool has been presented.
- (void)presentTool:
    (UINavigationController *(^)(void))future
    completion:(void (^)(void))completion;

#pragma mark - Keyboard Shortcut Helpers

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

- (void)explorerViewControllerDidFinish:
    (AVX512ExplorerViewController *)explorerViewController;

@end