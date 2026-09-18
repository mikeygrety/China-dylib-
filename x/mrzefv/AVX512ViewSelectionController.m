//
//  AVX512ViewSelectionController.m
//  AVX512 / MRzefv
//
//  View selection interaction:
//  - Walk the visible view hierarchy
//  - Highlight the currently targeted view
//  - Allow the user to confirm the glowing view
//  - Transition into the view editor
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#pragma mark - Forward Declarations
@interface AVX512ViewEditorController : UIViewController
@property (nonatomic, strong) UIView *targetView;
- (instancetype)initWithTargetView:(UIView *)view;
@end
#pragma mark - Selection Controller
@interface AVX512ViewSelectionController : NSObject
@property (nonatomic, weak) UIWindow *window;
@property (nonatomic, strong) UIView *selectedView;
@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, assign) BOOL selecting;
@property (nonatomic, assign) BOOL transitioningToEditor;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
+ (instancetype)sharedController;
- (void)beginSelectionInWindow:(UIWindow *)window;
- (void)stopSelection;
- (void)selectView:(UIView *)view;
- (void)confirmSelection;
@end
#pragma mark - Implementation
@implementation AVX512ViewSelectionController
+ (instancetype)sharedController
{
    static AVX512ViewSelectionController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[AVX512ViewSelectionController alloc] init];
    });
    return controller;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _selecting = NO;
        _transitioningToEditor = NO;
    }
    return self;
}
#pragma mark - Selection
- (void)beginSelectionInWindow:(UIWindow *)window
{
    if (!window) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window = window;
        self.selecting = YES;
        self.transitioningToEditor = NO;
        [self installGestures];
        if (!self.highlightView) {
            self.highlightView = [[UIView alloc] initWithFrame:CGRectZero];
            self.highlightView.backgroundColor =
                [[UIColor systemBlueColor] colorWithAlphaComponent:0.08];
            self.highlightView.layer.borderWidth = 2.0;
            self.highlightView.layer.borderColor =
                [UIColor systemBlueColor].CGColor;
            self.highlightView.userInteractionEnabled = NO;
            self.highlightView.hidden = YES;
            [window addSubview:self.highlightView];
        }
    });
}
- (void)stopSelection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.selecting = NO;
        [self removeGestures];
        self.highlightView.hidden = YES;
        self.selectedView = nil;
    });
}
#pragma mark - Gestures
- (void)installGestures
{
    [self removeGestures];
    self.tapGesture =
        [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(handleTap:)];
    self.tapGesture.cancelsTouchesInView = NO;
    self.doubleTapGesture =
        [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(handleDoubleTap:)];
    self.doubleTapGesture.numberOfTapsRequired = 2;
    self.doubleTapGesture.cancelsTouchesInView = NO;
    [self.window addGestureRecognizer:self.tapGesture];
    [self.window addGestureRecognizer:self.doubleTapGesture];
    [self.tapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
}
- (void)removeGestures
{
    if (self.tapGesture) {
        [self.window removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    if (self.doubleTapGesture) {
        [self.window removeGestureRecognizer:self.doubleTapGesture];
        self.doubleTapGesture = nil;
    }
}
#pragma mark - Touch Handling
- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    if (!self.selecting || self.transitioningToEditor) {
        return;
    }
    CGPoint point =
        [gesture locationInView:self.window];
    UIView *view =
        [self deepestViewAtPoint:point
                        inView:self.window];
    if (!view) {
        return;
    }
    /*
     Don't select AVX512's own overlay/UI.
     */
    if ([self isAVX512View:view]) {
        return;
    }
    [self selectView:view];
}
- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture
{
    if (!self.selecting || self.transitioningToEditor) {
        return;
    }
    if (!self.selectedView) {
        return;
    }
    [self confirmSelection];
}
#pragma mark - View Selection
- (void)selectView:(UIView *)view
{
    if (!view) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.selectedView = view;
        [self updateHighlightForView:view];
        /*
         A short visual pulse makes the selection state obvious.
         */
        self.highlightView.alpha = 0.0;
        self.highlightView.hidden = NO;
        [UIView animateWithDuration:0.12
                              animations:^{
            self.highlightView.alpha = 1.0;
        }];
    });
}
- (void)updateHighlightForView:(UIView *)view
{
    if (!view || !self.highlightView) {
        return;
    }
    if (!view.window) {
        return;
    }
    CGRect rect =
        [view convertRect:view.bounds
                  toView:self.window];
    self.highlightView.frame = rect;
    self.highlightView.layer.cornerRadius =
        MIN(8.0, CGRectGetHeight(rect) * 0.12);
    /*
     Put the highlight above the selected view without
     changing the target view itself.
     */
    [self.window bringSubviewToFront:self.highlightView];
}
#pragma mark - Confirmation
- (void)confirmSelection
{
    UIView *view = self.selectedView;
    if (!view || self.transitioningToEditor) {
        return;
    }
    self.transitioningToEditor = YES;
    [self pulseConfirmation:^{
        [self openEditorForView:view];
    }];
}
- (void)pulseConfirmation:(void (^)(void))completion
{
    self.highlightView.layer.borderWidth = 3.0;
    [UIView animateWithDuration:0.10
                          animations:^{
        self.highlightView.transform =
            CGAffineTransformMakeScale(1.04, 1.04);
        self.highlightView.alpha = 0.45;
    }
                     completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12
                         animations:^{
            self.highlightView.transform =
                CGAffineTransformIdentity;
            self.highlightView.alpha = 1.0;
        }
                         completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }];
}
#pragma mark - Editor Transition
- (void)openEditorForView:(UIView *)view
{
    if (!view) {
        self.transitioningToEditor = NO;
        return;
    }
    UIViewController *presentingController =
        [self topViewControllerForWindow:self.window];
    if (!presentingController) {
        self.transitioningToEditor = NO;
        return;
    }
    AVX512ViewEditorController *editor =
        [[AVX512ViewEditorController alloc]
            initWithTargetView:view];
    editor.modalPresentationStyle =
        UIModalPresentationPageSheet;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet =
            editor.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[
                [UISheetPresentationControllerDetent mediumDetent],
                [UISheetPresentationControllerDetent largeDetent]
            ];
            sheet.prefersGrabberVisible = YES;
        }
    }
    [self stopSelection];
    [presentingController
        presentViewController:editor
                     animated:YES
                   completion:^{
        self.transitioningToEditor = NO;
    }];
}
#pragma mark - Hit Testing
- (UIView *)deepestViewAtPoint:(CGPoint)point
                       inView:(UIView *)root
{
    if (!root ||
        root.hidden ||
        root.alpha <= 0.01 ||
        root.userInteractionEnabled == NO) {
        /*
         UIWindow itself is still traversable.
         */
        if (root != self.window) {
            return nil;
        }
    }
    NSArray<UIView *> *subviews =
        [root.subviews copy];
    /*
     Traverse from frontmost to backmost.
     */
    for (UIView *subview in [subviews reverseObjectEnumerator]) {
        if (subview.hidden ||
            subview.alpha <= 0.01) {
            continue;
        }
        CGPoint localPoint =
            [root convertPoint:point
                        toView:subview];
        if (![subview pointInside:localPoint
                        withEvent:nil]) {
            continue;
        }
        UIView *deepest =
            [self deepestViewAtPoint:localPoint
                             inView:subview];
        if (deepest) {
            return deepest;
        }
        return subview;
    }
    CGPoint localPoint =
        [root convertPoint:point
                    fromView:self.window];
    if ([root pointInside:localPoint
               withEvent:nil]) {
        return root;
    }
    return nil;
}
#pragma mark - AVX512 Filtering
- (BOOL)isAVX512View:(UIView *)view
{
    if (!view) {
        return YES;
    }
    /*
     Walk the view's controller hierarchy and identify
     views belonging to the inspector itself.
     This is intentionally class-name based so the generated
     dylib does not need to know anything about AVX512's
     private UI implementation.
     */
    Class cls = object_getClass(view);
    while (cls) {
        NSString *name = NSStringFromClass(cls);
        if ([name hasPrefix:@"AVX512"] ||
            [name hasPrefix:@"MRzefv"]) {
            return YES;
        }
        cls = class_getSuperclass(cls);
    }
    return NO;
}
#pragma mark - View Controller Resolution
- (UIViewController *)topViewControllerForWindow:(UIWindow *)window
{
    if (!window) {
        return nil;
    }
    UIViewController *controller =
        window.rootViewController;
    while (controller) {
        UIViewController *next = nil;
        if (controller.presentedViewController &&
            !controller.presentedViewController.isBeingDismissed) {
            next = controller.presentedViewController;
        } else if ([controller isKindOfClass:
                   [UINavigationController class]]) {
            next =
                [(UINavigationController *)controller
                    visibleViewController];
        } else if ([controller isKindOfClass:
                   [UITabBarController class]]) {
            next =
                [(UITabBarController *)controller
                    selectedViewController];
        } else if ([controller isKindOfClass:
                   [UISplitViewController class]]) {
            next =
                [(UISplitViewController *)controller
                    viewControllers].lastObject;
        }
        if (!next || next == controller) {
            break;
        }
        controller = next;
    }
    return controller;
}
@end