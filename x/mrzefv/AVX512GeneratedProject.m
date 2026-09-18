//
//  AVX512GeneratedProject.m
//  AVX512 / MRzefv
//
//  Converts recorded AVX512 edit operations into a real,
//  isolated MRzefvGenerated build project.
//
//  This file runs inside AVX512.
//  It is NOT compiled into MRzefvGenerated.dylib.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#pragma mark - Operation Compatibility
typedef NS_ENUM(NSInteger, AVX512GeneratedOperationType) {
    AVX512GeneratedOperationMove = 0,
    AVX512GeneratedOperationResize,
    AVX512GeneratedOperationReplaceText,
    AVX512GeneratedOperationAddText,
    AVX512GeneratedOperationSetHidden,
    AVX512GeneratedOperationReplaceImage
};
@interface AVX512GeneratedOperation : NSObject
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *viewPath;
@property (nonatomic, strong) NSDictionary *values;
@end
@implementation AVX512GeneratedOperation
@end
#pragma mark - Generator
@interface AVX512GeneratedProject : NSObject
+ (nullable NSURL *)generateProjectWithTargetView:(UIView *)targetView
                                      operations:(NSArray *)operations
                                           error:(NSError **)error;
@end
#pragma mark - Implementation
@implementation AVX512GeneratedProject
#pragma mark - Public
+ (NSURL *)generateProjectWithTargetView:(UIView *)targetView
                              operations:(NSArray *)operations
                                   error:(NSError **)error
{
    if (!targetView) {
        return [self fail:error
                    code:1
                  reason:@"No target view was supplied."];
    }
    if (operations.count == 0) {
        return [self fail:error
                    code:2
                  reason:@"No edit operations were recorded."];
    }
    /*
     * IMPORTANT:
     *
     * Generate exactly ONE session ID.
     *
     * Every generated artifact must use this same value:
     *
     *   project directory
     *   manifest.json
     *   generation-receipt.json
     *   MRzefvGenerated.h
     *   MRzefvGenerated.m
     *
     * GitHub Actions gets a separate build ID.
     */
    NSString *sessionID =
        [self sessionIdentifier];
    NSString *targetName =
        @"MRzefvGenerated";
    NSURL *root =
        [self projectDirectoryForSession:sessionID
                                  target:targetName
                                   error:error];
    if (!root) {
        return nil;
    }
    NSFileManager *fm =
        [NSFileManager defaultManager];
    NSURL *sources =
        [root URLByAppendingPathComponent:@"Sources"
                              isDirectory:YES];
    NSURL *workflows =
        [root URLByAppendingPathComponent:@".github/workflows"
                              isDirectory:YES];
    if (![fm createDirectoryAtURL:sources
       withIntermediateDirectories:YES
                        attributes:nil
                             error:error]) {
        return nil;
    }
    if (![fm createDirectoryAtURL:workflows
       withIntermediateDirectories:YES
                        attributes:nil
                             error:error]) {
        return nil;
    }
    /*
     * Do not use object_getClass() here.
     *
     * The generator already has the target object, so [targetView class]
     * is the direct and correct way to identify its Objective-C class.
     */
    NSString *className =
        NSStringFromClass([targetView class]);
    if (className.length == 0) {
        className = @"UIView";
    }
    NSString *header =
        [self headerSourceForTarget:targetName
                          sessionID:sessionID];
    NSString *implementation =
        [self implementationSourceForTarget:targetName
                                  sessionID:sessionID
                                  className:className
                                 operations:operations];
    NSString *manifest =
        [self manifestForTarget:targetName
                      sessionID:sessionID
                      className:className
                     operations:operations];
    NSString *buildScript =
        [self buildScript];
    NSString *workflow =
        [self workflow];
    if (![self writeString:header
                    toURL:[sources
                        URLByAppendingPathComponent:
                            @"MRzefvGenerated.h"]
                    error:error]) {
        return nil;
    }
    if (![self writeString:implementation
                    toURL:[sources
                        URLByAppendingPathComponent:
                            @"MRzefvGenerated.m"]
                    error:error]) {
        return nil;
    }
    if (![self writeString:manifest
                    toURL:[root
                        URLByAppendingPathComponent:
                            @"manifest.json"]
                    error:error]) {
        return nil;
    }
    if (![self writeString:buildScript
                    toURL:[root
                        URLByAppendingPathComponent:
                            @"build.sh"]
                    error:error]) {
        return nil;
    }
    if (![self writeString:workflow
                    toURL:[workflows
                        URLByAppendingPathComponent:
                            @"build-mrzefv-generated.yml"]
                    error:error]) {
        return nil;
    }
    /*
     * Make build.sh executable.
     */
    NSDictionary *attributes = @{
        NSFilePosixPermissions : @0755
    };
    [fm setAttributes:attributes
         ofItemAtPath:
            [[root
                URLByAppendingPathComponent:@"build.sh"]
                path]
              error:nil];
    /*
     * Write generation receipt.
     *
     * The receipt uses the EXACT SAME session ID as manifest.json.
     */
    NSDictionary *receipt = @{
        @"generator" : @"AVX512/MRzefv",
        @"target" : targetName,
        @"sessionID" : sessionID,
        @"className" : className,
        @"operationCount" : @(operations.count),
        @"status" : @"generated"
    };
    NSData *receiptData =
        [NSJSONSerialization
            dataWithJSONObject:receipt
                       options:NSJSONWritingPrettyPrinted
                         error:error];
    if (!receiptData) {
        return nil;
    }
    if (![receiptData
            writeToURL:
                [root
                    URLByAppendingPathComponent:@"generation-receipt.json"]
             options:NSDataWritingAtomic
               error:error]) {
        return nil;
    }
    NSLog(@"[AVX512] Generated project:");
    NSLog(@"%@", root.path);
    NSLog(@"[AVX512] Session ID:");
    NSLog(@"%@", sessionID);
    return root;
}
#pragma mark - Project Directory
+ (NSURL *)projectDirectoryForSession:(NSString *)sessionID
                               target:(NSString *)target
                                error:(NSError **)error
{
    NSFileManager *fm =
        [NSFileManager defaultManager];
    NSURL *documents =
        [fm URLsForDirectory:NSDocumentDirectory
                   inDomains:NSUserDomainMask].firstObject;
    if (!documents) {
        return [self fail:error
                    code:10
                  reason:@"Unable to locate Documents directory."];
    }
    NSURL *buildRoot =
        [documents
            URLByAppendingPathComponent:@"AVX512/Generated"
                              isDirectory:YES];
    NSURL *project =
        [[buildRoot
            URLByAppendingPathComponent:
                sessionID
                              isDirectory:YES]
            URLByAppendingPathComponent:
                target
                          isDirectory:YES];
    if (![fm createDirectoryAtURL:project
       withIntermediateDirectories:YES
                        attributes:nil
                             error:error]) {
        return nil;
    }
    return project;
}
#pragma mark - Header
+ (NSString *)headerSourceForTarget:(NSString *)target
                          sessionID:(NSString *)sessionID
{
    NSMutableString *source =
        [NSMutableString string];
    [source appendString:
@"//\n"
@"// MRzefvGenerated.h\n"
@"// Generated by AVX512 / MRzefv\n"
@"//\n"
@"\n"
@"#ifndef MRzefvGenerated_h\n"
@"#define MRzefvGenerated_h\n"
@"\n"
@"#import <Foundation/Foundation.h>\n"
@"#import <UIKit/UIKit.h>\n"
@"\n"];
    [source appendFormat:
@"// Session: %@\n"
@"\n",
        [self objcString:sessionID]];
    [source appendString:
@"FOUNDATION_EXPORT NSString * const MRzefvGeneratedSessionID;\n"
@"FOUNDATION_EXPORT NSString * const MRzefvGeneratedGenerator;\n"
@"FOUNDATION_EXPORT NSString * const MRzefvGeneratedTarget;\n"
@"\n"
@"FOUNDATION_EXPORT void MRzefvGeneratedInitialize(void);\n"
@"FOUNDATION_EXPORT NSString *MRzefvGeneratedBuildID(void);\n"
@"\n"
@"#endif\n"];
    return source;
}
#pragma mark - Objective-C Source
+ (NSString *)implementationSourceForTarget:(NSString *)target
                                  sessionID:(NSString *)sessionID
                                  className:(NSString *)className
                                 operations:(NSArray *)operations
{
    NSMutableString *source =
        [NSMutableString string];
    /*
     * Keep the generated source deliberately simple.
     *
     * The important rule here is that every Objective-C fragment
     * is appended as a complete NSString literal. This avoids
     * malformed nested string expressions in the generated source.
     */
    [source appendString:
@"//\n"
@"// MRzefvGenerated.m\n"
@"// Generated by AVX512 / MRzefv\n"
@"//\n"
@"\n"
@"#import \"MRzefvGenerated.h\"\n"
@"#import <objc/runtime.h>\n"
@"\n"];
    [source appendFormat:
@"NSString * const MRzefvGeneratedSessionID = @\"%@\";\n",
        [self objcString:sessionID]];
    [source appendString:
@"NSString * const MRzefvGeneratedGenerator = @\"AVX512/MRzefv\";\n"
@"NSString * const MRzefvGeneratedTarget = @\"MRzefvGenerated\";\n"
@"\n"
@"static BOOL MRzefvGeneratedDidInitialize = NO;\n"
@"\n"
@"/* Forward declaration required because MRzefvFindTargetView()\n"
@" * calls MRzefvFindViewInTree() before its implementation. */\n"
@"static UIView *MRzefvFindViewInTree(UIView *root, Class targetClass);\n"
@"\n"];
    /*
     * Target lookup.
     */
    [source appendString:
@"static UIView *MRzefvFindTargetView(void)\n"
@"{\n"
@"    Class targetClass = NSClassFromString(@\""];
    [source appendString:
        [self objcString:className]];
    [source appendString:
@"\");\n"
@"    if (!targetClass) {\n"
@"        return nil;\n"
@"    }\n"
@"\n"
@"    NSArray *windows = UIApplication.sharedApplication.windows;\n"
@"\n"
@"    for (UIWindow *window in windows) {\n"
@"        UIView *found = MRzefvFindViewInTree(window, targetClass);\n"
@"        if (found) {\n"
@"            return found;\n"
@"        }\n"
@"    }\n"
@"\n"
@"    return nil;\n"
@"}\n"
@"\n"
@"static UIView *MRzefvFindViewInTree(UIView *root, Class targetClass)\n"
@"{\n"
@"    if (!root) {\n"
@"        return nil;\n"
@"    }\n"
@"\n"
@"    if ([root isKindOfClass:targetClass]) {\n"
@"        return root;\n"
@"    }\n"
@"\n"
@"    for (UIView *child in root.subviews) {\n"
@"        UIView *found = MRzefvFindViewInTree(child, targetClass);\n"
@"        if (found) {\n"
@"            return found;\n"
@"        }\n"
@"    }\n"
@"\n"
@"    return nil;\n"
@"}\n"
@"\n"];
    /*
     * Generate recorded mutations.
     */
    [source appendString:
@"static void MRzefvApplyOperations(UIView *view)\n"
@"{\n"
@"    if (!view) {\n"
@"        return;\n"
@"    }\n"
@"\n"];
    for (id operation in operations) {
        NSInteger type =
            [operation[@"type"] integerValue];
        NSDictionary *values =
            operation[@"values"];
        if (![values isKindOfClass:[NSDictionary class]]) {
            values = @{};
        }
        switch (type) {
            case AVX512GeneratedOperationMove: {
                CGFloat x =
                    [values[@"x"] doubleValue];
                CGFloat y =
                    [values[@"y"] doubleValue];
                [source appendFormat:
@"    {\n"
@"        CGRect frame = view.frame;\n"
@"        frame.origin = CGPointMake(%g, %g);\n"
@"        view.frame = frame;\n"
@"    }\n",
                    x,
                    y];
                break;
            }
            case AVX512GeneratedOperationResize: {
                CGFloat width =
                    [values[@"width"] doubleValue];
                CGFloat height =
                    [values[@"height"] doubleValue];
                [source appendFormat:
@"    {\n"
@"        CGRect bounds = view.bounds;\n"
@"        bounds.size = CGSizeMake(%g, %g);\n"
@"        view.bounds = bounds;\n"
@"    }\n",
                    width,
                    height];
                break;
            }
            case AVX512GeneratedOperationSetHidden: {
                BOOL hidden =
                    [values[@"hidden"] boolValue];
                [source appendFormat:
@"    view.hidden = %@;\n",
                    hidden ? @"YES" : @"NO"];
                break;
            }
            case AVX512GeneratedOperationReplaceText: {
                NSString *text =
                    values[@"text"];
                if (![text isKindOfClass:[NSString class]]) {
                    text = @"";
                }
                [source appendFormat:
@"    if ([view respondsToSelector:@selector(setText:)]) {\n"
@"        [(id)view setText:@\"%@\"];\n"
@"    }\n",
                    [self objcString:text]];
                break;
            }
            case AVX512GeneratedOperationAddText: {
                NSString *text =
                    values[@"text"];
                if (![text isKindOfClass:[NSString class]]) {
                    text = @"";
                }
                [source appendFormat:
@"    {\n"
@"        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 40)];\n"
@"        label.text = @\"%@\";\n"
@"        [view addSubview:label];\n"
@"    }\n",
                    [self objcString:text]];
                break;
            }
            case AVX512GeneratedOperationReplaceImage: {
                NSString *resource =
                    values[@"resource"];
                if (![resource isKindOfClass:[NSString class]]) {
                    resource = @"";
                }
                [source appendFormat:
@"    {\n"
@"        UIImage *image = [UIImage imageNamed:@\"%@\"];\n"
@"        if ([view respondsToSelector:@selector(setImage:)]) {\n"
@"            [(id)view setImage:image];\n"
@"        }\n"
@"    }\n",
                    [self objcString:resource]];
                break;
            }
            default:
                break;
        }
    }
    [source appendString:
@"}\n"
@"\n"
@"void MRzefvGeneratedInitialize(void)\n"
@"{\n"
@"    if (MRzefvGeneratedDidInitialize) {\n"
@"        return;\n"
@"    }\n"
@"\n"
@"    MRzefvGeneratedDidInitialize = YES;\n"
@"\n"
@"    dispatch_async(dispatch_get_main_queue(), ^{\n"
@"        UIView *target = MRzefvFindTargetView();\n"
@"        MRzefvApplyOperations(target);\n"
@"    });\n"
@"}\n"
@"\n"
@"NSString *MRzefvGeneratedBuildID(void)\n"
@"{\n"
@"    return MRzefvGeneratedSessionID;\n"
@"}\n"
@"\n"
@"__attribute__((constructor))\n"
@"static void MRzefvGeneratedConstructor(void)\n"
@"{\n"
@"    @autoreleasepool {\n"
@"        MRzefvGeneratedInitialize();\n"
@"    }\n"
@"}\n"];
    return source;
}
#pragma mark - Manifest
+ (NSString *)manifestForTarget:(NSString *)target
                      sessionID:(NSString *)sessionID
                      className:(NSString *)className
                     operations:(NSArray *)operations
{
    NSMutableArray *manifestOperations =
        [NSMutableArray array];
    for (id operation in operations) {
        NSDictionary *values =
            operation[@"values"] ?: @{};
        NSDictionary *entry = @{
            @"type" :
                @([operation[@"type"] integerValue]),
            @"className" :
                operation[@"className"] ?: className,
            @"viewPath" :
                operation[@"viewPath"] ?: @"",
            @"values" :
                values
        };
        [manifestOperations addObject:entry];
    }
    NSDictionary *manifest = @{
        @"formatVersion" : @1,
        @"generator" : @{
            @"name" : @"AVX512",
            @"product" : @"MRzefv",
            @"version" : @"1.0.0"
        },
        @"build" : @{
            @"target" : target,
            @"sessionID" : sessionID,
            @"architecture" : @[
                @"arm64",
                @"arm64e"
            ]
        },
        @"target" : @{
            @"className" : className
        },
        @"operations" :
            manifestOperations,
        @"resources" :
            @[],
        @"integrity" : @{
            @"sourceHash" : @"__GENERATED_BY_BUILD__",
            @"manifestHash" : @"__GENERATED_BY_BUILD__"
        }
    };
    NSData *data =
        [NSJSONSerialization
            dataWithJSONObject:manifest
                       options:NSJSONWritingPrettyPrinted
                         error:nil];
    if (!data) {
        return @"{}";
    }
    return
        [[NSString alloc]
            initWithData:data
                encoding:NSUTF8StringEncoding];
}
#pragma mark - Build Script
+ (NSString *)buildScript
{
    /*
     * Self-contained Apple clang build.
     *
     * ldid is supplied by GitHub Actions.
     *
     * Session ID is supplied by the workflow from manifest.json.
     * Build ID is supplied separately by GitHub Actions.
     */
    return
@"#!/usr/bin/env bash\n"
@"set -euo pipefail\n"
@"\n"
@"ROOT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"\n"
@"cd \"$ROOT_DIR\"\n"
@"\n"
@"TARGET_NAME=\"${OUT_NAME:-MRzefvGenerated}\"\n"
@"MIN_IOS_VERSION=\"${MIN_IOS_VERSION:-15.0}\"\n"
@"BUILD_DIR=\"${BUILD_DIR:-build}\"\n"
@"PACKAGES_DIR=\"${PACKAGES_DIR:-packages}\"\n"
@"\n"
@"SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
@"CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n"
@"LDID=\"$(command -v ldid || true)\"\n"
@"\n"
@"if [[ -z \"$LDID\" ]]; then\n"
@"    echo \"ERROR: ldid is not installed\" >&2\n"
@"    exit 1\n"
@"fi\n"
@"\n"
@"if [[ -z \"${MRZEFV_SESSION_ID:-}\" ]]; then\n"
@"    echo \"ERROR: MRZEFV_SESSION_ID is not set\" >&2\n"
@"    exit 1\n"
@"fi\n"
@"\n"
@"rm -rf \"$BUILD_DIR\" \"$PACKAGES_DIR\"\n"
@"mkdir -p \"$BUILD_DIR/arm64\" \"$BUILD_DIR/arm64e\" \"$PACKAGES_DIR\"\n"
@"\n"
@"COMMON_CFLAGS=(\n"
@"    -fobjc-arc\n"
@"    -fblocks\n"
@"    -fmodules\n"
@"    -isysroot \"$SDK\"\n"
@"    -miphoneos-version-min=\"$MIN_IOS_VERSION\"\n"
@"    -ISources\n"
@"    -Wall\n"
@"    -Wextra\n"
@"    -Wno-deprecated-declarations\n"
@"    -Wno-nullability-completeness\n"
@")\n"
@"\n"
@"COMMON_LDFLAGS=(\n"
@"    -dynamiclib\n"
@"    -isysroot \"$SDK\"\n"
@"    -miphoneos-version-min=\"$MIN_IOS_VERSION\"\n"
@"    -install_name \"@rpath/${TARGET_NAME}.dylib\"\n"
@"    -Wl,-headerpad_max_install_names\n"
@"    -Wl,-search_paths_first\n"
@"    -framework Foundation\n"
@"    -framework UIKit\n"
@")\n"
@"\n"
@"echo \"========================================\"\n"
@"echo \" BUILDING MRzefv GENERATED DYLIB\"\n"
@"echo \"========================================\"\n"
@"echo \"Target:  $TARGET_NAME\"\n"
@"echo \"Session: $MRZEFV_SESSION_ID\"\n"
@"echo \"Build:   ${MRZEFV_BUILD_ID:-unknown}\"\n"
@"echo\n"
@"\n"
@"echo \"========================================\"\n"
@"echo \" BUILDING ARM64\"\n"
@"echo \"========================================\"\n"
@"\n"
@"\"$CLANG\" \"${COMMON_CFLAGS[@]}\" \\\n"
@"    -arch arm64 \\\n"
@"    -c \"Sources/${TARGET_NAME}.m\" \\\n"
@"    -o \"$BUILD_DIR/arm64/${TARGET_NAME}.o\"\n"
@"\n"
@"\"$CLANG\" \"${COMMON_LDFLAGS[@]}\" \\\n"
@"    -arch arm64 \\\n"
@"    \"$BUILD_DIR/arm64/${TARGET_NAME}.o\" \\\n"
@"    -o \"$BUILD_DIR/arm64/${TARGET_NAME}.dylib\"\n"
@"\n"
@"echo \"✓ arm64 complete\"\n"
@"\n"
@"echo \"========================================\"\n"
@"echo \" BUILDING ARM64E\"\n"
@"echo \"========================================\"\n"
@"\n"
@"\"$CLANG\" \"${COMMON_CFLAGS[@]}\" \\\n"
@"    -arch arm64e \\\n"
@"    -c \"Sources/${TARGET_NAME}.m\" \\\n"
@"    -o \"$BUILD_DIR/arm64e/${TARGET_NAME}.o\"\n"
@"\n"
@"\"$CLANG\" \"${COMMON_LDFLAGS[@]}\" \\\n"
@"    -arch arm64e \\\n"
@"    \"$BUILD_DIR/arm64e/${TARGET_NAME}.o\" \\\n"
@"    -o \"$BUILD_DIR/arm64e/${TARGET_NAME}.dylib\"\n"
@"\n"
@"echo \"✓ arm64e complete\"\n"
@"\n"
@"echo \"========================================\"\n"
@"echo \" CREATING UNIVERSAL DYLIB\"\n"
@"echo \"========================================\"\n"
@"\n"
@"lipo -create \\\n"
@"    \"$BUILD_DIR/arm64/${TARGET_NAME}.dylib\" \\\n"
@"    \"$BUILD_DIR/arm64e/${TARGET_NAME}.dylib\" \\\n"
@"    -output \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
@"\n"
@"echo \"✓ Universal dylib created\"\n"
@"\n"
@"echo \"========================================\"\n"
@"echo \" SIGNING\"\n"
@"echo \"========================================\"\n"
@"\n"
@"ldid -S \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
@"\n"
@"echo \"✓ ldid signature applied\"\n"
@"\n"
@"cat > \"$PACKAGES_DIR/build-info.json\" <<EOF\n"
@"{\n"
@"  \"target\": \"${TARGET_NAME}\",\n"
@"  \"generator\": \"AVX512/MRzefv\",\n"
@"  \"sessionID\": \"${MRZEFV_SESSION_ID}\",\n"
@"  \"buildID\": \"${MRZEFV_BUILD_ID:-unknown}\",\n"
@"  \"architectures\": [\n"
@"    \"arm64\",\n"
@"    \"arm64e\"\n"
@"  ],\n"
@"  \"minimumIOSVersion\": \"${MIN_IOS_VERSION}\",\n"
@"  \"sdk\": \"iphoneos\",\n"
@"  \"compiler\": \"Apple Clang\",\n"
@"  \"installName\": \"@rpath/${TARGET_NAME}.dylib\",\n"
@"  \"signing\": \"ldid\",\n"
@"  \"status\": \"built\"\n"
@"}\n"
@"EOF\n"
@"\n"
@"echo \"========================================\"\n"
@"echo \" PACKAGING\"\n"
@"echo \"========================================\"\n"
@"\n"
@"cd \"$PACKAGES_DIR\"\n"
@"\n"
@"zip -q \"${TARGET_NAME}.zip\" \\\n"
@"    \"${TARGET_NAME}.dylib\" \\\n"
@"    \"build-info.json\"\n"
@"\n"
@"cd \"$ROOT_DIR\"\n"
@"\n"
@"echo\n"
@"echo \"========================================\"\n"
@"echo \" BUILD COMPLETE\"\n"
@"echo \"========================================\"\n"
@"echo\n"
@"echo \"Dylib:\"\n"
@"ls -lh \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
@"echo\n"
@"echo \"ZIP:\"\n"
@"ls -lh \"$PACKAGES_DIR/${TARGET_NAME}.zip\"\n"
@"echo\n"
@"echo \"Architectures:\"\n"
@"lipo -info \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n";
}
#pragma mark - GitHub Workflow
+ (NSString *)workflow
{
    /*
     * The generated repository itself is the project root.
     *
     * No Makefile is required.
     *
     * GitHub run ID is NEVER used as the generation session ID.
     * The canonical session ID is read from manifest.json.
     */
    return
@"name: Build MRzefv Generated Dylib\n"
@"\n"
@"on:\n"
@"  workflow_dispatch:\n"
@"    inputs:\n"
@"      out_name:\n"
@"        description: Output dylib name\n"
@"        required: false\n"
@"        default: MRzefvGenerated\n"
@"  push:\n"
@"    branches:\n"
@"      - main\n"
@"\n"
@"permissions:\n"
@"  contents: read\n"
@"\n"
@"jobs:\n"
@"  build:\n"
@"    name: Build Generated Dylib\n"
@"    runs-on: macos-15\n"
@"\n"
@"    steps:\n"
@"      - name: Checkout generated project\n"
@"        uses: actions/checkout@v4\n"
@"\n"
@"      - name: Show Apple toolchain\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"APPLE TOOLCHAIN\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          xcodebuild -version\n"
@"\n"
@"          echo\n"
@"          echo \"iPhoneOS SDK:\"\n"
@"          xcrun --sdk iphoneos --show-sdk-path\n"
@"\n"
@"          echo\n"
@"          echo \"Clang:\"\n"
@"          xcrun --sdk iphoneos -f clang\n"
@"\n"
@"      - name: Install ldid\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"INSTALLING LDID\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          if command -v ldid >/dev/null 2>&1; then\n"
@"            echo \"ldid already installed\"\n"
@"          else\n"
@"            brew update\n"
@"            brew install ldid\n"
@"          fi\n"
@"\n"
@"          echo\n"
@"          echo \"ldid:\"\n"
@"          command -v ldid\n"
@"          ldid --version || true\n"
@"\n"
@"      - name: Validate generated project\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"VALIDATING GENERATED PROJECT\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          echo\n"
@"          echo \"Repository root:\"\n"
@"          pwd\n"
@"\n"
@"          required_files=(\n"
@"            \"build.sh\"\n"
@"            \"manifest.json\"\n"
@"            \"Sources/MRzefvGenerated.h\"\n"
@"            \"Sources/MRzefvGenerated.m\"\n"
@"          )\n"
@"\n"
@"          echo\n"
@"          echo \"Required files:\"\n"
@"\n"
@"          for file in \"${required_files[@]}\"; do\n"
@"            if [[ ! -f \"$file\" ]]; then\n"
@"              echo \"::error::Missing required file: $file\"\n"
@"              echo\n"
@"              echo \"Repository contents:\"\n"
@"              find . -maxdepth 4 -type f -print | sort\n"
@"              exit 1\n"
@"            fi\n"
@"\n"
@"            echo \"✓ $file\"\n"
@"          done\n"
@"\n"
@"          if [[ -f \"Makefile\" ]]; then\n"
@"            echo \"• Makefile present but not required\"\n"
@"          else\n"
@"            echo \"• Makefile not required\"\n"
@"          fi\n"
@"\n"
@"          if [[ -d \"Resources\" ]]; then\n"
@"            echo \"✓ Resources/\"\n"
@"          else\n"
@"            echo \"• Resources/ not present\"\n"
@"          fi\n"
@"\n"
@"          echo\n"
@"          echo \"✓ Generated project validation passed\"\n"
@"\n"
@"      - name: Read generated session ID\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"GENERATED SESSION\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          SESSION_ID=\"$(\n"
@"            plutil \\\n"
@"              -extract build.sessionID \\\n"
@"              raw \\\n"
@"              -o - \\\n"
@"              manifest.json\n"
@"          )\"\n"
@"\n"
@"          if [[ -z \"$SESSION_ID\" || \"$SESSION_ID\" == \"null\" ]]; then\n"
@"            echo \"::error::manifest.json does not contain build.sessionID\"\n"
@"            exit 1\n"
@"          fi\n"
@"\n"
@"          echo \"Session ID:\"\n"
@"          echo \"$SESSION_ID\"\n"
@"\n"
@"          echo \"MRZEFV_SESSION_ID=$SESSION_ID\" >> \"$GITHUB_ENV\"\n"
@"\n"
@"      - name: Verify session metadata\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"VERIFYING SESSION METADATA\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          MANIFEST_SESSION=\"$(\n"
@"            plutil \\\n"
@"              -extract build.sessionID \\\n"
@"              raw \\\n"
@"              -o - \\\n"
@"              manifest.json\n"
@"          )\"\n"
@"\n"
@"          if [[ -f \"generation-receipt.json\" ]]; then\n"
@"\n"
@"            RECEIPT_SESSION=\"$(\n"
@"              plutil \\\n"
@"                -extract sessionID \\\n"
@"                raw \\\n"
@"                -o - \\\n"
@"                generation-receipt.json\n"
@"            )\"\n"
@"\n"
@"            echo \"Manifest session: $MANIFEST_SESSION\"\n"
@"            echo \"Receipt session:  $RECEIPT_SESSION\"\n"
@"\n"
@"            if [[ \"$MANIFEST_SESSION\" != \"$RECEIPT_SESSION\" ]]; then\n"
@"              echo \"::error::Session ID mismatch between manifest.json and generation-receipt.json\"\n"
@"              exit 1\n"
@"            fi\n"
@"\n"
@"            echo \"✓ Session IDs match\"\n"
@"          else\n"
@"            echo \"• generation-receipt.json not present\"\n"
@"          fi\n"
@"\n"
@"      - name: Set build identity\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          BUILD_ID=\"MRZ-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}\"\n"
@"\n"
@"          echo \"MRZEFV_BUILD_ID=${BUILD_ID}\" >> \"$GITHUB_ENV\"\n"
@"\n"
@"          echo \"Build ID:\"\n"
@"          echo \"$BUILD_ID\"\n"
@"\n"
@"      - name: Build generated dylib\n"
@"        shell: bash\n"
@"        env:\n"
@"          OUT_NAME: ${{ github.event.inputs.out_name || 'MRzefvGenerated' }}\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"MRzefv GENERATED BUILD\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          echo \"Target:\"\n"
@"          echo \"${OUT_NAME}\"\n"
@"\n"
@"          echo\n"
@"          echo \"Session:\"\n"
@"          echo \"${MRZEFV_SESSION_ID}\"\n"
@"\n"
@"          echo\n"
@"          echo \"Build:\"\n"
@"          echo \"${MRZEFV_BUILD_ID}\"\n"
@"\n"
@"          echo\n"
@"          chmod +x build.sh\n"
@"          ./build.sh\n"
@"\n"
@"      - name: Verify build output\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"BUILD OUTPUT\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          if [[ ! -d \"packages\" ]]; then\n"
@"            echo \"::error::packages/ directory was not produced\"\n"
@"            exit 1\n"
@"          fi\n"
@"\n"
@"          find packages \\\n"
@"            -maxdepth 1 \\\n"
@"            -type f \\\n"
@"            -print \\\n"
@"            -exec ls -lh {} \\;\n"
@"\n"
@"          DYLIB=\"$(\n"
@"            find packages \\\n"
@"              -maxdepth 1 \\\n"
@"              -name \"*.dylib\" \\\n"
@"              -type f \\\n"
@"              | head -n 1\n"
@"          )\"\n"
@"\n"
@"          ZIP=\"$(\n"
@"            find packages \\\n"
@"              -maxdepth 1 \\\n"
@"              -name \"*.zip\" \\\n"
@"              -type f \\\n"
@"              | head -n 1\n"
@"          )\"\n"
@"\n"
@"          if [[ -z \"$DYLIB\" ]]; then\n"
@"            echo \"::error::No dylib produced\"\n"
@"            exit 1\n"
@"          fi\n"
@"\n"
@"          if [[ -z \"$ZIP\" ]]; then\n"
@"            echo \"::error::No ZIP package produced\"\n"
@"            exit 1\n"
@"          fi\n"
@"\n"
@"          echo\n"
@"          echo \"✓ Dylib:\"\n"
@"          echo \"$DYLIB\"\n"
@"\n"
@"          echo\n"
@"          echo \"✓ ZIP:\"\n"
@"          echo \"$ZIP\"\n"
@"\n"
@"      - name: Verify dylib\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          DYLIB=\"$(\n"
@"            find packages \\\n"
@"              -maxdepth 1 \\\n"
@"              -name \"*.dylib\" \\\n"
@"              -type f \\\n"
@"              | head -n 1\n"
@"          )\"\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"VERIFYING DYLIB\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          echo\n"
@"          echo \"File:\"\n"
@"          file \"$DYLIB\"\n"
@"\n"
@"          echo\n"
@"          echo \"Architectures:\"\n"
@"          lipo -info \"$DYLIB\"\n"
@"\n"
@"          echo\n"
@"          echo \"Linked libraries:\"\n"
@"          otool -L \"$DYLIB\" || true\n"
@"\n"
@"      - name: Verify build metadata\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"\n"
@"          BUILD_INFO=\"packages/build-info.json\"\n"
@"\n"
@"          if [[ ! -f \"$BUILD_INFO\" ]]; then\n"
@"            echo \"::error::Missing packages/build-info.json\"\n"
@"            exit 1\n"
@"          fi\n"
@"\n"
@"          echo \"========================================\"\n"
@"          echo \"BUILD METADATA\"\n"
@"          echo \"========================================\"\n"
@"\n"
@"          cat \"$BUILD_INFO\"\n"
@"\n"
@"          BUILD_SESSION=\"$(\n"
@"            plutil \\\n"
@"              -extract sessionID \\\n"
@"              raw \\\n"
@"              -o - \\\n"
@"              \"$BUILD_INFO\"\n"
@"          )\"\n"
@"\n"
@"          if [[ \"$BUILD_SESSION\" != \"$MRZEFV_SESSION_ID\" ]]; then\n"
@"            echo \"::error::Session ID mismatch in build-info.json\"\n"
@"            echo \"Expected: $MRZEFV_SESSION_ID\"\n"
@"            echo \"Found:    $BUILD_SESSION\"\n"
@"            exit 1\n"
@"          fi\n"
@"\n"
@"          echo\n"
@"          echo \"✓ build-info.json session ID matches manifest.json\"\n"
@"\n"
@"      - name: Upload dylib\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: MRzefvGenerated-dylib-${{ github.run_number }}\n"
@"          path: packages/*.dylib\n"
@"          if-no-files-found: error\n"
@"          retention-days: 30\n"
@"\n"
@"      - name: Upload generated ZIP\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: MRzefvGenerated-package-${{ github.run_number }}\n"
@"          path: packages/*.zip\n"
@"          if-no-files-found: error\n"
@"          retention-days: 30\n"
@"\n"
@"      - name: Upload build metadata\n"
@"        if: always()\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: MRzefvGenerated-metadata-${{ github.run_number }}\n"
@"          path: |\n"
@"            manifest.json\n"
@"            generation-receipt.json\n"
@"            packages/build-info.json\n"
@"          if-no-files-found: ignore\n"
@"          retention-days: 30\n";
    return workflow;
}
#pragma mark - File Writing
+ (BOOL)writeString:(NSString *)string
              toURL:(NSURL *)url
              error:(NSError **)error
{
    return [string
        writeToURL:url
        atomically:YES
          encoding:NSUTF8StringEncoding
             error:error];
}
#pragma mark - Session ID
+ (NSString *)sessionIdentifier
{
    /*
     * This method is called exactly once from
     * generateProjectWithTargetView:operations:error:.
     *
     * Do NOT call this again while generating individual files.
     */
    return
        [NSUUID UUID].UUIDString.lowercaseString;
}
#pragma mark - Objective-C Escaping
+ (NSString *)objcString:(NSString *)value
{
    if (!value) {
        return @"";
    }
    NSString *escaped =
        [value stringByReplacingOccurrencesOfString:@"\\"
                                         withString:@"\\\\"];
    escaped =
        [escaped stringByReplacingOccurrencesOfString:@"\""
                                           withString:@"\\\""];
    escaped =
        [escaped stringByReplacingOccurrencesOfString:@"\n"
                                           withString:@"\\n"];
    escaped =
        [escaped stringByReplacingOccurrencesOfString:@"\r"
                                           withString:@"\\r"];
    return escaped;
}
#pragma mark - Errors
+ (id)fail:(NSError **)error
       code:(NSInteger)code
     reason:(NSString *)reason
{
    if (error) {
        *error =
            [NSError
                errorWithDomain:@"AVX512GeneratedProject"
                           code:code
                       userInfo:@{
            NSLocalizedDescriptionKey : reason
        }];
    }
    return nil;
}
@end