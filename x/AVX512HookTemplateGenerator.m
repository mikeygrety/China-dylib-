//
// AVX512HookTemplateGenerator.m
// AVX512 by DELvEK.NET
//
// Runtime recon -> project generator.
//

#import "AVX512HookTemplateGenerator.h"
#import <objc/runtime.h>

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


#pragma mark - Inspector Controller

@interface AVX512ClassInspectorController : UITableViewController

@property (nonatomic, strong) AVX512ClassInfo *info;
@property (nonatomic, copy) void (^selectionHandler)(void);

@end


@implementation AVX512ClassInspectorController

- (instancetype)initWithClassInfo:(AVX512ClassInfo *)info
                  selectionHandler:(void (^)(void))handler
{
    self = [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _info = info;
        _selectionHandler = [handler copy];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.info.className;

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                 target:self
                                 action:@selector(closeInspector)];

    UIImage *signatureImage =
        [UIImage systemImageNamed:@"signature"];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithImage:signatureImage
                    style:UIBarButtonItemStyleDone
                   target:self
                   action:@selector(useClass)];

    self.navigationItem.rightBarButtonItem.accessibilityLabel =
        @"signature.zh — Use Class";

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 70.0;
}

- (void)closeInspector
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)useClass
{
    if (self.selectionHandler) {
        self.selectionHandler();
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
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
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;

        case 1:
            return 1;

        case 2:
            return self.info.methods.count;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:nil];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0) {

        if (indexPath.row == 0) {

            cell.textLabel.text = self.info.className;
            cell.textLabel.font =
                [UIFont monospacedSystemFontOfSize:17
                                            weight:UIFontWeightSemibold];

            cell.detailTextLabel.text =
                @"Objective-C runtime class";

        } else if (indexPath.row == 1) {

            cell.textLabel.text = @"Superclass";
            cell.detailTextLabel.text =
                self.info.superclassName ?: @"None";

        } else {

            cell.textLabel.text = @"Methods";
            cell.detailTextLabel.text =
                [NSString stringWithFormat:@"%lu runtime methods",
                 (unsigned long)self.info.methods.count];
        }

        return cell;
    }

    if (indexPath.section == 1) {

        cell.textLabel.text =
            [self explanationForClass:self.info];

        cell.textLabel.numberOfLines = 0;

        cell.textLabel.font =
            [UIFont systemFontOfSize:15];

        return cell;
    }

    AVX512MethodInfo *method =
        self.info.methods[indexPath.row];

    cell.textLabel.text =
        method.selectorName;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:14
                                    weight:UIFontWeightMedium];

    NSString *origin =
        method.declaredDirectly
            ? @"Declared by this class"
            : @"Inherited";

    cell.detailTextLabel.text =
        [NSString stringWithFormat:
            @"%@  •  Return: %@  •  Encoding: %@",
            origin,
            method.returnType,
            method.typeEncoding];

    cell.detailTextLabel.numberOfLines = 0;

    return cell;
}

- (NSString *)explanationForClass:(AVX512ClassInfo *)info
{
    NSMutableString *text =
        [NSMutableString string];

    [text appendFormat:
        @"%@ is a class currently visible to the Objective-C runtime.\n\n",
        info.className];

    if (info.superclassName.length > 0) {

        [text appendFormat:
            @"It inherits from %@. Methods inherited from that superclass "
             "are shown below alongside methods declared directly by this "
             "class.\n\n",
            info.superclassName];
    }

    [text appendFormat:
        @"AVX512 found %lu method entries while inspecting this class. "
         "The method encoding tells you the Objective-C ABI information "
         "available at runtime.",
        (unsigned long)info.methods.count];

    return text;
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

    self.title = @"Dylib Generator";

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                 target:self
                                 action:@selector(closeGenerator)];

    self.selectedClasses = [NSMutableSet set];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 58.0;

    [self loadRuntimeClasses];
    [self configureSearch];
    [self configureGenerateButton];
}

- (void)closeGenerator
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Runtime

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

    [names sortUsingComparator:^NSComparisonResult(
        NSString *a,
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

    self.navigationItem.searchController =
        self.search;

    self.definesPresentationContext = YES;
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

#pragma mark - Generate

- (void)configureGenerateButton
{
    UIImage *signatureImage =
        [UIImage systemImageNamed:@"signature"];

    UIBarButtonItem *button =
        [[UIBarButtonItem alloc]
            initWithImage:signatureImage
                    style:UIBarButtonItemStyleDone
                   target:self
                   action:@selector(generateProject)];

    button.accessibilityLabel =
        @"signature.zh — Make Dylib";

    self.navigationItem.rightBarButtonItem = button;

    [self updateGenerateButton];
}

- (void)updateGenerateButton
{
    NSUInteger count =
        self.selectedClasses.count;

    self.navigationItem.rightBarButtonItem.enabled =
        count > 0;

    self.navigationItem.rightBarButtonItem.accessibilityValue =
        [NSString stringWithFormat:@"%lu selected",
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
        cls ? class_getSuperclass(cls) : Nil;

    cell.textLabel.text =
        className;

    cell.textLabel.font =
        [UIFont monospacedSystemFontOfSize:14
                                    weight:UIFontWeightRegular];

    if (superClass) {

        cell.detailTextLabel.text =
            [NSString stringWithFormat:
                @"Superclass: %s  •  Tap to inspect",
                class_getName(superClass)];

    } else {

        cell.detailTextLabel.text =
            @"No superclass  •  Tap to inspect";
    }

    cell.detailTextLabel.numberOfLines = 2;

    cell.accessoryType =
        [self.selectedClasses containsObject:className]
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

#pragma mark - Inspector

- (void)inspectClass:(NSString *)className
{
    AVX512ClassInfo *info =
        [self classInfoForName:className];

    if (!info) {
        return;
    }

    __weak typeof(self) weakSelf = self;

    AVX512ClassInspectorController *controller =
        [[AVX512ClassInspectorController alloc]
            initWithClassInfo:info
            selectionHandler:^{

        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (!strongSelf) {
            return;
        }

        [strongSelf.selectedClasses
            addObject:info.className];

        [strongSelf updateGenerateButton];

        [controller dismissViewControllerAnimated:YES
                                       completion:nil];

        NSIndexPath *path =
            [strongSelf indexPathForClass:info.className];

        if (path) {

            [strongSelf.tableView
                reloadRowsAtIndexPaths:@[path]
                withRowAnimation:
                    UITableViewRowAnimationNone];
        }
    }];

    UINavigationController *navigation =
        [[UINavigationController alloc]
            initWithRootViewController:controller];

    navigation.modalPresentationStyle =
        UIModalPresentationPageSheet;

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

    info.className =
        className;

    Class superClass =
        class_getSuperclass(cls);

    if (superClass) {

        const char *name =
            class_getName(superClass);

        if (name) {
            info.superclassName =
                [NSString stringWithUTF8String:name];
        }
    }

    NSMutableArray<AVX512MethodInfo *> *methods =
        [NSMutableArray array];

    unsigned int methodCount = 0;

    Method *methodList =
        class_copyMethodList(cls, &methodCount);

    for (unsigned int i = 0;
         i < methodCount;
         i++) {

        AVX512MethodInfo *methodInfo =
            [self methodInfoFromMethod:
                methodList[i]
                                direct:YES];

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

        for (unsigned int i = 0;
             i < parentCount;
             i++) {

            AVX512MethodInfo *methodInfo =
                [self methodInfoFromMethod:
                    parentMethods[i]
                                    direct:NO];

            if (methodInfo) {
                [methods addObject:methodInfo];
            }
        }

        free(parentMethods);

        parent =
            class_getSuperclass(parent);
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
            : @"?";

    info.returnType =
        [self returnTypeFromEncoding:encoding];

    info.declaredDirectly =
        direct;

    return info;
}

- (NSString *)returnTypeFromEncoding:(const char *)encoding
{
    if (!encoding || !encoding[0]) {
        return @"?";
    }

    switch (encoding[0]) {

        case 'v': return @"void";
        case '@': return @"object";
        case 'B': return @"BOOL";
        case 'c': return @"char";
        case 'i': return @"int";
        case 's': return @"short";
        case 'l': return @"long";
        case 'q': return @"long long";
        case 'f': return @"float";
        case 'd': return @"double";
        case ':': return @"SEL";
        case '#': return @"Class";
        case '^': return @"pointer";
        case '{': return @"struct";
        case '[': return @"array";
        case 'b': return @"bitfield";

        default:
            return @"encoded";
    }
}

#pragma mark - Selection

- (NSIndexPath *)indexPathForClass:(NSString *)className
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
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"signature.zh"
                             message:
        @"MrZEfv • Make Dylib\n\n"
         "Choose the type of generated runtime project."
                      preferredStyle:
        UIAlertControllerStyleActionSheet];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Diagnostic"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:0];
    }]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Runtime Test Harness"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self chooseBuildStyle:1];
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

- (void)chooseBuildStyle:(NSInteger)dylibType
{
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Build"
                             message:
        @"How should signature.zh create the project?"
                      preferredStyle:
        UIAlertControllerStyleActionSheet];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Shell Script"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self writeProject:dylibType
                githubStyle:NO];
    }]];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"GitHub Actions"
                     style:UIAlertActionStyleDefault
                   handler:^(__unused UIAlertAction *action) {

        [self writeProject:dylibType
                githubStyle:YES];
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

#pragma mark - Project Writer

- (void)writeProject:(NSInteger)dylibType
         githubStyle:(BOOL)githubStyle
{
    /*
     Keep your existing project-generation methods here:
     
       generatedHeader
       generatedImplementationForType:
       generatedREADMEForType:buildStyle:
       generatedBuildScriptForType:
       generatedGitHubWorkflowForType:
       shareGeneratedProject:
     
     The important UI change is that generation is now reached
     through the signature.zh button and the selected classes.
    */

    /*
     If your existing implementation already contains
     writeGeneratedProjectForType:buildStyle:, simply bridge to it.
    */

    if ([self respondsToSelector:
         @selector(writeGeneratedProjectForType:buildStyle:)]) {

        SEL selector =
            @selector(writeGeneratedProjectForType:buildStyle:);

        NSMethodSignature *signature =
            [self methodSignatureForSelector:selector];

        if (signature) {

            NSInvocation *invocation =
                [NSInvocation invocationWithMethodSignature:signature];

            invocation.target = self;
            invocation.selector = selector;

            NSInteger type = dylibType;
            NSInteger build = githubStyle ? 1 : 0;

            [invocation setArgument:&type atIndex:2];
            [invocation setArgument:&build atIndex:3];

            [invocation invoke];
        }
    }
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
        [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:nil];

    cell.textLabel.text =
        self.lines[indexPath.row];

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