//
//  AVX512HookTemplateGenerator.m
//  AVX512 by DELvEK.NET
//
//  Runtime recon -> project generator.
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
//  The generated dylib is a diagnostic/test harness.
//  It records the selected runtime metadata and provides an explicit
//  install/diagnostic entry point without guessing arbitrary method ABIs.
//

#import "AVX512HookTemplateGenerator.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - Models

@interface AVX512MethodInfo : NSObject

@property (nonatomic, copy) NSString *selectorName;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *returnType;
@property (nonatomic, assign) BOOL declaredDirectly;

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


typedef NS_ENUM(NSInteger, AVX512BuildStyle) {
    AVX512BuildStyleShell = 0,
    AVX512BuildStyleGitHub
};


typedef NS_ENUM(NSInteger, AVX512DylibType) {
    AVX512DylibTypeDiagnostic = 0,
    AVX512DylibTypeTestHarness = 1
};


#pragma mark - Generator

@interface AVX512HookTemplateGenerator () <UISearchResultsUpdating>

@property (nonatomic, strong) NSArray<NSString *> *allClasses;
@property (nonatomic, strong) NSArray<NSString *> *filteredClasses;

@property (nonatomic, strong) NSMutableSet<NSString *> *selectedClasses;

@property (nonatomic, strong) UISearchController *search;

@end


@implementation AVX512HookTemplateGenerator

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Dylib Generator";

    self.selectedClasses = [NSMutableSet set];

    [self loadRuntimeClasses];
    [self configureSearch];
    [self configureGenerateButton];
}

#pragma mark - Runtime Recon

- (void)loadRuntimeClasses
{
    unsigned int count = 0;

    Class *classes = objc_copyClassList(&count);

    NSMutableArray<NSString *> *names =
        [NSMutableArray arrayWithCapacity:count];

    for (unsigned int i = 0; i < count; i++) {

        Class cls = classes[i];

        if (!cls) {
            continue;
        }

        const char *name = class_getName(cls);

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

    [names sortUsingComparator:^NSComparisonResult(NSString *a,
                                                    NSString *b) {
        return [a caseInsensitiveCompare:b];
    }];

    self.allClasses = names;
    self.filteredClasses = names;
}

#pragma mark - Search

- (void)configureSearch
{
    self.search =
        [[UISearchController alloc]
            initWithSearchResultsController:nil];

    self.search.searchResultsUpdater = self;

    self.search.obscuresBackgroundDuringPresentation = NO;

    self.search.searchBar.placeholder =
        @"Search runtime classes";

    self.navigationItem.searchController = self.search;

    self.definesPresentationContext = YES;
}

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
    NSString *query =
        searchController.searchBar.text ?: @"";

    if (query.length == 0) {

        self.filteredClasses = self.allClasses;

    } else {

        NSPredicate *predicate =
            [NSPredicate predicateWithFormat:
                @"SELF CONTAINS[cd] %@", query];

        self.filteredClasses =
            [self.allClasses filteredArrayUsingPredicate:predicate];
    }

    [self.tableView reloadData];
}

#pragma mark - Generate Button

- (void)configureGenerateButton
{
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithTitle:@"Generate"
            style:UIBarButtonItemStyleDone
            target:self
            action:@selector(generateProject)];

    [self updateGenerateButton];
}

- (void)updateGenerateButton
{
    NSUInteger count = self.selectedClasses.count;

    self.navigationItem.rightBarButtonItem.enabled =
        count > 0;

    self.navigationItem.rightBarButtonItem.title =
        count > 0
            ? [NSString stringWithFormat:@"Generate (%lu)",
               (unsigned long)count]
            : @"Generate";
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
        [tableView dequeueReusableCellWithIdentifier:@"RuntimeClassCell"];

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
        cls ? class_getSuperclass(cls) : Nil;

    cell.textLabel.text = className;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:14
                                    weight:UIFontWeightRegular];

    if (superClass) {

        cell.detailTextLabel.text =
            [NSString stringWithFormat:
                @"Superclass: %s",
                class_getName(superClass)];

    } else {

        cell.detailTextLabel.text =
            @"Superclass: —";
    }

    cell.accessoryType =
        [self.selectedClasses containsObject:className]
            ? UITableViewCellAccessoryCheckmark
            : UITableViewCellAccessoryNone;

    return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *className =
        self.filteredClasses[indexPath.row];

    /*
     Open the class inspector instead of immediately selecting it.
     This gives the user the runtime answers first.
    */

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

    if (UIDevice.currentDevice.userInterfaceIdiom ==
        UIUserInterfaceIdiomPad) {

        navigation.modalPresentationStyle =
            UIModalPresentationPopover;

        navigation.popoverPresentationController.barButtonItem =
            self.navigationItem.rightBarButtonItem;
    }

    [self presentViewController:navigation
                       animated:YES
                     completion:nil];
}

#pragma mark - Runtime Metadata

- (AVX512ClassInfo *)classInfoForName:(NSString *)className
{
    Class cls =
        objc_getClass(className.UTF8String);

    if (!cls) {
        return nil;
    }

    AVX512ClassInfo *info =
        [AVX512ClassInfo new];

    info.className = className;

    Class superClass =
        class_getSuperclass(cls);

    if (superClass) {

        info.superclassName =
            [NSString stringWithUTF8String:
                class_getName(superClass)];
    }

    NSMutableArray<AVX512MethodInfo *> *methods =
        [NSMutableArray array];

    /*
     Direct methods.
     
     class_copyMethodList() only reports methods declared directly
     by this class.
    */

    unsigned int methodCount = 0;

    Method *methodList =
        class_copyMethodList(cls, &methodCount);

    for (unsigned int i = 0;
         i < methodCount;
         i++) {

        Method method = methodList[i];

        if (!method) {
            continue;
        }

        AVX512MethodInfo *methodInfo =
            [self methodInfoFromMethod:method
                                direct:YES];

        if (methodInfo) {
            [methods addObject:methodInfo];
        }
    }

    free(methodList);

    /*
     Walk superclasses separately so the UI can distinguish
     inherited methods from methods declared by the selected class.
    */

    Class parent = class_getSuperclass(cls);

    while (parent) {

        unsigned int parentCount = 0;

        Method *parentMethods =
            class_copyMethodList(parent, &parentCount);

        for (unsigned int i = 0;
             i < parentCount;
             i++) {

            Method method = parentMethods[i];

            if (!method) {
                continue;
            }

            AVX512MethodInfo *methodInfo =
                [self methodInfoFromMethod:method
                                    direct:NO];

            if (methodInfo) {
                [methods addObject:methodInfo];
            }
        }

        free(parentMethods);

        parent = class_getSuperclass(parent);
    }

    [methods sortUsingComparator:^NSComparisonResult(
        AVX512MethodInfo *a,
        AVX512MethodInfo *b) {

        return [a.selectorName
            caseInsensitiveCompare:b.selectorName];
    }];

    info.methods = methods;

    return info;
}


- (AVX512MethodInfo *)methodInfoFromMethod:(Method)method
                                    direct:(BOOL)direct
{
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

    info.declaredDirectly = direct;

    return info;
}


- (NSString *)returnTypeFromEncoding:(const char *)encoding
{
    if (!encoding || encoding[0] == '\0') {
        return @"?";
    }

    /*
     Objective-C type encodings can contain offsets, structs,
     arrays, blocks, pointers, etc. We intentionally expose the
     raw encoding instead of pretending to fully parse arbitrary
     signatures.
    */

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

    controller.title = info.className;

    NSMutableArray<NSString *> *lines =
        [NSMutableArray array];

    [lines addObject:
        [NSString stringWithFormat:
            @"CLASS\n%@", info.className]];

    [lines addObject:
        [NSString stringWithFormat:
            @"SUPERCLASS\n%@",
            info.superclassName ?: @"—"]];

    [lines addObject:
        [NSString stringWithFormat:
            @"METHODS\n%lu",
            (unsigned long)info.methods.count]];

    for (AVX512MethodInfo *method in info.methods) {

        NSString *origin =
            method.declaredDirectly
                ? @"declared"
                : @"inherited";

        [lines addObject:
            [NSString stringWithFormat:
                @"%@\n%@\nencoding: %@\n%@",
                method.selectorName,
                method.returnType,
                method.typeEncoding,
                origin]];
    }

    controller.tableView.tag = 512;

    /*
     Build the inspector using a lightweight custom data source.
    */

    AVX512InspectorDataSource *source =
        [[AVX512InspectorDataSource alloc]
            initWithLines:lines
            className:info.className
            selectionHandler:^{
                [self.selectedClasses addObject:info.className];
                [self updateGenerateButton];

                [controller dismissViewControllerAnimated:YES
                                               completion:nil];

                NSIndexPath *path =
                    [self indexPathForClass:info.className];

                if (path) {
                    [self.tableView reloadRowsAtIndexPaths:@[path]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
            }];

    controller.tableView.dataSource = source;

    /*
     Retain the data source through the controller.
    */

    objc_setAssociatedObject(controller,
                             "AVX512InspectorSource",
                             source,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIBarButtonItem *select =
        [[UIBarButtonItem alloc]
            initWithTitle:@"Use Class"
            style:UIBarButtonItemStyleDone
            target:source
            action:@selector(selectClass)];

    controller.navigationItem.rightBarButtonItem =
        select;

    return controller;
}

- (NSIndexPath *)indexPathForClass:(NSString *)className
{
    NSUInteger index =
        [self.filteredClasses indexOfObject:className];

    if (index == NSNotFound) {
        return nil;
    }

    return [NSIndexPath indexPathForRow:index
                              inSection:0];
}

#pragma mark - Project Generation

- (void)generateProject
{
    UIAlertController *type =
        [UIAlertController
            alertControllerWithTitle:@"Dylib Type"
                             message:@"Choose the generated project type."
                      preferredStyle:UIAlertControllerStyleActionSheet];

    [type addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Diagnostic"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:AVX512DylibTypeDiagnostic];
    }]];

    [type addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Test Harness"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:AVX512DylibTypeTestHarness];
    }]];

    [type addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                     style:UIAlertActionStyleCancel
                   handler:nil]];

    type.popoverPresentationController.barButtonItem =
        self.navigationItem.rightBarButtonItem;

    [self presentViewController:type
                       animated:YES
                     completion:nil];
}


- (void)chooseBuildStyle:(AVX512DylibType)dylibType
{
    UIAlertController *build =
        [UIAlertController
            alertControllerWithTitle:@"Build Project"
                             message:@"Choose how the generated dylib project should build."
                      preferredStyle:UIAlertControllerStyleActionSheet];

    [build addAction:
        [UIAlertAction
            actionWithTitle:@"Shell Script"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self writeGeneratedProjectForType:dylibType
                                buildStyle:AVX512BuildStyleShell];
    }]];

    [build addAction:
        [UIAlertAction
            actionWithTitle:@"GitHub Actions"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self writeGeneratedProjectForType:dylibType
                                buildStyle:AVX512BuildStyleGitHub];
    }]];

    [build addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                     style:UIAlertActionStyleCancel
                   handler:nil]];

    build.popoverPresentationController.barButtonItem =
        self.navigationItem.rightBarButtonItem;

    [self presentViewController:build
                       animated:YES
                     completion:nil];
}

#pragma mark - Project Writer

- (void)writeGeneratedProjectForType:(AVX512DylibType)dylibType
                          buildStyle:(AVX512BuildStyle)buildStyle
{
    NSString *root =
        [NSTemporaryDirectory()
            stringByAppendingPathComponent:@"AVX512Generated"];

    NSFileManager *fm =
        [NSFileManager defaultManager];

    [fm removeItemAtPath:root error:nil];

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
        [root stringByAppendingPathComponent:@"AVX512Hook.h"];

    NSString *implementationPath =
        [root stringByAppendingPathComponent:@"AVX512Hook.m"];

    NSString *readmePath =
        [root stringByAppendingPathComponent:@"README.md"];

    if (![header writeToFile:headerPath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error]) {

        [self showError:error];
        return;
    }

    if (![implementation writeToFile:implementationPath
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

    if (buildStyle == AVX512BuildStyleShell) {

        NSString *script =
            [self generatedBuildScriptForType:dylibType];

        NSString *scriptPath =
            [root stringByAppendingPathComponent:@"build.sh"];

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
                stringByAppendingPathComponent:@"build.yml"];

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
"//\n"
"// Runtime diagnostic/test harness.\n"
"//\n"
"\n"
"#import \"AVX512Hook.h\"\n"
"#import <objc/runtime.h>\n"
"\n"];

    [s appendString:
@"static NSMutableArray<NSString *> *AVX512SelectedClasses(void)\n"
"{\n"
"    return [NSMutableArray arrayWithObjects:\n"];

    NSArray *classes =
        [self.selectedClasses.allObjects
            sortedArrayUsingSelector:
                @selector(caseInsensitiveCompare:)];

    for (NSString *className in classes) {

        [s appendFormat:
            @"        @\"%@\",\n",
            [self escapedString:className]];
    }

    [s appendString:
@"        nil];\n"
"}\n"
"\n"];

    [s appendString:
@"static void AVX512PrintClass(Class cls)\n"
"{\n"
"    if (!cls) return;\n"
"\n"
"    NSLog(@\"[AVX512] Class: %s\", class_getName(cls));\n"
"\n"
"    Class superClass = class_getSuperclass(cls);\n"
"    if (superClass) {\n"
"        NSLog(@\"[AVX512] Superclass: %s\", class_getName(superClass));\n"
"    }\n"
"\n"
"    unsigned int count = 0;\n"
"    Method *methods = class_copyMethodList(cls, &count);\n"
"\n"
"    NSLog(@\"[AVX512] Direct instance methods: %u\", count);\n"
"\n"
"    for (unsigned int i = 0; i < count; i++) {\n"
"        SEL selector = method_getName(methods[i]);\n"
"        const char *encoding = method_getTypeEncoding(methods[i]);\n"
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

    if (dylibType == AVX512DylibTypeTestHarness) {

        [s appendString:
@"\n"
"// Test-harness mode intentionally keeps behavioral changes explicit.\n"
"// Add controlled test behavior here for classes owned by the test project.\n"];
    }

    return s;
}

#pragma mark - Build Script

- (NSString *)generatedBuildScriptForType:
    (AVX512DylibType)dylibType
{
    NSString *description =
        dylibType == AVX512DylibTypeDiagnostic
            ? @"Runtime Diagnostic"
            : @"Runtime Test Harness";

    return [NSString stringWithFormat:
@"#!/bin/sh\n"
"set -eu\n"
"\n"
"PROJECT_DIR=\"$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)\"\n"
"SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
"CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n"
"OUT=\"$PROJECT_DIR/AVX512Hook.dylib\"\n"
"\n"
"echo \"[AVX512] %@\"\n"
"echo \"[AVX512] SDK: $SDK\"\n"
"echo \"[AVX512] Compiler: $CLANG\"\n"
"\n"
"\"$CLANG\" \\\n"
"    -target arm64-apple-ios \\\n"
"    -isysroot \"$SDK\" \\\n"
"    -fobjc-arc \\\n"
"    -fmodules \\\n"
"    -dynamiclib \\\n"
"    -I\"$PROJECT_DIR\" \\\n"
"    -install_name \"@rpath/AVX512Hook.dylib\" \\\n"
"    -framework Foundation \\\n"
"    -o \"$OUT\" \\\n"
"    \"$PROJECT_DIR/AVX512Hook.m\"\n"
"\n"
"echo\n"
"echo \"[AVX512] Build complete\"\n"
"echo \"[AVX512] $OUT\"\n"
"\n"
"if command -v file >/dev/null 2>&1; then\n"
"    file \"$OUT\"\n"
"fi\n"
"\n"
"if command -v lipo >/dev/null 2>&1; then\n"
"    lipo -info \"$OUT\" || true\n"
"fi\n"
"\n"
"if command -v ldid >/dev/null 2>&1; then\n"
"    echo \"[AVX512] ldid detected; signing is available in this environment.\"\n"
"else\n"
"    echo \"[AVX512] ldid not found; leaving dylib unsigned.\"\n"
"fi\n",
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
"  workflow_dispatch:\n"
"  push:\n"
"    paths:\n"
"      - 'AVX512Hook.h'\n"
"      - 'AVX512Hook.m'\n"
"      - '.github/workflows/build.yml'\n"
"\n"
"jobs:\n"
"  build:\n"
"    name: %@\n"
"    runs-on: macos-latest\n"
"\n"
"    steps:\n"
"      - name: Checkout\n"
"        uses: actions/checkout@v4\n"
"\n"
"      - name: Show Xcode\n"
"        run: |\n"
"          xcodebuild -version\n"
"          xcrun --sdk iphoneos --show-sdk-path\n"
"          xcrun --sdk iphoneos -f clang\n"
"\n"
"      - name: Build dylib\n"
"        run: |\n"
"          chmod +x build.sh\n"
"          ./build.sh\n"
"\n"
"      - name: Inspect dylib\n"
"        run: |\n"
"          file AVX512Hook.dylib\n"
"          lipo -info AVX512Hook.dylib || true\n"
"\n"
"      - name: Upload dylib\n"
"        uses: actions/upload-artifact@v4\n"
"        with:\n"
"          name: AVX512Hook-dylib\n"
"          path: AVX512Hook.dylib\n"
"\n"
"      - name: Upload source project\n"
"        uses: actions/upload-artifact@v4\n"
"        with:\n"
"          name: AVX512Hook-source\n"
"          path: |\n"
"            AVX512Hook.h\n"
"            AVX512Hook.m\n"
"            README.md\n"
"            build.sh\n",
        description];
}

#pragma mark - README

- (NSString *)generatedREADMEForType:(AVX512DylibType)dylibType
                          buildStyle:(AVX512BuildStyle)buildStyle
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
"Generated by AVX512.\n\n"
"## Project type\n\n"
"%@\n\n"
"## Build mode\n\n"
"%@\n\n"
"## Files\n\n"
"- `AVX512Hook.h` — public interface\n"
"- `AVX512Hook.m` — generated implementation\n"
"- `README.md` — this documentation\n",
        type,
        build];

    if (buildStyle == AVX512BuildStyleShell) {

        [readme appendString:
@"- `build.sh` — iPhoneOS arm64 build script\n\n"
"## Build\n\n"
"```sh\n"
"chmod +x build.sh\n"
"./build.sh\n"
"```\n\n"];

    } else {

        [readme appendString:
@"- `.github/workflows/build.yml` — GitHub Actions workflow\n\n"
"## Build\n\n"
"Push the project to GitHub and run the workflow manually, or push a change to the generated source files.\n\n"];
    }

    [readme appendString:
@"## Runtime information\n\n"
"The generator inspected the Objective-C runtime when the project was created.\n"
"The selected class names are embedded in the generated implementation.\n"
"The generated diagnostic code resolves those classes at load time and prints their direct instance methods and Objective-C type encodings.\n\n"
"## Important ABI note\n\n"
"Objective-C selectors can have arbitrary argument and return types. The generator therefore does not invent a universal function signature for an arbitrary selector. The raw Objective-C type encoding is exposed so a developer working on a controlled test target can determine the correct signature before implementing behavior.\n\n"
"## Signing\n\n"
"The build does not assume `ldid` is installed. If `ldid` exists in the build environment, it is detected; otherwise the dylib remains unsigned.\n"];

    return readme;
}

#pragma mark - Sharing

- (void)shareGeneratedProject:(NSString *)root
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
            [NSError errorWithDomain:@"AVX512"
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

    share.popoverPresentationController.barButtonItem =
        self.navigationItem.rightBarButtonItem;

    [self presentViewController:share
                       animated:YES
                     completion:nil];
}


- (NSArray<NSString *> *)filesRecursivelyAtPath:(NSString *)root
{
    NSFileManager *fm =
        [NSFileManager defaultManager];

    NSDirectoryEnumerator *enumerator =
        [fm enumeratorAtPath:root];

    NSMutableArray<NSString *> *result =
        [NSMutableArray array];

    for (NSString *relativePath in enumerator) {

        NSString *absolutePath =
            [root stringByAppendingPathComponent:relativePath];

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

- (NSString *)escapedString:(NSString *)string
{
    NSString *result =
        [string stringByReplacingOccurrencesOfString:@"\\"
                                           withString:@"\\\\"];

    result =
        [result stringByReplacingOccurrencesOfString:@"\""
                                           withString:@"\\\""];

    return result;
}


- (void)showError:(NSError *)error
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

@interface AVX512InspectorDataSource : NSObject
    <UITableViewDataSource>

@property (nonatomic, strong) NSArray<NSString *> *lines;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) void (^selectionHandler)(void);

@end


@implementation AVX512InspectorDataSource

- (instancetype)initWithLines:(NSArray<NSString *> *)lines
                     className:(NSString *)className
             selectionHandler:(void (^)(void))handler
{
    self = [super init];

    if (self) {

        _lines = [lines copy];
        _className = [className copy];
        _selectionHandler = [handler copy];
    }

    return self;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.lines.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"InspectorCell"];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:@"InspectorCell"];
    }

    NSString *text =
        self.lines[indexPath.row];

    cell.textLabel.text = text;

    cell.textLabel.numberOfLines = 0;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:12
                                    weight:UIFontWeightRegular];

    return cell;
}


- (void)selectClass
{
    if (self.selectionHandler) {
        self.selectionHandler();
    }
}

@end