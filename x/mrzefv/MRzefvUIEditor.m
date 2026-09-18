//
//  MRzefvUIEditor.m
//  AVX512
//
//  MRzefv UI Editor
//  AVX512 by DELvEK.NET
//

#import "MRzefvUIEditor.h"

#import "FLEXExplorerViewController.h"

#import <objc/runtime.h>

#pragma mark - MRzefvUIChange

@implementation MRzefvUIChange

@end

#pragma mark - MRzefvUIProfile

@implementation MRzefvUIProfile

- (instancetype)init {
    self = [super init];

    if (self) {
        _format = @"mrzefv-ui-profile";
        _version = 1;
        _changes = [NSMutableArray array];
    }

    return self;
}

- (void)addChange:(MRzefvUIChange *)change {
    if (!change) {
        return;
    }

    [self.changes addObject:change];
}

- (void)removeChange:(MRzefvUIChange *)change {
    if (!change) {
        return;
    }

    [self.changes removeObject:change];
}

- (void)removeAllChanges {
    [self.changes removeAllObjects];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableArray *serializedChanges =
        [NSMutableArray arrayWithCapacity:self.changes.count];

    for (MRzefvUIChange *change in self.changes) {
        NSMutableDictionary *dictionary =
            [NSMutableDictionary dictionary];

        dictionary[@"type"] = @(change.type);

        if (change.targetClass.length) {
            dictionary[@"targetClass"] = change.targetClass;
        }

        if (change.hierarchyPath.length) {
            dictionary[@"hierarchyPath"] = change.hierarchyPath;
        }

        if (change.propertyName.length) {
            dictionary[@"propertyName"] = change.propertyName;
        }

        if (change.originalValue.length) {
            dictionary[@"originalValue"] = change.originalValue;
        }

        if (change.replacementValue.length) {
            /*
             * Keep the on-disk JSON key as "newValue".
             *
             * The Objective-C property is intentionally named
             * replacementValue because "newValue" conflicts with
             * Objective-C method-family naming rules.
             */
            dictionary[@"newValue"] = change.replacementValue;
        }

        if (change.type == MRzefvUIChangeTypeFrame) {
            dictionary[@"frame"] = @{
                @"x": @(change.frame.origin.x),
                @"y": @(change.frame.origin.y),
                @"width": @(change.frame.size.width),
                @"height": @(change.frame.size.height)
            };
        }

        if (change.type == MRzefvUIChangeTypeAlignment) {
            dictionary[@"alignment"] = @(change.alignment);
        }

        [serializedChanges addObject:dictionary];
    }

    return @{
        @"format": self.format ?: @"mrzefv-ui-profile",
        @"version": @(self.version),
        @"changes": serializedChanges
    };
}

- (NSData *)JSONData {
    NSError *error = nil;

    NSData *data =
        [NSJSONSerialization dataWithJSONObject:self.dictionaryRepresentation
                                        options:NSJSONWritingPrettyPrinted
                                          error:&error];

    if (error) {
        NSLog(@"[MRzefv] Failed to serialize profile: %@", error);
        return nil;
    }

    return data;
}

@end

#pragma mark - MRzefvUIEditorController

@interface MRzefvUIEditorController ()

@property (nonatomic, strong) MRzefvUIProfile *profile;

@end

@implementation MRzefvUIEditorController

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _profile = [[MRzefvUIProfile alloc] init];
        self.title = @"MRzefv UI Editor";
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"MRzefv UI Editor";

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                 target:self
                                 action:@selector(saveCurrentProfile)];

    [self.tableView registerClass:UITableViewCell.class
           forCellReuseIdentifier:@"MRzefvCell"];
}

#pragma mark - Explorer Lookup

/// Searches from a controller through its presentation/navigation/child
/// hierarchy until the existing AVX512 Explorer is found.
- (AVX512ExplorerViewController *)findExplorerFromViewController:
    (UIViewController *)controller {

    if (!controller) {
        return nil;
    }

    if ([controller isKindOfClass:AVX512ExplorerViewController.class]) {
        return (AVX512ExplorerViewController *)controller;
    }

    /*
     * If MRzefv is presented by the Explorer, this is normally the
     * fastest path back to it.
     */
    if (controller.presentingViewController) {
        AVX512ExplorerViewController *explorer =
            [self findExplorerFromViewController:
                controller.presentingViewController];

        if (explorer) {
            return explorer;
        }
    }

    if (controller.navigationController &&
        controller.navigationController != controller) {

        AVX512ExplorerViewController *explorer =
            [self findExplorerFromViewController:
                controller.navigationController];

        if (explorer) {
            return explorer;
        }
    }

    for (UIViewController *child in controller.childViewControllers) {
        AVX512ExplorerViewController *explorer =
            [self findExplorerFromViewController:child];

        if (explorer) {
            return explorer;
        }
    }

    return nil;
}

/// Fallback lookup through the application's active window hierarchy.
- (AVX512ExplorerViewController *)avx512ExplorerViewController {
    UIWindow *keyWindow = nil;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene
             in UIApplication.sharedApplication.connectedScenes) {

            if (![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }

            UIWindowScene *windowScene =
                (UIWindowScene *)scene;

            if (windowScene.activationState ==
                UISceneActivationStateUnattached) {
                continue;
            }

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }

            if (keyWindow) {
                break;
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!keyWindow) {
        keyWindow = UIApplication.sharedApplication.keyWindow;
    }
#pragma clang diagnostic pop

    if (!keyWindow) {
        return nil;
    }

    UIViewController *controller =
        keyWindow.rootViewController;

    while (controller) {
        if ([controller isKindOfClass:
                AVX512ExplorerViewController.class]) {

            return (AVX512ExplorerViewController *)controller;
        }

        UIViewController *next = nil;

        if (controller.presentedViewController) {
            next = controller.presentedViewController;
        } else if (controller.navigationController &&
                   controller.navigationController != controller) {
            next = controller.navigationController;
        } else if (controller.childViewControllers.count > 0) {
            next = controller.childViewControllers.lastObject;
        }

        if (!next || next == controller) {
            break;
        }

        controller = next;
    }

    return nil;
}

#pragma mark - MRzefv Selection Handoff

- (void)beginViewSelection {
    AVX512ExplorerViewController *explorer =
        [self findExplorerFromViewController:self];

    if (!explorer) {
        explorer = [self avx512ExplorerViewController];
    }

    if (!explorer) {
        UIAlertController *alert =
            [UIAlertController
                alertControllerWithTitle:@"MRzefv UI Editor"
                message:@"The AVX512 live-view explorer could not be found."
                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:
            [UIAlertAction
                actionWithTitle:@"OK"
                style:UIAlertActionStyleDefault
                handler:nil]];

        [self presentViewController:alert
                           animated:YES
                         completion:nil];

        return;
    }

    __weak typeof(self) weakSelf = self;

    /*
     * The Explorer owns the actual live-view selection system.
     *
     * MRzefv does not install another gesture recognizer, perform its
     * own hit-testing, or create another selection overlay.
     *
     * The Explorer temporarily dismisses the editor, activates its
     * existing Select mode, and terminates this request in exactly
     * one of two ways:
     *
     *   selectedView != nil, cancelled == NO
     *       User selected a UIView.
     *
     *   selectedView == nil, cancelled == YES
     *       User cancelled selection, for example by pressing Close.
     */
    [explorer
        beginLiveViewSelectionWithCompletion:
            ^(UIView *selectedView, BOOL cancelled) {

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;

            if (!self) {
                return;
            }

            /*
             * Only replace the selected view on an actual successful
             * selection. A cancellation leaves the previous selection
             * intact.
             */
            if (!cancelled && selectedView) {
                self.selectedView = selectedView;

                NSLog(@"[MRzefv] Live view selected: %@ <%p>",
                      NSStringFromClass(selectedView.class),
                      selectedView);
            } else {
                NSLog(@"[MRzefv] Live view selection cancelled.");
            }

            /*
             * Regardless of success or cancellation, return to MRzefv.
             */
            [self presentEditorAfterSelectionFromExplorer:explorer];
        });
    }];
}

- (void)presentEditorAfterSelectionFromExplorer:
    (AVX512ExplorerViewController *)explorer {

    if (!explorer) {
        return;
    }

    /*
     * The Explorer's dismissal completion and the selection callback
     * can occur around the same run-loop boundary. Give UIKit a clean
     * main-thread turn before presenting the editor again.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        /*
         * If another controller is already being presented, don't
         * stack another copy of MRzefv on top of it.
         */
        if (explorer.presentedViewController) {
            UIViewController *presented =
                explorer.presentedViewController;

            /*
             * If this is already our editor navigation controller,
             * simply refresh the table.
             */
            if ([presented isKindOfClass:UINavigationController.class] &&
                ((UINavigationController *)presented).viewControllers.firstObject
                    == self) {

                [self.tableView reloadData];
                return;
            }

            /*
             * UIKit is still transitioning away from another controller.
             * Try once on the next main-loop turn.
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!explorer.presentedViewController) {
                    [self presentEditorAfterSelectionFromExplorer:explorer];
                }
            });

            return;
        }

        /*
         * Do not create a second MRzefv controller. Reuse this exact
         * controller so the existing profile and selectedView survive
         * the handoff.
         */
        UINavigationController *navigationController =
            [[UINavigationController alloc]
                initWithRootViewController:self];

        navigationController.modalPresentationStyle =
            UIModalPresentationFormSheet;

        [explorer
            presentViewController:navigationController
                         animated:YES
                       completion:^{
            [self.tableView reloadData];
        }];
    });
}

#pragma mark - Preview

- (void)beginPreview {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    NSLog(@"[MRzefv] Beginning live preview for %@ <%p>",
          NSStringFromClass(view.class),
          view);

    /*
     * Live changes are applied directly to the selected UIView.
     * Each change is recorded in the MRzefv profile for later
     * persistence / dylib generation.
     */
}

- (void)resetPreview {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    /*
     * Walk backwards so the most recent change is restored first.
     */
    for (MRzefvUIChange *change
         in self.profile.changes.reverseObjectEnumerator) {

        if (change.targetClass.length &&
            ![NSStringFromClass(view.class)
                isEqualToString:change.targetClass]) {
            continue;
        }

        if (change.type == MRzefvUIChangeTypeText &&
            change.propertyName.length &&
            change.originalValue) {

            if ([view isKindOfClass:UILabel.class] &&
                [change.propertyName isEqualToString:@"text"]) {

                ((UILabel *)view).text =
                    change.originalValue;

            } else if ([view isKindOfClass:UITextField.class] &&
                       [change.propertyName isEqualToString:@"text"]) {

                ((UITextField *)view).text =
                    change.originalValue;

            } else if ([view isKindOfClass:UITextView.class] &&
                       [change.propertyName isEqualToString:@"text"]) {

                ((UITextView *)view).text =
                    change.originalValue;

            } else if ([view isKindOfClass:UIButton.class] &&
                       [change.propertyName isEqualToString:@"title"]) {

                [(UIButton *)view
                    setTitle:change.originalValue
                    forState:UIControlStateNormal];
            }
        }

        if (change.type == MRzefvUIChangeTypeHidden) {
            view.hidden = NO;
        }

        if (change.type == MRzefvUIChangeTypeFrame) {
            /*
             * Frame changes are restored only when the original
             * frame was explicitly represented by the change.
             */
        }

        if (change.type == MRzefvUIChangeTypeAlignment) {
            if ([view isKindOfClass:UILabel.class] &&
                [change.propertyName isEqualToString:@"textAlignment"]) {

                ((UILabel *)view).textAlignment =
                    (NSTextAlignment)
                    change.originalValue.integerValue;

            } else if ([view isKindOfClass:UITextField.class] &&
                       [change.propertyName isEqualToString:@"textAlignment"]) {

                ((UITextField *)view).textAlignment =
                    (NSTextAlignment)
                    change.originalValue.integerValue;

            } else if ([view isKindOfClass:UITextView.class] &&
                       [change.propertyName isEqualToString:@"textAlignment"]) {

                ((UITextView *)view).textAlignment =
                    (NSTextAlignment)
                    change.originalValue.integerValue;
            }
        }
    }

    [self.profile removeAllChanges];

    [self.tableView reloadData];
}

#pragma mark - Text Editing

- (void)changeText {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    NSString *currentText = nil;

    if ([view isKindOfClass:UILabel.class]) {
        currentText = ((UILabel *)view).text;

    } else if ([view isKindOfClass:UITextField.class]) {
        currentText = ((UITextField *)view).text;

    } else if ([view isKindOfClass:UITextView.class]) {
        currentText = ((UITextView *)view).text;

    } else if ([view isKindOfClass:UIButton.class]) {
        currentText =
            [((UIButton *)view)
                titleForState:UIControlStateNormal];
    }

    if (!currentText) {
        currentText = @"";
    }

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Change Text"
            message:@"Enter replacement text."
            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:
        ^(UITextField *textField) {
        textField.text = currentText;
        textField.clearButtonMode =
            UITextFieldViewModeWhileEditing;
    }];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
            style:UIAlertActionStyleCancel
            handler:nil]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Apply"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {

        __strong typeof(weakSelf) self = weakSelf;

        if (!self) {
            return;
        }

        NSString *replacement =
            alert.textFields.firstObject.text ?: @"";

        UIView *selectedView = self.selectedView;

        if ([selectedView isKindOfClass:UILabel.class]) {
            ((UILabel *)selectedView).text = replacement;

        } else if ([selectedView isKindOfClass:UITextField.class]) {
            ((UITextField *)selectedView).text = replacement;

        } else if ([selectedView isKindOfClass:UITextView.class]) {
            ((UITextView *)selectedView).text = replacement;

        } else if ([selectedView isKindOfClass:UIButton.class]) {
            [(UIButton *)selectedView
                setTitle:replacement
                forState:UIControlStateNormal];

        } else {
            return;
        }

        MRzefvUIChange *change =
            [[MRzefvUIChange alloc] init];

        change.type = MRzefvUIChangeTypeText;
        change.targetClass =
            NSStringFromClass(selectedView.class);
        change.propertyName = @"text";
        change.originalValue = currentText;
        change.replacementValue = replacement;

        [self.profile addChange:change];

        [self.tableView reloadData];
    }];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - Hidden

- (void)toggleHidden {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    BOOL oldHidden = view.hidden;

    view.hidden = !view.hidden;

    MRzefvUIChange *change =
        [[MRzefvUIChange alloc] init];

    change.type = MRzefvUIChangeTypeHidden;
    change.targetClass =
        NSStringFromClass(view.class);
    change.propertyName = @"hidden";
    change.originalValue =
        oldHidden ? @"YES" : @"NO";
    change.replacementValue =
        view.hidden ? @"YES" : @"NO";

    [self.profile addChange:change];

    [self.tableView reloadData];
}

#pragma mark - Alignment

- (void)changeAlignment {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    NSTextAlignment alignment =
        NSTextAlignmentNatural;

    if ([view isKindOfClass:UILabel.class]) {
        alignment = ((UILabel *)view).textAlignment;

    } else if ([view isKindOfClass:UITextField.class]) {
        alignment = ((UITextField *)view).textAlignment;

    } else if ([view isKindOfClass:UITextView.class]) {
        alignment = ((UITextView *)view).textAlignment;

    } else {
        return;
    }

    NSArray<NSString *> *names = @[
        @"Natural",
        @"Left",
        @"Center",
        @"Right",
        @"Justified"
    ];

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Text Alignment"
            message:nil
            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;

    for (NSUInteger index = 0;
         index < names.count;
         index++) {

        [alert addAction:
            [UIAlertAction
                actionWithTitle:names[index]
                style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *action) {

            __strong typeof(weakSelf) self = weakSelf;

            if (!self) {
                return;
            }

            NSTextAlignment newAlignment =
                (NSTextAlignment)index;

            if ([view isKindOfClass:UILabel.class]) {
                ((UILabel *)view).textAlignment =
                    newAlignment;

            } else if ([view isKindOfClass:UITextField.class]) {
                ((UITextField *)view).textAlignment =
                    newAlignment;

            } else if ([view isKindOfClass:UITextView.class]) {
                ((UITextView *)view).textAlignment =
                    newAlignment;
            }

            MRzefvUIChange *change =
                [[MRzefvUIChange alloc] init];

            change.type =
                MRzefvUIChangeTypeAlignment;

            change.targetClass =
                NSStringFromClass(view.class);

            change.propertyName =
                @"textAlignment";

            change.originalValue =
                [NSString stringWithFormat:@"%ld",
                    (long)alignment];

            change.replacementValue =
                [NSString stringWithFormat:@"%ld",
                    (long)newAlignment];

            change.alignment = newAlignment;

            [self.profile addChange:change];

            [self.tableView reloadData];
        }];
    }

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
            style:UIAlertActionStyleCancel
            handler:nil]];

    alert.popoverPresentationController.sourceView =
        self.tableView;

    alert.popoverPresentationController.sourceRect =
        [self.tableView
            rectForRowAtIndexPath:
                [NSIndexPath indexPathForRow:0
                                   inSection:0]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - Frame

- (void)changeFrame {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    CGRect oldFrame = view.frame;

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Move View"
            message:@"Enter X and Y offsets."
            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:
        ^(UITextField *textField) {

        textField.placeholder = @"X offset";
        textField.keyboardType =
            UIKeyboardTypeNumbersAndPunctuation;
        textField.text = @"0";
    }];

    [alert addTextFieldWithConfigurationHandler:
        ^(UITextField *textField) {

        textField.placeholder = @"Y offset";
        textField.keyboardType =
            UIKeyboardTypeNumbersAndPunctuation;
        textField.text = @"0";
    }];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
            style:UIAlertActionStyleCancel
            handler:nil]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Apply"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {

        __strong typeof(weakSelf) self = weakSelf;

        if (!self) {
            return;
        }

        CGFloat dx =
            [alert.textFields[0].text doubleValue];

        CGFloat dy =
            [alert.textFields[1].text doubleValue];

        CGRect newFrame = oldFrame;

        newFrame.origin.x += dx;
        newFrame.origin.y += dy;

        view.frame = newFrame;

        MRzefvUIChange *change =
            [[MRzefvUIChange alloc] init];

        change.type = MRzefvUIChangeTypeFrame;
        change.targetClass =
            NSStringFromClass(view.class);
        change.propertyName = @"frame";
        change.frame = newFrame;

        [self.profile addChange:change];

        [self.tableView reloadData];
    }];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - Add Text

- (void)addText {
    UIView *container = self.selectedView;

    if (!container) {
        return;
    }

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Add Text"
            message:@"Enter text for the new label."
            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:
        ^(UITextField *textField) {
        textField.placeholder = @"Text";
    }];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
            style:UIAlertActionStyleCancel
            handler:nil]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Add"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {

        __strong typeof(weakSelf) self = weakSelf;

        if (!self) {
            return;
        }

        NSString *text =
            alert.textFields.firstObject.text ?: @"";

        UILabel *label =
            [[UILabel alloc]
                initWithFrame:
                    CGRectMake(10, 10, 200, 30)];

        label.text = text;
        label.textColor = UIColor.labelColor;
        label.backgroundColor = UIColor.clearColor;
        label.userInteractionEnabled = YES;

        [container addSubview:label];

        MRzefvUIChange *change =
            [[MRzefvUIChange alloc] init];

        change.type =
            MRzefvUIChangeTypeAddText;

        change.targetClass =
            NSStringFromClass(container.class);

        change.propertyName = @"subviews";
        change.replacementValue = text;
        change.frame = label.frame;

        [self.profile addChange:change];

        [self.tableView reloadData];
    }];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - Save

- (void)saveCurrentProfile {
    NSData *data = [self.profile JSONData];

    if (!data) {
        return;
    }

    NSURL *documentsURL =
        [[[NSFileManager defaultManager]
            URLsForDirectory:NSDocumentDirectory
            inDomains:NSUserDomainMask]
            firstObject];

    if (!documentsURL) {
        return;
    }

    NSURL *profileURL =
        [documentsURL
            URLByAppendingPathComponent:
                @"MRzefv-ui-profile.json"];

    NSError *error = nil;

    BOOL success =
        [data writeToURL:profileURL
                 options:NSDataWritingAtomic
                   error:&error];

    UIAlertController *alert = nil;

    if (success) {
        NSLog(@"[MRzefv] Saved profile: %@",
              profileURL.path);

        alert =
            [UIAlertController
                alertControllerWithTitle:@"Profile Saved"
                message:profileURL.path
                preferredStyle:UIAlertControllerStyleAlert];

    } else {
        NSLog(@"[MRzefv] Failed to save profile: %@",
              error);

        alert =
            [UIAlertController
                alertControllerWithTitle:@"Save Failed"
                message:error.localizedDescription
                preferredStyle:UIAlertControllerStyleAlert];
    }

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:
    (UITableView *)tableView {

    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0:
            return 1;

        case 1:
            return 5;

        case 2:
            return 1;

        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section {

    switch (section) {
        case 0:
            return @"Selection";

        case 1:
            return @"Live Editor";

        case 2:
            return @"Profile";

        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell =
        [tableView
            dequeueReusableCellWithIdentifier:@"MRzefvCell"
            forIndexPath:indexPath];

    cell.accessoryType =
        UITableViewCellAccessoryDisclosureIndicator;

    cell.textLabel.textColor =
        UIColor.labelColor;

    switch (indexPath.section) {

        case 0: {
            if (self.selectedView) {
                cell.textLabel.text =
                    [NSString
                        stringWithFormat:@"Selected: %@",
                        NSStringFromClass(
                            self.selectedView.class)];
            } else {
                cell.textLabel.text =
                    @"Select Live View";
            }

            cell.imageView.image =
                [UIImage systemImageNamed:@"scope"];

            break;
        }

        case 1: {
            NSArray<NSString *> *titles = @[
                @"Change Text",
                @"Hide / Show",
                @"Alignment",
                @"Move / Frame",
                @"Add Text"
            ];

            NSArray<NSString *> *icons = @[
                @"character.cursor.ibeam",
                @"eye.slash",
                @"text.alignleft",
                @"arrow.up.left.and.arrow.down.right",
                @"plus.rectangle"
            ];

            cell.textLabel.text =
                titles[indexPath.row];

            cell.imageView.image =
                [UIImage
                    systemImageNamed:
                        icons[indexPath.row]];

            if (self.selectedView) {
                cell.accessoryType =
                    UITableViewCellAccessoryDisclosureIndicator;

                cell.textLabel.textColor =
                    UIColor.labelColor;
            } else {
                cell.accessoryType =
                    UITableViewCellAccessoryNone;

                cell.textLabel.textColor =
                    UIColor.secondaryLabelColor;
            }

            break;
        }

        case 2:
            cell.textLabel.text =
                @"Save Current Profile";

            cell.imageView.image =
                [UIImage
                    systemImageNamed:
                        @"square.and.arrow.down"];

            break;

        default:
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];

    switch (indexPath.section) {

        case 0:
            [self beginViewSelection];
            break;

        case 1:
            if (!self.selectedView) {
                return;
            }

            switch (indexPath.row) {
                case 0:
                    [self changeText];
                    break;

                case 1:
                    [self toggleHidden];
                    break;

                case 2:
                    [self changeAlignment];
                    break;

                case 3:
                    [self changeFrame];
                    break;

                case 4:
                    [self addText];
                    break;

                default:
                    break;
            }

            break;

        case 2:
            [self saveCurrentProfile];
            break;

        default:
            break;
    }
}

@end