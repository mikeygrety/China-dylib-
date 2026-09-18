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
    NSString *className =
        NSStringFromClass(
            object_getClass(targetView));
    if (className.length == 0) {
        className = @"UIView";
    }
    NSString *header =
        [self headerSourceForTarget:targetName];
    NSString *implementation =
        [self implementationSourceForTarget:targetName
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
     * Write a small generation receipt.
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
{
    return
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
@"\n"
@"FOUNDATION_EXPORT NSString * const MRzefvGeneratedSessionID;\n"
@"FOUNDATION_EXPORT NSString * const MRzefvGeneratedGenerator;\n"
@"FOUNDATION_EXPORT NSString * const MRzefvGeneratedTarget;\n"
@"\n"
@"FOUNDATION_EXPORT void MRzefvGeneratedInitialize(void);\n"
@"FOUNDATION_EXPORT NSString *MRzefvGeneratedBuildID(void);\n"
@"\n"
@"#endif\n";
}
#pragma mark - Objective-C Source
+ (NSString *)implementationSourceForTarget:(NSString *)target
                                  className:(NSString *)className
                                  operations:(NSArray *)operations
{
    NSMutableString *source =
        [NSMutableString string];
    [source appendString:
@"//\n"
@"// MRzefvGenerated.m\n"
@"// Generated by AVX512 / MRzefv\n"
@"//\n"
@"\n"
@"#import \"MRzefvGenerated.h\"\n"
@"#import <objc/runtime.h>\n"
@"\n"];
    NSString *sessionID =
        [self sessionIdentifier];
    [source appendFormat:
@"NSString * const MRzefvGeneratedSessionID = @\"%@\";\n",
        [self objcString:sessionID]];
    [source appendString:
@"NSString * const MRzefvGeneratedGenerator = @\"AVX512/MRzefv\";\n"
@"NSString * const MRzefvGeneratedTarget = @\"MRzefvGenerated\";\n"
@"\n"
@"static BOOL MRzefvGeneratedDidInitialize = NO;\n"
@"\n"];
    /*
     * The generated runtime resolves the class dynamically.
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
     * Generate the actual recorded mutations.
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
                /*
                 * Resource-backed image replacement is represented
                 * by a generated resource name. The image importer
                 * will place the actual file into Resources/.
                 */
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
@"}\n";
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
     * Keep the generated project self-contained.
     * The workflow installs ldid before invoking this script.
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
@")\n"
@"\n"
@"COMMON_LDFLAGS=(\n"
@"    -dynamiclib\n"
@"    -isysroot \"$SDK\"\n"
@"    -miphoneos-version-min=\"$MIN_IOS_VERSION\"\n"
@"    -install_name \"@rpath/${TARGET_NAME}.dylib\"\n"
@"    -Wl,-headerpad_max_install_names\n"
@"    -framework Foundation\n"
@"    -framework UIKit\n"
@")\n"
@"\n"
@"for ARCH in arm64 arm64e; do\n"
@"    \"$CLANG\" \"${COMMON_CFLAGS[@]}\" -arch \"$ARCH\" \\\n"
@"        -c \"Sources/${TARGET_NAME}.m\" \\\n"
@"        -o \"$BUILD_DIR/$ARCH/${TARGET_NAME}.o\"\n"
@"\n"
@"    \"$CLANG\" \"${COMMON_LDFLAGS[@]}\" -arch \"$ARCH\" \\\n"
@"        \"$BUILD_DIR/$ARCH/${TARGET_NAME}.o\" \\\n"
@"        -o \"$BUILD_DIR/$ARCH/${TARGET_NAME}.dylib\"\n"
@"done\n"
@"\n"
@"lipo -create \\\n"
@"    \"$BUILD_DIR/arm64/${TARGET_NAME}.dylib\" \\\n"
@"    \"$BUILD_DIR/arm64e/${TARGET_NAME}.dylib\" \\\n"
@"    -output \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
@"\n"
@"ldid -S \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
@"\n"
@"cat > \"$PACKAGES_DIR/build-info.json\" <<EOF\n"
@"{\n"
@"  \"target\": \"${TARGET_NAME}\",\n"
@"  \"generator\": \"AVX512/MRzefv\",\n"
@"  \"sessionID\": \"${MRZEFV_SESSION_ID:-unknown}\",\n"
@"  \"buildID\": \"${MRZEFV_BUILD_ID:-unknown}\",\n"
@"  \"architectures\": [\"arm64\", \"arm64e\"],\n"
@"  \"minimumIOSVersion\": \"${MIN_IOS_VERSION}\",\n"
@"  \"signing\": \"ldid\"\n"
@"}\n"
@"EOF\n"
@"\n"
@"cd \"$PACKAGES_DIR\"\n"
@"zip -q \"${TARGET_NAME}.zip\" \\\n"
@"    \"${TARGET_NAME}.dylib\" \\\n"
@"    \"build-info.json\"\n"
@"\n"
@"echo \"Build complete: $ROOT_DIR/$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n";
}
#pragma mark - GitHub Workflow
+ (NSString *)workflow
{
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
@"    runs-on: macos-15\n"
@"\n"
@"    steps:\n"
@"      - name: Checkout generated project\n"
@"        uses: actions/checkout@v4\n"
@"\n"
@"      - name: Install ldid\n"
@"        shell: bash\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"          if command -v ldid >/dev/null 2>&1; then\n"
@"            echo \"ldid already installed\"\n"
@"          else\n"
@"            brew update\n"
@"            brew install ldid\n"
@"          fi\n"
@"          command -v ldid\n"
@"          ldid --version || true\n"
@"\n"
@"      - name: Show Apple toolchain\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"          xcodebuild -version\n"
@"          xcrun --sdk iphoneos --show-sdk-path\n"
@"          xcrun --sdk iphoneos -f clang\n"
@"\n"
@"      - name: Build generated dylib\n"
@"        env:\n"
@"          OUT_NAME: ${{ github.event.inputs.out_name || 'MRzefvGenerated' }}\n"
@"          MRZEFV_SESSION_ID: ${{ github.run_id }}\n"
@"          MRZEFV_BUILD_ID: MRZ-${{ github.run_id }}-${{ github.run_attempt }}\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"          chmod +x build.sh\n"
@"          ./build.sh\n"
@"\n"
@"      - name: Verify dylib\n"
@"        run: |\n"
@"          set -euo pipefail\n"
@"          test -f packages/*.dylib\n"
@"          file packages/*.dylib\n"
@"          lipo -info packages/*.dylib\n"
@"          otool -L packages/*.dylib || true\n"
@"\n"
@"      - name: Upload dylib\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: MRzefvGenerated-dylib-${{ github.run_number }}\n"
@"          path: packages/*.dylib\n"
@"          if-no-files-found: error\n"
@"          retention-days: 30\n"
@"\n"
@"      - name: Upload package\n"
@"        uses: actions/upload-artifact@v4\n"
@"        with:\n"
@"          name: MRzefvGenerated-package-${{ github.run_number }}\n"
@"          path: packages/*.zip\n"
@"          if-no-files-found: error\n"
@"          retention-days: 30\n";
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