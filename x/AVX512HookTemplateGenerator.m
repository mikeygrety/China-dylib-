//
//  AVX512HookTemplateGenerator.m
//  AVX512HookTemplateGenerator
//
//  AVX512 by DELvEK.NET
//
//  Runtime inspector + implementation learning UI +
//  controlled test-patch project generator.
//

#import "AVX512HookTemplateGenerator.h"

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

#pragma mark - Private Helpers

static NSString *AVX512HumanType(const char *encoding)
{
    if (!encoding || !encoding[0]) {
        return @"unknown";
    }

    switch (encoding[0]) {
        case 'v': return @"void";
        case 'c': return @"char";
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
        case '@': return @"object";
        case '#': return @"Class";
        case ':': return @"SEL";
        case '^': return @"pointer";
        case '*': return @"char *";
        case '?': return @"unknown";
        default:
            return [NSString stringWithFormat:@"type '%c'", encoding[0]];
    }
}

static NSUInteger AVX512ExplicitArgumentCount(Method method)
{
    if (!method) {
        return 0;
    }

    NSUInteger total = method_getNumberOfArguments(method);

    if (total < 2) {
        return 0;
    }

    return total - 2;
}

static NSString *AVX512IMPString(IMP imp)
{
    if (!imp) {
        return @"Unavailable";
    }

    return [NSString stringWithFormat:@"0x%llX",
            (unsigned long long)(uintptr_t)imp];
}

static NSString *AVX512Hex32(uint32_t value)
{
    return [NSString stringWithFormat:@"%08X", value];
}

static NSString *AVX512ImageForAddress(uintptr_t address,
                                       uintptr_t *slideOut,
                                       uintptr_t *offsetOut)
{
    if (address == 0) {
        return nil;
    }

    uint32_t count = _dyld_image_count();

    for (uint32_t i = 0; i < count; i++) {

        const struct mach_header *header =
            _dyld_get_image_header(i);

        if (!header) {
            continue;
        }

        intptr_t slide =
            _dyld_get_image_vmaddr_slide(i);

        uintptr_t base =
            (uintptr_t)header + (uintptr_t)slide;

        uintptr_t minAddress = UINTPTR_MAX;
        uintptr_t maxAddress = 0;

        const uint8_t *cursor =
            (const uint8_t *)header;

        if (header->magic == MH_MAGIC_64 ||
            header->magic == MH_CIGAM_64) {

            const struct mach_header_64 *mh =
                (const struct mach_header_64 *)cursor;

            const struct load_command *cmd =
                (const struct load_command *)
                (cursor + sizeof(struct mach_header_64));

            for (uint32_t j = 0; j < mh->ncmds; j++) {

                if (cmd->cmdsize < sizeof(struct load_command)) {
                    break;
                }

                if (cmd->cmd == LC_SEGMENT_64) {

                    const struct segment_command_64 *seg =
                        (const struct segment_command_64 *)cmd;

                    uintptr_t segStart =
                        (uintptr_t)seg->vmaddr +
                        (uintptr_t)slide;

                    uintptr_t segEnd =
                        segStart +
                        (uintptr_t)seg->vmsize;

                    if (segStart < minAddress) {
                        minAddress = segStart;
                    }

                    if (segEnd > maxAddress) {
                        maxAddress = segEnd;
                    }
                }

                cmd =
                    (const struct load_command *)
                    ((const uint8_t *)cmd + cmd->cmdsize);
            }
        }

        /*
         * If no valid segment range was discovered, don't attempt
         * to classify the address using an invalid range.
         */
        if (minAddress == UINTPTR_MAX ||
            maxAddress <= minAddress) {
            continue;
        }

        if (address >= minAddress &&
            address < maxAddress) {

            if (slideOut) {
                *slideOut = (uintptr_t)slide;
            }

            if (offsetOut) {
                *offsetOut = address - base;
            }

            const char *name =
                _dyld_get_image_name(i);

            if (name) {
                return [[NSString stringWithUTF8String:name]
                        lastPathComponent];
            }

            return @"Unknown Image";
        }
    }

    return nil;
}

static NSString *AVX512InstructionExplanation(NSString *mnemonic,
                                              NSString *operands)
{
    NSString *m =
        mnemonic.lowercaseString ?: @"";

    if ([m isEqualToString:@"nop"]) {
        return
        @"NOP performs no architectural operation. "
        @"It is useful as a controlled test replacement when "
        @"observing instruction-flow changes.";
    }

    if ([m hasPrefix:@"mov"]) {
        return [NSString stringWithFormat:
                @"MOV copies a value between registers or operands. "
                @"Here the operands are %@.",
                operands ?: @""];
    }

    if ([m hasPrefix:@"ldr"] ||
        [m hasPrefix:@"ldp"]) {
        return
        @"This is a load instruction. It reads data from memory "
        @"into one or more registers.";
    }

    if ([m hasPrefix:@"str"] ||
        [m hasPrefix:@"stp"]) {
        return
        @"This is a store instruction. It writes register values "
        @"to memory, commonly as part of stack-frame setup or "
        @"data storage.";
    }

    if ([m hasPrefix:@"cmp"] ||
        [m hasPrefix:@"tst"]) {
        return
        @"This instruction compares or tests values and updates "
        @"condition flags used by later conditional branches.";
    }

    if ([m hasPrefix:@"b."] ||
        [m isEqualToString:@"b"] ||
        [m isEqualToString:@"br"] ||
        [m isEqualToString:@"blr"]) {
        return
        @"This instruction changes control flow. Conditional "
        @"branches depend on processor flags, while register "
        @"branches use an address stored in a register.";
    }

    if ([m isEqualToString:@"bl"]) {
        return
        @"BL performs a function call and records the return "
        @"address in the link register.";
    }

    if ([m isEqualToString:@"ret"]) {
        return
        @"RET returns from the current function using the "
        @"address in the link register.";
    }

    if ([m hasPrefix:@"add"] ||
        [m hasPrefix:@"sub"]) {
        return
        @"This arithmetic instruction adds or subtracts integer "
        @"values, commonly for address calculation, counters, "
        @"or stack management.";
    }

    if ([m hasPrefix:@"and"] ||
        [m hasPrefix:@"orr"] ||
        [m hasPrefix:@"eor"]) {
        return
        @"This is a bitwise operation performed on register values.";
    }

    return
    @"AVX512 identified this as an ARM64 instruction. "
    @"The mnemonic and operands describe the operation performed "
    @"by the CPU.";
}

#pragma mark - Method Model

@implementation AVX512MethodInfo
@end

#pragma mark - Class Model

@implementation AVX512ClassInfo
@end

#pragma mark - Instruction Model

@implementation AVX512InstructionInfo
@end

#pragma mark - Patch Model

@implementation AVX512PatchInfo
@end

#pragma mark - Inspector Controller

@interface AVX512ClassInspectorController : UITableViewController

@property (nonatomic, strong) AVX512ClassInfo *classInfo;
@property (nonatomic, strong) NSArray<AVX512MethodInfo *> *methods;

@end

@implementation AVX512ClassInspectorController

- (instancetype)initWithClassInfo:(AVX512ClassInfo *)classInfo
{
    self =
        [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {
        _classInfo = classInfo;
        _methods = classInfo.methods ?: @[];
        self.title = classInfo.className;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemClose
         target:self
         action:@selector(close)];

    self.tableView.rowHeight =
        UITableViewAutomaticDimension;

    self.tableView.estimatedRowHeight = 72.0;

    self.tableView.accessibilityIdentifier =
        @"AVX512ClassInspector";
}

- (void)close
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:
    (UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    switch (section) {

        case 0:
            return 4;

        case 1:
            return self.methods.count;

        case 2:
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
            return [NSString stringWithFormat:
                    @"METHODS · %lu",
                    (unsigned long)self.methods.count];

        case 2:
            return @"LEARNING";

        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:
    (UITableView *)tableView
    cellForRowAtIndexPath:
    (NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [[UITableViewCell alloc]
         initWithStyle:UITableViewCellStyleSubtitle
         reuseIdentifier:nil];

    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;

    if (indexPath.section == 0) {

        switch (indexPath.row) {

            case 0:
                cell.textLabel.text = @"Class";
                cell.detailTextLabel.text =
                    self.classInfo.className;
                break;

            case 1:
                cell.textLabel.text = @"Superclass";
                cell.detailTextLabel.text =
                    self.classInfo.superclassName ?: @"None";
                break;

            case 2:
                cell.textLabel.text = @"Methods";
                cell.detailTextLabel.text =
                    [NSString stringWithFormat:
                     @"%lu discovered",
                     (unsigned long)self.methods.count];
                break;

            case 3:
                cell.textLabel.text = @"Runtime";
                cell.detailTextLabel.text =
                    @"Objective-C runtime metadata";
                break;
        }

        return cell;
    }

    if (indexPath.section == 1) {

        AVX512MethodInfo *info =
            self.methods[indexPath.row];

        cell.accessoryType =
            UITableViewCellAccessoryDisclosureIndicator;

        cell.textLabel.text =
            [NSString stringWithFormat:
             @"-%@",
             info.selectorName];

        NSString *origin =
            info.inherited
            ? @"Inherited"
            : @"Declared here";

        cell.detailTextLabel.text =
            [NSString stringWithFormat:
             @"%@ · %@ · %lu argument%@",
             origin,
             info.returnType,
             (unsigned long)info.argumentCount,
             info.argumentCount == 1 ? @"" : @"s"];

        return cell;
    }

    cell.textLabel.text =
        @"How to read a method";

    cell.detailTextLabel.text =
        @"Tap a method to inspect its runtime IMP, image, "
        @"signature, and implementation-learning information.";

    cell.accessoryType =
        UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];

    if (indexPath.section == 1) {

        AVX512MethodInfo *method =
            self.methods[indexPath.row];

        [self showMethod:method];
        return;
    }

    if (indexPath.section == 2) {
        [self showLearning];
    }
}

- (void)showLearning
{
    UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:
         @"Understanding the Implementation"
         message:
         @"The Objective-C runtime gives AVX512 the method's "
         @"selector, type encoding, and IMP address.\n\n"
         @"The IMP is the native implementation entry point. "
         @"An ARM64 analysis layer can associate that address "
         @"with a Mach-O image and decode instructions.\n\n"
         @"NOP is exposed as a controlled test-patch concept. "
         @"The generated test project records the proposed "
         @"replacement instead of silently modifying the "
         @"original binary."
         preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"Close"
                              style:UIAlertActionStyleDefault
                            handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)showMethod:(AVX512MethodInfo *)method
{
    NSString *imp =
        AVX512IMPString(method.implementation);

    uintptr_t slide = 0;
    uintptr_t offset = 0;

    NSString *image =
        AVX512ImageForAddress(
            method.implementationAddress,
            &slide,
            &offset);

    NSString *message =
        [NSString stringWithFormat:
         @"Selector\n%@\n\n"
         @"Return type\n%@\n\n"
         @"Arguments\n%lu\n\n"
         @"Type encoding\n%@\n\n"
         @"IMP\n%@\n\n"
         @"Image\n%@\n\n"
         @"Image offset\n0x%llX\n\n"
         @"Implementation\n"
         @"The IMP is the native entry point associated with "
         @"this Objective-C method. The next analysis layer "
         @"can decode instructions beginning at this address.",
         method.selectorName,
         method.returnType,
         (unsigned long)method.argumentCount,
         method.typeEncoding,
         imp,
         image ?: method.imageName ?: @"Unknown",
         (unsigned long long)
         (method.imageOffset
          ? method.imageOffset
          : offset)];

    UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:
         [NSString stringWithFormat:
          @"-%@",
          method.selectorName]
         message:message
         preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"Implementation"
                              style:UIAlertActionStyleDefault
                            handler:^(__unused UIAlertAction *action) {
        [self showImplementation:method];
    }]];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"NOP Test Preview"
                              style:UIAlertActionStyleDefault
                            handler:^(__unused UIAlertAction *action) {
        [self showNOPPreview:method];
    }]];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"Close"
                              style:UIAlertActionStyleCancel
                            handler:nil]];

    UIPopoverPresentationController *popover =
        alert.popoverPresentationController;

    popover.sourceView = self.view;

    popover.sourceRect =
        CGRectMake(CGRectGetMidX(self.view.bounds),
                   CGRectGetMidY(self.view.bounds),
                   1,
                   1);

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)showImplementation:(AVX512MethodInfo *)method
{
    NSString *message =
        [NSString stringWithFormat:
         @"IMP\n%@\n\n"
         @"ARM64 implementation entry point\n"
         @"0x%llX\n\n"
         @"Runtime signature\n%@\n\n"
         @"Encoding\n%@\n\n"
         @"Learning note\n"
         @"On ARM64, Objective-C arguments use the platform "
         @"calling convention. x0 and x1 contain self and _cmd "
         @"for a normal Objective-C instance method.\n\n"
         @"A Capstone-backed implementation view can use this "
         @"IMP address as the starting point for instruction "
         @"decoding.",
         AVX512IMPString(method.implementation),
         (unsigned long long)method.implementationAddress,
         method.returnType,
         method.typeEncoding];

    UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:@"Implementation"
         message:message
         preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"Close"
                              style:UIAlertActionStyleDefault
                            handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)showNOPPreview:(AVX512MethodInfo *)method
{
    UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:@"NOP Test Patch"
         message:
         @"This creates a test-patch description for the selected "
         @"implementation.\n\n"
         @"Original instruction\n"
         @"<decoded ARM64 instruction>\n\n"
         @"Replacement\n"
         @"nop\n\n"
         @"The generated test project keeps the original method "
         @"information and records the proposed replacement. "
         @"It does not rewrite the source application."
         preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"Create Test Project"
                              style:UIAlertActionStyleDefault
                            handler:^(__unused UIAlertAction *action) {
        [self createTestProjectForMethod:method];
    }]];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"Cancel"
                              style:UIAlertActionStyleCancel
                            handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)createTestProjectForMethod:
    (AVX512MethodInfo *)method
{
    NSString *directory =
        [NSTemporaryDirectory()
         stringByAppendingPathComponent:
         [NSString stringWithFormat:
          @"AVX512-Test-%@",
          NSUUID.UUID.UUIDString]];

    NSError *error = nil;

    [[NSFileManager defaultManager]
     createDirectoryAtPath:directory
     withIntermediateDirectories:YES
     attributes:nil
     error:&error];

    if (error) {
        [self showError:error];
        return;
    }

    NSString *manifest =
        [NSString stringWithFormat:
         @"{\n"
          "  \"generator\": \"AVX512\",\n"
          "  \"mode\": \"Runtime Test Harness\",\n"
          "  \"class\": \"%@\",\n"
          "  \"selector\": \"%@\",\n"
          "  \"imp\": \"0x%llX\",\n"
          "  \"patch\": {\n"
          "    \"type\": \"NOP\",\n"
          "    \"originalInstruction\": "
          "\"<decoded ARM64 instruction>\",\n"
          "    \"replacementInstruction\": \"nop\",\n"
          "    \"reversible\": true\n"
          "  }\n"
          "}\n",
         self.classInfo.className,
         method.selectorName,
         (unsigned long long)
         method.implementationAddress];

    NSString *manifestPath =
        [directory stringByAppendingPathComponent:
         @"AVX512PatchManifest.json"];

    [manifest writeToFile:manifestPath
                atomically:YES
                  encoding:NSUTF8StringEncoding
                     error:&error];

    if (error) {
        [self showError:error];
        return;
    }

    NSString *readme =
        [NSString stringWithFormat:
         @"# AVX512 Test Patch\n\n"
          "Generated by AVX512 / DELvEK.NET.\n\n"
          "## Target\n\n"
          "Class: `%@`\n\n"
          "Method: `-%@`\n\n"
          "IMP: `0x%llX`\n\n"
          "## Test operation\n\n"
          "This project records a proposed ARM64 NOP replacement "
          "for controlled testing.\n\n"
          "The original application binary is not modified by "
          "the generator.\n\n"
          "## Next analysis stage\n\n"
          "A Capstone-backed analyzer can resolve the implementation "
          "address, decode the instruction stream, construct basic "
          "blocks, and present the proposed patch for review before "
          "a test build is produced.\n",
         self.classInfo.className,
         method.selectorName,
         (unsigned long long)
         method.implementationAddress];

    NSString *readmePath =
        [directory stringByAppendingPathComponent:
         @"README.md"];

    [readme writeToFile:readmePath
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];

    if (error) {
        [self showError:error];
        return;
    }

    UIActivityViewController *share =
        [[UIActivityViewController alloc]
         initWithActivityItems:
         @[
             [NSURL fileURLWithPath:manifestPath],
             [NSURL fileURLWithPath:readmePath]
         ]
         applicationActivities:nil];

    [self presentViewController:share
                       animated:YES
                     completion:nil];
}

- (void)showError:(NSError *)error
{
    UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:@"AVX512 Error"
         message:error.localizedDescription
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

#pragma mark - Generator

@interface AVX512HookTemplateGenerator ()

@property (nonatomic, strong)
    NSArray<AVX512ClassInfo *> *allClasses;

@property (nonatomic, strong)
    NSArray<AVX512ClassInfo *> *filteredClasses;

@property (nonatomic, strong)
    NSMutableSet<NSString *> *selectedClasses;

@property (nonatomic, strong)
    UISearchController *searchController;

@property (nonatomic, assign)
    BOOL loadingRuntimeClasses;

@end

@implementation AVX512HookTemplateGenerator

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"AVX512";

    self.selectedClasses =
        [NSMutableSet set];

    self.tableView.rowHeight =
        UITableViewAutomaticDimension;

    self.tableView.estimatedRowHeight =
        72.0;

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemClose
         target:self
         action:@selector(close)];

    UIImage *signature =
        [UIImage systemImageNamed:@"signature.zh"];

    if (!signature) {
        signature =
            [UIImage systemImageNamed:@"signature"];
    }

    if (!signature) {
        signature =
            [UIImage systemImageNamed:@"square.and.pencil"];
    }

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
         initWithImage:signature
         style:UIBarButtonItemStylePlain
         target:self
         action:@selector(makeDylib)];

    self.navigationItem.rightBarButtonItem.accessibilityLabel =
        @"Make Dylib";

    [self configureSearch];

    /*
     * Runtime enumeration can be very large.
     * Do not perform the entire class/method walk on the UI thread.
     */
    [self loadRuntimeClasses];
}

#pragma mark - Search

- (void)configureSearch
{
    self.searchController =
        [[UISearchController alloc]
         initWithSearchResultsController:nil];

    self.searchController.obscuresBackgroundDuringPresentation =
        NO;

    self.searchController.searchResultsUpdater =
        self;

    self.navigationItem.searchController =
        self.searchController;

    self.navigationItem.hidesSearchBarWhenScrolling =
        NO;

    self.definesPresentationContext =
        YES;
}

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
    NSString *query =
        searchController.searchBar.text;

    NSArray<AVX512ClassInfo *> *source =
        self.allClasses ?: @[];

    if (!query.length) {
        self.filteredClasses = source;
    } else {

        NSPredicate *predicate =
            [NSPredicate predicateWithBlock:
             ^BOOL(AVX512ClassInfo *obj,
                   NSDictionary<NSString *, id> *_) {

            return [obj.className
                    localizedCaseInsensitiveContainsString:query];
        }];

        self.filteredClasses =
            [source filteredArrayUsingPredicate:predicate];
    }

    [self.tableView reloadData];
}

#pragma mark - Runtime Discovery

- (void)loadRuntimeClasses
{
    if (self.loadingRuntimeClasses) {
        return;
    }

    self.loadingRuntimeClasses = YES;

    /*
     * Snapshot the runtime on a background queue.
     *
     * The resulting model objects are constructed away from the
     * main thread. UI state is assigned back on the main queue.
     */
    dispatch_async(
        dispatch_get_global_queue(
            QOS_CLASS_USER_INITIATED,
            0),
        ^{

        uint32_t count = 0;

        Class *classes =
            objc_copyClassList(&count);

        NSMutableArray<AVX512ClassInfo *> *results =
            [NSMutableArray arrayWithCapacity:count];

        for (uint32_t i = 0; i < count; i++) {

            @autoreleasepool {

                Class cls = classes[i];

                if (!cls) {
                    continue;
                }

                NSString *name =
                    NSStringFromClass(cls);

                if (!name.length) {
                    continue;
                }

                AVX512ClassInfo *info =
                    [self inspectClass:cls];

                if (info) {
                    [results addObject:info];
                }
            }
        }

        free(classes);

        [results sortUsingComparator:
         ^NSComparisonResult(AVX512ClassInfo *a,
                             AVX512ClassInfo *b) {

            return [a.className
                    localizedCaseInsensitiveCompare:
                    b.className];
        }];

        dispatch_async(
            dispatch_get_main_queue(),
            ^{

            self.loadingRuntimeClasses = NO;

            self.allClasses = results;
            self.filteredClasses = results;

            [self.tableView reloadData];
        });
    });
}

- (AVX512ClassInfo *)inspectClass:(Class)cls
{
    if (!cls) {
        return nil;
    }

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

    NSMutableArray<AVX512MethodInfo *> *methods =
        [NSMutableArray array];

    NSMutableSet<NSString *> *seen =
        [NSMutableSet set];

    Class current = cls;
    BOOL inherited = NO;

    while (current) {

        unsigned int count = 0;

        Method *list =
            class_copyMethodList(
                current,
                &count);

        if (list) {

            for (unsigned int i = 0;
                 i < count;
                 i++) {

                @autoreleasepool {

                    Method method = list[i];

                    if (!method) {
                        continue;
                    }

                    SEL selector =
                        method_getName(method);

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

                    AVX512MethodInfo *methodInfo =
                        [AVX512MethodInfo new];

                    methodInfo.selectorName =
                        selectorName;

                    methodInfo.typeEncoding =
                        encoding
                        ? [NSString stringWithUTF8String:encoding]
                        : @"";

                    methodInfo.returnType =
                        AVX512HumanType(encoding);

                    methodInfo.argumentCount =
                        AVX512ExplicitArgumentCount(method);

                    methodInfo.inherited =
                        inherited;

                    methodInfo.implementation =
                        method_getImplementation(method);

                    methodInfo.implementationAddress =
                        (uintptr_t)
                        methodInfo.implementation;

                    uintptr_t slide = 0;
                    uintptr_t offset = 0;

                    methodInfo.imageName =
                        AVX512ImageForAddress(
                            methodInfo.implementationAddress,
                            &slide,
                            &offset);

                    methodInfo.imageOffset =
                        offset;

                    [methods addObject:methodInfo];
                }
            }

            free(list);
        }

        inherited = YES;

        current =
            class_getSuperclass(current);
    }

    [methods sortUsingComparator:
     ^NSComparisonResult(AVX512MethodInfo *a,
                         AVX512MethodInfo *b) {

        return [a.selectorName
                localizedCaseInsensitiveCompare:
                b.selectorName];
    }];

    info.methods = methods;

    return info;
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:
    (UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.filteredClasses.count;
}

- (UITableViewCell *)tableView:
    (UITableView *)tableView
    cellForRowAtIndexPath:
    (NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [[UITableViewCell alloc]
         initWithStyle:UITableViewCellStyleSubtitle
         reuseIdentifier:nil];

    AVX512ClassInfo *info =
        self.filteredClasses[indexPath.row];

    cell.textLabel.text =
        info.className;

    cell.detailTextLabel.text =
        [NSString stringWithFormat:
         @"%@ · %lu methods",
         info.superclassName ?: @"No superclass",
         (unsigned long)info.methods.count];

    cell.accessoryType =
        [self.selectedClasses
         containsObject:info.className]
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:
    (NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];

    AVX512ClassInfo *info =
        self.filteredClasses[indexPath.row];

    if ([self.selectedClasses
         containsObject:info.className]) {

        [self.selectedClasses
         removeObject:info.className];

    } else {

        [self.selectedClasses
         addObject:info.className];
    }

    [tableView reloadRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:
                     UITableViewRowAnimationAutomatic];

    [self showClassInspector:info];
}

#pragma mark - Class Inspector

- (void)showClassInspector:
    (AVX512ClassInfo *)info
{
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

#pragma mark - Make Dylib

- (void)makeDylib
{
    if (self.loadingRuntimeClasses) {

        UIAlertController *alert =
            [UIAlertController
             alertControllerWithTitle:
             @"Runtime Still Loading"
             message:
             @"AVX512 is still collecting runtime metadata. "
             @"Please wait for the class list to finish loading."
             preferredStyle:
             UIAlertControllerStyleAlert];

        [alert addAction:
         [UIAlertAction actionWithTitle:@"OK"
                                  style:
                                  UIAlertActionStyleDefault
                                handler:nil]];

        [self presentViewController:alert
                           animated:YES
                         completion:nil];

        return;
    }

    if (self.selectedClasses.count == 0) {

        UIAlertController *alert =
            [UIAlertController
             alertControllerWithTitle:
             @"No Classes Selected"
             message:
             @"Select at least one class first. "
             @"You can inspect its methods and then generate "
             @"a runtime diagnostic or controlled test-harness "
             @"project."
             preferredStyle:
             UIAlertControllerStyleAlert];

        [alert addAction:
         [UIAlertAction actionWithTitle:@"OK"
                                  style:
                                  UIAlertActionStyleDefault
                                handler:nil]];

        [self presentViewController:alert
                           animated:YES
                         completion:nil];

        return;
    }

    UIAlertController *config =
        [UIAlertController
         alertControllerWithTitle:@"Make Dylib"
         message:
         [NSString stringWithFormat:
          @"%lu class%@ selected.",
          (unsigned long)
          self.selectedClasses.count,
          self.selectedClasses.count == 1
          ? @""
          : @"es"]
         preferredStyle:
         UIAlertControllerStyleActionSheet];

    [config addAction:
     [UIAlertAction
      actionWithTitle:@"Runtime Diagnostic"
      style:UIAlertActionStyleDefault
      handler:^(__unused UIAlertAction *action) {

        [self generateProject:
         AVX512DylibTypeDiagnostic
         buildStyle:
         AVX512BuildStyleShell];
    }]];

    [config addAction:
     [UIAlertAction
      actionWithTitle:@"Runtime Test Harness"
      style:UIAlertActionStyleDefault
      handler:^(__unused UIAlertAction *action) {

        [self generateProject:
         AVX512DylibTypeTestHarness
         buildStyle:
         AVX512BuildStyleShell];
    }]];

    [config addAction:
     [UIAlertAction
      actionWithTitle:@"GitHub Actions Test Harness"
      style:UIAlertActionStyleDefault
      handler:^(__unused UIAlertAction *action) {

        [self generateProject:
         AVX512DylibTypeTestHarness
         buildStyle:
         AVX512BuildStyleGitHubActions];
    }]];

    [config addAction:
     [UIAlertAction
      actionWithTitle:@"Cancel"
      style:UIAlertActionStyleCancel
      handler:nil]];

    UIPopoverPresentationController *popover =
        config.popoverPresentationController;

    popover.barButtonItem =
        self.navigationItem.rightBarButtonItem;

    [self presentViewController:config
                       animated:YES
                     completion:nil];
}

#pragma mark - Project Generation

- (void)generateProject:
    (AVX512DylibType)dylibType
    buildStyle:
    (AVX512BuildStyle)buildStyle
{
    /*
     * Snapshot the selection before generating files.
     * This prevents later UI changes from changing the generated
     * project while generation is in progress.
     */
    NSArray<NSString *> *selected =
        [self.selectedClasses.allObjects
         sortedArrayUsingSelector:
         @selector(localizedCaseInsensitiveCompare:)];

    if (selected.count == 0) {
        return;
    }

    NSString *directory =
        [NSTemporaryDirectory()
         stringByAppendingPathComponent:
         [NSString stringWithFormat:
          @"AVX512-%@",
          NSUUID.UUID.UUIDString]];

    NSError *error = nil;

    [[NSFileManager defaultManager]
     createDirectoryAtPath:directory
     withIntermediateDirectories:YES
     attributes:nil
     error:&error];

    if (error) {
        [self showGeneratorError:error];
        return;
    }

    NSString *header =
        [self generatedHeader];

    NSString *implementation =
        [self generatedImplementation:dylibType
                         selectedClasses:selected];

    NSString *readme =
        [self generatedREADME:dylibType
                    buildStyle:buildStyle];

    NSString *headerPath =
        [directory stringByAppendingPathComponent:
         @"AVX512Hook.h"];

    NSString *implementationPath =
        [directory stringByAppendingPathComponent:
         @"AVX512Hook.m"];

    NSString *readmePath =
        [directory stringByAppendingPathComponent:
         @"README.md"];

    [header writeToFile:headerPath
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];

    if (error) {
        [self showGeneratorError:error];
        return;
    }

    [implementation writeToFile:implementationPath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&error];

    if (error) {
        [self showGeneratorError:error];
        return;
    }

    [readme writeToFile:readmePath
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];

    if (error) {
        [self showGeneratorError:error];
        return;
    }

    NSMutableArray<NSURL *> *files =
        [NSMutableArray array];

    [files addObject:
     [NSURL fileURLWithPath:headerPath]];

    [files addObject:
     [NSURL fileURLWithPath:implementationPath]];

    [files addObject:
     [NSURL fileURLWithPath:readmePath]];

    if (buildStyle ==
        AVX512BuildStyleShell) {

        NSString *build =
            [self generatedBuildScript];

        NSString *buildPath =
            [directory stringByAppendingPathComponent:
             @"build.sh"];

        [build writeToFile:buildPath
                atomically:YES
                  encoding:NSUTF8StringEncoding
                     error:&error];

        if (error) {
            [self showGeneratorError:error];
            return;
        }

        [files addObject:
         [NSURL fileURLWithPath:buildPath]];

    } else {

        NSString *workflow =
            [self generatedGitHubWorkflow];

        NSString *github =
            [directory stringByAppendingPathComponent:
             @".github/workflows"];

        [[NSFileManager defaultManager]
         createDirectoryAtPath:github
         withIntermediateDirectories:YES
         attributes:nil
         error:&error];

        if (error) {
            [self showGeneratorError:error];
            return;
        }

        NSString *workflowPath =
            [github stringByAppendingPathComponent:
             @"build.yml"];

        [workflow writeToFile:workflowPath
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:&error];

        if (error) {
            [self showGeneratorError:error];
            return;
        }

        [files addObject:
         [NSURL fileURLWithPath:workflowPath]];
    }

    UIActivityViewController *share =
        [[UIActivityViewController alloc]
         initWithActivityItems:files
         applicationActivities:nil];

    [self presentViewController:share
                       animated:YES
                     completion:nil];
}

#pragma mark - Generated Header

- (NSString *)generatedHeader
{
    return
    @"//\n"
     "// AVX512Hook.h\n"
     "// Generated by AVX512 / DELvEK.NET\n"
     "//\n\n"
     "#import <Foundation/Foundation.h>\n"
     "#import <objc/runtime.h>\n\n"
     "FOUNDATION_EXPORT void "
     "AVX512PrintSelectedRuntimeMetadata(void);\n";
}

#pragma mark - Generated Implementation

- (NSString *)generatedImplementation:
    (AVX512DylibType)dylibType
    selectedClasses:
    (NSArray<NSString *> *)selectedClasses
{
    NSMutableString *source =
        [NSMutableString string];

    [source appendString:
     @"//\n"
      "// AVX512Hook.m\n"
      "// Generated by AVX512 / DELvEK.NET\n"
      "//\n\n"
      "#import \"AVX512Hook.h\"\n"
      "#import <objc/runtime.h>\n"
      "#import <stdio.h>\n"
      "#import <stdint.h>\n"
      "#import <stdatomic.h>\n\n"];

    [source appendString:
     @"static atomic_flag "
      "AVX512MetadataRunning = ATOMIC_FLAG_INIT;\n\n"];

    [source appendString:
     @"static void AVX512PrintClass(Class cls)\n"
      "{\n"
      "    if (!cls) return;\n\n"
      "    const char *name = class_getName(cls);\n"
      "    const char *superName = "
      "class_getName(class_getSuperclass(cls));\n\n"
      "    printf(\"[AVX512] CLASS %s\\\\n\", "
      "name ? name : \"<unknown>\");\n"
      "    printf(\"[AVX512] SUPER %s\\\\n\", "
      "superName ? superName : \"<none>\");\n\n"
      "    unsigned int count = 0;\n"
      "    Method *methods = class_copyMethodList(cls, &count);\n\n"
      "    if (!methods) {\n"
      "        printf(\"[AVX512] METHODS 0\\\\n\");\n"
      "        return;\n"
      "    }\n\n"
      "    printf(\"[AVX512] METHODS %u\\\\n\", count);\n\n"
      "    for (unsigned int i = 0; i < count; i++) {\n"
      "        Method method = methods[i];\n"
      "        SEL selector = method_getName(method);\n"
      "        const char *encoding = "
      "method_getTypeEncoding(method);\n"
      "        IMP imp = method_getImplementation(method);\n\n"
      "        printf(\"[AVX512] METHOD %s\\\\n\",\n"
      "               selector ? sel_getName(selector) : "
      "\"<unknown>\");\n"
      "        printf(\"[AVX512] IMP 0x%llX\\\\n\",\n"
      "               (unsigned long long)(uintptr_t)imp);\n"
      "        printf(\"[AVX512] ENCODING %s\\\\n\",\n"
      "               encoding ? encoding : \"<none>\");\n"
      "    }\n\n"
      "    free(methods);\n"
      "}\n\n"];

    [source appendString:
     @"void AVX512PrintSelectedRuntimeMetadata(void)\n"
      "{\n"
      "    /*\n"
      "     * Explicit invocation only.\n"
      "     *\n"
      "     * This used to be called from a Mach-O constructor.\n"
      "     * Constructors run while the image is loading, which means\n"
      "     * a large runtime scan can stall the host before it has\n"
      "     * finished loading the dylib.\n"
      "     *\n"
      "     * The function remains exported so the host/test harness\n"
      "     * can request diagnostics deliberately.\n"
      "     */\n\n"
      "    if (atomic_flag_test_and_set(&AVX512MetadataRunning)) {\n"
      "        printf(\"[AVX512] Metadata scan already running.\\\\n\");\n"
      "        return;\n"
      "    }\n\n"];

    for (NSString *className in selectedClasses) {

        NSString *escaped =
            [className
             stringByReplacingOccurrencesOfString:@"\\"
             withString:@"\\\\"];

        escaped =
            [escaped
             stringByReplacingOccurrencesOfString:@"\""
             withString:@"\\\""];

        [source appendFormat:
         @"    AVX512PrintClass("
          "NSClassFromString(@\"%@\"));\n",
         escaped];
    }

    NSString *mode =
        dylibType ==
        AVX512DylibTypeTestHarness
        ? @"Runtime Test Harness"
        : @"Runtime Diagnostic";

    [source appendFormat:
     @"\n"
      "    printf(\"[AVX512] MODE: %@\\\\n\");\n"
      "    atomic_flag_clear(&AVX512MetadataRunning);\n"
      "}\n\n",
     mode];

    /*
     * Deliberately no __attribute__((constructor)).
     *
     * Loading the generated dylib must not automatically trigger
     * the complete Objective-C runtime enumeration.
     */
    [source appendString:
     @"/*\n"
      " * AVX512 intentionally does not install a constructor here.\n"
      " * Call AVX512PrintSelectedRuntimeMetadata() explicitly from\n"
      " * the controlled diagnostic/test harness when desired.\n"
      " */\n"];

    return source;
}

#pragma mark - README

- (NSString *)generatedREADME:
    (AVX512DylibType)dylibType
    buildStyle:
    (AVX512BuildStyle)buildStyle
{
    NSMutableString *readme =
        [NSMutableString string];

    [readme appendString:
     @"# AVX512 Generated Test Dylib\n\n"
      "Generated by **AVX512 / DELvEK.NET**.\n\n"];

    [readme appendString:
     dylibType ==
     AVX512DylibTypeTestHarness
     ? @"Mode: **Runtime Test Harness**\n\n"
     : @"Mode: **Runtime Diagnostic**\n\n"];

    [readme appendString:
     buildStyle ==
     AVX512BuildStyleGitHubActions
     ? @"Build: **GitHub Actions**\n\n"
     : @"Build: **Shell Script**\n\n"];

    [readme appendString:
     @"## Selected Classes\n\n"];

    NSArray<NSString *> *selected =
        [self.selectedClasses.allObjects
         sortedArrayUsingSelector:
         @selector(localizedCaseInsensitiveCompare:)];

    for (NSString *name in selected) {
        [readme appendFormat:
         @"- `%@`\n",
         name];
    }

    [readme appendString:
     @"\n## Runtime implementation inspection\n\n"
      "AVX512 records the Objective-C selector, type encoding, "
      "implementation pointer (IMP), image information, and "
      "runtime method metadata.\n\n"
      "The implementation-learning view is designed to connect "
      "Objective-C runtime metadata with ARM64/Mach-O analysis.\n\n"
      "## Runtime loading behavior\n\n"
      "The generated diagnostic dylib does not perform its full "
      "metadata enumeration from a Mach-O constructor. The exported "
      "metadata function is invoked explicitly by the host/test "
      "harness so image loading remains lightweight.\n\n"
      "## NOP test patches\n\n"
      "A NOP action represents a proposed replacement for a selected "
      "instruction in a controlled test environment. The generator "
      "does not rewrite the original application source or binary.\n\n"
      "A future Capstone-backed analyzer can populate the exact "
      "instruction bytes and generate a reversible test-patch "
      "manifest after verifying instruction boundaries.\n\n"
      "## Architectures\n\n"
      "- arm64\n"
      "- arm64e\n\n"];

    return readme;
}

#pragma mark - Build Script

- (NSString *)generatedBuildScript
{
    return
    @"#!/bin/sh\n"
     "set -eu\n\n"
     "SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
     "CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n\n"
     "mkdir -p build\n\n"
     "build_slice() {\n"
     "    ARCH=\"$1\"\n"
     "    \"$CLANG\" \\\n"
     "        -arch \"$ARCH\" \\\n"
     "        -isysroot \"$SDK\" \\\n"
     "        -miphoneos-version-min=14.0 \\\n"
     "        -dynamiclib \\\n"
     "        -fobjc-arc \\\n"
     "        -framework Foundation \\\n"
     "        -framework UIKit \\\n"
     "        -O2 \\\n"
     "        -Wall \\\n"
     "        -Wextra \\\n"
     "        -install_name \"@rpath/AVX512.dylib\" \\\n"
     "        AVX512Hook.m \\\n"
     "        -o \"build/AVX512-${ARCH}.dylib\"\n"
     "}\n\n"
     "build_slice arm64\n"
     "build_slice arm64e\n\n"
     "lipo -create \\\n"
     "    build/AVX512-arm64.dylib \\\n"
     "    build/AVX512-arm64e.dylib \\\n"
     "    -output build/AVX512.dylib\n\n"
     "if command -v ldid >/dev/null 2>&1; then\n"
     "    ldid -S build/AVX512.dylib\n"
     "fi\n\n"
     "file build/AVX512.dylib\n"
     "lipo -info build/AVX512.dylib\n";
}

#pragma mark - GitHub Actions

- (NSString *)generatedGitHubWorkflow
{
    return
    @"name: Build AVX512 Test Dylib\n\n"
     "on:\n"
     "  workflow_dispatch:\n"
     "  push:\n"
     "    branches: [main]\n\n"
     "jobs:\n"
     "  build:\n"
     "    runs-on: macos-15\n\n"
     "    steps:\n"
     "      - name: Checkout\n"
     "        uses: actions/checkout@v4\n\n"
     "      - name: Show Xcode\n"
     "        run: xcodebuild -version\n\n"
     "      - name: Install ldid\n"
     "        run: brew install ldid\n\n"
     "      - name: Build arm64\n"
     "        run: |\n"
     "          set -e\n"
     "          SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
     "          CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n"
     "          mkdir -p build\n"
     "          \"$CLANG\" \\\n"
     "            -arch arm64 \\\n"
     "            -isysroot \"$SDK\" \\\n"
     "            -miphoneos-version-min=14.0 \\\n"
     "            -dynamiclib \\\n"
     "            -fobjc-arc \\\n"
     "            -framework Foundation \\\n"
     "            -framework UIKit \\\n"
     "            -O2 -Wall -Wextra \\\n"
     "            -install_name '@rpath/AVX512.dylib' \\\n"
     "            AVX512Hook.m \\\n"
     "            -o build/AVX512-arm64.dylib\n\n"
     "      - name: Build arm64e\n"
     "        run: |\n"
     "          set -e\n"
     "          SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
     "          CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n"
     "          \"$CLANG\" \\\n"
     "            -arch arm64e \\\n"
     "            -isysroot \"$SDK\" \\\n"
     "            -miphoneos-version-min=14.0 \\\n"
     "            -dynamiclib \\\n"
     "            -fobjc-arc \\\n"
     "            -framework Foundation \\\n"
     "            -framework UIKit \\\n"
     "            -O2 -Wall -Wextra \\\n"
     "            -install_name '@rpath/AVX512.dylib' \\\n"
     "            AVX512Hook.m \\\n"
     "            -o build/AVX512-arm64e.dylib\n\n"
     "      - name: Create universal dylib\n"
     "        run: |\n"
     "          set -e\n"
     "          lipo -create \\\n"
     "            build/AVX512-arm64.dylib \\\n"
     "            build/AVX512-arm64e.dylib \\\n"
     "            -output build/AVX512.dylib\n"
     "          ldid -S build/AVX512.dylib\n"
     "          file build/AVX512.dylib\n"
     "          lipo -info build/AVX512.dylib\n\n"
     "      - name: Upload dylib\n"
     "        uses: actions/upload-artifact@v4\n"
     "        with:\n"
     "          name: AVX512-test-dylib\n"
     "          path: build/AVX512.dylib\n\n"
     "      - name: Upload slices\n"
     "        uses: actions/upload-artifact@v4\n"
     "        with:\n"
     "          name: AVX512-test-slices\n"
     "          path: |\n"
     "            build/AVX512-arm64.dylib\n"
     "            build/AVX512-arm64e.dylib\n";
}

#pragma mark - Close

- (void)close
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Errors

- (void)showGeneratorError:(NSError *)error
{
    UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:
         @"AVX512 Generator Error"
         message:error.localizedDescription
         preferredStyle:
         UIAlertControllerStyleAlert];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"OK"
                              style:
                              UIAlertActionStyleDefault
                            handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

@end