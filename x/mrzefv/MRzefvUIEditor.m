//
//  MRzefvUIEditor.m
//  AVX512HookTemplateGenerator
//
//  MRzefv UI Editor by DELvEK.NET
//

#import "MRzefvUIEditor.h"

#pragma mark - MRzefvUIChange

@implementation MRzefvUIChange

- (instancetype)init {
    self = [super init];

    if (self) {
        _type = MRzefvUIChangeTypeText;
        _targetClass = @"";
        _hierarchyPath = @"";
        _frame = CGRectZero;
        _alignment = NSTextAlignmentNatural;
    }

    return self;
}

@end

#pragma mark - MRzefvUIProfile

@implementation MRzefvUIProfile

- (instancetype)init {
    self = [super init];

    if (self) {
        _format = @"MRzefv-UI";
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
    NSMutableArray *changes = [NSMutableArray arrayWithCapacity:self.changes.count];

    for (MRzefvUIChange *change in self.changes) {

        NSMutableDictionary *entry = [NSMutableDictionary dictionary];

        entry[@"type"] = @(change.type);
        entry[@"targetClass"] = change.targetClass ?: @"";
        entry[@"hierarchyPath"] = change.hierarchyPath ?: @"";

        if (change.propertyName) {
            entry[@"property"] = change.propertyName;
        }

        if (change.originalValue) {
            entry[@"originalValue"] = change.originalValue;
        }

        if (change.newValue) {
            entry[@"newValue"] = change.newValue;
        }

        if (!CGRectIsEmpty(change.frame)) {
            entry[@"frame"] = @{
                @"x": @(change.frame.origin.x),
                @"y": @(change.frame.origin.y),
                @"width": @(change.frame.size.width),
                @"height": @(change.frame.size.height)
            };
        }

        entry[@"alignment"] = @(change.alignment);

        [changes addObject:entry];
    }

    return @{
        @"format": self.format ?: @"MRzefv-UI",
        @"version": @(self.version),
        @"changes": changes
    };
}

- (NSData *)JSONData:(NSError **)error {
    NSDictionary *dictionary = [self dictionaryRepresentation];

    return [NSJSONSerialization dataWithJSONObject:dictionary
                                           options:NSJSONWritingPrettyPrinted
                                             error:error];
}

@end

#pragma mark - Editor

@interface MRzefvUIEditorController ()

@property (nonatomic, strong) NSMutableDictionary<NSValue *, NSValue *> *originalFrames;
@property (nonatomic, strong) NSMutableDictionary<NSValue *, NSNumber *> *originalHiddenStates;
@property (nonatomic, strong) NSMutableDictionary<NSValue *, NSString *> *originalTexts;

@end

@implementation MRzefvUIEditorController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _profile = [MRzefvUIProfile new];
        _originalFrames = [NSMutableDictionary dictionary];
        _originalHiddenStates = [NSMutableDictionary dictionary];
        _originalTexts = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"MRzefv UI Editor";

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(saveCurrentProfile)];

    self.tableView.rowHeight = 52.0;
}

#pragma mark - Preview

- (void)beginPreview {
    UIView *view = self.selectedView;

    if (!view) {
        return;
    }

    NSValue *key = [NSValue valueWithNonretainedObject:view];

    if (![self.originalFrames objectForKey:key]) {
        self.originalFrames[key] = [NSValue valueWithCGRect:view.frame];
    }

    if (![self.originalHiddenStates objectForKey:key]) {
        self.originalHiddenStates[key] = @(view.hidden);
    }

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;

        if (![self.originalTexts objectForKey:key]) {
            self.originalTexts[key] = label.text ?: @"";
        }
    }
}

- (void)resetPreview {
    [self.originalFrames enumerateKeysAndObjectsUsingBlock:
     ^(NSValue *key, NSValue *value, BOOL *stop) {

        UIView *view = [key nonretainedObjectValue];

        if (view) {
            view.frame = value.CGRectValue;
        }
    }];

    [self.originalHiddenStates enumerateKeysAndObjectsUsingBlock:
     ^(NSValue *key, NSNumber *value, BOOL *stop) {

        UIView *view = [key nonretainedObjectValue];

        if (view) {
            view.hidden = value.boolValue;
        }
    }];

    [self.originalTexts enumerateKeysAndObjectsUsingBlock:
     ^(NSValue *key, NSString *value, BOOL *stop) {

        UIView *view = [key nonretainedObjectValue];

        if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).text = value;
        }
    }];

    [self.originalFrames removeAllObjects];
    [self.originalHiddenStates removeAllObjects];
    [self.originalTexts removeAllObjects];

    [self.tableView reloadData];
}

#pragma mark - Profile

- (void)saveCurrentProfile {
    NSError *error = nil;

    NSData *data = [self.profile JSONData:&error];

    if (!data || error) {
        NSLog(@"[MRzefv] Failed to serialize UI profile: %@", error);
        return;
    }

    NSLog(@"[MRzefv] UI profile generated: %lu bytes",
          (unsigned long)data.length);

    NSLog(@"[MRzefv] Changes: %lu",
          (unsigned long)self.profile.changes.count);

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"MRzefv UI Profile"
                                             message:[NSString stringWithFormat:
                                                      @"%lu UI changes ready for preview or dylib generation.",
                                                      (unsigned long)self.profile.changes.count]
                                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"OK"
                              style:UIAlertActionStyleDefault
                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table

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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *identifier = @"MRzefvCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:identifier];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;

    if (indexPath.section == 0) {
        cell.textLabel.text = @"Selected View";

        if (self.selectedView) {
            cell.detailTextLabel.text =
                NSStringFromClass(self.selectedView.class);
        } else {
            cell.detailTextLabel.text = @"No view selected";
        }

        return cell;
    }

    if (indexPath.section == 1) {

        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Change Text";
                break;

            case 1:
                cell.textLabel.text = @"Hide / Show";
                break;

            case 2:
                cell.textLabel.text = @"Alignment";
                break;

            case 3:
                cell.textLabel.text = @"Position / Size";
                break;
        }

        return cell;
    }

    if (indexPath.section == 2) {

        if (indexPath.row == 0) {
            cell.textLabel.text = @"Add Text";
        } else {
            cell.textLabel.text = @"Save UI Profile";
        }

        return cell;
    }

    return cell;
}

@end
