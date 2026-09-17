//
//  AVX512HookTemplateGenerator.m
//  AVX512HookTemplateGenerator
//
//  AVX512 by DELvEK.NET
//

#import "AVX512HookTemplateGenerator.h"

#import <objc/runtime.h>

#pragma mark - Types

typedef NS_ENUM(NSInteger, AVX512DylibType) {
    AVX512DylibTypeDiagnostic = 0,
    AVX512DylibTypeTestHarness
};

typedef NS_ENUM(NSInteger, AVX512BuildStyle) {
    AVX512BuildStyleShell = 0,
    AVX512BuildStyleGitHubActions
};

#pragma mark - Runtime Method Info

@interface AVX512MethodInfo : NSObject

@property (nonatomic, copy) NSString *selectorName;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *returnType;
@property (nonatomic, assign) NSUInteger argumentCount;
@property (nonatomic, assign) BOOL inherited;

@end

@implementation AVX512MethodInfo
@end

#pragma mark - Runtime Class Info

@interface AVX512ClassInfo : NSObject

@property (nonatomic, assign) Class cls;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *superclassName;
@property (nonatomic, strong) NSArray<AVX512MethodInfo *> *methods;

@end

@implementation AVX512ClassInfo
@end

#pragma mark - Runtime Helpers

static NSString *AVX512HumanType(const char *encoding)
{
    if (!encoding || encoding[0] == '\0') {
        return @"Unknown";
    }

    switch (encoding[0]) {
        case 'v': return @"void";
        case '@': return @"object";
        case '#': return @"Class";
        case ':': return @"SEL";
        case 'c': return @"char / BOOL";
        case 'i': return @"int";
        case 's': return @"short";
        case 'l': return @"long";
        case 'q': return @"long long";
        case 'C': return @"unsigned char";
        case 'I': return @"unsigned int";
        case 'S': return @"unsigned short";
        case 'L': return @"unsigned long";
        case 'Q': return @"unsigned long long";
        case 'f': return @"float";
        case 'd': return @"double";
        case 'B': return @"BOOL";
        case '^': return @"pointer";
        case '{': return @"struct";
        case '[': return @"array";
        case 'b': return @"bit-field";
        default:
            return [NSString stringWithFormat:@"encoding %c", encoding[0]];
    }
}

static NSUInteger AVX512ExplicitArgumentCount(Method method)
{
    if (!method) {
        return 0;
    }

    unsigned int count = method_getNumberOfArguments(method);

    /*
     Objective-C instance methods implicitly receive:

         self
         _cmd

     Therefore the remaining arguments are explicit arguments.
     */

    return count >= 2 ? count - 2 : 0;
}

static NSArray<AVX512MethodInfo *> *AVX512MethodsForClass(Class cls)
{
    if (!cls) {
        return @[];
    }

    NSMutableArray<AVX512MethodInfo *> *methods =
        [NSMutableArray array];

    NSMutableSet<NSString *> *seen =
        [NSMutableSet set];

    Class current = cls;
    BOOL inherited = NO;

    while (current) {

        unsigned int count = 0;

        Method *runtimeMethods =
            class_copyMethodList(current, &count);

        if (runtimeMethods) {

            for (unsigned int index = 0;
                 index < count;
                 index++) {

                Method method = runtimeMethods[index];

                SEL selector = method_getName(method);

                if (!selector) {
                    continue;
                }

                NSString *selectorName =
                    NSStringFromSelector(selector);

                if ([seen containsObject:selectorName]) {
                    continue;
                }

                [seen addObject:selectorName];

                const char *encoding =
                    method_getTypeEncoding(method);

                char *returnEncoding =
                    method_copyReturnType(method);

                AVX512MethodInfo *info =
                    [AVX512MethodInfo new];

                info.selectorName = selectorName;

                info.typeEncoding =
                    encoding
                        ? [NSString stringWithUTF8String:encoding]
                        : @"";

                info.returnType =
                    AVX512HumanType(returnEncoding);

                info.argumentCount =
                    AVX512ExplicitArgumentCount(method);

                info.inherited = inherited;

                if (returnEncoding) {
                    free(returnEncoding);
                }

                [methods addObject:info];
            }

            free(runtimeMethods);
        }

        current = class_getSuperclass(current);
        inherited = YES;
    }

    [methods sortUsingComparator:^NSComparisonResult(
        AVX512MethodInfo *a,
        AVX512MethodInfo *b
    ) {
        return [a.selectorName
            localizedCaseInsensitiveCompare:b.selectorName];
    }];

    return methods;
}

static AVX512ClassInfo *AVX512InspectClass(Class cls)
{
    AVX512ClassInfo *info =
        [AVX512ClassInfo new];

    info.cls = cls;

    info.className =
        NSStringFromClass(cls);

    Class superclass =
        class_getSuperclass(cls);

    info.superclassName =
        superclass
            ? NSStringFromClass(superclass)
            : @"None";

    info.methods =
        AVX512MethodsForClass(cls);

    return info;
}

#pragma mark - Class Inspector

@interface AVX512ClassInspectorController : UITableViewController

@property (nonatomic, strong) AVX512ClassInfo *classInfo;

- (instancetype)initWithClassInfo:(AVX512ClassInfo *)classInfo;

@end

@implementation AVX512ClassInspectorController

- (instancetype)initWithClassInfo:(AVX512ClassInfo *)classInfo
{
    self =
        [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _classInfo = classInfo;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.classInfo.className;

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                 target:self
                                 action:@selector(closeInspector)];

    UIImage *signatureImage = nil;

    if (@available(iOS 13.0, *)) {
        signatureImage =
            [UIImage systemImageNamed:@"signature"];
    }

    if (!signatureImage) {
        signatureImage =
            [UIImage systemImageNamed:@"pencil.and.outline"];
    }

    if (!signatureImage) {
        signatureImage =
            [UIImage systemImageNamed:@"square.and.pencil"];
    }

    UIBarButtonItem *makeButton =
        [[UIBarButtonItem alloc]
            initWithImage:signatureImage
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(makeDylib)];

    makeButton.accessibilityLabel =
        @"signature.zh — Make Dylib";

    self.navigationItem.rightBarButtonItem =
        makeButton;

    self.tableView.rowHeight =
        UITableViewAutomaticDimension;

    self.tableView.estimatedRowHeight =
        76.0;
}

- (void)closeInspector
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)makeDylib
{
    /*
     The inspector is intentionally informational.
     The generator's main screen owns the generation workflow.
     */

    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Sections

- (NSInteger)numberOfSectionsInTableView:
    (UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    switch (section) {

        case 0:
            return 1;

        case 1:
            return 1;

        case 2:
            return self.classInfo.methods.count;

        case 3:
            return 1;

        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    switch (section) {

        case 0:
            return @"CLASS";

        case 1:
            return @"WHAT THIS CLASS IS";

        case 2:
            return @"METHODS";

        case 3:
            return @"HOW TO READ THIS";

        default:
            return nil;
    }
}

#pragma mark - Cells

- (UITableViewCell *)tableView:
    (UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier =
        [NSString stringWithFormat:@"AVX512-%ld",
         (long)indexPath.section];

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:identifier];
    }

    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;

    switch (indexPath.section) {

        case 0: {
            cell.textLabel.text =
                self.classInfo.className;

            cell.detailTextLabel.text =
                [NSString stringWithFormat:
                    @"Superclass: %@\nMethods discovered: %lu",
                    self.classInfo.superclassName,
                    (unsigned long)self.classInfo.methods.count];

            cell.imageView.image =
                [UIImage systemImageNamed:@"shippingbox"];

            break;
        }

        case 1: {
            cell.textLabel.text =
                [NSString stringWithFormat:
                    @"The Objective-C runtime reports this object "
                     "as the class \"%@\". It inherits from %@.\n\n"
                     "The methods below include methods declared "
                     "directly by this class and methods visible "
                     "through its superclass chain.\n\n"
                     "Runtime metadata describes the class interface. "
                     "It does not reveal the implementation or prove "
                     "what a method does internally.",
                    self.classInfo.className,
                    self.classInfo.superclassName];

            cell.textLabel.font =
                [UIFont preferredFontForTextStyle:
                    UIFontTextStyleBody];

            break;
        }

        case 2: {
            AVX512MethodInfo *method =
                self.classInfo.methods[indexPath.row];

            cell.textLabel.text =
                method.selectorName;

            cell.detailTextLabel.text =
                [NSString stringWithFormat:
                    @"%@  •  return: %@  •  %lu args\n"
                     @"encoding: %@",
                    method.inherited
                        ? @"Inherited"
                        : @"Declared",
                    method.returnType,
                    (unsigned long)method.argumentCount,
                    method.typeEncoding];

            cell.imageView.image =
                [UIImage systemImageNamed:
                    method.inherited
                        ? @"arrow.turn.up.right"
                        : @"function"];

            cell.accessoryType =
                UITableViewCellAccessoryDisclosureIndicator;

            break;
        }

        case 3: {
            cell.textLabel.text =
                @"Selector = Objective-C method name.\n\n"
                 "Declared = found directly on this class.\n\n"
                 "Inherited = found on a superclass.\n\n"
                 "Arguments = explicit arguments after self and _cmd.\n\n"
                 "Encoding = raw Objective-C runtime type encoding.\n\n"
                 "The encoding is useful for understanding the "
                 "runtime ABI, but it does not reveal implementation "
                 "logic.";

            cell.textLabel.font =
                [UIFont preferredFontForTextStyle:
                    UIFontTextStyleBody];

            break;
        }
    }

    return cell;
}

#pragma mark - Method Details

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 2) {
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
        return;
    }

    AVX512MethodInfo *method =
        self.classInfo.methods[indexPath.row];

    NSString *message =
        [NSString stringWithFormat:
            @"Selector\n%@\n\n"
             @"Runtime status\n%@\n\n"
             @"Return type\n%@\n\n"
             @"Explicit arguments\n%lu\n\n"
             @"Type encoding\n%@\n\n"
             @"This is runtime metadata. It describes how "
             "Objective-C represents the method, but it does "
             "not reveal the method's internal implementation.",
            method.selectorName,
            method.inherited
                ? @"Inherited"
                : @"Declared by this class",
            method.returnType,
            (unsigned long)method.argumentCount,
            method.typeEncoding];

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:method.selectorName
                               message:message
                        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Done"
                      style:UIAlertActionStyleDefault
                    handler:nil]];

    [self presentViewController:alert
                         animated:YES
                       completion:nil];

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

@end

#pragma mark - Generator

@interface AVX512HookTemplateGenerator ()
    <UISearchResultsUpdating>

@property (nonatomic, strong)
    NSArray<NSString *> *allClasses;

@property (nonatomic, strong)
    NSArray<NSString *> *filteredClasses;

@property (nonatomic, strong)
    NSMutableSet<NSString *> *selectedClasses;

@property (nonatomic, strong)
    UISearchController *searchController;

@end

@implementation AVX512HookTemplateGenerator

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title =
        @"AVX512 Dylib Generator";

    self.selectedClasses =
        [NSMutableSet set];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                 target:self
                                 action:@selector(closeGenerator)];

    UIImage *signatureImage = nil;

    if (@available(iOS 13.0, *)) {
        signatureImage =
            [UIImage systemImageNamed:@"signature"];
    }

    if (!signatureImage) {
        signatureImage =
            [UIImage systemImageNamed:@"pencil.and.outline"];
    }

    if (!signatureImage) {
        signatureImage =
            [UIImage systemImageNamed:@"square.and.pencil"];
    }

    UIBarButtonItem *makeButton =
        [[UIBarButtonItem alloc]
            initWithImage:signatureImage
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(generate)];

    makeButton.accessibilityLabel =
        @"signature.zh — Make Dylib";

    self.navigationItem.rightBarButtonItem =
        makeButton;

    self.tableView.rowHeight =
        UITableViewAutomaticDimension;

    self.tableView.estimatedRowHeight =
        72.0;

    self.searchController =
        [[UISearchController alloc]
            initWithSearchResultsController:nil];

    self.searchController.searchResultsUpdater =
        self;

    self.searchController.obscuresBackgroundDuringPresentation =
        NO;

    self.navigationItem.searchController =
        self.searchController;

    self.definesPresentationContext =
        YES;

    [self loadRuntimeClasses];
}

#pragma mark - Close

- (void)closeGenerator
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Runtime Class List

- (void)loadRuntimeClasses
{
    unsigned int count = 0;

    Class *classes =
        objc_copyClassList(&count);

    NSMutableArray<NSString *> *names =
        [NSMutableArray arrayWithCapacity:count];

    if (classes) {

        for (unsigned int index = 0;
             index < count;
             index++) {

            Class cls = classes[index];

            if (!cls) {
                continue;
            }

            NSString *name =
                NSStringFromClass(cls);

            if (name.length > 0) {
                [names addObject:name];
            }
        }

        free(classes);
    }

    [names sortUsingSelector:
        @selector(localizedCaseInsensitiveCompare:)];

    self.allClasses =
        [names copy];

    self.filteredClasses =
        [names copy];

    [self.tableView reloadData];
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
    NSString *query =
        searchController.searchBar.text.lowercaseString;

    if (query.length == 0) {

        self.filteredClasses =
            self.allClasses;

    } else {

        NSMutableArray *matches =
            [NSMutableArray array];

        for (NSString *name in self.allClasses) {

            if ([name.lowercaseString
                    containsString:query]) {

                [matches addObject:name];
            }
        }

        self.filteredClasses =
            matches;
    }

    [self.tableView reloadData];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.filteredClasses.count;
}

- (UITableViewCell *)tableView:
    (UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier =
        @"AVX512ClassCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:
            identifier];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:identifier];
    }

    NSString *className =
        self.filteredClasses[indexPath.row];

    BOOL selected =
        [self.selectedClasses
            containsObject:className];

    cell.textLabel.text =
        className;

    cell.detailTextLabel.text =
        selected
            ? @"Selected • Tap to inspect"
            : @"Tap to inspect runtime metadata";

    cell.imageView.image =
        [UIImage systemImageNamed:@"shippingbox"];

    cell.accessoryType =
        selected
            ? UITableViewCellAccessoryCheckmark
            : UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *className =
        self.filteredClasses[indexPath.row];

    Class cls =
        NSClassFromString(className);

    if (!cls) {
        return;
    }

    if ([self.selectedClasses
            containsObject:className]) {

        [self.selectedClasses
            removeObject:className];

    } else {

        [self.selectedClasses
            addObject:className];
    }

    [tableView reloadRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:
                         UITableViewRowAnimationAutomatic];

    AVX512ClassInfo *info =
        AVX512InspectClass(cls);

    AVX512ClassInspectorController *inspector =
        [[AVX512ClassInspectorController alloc]
            initWithClassInfo:info];

    UINavigationController *navigation =
        [[UINavigationController alloc]
            initWithRootViewController:inspector];

    navigation.modalPresentationStyle =
        UIModalPresentationPageSheet;

    [self presentViewController:navigation
                         animated:YES
                       completion:nil];
}

#pragma mark - Generation Flow

- (void)generate
{
    if (self.selectedClasses.count == 0) {

        UIAlertController *alert =
            [UIAlertController
                alertControllerWithTitle:@"No Classes Selected"
                                   message:
                                       @"Select at least one runtime class first."
                            preferredStyle:
                                UIAlertControllerStyleAlert];

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

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:
                @"signature.zh — Make Dylib"
                               message:
                                   @"Choose the generated project type."
                        preferredStyle:
                            UIAlertControllerStyleActionSheet];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Diagnostic"
                      style:UIAlertActionStyleDefault
                    handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:
            AVX512DylibTypeDiagnostic];
    }]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Test Harness"
                      style:UIAlertActionStyleDefault
                    handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:
            AVX512DylibTypeTestHarness];
    }]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:nil]];

    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:alert
                         animated:YES
                       completion:nil];
}

- (void)chooseBuildStyle:
    (AVX512DylibType)dylibType
{
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Build Output"
                               message:
                                   @"Choose how the generated project will build."
                        preferredStyle:
                            UIAlertControllerStyleActionSheet];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Shell Script"
                      style:UIAlertActionStyleDefault
                    handler:^(__unused UIAlertAction *action) {

        [self generateProjectWithDylibType:dylibType
                                buildStyle:
                                    AVX512BuildStyleShell];
    }]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"GitHub Actions"
                      style:UIAlertActionStyleDefault
                    handler:^(__unused UIAlertAction *action) {

        [self generateProjectWithDylibType:dylibType
                                buildStyle:
                                    AVX512BuildStyleGitHubActions];
    }]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:nil]];

    [self presentViewController:alert
                         animated:YES
                       completion:nil];
}

#pragma mark - Project Generation

- (void)generateProjectWithDylibType:
            (AVX512DylibType)dylibType
                         buildStyle:
            (AVX512BuildStyle)buildStyle
{
    NSString *folderName =
        [NSString stringWithFormat:
            @"AVX512Generated-%@",
            NSUUID.UUID.UUIDString];

    NSString *root =
        [NSTemporaryDirectory()
            stringByAppendingPathComponent:folderName];

    NSFileManager *fm =
        [NSFileManager defaultManager];

    NSError *error = nil;

    if (![fm createDirectoryAtPath:root
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error]) {

        [self showError:
            error.localizedDescription];

        return;
    }

    NSString *header =
        [self generatedHeader];

    NSString *implementation =
        [self generatedImplementation:dylibType];

    NSString *readme =
        [self generatedREADME:dylibType
                   buildStyle:buildStyle];

    if (![self writeString:header
                    toPath:
                        [root
                            stringByAppendingPathComponent:
                                @"AVX512Hook.h"]
                     error:&error]) {

        [self showError:error.localizedDescription];
        return;
    }

    if (![self writeString:implementation
                    toPath:
                        [root
                            stringByAppendingPathComponent:
                                @"AVX512Hook.m"]
                     error:&error]) {

        [self showError:error.localizedDescription];
        return;
    }

    if (![self writeString:readme
                    toPath:
                        [root
                            stringByAppendingPathComponent:
                                @"README.md"]
                     error:&error]) {

        [self showError:error.localizedDescription];
        return;
    }

    if (buildStyle ==
        AVX512BuildStyleShell) {

        NSString *build =
            [self generatedBuildScript];

        if (![self writeString:build
                        toPath:
                            [root
                                stringByAppendingPathComponent:
                                    @"build.sh"]
                         error:&error]) {

            [self showError:
                error.localizedDescription];

            return;
        }

    } else {

        NSString *workflowDirectory =
            [root
                stringByAppendingPathComponent:
                    @".github/workflows"];

        if (![fm createDirectoryAtPath:
                workflowDirectory
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error]) {

            [self showError:
                error.localizedDescription];

            return;
        }

        NSString *workflow =
            [self generatedGitHubActions];

        NSString *workflowPath =
            [workflowDirectory
                stringByAppendingPathComponent:
                    @"build.yml"];

        if (![self writeString:workflow
                        toPath:workflowPath
                         error:&error]) {

            [self showError:
                error.localizedDescription];

            return;
        }
    }

    [self shareProject:root];
}

#pragma mark - Generated Header

- (NSString *)generatedHeader
{
    return
@"//\n"
@"// AVX512Hook.h\n"
@"// Generated by signature.zh — AVX512 / DELvEK.NET\n"
@"//\n"
@"\n"
@"#import <Foundation/Foundation.h>\n"
@"\n"
@"FOUNDATION_EXPORT void AVX512PrintSelectedRuntimeMetadata(void);\n";
}

#pragma mark - Generated Implementation

- (NSString *)generatedImplementation:
    (AVX512DylibType)dylibType
{
    NSMutableString *selected =
        [NSMutableString string];

    NSArray *classes =
        [[self.selectedClasses allObjects]
            sortedArrayUsingSelector:
                @selector(localizedCaseInsensitiveCompare:)];

    for (NSString *className in classes) {

        NSString *escaped =
            [self escapedString:className];

        [selected appendFormat:
            @"        @\"%@\",\n",
            escaped];
    }

    NSString *mode =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    NSMutableString *source =
        [NSMutableString string];

    [source appendString:
@"//\n"
@"// AVX512Hook.m\n"
@"// Generated by signature.zh — AVX512 / DELvEK.NET\n"
@"//\n"
@"\n"
@"#import \"AVX512Hook.h\"\n"
@"#import <objc/runtime.h>\n"
@"\n"];

    [source appendString:
@"static NSArray<NSString *> *AVX512SelectedClasses(void)\n"
@"{\n"
@"    return @[\n"];

    [source appendString:selected];

    [source appendString:
@"    ];\n"
@"}\n"
@"\n"
@"static NSString *AVX512ReturnType(const char *encoding)\n"
@"{\n"
@"    if (!encoding || encoding[0] == '\\0') {\n"
@"        return @\"Unknown\";\n"
@"    }\n"
@"\n"
@"    switch (encoding[0]) {\n"
@"        case 'v': return @\"void\";\n"
@"        case '@': return @\"object\";\n"
@"        case '#': return @\"Class\";\n"
@"        case ':': return @\"SEL\";\n"
@"        case 'c': return @\"char / BOOL\";\n"
@"        case 'i': return @\"int\";\n"
@"        case 's': return @\"short\";\n"
@"        case 'l': return @\"long\";\n"
@"        case 'q': return @\"long long\";\n"
@"        case 'C': return @\"unsigned char\";\n"
@"        case 'I': return @\"unsigned int\";\n"
@"        case 'S': return @\"unsigned short\";\n"
@"        case 'L': return @\"unsigned long\";\n"
@"        case 'Q': return @\"unsigned long long\";\n"
@"        case 'f': return @\"float\";\n"
@"        case 'd': return @\"double\";\n"
@"        case 'B': return @\"BOOL\";\n"
@"        case '^': return @\"pointer\";\n"
@"        case '{': return @\"struct\";\n"
@"        case '[': return @\"array\";\n"
@"        default:\n"
@"            return [NSString stringWithFormat:@\"encoding %%c\", encoding[0]];\n"
@"    }\n"
@"}\n"
@"\n"
@"static NSUInteger AVX512ExplicitArguments(Method method)\n"
@"{\n"
@"    if (!method) {\n"
@"        return 0;\n"
@"    }\n"
@"\n"
@"    unsigned int count = method_getNumberOfArguments(method);\n"
@"\n"
@"    return count >= 2 ? count - 2 : 0;\n"
@"}\n"
@"\n"
@"static void AVX512PrintClass(Class cls)\n"
@"{\n"
@"    if (!cls) {\n"
@"        return;\n"
@"    }\n"
@"\n"
@"    fprintf(stderr,\n"
@"            \"\\n[AVX512] Class: %s\\n\",\n"
@"            class_getName(cls));\n"
@"\n"
@"    Class superclass = class_getSuperclass(cls);\n"
@"\n"
@"    if (superclass) {\n"
@"        fprintf(stderr,\n"
@"                \"[AVX512] Superclass: %s\\n\",\n"
@"                class_getName(superclass));\n"
@"    }\n"
@"\n"
@"    unsigned int count = 0;\n"
@"\n"
@"    Method *methods =\n"
@"        class_copyMethodList(cls, &count);\n"
@"\n"
@"    fprintf(stderr,\n"
@"            \"[AVX512] Direct methods: %u\\n\",\n"
@"            count);\n"
@"\n"
@"    for (unsigned int index = 0;\n"
@"         index < count;\n"
@"         index++) {\n"
@"\n"
@"        Method method = methods[index];\n"
@"        SEL selector = method_getName(method);\n"
@"        const char *encoding = method_getTypeEncoding(method);\n"
@"\n"
@"        fprintf(stderr,\n"
@"                \"[AVX512]   %s | return=%s | args=%lu | encoding=%s\\n\",\n"
@"                sel_getName(selector),\n"
@"                AVX512ReturnType(encoding).UTF8String,\n"
@"                (unsigned long)AVX512ExplicitArguments(method),\n"
@"                encoding ? encoding : \"\");\n"
@"    }\n"
@"\n"
@"    if (methods) {\n"
@"        free(methods);\n"
@"    }\n"
@"}\n"
@"\n"
@"void AVX512PrintSelectedRuntimeMetadata(void)\n"
@"{\n"
@"    @autoreleasepool {\n"
@"        fprintf(stderr,\n"
@"                \"\\n========================================\\n\");\n"
@"        fprintf(stderr,\n"
@"                \"AVX512 — %s\\n\",\n"
@"                \""];

    [source appendString:
        [self escapedString:mode]];

    [source appendString:
@"\");\n"
@"        fprintf(stderr,\n"
@"                \"Generated by signature.zh / DELvEK.NET\\n\");\n"
@"        fprintf(stderr,\n"
@"                \"========================================\\n\");\n"
@"\n"
@"        for (NSString *name in AVX512SelectedClasses()) {\n"
@"            Class cls = NSClassFromString(name);\n"
@"\n"
@"            if (!cls) {\n"
@"                fprintf(stderr,\n"
@"                        \"[AVX512] Class not found: %s\\n\",\n"
@"                        name.UTF8String);\n"
@"                continue;\n"
@"            }\n"
@"\n"
@"            AVX512PrintClass(cls);\n"
@"        }\n"
@"\n"
@"        fprintf(stderr,\n"
@"                \"========================================\\n\\n\");\n"
@"    }\n"
@"}\n"
@"\n"
@"__attribute__((constructor))\n"
@"static void AVX512Constructor(void)\n"
@"{\n"
@"    AVX512PrintSelectedRuntimeMetadata();\n"
@"}\n"];

    return source;
}

#pragma mark - Build Script

- (NSString *)generatedBuildScript
{
    return
@"#!/bin/bash\n"
@"set -euo pipefail\n"
@"\n"
@"ROOT=\"$(cd \"$(dirname \"$0\")\" && pwd)\"\n"
@"SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
@"OUT=\"$ROOT/build\"\n"
@"\n"
@"mkdir -p \"$OUT\"\n"
@"\n"
@"clang \\\n"
@"  -isysroot \"$SDK\" \\\n"
@"  -arch arm64 \\\n"
@"  -miphoneos-version-min=14.0 \\\n"
@"  -fobjc-arc \\\n"
@"  -dynamiclib \\\n"
@"  -framework Foundation \\\n"
@"  -framework UIKit \\\n"
@"  -O2 \\\n"
@"  -Wall \\\n"
@"  -Wextra \\\n"
@"  \"$ROOT/AVX512Hook.m\" \\\n"
@"  -o \"$OUT/AVX512Hook-arm64.dylib\"\n"
@"\n"
@"clang \\\n"
@"  -isysroot \"$SDK\" \\\n"
@"  -arch arm64e \\\n"
@"  -miphoneos-version-min=14.0 \\\n"
@"  -fobjc-arc \\\n"
@"  -dynamiclib \\\n"
@"  -framework Foundation \\\n"
@"  -framework UIKit \\\n"
@"  -O2 \\\n"
@"  -Wall \\\n"
@"  -Wextra \\\n"
@"  \"$ROOT/AVX512Hook.m\" \\\n"
@"  -o \"$OUT/AVX512Hook-arm64e.dylib\"\n"
@"\n"
@"lipo -create \\\n"
@"  \"$OUT/AVX512Hook-arm64.dylib\" \\\n"
@"  \"$OUT/AVX512Hook-arm64e.dylib\" \\\n"
@"  -output \"$OUT/AVX512Hook.dylib\"\n"
@"\n"
@"if command -v ldid >/dev/null 2>&1; then\n"
@"    ldid -S \"$OUT/AVX512Hook.dylib\"\n"
@"fi\n"
@"\n"
@"file \"$OUT/AVX512Hook.dylib\"\n"
@"lipo -info \"$OUT/AVX512Hook.dylib\"\n";
}

#pragma mark - GitHub Actions

- (NSString *)generatedGitHubActions
{
    return
@"name: Build AVX512 Dylib\n"
@"\n"
@"on:\n"
@"  push:\n"
@"    branches: [main]\n"
@"  workflow_dispatch:\n"
@"\n"
@"jobs:\n"
@"  build:\n"
@"    runs-on: macos-15\n"
@"\n"
@"    steps:\n"
@"      - name: Checkout\n"
@"        uses: actions/checkout@v4\n"
@"\n"
@"      - name: Show Xcode\n"
@"        run: xcodebuild -version\n"
@"\n"
@"      - name: Install ldid\n"
@"        run: brew install ldid\n"
@"\n"
@"      - name: Build arm64\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"          SDK=$(xcrun --sdk iphoneos --show-sdk-path)\n"
@"          CLANG=$(xcrun --sdk iphoneos -f clang)\n"
@"          mkdir -p build\n"
@"\n"
@"          \"$CLANG\" \\\n"
@"            -isysroot \"$SDK\" \\\n"
@"            -arch arm64 \\\n"
@"            -miphoneos-version-min=14.0 \\\n"
@"            -fobjc-arc \\\n"
@"            -dynamiclib \\\n"
@"            -framework Foundation \\\n"
@"            -framework UIKit \\\n"
@"            -O2 \\\n"
@"            -Wall \\\n"
@"            -Wextra \\\n"
@"            AVX512Hook.m \\\n"
@"            -o build/AVX512Hook-arm64.dylib\n"
@"\n"
@"      - name: Build arm64e\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"          SDK=$(xcrun --sdk iphoneos --show-sdk-path)\n"
@"          CLANG=$(xcrun --sdk iphoneos -f clang)\n"
@"\n"
@"          \"$CLANG\" \\\n"
@"            -isysroot \"$SDK\" \\\n"
@"            -arch arm64e \\\n"
@"            -miphoneos-version-min=14.0 \\\n"
@"            -fobjc-arc \\\n"
@"            -dynamiclib \\\n"
@"            -framework Foundation \\\n"
@"            -framework UIKit \\\n"
@"            -O2 \\\n"
@"            -Wall \\\n"
@"            -Wextra \\\n"
@"            AVX512Hook.m \\\n"
@"            -o build/AVX512Hook-arm64e.dylib\n"
@"\n"
@"      - name: Create universal dylib\n"
@"        run: |\n"
@"          lipo -create \\\n"
@"            build/AVX512Hook-arm64.dylib \\\n"
@"            build/AVX512Hook-arm64e.dylib \\\n"
@"            -output build/AVX512Hook.dylib\n"
@"\n"
@"      - name: Sign dylib\n"
@"        run: |\n"
@"          ldid -S build/AVX512Hook.dylib\n"
@"\n"
@"      - name: Package project\n"
@"        run: |\n"
@"          zip -r AVX512Generated.zip . \\\n"
@"            -x '.git/*' \\\n"
@"            -x 'build/*'\n"
@"\n"
@"      - name: Upload dylib\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: AVX512-dylib\n"
@"          path: build/AVX512Hook.dylib\n"
@"\n"
@"      - name: Upload project\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: AVX512-project\n"
@"          path: AVX512Generated.zip\n";
}

#pragma mark - README

- (NSString *)generatedREADME:
            (AVX512DylibType)dylibType
        buildStyle:
            (AVX512BuildStyle)buildStyle
{
    NSMutableString *classes =
        [NSMutableString string];

    NSArray *selected =
        [[self.selectedClasses allObjects]
            sortedArrayUsingSelector:
                @selector(localizedCaseInsensitiveCompare:)];

    for (NSString *name in selected) {
        [classes appendFormat:@"- `%@`\n", name];
    }

    NSString *type =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    NSString *build =
        buildStyle == AVX512BuildStyleShell
            ? @"`build.sh`"
            : @"GitHub Actions (`.github/workflows/build.yml`)";

    return [NSString stringWithFormat:
@"# AVX512 Generated Dylib\n"
@"\n"
@"Generated by **signature.zh — AVX512 / DELvEK.NET**.\n"
@"\n"
@"## Type\n"
@"%@\n"
@"\n"
@"## Selected Classes\n"
@"%@\n"
@"## Runtime Metadata\n"
@"The generated dylib reports runtime metadata for the selected classes:\n"
@"\n"
@"- Class name\n"
@"- Superclass\n"
@"- Direct method count\n"
@"- Selector names\n"
@"- Return type classification\n"
@"- Explicit argument count\n"
@"- Objective-C type encoding\n"
@"\n"
@"The generator does not infer arbitrary method ABIs or modify method "
@"implementations from metadata alone.\n"
@"\n"
@"## Build\n"
@"Use %@.\n"
@"\n"
@"## Branding\n"
@"signature.zh — AVX512 by DELvEK.NET.\n",
        type,
        classes,
        build];
}

#pragma mark - File Writing

- (BOOL)writeString:(NSString *)string
            toPath:(NSString *)path
             error:(NSError **)error
{
    return [string writeToFile:path
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:error];
}

#pragma mark - Share

- (void)shareProject:(NSString *)root
{
    NSFileManager *fm =
        [NSFileManager defaultManager];

    NSArray<NSString *> *paths =
        [fm subpathsAtPath:root];

    NSMutableArray *items =
        [NSMutableArray array];

    for (NSString *relativePath in paths) {

        NSString *fullPath =
            [root stringByAppendingPathComponent:
                relativePath];

        BOOL directory = NO;

        if ([fm fileExistsAtPath:fullPath
                      isDirectory:&directory] &&
            !directory) {

            [items addObject:
                [NSURL fileURLWithPath:fullPath]];
        }
    }

    if (items.count == 0) {
        [self showError:
            @"The generated project contains no files."];

        return;
    }

    UIActivityViewController *activity =
        [[UIActivityViewController alloc]
            initWithActivityItems:items
            applicationActivities:nil];

    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:activity
                         animated:YES
                       completion:nil];
}

#pragma mark - Error

- (void)showError:(NSString *)message
{
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Generation Failed"
                               message:message ?: @"Unknown error."
                        preferredStyle:
                            UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"OK"
                      style:UIAlertActionStyleDefault
                    handler:nil]];

    [self presentViewController:alert
                         animated:YES
                       completion:nil];
}

#pragma mark - String Escaping

- (NSString *)escapedString:(NSString *)string
{
    NSString *result =
        [string stringByReplacingOccurrencesOfString:@"\\"
                                          withString:@"\\\\"];

    result =
        [result stringByReplacingOccurrencesOfString:@"\""
                                          withString:@"\\\""];

    result =
        [result stringByReplacingOccurrencesOfString:@"\n"
                                          withString:@"\\n"];

    return result;
}

@end