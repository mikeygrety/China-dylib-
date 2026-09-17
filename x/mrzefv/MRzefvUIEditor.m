//
//  MRzefvUIEditor.m
//  AVX512
//
//  MRzefv UI Editor
//  AVX512 by DELvEK.NET
//

#import "MRzefvUIEditor.h"

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
    NSMutableArray *serializedChanges = [NSMutableArray array];

    for (MRzefvUIChange *change in self.changes) {
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];

        entry[@"type"] = @(change.type);

        if (change.targetClass) {
            entry[@"targetClass"] = change.targetClass;
        }

        if (change.hierarchyPath) {
            entry[@"hierarchyPath"] = change.hierarchyPath;
        }

        if (change.propertyName) {
            entry[@"propertyName"] = change.propertyName;
        }

        if (change.originalValue) {
            entry[@"originalValue"] = change.originalValue;
        }

        if (change.replacementValue) {
            entry[@"newValue"] = change.replacementValue;
        }

        if (change.type == MRzefvUIChangeTypeFrame ||
            change.type == MRzefvUIChangeTypeAddText) {

            entry[@"frame"] = @{
                @"x": @(change.frame.origin.x),
                @"y": @(change.frame.origin.y),
                @"width": @(change.frame.size.width),
                @"height": @(change.frame.size.height)
            };
        }

        if (change.type == MRzefvUIChangeTypeAlignment) {
            entry[@"alignment"] = @(change.alignment);
        }

        [serializedChanges addObject:entry];
    }

    return @{
        @"format": self.format ?: @"mrzefv-ui-profile",
        @"version": @(self.version),
        @"changes": serializedChanges
    };
}

- (NSData *)JSONData {
    NSDictionary *dictionary = [self dictionaryRepresentation];

    if (![NSJSONSerialization isValidJSONObject:dictionary]) {
        return nil;
    }

    return [NSJSONSerialization dataWithJSONObject:dictionary
                                           options:NSJSONWritingPrettyPrinted
                                             error:nil];
}

@end

#pragma mark - MRzefvUIEditorController

@interface MRzefvUIEditorController ()

@property (nonatomic, strong) NSMutableDictionary<NSValue *, NSDictionary *> *previewState;

@end

@implementation MRzefvUIEditorController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _profile = [MRzefvUIProfile new];
        _previewState = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"MRzefv UI Editor";

    self.tableView.rowHeight = 52.0;

    [self.tableView registerClass:UITableViewCell.class
           forCellReuseIdentifier:@"MRzefvCell"];
}

#pragma mark - Sections

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0:
            return 1;

        case 1:
            return 4;

        case 2:
            return 2;

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
            return @"Profile";

        default:
            return nil;
    }
}

#pragma mark - Cells

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"MRzefvCell"
                                        forIndexPath:indexPath];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    cell.textLabel.text = nil;

    if (indexPath.section == 0) {

        cell.textLabel.text = self.selectedView
            ? NSStringFromClass(self.selectedView.class)
            : @"Select View";

        cell.imageView.image =
            [UIImage systemImageNamed:@"viewfinder"];

    } else if (indexPath.section == 1) {

        switch (indexPath.row) {

            case 0:
                cell.textLabel.text = @"Change Text";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"character.cursor.ibeam"];
                break;

            case 1:
                cell.textLabel.text =
                    self.selectedView.hidden ? @"Show View" : @"Hide View";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"eye"];
                break;

            case 2:
                cell.textLabel.text = @"Alignment";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"text.alignleft"];
                break;

            case 3:
                cell.textLabel.text = @"Position / Size";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"];
                break;
        }

    } else if (indexPath.section == 2) {

        switch (indexPath.row) {

            case 0:
                cell.textLabel.text = @"Add Text";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"plus.square"];
                break;

            case 1:
                cell.textLabel.text = @"Save UI Profile";
                cell.imageView.image =
                    [UIImage systemImageNamed:@"square.and.arrow.down"];
                break;
        }
    }

    return cell;
}

#pragma mark - Selection

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        [self beginViewSelection];
        return;
    }

    if (indexPath.section == 1) {

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
        }

        return;
    }

    if (indexPath.section == 2) {

        switch (indexPath.row) {

            case 0:
                [self addText];
                break;

            case 1:
                [self saveCurrentProfile];
                break;
        }
    }
}

#pragma mark - View Selection

- (void)beginViewSelection {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"MRzefv UI Editor"
                                            message:@"View selection is ready for the live preview."
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Preview

- (void)beginPreview {
    if (!self.selectedView) {
        return;
    }

    NSValue *key = [NSValue valueWithNonretainedObject:self.selectedView];

    if (!self.previewState[key]) {
        self.previewState[key] = @{
            @"frame": [NSValue valueWithCGRect:self.selectedView.frame],
            @"hidden": @(self.selectedView.hidden),
            @"alpha": @(self.selectedView.alpha)
        };
    }
}

- (void)resetPreview {
    for (NSValue *key in self.previewState) {

        UIView *view = key.nonretainedObjectValue;

        if (!view) {
            continue;
        }

        NSDictionary *state = self.previewState[key];

        NSValue *frameValue = state[@"frame"];

        if (frameValue) {
            view.frame = frameValue.CGRectValue;
        }

        NSNumber *hidden = state[@"hidden"];

        if (hidden) {
            view.hidden = hidden.boolValue;
        }

        NSNumber *alpha = state[@"alpha"];

        if (alpha) {
            view.alpha = alpha.floatValue;
        }
    }

    [self.previewState removeAllObjects];
}

#pragma mark - Change Text

- (void)changeText {
    if (!self.selectedView) {
        return;
    }

    if (![self.selectedView isKindOfClass:UITextField.class] &&
        ![self.selectedView isKindOfClass:UITextView.class] &&
        ![self.selectedView isKindOfClass:UILabel.class] &&
        ![self.selectedView isKindOfClass:UIButton.class]) {

        return;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Change Text"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"New text";
    }];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Apply"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {

        __strong typeof(weakSelf) self = weakSelf;

        NSString *text = alert.textFields.firstObject.text;

        if (!text.length) {
            return;
        }

        [self beginPreview];

        NSString *original = nil;

        if ([self.selectedView isKindOfClass:UILabel.class]) {
            original = [(UILabel *)self.selectedView text];
            [(UILabel *)self.selectedView setText:text];

        } else if ([self.selectedView isKindOfClass:UITextField.class]) {
            original = [(UITextField *)self.selectedView text];
            [(UITextField *)self.selectedView setText:text];

        } else if ([self.selectedView isKindOfClass:UITextView.class]) {
            original = [(UITextView *)self.selectedView text];
            [(UITextView *)self.selectedView setText:text];

        } else if ([self.selectedView isKindOfClass:UIButton.class]) {
            original = [(UIButton *)self.selectedView
                        titleForState:UIControlStateNormal];

            [(UIButton *)self.selectedView
                setTitle:text
                forState:UIControlStateNormal];
        }

        MRzefvUIChange *change = [MRzefvUIChange new];

        change.type = MRzefvUIChangeTypeText;
        change.targetClass =
            NSStringFromClass(self.selectedView.class);
        change.originalValue = original;
        change.replacementValue = text;
        change.propertyName = @"text";

        [self.profile addChange:change];

        [self.tableView reloadData];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Hidden

- (void)toggleHidden {
    if (!self.selectedView) {
        return;
    }

    [self beginPreview];

    BOOL hidden = !self.selectedView.hidden;

    self.selectedView.hidden = hidden;

    MRzefvUIChange *change = [MRzefvUIChange new];

    change.type = MRzefvUIChangeTypeHidden;
    change.targetClass =
        NSStringFromClass(self.selectedView.class);
    change.propertyName = @"hidden";
    change.originalValue =
        hidden ? @"NO" : @"YES";
    change.replacementValue =
        hidden ? @"YES" : @"NO";

    [self.profile addChange:change];

    [self.tableView reloadData];
}

#pragma mark - Alignment

- (void)changeAlignment {
    if (![self.selectedView isKindOfClass:UILabel.class]) {
        return;
    }

    UILabel *label = (UILabel *)self.selectedView;

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Alignment"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *names = @[
        @"Left",
        @"Center",
        @"Right",
        @"Justified",
        @"Natural"
    ];

    NSArray *values = @[
        @(NSTextAlignmentLeft),
        @(NSTextAlignmentCenter),
        @(NSTextAlignmentRight),
        @(NSTextAlignmentJustified),
        @(NSTextAlignmentNatural)
    ];

    __weak typeof(self) weakSelf = self;

    for (NSUInteger i = 0; i < names.count; i++) {

        [alert addAction:
            [UIAlertAction actionWithTitle:names[i]
                                     style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {

            __strong typeof(weakSelf) self = weakSelf;

            [self beginPreview];

            NSTextAlignment oldAlignment = label.textAlignment;
            NSTextAlignment newAlignment = [values[i] integerValue];

            label.textAlignment = newAlignment;

            MRzefvUIChange *change = [MRzefvUIChange new];

            change.type = MRzefvUIChangeTypeAlignment;
            change.targetClass =
                NSStringFromClass(label.class);
            change.propertyName = @"textAlignment";
            change.originalValue =
                @(oldAlignment).stringValue;
            change.replacementValue =
                @(newAlignment).stringValue;
            change.alignment = newAlignment;

            [self.profile addChange:change];

            [self.tableView reloadData];
        }]];
    }

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Frame

- (void)changeFrame {
    if (!self.selectedView) {
        return;
    }

    [self beginPreview];

    CGRect oldFrame = self.selectedView.frame;

    CGFloat x = oldFrame.origin.x + 10.0;
    CGFloat y = oldFrame.origin.y + 10.0;

    CGRect newFrame =
        CGRectMake(x,
                   y,
                   oldFrame.size.width,
                   oldFrame.size.height);

    self.selectedView.frame = newFrame;

    MRzefvUIChange *change = [MRzefvUIChange new];

    change.type = MRzefvUIChangeTypeFrame;
    change.targetClass =
        NSStringFromClass(self.selectedView.class);
    change.propertyName = @"frame";
    change.originalValue =
        NSStringFromCGRect(oldFrame);
    change.replacementValue =
        NSStringFromCGRect(newFrame);
    change.frame = newFrame;

    [self.profile addChange:change];
}

#pragma mark - Add Text

- (void)addText {
    if (!self.selectedView) {
        return;
    }

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(
        20.0,
        20.0,
        200.0,
        40.0
    )];

    label.text = @"MRzefv";
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor =
        [UIColor colorWithWhite:0.0 alpha:0.08];

    [self.selectedView addSubview:label];

    MRzefvUIChange *change = [MRzefvUIChange new];

    change.type = MRzefvUIChangeTypeAddText;
    change.targetClass =
        NSStringFromClass(self.selectedView.class);
    change.propertyName = @"UILabel";
    change.replacementValue = label.text;
    change.frame = label.frame;

    [self.profile addChange:change];
}

#pragma mark - Save

- (void)saveCurrentProfile {
    NSData *data = [self.profile JSONData];

    if (!data) {
        return;
    }

    NSURL *directory =
        [[[NSFileManager defaultManager]
          URLsForDirectory:NSDocumentDirectory
          inDomains:NSUserDomainMask] firstObject];

    NSURL *file =
        [directory URLByAppendingPathComponent:@"MRzefv-ui-profile.json"];

    [data writeToURL:file atomically:YES];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"UI Profile Saved"
                                            message:file.lastPathComponent
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end