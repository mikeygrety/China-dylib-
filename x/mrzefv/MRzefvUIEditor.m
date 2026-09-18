//
//  MRzefvUIEditor.m
//  AVX512
//
//  MRzefv UI Editor
//  AVX512 by DELvEK.NET
//

#import "MRzefvUIEditor.h"

#import "AVX512ExplorerViewController.h"

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
    NSMutableArray *changeObjects = [NSMutableArray array];

    for (MRzefvUIChange *change in self.changes) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

        dictionary[@"type"] = @(change.type);

        if (change.targetClass) {
            dictionary[@"targetClass"] = change.targetClass;
        }

        if (change.hierarchyPath) {
            dictionary[@"hierarchyPath"] = change.hierarchyPath;
        }

        if (change.propertyName) {
            dictionary[@"propertyName"] = change.propertyName;
        }

        if (change.originalValue) {
            dictionary[@"originalValue"] = change.originalValue;
        }

        if (change.replacementValue) {
            // Keep the external profile format as "newValue".
            dictionary[@"newValue"] = change.replacementValue;
        }

        if (!CGRectIsEmpty(change.frame)) {
            dictionary[@"frame"] = @{
                @"x": @(change.frame.origin.x),
                @"y": @(change.frame.origin.y),
                @"width": @(change.frame.size.width),
                @"height": @(change.frame.size.height)
            };
        }

        dictionary[@"alignment"] = @(change.alignment);

        [changeObjects addObject:dictionary];
    }

    return @{
        @"format": self.format ?: @"mrzefv-ui-profile",
        @"version": @(self.version),
        @"changes": changeObjects
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

@property (nonatomic, weak) AVX512ExplorerViewController *explorerViewController;

@property (nonatomic, weak) UIView *previewView;

@property (nonatomic) BOOL observingSelection;

@end

@implementation MRzefvUIEditorController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _profile = [[MRzefvUIProfile alloc] init];
        _observingSelection = NO;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"MRzefv UI Editor";

    self.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeNever;

    [self beginObservingExplorerSelection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self locateExplorerViewController];
    [self beginObservingExplorerSelection];

    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    /*
     * Do not remove the observer here.
     *
     * The editor may temporarily disappear while AVX512 Select mode
     * is being used. The controller needs to continue receiving the
     * selectedView notification when the live view is selected.
     */
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Explorer bridge

- (void)locateExplorerViewController {
    UIViewController *controller = self;

    while (controller) {
        if ([controller isKindOfClass:[AVX512ExplorerViewController class]]) {
            self.explorerViewController =
                (AVX512ExplorerViewController *)controller;
            return;
        }

        controller = controller.parentViewController;
    }

    /*
     * The editor is normally presented by the explorer rather than
     * being embedded inside it, so walk the presentation chain too.
     */
    controller = self.presentingViewController;

    while (controller) {
        if ([controller isKindOfClass:[AVX512ExplorerViewController class]]) {
            self.explorerViewController =
                (AVX512ExplorerViewController *)controller;
            return;
        }

        controller = controller.presentingViewController;
    }

    /*
     * Search the application windows as a final fallback.
     */
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        UIViewController *root = window.rootViewController;

        if ([root isKindOfClass:[AVX512ExplorerViewController class]]) {
            self.explorerViewController =
                (AVX512ExplorerViewController *)root;
            return;
        }
    }
}

- (void)beginObservingExplorerSelection {
    if (self.observingSelection) {
        return;
    }

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(explorerSelectedViewDidChange:)
               name:AVX512ExplorerSelectedViewDidChangeNotification
             object:nil];

    self.observingSelection = YES;

    [self locateExplorerViewController];

    if (self.explorerViewController.selectedView) {
        self.selectedView = self.explorerViewController.selectedView;
    }
}

- (void)explorerSelectedViewDidChange:(NSNotification *)notification {
    AVX512ExplorerViewController *explorer =
        notification.object;

    if (![explorer isKindOfClass:[AVX512ExplorerViewController class]]) {
        return;
    }

    self.explorerViewController = explorer;

    UIView *selectedView =
        notification.userInfo[@"selectedView"];

    if ((id)selectedView == [NSNull null]) {
        selectedView = nil;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.selectedView = selectedView;

        [self.tableView reloadSections:
            [NSIndexSet indexSetWithIndex:0]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

#pragma mark - Selection

- (void)beginViewSelection {
    [self locateExplorerViewController];

    AVX512ExplorerViewController *explorer =
        self.explorerViewController;

    if (!explorer) {
        NSLog(@"[MRzefv] Could not locate AVX512 explorer.");
        return;
    }

    /*
     * This is the important part:
     *
     * MRzefv does NOT perform its own hit testing.
     *
     * AVX512/FLEX owns selection, outlines, hit testing and
     * selectedView. We simply activate that existing Select mode.
     */
    [explorer toggleSelectTool];
}

#pragma mark - Preview

- (void)beginPreview {
    UIView *view = self.selectedView;

    if (!view) {
        [self showMessage:@"Select a live view first."];
        return;
    }

    self.previewView = view;

    NSLog(@"[MRzefv] Preview started for %@",
          NSStringFromClass(view.class));

    [self.tableView reloadData];
}

- (void)resetPreview {
    self.previewView = nil;

    NSLog(@"[MRzefv] Preview reset.");

    [self.tableView reloadData];
}

#pragma mark - Editing

- (void)changeText {
    UIView *view = self.selectedView;

    if (!view) {
        [self showMessage:@"Select a view first."];
        return;
    }

    NSString *currentText = nil;

    if ([view isKindOfClass:[UILabel class]]) {
        currentText = ((UILabel *)view).text;
    } else if ([view isKindOfClass:[UITextField class]]) {
        currentText = ((UITextField *)view).text;
    } else if ([view isKindOfClass:[UITextView class]]) {
        currentText = ((UITextView *)view).text;
    } else if ([view isKindOfClass:[UIButton class]]) {
        currentText =
            [((UIButton *)view) titleForState:UIControlStateNormal];
    }

    if (!currentText) {
        [self showMessage:@"The selected view does not expose editable text."];
        return;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Change Text"
                                            message:NSStringFromClass(view.class)
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = currentText;
        textField.placeholder = @"New text";
    }];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Apply"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {

        NSString *newText =
            alert.textFields.firstObject.text ?: @"";

        MRzefvUIChange *change =
            [[MRzefvUIChange alloc] init];

        change.type = MRzefvUIChangeTypeText;
        change.targetClass =
            NSStringFromClass(view.class);
        change.propertyName = @"text";
        change.originalValue = currentText;
        change.replacementValue = newText;

        [self.profile addChange:change];

        if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).text = newText;
        } else if ([view isKindOfClass:[UITextField class]]) {
            ((UITextField *)view).text = newText;
        } else if ([view isKindOfClass:[UITextView class]]) {
            ((UITextView *)view).text = newText;
        } else if ([view isKindOfClass:[UIButton class]]) {
            [((UIButton *)view) setTitle:newText
                                 forState:UIControlStateNormal];
        }

        [self.tableView reloadData];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toggleHidden {
    UIView *view = self.selectedView;

    if (!view) {
        [self showMessage:@"Select a view first."];
        return;
    }

    BOOL newHidden = !view.hidden;

    MRzefvUIChange *change =
        [[MRzefvUIChange alloc] init];

    change.type = MRzefvUIChangeTypeHidden;
    change.targetClass = NSStringFromClass(view.class);
    change.propertyName = @"hidden";
    change.originalValue = view.hidden ? @"YES" : @"NO";
    change.replacementValue = newHidden ? @"YES" : @"NO";

    [self.profile addChange:change];

    view.hidden = newHidden;

    [self.tableView reloadData];
}

- (void)changeAlignment {
    UIView *view = self.selectedView;

    if (!view) {
        [self showMessage:@"Select a view first."];
        return;
    }

    NSTextAlignment currentAlignment = NSTextAlignmentNatural;

    if ([view isKindOfClass:[UILabel class]]) {
        currentAlignment = ((UILabel *)view).textAlignment;
    } else if ([view isKindOfClass:[UITextField class]]) {
        currentAlignment = ((UITextField *)view).textAlignment;
    } else if ([view isKindOfClass:[UITextView class]]) {
        currentAlignment = ((UITextView *)view).textAlignment;
    } else {
        [self showMessage:@"The selected view does not support text alignment."];
        return;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Alignment"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray<NSDictionary *> *options = @[
        @{@"name": @"Natural", @"value": @(NSTextAlignmentNatural)},
        @{@"name": @"Left",    @"value": @(NSTextAlignmentLeft)},
        @{@"name": @"Center",  @"value": @(NSTextAlignmentCenter)},
        @{@"name": @"Right",   @"value": @(NSTextAlignmentRight)}
    ];

    for (NSDictionary *option in options) {
        [alert addAction:
            [UIAlertAction
                actionWithTitle:option[@"name"]
                          style:UIAlertActionStyleDefault
                        handler:^(UIAlertAction *action) {

            NSTextAlignment alignment =
                [option[@"value"] integerValue];

            MRzefvUIChange *change =
                [[MRzefvUIChange alloc] init];

            change.type = MRzefvUIChangeTypeAlignment;
            change.targetClass =
                NSStringFromClass(view.class);
            change.propertyName = @"textAlignment";
            change.originalValue =
                [NSString stringWithFormat:@"%ld",
                 (long)currentAlignment];
            change.replacementValue =
                [NSString stringWithFormat:@"%ld",
                 (long)alignment];
            change.alignment = alignment;

            [self.profile addChange:change];

            if ([view isKindOfClass:[UILabel class]]) {
                ((UILabel *)view).textAlignment = alignment;
            } else if ([view isKindOfClass:[UITextField class]]) {
                ((UITextField *)view).textAlignment = alignment;
            } else if ([view isKindOfClass:[UITextView class]]) {
                ((UITextView *)view).textAlignment = alignment;
            }

            [self.tableView reloadData];
        }]];
    }

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)changeFrame {
    UIView *view = self.selectedView;

    if (!view) {
        [self showMessage:@"Select a view first."];
        return;
    }

    CGRect oldFrame = view.frame;

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Frame"
                                            message:@"Enter x, y, width and height."
                                     preferredStyle:UIAlertControllerStyleAlert];

    NSArray<NSString *> *values = @[
        [NSString stringWithFormat:@"%.1f", oldFrame.origin.x],
        [NSString stringWithFormat:@"%.1f", oldFrame.origin.y],
        [NSString stringWithFormat:@"%.1f", oldFrame.size.width],
        [NSString stringWithFormat:@"%.1f", oldFrame.size.height]
    ];

    for (NSString *value in values) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.keyboardType = UIKeyboardTypeDecimalPad;
            field.text = value;
        }];
    }

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Apply"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {

        NSArray<UITextField *> *fields = alert.textFields;

        CGFloat x =
            fields.count > 0 ? fields[0].text.doubleValue : oldFrame.origin.x;

        CGFloat y =
            fields.count > 1 ? fields[1].text.doubleValue : oldFrame.origin.y;

        CGFloat width =
            fields.count > 2 ? fields[2].text.doubleValue : oldFrame.size.width;

        CGFloat height =
            fields.count > 3 ? fields[3].text.doubleValue : oldFrame.size.height;

        CGRect newFrame =
            CGRectMake(x, y, width, height);

        MRzefvUIChange *change =
            [[MRzefvUIChange alloc] init];

        change.type = MRzefvUIChangeTypeFrame;
        change.targetClass =
            NSStringFromClass(view.class);
        change.propertyName = @"frame";
        change.frame = newFrame;

        [self.profile addChange:change];

        view.frame = newFrame;

        [self.tableView reloadData];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addText {
    UIView *parent = self.selectedView;

    if (!parent) {
        [self showMessage:@"Select a parent view first."];
        return;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Add Text"
                                            message:@"Add a UILabel to the selected view."
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Text";
    }];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Add"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {

        NSString *text =
            alert.textFields.firstObject.text ?: @"New Text";

        UILabel *label =
            [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 160, 40)];

        label.text = text;
        label.textColor = UIColor.labelColor;
        label.backgroundColor =
            [UIColor colorWithWhite:0 alpha:0.08];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = YES;

        [parent addSubview:label];

        MRzefvUIChange *change =
            [[MRzefvUIChange alloc] init];

        change.type = MRzefvUIChangeTypeAddText;
        change.targetClass =
            NSStringFromClass(parent.class);
        change.propertyName = @"subview";
        change.replacementValue = text;
        change.frame = label.frame;

        [self.profile addChange:change];

        [self.tableView reloadData];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Save

- (void)saveCurrentProfile {
    NSData *data = [self.profile JSONData];

    if (!data) {
        [self showMessage:@"Could not serialize the MRzefv profile."];
        return;
    }

    NSURL *documentsURL =
        [[[NSFileManager defaultManager]
            URLsForDirectory:NSDocumentDirectory
                   inDomains:NSUserDomainMask] firstObject];

    NSURL *fileURL =
        [documentsURL URLByAppendingPathComponent:@"MRzefv-ui-profile.json"];

    NSError *error = nil;

    if (![data writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
        [self showMessage:
            [NSString stringWithFormat:@"Save failed: %@",
             error.localizedDescription]];
        return;
    }

    NSLog(@"[MRzefv] Profile saved: %@", fileURL.path);

    [self showMessage:
        [NSString stringWithFormat:@"Saved %lu changes.",
         (unsigned long)self.profile.changes.count]];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0:
            return 2;

        case 1:
            return 2;

        case 2:
            return 5;

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
            return @"Live Preview";

        case 2:
            return @"Edit";

        default:
            return nil;
    }
}

- (UITableViewCell *)
    tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *identifier = @"MRzefvCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:identifier];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;

    if (indexPath.section == 0) {

        if (indexPath.row == 0) {
            cell.textLabel.text = @"Select Live View";
            cell.imageView.image =
                [UIImage systemImageNamed:@"scope"];
        } else {
            cell.textLabel.text = @"Selected View";

            UIView *view = self.selectedView;

            if (view) {
                cell.detailTextLabel.text =
                    [NSString stringWithFormat:@"%@ <%p>",
                     NSStringFromClass(view.class),
                     view];

                cell.imageView.image =
                    [UIImage systemImageNamed:@"checkmark.circle.fill"];
            } else {
                cell.detailTextLabel.text =
                    @"No view selected";

                cell.imageView.image =
                    [UIImage systemImageNamed:@"circle"];
            }
        }

    } else if (indexPath.section == 1) {

        if (indexPath.row == 0) {
            cell.textLabel.text = @"Live Preview";
            cell.detailTextLabel.text =
                self.previewView ? @"Active" : @"Ready";

            cell.imageView.image =
                [UIImage systemImageNamed:@"play.circle"];
        } else {
            cell.textLabel.text = @"Reset Preview";
            cell.imageView.image =
                [UIImage systemImageNamed:@"arrow.counterclockwise"];
        }

    } else {

        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Change Text";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"character.cursor.ibeam"];
                break;

            case 1:
                cell.textLabel.text = @"Hide / Show";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"eye"];
                break;

            case 2:
                cell.textLabel.text = @"Alignment";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"text.alignleft"];
                break;

            case 3:
                cell.textLabel.text = @"Frame";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"rectangle"];
                break;

            case 4:
                cell.textLabel.text = @"Add Text";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"plus.rectangle"];
                break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {

        if (indexPath.row == 0) {
            [self beginViewSelection];
        }

        return;
    }

    if (indexPath.section == 1) {

        if (indexPath.row == 0) {
            [self beginPreview];
        } else {
            [self resetPreview];
        }

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
    }
}

#pragma mark - Helpers

- (void)showMessage:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"MRzefv"
                             message:message
                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

@end