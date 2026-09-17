//
//  AVX512HookTemplateGenerator.m
//  AVX512 by DELvEK.NET
//
//  Runtime explorer + diagnostic dylib generator.
//
//  Generated project:
//
//      AVX512Generated/
//      ├── AVX512Hook.h
//      ├── AVX512Hook.m
//      ├── README.md
//      ├── build.sh
//      OR
//      └── .github/workflows/build.yml
//
//  Signature.zh · MrZEfv
//

#import "AVX512HookTemplateGenerator.h"
#import <objc/runtime.h>

#pragma mark - Models

@interface AVX512MethodInfo : NSObject

@property (nonatomic, copy) NSString *selectorName;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *returnType;
@property (nonatomic, assign) BOOL declaredDirectly;
@property (nonatomic, copy) NSString *declaringClass;

@end

@implementation AVX512MethodInfo
@end


@interface AVX512ClassInfo : NSObject

@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *superclassName;
@property (nonatomic, strong) NSArray<AVX512MethodInfo *> *methods;

@end

@implementation AVX512ClassInfo
@end


#pragma mark - Build Types

typedef NS_ENUM(NSInteger, AVX512BuildStyle) {
    AVX512BuildStyleShell = 0,
    AVX512BuildStyleGitHub = 1
};

typedef NS_ENUM(NSInteger, AVX512DylibType) {
    AVX512DylibTypeDiagnostic = 0,
    AVX512DylibTypeTestHarness = 1
};


#pragma mark - Method Detail Controller

@interface AVX512MethodDetailViewController : UITableViewController

@property (nonatomic, strong) AVX512MethodInfo *methodInfo;
@property (nonatomic, copy) NSString *className;

- (instancetype)initWithMethod:(AVX512MethodInfo *)method
                      className:(NSString *)className;

@end


@implementation AVX512MethodDetailViewController

- (instancetype)initWithMethod:(AVX512MethodInfo *)method
                      className:(NSString *)className
{
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _methodInfo = method;
        _className = [className copy];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Method Details";

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                 target:self
                                 action:@selector(close)];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80.0;
}

- (void)close
{
    if (self.navigationController.presentingViewController) {
        [self.navigationController
            dismissViewControllerAnimated:YES
                               completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)titleForSection:(NSInteger)section
{
    switch (section) {

        case 0:
            return @"SELECTOR";

        case 1:
            return @"RETURN TYPE";

        case 2:
            return @"OBJECTIVE-C TYPE ENCODING";

        case 3:
            return @"ORIGIN";

        case 4:
            return @"ABOUT THIS DATA";

        default:
            return @"";
    }
}

- (NSString *)textForSection:(NSInteger)section
{
    AVX512MethodInfo *method = self.methodInfo;

    switch (section) {

        case 0:
            return method.selectorName ?: @"—";

        case 1:
            return method.returnType ?: @"?";

        case 2:
            return method.typeEncoding ?: @"?";

        case 3:
            return method.declaredDirectly
                ? [NSString stringWithFormat:
                    @"Declared directly by %@", self.className]
                : [NSString stringWithFormat:
                    @"Inherited by %@", self.className];

        case 4:
            return
                @"The selector is the runtime name used to identify "
                @"the method. The Objective-C type encoding describes "
                @"its method ABI, including the return value and "
                @"arguments. AVX512 exposes the raw encoding instead "
                @"of guessing an arbitrary Objective-C function "
                @"signature.";

        default:
            return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    return [self titleForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"MethodDetailCell"];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:@"MethodDetailCell"];
    }

    NSString *text =
        [self textForSection:indexPath.section];

    cell.textLabel.text = text;
    cell.textLabel.numberOfLines = 0;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:
            indexPath.section == 4 ? 13.0 : 14.0
                                   weight:UIFontWeightRegular];

    cell.detailTextLabel.text = nil;

    return cell;
}

@end


#pragma mark - Generator

@interface AVX512HookTemplateGenerator () <UISearchResultsUpdating>

@property (nonatomic, strong) NSArray<NSString *> *allClasses;
@property (nonatomic, strong) NSArray<NSString *> *filteredClasses;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedClasses;
@property (nonatomic, strong) UISearchController *search;

@end


@implementation AVX512HookTemplateGenerator

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Runtime Explorer";

    self.selectedClasses =
        [NSMutableSet set];

    [self loadRuntimeClasses];
    [self configureSearch];
    [self configureSignatureButton];
}

#pragma mark - Runtime Recon

- (void)loadRuntimeClasses
{
    unsigned int count = 0;

    Class *classes =
        objc_copyClassList(&count);

    NSMutableArray<NSString *> *names =
        [NSMutableArray arrayWithCapacity:count];

    for (unsigned int i = 0; i < count; i++) {

        Class cls = classes[i];

        if (!cls) {
            continue;
        }

        const char *name =
            class_getName(cls);

        if (!name) {
            continue;
        }

        NSString *className =
            [NSString stringWithUTF8String:name];

        if (className.length > 0) {
            [names addObject:className];
        }
    }

    free(classes);

    [names sortUsingComparator:
        ^NSComparisonResult(NSString *a, NSString *b) {

        return [a caseInsensitiveCompare:b];
    }];

    self.allClasses =
        [names copy];

    self.filteredClasses =
        [names copy];
}

#pragma mark - Search

- (void)configureSearch
{
    self.search =
        [[UISearchController alloc]
            initWithSearchResultsController:nil];

    self.search.searchResultsUpdater =
        self;

    self.search.obscuresBackgroundDuringPresentation =
        NO;

    self.search.searchBar.placeholder =
        @"Search runtime classes";

    self.navigationItem.searchController =
        self.search;

    self.definesPresentationContext =
        YES;
}

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
    NSString *query =
        searchController.searchBar.text ?: @"";

    if (query.length == 0) {

        self.filteredClasses =
            self.allClasses;

    } else {

        NSPredicate *predicate =
            [NSPredicate predicateWithFormat:
                @"SELF CONTAINS[cd] %@", query];

        self.filteredClasses =
            [self.allClasses
                filteredArrayUsingPredicate:predicate];
    }

    [self.tableView reloadData];
}

#pragma mark - Signature.zh

- (void)configureSignatureButton
{
    UIButton *button =
        [UIButton buttonWithType:UIButtonTypeSystem];

    UIImage *image =
        [UIImage systemImageNamed:@"signature"];

    if (image) {
        [button setImage:image
                forState:UIControlStateNormal];
    }

    [button setTitle:@"  Signature.zh | MrZEfv"
            forState:UIControlStateNormal];

    button.titleLabel.font =
        [UIFont systemFontOfSize:14.0
                           weight:UIFontWeightSemibold];

    button.accessibilityLabel =
        @"Signature.zh by MrZEfv";

    button.accessibilityHint =
        @"Build a diagnostic dylib from the selected runtime classes.";

    [button addTarget:self
               action:@selector(generateProject)
     forControlEvents:UIControlEventTouchUpInside];

    [button sizeToFit];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithCustomView:button];

    [self updateSignatureButton];
}

- (void)updateSignatureButton
{
    UIButton *button =
        (UIButton *)self.navigationItem
            .rightBarButtonItem.customView;

    if (![button isKindOfClass:[UIButton class]]) {
        return;
    }

    NSUInteger count =
        self.selectedClasses.count;

    NSString *title =
        count > 0
            ? [NSString stringWithFormat:
                @"  Signature.zh · MrZEfv (%lu)",
                (unsigned long)count]
            : @"  Signature.zh · MrZEfv";

    [button setTitle:title
            forState:UIControlStateNormal];

    button.accessibilityValue =
        [NSString stringWithFormat:
            @"%lu classes selected",
            (unsigned long)count];
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
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:
            @"RuntimeClassCell"];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:@"RuntimeClassCell"];
    }

    NSString *className =
        self.filteredClasses[indexPath.row];

    Class cls =
        objc_getClass(className.UTF8String);

    Class superClass =
        cls
            ? class_getSuperclass(cls)
            : Nil;

    AVX512ClassInfo *info =
        [self classInfoForName:className];

    NSUInteger methodCount =
        info.methods.count;

    cell.textLabel.text =
        className;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:
            14.0
                                   weight:UIFontWeightMedium];

    NSString *superName =
        superClass
            ? [NSString stringWithUTF8String:
                class_getName(superClass)]
            : @"—";

    cell.detailTextLabel.text =
        [NSString stringWithFormat:
            @"Superclass: %@  •  %lu method%@",
            superName,
            (unsigned long)methodCount,
            methodCount == 1 ? @"" : @"s"];

    cell.detailTextLabel.numberOfLines =
        2;

    BOOL selected =
        [self.selectedClasses
            containsObject:className];

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

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];

    [self inspectClass:className];
}

#pragma mark - Class Inspector

- (void)inspectClass:(NSString *)className
{
    AVX512ClassInfo *info =
        [self classInfoForName:className];

    if (!info) {
        return;
    }

    UIViewController *controller =
        [self inspectorControllerForClassInfo:info];

    UINavigationController *navigation =
        [[UINavigationController alloc]
            initWithRootViewController:controller];

    navigation.modalPresentationStyle =
        UIModalPresentationPageSheet;

    [self presentViewController:navigation
                       animated:YES
                     completion:nil];
}

- (void)closeInspector
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Runtime Metadata

- (AVX512ClassInfo *)classInfoForName:
    (NSString *)className
{
    Class cls =
        objc_getClass(className.UTF8String);

    if (!cls) {
        return nil;
    }

    AVX512ClassInfo *info =
        [AVX512ClassInfo new];

    info.className =
        className;

    Class superClass =
        class_getSuperclass(cls);

    if (superClass) {

        const char *superName =
            class_getName(superClass);

        if (superName) {

            info.superclassName =
                [NSString stringWithUTF8String:
                    superName];
        }
    }

    NSMutableArray<AVX512MethodInfo *> *methods =
        [NSMutableArray array];

    unsigned int methodCount = 0;

    Method *methodList =
        class_copyMethodList(cls,
                             &methodCount);

    for (unsigned int i = 0;
         i < methodCount;
         i++) {

        Method method =
            methodList[i];

        if (!method) {
            continue;
        }

        AVX512MethodInfo *methodInfo =
            [self methodInfoFromMethod:method
                                direct:YES
                       declaringClass:className];

        if (methodInfo) {
            [methods addObject:methodInfo];
        }
    }

    free(methodList);

    Class parent =
        class_getSuperclass(cls);

    while (parent) {

        unsigned int parentCount = 0;

        Method *parentMethods =
            class_copyMethodList(parent,
                                 &parentCount);

        NSString *parentName =
            class_getName(parent)
                ? [NSString stringWithUTF8String:
                    class_getName(parent)]
                : @"Unknown";

        for (unsigned int i = 0;
             i < parentCount;
             i++) {

            Method method =
                parentMethods[i];

            if (!method) {
                continue;
            }

            AVX512MethodInfo *methodInfo =
                [self methodInfoFromMethod:method
                                    direct:NO
                           declaringClass:parentName];

            if (methodInfo) {
                [methods addObject:methodInfo];
            }
        }

        free(parentMethods);

        parent =
            class_getSuperclass(parent);
    }

    [methods sortUsingComparator:
        ^NSComparisonResult(
            AVX512MethodInfo *a,
            AVX512MethodInfo *b) {

        return [a.selectorName
            caseInsensitiveCompare:b.selectorName];
    }];

    info.methods =
        [methods copy];

    return info;
}

- (AVX512MethodInfo *)methodInfoFromMethod:(Method)method
                                    direct:(BOOL)direct
                           declaringClass:
                               (NSString *)declaringClass
{
    if (!method) {
        return nil;
    }

    SEL selector =
        method_getName(method);

    if (!selector) {
        return nil;
    }

    const char *encoding =
        method_getTypeEncoding(method);

    AVX512MethodInfo *info =
        [AVX512MethodInfo new];

    info.selectorName =
        NSStringFromSelector(selector);

    info.typeEncoding =
        encoding
            ? [NSString stringWithUTF8String:encoding]
            : @"";

    info.returnType =
        encoding
            ? [self returnTypeFromEncoding:encoding]
            : @"?";

    info.declaredDirectly =
        direct;

    info.declaringClass =
        declaringClass ?: @"Unknown";

    return info;
}

- (NSString *)returnTypeFromEncoding:
    (const char *)encoding
{
    if (!encoding ||
        encoding[0] == '\0') {

        return @"?";
    }

    switch (encoding[0]) {

        case 'v':
            return @"void";

        case '@':
            return @"object";

        case 'B':
            return @"BOOL";

        case 'c':
            return @"char";

        case 'i':
            return @"int";

        case 's':
            return @"short";

        case 'l':
            return @"long";

        case 'q':
            return @"long long";

        case 'f':
            return @"float";

        case 'd':
            return @"double";

        case ':':
            return @"SEL";

        case '#':
            return @"Class";

        case '^':
            return @"pointer";

        case '{':
            return @"struct";

        case '[':
            return @"array";

        case 'b':
            return @"bitfield";

        default:
            return @"encoded";
    }
}

#pragma mark - Inspector UI

- (UIViewController *)inspectorControllerForClassInfo:
    (AVX512ClassInfo *)info
{
    UITableViewController *controller =
        [[UITableViewController alloc]
            initWithStyle:UITableViewStyleInsetGrouped];

    controller.title =
        info.className;

    controller.tableView.rowHeight =
        UITableViewAutomaticDimension;

    controller.tableView.estimatedRowHeight =
        70.0;

    controller.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithTitle:@"Back"
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(closeInspector)];

    UIButton *useButton =
        [UIButton buttonWithType:UIButtonTypeSystem];

    UIImage *signature =
        [UIImage systemImageNamed:@"signature"];

    if (signature) {
        [useButton setImage:signature
                   forState:UIControlStateNormal];
    }

    [useButton setTitle:@"  Use Class"
               forState:UIControlStateNormal];

    useButton.titleLabel.font =
        [UIFont systemFontOfSize:14.0
                           weight:UIFontWeightSemibold];

    [useButton addTarget:self
                  action:@selector(selectCurrentInspectorClass:)
        forControlEvents:UIControlEventTouchUpInside];

    objc_setAssociatedObject(
        useButton,
        "AVX512ClassName",
        info.className,
        OBJC_ASSOCIATION_COPY_NONATOMIC
    );

    controller.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithCustomView:useButton];

    NSMutableArray<NSString *> *lines =
        [NSMutableArray array];

    [lines addObject:
        [NSString stringWithFormat:
            @"CLASS\n%@\n\n"
             "The Objective-C runtime class currently being inspected.",
            info.className]];

    [lines addObject:
        [NSString stringWithFormat:
            @"SUPERCLASS\n%@\n\n"
             "The superclass is the class from which this class "
             "inherits runtime behavior.",
            info.superclassName ?: @"—"]];

    [lines addObject:
        [NSString stringWithFormat:
            @"METHODS\n%lu\n\n"
             "This includes methods declared directly by the class "
             "and methods discovered while walking its superclass chain.",
            (unsigned long)info.methods.count]];

    for (AVX512MethodInfo *method in info.methods) {

        NSString *origin =
            method.declaredDirectly
                ? @"Declared directly"
                : @"Inherited";

        [lines addObject:
            [NSString stringWithFormat:
                @"%@\n"
                 "Return: %@\n"
                 "Encoding: %@\n"
                 "%@\n"
                 "Declared by: %@",
                method.selectorName,
                method.returnType,
                method.typeEncoding,
                origin,
                method.declaringClass]];
    }

    __weak typeof(self) weakSelf =
        self;

    AVX512InspectorDataSource *source =
        [[AVX512InspectorDataSource alloc]
            initWithLines:lines
            className:info.className
            selectionHandler:^{

        __strong typeof(weakSelf) strongSelf =
            weakSelf;

        if (!strongSelf) {
            return;
        }

        [strongSelf.selectedClasses
            addObject:info.className];

        [strongSelf updateSignatureButton];

        [strongSelf.tableView reloadData];

        [controller dismissViewControllerAnimated:YES
                                       completion:nil];
    }];

    controller.tableView.dataSource =
        source;

    controller.tableView.delegate =
        source;

    objc_setAssociatedObject(
        controller,
        "AVX512InspectorSource",
        source,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );

    source.presentingController =
        controller;

    return controller;
}

- (void)selectCurrentInspectorClass:
    (UIButton *)sender
{
    NSString *className =
        objc_getAssociatedObject(
            sender,
            "AVX512ClassName"
        );

    if (!className) {
        return;
    }

    [self.selectedClasses
        addObject:className];

    [self updateSignatureButton];

    [self.tableView reloadData];

    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (NSIndexPath *)indexPathForClass:
    (NSString *)className
{
    NSUInteger index =
        [self.filteredClasses
            indexOfObject:className];

    if (index == NSNotFound) {
        return nil;
    }

    return
        [NSIndexPath indexPathForRow:index
                            inSection:0];
}

#pragma mark - Project Generation

- (void)generateProject
{
    if (self.selectedClasses.count == 0) {

        UIAlertController *alert =
            [UIAlertController
                alertControllerWithTitle:
                    @"Nothing Selected"
                                 message:
                    @"Select at least one runtime class before "
                     "creating the dylib."
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

    UIAlertController *type =
        [UIAlertController
            alertControllerWithTitle:@"Dylib Type"
                             message:
            @"Choose the generated project type."
                      preferredStyle:
            UIAlertControllerStyleActionSheet];

    [type addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Diagnostic"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:
            AVX512DylibTypeDiagnostic];
    }]];

    [type addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Test Harness"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:
            AVX512DylibTypeTestHarness];
    }]];

    [type addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                     style:UIAlertActionStyleCancel
                   handler:nil]];

    if (type.popoverPresentationController) {

        type.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:type
                       animated:YES
                     completion:nil];
}

- (void)chooseBuildStyle:
    (AVX512DylibType)dylibType
{
    UIAlertController *build =
        [UIAlertController
            alertControllerWithTitle:@"Build Project"
                             message:
            @"Choose how the generated project should build."
                      preferredStyle:
            UIAlertControllerStyleActionSheet];

    [build addAction:
        [UIAlertAction
            actionWithTitle:@"Shell Script"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self writeGeneratedProjectForType:dylibType
                                buildStyle:
            AVX512BuildStyleShell];
    }]];

    [build addAction:
        [UIAlertAction
            actionWithTitle:@"GitHub Actions"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self writeGeneratedProjectForType:dylibType
                                buildStyle:
            AVX512BuildStyleGitHub];
    }]];

    [build addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                     style:UIAlertActionStyleCancel
                   handler:nil]];

    if (build.popoverPresentationController) {

        build.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:build
                       animated:YES
                     completion:nil];
}

#pragma mark - Project Writer

- (void)writeGeneratedProjectForType:
            (AVX512DylibType)dylibType
                          buildStyle:
            (AVX512BuildStyle)buildStyle
{
    NSString *root =
        [NSTemporaryDirectory()
            stringByAppendingPathComponent:
                @"AVX512Generated"];

    NSFileManager *fm =
        [NSFileManager defaultManager];

    [fm removeItemAtPath:root
                   error:nil];

    NSError *error = nil;

    if (![fm createDirectoryAtPath:root
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error]) {

        [self showError:error];
        return;
    }

    NSString *header =
        [self generatedHeader];

    NSString *implementation =
        [self generatedImplementationForType:dylibType];

    NSString *readme =
        [self generatedREADMEForType:dylibType
                          buildStyle:buildStyle];

    NSString *headerPath =
        [root stringByAppendingPathComponent:
            @"AVX512Hook.h"];

    NSString *implementationPath =
        [root stringByAppendingPathComponent:
            @"AVX512Hook.m"];

    NSString *readmePath =
        [root stringByAppendingPathComponent:
            @"README.md"];

    if (![header writeToFile:headerPath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error]) {

        [self showError:error];
        return;
    }

    if (![implementation
            writeToFile:implementationPath
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error]) {

        [self showError:error];
        return;
    }

    if (![readme writeToFile:readmePath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error]) {

        [self showError:error];
        return;
    }

    if (buildStyle ==
        AVX512BuildStyleShell) {

        NSString *script =
            [self generatedBuildScriptForType:dylibType];

        NSString *scriptPath =
            [root stringByAppendingPathComponent:
                @"build.sh"];

        if (![script writeToFile:scriptPath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&error]) {

            [self showError:error];
            return;
        }

    } else {

        NSString *workflowDirectory =
            [root stringByAppendingPathComponent:
                @".github/workflows"];

        if (![fm createDirectoryAtPath:workflowDirectory
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error]) {

            [self showError:error];
            return;
        }

        NSString *workflow =
            [self generatedGitHubWorkflowForType:dylibType];

        NSString *workflowPath =
            [workflowDirectory
                stringByAppendingPathComponent:
                    @"build.yml"];

        if (![workflow writeToFile:workflowPath
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:&error]) {

            [self showError:error];
            return;
        }
    }

    [self shareGeneratedProject:root];
}

#pragma mark - Generated Header

- (NSString *)generatedHeader
{
    return
@"//\n"
"// AVX512Hook.h\n"
"// Generated by AVX512\n"
"// Signature.zh · MrZEfv\n"
"//\n"
"\n"
"#import <Foundation/Foundation.h>\n"
"#import <objc/runtime.h>\n"
"\n"
"NS_ASSUME_NONNULL_BEGIN\n"
"\n"
"@interface AVX512Hook : NSObject\n"
"\n"
"+ (void)install;\n"
"+ (void)uninstall;\n"
"+ (void)printDiagnostics;\n"
"\n"
"@end\n"
"\n"
"NS_ASSUME_NONNULL_END\n";
}

#pragma mark - Generated Implementation

- (NSString *)generatedImplementationForType:
    (AVX512DylibType)dylibType
{
    NSMutableString *s =
        [NSMutableString string];

    [s appendString:
@"//\n"
"// AVX512Hook.m\n"
"// Generated by AVX512\n"
"// Signature.zh · MrZEfv\n"
"//\n"
"// Runtime diagnostic/test harness.\n"
"//\n"
"\n"
"#import \"AVX512Hook.h\"\n"
"#import <objc/runtime.h>\n"
"\n"];

    NSArray *classes =
        [self.selectedClasses.allObjects
            sortedArrayUsingSelector:
                @selector(caseInsensitiveCompare:)];

    [s appendString:
@"static NSArray<NSString *> *AVX512SelectedClasses(void)\n"
"{\n"
"    return @[\n"];

    for (NSString *className in classes) {

        [s appendFormat:
            @"        @\"%@\",\n",
            [self escapedString:className]];
    }

    [s appendString:
@"    ];\n"
"}\n"
"\n"];

    [s appendString:
@"static void AVX512PrintClass(Class cls)\n"
"{\n"
"    if (!cls) {\n"
"        return;\n"
"    }\n"
"\n"
"    NSLog(@\"[AVX512] Class: %s\", class_getName(cls));\n"
"\n"
"    Class superClass = class_getSuperclass(cls);\n"
"\n"
"    if (superClass) {\n"
"        NSLog(@\"[AVX512] Superclass: %s\",\n"
"              class_getName(superClass));\n"
"    }\n"
"\n"
"    unsigned int count = 0;\n"
"\n"
"    Method *methods =\n"
"        class_copyMethodList(cls, &count);\n"
"\n"
"    NSLog(@\"[AVX512] Direct instance methods: %u\", count);\n"
"\n"
"    for (unsigned int i = 0; i < count; i++) {\n"
"\n"
"        Method method = methods[i];\n"
"\n"
"        if (!method) {\n"
"            continue;\n"
"        }\n"
"\n"
"        SEL selector = method_getName(method);\n"
"        const char *encoding =\n"
"            method_getTypeEncoding(method);\n"
"\n"
"        NSLog(@\"[AVX512]   - %@ | %s\",\n"
"              NSStringFromSelector(selector),\n"
"              encoding ?: \"?\");\n"
"    }\n"
"\n"
"    free(methods);\n"
"}\n"
"\n"];

    [s appendString:
@"@implementation AVX512Hook\n"
"\n"
"+ (void)install\n"
"{\n"
"    NSLog(@\"[AVX512] Signature.zh · MrZEfv\");\n"
"    NSLog(@\"[AVX512] install\");\n"
"\n"
"    for (NSString *name in AVX512SelectedClasses()) {\n"
"\n"
"        Class cls = objc_getClass(name.UTF8String);\n"
"\n"
"        if (!cls) {\n"
"            NSLog(@\"[AVX512] Class not loaded: %@\", name);\n"
"            continue;\n"
"        }\n"
"\n"
"        AVX512PrintClass(cls);\n"
"    }\n"
"}\n"
"\n"
"+ (void)uninstall\n"
"{\n"
"    NSLog(@\"[AVX512] uninstall\");\n"
"}\n"
"\n"
"+ (void)printDiagnostics\n"
"{\n"
"    NSLog(@\"[AVX512] ---- diagnostics ----\");\n"
"\n"
"    for (NSString *name in AVX512SelectedClasses()) {\n"
"        Class cls = objc_getClass(name.UTF8String);\n"
"        AVX512PrintClass(cls);\n"
"    }\n"
"}\n"
"\n"
"@end\n"
"\n"
"__attribute__((constructor))\n"
"static void AVX512Init(void)\n"
"{\n"
"    @autoreleasepool {\n"
"        [AVX512Hook install];\n"
"    }\n"
"}\n";

    if (dylibType ==
        AVX512DylibTypeTestHarness) {

        [s appendString:
@"\n"
"// Test-harness mode intentionally keeps behavioral changes explicit.\n"
"// Add controlled test behavior here for classes owned by the test project.\n"];
    }

    return s;
}

#pragma mark - Shell Build Script

- (NSString *)generatedBuildScriptForType:
    (AVX512DylibType)dylibType
{
    NSString *description =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    return [NSString stringWithFormat:
@"#!/bin/bash\n"
"set -euo pipefail\n"
"\n"
"PROJECT_DIR=\"$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)\"\n"
"SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
"CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n"
"OUT_DIR=\"$PROJECT_DIR/build\"\n"
"PACKAGE_DIR=\"$PROJECT_DIR/packages\"\n"
"\n"
"mkdir -p \"$OUT_DIR\" \"$PACKAGE_DIR\"\n"
"\n"
"echo \"[AVX512] %@\"\n"
"echo \"[AVX512] Signature.zh · MrZEfv\"\n"
"echo \"[AVX512] SDK: $SDK\"\n"
"\n"
"BUILT=()\n"
"\n"
"for ARCH in arm64 arm64e; do\n"
"    echo \"[AVX512] Building $ARCH\"\n"
"\n"
"    if \"$CLANG\" \\\n"
"        -arch \"$ARCH\" \\\n"
"        -isysroot \"$SDK\" \\\n"
"        -miphoneos-version-min=14.0 \\\n"
"        -dynamiclib \\\n"
"        -fobjc-arc \\\n"
"        -fmodules \\\n"
"        -I\"$PROJECT_DIR\" \\\n"
"        -framework Foundation \\\n"
"        -install_name \"@rpath/AVX512Hook.dylib\" \\\n"
"        -o \"$OUT_DIR/AVX512Hook-$ARCH.dylib\" \\\n"
"        \"$PROJECT_DIR/AVX512Hook.m\"; then\n"
"\n"
"        BUILT+=(\"$OUT_DIR/AVX512Hook-$ARCH.dylib\")\n"
"        echo \"[AVX512] $ARCH OK\"\n"
"    else\n"
"        echo \"[AVX512] $ARCH failed; continuing\"\n"
"    fi\n"
"done\n"
"\n"
"if [ \"${#BUILT[@]}\" -eq 0 ]; then\n"
"    echo \"[AVX512] ERROR: no architecture built\"\n"
"    exit 1\n"
"fi\n"
"\n"
"if [ \"${#BUILT[@]}\" -eq 1 ]; then\n"
"    cp \"${BUILT[0]}\" \"$PACKAGE_DIR/AVX512Hook.dylib\"\n"
"else\n"
"    lipo -create \"${BUILT[@]}\" \\\n"
"        -output \"$PACKAGE_DIR/AVX512Hook.dylib\"\n"
"fi\n"
"\n"
"if command -v ldid >/dev/null 2>&1; then\n"
"    echo \"[AVX512] Signing with ldid\"\n"
"    ldid -S \"$PACKAGE_DIR/AVX512Hook.dylib\"\n"
"else\n"
"    echo \"[AVX512] ldid not found; dylib remains unsigned\"\n"
"fi\n"
"\n"
"echo\n"
"echo \"[AVX512] Build complete\"\n"
"file \"$PACKAGE_DIR/AVX512Hook.dylib\"\n"
"lipo -info \"$PACKAGE_DIR/AVX512Hook.dylib\" || true\n",
        description];
}

#pragma mark - GitHub Workflow

- (NSString *)generatedGitHubWorkflowForType:
    (AVX512DylibType)dylibType
{
    NSString *description =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    return [NSString stringWithFormat:
@"name: Build AVX512 Dylib\n"
"\n"
"on:\n"
"  push:\n"
"    branches: [main]\n"
"  workflow_dispatch:\n"
"\n"
"jobs:\n"
"  build:\n"
"    name: %@\n"
"    runs-on: macos-15\n"
"\n"
"    steps:\n"
"      - name: Checkout\n"
"        uses: actions/checkout@v4\n"
"\n"
"      - name: Show Xcode\n"
"        run: |\n"
"          xcodebuild -version\n"
"          xcrun --sdk iphoneos --show-sdk-path\n"
"\n"
"      - name: Install ldid\n"
"        run: brew install ldid\n"
"\n"
"      - name: Build dylib\n"
"        shell: bash\n"
"        run: |\n"
"          set -euo pipefail\n"
"\n"
"          SDK=$(xcrun --sdk iphoneos --show-sdk-path)\n"
"          CLANG=$(xcrun --sdk iphoneos -f clang)\n"
"\n"
"          mkdir -p build_slices packages\n"
"\n"
"          BUILT=()\n"
"\n"
"          for ARCH in arm64 arm64e; do\n"
"            echo \"=== Building $ARCH ===\"\n"
"\n"
"            if \"$CLANG\" \\\n"
"              -arch \"$ARCH\" \\\n"
"              -isysroot \"$SDK\" \\\n"
"              -miphoneos-version-min=14.0 \\\n"
"              -dynamiclib \\\n"
"              -fobjc-arc \\\n"
"              -fmodules \\\n"
"              -I. \\\n"
"              -framework Foundation \\\n"
"              -install_name \"@rpath/AVX512Hook.dylib\" \\\n"
"              -o \"build_slices/AVX512Hook-$ARCH.dylib\" \\\n"
"              AVX512Hook.m; then\n"
"\n"
"              BUILT+=(\"build_slices/AVX512Hook-$ARCH.dylib\")\n"
"              echo \"$ARCH OK\"\n"
"            else\n"
"              echo \"::warning::$ARCH failed to link — continuing\"\n"
"            fi\n"
"          done\n"
"\n"
"          if [ \"${#BUILT[@]}\" -eq 0 ]; then\n"
"            echo \"::error::No architecture linked successfully\"\n"
"            exit 1\n"
"          fi\n"
"\n"
"          if [ \"${#BUILT[@]}\" -eq 1 ]; then\n"
"            cp \"${BUILT[0]}\" packages/AVX512Hook.dylib\n"
"          else\n"
"            lipo -create \"${BUILT[@]}\" \\\n"
"              -output packages/AVX512Hook.dylib\n"
"          fi\n"
"\n"
"          echo \"[AVX512] Signature.zh · MrZEfv\"\n"
"          ldid -S packages/AVX512Hook.dylib\n"
"\n"
"          file packages/AVX512Hook.dylib\n"
"          lipo -info packages/AVX512Hook.dylib || true\n"
"          ls -lh packages/AVX512Hook.dylib\n"
"\n"
"      - name: Upload dylib\n"
"        uses: actions/upload-artifact@v4\n"
"        with:\n"
"          name: AVX512Hook-dylib-${{ github.sha }}\n"
"          path: packages/AVX512Hook.dylib\n"
"          retention-days: 30\n"
"\n"
"      - name: Upload generated source\n"
"        uses: actions/upload-artifact@v4\n"
"        with:\n"
"          name: AVX512Hook-source-${{ github.sha }}\n"
"          path: |\n"
"            AVX512Hook.h\n"
"            AVX512Hook.m\n"
"            README.md\n"
"            .github/workflows/build.yml\n"
"          retention-days: 30\n",
        description];
}

#pragma mark - README

- (NSString *)generatedREADMEForType:
            (AVX512DylibType)dylibType
                          buildStyle:
            (AVX512BuildStyle)buildStyle
{
    NSMutableString *readme =
        [NSMutableString string];

    NSString *type =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    NSString *build =
        buildStyle == AVX512BuildStyleShell
            ? @"Shell Script"
            : @"GitHub Actions";

    [readme appendFormat:
@"# AVX512 Generated Dylib\n\n"
"**Signature.zh · MrZEfv**\n\n"
"Generated by the AVX512 Runtime Explorer.\n\n"
"## Project type\n\n"
"%@\n\n"
"## Build mode\n\n"
"%@\n\n"
"## Files\n\n"
"- `AVX512Hook.h` — public interface\n"
"- `AVX512Hook.m` — runtime diagnostic implementation\n"
"- `README.md` — project documentation\n",
        type,
        build];

    if (buildStyle ==
        AVX512BuildStyleShell) {

        [readme appendString:
@"- `build.sh` — iPhoneOS arm64/arm64e build script\n\n"
"## Build\n\n"
"```sh\n"
"chmod +x build.sh\n"
"./build.sh\n"
"```\n\n"
"The resulting dylib is written to "
"`packages/AVX512Hook.dylib`.\n\n"];

    } else {

        [readme appendString:
@"- `.github/workflows/build.yml` — GitHub Actions workflow\n\n"
"## Build\n\n"
"Push the project to GitHub and run the workflow manually, "
"or push to `main`.\n\n"
"The workflow builds arm64 and arm64e slices, combines them "
"with `lipo`, applies `ldid`, and uploads the resulting dylib.\n\n"];
    }

    [readme appendString:
@"## Runtime information\n\n"
"The generator inspected Objective-C runtime metadata when "
"this project was created.\n\n"
"The selected class names are embedded in the generated "
"implementation. At load time the diagnostic code resolves "
"those classes and prints their direct instance methods and "
"Objective-C type encodings.\n\n"
"## ABI note\n\n"
"Objective-C selectors may use arbitrary argument and return "
"types. This generator does not invent a universal function "
"signature for an arbitrary selector. The raw Objective-C type "
"encoding is exposed so a developer working on a controlled "
"test target can determine the appropriate signature before "
"implementing behavior.\n\n"
"## Scope\n\n"
"This generated project is intended for runtime diagnostics "
"and controlled test targets. It does not automatically alter "
"arbitrary method behavior.\n"];

    return readme;
}

#pragma mark - Sharing

- (void)shareGeneratedProject:
    (NSString *)root
{
    NSFileManager *fm =
        [NSFileManager defaultManager];

    NSMutableArray<NSURL *> *items =
        [NSMutableArray array];

    NSArray<NSString *> *files =
        [self filesRecursivelyAtPath:root];

    for (NSString *path in files) {

        if ([fm fileExistsAtPath:path]) {

            [items addObject:
                [NSURL fileURLWithPath:path]];
        }
    }

    if (items.count == 0) {

        [self showError:
            [NSError
                errorWithDomain:@"AVX512"
                           code:1
                       userInfo:@{
                NSLocalizedDescriptionKey:
                    @"No generated project files were found."
            }]];

        return;
    }

    UIActivityViewController *share =
        [[UIActivityViewController alloc]
            initWithActivityItems:items
            applicationActivities:nil];

    if (share.popoverPresentationController) {

        share.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:share
                       animated:YES
                     completion:nil];
}

- (NSArray<NSString *> *)filesRecursivelyAtPath:
    (NSString *)root
{
    NSFileManager *fm =
        [NSFileManager defaultManager];

    NSDirectoryEnumerator *enumerator =
        [fm enumeratorAtPath:root];

    NSMutableArray<NSString *> *result =
        [NSMutableArray array];

    for (NSString *relativePath in enumerator) {

        NSString *absolutePath =
            [root stringByAppendingPathComponent:
                relativePath];

        BOOL isDirectory = NO;

        [fm fileExistsAtPath:absolutePath
                 isDirectory:&isDirectory];

        if (!isDirectory) {
            [result addObject:absolutePath];
        }
    }

    return result;
}

#pragma mark - Helpers

- (NSString *)escapedString:
    (NSString *)string
{
    NSString *result =
        [string
            stringByReplacingOccurrencesOfString:@"\\"
                                      withString:@"\\\\"];

    result =
        [result
            stringByReplacingOccurrencesOfString:@"\""
                                      withString:@"\\\""];

    return result;
}

- (void)showError:
    (NSError *)error
{
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Generation Error"
                             message:error.localizedDescription
                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"OK"
                     style:UIAlertActionStyleDefault
                   handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

@end


#pragma mark - Inspector Data Source

/*
 AVX512InspectorDataSource is declared in:

 AVX512HookTemplateGenerator.h

 There is intentionally NO:

 AVX512InspectorDataSource.h
*/

@interface AVX512InspectorDataSource ()

@property (nonatomic, strong) NSArray<NSString *> *lines;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) void (^selectionHandler)(void);
@property (nonatomic, weak) UIViewController *presentingController;

@end


@implementation AVX512InspectorDataSource

- (instancetype)initWithLines:
                    (NSArray<NSString *> *)lines
                     className:
                    (NSString *)className
              selectionHandler:
                    (void (^)(void))handler
{
    self = [super init];

    if (self) {

        _lines =
            [lines copy];

        _className =
            [className copy];

        _selectionHandler =
            [handler copy];
    }

    return self;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.lines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:
            (NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [tableView
            dequeueReusableCellWithIdentifier:
                @"InspectorCell"];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:
                    UITableViewCellStyleSubtitle
                reuseIdentifier:
                    @"InspectorCell"];
    }

    NSString *text =
        self.lines[indexPath.row];

    cell.textLabel.text =
        text;

    cell.textLabel.numberOfLines =
        0;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:
            12.0
                                   weight:UIFontWeightRegular];

    return cell;
}

#pragma mark - Method Selection

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:
    (NSIndexPath *)indexPath
{
    /*
     The first three rows are class metadata.
     Method rows begin after those entries.
     */

    if (indexPath.row < 3) {

        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];

        return;
    }

    NSUInteger methodIndex =
        indexPath.row - 3;

    /*
     The generator's lines contain formatted method
     descriptions. For the detailed screen we recover
     the method metadata by asking the runtime again.
     */

    Class cls =
        objc_getClass(self.className.UTF8String);

    if (!cls) {
        return;
    }

    NSMutableArray<AVX512MethodInfo *> *methods =
        [NSMutableArray array];

    Class current =
        cls;

    while (current) {

        unsigned int count = 0;

        Method *methodList =
            class_copyMethodList(current, &count);

        NSString *declaringClass =
            class_getName(current)
                ? [NSString stringWithUTF8String:
                    class_getName(current)]
                : @"Unknown";

        for (unsigned int i = 0;
             i < count;
             i++) {

            Method method =
                methodList[i];

            if (!method) {
                continue;
            }

            SEL selector =
                method_getName(method);

            const char *encoding =
                method_getTypeEncoding(method);

            AVX512MethodInfo *info =
                [AVX512MethodInfo new];

            info.selectorName =
                NSStringFromSelector(selector);

            info.typeEncoding =
                encoding
                    ? [NSString stringWithUTF8String:
                        encoding]
                    : @"";

            info.returnType =
                encoding
                    ? [self returnTypeFromEncoding:
                        encoding]
                    : @"?";

            info.declaredDirectly =
                current == cls;

            info.declaringClass =
                declaringClass;

            [methods addObject:info];
        }

        free(methodList);

        current =
            class_getSuperclass(current);
    }

    [methods sortUsingComparator:
        ^NSComparisonResult(
            AVX512MethodInfo *a,
            AVX512MethodInfo *b) {

        return [a.selectorName
            caseInsensitiveCompare:b.selectorName];
    }];

    if (methodIndex >= methods.count) {
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
        return;
    }

    AVX512MethodInfo *method =
        methods[methodIndex];

    AVX512MethodDetailViewController *detail =
        [[AVX512MethodDetailViewController alloc]
            initWithMethod:method
                  className:self.className];

    UINavigationController *navigation =
        (UINavigationController *)
            self.presentingController.navigationController;

    if (navigation) {

        [navigation pushViewController:detail
                              animated:YES];

    } else {

        [self.presentingController
            presentViewController:detail
                           animated:YES
                         completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - Type Decoder

- (NSString *)returnTypeFromEncoding:
    (const char *)encoding
{
    if (!encoding ||
        encoding[0] == '\0') {

        return @"?";
    }

    switch (encoding[0]) {

        case 'v':
            return @"void";

        case '@':
            return @"object";

        case 'B':
            return @"BOOL";

        case 'c':
            return @"char";

        case 'i':
            return @"int";

        case 's':
            return @"short";

        case 'l':
            return @"long";

        case 'q':
            return @"long long";

        case 'f':
            return @"float";

        case 'd':
            return @"double";

        case ':':
            return @"SEL";

        case '#':
            return @"Class";

        case '^':
            return @"pointer";

        case '{':
            return @"struct";

        case '[':
            return @"array";

        case 'b':
            return @"bitfield";

        default:
            return @"encoded";
    }
}

- (void)selectClass
{
    if (self.selectionHandler) {
        self.selectionHandler();
    }
}

@end