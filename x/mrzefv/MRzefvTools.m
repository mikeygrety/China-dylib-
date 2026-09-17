//
//  MRzefvTools.m
//  AVX512HookTemplateGenerator
//
//  MRzefv Tools by DELvEK.NET
//

#import "MRzefvTools.h"
#import "MRzefvUIEditor.h"

@implementation MRzefvToolsController

+ (void)presentFromViewController:(UIViewController *)viewController {
    if (!viewController) {
        return;
    }

    MRzefvToolsController *controller =
        [[MRzefvToolsController alloc] initWithStyle:UITableViewStyleInsetGrouped];

    UINavigationController *navigation =
        [[UINavigationController alloc] initWithRootViewController:controller];

    [viewController presentViewController:navigation
                                 animated:YES
                               completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"MRzefv Tools";

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                      target:self
                                                      action:@selector(close)];

    self.tableView.rowHeight = 58.0;
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
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
            return 1;

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
            return @"UI Tools";

        case 1:
            return @"Dylib";

        case 2:
            return @"Analysis";

        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *identifier = @"MRzefvToolCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:identifier];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.section == 0) {
        cell.textLabel.text = @"UI Editor";
        cell.detailTextLabel.text =
            @"Inspect, preview, edit and save UI changes";
        cell.imageView.image =
            [UIImage systemImageNamed:@"rectangle.and.pencil.and.ellipsis"];
    }

    else if (indexPath.section == 1) {
        cell.textLabel.text = @"Dylib Generator";
        cell.detailTextLabel.text =
            @"Generate from selected classes and UI profiles";
        cell.imageView.image =
            [UIImage systemImageNamed:@"shippingbox"];
    }

    else if (indexPath.section == 2) {
        cell.textLabel.text = @"Enhanced CFG";
        cell.detailTextLabel.text =
            @"View, write and export control-flow graphs";
        cell.imageView.image =
            [UIImage systemImageNamed:@"point.3.connected.trianglepath.dotted"];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {

        MRzefvUIEditorController *editor =
            [[MRzefvUIEditorController alloc] init];

        [self.navigationController pushViewController:editor
                                             animated:YES];

        return;
    }

    if (indexPath.section == 1) {
        NSLog(@"[MRzefv] Dylib Generator selected");
        return;
    }

    if (indexPath.section == 2) {
        NSLog(@"[MRzefv] Enhanced CFG selected");
        return;
    }
}

@end
