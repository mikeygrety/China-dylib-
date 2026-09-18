//
//  AVX512ExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerViewController.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXUtility.h"
#import "FLEXWindow.h"
#import "FLEXTabList.h"
#import "FLEXNavigationController.h"
#import "FLEXHierarchyViewController.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXTabsViewController.h"
#import "FLEXWindowManagerController.h"
#import "FLEXViewControllersViewController.h"
#import "NSUserDefaults+FLEX.h"

// xFunctional modules
#import "x/ClassDump/UCClassDumpTool.h"
#import "x/ClassDump/UCClassSearchViewController.h"
#import "x/Disassembler/UCDisassembler.h"
#import "x/Disassembler/UCDisasmViewController.h"
#import "x/filza/UCFilzaTool.h"
#import "x/Decrypt/UCDecryptTool.h"
#import "x/Decrypt/DatabaseManager.h"
#import "x/AppProtection/UCAppProtectionTool.h"
#import "x/AVX512HookTemplateGenerator.h"

NSNotificationName const AVX512ExplorerSelectedViewDidChangeNotification =
    @"AVX512ExplorerSelectedViewDidChangeNotification";

static NSString * const AVX512ExplorerSelectedViewUserInfoKey =
    @"selectedView";

typedef NS_ENUM(NSUInteger, AVX512ExplorerMode) {
    AVX512ExplorerModeDefault,
    AVX512ExplorerModeSelect,
    AVX512ExplorerModeMove
};

@interface AVX512ExplorerViewController ()
    <AVX512HierarchyDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic) AVX512ExplorerMode currentMode;

@property (nonatomic) UIPanGestureRecognizer *movePanGR;
@property (nonatomic) UITapGestureRecognizer *detailsTapGR;

@property (nonatomic) CGRect selectedViewFrameBeforeDragging;
@property (nonatomic) CGRect toolbarFrameBeforeDragging;

@property (nonatomic) CGFloat selectedViewLastPanX;

@property (nonatomic) NSDictionary<NSValue *, UIView *> *outlineViewsForVisibleViews;
@property (nonatomic) NSArray<UIView *> *viewsAtTapPoint;

@property (nonatomic) UIView *selectedView;
@property (nonatomic) UIView *selectedViewOverlay;

@property (nonatomic, readonly)
    UISelectionFeedbackGenerator *selectionFBG API_AVAILABLE(ios(10.0));

@property (nonatomic, readonly) AVX512Window *window;

@property (nonatomic) NSMutableSet<UIView *> *observedViews;

@property (nonatomic) NSArray<UIMenuItem *> *appMenuItems;

/*
 * MRzefv live-selection handoff.
 *
 * MRzefv never performs its own hit-testing.
 *
 * Instead:
 *
 *   1. MRzefv asks the Explorer to begin selection.
 *   2. Explorer dismisses the currently presented tool.
 *   3. Explorer enters the existing Select mode.
 *   4. The normal Explorer selection recognizer handles the tap.
 *   5. setSelectedView: receives the canonical UIView.
 *   6. The pending callback is fired on the next main-loop turn.
 *
 * The callback is cleared after firing or cancellation.
 */
@property (nonatomic, copy, nullable)
    void (^pendingLiveSelectionCompletion)(UIView *selectedView);

@end

@implementation AVX512ExplorerViewController

#pragma mark - Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil
                            bundle:nibBundleOrNil];

    if (self) {
        _observedViews = [NSMutableSet set];
        _currentMode = AVX512ExplorerModeDefault;
    }

    return self;
}

- (void)dealloc {

    NSArray<UIView *> *views =
        self.observedViews.allObjects;

    for (UIView *view in views) {
        [self stopObservingView:view];
    }

    self.pendingLiveSelectionCompletion = nil;

    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
}

- (void)viewDidLoad {

    [super viewDidLoad];

    _explorerToolbar =
        [AVX512ExplorerToolbar new];

    CGFloat toolbarOriginY =
        NSUserDefaults.standardUserDefaults.avx512_toolbarTopMargin;

    CGRect safeArea =
        [self viewSafeArea];

    CGSize toolbarSize =
        [self.explorerToolbar
            sizeThatFits:
                CGSizeMake(
                    CGRectGetWidth(self.view.bounds),
                    CGRectGetHeight(safeArea)
                )];

    [self
        updateToolbarPositionWithUnconstrainedFrame:
            CGRectMake(
                CGRectGetMinX(safeArea),
                toolbarOriginY,
                toolbarSize.width,
                toolbarSize.height
            )];

    self.explorerToolbar.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleTopMargin;

    [self.view
        addSubview:self.explorerToolbar];

    [self setupToolbarActions];
    [self setupToolbarGestures];

    /*
     * This remains the ONLY live-view selection recognizer.
     *
     * MRzefv uses this existing Explorer selection pipeline.
     */
    UITapGestureRecognizer *selectionTapGR =
        [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(handleSelectionTap:)];

    [self.view
        addGestureRecognizer:selectionTapGR];

    self.movePanGR =
        [[UIPanGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(handleMovePan:)];

    self.movePanGR.enabled =
        self.currentMode == AVX512ExplorerModeMove;

    [self.view
        addGestureRecognizer:self.movePanGR];

    if (@available(iOS 10.0, *)) {
        _selectionFBG =
            [UISelectionFeedbackGenerator new];
    }

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(keyboardShown:)
               name:UIKeyboardWillShowNotification
             object:nil];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self updateButtonStates];
}

#pragma mark - MRzefv Live Selection Handoff

- (void)beginLiveViewSelectionWithCompletion:
    (void (^)(UIView * _Nullable selectedView))completion {

    NSParameterAssert(completion != nil);

    /*
     * Replace any stale request.
     */
    self.pendingLiveSelectionCompletion =
        [completion copy];

    /*
     * Clear the previous selection so the user can select
     * the exact same UIView again.
     */
    self.selectedView = nil;

    /*
     * MRzefv is normally presented over the Explorer.
     *
     * Dismiss the presented editor/tool first. Once dismissal
     * finishes, activate the existing Explorer Select mode.
     */
    void (^activateSelection)(void) = ^{

        self.currentMode =
            AVX512ExplorerModeSelect;

        [self updateButtonStates];
    };

    UIViewController *presented =
        self.presentedViewController;

    if (presented) {

        [self
            dismissViewControllerAnimated:YES
                               completion:
                                   activateSelection];

    } else {

        activateSelection();
    }
}

- (void)cancelPendingLiveViewSelection {

    /*
     * The one-shot callback is intentionally just discarded.
     *
     * The current MRzefv API uses a one-argument completion,
     * therefore there is no cancellation result to deliver.
     */
    self.pendingLiveSelectionCompletion = nil;
}

#pragma mark - Rotation

- (UIViewController *)viewControllerForRotationAndOrientation {

    UIViewController *viewController =
        AVX512Utility.appKeyWindow.rootViewController;

    NSString *viewControllerSelectorString =
        [@[
            @"_vie",
            @"wContro",
            @"llerFor",
            @"Supported",
            @"Interface",
            @"Orientations"
        ] componentsJoinedByString:@""];

    SEL viewControllerSelector =
        NSSelectorFromString(viewControllerSelectorString);

    if ([viewController
            respondsToSelector:viewControllerSelector]) {

        viewController =
            [viewController
                valueForKey:viewControllerSelectorString];
    }

    return viewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {

    UIViewController *viewControllerToAsk =
        [self viewControllerForRotationAndOrientation];

    UIInterfaceOrientationMask supportedOrientations =
        AVX512Utility.infoPlistSupportedInterfaceOrientationsMask;

    if (viewControllerToAsk &&
        ![NSStringFromClass([viewControllerToAsk class])
            hasPrefix:@"AVX512"]) {

        supportedOrientations =
            [viewControllerToAsk supportedInterfaceOrientations];
    }

    if (supportedOrientations == 0) {
        supportedOrientations =
            UIInterfaceOrientationMaskAll;
    }

    return supportedOrientations;
}

- (BOOL)shouldAutorotate {

    UIViewController *viewControllerToAsk =
        [self viewControllerForRotationAndOrientation];

    BOOL shouldAutorotate = YES;

    if (viewControllerToAsk &&
        viewControllerToAsk != self) {

        shouldAutorotate =
            [viewControllerToAsk shouldAutorotate];
    }

    return shouldAutorotate;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
           (id<UIViewControllerTransitionCoordinator>)coordinator {

    [super
        viewWillTransitionToSize:size
        withTransitionCoordinator:coordinator];

    [coordinator
        animateAlongsideTransition:
            ^(id<UIViewControllerTransitionCoordinatorContext> context) {

        for (UIView *outlineView
             in self.outlineViewsForVisibleViews.allValues) {

            outlineView.hidden = YES;
        }

        self.selectedViewOverlay.hidden = YES;

    } completion:
        ^(id<UIViewControllerTransitionCoordinatorContext> context) {

        for (UIView *view in self.viewsAtTapPoint) {

            NSValue *key =
                [NSValue
                    valueWithNonretainedObject:view];

            UIView *outlineView =
                self.outlineViewsForVisibleViews[key];

            outlineView.frame =
                [self frameInLocalCoordinatesForView:view];

            if (self.currentMode ==
                AVX512ExplorerModeSelect) {

                outlineView.hidden = NO;
            }
        }

        if (self.selectedView) {

            self.selectedViewOverlay.frame =
                [self
                    frameInLocalCoordinatesForView:
                        self.selectedView];

            self.selectedViewOverlay.hidden = NO;
        }
    }];
}

#pragma mark - Selection State

- (void)setSelectedView:(UIView *)selectedView {

    if (_selectedView == selectedView) {
        return;
    }

    UIView *previousSelectedView =
        _selectedView;

    if (previousSelectedView &&
        ![self.viewsAtTapPoint
            containsObject:previousSelectedView]) {

        [self stopObservingView:previousSelectedView];
    }

    _selectedView = selectedView;

    if (selectedView) {
        [self beginObservingView:selectedView];
    }

    self.explorerToolbar.selectedViewDescription =
        [AVX512Utility
            descriptionForView:selectedView
            includingFrame:YES];

    self.explorerToolbar.selectedViewOverlayColor =
        [AVX512Utility
            consistentRandomColorForObject:selectedView];

    if (selectedView) {

        if (!self.selectedViewOverlay) {

            self.selectedViewOverlay =
                [UIView new];

            self.selectedViewOverlay.userInteractionEnabled =
                NO;

            self.selectedViewOverlay.layer.borderWidth =
                1.0;

            [self.view
                addSubview:self.selectedViewOverlay];
        }

        UIColor *outlineColor =
            [AVX512Utility
                consistentRandomColorForObject:selectedView];

        self.selectedViewOverlay.backgroundColor =
            [outlineColor
                colorWithAlphaComponent:0.2];

        self.selectedViewOverlay.layer.borderColor =
            outlineColor.CGColor;

        self.selectedViewOverlay.frame =
            [self
                frameInLocalCoordinatesForView:selectedView];

        [self.view
            bringSubviewToFront:self.selectedViewOverlay];

        [self.view
            bringSubviewToFront:self.explorerToolbar];

    } else {

        [self.selectedViewOverlay
            removeFromSuperview];

        self.selectedViewOverlay = nil;
    }

    [self updateButtonStates];

    /*
     * Canonical Explorer selection notification.
     */
    [[NSNotificationCenter defaultCenter]
        postNotificationName:
            AVX512ExplorerSelectedViewDidChangeNotification
                      object:self
                    userInfo:@{
        AVX512ExplorerSelectedViewUserInfoKey:
            selectedView ?: [NSNull null]
    }];

    /*
     * Complete the MRzefv request only for an actual selection.
     *
     * Defer one main-run-loop turn so the Explorer has finished
     * updating its overlay and toolbar before MRzefv returns.
     */
    if (selectedView &&
        self.pendingLiveSelectionCompletion) {

        void (^completion)(UIView *) =
            self.pendingLiveSelectionCompletion;

        self.pendingLiveSelectionCompletion = nil;

        UIView *newlySelectedView =
            selectedView;

        dispatch_async(
            dispatch_get_main_queue(), ^{

            completion(newlySelectedView);
        });
    }
}

- (void)setViewsAtTapPoint:
    (NSArray<UIView *> *)viewsAtTapPoint {

    if ([_viewsAtTapPoint
            isEqual:viewsAtTapPoint]) {

        return;
    }

    for (UIView *view in _viewsAtTapPoint) {

        if (view != self.selectedView) {
            [self stopObservingView:view];
        }
    }

    _viewsAtTapPoint =
        [viewsAtTapPoint copy];

    for (UIView *view in viewsAtTapPoint) {
        [self beginObservingView:view];
    }
}

- (void)setCurrentMode:
    (AVX512ExplorerMode)currentMode {

    if (_currentMode == currentMode) {
        return;
    }

    /*
     * Leaving Select mode cancels any pending MRzefv request.
     */
    if (_currentMode == AVX512ExplorerModeSelect &&
        currentMode != AVX512ExplorerModeSelect) {

        [self cancelPendingLiveViewSelection];
    }

    _currentMode = currentMode;

    switch (currentMode) {

        case AVX512ExplorerModeDefault: {

            [self removeAndClearOutlineViews];

            self.viewsAtTapPoint = nil;

            self.selectedView = nil;

            break;
        }

        case AVX512ExplorerModeSelect: {

            for (NSValue *key
                 in self.outlineViewsForVisibleViews) {

                UIView *outlineView =
                    self.outlineViewsForVisibleViews[key];

                outlineView.hidden = NO;
            }

            break;
        }

        case AVX512ExplorerModeMove: {

            for (NSValue *key
                 in self.outlineViewsForVisibleViews) {

                UIView *outlineView =
                    self.outlineViewsForVisibleViews[key];

                outlineView.hidden = YES;
            }

            break;
        }
    }

    self.movePanGR.enabled =
        currentMode == AVX512ExplorerModeMove;

    [self updateButtonStates];
}

#pragma mark - View Tracking

- (void)beginObservingView:(UIView *)view {

    if (!view ||
        [self.observedViews containsObject:view]) {

        return;
    }

    for (NSString *keyPath
         in self.viewKeyPathsToTrack) {

        [view
            addObserver:self
            forKeyPath:keyPath
               options:0
               context:nil];
    }

    [self.observedViews addObject:view];
}

- (void)stopObservingView:(UIView *)view {

    if (!view ||
        ![self.observedViews containsObject:view]) {

        return;
    }

    for (NSString *keyPath
         in self.viewKeyPathsToTrack) {

        @try {

            [view
                removeObserver:self
                forKeyPath:keyPath];

        } @catch (__unused NSException *exception) {
        }
    }

    [self.observedViews removeObject:view];
}

- (NSArray<NSString *> *)viewKeyPathsToTrack {

    static NSArray<NSString *> *trackedViewKeyPaths;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{

        trackedViewKeyPaths =
            @[
                NSStringFromSelector(
                    @selector(frame)
                )
            ];
    });

    return trackedViewKeyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context {

    [self
        updateOverlayAndDescriptionForObjectIfNeeded:object];
}

- (void)updateOverlayAndDescriptionForObjectIfNeeded:
    (id)object {

    NSUInteger indexOfView =
        [self.viewsAtTapPoint
            indexOfObject:object];

    if (indexOfView != NSNotFound) {

        UIView *view =
            self.viewsAtTapPoint[indexOfView];

        NSValue *key =
            [NSValue
                valueWithNonretainedObject:view];

        UIView *outline =
            self.outlineViewsForVisibleViews[key];

        if (outline) {

            outline.frame =
                [self
                    frameInLocalCoordinatesForView:view];
        }
    }

    if (object == self.selectedView) {

        self.explorerToolbar.selectedViewDescription =
            [AVX512Utility
                descriptionForView:self.selectedView
                includingFrame:YES];

        if (self.selectedViewOverlay) {

            self.selectedViewOverlay.frame =
                [self
                    frameInLocalCoordinatesForView:
                        self.selectedView];
        }
    }
}

- (CGRect)frameInLocalCoordinatesForView:
    (UIView *)view {

    if (!view) {
        return CGRectZero;
    }

    CGRect frameInWindow =
        [view
            convertRect:view.bounds
                 toView:nil];

    return
        [self.view
            convertRect:frameInWindow
                 fromView:nil];
}

- (void)keyboardShown:(NSNotification *)notif {

    CGRect keyboardFrame =
        [notif.userInfo[
            UIKeyboardFrameEndUserInfoKey
        ] CGRectValue];

    CGRect toolbarFrame =
        self.explorerToolbar.frame;

    if (CGRectGetMinY(keyboardFrame) <
        CGRectGetMaxY(toolbarFrame)) {

        toolbarFrame.origin.y =
            keyboardFrame.origin.y -
            toolbarFrame.size.height -
            50.0;

        [UIView
            animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0.5
                        options:
                            UIViewAnimationOptionCurveEaseOut
                     animations:^{

            [self
                updateToolbarPositionWithUnconstrainedFrame:
                    toolbarFrame];

        } completion:nil];
    }
}

#pragma mark - Toolbar Buttons

- (void)setupToolbarActions {

    AVX512ExplorerToolbar *toolbar =
        self.explorerToolbar;

    [toolbar.selectItem
        addTarget:self
           action:@selector(selectButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.hierarchyItem
        addTarget:self
           action:@selector(hierarchyButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.recentItem
        addTarget:self
           action:@selector(recentButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.moveItem
        addTarget:self
           action:@selector(moveButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.globalsItem
        addTarget:self
           action:@selector(globalsButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.closeItem
        addTarget:self
           action:@selector(closeButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.classdumpItem
        addTarget:self
           action:@selector(classdumpButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.disassemblerItem
        addTarget:self
           action:@selector(disassemblerButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.decryptItem
        addTarget:self
           action:@selector(decryptButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.filzaItem
        addTarget:self
           action:@selector(filzaButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.protectionItem
        addTarget:self
           action:@selector(protectionButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];

    [toolbar.hookGenItem
        addTarget:self
           action:@selector(hookGenButtonTapped:)
 forControlEvents:UIControlEventTouchUpInside];
}

- (void)selectButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    [self toggleSelectTool];
}

- (void)hierarchyButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    [self toggleViewsTool];
}

- (UIWindow *)statusWindow {

    if (!@available(iOS 16, *)) {

        NSString *statusBarString =
            [@[
                @"_statusB",
                @"arWindow"
            ] componentsJoinedByString:@""];

        return
            [UIApplication.sharedApplication
                valueForKey:statusBarString];
    }

    return nil;
}

- (void)recentButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    NSAssert(
        AVX512TabList.sharedList.activeTab,
        @"There must be an active tab."
    );

    [self
        presentViewController:
            AVX512TabList.sharedList.activeTab
                    animated:YES
                  completion:nil];
}

- (void)moveButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    [self toggleMoveTool];
}

- (void)globalsButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    [self toggleMenuTool];
}

- (void)closeButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    /*
     * Explicitly cancel any MRzefv request before leaving
     * the Explorer.
     */
    [self cancelPendingLiveViewSelection];

    self.currentMode =
        AVX512ExplorerModeDefault;

    [self.delegate
        explorerViewControllerDidFinish:self];
}

#pragma mark - Second Row Tool Buttons

- (void)classdumpButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    UCClassSearchViewController *searchVC =
        [[UCClassSearchViewController alloc] init];

    UINavigationController *nav =
        [[UINavigationController alloc]
            initWithRootViewController:searchVC];

    nav.modalPresentationStyle =
        UIModalPresentationFullScreen;

    [self
        presentViewController:nav
                     animated:YES
                   completion:nil];
}

- (void)hookGenButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    AVX512HookTemplateGenerator *gen =
        [[AVX512HookTemplateGenerator alloc] init];

    UINavigationController *nav =
        [[UINavigationController alloc]
            initWithRootViewController:gen];

    nav.modalPresentationStyle =
        UIModalPresentationFullScreen;

    [self
        presentViewController:nav
                     animated:YES
                   completion:nil];
}

- (void)exportAllHeaders {

    UIAlertController *confirmAlert =
        [UIAlertController
            alertControllerWithTitle:@"Export Headers"
                             message:@"Export all discovered class headers?"
                      preferredStyle:UIAlertControllerStyleAlert];

    [confirmAlert
        addAction:
            [UIAlertAction
                actionWithTitle:@"Cancel"
                          style:UIAlertActionStyleCancel
                        handler:nil]];

    [confirmAlert
        addAction:
            [UIAlertAction
                actionWithTitle:@"Export"
                          style:UIAlertActionStyleDefault
                        handler:^(UIAlertAction *action) {

        UIAlertController *progressAlert =
            [UIAlertController
                alertControllerWithTitle:@"Exporting Headers"
                                 message:@"Preparing class headers..."
                          preferredStyle:UIAlertControllerStyleAlert];

        [self
            presentViewController:progressAlert
                         animated:YES
                       completion:^{

            [UCClassDumpTool
                dumpHeadersZipWithProgress:
                    ^(CGFloat progress, NSString *text) {

                dispatch_async(
                    dispatch_get_main_queue(), ^{

                    progressAlert.message =
                        text ?: @"Exporting...";
                });

            } completion:
                ^(NSURL *zipURL, NSError *error) {

                dispatch_async(
                    dispatch_get_main_queue(), ^{

                    [progressAlert
                        dismissViewControllerAnimated:YES
                        completion:^{

                        if (error) {

                            UIAlertController *errAlert =
                                [UIAlertController
                                    alertControllerWithTitle:
                                        @"Export Failed"
                                    message:
                                        error.localizedDescription
                                    preferredStyle:
                                        UIAlertControllerStyleAlert];

                            [errAlert
                                addAction:
                                    [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:
                                            UIAlertActionStyleDefault
                                        handler:nil]];

                            [self
                                presentViewController:errAlert
                                             animated:YES
                                           completion:nil];

                        } else if (zipURL) {

                            UIActivityViewController *activityVC =
                                [[UIActivityViewController alloc]
                                    initWithActivityItems:@[zipURL]
                                    applicationActivities:nil];

                            [self
                                presentViewController:activityVC
                                             animated:YES
                                           completion:nil];
                        }
                    }];
                });
            }];
        }];
    }]];

    [self
        presentViewController:confirmAlert
                     animated:YES
                   completion:nil];
}

- (void)decryptButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    NSString *bundleID =
        [[NSBundle mainBundle] bundleIdentifier]
            ?: @"unknown";

    DatabaseManager *db =
        [DatabaseManager sharedManager];

    BOOL isMainSwitchOn =
        [db getSwitch:@"zongkaiguan"
             bundleID:bundleID
          defaultValue:NO];

    if (isMainSwitchOn) {

        [UCDecryptTool
            presentDecryptPanelFromViewController:self];

    } else {

        UIAlertController *alert =
            [UIAlertController
                alertControllerWithTitle:@"Capture"
                                 message:
                                    @"Capture logs network requests, crypto calls, and keys. Enable it?"
                          preferredStyle:
                            UIAlertControllerStyleAlert];

        [alert
            addAction:
                [UIAlertAction
                    actionWithTitle:@"Cancel"
                              style:UIAlertActionStyleCancel
                            handler:nil]];

        [alert
            addAction:
                [UIAlertAction
                    actionWithTitle:@"Enable"
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {

            [db setSwitch:@"zongkaiguan"
                 bundleID:bundleID
                     value:YES];

            [db setSwitch:@"zhaiyaokaiguan"
                 bundleID:bundleID
                     value:YES];

            [db setSwitch:@"jiamisuanfakaiguan"
                 bundleID:bundleID
                     value:YES];

            [UCDecryptTool
                presentDecryptPanelFromViewController:self];
        }]];

        alert.popoverPresentationController.barButtonItem =
            sender;

        [self
            presentViewController:alert
                         animated:YES
                       completion:nil];
    }
}

- (void)disassemblerButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    UCClassSearchViewController *searchVC =
        [UCClassSearchViewController
            searchViewControllerWithMode:
                UCClassSearchModeDisassembler];

    UINavigationController *nav =
        [[UINavigationController alloc]
            initWithRootViewController:searchVC];

    nav.modalPresentationStyle =
        UIModalPresentationFullScreen;

    [self
        presentViewController:nav
                     animated:YES
                   completion:nil];
}

- (void)showDisasmAddressDialog {

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Enter Address"
                             message:
                                @"Enter a hexadecimal memory address."
                      preferredStyle:
                        UIAlertControllerStyleAlert];

    [alert
        addTextFieldWithConfigurationHandler:
            ^(UITextField *textField) {

        textField.placeholder =
            @"0x100001234";

        textField.keyboardType =
            UIKeyboardTypeASCIICapable;

        textField.autocapitalizationType =
            UITextAutocapitalizationTypeNone;

        textField.autocorrectionType =
            UITextAutocorrectionTypeNo;
    }];

    [alert
        addAction:
            [UIAlertAction
                actionWithTitle:@"Cancel"
                          style:UIAlertActionStyleCancel
                        handler:nil]];

    [alert
        addAction:
            [UIAlertAction
                actionWithTitle:@"Open"
                          style:UIAlertActionStyleDefault
                        handler:^(UIAlertAction *action) {

        NSString *addrStr =
            alert.textFields.firstObject.text;

        if (addrStr.length == 0) {
            return;
        }

        unsigned long long addr = 0;

        NSScanner *scanner =
            [NSScanner scannerWithString:addrStr];

        [scanner scanHexLongLong:&addr];

        if (addr == 0) {
            return;
        }

        UCDisasmViewController *disasmVC =
            [[UCDisasmViewController alloc]
                initWithAddress:(uint64_t)addr
                           size:4096
                          title:
                            [NSString
                                stringWithFormat:
                                    @"0x%llx",
                                    addr]];

        UINavigationController *nav =
            [[UINavigationController alloc]
                initWithRootViewController:disasmVC];

        nav.modalPresentationStyle =
            UIModalPresentationFullScreen;

        [self
            presentViewController:nav
                         animated:YES
                       completion:nil];
    }]];

    [self
        presentViewController:alert
                     animated:YES
                   completion:nil];
}

- (void)filzaButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    [UCFilzaTool
        presentFilzaPanelFromViewController:self];
}

- (void)protectionButtonTapped:
    (AVX512ExplorerToolbarItem *)sender {

    [UCAppProtectionTool enableWithSetup];

    [UCAppProtectionTool
        presentProtectionPanelFromViewController:self
                                      completion:nil];
}

- (void)updateButtonStates {

    AVX512ExplorerToolbar *toolbar =
        self.explorerToolbar;

    toolbar.selectItem.selected =
        self.currentMode ==
        AVX512ExplorerModeSelect;

    toolbar.moveItem.selected =
        self.currentMode ==
        AVX512ExplorerModeMove;

    toolbar.moveItem.enabled =
        self.selectedView != nil;

    if (!self.presentedViewController) {

        toolbar.recentItem.enabled =
            AVX512TabList.sharedList.activeTab != nil;

    } else {

        toolbar.recentItem.enabled = NO;
    }
}

#pragma mark - Toolbar Dragging

- (void)setupToolbarGestures {

    AVX512ExplorerToolbar *toolbar =
        self.explorerToolbar;

    [toolbar.dragHandle
        addGestureRecognizer:
            [[UIPanGestureRecognizer alloc]
                initWithTarget:self
                        action:
                            @selector(
                                handleToolbarPanGesture:)]];

    [toolbar.secondRowDragHandle
        addGestureRecognizer:
            [[UIPanGestureRecognizer alloc]
                initWithTarget:self
                        action:
                            @selector(
                                handleToolbarPanGesture:)]];

    [toolbar.dragHandle
        addGestureRecognizer:
            [[UITapGestureRecognizer alloc]
                initWithTarget:self
                        action:
                            @selector(
                                handleToolbarHintTapGesture:)]];

    self.detailsTapGR =
        [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:
                        @selector(
                            handleToolbarDetailsTapGesture:)];

    [toolbar.selectedViewDescriptionContainer
        addGestureRecognizer:self.detailsTapGR];

    UIPanGestureRecognizer *panGesture =
        [[UIPanGestureRecognizer alloc]
            initWithTarget:self
                    action:
                        @selector(
                            handleChangeViewAtPointGesture:)];

    [toolbar.selectedViewDescriptionContainer
        addGestureRecognizer:panGesture];

    [toolbar.globalsItem
        addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc]
                initWithTarget:self
                        action:
                            @selector(
                                handleToolbarShowTabsGesture:)]];

    [toolbar.selectItem
        addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc]
                initWithTarget:self
                        action:
                            @selector(
                                handleToolbarWindowManagerGesture:)]];

    [toolbar.hierarchyItem
        addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc]
                initWithTarget:self
                        action:
                            @selector(
                                handleToolbarShowViewControllersGesture:)]];
}

- (void)handleToolbarPanGesture:
    (UIPanGestureRecognizer *)panGR {

    switch (panGR.state) {

        case UIGestureRecognizerStateBegan:

            self.toolbarFrameBeforeDragging =
                self.explorerToolbar.frame;

            [self
                updateToolbarPositionWithDragGesture:panGR];

            break;

        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:

            [self
                updateToolbarPositionWithDragGesture:panGR];

            break;

        default:
            break;
    }
}

- (void)updateToolbarPositionWithDragGesture:
    (UIPanGestureRecognizer *)panGR {

    CGPoint translation =
        [panGR translationInView:self.view];

    CGRect newToolbarFrame =
        self.toolbarFrameBeforeDragging;

    newToolbarFrame.origin.y +=
        translation.y;

    [self
        updateToolbarPositionWithUnconstrainedFrame:
            newToolbarFrame];
}

- (void)updateToolbarPositionWithUnconstrainedFrame:
    (CGRect)unconstrainedFrame {

    CGRect safeArea =
        [self viewSafeArea];

    CGFloat minY =
        CGRectGetMinY(safeArea);

    CGFloat maxY =
        CGRectGetMaxY(safeArea) -
        unconstrainedFrame.size.height;

    if (unconstrainedFrame.origin.y < minY) {

        unconstrainedFrame.origin.y =
            minY;

    } else if (unconstrainedFrame.origin.y > maxY) {

        unconstrainedFrame.origin.y =
            maxY;
    }

    self.explorerToolbar.frame =
        unconstrainedFrame;

    NSUserDefaults.standardUserDefaults.avx512_toolbarTopMargin =
        unconstrainedFrame.origin.y;
}

- (void)handleToolbarHintTapGesture:
    (UITapGestureRecognizer *)tapGR {

    if (tapGR.state ==
        UIGestureRecognizerStateRecognized) {

        CGRect originalToolbarFrame =
            self.explorerToolbar.frame;

        const NSTimeInterval kHalfwayDuration =
            0.2;

        const CGFloat kVerticalOffset =
            30.0;

        [UIView
            animateWithDuration:kHalfwayDuration
                          delay:0
                        options:
                            UIViewAnimationOptionCurveEaseOut
                     animations:^{

            CGRect newToolbarFrame =
                self.explorerToolbar.frame;

            newToolbarFrame.origin.y +=
                kVerticalOffset;

            self.explorerToolbar.frame =
                newToolbarFrame;

        } completion:^(BOOL finished) {

            [UIView
                animateWithDuration:kHalfwayDuration
                              delay:0
                            options:
                                UIViewAnimationOptionCurveEaseIn
                         animations:^{

                self.explorerToolbar.frame =
                    originalToolbarFrame;

            } completion:nil];
        }];
    }
}

- (void)handleToolbarDetailsTapGesture:
    (UITapGestureRecognizer *)tapGR {

    if (tapGR.state ==
            UIGestureRecognizerStateRecognized &&
        self.selectedView) {

        UIViewController *topStackVC =
            [AVX512ObjectExplorerFactory
                explorerViewControllerForObject:
                    self.selectedView];

        [self
            presentViewController:
                [AVX512NavigationController
                    withRootViewController:topStackVC]
                    animated:YES
                  completion:nil];
    }
}

- (void)handleToolbarShowTabsGesture:
    (UILongPressGestureRecognizer *)sender {

    if (sender.state ==
        UIGestureRecognizerStateBegan) {

        self.appMenuItems =
            UIMenuController.sharedMenuController.menuItems;

        [super
            presentViewController:
                [[UINavigationController alloc]
                    initWithRootViewController:
                        [AVX512TabsViewController new]]
                       animated:YES
                     completion:nil];
    }
}

- (void)handleToolbarWindowManagerGesture:
    (UILongPressGestureRecognizer *)sender {

    if (sender.state ==
        UIGestureRecognizerStateBegan) {

        self.appMenuItems =
            UIMenuController.sharedMenuController.menuItems;

        [super
            presentViewController:
                [AVX512NavigationController
                    withRootViewController:
                        [AVX512WindowManagerController new]]
                       animated:YES
                     completion:nil];
    }
}

- (void)handleToolbarShowViewControllersGesture:
    (UILongPressGestureRecognizer *)sender {

    if (sender.state ==
            UIGestureRecognizerStateBegan &&
        self.viewsAtTapPoint.count) {

        self.appMenuItems =
            UIMenuController.sharedMenuController.menuItems;

        UIViewController *list =
            [AVX512ViewControllersViewController
                controllersForViews:
                    self.viewsAtTapPoint];

        [self
            presentViewController:
                [AVX512NavigationController
                    withRootViewController:list]
                    animated:YES
                  completion:nil];
    }
}

#pragma mark - View Selection

- (void)handleSelectionTap:
    (UITapGestureRecognizer *)tapGR {

    if (self.currentMode !=
            AVX512ExplorerModeSelect ||
        tapGR.state !=
            UIGestureRecognizerStateRecognized) {

        return;
    }

    CGPoint tapPointInView =
        [tapGR locationInView:self.view];

    CGPoint tapPointInWindow =
        [self.view
            convertPoint:tapPointInView
                  toView:nil];

    [self
        updateOutlineViewsForSelectionPoint:
            tapPointInWindow];
}

- (void)handleChangeViewAtPointGesture:
    (UIPanGestureRecognizer *)sender {

    NSInteger max =
        self.viewsAtTapPoint.count - 1;

    NSInteger currentIdx =
        [self.viewsAtTapPoint
            indexOfObject:self.selectedView];

    if (currentIdx == NSNotFound) {
        currentIdx = 0;
    }

    CGFloat locationX =
        [sender locationInView:self.view].x;

    switch (sender.state) {

        case UIGestureRecognizerStateBegan:

            self.selectedViewLastPanX =
                locationX;

            break;

        case UIGestureRecognizerStateChanged: {

            static CGFloat kNextLevelThreshold =
                20.0;

            CGFloat lastX =
                self.selectedViewLastPanX;

            NSInteger newSelection =
                currentIdx;

            if (locationX < lastX &&
                (lastX - locationX) >=
                    kNextLevelThreshold) {

                newSelection =
                    MIN(max, currentIdx + 1);

                self.selectedViewLastPanX =
                    locationX;

            } else if (
                lastX < locationX &&
                (locationX - lastX) >=
                    kNextLevelThreshold) {

                newSelection =
                    MAX(0, currentIdx - 1);

                self.selectedViewLastPanX =
                    locationX;
            }

            if (currentIdx != newSelection &&
                newSelection >= 0 &&
                newSelection <
                    self.viewsAtTapPoint.count) {

                self.selectedView =
                    self.viewsAtTapPoint[newSelection];

                [self actuateSelectionChangedFeedback];
            }

            break;
        }

        default:
            break;
    }
}

- (void)actuateSelectionChangedFeedback {

    if (@available(iOS 10.0, *)) {
        [self.selectionFBG selectionChanged];
    }
}

- (void)updateOutlineViewsForSelectionPoint:
    (CGPoint)selectionPointInWindow {

    [self removeAndClearOutlineViews];

    self.viewsAtTapPoint =
        [self
            viewsAtPoint:
                selectionPointInWindow
            skipHiddenViews:NO];

    NSArray<UIView *> *visibleViewsAtTapPoint =
        [self
            viewsAtPoint:
                selectionPointInWindow
            skipHiddenViews:YES];

    NSMutableDictionary<NSValue *, UIView *> *
        newOutlineViewsForVisibleViews =
            [NSMutableDictionary new];

    for (UIView *view
         in visibleViewsAtTapPoint) {

        UIView *outlineView =
            [self outlineViewForView:view];

        [self.view
            addSubview:outlineView];

        NSValue *key =
            [NSValue
                valueWithNonretainedObject:view];

        [newOutlineViewsForVisibleViews
            setObject:outlineView
               forKey:key];
    }

    self.outlineViewsForVisibleViews =
        newOutlineViewsForVisibleViews;

    /*
     * Canonical Explorer selection.
     *
     * This is the only place where a live tap is converted
     * into the selected UIView.
     */
    self.selectedView =
        [self
            viewForSelectionAtPoint:
                selectionPointInWindow];

    [self.view
        bringSubviewToFront:self.explorerToolbar];

    [self updateButtonStates];
}

- (UIView *)outlineViewForView:
    (UIView *)view {

    CGRect outlineFrame =
        [self
            frameInLocalCoordinatesForView:view];

    UIView *outlineView =
        [[UIView alloc]
            initWithFrame:outlineFrame];

    outlineView.backgroundColor =
        UIColor.clearColor;

    outlineView.layer.borderColor =
        [AVX512Utility
            consistentRandomColorForObject:view].CGColor;

    outlineView.layer.borderWidth =
        1.0;

    outlineView.userInteractionEnabled =
        NO;

    return outlineView;
}

- (void)removeAndClearOutlineViews {

    for (NSValue *key
         in self.outlineViewsForVisibleViews) {

        UIView *outlineView =
            self.outlineViewsForVisibleViews[key];

        [outlineView removeFromSuperview];
    }

    self.outlineViewsForVisibleViews = nil;
}

- (NSArray<UIView *> *)viewsAtPoint:
    (CGPoint)tapPointInWindow
    skipHiddenViews:(BOOL)skipHidden {

    NSMutableArray<UIView *> *views =
        [NSMutableArray new];

    for (UIWindow *window
         in AVX512Utility.allWindows) {

        if (window != self.view.window &&
            [window
                pointInside:tapPointInWindow
                  withEvent:nil]) {

            [views addObject:window];

            [views
                addObjectsFromArray:
                    [self
                        recursiveSubviewsAtPoint:
                            tapPointInWindow
                        inView:window
                        skipHiddenViews:skipHidden]];
        }
    }

    return views;
}

- (UIView *)viewForSelectionAtPoint:
    (CGPoint)tapPointInWindow {

    UIWindow *windowForSelection =
        UIApplication.sharedApplication.keyWindow;

    for (UIWindow *window
         in AVX512Utility.allWindows.reverseObjectEnumerator) {

        if (window != self.view.window &&
            [window
                hitTest:tapPointInWindow
                withEvent:nil]) {

            windowForSelection =
                window;

            break;
        }
    }

    return
        [self
            recursiveSubviewsAtPoint:
                tapPointInWindow
            inView:windowForSelection
            skipHiddenViews:YES].lastObject;
}

- (NSArray<UIView *> *)recursiveSubviewsAtPoint:
    (CGPoint)pointInView
    inView:(UIView *)view
    skipHiddenViews:(BOOL)skipHidden {

    NSMutableArray<UIView *> *subviewsAtPoint =
        [NSMutableArray new];

    for (UIView *subview in view.subviews) {

        BOOL isHidden =
            subview.hidden ||
            subview.alpha < 0.01;

        if (skipHidden && isHidden) {
            continue;
        }

        BOOL subviewContainsPoint =
            CGRectContainsPoint(
                subview.frame,
                pointInView
            );

        if (subviewContainsPoint) {

            [subviewsAtPoint
                addObject:subview];
        }

        if (subviewContainsPoint ||
            !subview.clipsToBounds) {

            CGPoint pointInSubview =
                [view
                    convertPoint:pointInView
                          toView:subview];

            [subviewsAtPoint
                addObjectsFromArray:
                    [self
                        recursiveSubviewsAtPoint:
                            pointInSubview
                        inView:subview
                        skipHiddenViews:skipHidden]];
        }
    }

    return subviewsAtPoint;
}

#pragma mark - Selected View Moving

- (void)handleMovePan:
    (UIPanGestureRecognizer *)movePanGR {

    switch (movePanGR.state) {

        case UIGestureRecognizerStateBegan:

            if (!self.selectedView) {
                return;
            }

            self.selectedViewFrameBeforeDragging =
                self.selectedView.frame;

            [self
                updateSelectedViewPositionWithDragGesture:
                    movePanGR];

            break;

        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:

            if (!self.selectedView) {
                return;
            }

            [self
                updateSelectedViewPositionWithDragGesture:
                    movePanGR];

            break;

        default:
            break;
    }
}

- (void)updateSelectedViewPositionWithDragGesture:
    (UIPanGestureRecognizer *)movePanGR {

    if (!self.selectedView.superview) {
        return;
    }

    CGPoint translation =
        [movePanGR
            translationInView:
                self.selectedView.superview];

    CGRect newSelectedViewFrame =
        self.selectedViewFrameBeforeDragging;

    newSelectedViewFrame.origin.x =
        AVX512Floor(
            newSelectedViewFrame.origin.x +
            translation.x
        );

    newSelectedViewFrame.origin.y =
        AVX512Floor(
            newSelectedViewFrame.origin.y +
            translation.y
        );

    self.selectedView.frame =
        newSelectedViewFrame;
}

#pragma mark - Safe Area Handling

- (CGRect)viewSafeArea {

    CGRect safeArea =
        self.view.bounds;

    if (@available(iOS 11.0, *)) {

        safeArea =
            UIEdgeInsetsInsetRect(
                self.view.bounds,
                self.view.safeAreaInsets
            );
    }

    return safeArea;
}

- (void)viewSafeAreaInsetsDidChange {

    if (@available(iOS 11.0, *)) {

        [super viewSafeAreaInsetsDidChange];

        CGRect safeArea =
            [self viewSafeArea];

        CGSize toolbarSize =
            [self.explorerToolbar
                sizeThatFits:
                    CGSizeMake(
                        CGRectGetWidth(self.view.bounds),
                        CGRectGetHeight(safeArea)
                    )];

        [self
            updateToolbarPositionWithUnconstrainedFrame:
                CGRectMake(
                    CGRectGetMinX(
                        self.explorerToolbar.frame
                    ),
                    CGRectGetMinY(
                        self.explorerToolbar.frame
                    ),
                    toolbarSize.width,
                    toolbarSize.height
                )];
    }
}

#pragma mark - Touch Handling

- (BOOL)shouldReceiveTouchAtWindowPoint:
    (CGPoint)pointInWindowCoordinates {

    CGPoint pointInLocalCoordinates =
        [self.view
            convertPoint:pointInWindowCoordinates
                  fromView:nil];

    /*
     * If a modal tool is still presented, allow the presented
     * hierarchy to decide whether the point belongs to it.
     */
    if (self.presentedViewController) {

        UIView *presentedView =
            self.presentedViewController.view;

        CGPoint pointInPresentedView =
            [presentedView
                convertPoint:pointInLocalCoordinates
                      fromView:self.view];

        UIView *hit =
            [presentedView
                hitTest:pointInPresentedView
                withEvent:nil];

        if (hit != nil) {
            return YES;
        }
    }

    if (self.currentMode ==
        AVX512ExplorerModeSelect) {

        return YES;
    }

    if (self.currentMode ==
        AVX512ExplorerModeMove) {

        return YES;
    }

    if (CGRectContainsPoint(
            self.explorerToolbar.frame,
            pointInLocalCoordinates)) {

        return YES;
    }

    return NO;
}

#pragma mark - AVX512HierarchyDelegate

- (void)viewHierarchyDidDismiss:
    (UIView *)selectedView {

    [self
        toggleViewsToolWithCompletion:^{

        if (![self.viewsAtTapPoint
                containsObject:selectedView]) {

            self.viewsAtTapPoint = nil;

            [self removeAndClearOutlineViews];
        }

        if (self.currentMode ==
                AVX512ExplorerModeDefault &&
            selectedView) {

            self.currentMode =
                AVX512ExplorerModeSelect;
        }

        self.selectedView =
            selectedView;
    }];
}

#pragma mark - Modal Presentation and Window Management

- (void)presentViewController:
    (UIViewController *)toPresent
    animated:(BOOL)animated
    completion:(void (^)(void))completion {

    [self.view.window makeKeyWindow];

    if (!@available(iOS 13, *)) {

        UIWindow *statusWindow =
            [self statusWindow];

        statusWindow.windowLevel =
            self.view.window.windowLevel + 1.0;
    }

    self.appMenuItems =
        UIMenuController.sharedMenuController.menuItems;

    [self updateButtonStates];

    [super
        presentViewController:toPresent
                    animated:animated
                  completion:^{

        [self updateButtonStates];

        if (completion) {
            completion();
        }
    }];
}

- (void)dismissViewControllerAnimated:
    (BOOL)animated
    completion:(void (^)(void))completion {

    UIWindow *appWindow =
        self.window.previousKeyWindow;

    [appWindow makeKeyWindow];

    [appWindow.rootViewController
        setNeedsStatusBarAppearanceUpdate];

    UIMenuController.sharedMenuController.menuItems =
        self.appMenuItems;

    [UIMenuController.sharedMenuController
        update];

    self.appMenuItems = nil;

    UIWindow *statusWindow =
        [self statusWindow];

    if (statusWindow) {
        statusWindow.windowLevel =
            UIWindowLevelStatusBar;
    }

    [self updateButtonStates];

    [super
        dismissViewControllerAnimated:animated
                          completion:^{

        [self updateButtonStates];

        if (completion) {
            completion();
        }
    }];
}

- (BOOL)wantsWindowToBecomeKey {

    return self.window.previousKeyWindow != nil;
}

- (void)toggleToolWithViewControllerProvider:
    (UINavigationController *(^)(void))future
    completion:(void (^)(void))completion {

    if (self.presentedViewController) {

        [self
            dismissViewControllerAnimated:YES
                               completion:completion];

    } else if (future) {

        [self
            presentViewController:future()
                         animated:YES
                       completion:completion];
    }
}

- (void)presentTool:
    (UINavigationController *(^)(void))future
    completion:(void (^)(void))completion {

    if (self.presentedViewController) {

        [self
            dismissViewControllerAnimated:YES
                               completion:^{

            if (future) {

                [self
                    presentViewController:future()
                                 animated:YES
                               completion:completion];
            }
        }];

    } else if (future) {

        [self
            presentViewController:future()
                         animated:YES
                       completion:completion];
    }
}

- (AVX512Window *)window {

    return (id)self.view.window;
}

#pragma mark - Keyboard Shortcut Helpers

- (void)toggleSelectTool {

    if (self.currentMode ==
        AVX512ExplorerModeSelect) {

        [self cancelPendingLiveViewSelection];

        self.currentMode =
            AVX512ExplorerModeDefault;

    } else {

        self.currentMode =
            AVX512ExplorerModeSelect;
    }
}

- (void)toggleMoveTool {

    if (self.currentMode ==
        AVX512ExplorerModeMove) {

        self.currentMode =
            AVX512ExplorerModeSelect;

    } else if (
        self.currentMode ==
            AVX512ExplorerModeSelect &&
        self.selectedView) {

        self.currentMode =
            AVX512ExplorerModeMove;
    }
}

- (void)toggleViewsTool {

    [self toggleViewsToolWithCompletion:nil];
}

- (void)toggleViewsToolWithCompletion:
    (void (^)(void))completion {

    [self
        toggleToolWithViewControllerProvider:
            ^UINavigationController *{

        if (self.selectedView) {

            return
                [AVX512HierarchyViewController
                    delegate:self
                    viewsAtTap:self.viewsAtTapPoint
                    selectedView:self.selectedView];

        } else {

            return
                [AVX512HierarchyViewController
                    delegate:self];
        }

    } completion:completion];
}

- (void)toggleMenuTool {

    [self
        toggleToolWithViewControllerProvider:
            ^UINavigationController *{

        return
            [AVX512NavigationController
                withRootViewController:
                    [AVX512GlobalsViewController new]];

    } completion:nil];
}

- (BOOL)handleDownArrowKeyPressed {

    if (self.currentMode ==
        AVX512ExplorerModeMove) {

        if (!self.selectedView) {
            return NO;
        }

        CGRect frame =
            self.selectedView.frame;

        frame.origin.y +=
            1.0 / UIScreen.mainScreen.scale;

        self.selectedView.frame =
            frame;

    } else if (
        self.currentMode ==
            AVX512ExplorerModeSelect &&
        self.viewsAtTapPoint.count > 0) {

        NSInteger selectedViewIndex =
            [self.viewsAtTapPoint
                indexOfObject:self.selectedView];

        if (selectedViewIndex > 0) {

            self.selectedView =
                self.viewsAtTapPoint[
                    selectedViewIndex - 1
                ];

        } else {

            return NO;
        }

    } else {

        return NO;
    }

    return YES;
}

- (BOOL)handleUpArrowKeyPressed {

    if (self.currentMode ==
        AVX512ExplorerModeMove) {

        if (!self.selectedView) {
            return NO;
        }

        CGRect frame =
            self.selectedView.frame;

        frame.origin.y -=
            1.0 / UIScreen.mainScreen.scale;

        self.selectedView.frame =
            frame;

    } else if (
        self.currentMode ==
            AVX512ExplorerModeSelect &&
        self.viewsAtTapPoint.count > 0) {

        NSInteger selectedViewIndex =
            [self.viewsAtTapPoint
                indexOfObject:self.selectedView];

        if (selectedViewIndex <
            self.viewsAtTapPoint.count - 1) {

            self.selectedView =
                self.viewsAtTapPoint[
                    selectedViewIndex + 1
                ];

        } else {

            return NO;
        }

    } else {

        return NO;
    }

    return YES;
}

- (BOOL)handleRightArrowKeyPressed {

    if (self.currentMode ==
        AVX512ExplorerModeMove) {

        if (!self.selectedView) {
            return NO;
        }

        CGRect frame =
            self.selectedView.frame;

        frame.origin.x +=
            1.0 / UIScreen.mainScreen.scale;

        self.selectedView.frame =
            frame;

        return YES;
    }

    return NO;
}

- (BOOL)handleLeftArrowKeyPressed {

    if (self.currentMode ==
        AVX512ExplorerModeMove) {

        if (!self.selectedView) {
            return NO;
        }

        CGRect frame =
            self.selectedView.frame;

        frame.origin.x -=
            1.0 / UIScreen.mainScreen.scale;

        self.selectedView.frame =
            frame;

        return YES;
    }

    return NO;
}

@end