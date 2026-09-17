//
//  AVX512HookTemplateGenerator.m
//  AVX512HookTemplateGenerator
//
//  AVX512 by DELvEK.NET
//

#import "AVX512HookTemplateGenerator.h"

#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - Enums

typedef NS_ENUM(NSInteger, AVX512DylibType) {
    AVX512DylibTypeDiagnostic = 0,
    AVX512DylibTypeTestHarness
};

typedef NS_ENUM(NSInteger, AVX512BuildStyle) {
    AVX512BuildStyleShell = 0,
    AVX512BuildStyleGitHubActions
};

#pragma mark - Runtime Metadata

@interface AVX512MethodInfo : NSObject

@property (nonatomic, copy) NSString *selectorName;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *returnType;
@property (nonatomic, assign) NSUInteger argumentCount;
@property (nonatomic, assign) BOOL inherited;

@end

@implementation AVX512MethodInfo
@end

@interface AVX512ClassInfo : NSObject

@property (nonatomic, assign) Class cls;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *superclassName;
@property (nonatomic, strong) NSArray<AVX512MethodInfo *> *methods;

@end

@implementation AVX512ClassInfo
@end

#pragma mark - Helpers

static NSString *AVX512HumanType(const char *encoding)
{
    if (!encoding || encoding[0] == '\0') {
        return @"Unknown";
    }

    switch (encoding[0]) {
        case 'v':
            return @"void";
        case '@':
            return @"object";
        case '#':
            return @"Class";
        case ':':
            return @"SEL";
        case 'c':
            return @"char / BOOL";
        case 'i':
            return @"int";
        case 's':
            return @"short";
        case 'l':
            return @"long";
        case 'q':
            return @"long long";
        case 'C':
            return @"unsigned char";
        case 'I':
            return @"unsigned int";
        case 'S':
            return @"unsigned short";
        case 'L':
            return @"unsigned long";
        case 'Q':
            return @"unsigned long long";
        case 'f':
            return @"float";
        case 'd':
            return @"double";
        case 'B':
            return @"BOOL";
        case '^':
            return @"pointer";
        case '{':
            return @"struct";
        case '[':
            return @"array";
        case 'b':
            return @"bit-field";
        default:
            return [NSString stringWithFormat:@"encoding %c", encoding[0]];
    }
}

static NSString *AVX512SymbolName(void)
{
    if (@available(iOS 13.0, *)) {
        return @"signature";
    }

    return @"pencil.and.outline";
}

static NSUInteger AVX512ExplicitArgumentCount(Method method)
{
    if (!method) {
        return 0;
    }

    unsigned int count = method_getNumberOfArguments(method);

    if (count < 2) {
        return 0;
    }

    return count - 2;
}

static NSArray<AVX512MethodInfo *> *AVX512MethodsForClass(Class cls)
{
    if (!cls) {
        return @[];
    }

    NSMutableArray<AVX512MethodInfo *> *result = [NSMutableArray array];
    NSMutableSet<NSString *> *seenSelectors = [NSMutableSet set];

    Class current = cls;
    BOOL inherited = NO;

    while (current) {
        unsigned int count = 0;
        Method *methods = class_copyMethodList(current, &count);

        if (methods) {
            for (unsigned int i = 0; i < count; i++) {
                Method method = methods[i];

                SEL selector = method_getName(method);
                if (!selector) {
                    continue;
                }

                NSString *selectorName = NSStringFromSelector(selector);

                if ([seenSelectors containsObject:selectorName]) {
                    continue;
                }

                [seenSelectors addObject:selectorName];

                const char *encoding = method_getTypeEncoding(method);

                AVX512MethodInfo *info = [AVX512MethodInfo new];
                info.selectorName = selectorName;
                info.typeEncoding = encoding
                    ? [NSString stringWithUTF8String:encoding]
                    : @"";
                info.returnType = AVX512HumanType(
                    encoding ? method_copyReturnType(method) : NULL
                );
                info.argumentCount = AVX512ExplicitArgumentCount(method);
                info.inherited = inherited;

                /*
                 method_copyReturnType() allocates memory.
                 Re-query it here so the ownership is handled safely.
                 */
                if (encoding) {
                    char *returnType = method_copyReturnType(method);

                    if (returnType) {
                        info.returnType = AVX512HumanType(returnType);
                        free(returnType);
                    }
                }

                [result addObject:info];
            }

            free(methods);
        }

        current = class_getSuperclass(current);
        inherited = YES;
    }

    [result sortUsingComparator:^NSComparisonResult(AVX512MethodInfo *a,
                                                    AVX512MethodInfo *b) {
        return [a.selectorName localizedCaseInsensitiveCompare:b.selectorName];
    }];

    return result;
}

static AVX512ClassInfo *AVX512InspectRuntimeClass(Class cls)
{
    AVX512ClassInfo *info = [AVX512ClassInfo new];

    info.cls = cls;
    info.className = NSStringFromClass(cls);

    Class superclass = class_getSuperclass(cls);

    info.superclassName = superclass
        ? NSStringFromClass(superclass)
        : @"None";

    info.methods = AVX512MethodsForClass(cls);

    return info;
}

#pragma mark - Inspector

@interface AVX512ClassInspectorController : UITableViewController

@property (nonatomic, strong) AVX512ClassInfo *classInfo;
@property (nonatomic, strong) NSArray<NSDictionary *> *sections;

@end

@implementation AVX512ClassInspectorController

- (instancetype)initWithClassInfo:(AVX512ClassInfo *)classInfo
{
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _classInfo = classInfo;
        _sections = @[];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.classInfo.className;

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                      target:self
                                                      action:@selector(close)];

    UIBarButtonItem *signatureButton =
        [[UIBarButtonItem alloc] initWithImage:
            [UIImage systemImageNamed:AVX512SymbolName()]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(makeDylib)];

    signatureButton.accessibilityLabel = @"Make Dylib";

    self.navigationItem.rightBarButtonItem = signatureButton;

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80.0;

    [self buildSections];
}

- (void)buildSections
{
    NSMutableArray *sections = [NSMutableArray array];

    [sections addObject:@{
        @"title": @"CLASS",
        @"kind": @"class"
    }];

    [sections addObject:@{
        @"title": @"WHAT THIS CLASS IS",
        @"kind": @"explanation"
    }];

    [sections addObject:@{
        @"title": @"METHODS",
        @"kind": @"methods"
    }];

    [sections addObject:@{
        @"title": @"HOW TO READ THIS",
        @"kind": @"help"
    }];

    self.sections = sections;
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)makeDylib
{
    /*
     The inspector's signature button deliberately sends the user back
     into the generator rather than silently generating anything.
     */

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSString *kind = self.sections[section][@"kind"];

    if ([kind isEqualToString:@"methods"]) {
        return self.classInfo.methods.count;
    }

    return 1;
}

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section][@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *kind = self.sections[indexPath.section][@"kind"];

    if ([kind isEqualToString:@"class"]) {
        UITableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"class"];

        if (!cell) {
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:@"class"];
        }

        cell.textLabel.text = self.classInfo.className;

        cell.detailTextLabel.text =
            [NSString stringWithFormat:@"Superclass: %@\nMethods: %lu",
             self.classInfo.superclassName,
             (unsigned long)self.classInfo.methods.count];

        cell.detailTextLabel.numberOfLines = 2;

        cell.imageView.image =
            [UIImage systemImageNamed:@"shippingbox"];

        return cell;
    }

    if ([kind isEqualToString:@"explanation"]) {
        UITableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"explanation"];

        if (!cell) {
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"explanation"];
        }

        NSString *text =
            [NSString stringWithFormat:
                @"The runtime reports this object as an Objective-C class named "
                 "\"%@\". It inherits from %@. The method list below combines "
                 "methods declared directly by this class with methods visible "
                 "through its superclass chain.\n\n"
                 "This metadata describes the runtime interface. It does not "
                 "prove what a method actually does internally.",
                self.classInfo.className,
                self.classInfo.superclassName];

        cell.textLabel.text = text;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font =
            [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

        return cell;
    }

    if ([kind isEqualToString:@"help"]) {
        UITableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"help"];

        if (!cell) {
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"help"];
        }

        cell.textLabel.text =
            @"Selector = the Objective-C method name.\n\n"
             "Declared = implemented directly by this class.\n\n"
             "Inherited = found while walking the superclass chain.\n\n"
             "Arguments = explicit method arguments, excluding self and _cmd.\n\n"
             "Encoding = the raw Objective-C runtime type encoding.\n\n"
             "The encoding is useful when writing controlled runtime diagnostics "
             "because it describes the method's ABI-level type information. "
             "It does not reveal the implementation's business logic.";

        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font =
            [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

        return cell;
    }

    AVX512MethodInfo *methodInfo = self.classInfo.methods[indexPath.row];

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"method"];

    if (!cell) {
        cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:@"method"];
    }

    cell.textLabel.text = methodInfo.selectorName;

    cell.detailTextLabel.text =
        [NSString stringWithFormat:
            @"%@  •  %@  •  %lu args  •  %@",
            methodInfo.inherited ? @"Inherited" : @"Declared",
            methodInfo.returnType,
            (unsigned long)methodInfo.argumentCount,
            methodInfo.typeEncoding];

    cell.detailTextLabel.numberOfLines = 0;

    cell.imageView.image =
        [UIImage systemImageNamed:
            methodInfo.inherited
                ? @"arrow.turn.up.right"
                : @"function"];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *kind = self.sections[indexPath.section][@"kind"];

    if (![kind isEqualToString:@"methods"]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    AVX512MethodInfo *methodInfo =
        self.classInfo.methods[indexPath.row];

    NSString *message =
        [NSString stringWithFormat:
            @"Selector\n%@\n\n"
             @"Runtime status\n%@\n\n"
             @"Return type\n%@\n\n"
             @"Explicit arguments\n%lu\n\n"
             @"Type encoding\n%@\n\n"
             @"The runtime metadata tells you how Objective-C describes "
             "this method. It does not reveal the method's implementation "
             "or guarantee what the selector means internally.",
            methodInfo.selectorName,
            methodInfo.inherited ? @"Inherited" : @"Declared by this class",
            methodInfo.returnType,
            (unsigned long)methodInfo.argumentCount,
            methodInfo.typeEncoding];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:methodInfo.selectorName
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Done"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

#pragma mark - Generator

@interface AVX512HookTemplateGenerator () <
    UISearchResultsUpdating
>

@property (nonatomic, strong) NSArray<NSString *> *allClasses;
@property (nonatomic, strong) NSArray<NSString *> *filteredClasses;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedClasses;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation AVX512HookTemplateGenerator

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"AVX512 Dylib Generator";

    self.selectedClasses = [NSMutableSet set];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                 target:self
                                 action:@selector(closeGenerator)];

    UIBarButtonItem *signatureButton =
        [[UIBarButtonItem alloc]
            initWithImage:[UIImage systemImageNamed:AVX512SymbolName()]
                   style:UIBarButtonItemStylePlain
                  target:self
                  action:@selector(generate)];

    signatureButton.accessibilityLabel = @"Make Dylib";

    self.navigationItem.rightBarButtonItem = signatureButton;

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 72.0;

    self.searchController =
        [[UISearchController alloc] initWithSearchResultsController:nil];

    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;

    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;

    [self loadRuntimeClasses];
}

#pragma mark - Navigation

- (void)closeGenerator
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Runtime Classes

- (void)loadRuntimeClasses
{
    unsigned int count = 0;

    Class *classes = objc_copyClassList(&count);

    NSMutableArray<NSString *> *names =
        [NSMutableArray arrayWithCapacity:count];

    if (classes) {
        for (unsigned int i = 0; i < count; i++) {
            Class cls = classes[i];

            if (!cls) {
                continue;
            }

            NSString *name = NSStringFromClass(cls);

            if (name.length == 0) {
                continue;
            }

            [names addObject:name];
        }

        free(classes);
    }

    [names sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    self.allClasses = names;
    self.filteredClasses = names;

    [self.tableView reloadData];
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
    NSString *query =
        searchController.searchBar.text.lowercaseString;

    if (query.length == 0) {
        self.filteredClasses = self.allClasses;
    } else {
        NSMutableArray *matches = [NSMutableArray array];

        for (NSString *name in self.allClasses) {
            if ([name.lowercaseString containsString:query]) {
                [matches addObject:name];
            }
        }

        self.filteredClasses = matches;
    }

    [self.tableView reloadData];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.filteredClasses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"AVX512ClassCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:identifier];
    }

    NSString *className = self.filteredClasses[indexPath.row];

    cell.textLabel.text = className;

    cell.detailTextLabel.text =
        [self.selectedClasses containsObject:className]
            ? @"Selected • Tap to inspect"
            : @"Tap to inspect runtime metadata";

    cell.detailTextLabel.numberOfLines = 1;

    cell.imageView.image =
        [UIImage systemImageNamed:@"shippingbox"];

    cell.accessoryType =
        [self.selectedClasses containsObject:className]
            ? UITableViewCellAccessoryCheckmark
            : UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *className = self.filteredClasses[indexPath.row];

    Class cls = NSClassFromString(className);

    if (!cls) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    /*
     Selection is independent from inspection.
     Tapping a class both selects it for generation and opens the
     human-readable runtime inspector.
     */

    if ([self.selectedClasses containsObject:className]) {
        [self.selectedClasses removeObject:className];
    } else {
        [self.selectedClasses addObject:className];
    }

    [tableView reloadRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];

    AVX512ClassInfo *info =
        AVX512InspectRuntimeClass(cls);

    AVX512ClassInspectorController *inspector =
        [[AVX512ClassInspectorController alloc]
            initWithClassInfo:info];

    UINavigationController *navigation =
        [[UINavigationController alloc]
            initWithRootViewController:inspector];

    navigation.modalPresentationStyle = UIModalPresentationPageSheet;

    [self presentViewController:navigation
                         animated:YES
                       completion:nil];
}

#pragma mark - Generation

- (void)generate
{
    if (self.selectedClasses.count == 0) {
        UIAlertController *alert =
            [UIAlertController
                alertControllerWithTitle:@"No Classes Selected"
                                   message:@"Select at least one runtime class first."
                            preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:
            [UIAlertAction actionWithTitle:@"OK"
                                     style:UIAlertActionStyleDefault
                                   handler:nil]];

        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    UIAlertController *typeAlert =
        [UIAlertController
            alertControllerWithTitle:@"Dylib Type"
                               message:@"Choose the generated dylib behavior."
                        preferredStyle:UIAlertControllerStyleActionSheet];

    [typeAlert addAction:
        [UIAlertAction actionWithTitle:@"Runtime Diagnostic"
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action) {
        [self chooseBuildStyle:AVX512DylibTypeDiagnostic];
    }]];

    [typeAlert addAction:
        [UIAlertAction actionWithTitle:@"Runtime Test Harness"
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action) {
        [self chooseBuildStyle:AVX512DylibTypeTestHarness];
    }]];

    [typeAlert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    if (typeAlert.popoverPresentationController) {
        typeAlert.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:typeAlert
                         animated:YES
                       completion:nil];
}

- (void)chooseBuildStyle:(AVX512DylibType)dylibType
{
    UIAlertController *buildAlert =
        [UIAlertController
            alertControllerWithTitle:@"Build Output"
                               message:@"Choose how the generated project should build."
                        preferredStyle:UIAlertControllerStyleActionSheet];

    [buildAlert addAction:
        [UIAlertAction actionWithTitle:@"Shell Script"
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action) {
        [self writeProjectForType:dylibType
                       buildStyle:AVX512BuildStyleShell];
    }]];

    [buildAlert addAction:
        [UIAlertAction actionWithTitle:@"GitHub Actions"
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action) {
        [self writeProjectForType:dylibType
                       buildStyle:AVX512BuildStyleGitHubActions];
    }]];

    [buildAlert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:buildAlert
                         animated:YES
                       completion:nil];
}

#pragma mark - Project Generation

- (void)writeProjectForType:(AVX512DylibType)dylibType
                 buildStyle:(AVX512BuildStyle)buildStyle
{
    NSString *root =
        [NSTemporaryDirectory()
            stringByAppendingPathComponent:
                [NSString stringWithFormat:
                    @"AVX512Generated-%@",
                    NSUUID.UUID.UUIDString]];

    NSFileManager *fm = [NSFileManager defaultManager];

    NSError *error = nil;

    if (![fm createDirectoryAtPath:root
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error]) {

        [self showError:error.localizedDescription];
        return;
    }

    NSString *header =
        [self generatedHeader];

    NSString *implementation =
        [self generatedImplementationForType:dylibType];

    NSString *readme =
        [self generatedREADMEForType:dylibType
                         buildStyle:buildStyle];

    if (![self writeString:header
                    toPath:[root stringByAppendingPathComponent:@"AVX512Hook.h"]
                     error:&error] ||
        ![self writeString:implementation
                    toPath:[root stringByAppendingPathComponent:@"AVX512Hook.m"]
                     error:&error] ||
        ![self writeString:readme
                    toPath:[root stringByAppendingPathComponent:@"README.md"]
                     error:&error]) {

        [self showError:error.localizedDescription];
        return;
    }

    if (buildStyle == AVX512BuildStyleShell) {

        NSString *build =
            [self generatedBuildScript];

        if (![self writeString:build
                        toPath:[root stringByAppendingPathComponent:@"build.sh"]
                         error:&error]) {

            [self showError:error.localizedDescription];
            return;
        }

    } else {

        NSString *workflowDirectory =
            [root stringByAppendingPathComponent:@".github/workflows"];

        if (![fm createDirectoryAtPath:workflowDirectory
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error]) {

            [self showError:error.localizedDescription];
            return;
        }

        NSString *workflow =
            [self generatedGitHubActions];

        NSString *workflowPath =
            [workflowDirectory
                stringByAppendingPathComponent:@"build.yml"];

        if (![self writeString:workflow
                        toPath:workflowPath
                         error:&error]) {

            [self showError:error.localizedDescription];
            return;
        }
    }

    [self shareGeneratedProject:root];
}

- (BOOL)writeString:(NSString *)string
            toPath:(NSString *)path
             error:(NSError **)error
{
    return [string writeToFile:path
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:error];
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

- (NSString *)generatedImplementationForType:
    (AVX512DylibType)dylibType
{
    NSMutableString *classes = [NSMutableString string];

    NSArray *sorted =
        [[self.selectedClasses allObjects]
            sortedArrayUsingSelector:
                @selector(localizedCaseInsensitiveCompare:)];

    for (NSString *className in sorted) {
        [classes appendFormat:@"    @\"%@\",\n",
            [self escapedString:className]];
    }

    NSString *mode =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    return [NSString stringWithFormat:
@"//\n"
 @"// AVX512Hook.m\n"
 @"// Generated by signature.zh — AVX512 / DELvEK.NET\n"
 @"//\n"
 @"\n"
 @"#import \"AVX512Hook.h\"\n"
 @"#import <objc/runtime.h>\n"
 @"\n"
 @"static NSArray<NSString *> *AVX512SelectedClasses(void)\n"
 @"{\n"
 @"    return @[\n"
 @"%@"
 @"    ];\n"
 @"}\n"
 @"\n"
 @"static NSString *AVX512ReturnType(const char *encoding)\n"
 @"{\n"
 @"    if (!encoding || encoding[0] == '\\0') return @\"Unknown\";\n"
 @"\n"
 @"    switch (encoding[0]) {\n"
 @"        case 'v': return @\"void\";\n"
 @"        case '@': return @\"object\";\n"
 @"        case '#': return @\"Class\";\n"
 @"        case ':': return @\"SEL\";\n"
 @"        case 'c': return @\"char / BOOL\";\n"
 @"        case 'i': return @\"int\";\n"
 @"        case 'q': return @\"long long\";\n"
 @"        case 'Q': return @\"unsigned long long\";\n"
 @"        case 'f': return @\"float\";\n"
 @"        case 'd': return @\"double\";\n"
 @"        case 'B': return @\"BOOL\";\n"
 @"        case '^': return @\"pointer\";\n"
 @"        case '{': return @\"struct\";\n"
 @"        default: return [NSString stringWithFormat:@\"encoding %%c\", encoding[0]];\n"
 @"    }\n"
 @"}\n"
 @"\n"
 @"static NSUInteger AVX512ExplicitArguments(Method method)\n"
 @"{\n"
 @"    unsigned int count = method_getNumberOfArguments(method);\n"
 @"    return count >= 2 ? count - 2 : 0;\n"
 @"}\n"
 @"\n"
 @"static void AVX512PrintClass(Class cls)\n"
 @"{\n"
 @"    if (!cls) return;\n"
 @"\n"
 @"    fprintf(stderr, \"\\\\n[AVX512] Class: %%s\\\\n\", class_getName(cls));\n"
 @"\n"
 @"    Class superclass = class_getSuperclass(cls);\n"
 @"    if (superclass) {\n"
 @"        fprintf(stderr, \"[AVX512] Superclass: %%s\\\\n\", class_getName(superclass));\n"
 @"    }\n"
 @"\n"
 @"    unsigned int count = 0;\n"
 @"    Method *methods = class_copyMethodList(cls, &count);\n"
 @"\n"
 @"    fprintf(stderr, \"[AVX512] Direct methods: %%u\\\\n\", count);\n"
 @"\n"
 @"    for (unsigned int i = 0; i < count; i++) {\n"
 @"        Method method = methods[i];\n"
 @"        SEL selector = method_getName(method);\n"
 @"        const char *encoding = method_getTypeEncoding(method);\n"
 @"\n"
 @"        fprintf(stderr,\n"
 @"                \"[AVX512]   %%s | return=%%s | args=%%lu | encoding=%%s\\\\n\",\n"
 @"                sel_getName(selector),\n"
 @"                AVX512ReturnType(encoding).UTF8String,\n"
 @"                (unsigned long)AVX512ExplicitArguments(method),\n"
 @"                encoding ?: \"\");\n"
 @"    }\n"
 @"\n"
 @"    if (methods) free(methods);\n"
 @"}\n"
 @"\n"
 @"void AVX512PrintSelectedRuntimeMetadata(void)\n"
 @"{\n"
 @"    @autoreleasepool {\n"
 @"        fprintf(stderr, \"\\\\n========================================\\\\n\");\n"
 @"        fprintf(stderr, \"AVX512 — %@\\\\n\");\n"
 @"        fprintf(stderr, \"Generated by signature.zh / DELvEK.NET\\\\n\");\n"
 @"        fprintf(stderr, \"========================================\\\\n\");\n"
 @"\n"
 @"        for (NSString *name in AVX512SelectedClasses()) {\n"
 @"            Class cls = NSClassFromString(name);\n"
 @"\n"
 @"            if (!cls) {\n"
 @"                fprintf(stderr, \"[AVX512] Class not found: %%s\\\\n\", name.UTF8String);\n"
 @"                continue;\n"
 @"            }\n"
 @"\n"
 @"            AVX512PrintClass(cls);\n"
 @"        }\n"
 @"\n"
 @"        fprintf(stderr, \"========================================\\\\n\\\\n\");\n"
 @"    }\n"
 @"}\n"
 @"\n"
 @"__attribute__((constructor))\n"
 @"static void AVX512Constructor(void)\n"
 @"{\n"
 @"    AVX512PrintSelectedRuntimeMetadata();\n"
 @"}\n",
        classes,
        mode];
}

#pragma mark - Build Script

- (NSString *)generatedBuildScript
{
    return
@"#!/bin/bash\n"
 @"set -euo pipefail\n"
 @"\n"
 @"ROOT=\"$(cd \"$(dirname \"$0\")\" && pwd)\"\n"
 @"OUT=\"$ROOT/build\"\n"
 @"SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
 @"\n"
 @"mkdir -p \"$OUT\"\n"
 @"\n"
 @"echo \"== AVX512 arm64 ==\"\n"
 @"clang \\\n"
 @"  -isysroot \"$SDK\" \\\n"
 @"  -arch arm64 \\\n"
 @"  -fobjc-arc \\\n"
 @"  -O2 \\\n"
 @"  -Wall \\\n"
 @"  -Wextra \\\n"
 @"  -dynamiclib \\\n"
 @"  -framework Foundation \\\n"
 @"  \"$ROOT/AVX512Hook.m\" \\\n"
 @"  -o \"$OUT/AVX512Hook-arm64.dylib\"\n"
 @"\n"
 @"echo \"== AVX512 arm64e ==\"\n"
 @"clang \\\n"
 @"  -isysroot \"$SDK\" \\\n"
 @"  -arch arm64e \\\n"
 @"  -fobjc-arc \\\n"
 @"  -O2 \\\n"
 @"  -Wall \\\n"
 @"  -Wextra \\\n"
 @"  -dynamiclib \\\n"
 @"  -framework Foundation \\\n"
 @"  \"$ROOT/AVX512Hook.m\" \\\n"
 @"  -o \"$OUT/AVX512Hook-arm64e.dylib\"\n"
 @"\n"
 @"echo \"== Creating universal dylib ==\"\n"
 @"lipo -create \\\n"
 @"  \"$OUT/AVX512Hook-arm64.dylib\" \\\n"
 @"  \"$OUT/AVX512Hook-arm64e.dylib\" \\\n"
 @"  -output \"$OUT/AVX512Hook.dylib\"\n"
 @"\n"
 @"if command -v ldid >/dev/null 2>&1; then\n"
 @"  echo \"== Signing with ldid ==\"\n"
 @"  ldid -S \"$OUT/AVX512Hook.dylib\"\n"
 @"else\n"
 @"  echo \"ldid not found; leaving dylib unsigned.\"\n"
 @"fi\n"
 @"\n"
 @"echo\n"
 @"echo \"Built: $OUT/AVX512Hook.dylib\"\n"
 @"file \"$OUT/AVX512Hook.dylib\"\n";
}

#pragma mark - GitHub Actions

- (NSString *)generatedGitHubActions
{
    return
@"name: Build AVX512 Dylib\n"
 @"\n"
 @"on:\n"
 @"  workflow_dispatch:\n"
 @"  push:\n"
 @"    branches: [ main ]\n"
 @"\n"
 @"jobs:\n"
 @"  build:\n"
 @"    runs-on: macos-15\n"
 @"\n"
 @"    steps:\n"
 @"      - name: Checkout\n"
 @"        uses: actions/checkout@v4\n"
 @"\n"
 @"      - name: Select Xcode\n"
 @"        uses: maxim-lobanov/setup-xcode@v1\n"
 @"        with:\n"
 @"          xcode-version: latest-stable\n"
 @"\n"
 @"      - name: Install ldid\n"
 @"        run: brew install ldid\n"
 @"\n"
 @"      - name: Build arm64\n"
 @"        run: |\n"
 @"          SDK=$(xcrun --sdk iphoneos --show-sdk-path)\n"
 @"          mkdir -p build\n"
 @"          clang \\\n"
 @"            -isysroot \"$SDK\" \\\n"
 @"            -arch arm64 \\\n"
 @"            -fobjc-arc \\\n"
 @"            -O2 \\\n"
 @"            -Wall \\\n"
 @"            -Wextra \\\n"
 @"            -dynamiclib \\\n"
 @"            -framework Foundation \\\n"
 @"            AVX512Hook.m \\\n"
 @"            -o build/AVX512Hook-arm64.dylib\n"
 @"\n"
 @"      - name: Build arm64e\n"
 @"        run: |\n"
 @"          SDK=$(xcrun --sdk iphoneos --show-sdk-path)\n"
 @"          clang \\\n"
 @"            -isysroot \"$SDK\" \\\n"
 @"            -arch arm64e \\\n"
 @"            -fobjc-arc \\\n"
 @"            -O2 \\\n"
 @"            -Wall \\\n"
 @"            -Wextra \\\n"
 @"            -dynamiclib \\\n"
 @"            -framework Foundation \\\n"
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
 @"            -x 'build/*.dylib'\n"
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

- (NSString *)generatedREADMEForType:(AVX512DylibType)dylibType
                          buildStyle:(AVX512BuildStyle)buildStyle
{
    NSMutableString *selected = [NSMutableString string];

    NSArray *classes =
        [[self.selectedClasses allObjects]
            sortedArrayUsingSelector:
                @selector(localizedCaseInsensitiveCompare:)];

    for (NSString *className in classes) {
        [selected appendFormat:@"- `%@`\n", className];
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
 @"Generated by **signature.zh** / **AVX512** / **DELvEK.NET**.\n"
 @"\n"
 @"## Type\n"
 @"%@\n"
 @"\n"
 @"## Selected Classes\n"
 @"%@"
 @"\n"
 @"## What It Does\n"
 @"The generated dylib performs controlled Objective-C runtime metadata "
 @"inspection for the selected classes.\n"
 @"\n"
 @"At load time it reports:\n"
 @"\n"
 @"- Class name\n"
 @"- Superclass\n"
 @"- Direct method count\n"
 @"- Selector names\n"
 @"- Runtime type encodings\n"
 @"- Return type classification\n"
 @"- Explicit argument count\n"
 @"\n"
 @"The generator intentionally does not guess arbitrary Objective-C method "
 @"signatures or replace method implementations. Runtime metadata alone does "
 @"not establish what a method's implementation does.\n"
 @"\n"
 @"## Build\n"
 @"Use %@.\n"
 @"\n"
 @"## Output\n"
 @"The resulting universal dylib contains arm64 and arm64e slices.\n"
 @"\n"
 @"## Branding\n"
 @"Generated with signature.zh — AVX512 by DELvEK.NET.\n",
        type,
        selected,
        build];
}

#pragma mark - Sharing

- (void)shareGeneratedProject:(NSString *)root
{
    NSMutableArray *items = [NSMutableArray array];

    NSFileManager *fm = [NSFileManager defaultManager];

    NSArray<NSString *> *files =
        [fm subpathsAtPath:root];

    for (NSString *relativePath in files) {
        NSString *fullPath =
            [root stringByAppendingPathComponent:relativePath];

        BOOL directory = NO;

        if ([fm fileExistsAtPath:fullPath isDirectory:&directory] &&
            !directory) {

            [items addObject:[NSURL fileURLWithPath:fullPath]];
        }
    }

    /*
     We intentionally share the generated files directly instead of invoking
     NSTask/zip from iOS. macOS-only process APIs do not belong inside the
     generator application.
     */

    if (items.count == 0) {
        [self showError:@"The generated project contains no files."];
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

#pragma mark - Errors

- (void)showError:(NSString *)message
{
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Generation Failed"
                               message:message ?: @"Unknown error."
                        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    [self presentViewController:alert
                         animated:YES
                       completion:nil];
}

#pragma mark - Escaping

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

#pragma mark - Legacy Inspector Data Source

@interface AVX512InspectorDataSource ()

@property (nonatomic, strong) NSArray<NSString *> *lines;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) void (^selectionHandler)(void);

@end

@implementation AVX512InspectorDataSource

- (instancetype)initWithLines:(NSArray<NSString *> *)lines
                     className:(NSString *)className
              selectionHandler:(void (^)(void))selectionHandler
{
    self = [super init];

    if (self) {
        _lines = [lines copy];
        _className = [className copy];
        _selectionHandler = [selectionHandler copy];
    }

    return self;
}

- (void)selectClass
{
    if (self.selectionHandler) {
        self.selectionHandler();
    }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.lines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"AVX512LegacyInspectorCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:identifier];
    }

    cell.textLabel.text = self.lines[indexPath.row];
    cell.textLabel.numberOfLines = 0;

    return cell;
}

@end