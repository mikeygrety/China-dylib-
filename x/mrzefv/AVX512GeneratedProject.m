//
//  AVX512GeneratedProject.m
//  AVX512
//
//  AVX512 / MRzefv generated Objective-C dylib project builder.
//
#import "AVX512GeneratedProject.h"
#import <UIKit/UIKit.h>
static NSString * const AVX512GeneratedProjectErrorDomain =
    @"com.delvek.avx512.generated-project";
#pragma mark - Helpers
static NSString *AVX512UUID(void)
{
    return [[NSUUID UUID].UUIDString lowercaseString];
}
static NSString *AVX512JSONObjectString(id object)
{
    if (!object) {
        return @"null";
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                   options:0
                                                     error:&error];
    if (!data || error) {
        return @"null";
    }
    NSString *result = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];
    return result ?: @"null";
}
static NSString *AVX512ObjCString(NSString *value)
{
    if (!value) {
        return @"";
    }
    NSMutableString *result = [NSMutableString stringWithString:value];
    [result replaceOccurrencesOfString:@"\\"
                            withString:@"\\\\"
                               options:0
                                 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\""
                            withString:@"\\\""
                               options:0
                                 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\n"
                            withString:@"\\n"
                               options:0
                                 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\r"
                            withString:@"\\r"
                               options:0
                                 range:NSMakeRange(0, result.length)];
    return result;
}
static void AVX512AppendLine(NSMutableString *string, NSString *line)
{
    [string appendString:line ?: @""];
    [string appendString:@"\n"];
}
static NSError *AVX512Error(NSString *description)
{
    return [NSError errorWithDomain:AVX512GeneratedProjectErrorDomain
                               code:1
                           userInfo:@{
                               NSLocalizedDescriptionKey : description
                           }];
}
static BOOL AVX512WriteString(NSString *string,
                              NSURL *url,
                              NSError **error)
{
    return [string writeToURL:url
                    atomically:YES
                      encoding:NSUTF8StringEncoding
                         error:error];
}
static BOOL AVX512WriteData(NSData *data,
                            NSURL *url,
                            NSError **error)
{
    return [data writeToURL:url
                    options:NSDataWritingAtomic
                      error:error];
}
#pragma mark - Operation
@implementation AVX512GeneratedOperation
+ (instancetype)operationWithType:(AVX512GeneratedOperationType)type
                         className:(NSString *)className
                          viewPath:(NSString *)viewPath
                            values:(NSDictionary<NSString *,id> *)values
{
    AVX512GeneratedOperation *operation =
        [[self alloc] init];
    operation.type = type;
    operation.className = className;
    operation.viewPath = viewPath;
    operation.values = values ?: @{};
    return operation;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _values = @{};
    }
    return self;
}
@end
#pragma mark - Operation Normalization
static NSDictionary *AVX512OperationDictionary(id operation)
{
    if ([operation isKindOfClass:NSDictionary.class]) {
        return operation;
    }
    if ([operation isKindOfClass:AVX512GeneratedOperation.class]) {
        AVX512GeneratedOperation *op =
            (AVX512GeneratedOperation *)operation;
        NSMutableDictionary *dictionary =
            [NSMutableDictionary dictionary];
        dictionary[@"type"] = @(op.type);
        if (op.className) {
            dictionary[@"className"] = op.className;
        }
        if (op.viewPath) {
            dictionary[@"viewPath"] = op.viewPath;
        }
        if (op.values) {
            dictionary[@"values"] = op.values;
        }
        return dictionary;
    }
    return nil;
}
static NSInteger AVX512OperationTypeFromObject(id value)
{
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    if ([value isKindOfClass:NSString.class]) {
        NSString *name = [(NSString *)value lowercaseString];
        if ([name isEqualToString:@"move"]) {
            return AVX512GeneratedOperationTypeMove;
        }
        if ([name isEqualToString:@"resize"]) {
            return AVX512GeneratedOperationTypeResize;
        }
        if ([name isEqualToString:@"hide"]) {
            return AVX512GeneratedOperationTypeHide;
        }
        if ([name isEqualToString:@"show"]) {
            return AVX512GeneratedOperationTypeShow;
        }
        if ([name isEqualToString:@"replacetext"]) {
            return AVX512GeneratedOperationTypeReplaceText;
        }
        if ([name isEqualToString:@"addtext"]) {
            return AVX512GeneratedOperationTypeAddText;
        }
        if ([name isEqualToString:@"replaceimage"]) {
            return AVX512GeneratedOperationTypeReplaceImage;
        }
    }
    return -1;
}
#pragma mark - Generated Header
static NSString *AVX512GeneratedHeader(NSString *sessionID)
{
    NSMutableString *output =
        [NSMutableString string];
    AVX512AppendLine(output, @"//");
    AVX512AppendLine(output, @"// MRzefvGenerated.h");
    AVX512AppendLine(output, @"// Generated by AVX512.");
    AVX512AppendLine(output, @"//");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"#import <Foundation/Foundation.h>");
    AVX512AppendLine(output, @"#import <UIKit/UIKit.h>");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"NS_ASSUME_NONNULL_BEGIN");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"FOUNDATION_EXPORT NSString *MRzefvGeneratedSessionID(void);");
    AVX512AppendLine(output, @"FOUNDATION_EXPORT void MRzefvGeneratedInitialize(void);");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"NS_ASSUME_NONNULL_END");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output,
                     [NSString stringWithFormat:
                      @"// Generation session: %@",
                      sessionID]);
    return output;
}
#pragma mark - Generated Source
static NSString *AVX512GeneratedSource(NSString *sessionID,
                                       NSString *targetClassName,
                                       NSArray *operations)
{
    NSMutableString *output =
        [NSMutableString string];
    AVX512AppendLine(output, @"//");
    AVX512AppendLine(output, @"// MRzefvGenerated.m");
    AVX512AppendLine(output, @"// Generated by AVX512.");
    AVX512AppendLine(output, @"//");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"#import \"MRzefvGenerated.h\"");
    AVX512AppendLine(output, @"#import <objc/runtime.h>");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"static UIView *MRzefvFindViewInTree(UIView *root, Class targetClass);");
    AVX512AppendLine(output, @"");
    
    AVX512AppendLine(output, @"NSString *MRzefvGeneratedSessionID(void)");
    AVX512AppendLine(output, @"{");
    AVX512AppendLine(output,
                     [NSString stringWithFormat:
                      @"    return @\"%@\";",
                      AVX512ObjCString(sessionID)]);
    AVX512AppendLine(output, @"}");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"static UIView *MRzefvFindViewInTree(UIView *root, Class targetClass)");
    AVX512AppendLine(output, @"{");
    AVX512AppendLine(output, @"    if (!root || !targetClass) {");
    AVX512AppendLine(output, @"        return nil;");
    AVX512AppendLine(output, @"    }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"    if ([root isKindOfClass:targetClass]) {");
    AVX512AppendLine(output, @"        return root;");
    AVX512AppendLine(output, @"    }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"    for (UIView *subview in root.subviews) {");
    AVX512AppendLine(output, @"        UIView *found = MRzefvFindViewInTree(subview, targetClass);");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"        if (found) {");
    AVX512AppendLine(output, @"            return found;");
    AVX512AppendLine(output, @"        }");
    AVX512AppendLine(output, @"    }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"    return nil;");
    AVX512AppendLine(output, @"}");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"static UIView *MRzefvFindTargetView(void)");
    AVX512AppendLine(output, @"{");
    AVX512AppendLine(output,
                     [NSString stringWithFormat:
                      @"    Class targetClass = NSClassFromString(@\"%@\");",
                      AVX512ObjCString(targetClassName)]);
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"    if (!targetClass) {");
    AVX512AppendLine(output, @"        return nil;");
    AVX512AppendLine(output, @"    }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {");
    AVX512AppendLine(output, @"        if (![scene isKindOfClass:UIWindowScene.class]) {");
    AVX512AppendLine(output, @"            continue;");
    AVX512AppendLine(output, @"        }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"        UIWindowScene *windowScene = (UIWindowScene *)scene;");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"        for (UIWindow *window in windowScene.windows) {");
    AVX512AppendLine(output, @"            UIView *found = MRzefvFindViewInTree(window, targetClass);");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"            if (found) {");
    AVX512AppendLine(output, @"                return found;");
    AVX512AppendLine(output, @"            }");
    AVX512AppendLine(output, @"        }");
    AVX512AppendLine(output, @"    }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"    return nil;");
    AVX512AppendLine(output, @"}");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"static void MRzefvApplyOperations(UIView *target)");
    AVX512AppendLine(output, @"{");
    for (id rawOperation in operations) {
        NSDictionary *operation =
            AVX512OperationDictionary(rawOperation);
        if (!operation) {
            continue;
        }
        NSInteger type =
            AVX512OperationTypeFromObject(operation[@"type"]);
        NSDictionary *values =
            [operation[@"values"] isKindOfClass:NSDictionary.class]
                ? operation[@"values"]
                : @{};
        switch (type) {
            case AVX512GeneratedOperationTypeMove: {
                NSString *x = [values[@"x"] description];
                NSString *y = [values[@"y"] description];
                if (x && y) {
                    AVX512AppendLine(
                        output,
                        [NSString stringWithFormat:
                         @"    target.center = CGPointMake(%@, %@);",
                         x,
                         y]);
                }
                break;
            }
            case AVX512GeneratedOperationTypeResize: {
                NSString *width = [values[@"width"] description];
                NSString *height = [values[@"height"] description];
                if (width && height) {
                    AVX512AppendLine(
                        output,
                        [NSString stringWithFormat:
                         @"    target.frame = CGRectMake(target.frame.origin.x, target.frame.origin.y, %@, %@);",
                         width,
                         height]);
                }
                break;
            }
            case AVX512GeneratedOperationTypeHide:
                AVX512AppendLine(output,
                                 @"    target.hidden = YES;");
                break;
            case AVX512GeneratedOperationTypeShow:
                AVX512AppendLine(output,
                                 @"    target.hidden = NO;");
                break;
            case AVX512GeneratedOperationTypeReplaceText: {
                NSString *text =
                    [values[@"text"] isKindOfClass:NSString.class]
                        ? values[@"text"]
                        : [values[@"text"] description];
                if (text) {
                    AVX512AppendLine(
                        output,
                        [NSString stringWithFormat:
                         @"    if ([target respondsToSelector:@selector(setText:)]) {");
                    AVX512AppendLine(
                        output,
                        [NSString stringWithFormat:
                         @"        [(id)target setText:@\"%@\"];",
                         AVX512ObjCString(text)]);
                    AVX512AppendLine(
                        output,
                        @"    }");
                }
                break;
            }
            case AVX512GeneratedOperationTypeAddText: {
                NSString *text =
                    [values[@"text"] isKindOfClass:NSString.class]
                        ? values[@"text"]
                        : [values[@"text"] description];
                if (text) {
                    AVX512AppendLine(output, @"    UILabel *label = [[UILabel alloc] initWithFrame:target.bounds];");
                    AVX512AppendLine(output, @"    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;");
                    AVX512AppendLine(output,
                                     [NSString stringWithFormat:
                                      @"    label.text = @\"%@\";",
                                      AVX512ObjCString(text)]);
                    AVX512AppendLine(output, @"    label.textAlignment = NSTextAlignmentCenter;");
                    AVX512AppendLine(output, @"    label.userInteractionEnabled = NO;");
                    AVX512AppendLine(output, @"    [target addSubview:label];");
                }
                break;
            }
            case AVX512GeneratedOperationTypeReplaceImage: {
                NSString *imageName =
                    [values[@"imageName"] isKindOfClass:NSString.class]
                        ? values[@"imageName"]
                        : [values[@"imageName"] description];
                if (imageName) {
                    AVX512AppendLine(
                        output,
                        @"    if ([target isKindOfClass:UIImageView.class]) {");
                    AVX512AppendLine(
                        output,
                        [NSString stringWithFormat:
                         @"        ((UIImageView *)target).image = [UIImage imageNamed:@\"%@\"];",
                         AVX512ObjCString(imageName)]);
                    AVX512AppendLine(output, @"    }");
                }
                break;
            }
            default:
                break;
        }
    }
    AVX512AppendLine(output, @"}");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"void MRzefvGeneratedInitialize(void)");
    AVX512AppendLine(output, @"{");
    AVX512AppendLine(output, @"    dispatch_async(dispatch_get_main_queue(), ^{");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"        for (NSInteger attempt = 0; attempt < 20; attempt++) {");
    AVX512AppendLine(output, @"            UIView *target = MRzefvFindTargetView();");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"            if (target) {");
    AVX512AppendLine(output, @"                MRzefvApplyOperations(target);");
    AVX512AppendLine(output, @"                return;");
    AVX512AppendLine(output, @"            }");
    AVX512AppendLine(output, @"");
    AVX512AppendLine(output, @"            [NSThread sleepForTimeInterval:0.25];");
    AVX512AppendLine(output, @"        }");
    AVX512AppendLine(output, @"    });");
    AVX512AppendLine(output, @"}");
    AVX512AppendLine(output, @"");
    __unused NSString *unusedTargetClassName = targetClassName;
    return output;
}
#pragma mark - Manifest
static NSDictionary *AVX512Manifest(NSString *sessionID,
                                    NSString *targetClassName,
                                    NSArray *operations)
{
    NSMutableArray *serializedOperations =
        [NSMutableArray array];
    for (id rawOperation in operations) {
        NSDictionary *operation =
            AVX512OperationDictionary(rawOperation);
        if (!operation) {
            continue;
        }
        NSMutableDictionary *copy =
            [operation mutableCopy];
        id values = copy[@"values"];
        if (!values) {
            copy[@"values"] = @{};
        }
        [serializedOperations addObject:copy];
    }
    return @{
        @"schemaVersion" : @1,
        @"generator" : @"AVX512/MRzefv",
        @"build" : @{
            @"sessionID" : sessionID,
            @"target" : @"MRzefvGenerated"
        },
        @"target" : @{
            @"className" : targetClassName ?: @"",
            @"operationCount" : @(serializedOperations.count)
        },
        @"operations" : serializedOperations
    };
}
#pragma mark - Build Script
static NSString *AVX512BuildScript(void)
{
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
    @"SOURCE_DIR=\"${ROOT_DIR}/Sources\"\n"
    @"SOURCE_FILE=\"${SOURCE_DIR}/${TARGET_NAME}.m\"\n"
    @"HEADER_FILE=\"${SOURCE_DIR}/${TARGET_NAME}.h\"\n"
    @"\n"
    @"fail() {\n"
    @"    echo \"ERROR: $*\" >&2\n"
    @"    exit 1\n"
    @"}\n"
    @"\n"
    @"command -v xcrun >/dev/null 2>&1 || fail \"xcrun not found\"\n"
    @"command -v lipo >/dev/null 2>&1 || fail \"lipo not found\"\n"
    @"command -v otool >/dev/null 2>&1 || fail \"otool not found\"\n"
    @"command -v file >/dev/null 2>&1 || fail \"file not found\"\n"
    @"command -v zip >/dev/null 2>&1 || fail \"zip not found\"\n"
    @"command -v ldid >/dev/null 2>&1 || fail \"ldid not installed\"\n"
    @"\n"
    @"CLANG=\"$(xcrun --sdk iphoneos -f clang)\"\n"
    @"SDK=\"$(xcrun --sdk iphoneos --show-sdk-path)\"\n"
    @"\n"
    @"[[ -f \"$SOURCE_FILE\" ]] || fail \"${SOURCE_FILE} not found\"\n"
    @"[[ -f \"$HEADER_FILE\" ]] || fail \"${HEADER_FILE} not found\"\n"
    @"[[ -f \"${ROOT_DIR}/manifest.json\" ]] || fail \"manifest.json not found\"\n"
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
    @"    -I\"$SOURCE_DIR\"\n"
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
    @"echo \"[1/9] Compiling arm64\"\n"
    @"\"$CLANG\" \"${COMMON_CFLAGS[@]}\" -arch arm64 -c \"$SOURCE_FILE\" -o \"$BUILD_DIR/arm64/${TARGET_NAME}.o\"\n"
    @"\n"
    @"echo \"[2/9] Linking arm64\"\n"
    @"\"$CLANG\" \"${COMMON_LDFLAGS[@]}\" -arch arm64 \"$BUILD_DIR/arm64/${TARGET_NAME}.o\" -o \"$BUILD_DIR/arm64/${TARGET_NAME}.dylib\"\n"
    @"\n"
    @"echo \"[3/9] Compiling arm64e\"\n"
    @"\"$CLANG\" \"${COMMON_CFLAGS[@]}\" -arch arm64e -c \"$SOURCE_FILE\" -o \"$BUILD_DIR/arm64e/${TARGET_NAME}.o\"\n"
    @"\n"
    @"echo \"[4/9] Linking arm64e\"\n"
    @"\"$CLANG\" \"${COMMON_LDFLAGS[@]}\" -arch arm64e \"$BUILD_DIR/arm64e/${TARGET_NAME}.o\" -o \"$BUILD_DIR/arm64e/${TARGET_NAME}.dylib\"\n"
    @"\n"
    @"echo \"[5/9] Creating universal dylib\"\n"
    @"lipo -create \\\n"
    @"    \"$BUILD_DIR/arm64/${TARGET_NAME}.dylib\" \\\n"
    @"    \"$BUILD_DIR/arm64e/${TARGET_NAME}.dylib\" \\\n"
    @"    -output \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
    @"\n"
    @"echo \"[6/9] Signing with ldid\"\n"
    @"ldid -S \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
    @"\n"
    @"echo \"[7/9] Writing build metadata\"\n"
    @"SESSION_ID=\"$(plutil -extract build.sessionID raw -o - manifest.json)\"\n"
    @"BUILD_ID=\"${MRZEFV_BUILD_ID:-local}\"\n"
    @"\n"
    @"cat > \"$PACKAGES_DIR/build-info.json\" <<EOF\n"
    @"{\n"
    @"  \"target\": \"${TARGET_NAME}\",\n"
    @"  \"generator\": \"AVX512/MRzefv\",\n"
    @"  \"sessionID\": \"${SESSION_ID}\",\n"
    @"  \"buildID\": \"${BUILD_ID}\",\n"
    @"  \"architecture\": [\"arm64\", \"arm64e\"],\n"
    @"  \"minimumIOSVersion\": \"${MIN_IOS_VERSION}\",\n"
    @"  \"sdk\": \"iphoneos\",\n"
    @"  \"compiler\": \"Apple Clang\",\n"
    @"  \"installName\": \"@rpath/${TARGET_NAME}.dylib\",\n"
    @"  \"signing\": \"ldid\",\n"
    @"  \"status\": \"built\"\n"
    @"}\n"
    @"EOF\n"
    @"\n"
    @"echo \"[8/9] Verifying\"\n"
    @"file \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
    @"lipo -info \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
    @"otool -D \"$PACKAGES_DIR/${TARGET_NAME}.dylib\"\n"
    @"\n"
    @"echo \"[9/9] Creating ZIP\"\n"
    @"(\n"
    @"    cd \"$PACKAGES_DIR\"\n"
    @"    zip -q \"${TARGET_NAME}.zip\" \"${TARGET_NAME}.dylib\" \"build-info.json\"\n"
    @")\n"
    @"\n"
    @"echo \"BUILD COMPLETE\"\n"
    @"echo \"  packages/${TARGET_NAME}.dylib\"\n"
    @"echo \"  packages/${TARGET_NAME}.zip\"\n"
    @"echo \"  packages/build-info.json\"\n";
}
#pragma mark - GitHub Actions
static NSString *AVX512Workflow(void)
{
    return
    @"name: Build MRzefv Generated Dylib\n"
    @"\n"
    @"on:\n"
    @"  workflow_dispatch:\n"
    @"  push:\n"
    @"    branches:\n"
    @"      - main\n"
    @"\n"
    @"jobs:\n"
    @"  build:\n"
    @"    runs-on: macos-15\n"
    @"\n"
    @"    env:\n"
    @"      OUT_NAME: ${{ github.event.inputs.out_name || 'MRzefvGenerated' }}\n"
    @"      MRZEFV_BUILD_ID: MRZ-${{ github.run_id }}-${{ github.run_attempt }}\n"
    @"\n"
    @"    steps:\n"
    @"      - name: Checkout\n"
    @"        uses: actions/checkout@v4\n"
    @"\n"
    @"      - name: Check Apple toolchain\n"
    @"        run: |\n"
    @"          xcodebuild -version\n"
    @"          xcrun --sdk iphoneos --show-sdk-path\n"
    @"          xcrun --sdk iphoneos -f clang\n"
    @"          lipo -info \"$(xcrun --sdk iphoneos -f clang)\"\n"
    @"\n"
    @"      - name: Install ldid\n"
    @"        run: |\n"
    @"          brew install ldid\n"
    @"          ldid --version || true\n"
    @"\n"
    @"      - name: Validate generated project\n"
    @"        run: |\n"
    @"          set -e\n"
    @"          test -f build.sh\n"
    @"          test -f manifest.json\n"
    @"          test -f Sources/MRzefvGenerated.h\n"
    @"          test -f Sources/MRzefvGenerated.m\n"
    @"          test -f generation-receipt.json\n"
    @"          echo \"Generated project files OK\"\n"
    @"          find . -maxdepth 3 -type f | sort\n"
    @"\n"
    @"      - name: Verify session ID\n"
    @"        run: |\n"
    @"          set -e\n"
    @"          SESSION_ID=\"$(plutil -extract build.sessionID raw -o - manifest.json)\"\n"
    @"          RECEIPT_ID=\"$(plutil -extract sessionID raw -o - generation-receipt.json)\"\n"
    @"          test -n \"$SESSION_ID\"\n"
    @"          test \"$SESSION_ID\" = \"$RECEIPT_ID\"\n"
    @"          echo \"Session: $SESSION_ID\"\n"
    @"\n"
    @"      - name: Build generated dylib\n"
    @"        run: |\n"
    @"          chmod +x build.sh\n"
    @"          ./build.sh\n"
    @"\n"
    @"      - name: Verify artifacts\n"
    @"        run: |\n"
    @"          set -e\n"
    @"          test -f packages/MRzefvGenerated.dylib\n"
    @"          test -f packages/MRzefvGenerated.zip\n"
    @"          test -f packages/build-info.json\n"
    @"          file packages/MRzefvGenerated.dylib\n"
    @"          lipo -info packages/MRzefvGenerated.dylib\n"
    @"          otool -D packages/MRzefvGenerated.dylib\n"
    @"          cat packages/build-info.json\n"
    @"\n"
    @"      - name: Upload dylib\n"
    @"        uses: actions/upload-artifact@v4\n"
    @"        with:\n"
    @"          name: MRzefvGenerated-dylib\n"
    @"          path: packages/MRzefvGenerated.dylib\n"
    @"\n"
    @"      - name: Upload ZIP\n"
    @"        uses: actions/upload-artifact@v4\n"
    @"        with:\n"
    @"          name: MRzefvGenerated-package\n"
    @"          path: packages/MRzefvGenerated.zip\n"
    @"\n"
    @"      - name: Upload build metadata\n"
    @"        uses: actions/upload-artifact@v4\n"
    @"        with:\n"
    @"          name: MRzefvGenerated-metadata\n"
    @"          path: packages/build-info.json\n";
}
#pragma mark - Generation Receipt
static NSDictionary *AVX512GenerationReceipt(NSString *sessionID,
                                             NSString *targetClassName,
                                             NSArray *operations)
{
    return @{
        @"generator" : @"AVX512/MRzefv",
        @"sessionID" : sessionID,
        @"targetClass" : targetClassName ?: @"",
        @"operationCount" : @(operations.count),
        @"status" : @"generated"
    };
}
#pragma mark - Main Generator
@implementation AVX512GeneratedProject
+ (NSURL *)generateProjectWithTargetView:(UIView *)targetView
                              operations:(NSArray *)operations
                                   error:(NSError **)error
{
    if (!targetView) {
        if (error) {
            *error = AVX512Error(@"A target view is required.");
        }
        return nil;
    }
    if (![operations isKindOfClass:NSArray.class]) {
        if (error) {
            *error = AVX512Error(@"Operations must be an NSArray.");
        }
        return nil;
    }
    NSString *sessionID =
        AVX512UUID();
    NSString *targetClassName =
        NSStringFromClass(targetView.class);
    NSArray *safeOperations =
        [operations copy];
    NSArray *documents =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                            NSUserDomainMask,
                                            YES);
    NSString *documentsPath =
        documents.firstObject;
    if (!documentsPath) {
        if (error) {
            *error = AVX512Error(@"Could not locate the Documents directory.");
        }
        return nil;
    }
    NSURL *root =
        [NSURL fileURLWithPath:documentsPath
                   isDirectory:YES];
    NSURL *generatedRoot =
        [[root
          URLByAppendingPathComponent:@"AVX512"
                          isDirectory:YES]
         URLByAppendingPathComponent:@"Generated"
                         isDirectory:YES];
    NSURL *sessionRoot =
        [generatedRoot
         URLByAppendingPathComponent:sessionID
                         isDirectory:YES];
    NSURL *projectRoot =
        [sessionRoot
         URLByAppendingPathComponent:@"MRzefvGenerated"
                         isDirectory:YES];
    NSURL *sourcesRoot =
        [projectRoot
         URLByAppendingPathComponent:@"Sources"
                         isDirectory:YES];
    NSURL *githubRoot =
        [projectRoot
         URLByAppendingPathComponent:@".github"
                         isDirectory:YES];
    NSURL *workflowsRoot =
        [githubRoot
         URLByAppendingPathComponent:@"workflows"
                         isDirectory:YES];
    NSFileManager *fm =
        NSFileManager.defaultManager;
    NSError *directoryError = nil;
    NSArray<NSURL *> *directories = @[
        generatedRoot,
        sessionRoot,
        projectRoot,
        sourcesRoot,
        githubRoot,
        workflowsRoot
    ];
    for (NSURL *directory in directories) {
        if (![fm createDirectoryAtURL:directory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&directoryError]) {
            if (error) {
                *error = directoryError;
            }
            return nil;
        }
    }
    NSURL *headerURL =
        [sourcesRoot
         URLByAppendingPathComponent:@"MRzefvGenerated.h"];
    NSURL *sourceURL =
        [sourcesRoot
         URLByAppendingPathComponent:@"MRzefvGenerated.m"];
    NSURL *manifestURL =
        [projectRoot
         URLByAppendingPathComponent:@"manifest.json"];
    NSURL *receiptURL =
        [projectRoot
         URLByAppendingPathComponent:@"generation-receipt.json"];
    NSURL *buildScriptURL =
        [projectRoot
         URLByAppendingPathComponent:@"build.sh"];
    NSURL *workflowURL =
        [workflowsRoot
         URLByAppendingPathComponent:@"build-mrzefv-generated.yml"];
    NSString *header =
        AVX512GeneratedHeader(sessionID);
    NSString *source =
        AVX512GeneratedSource(sessionID,
                              targetClassName,
                              safeOperations);
    NSDictionary *manifest =
        AVX512Manifest(sessionID,
                       targetClassName,
                       safeOperations);
    NSDictionary *receipt =
        AVX512GenerationReceipt(sessionID,
                                targetClassName,
                                safeOperations);
    NSError *writeError = nil;
    if (!AVX512WriteString(header,
                           headerURL,
                           &writeError)) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    if (!AVX512WriteString(source,
                           sourceURL,
                           &writeError)) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    NSData *manifestData =
        [NSJSONSerialization dataWithJSONObject:manifest
                                        options:NSJSONWritingPrettyPrinted |
                                                NSJSONWritingSortedKeys
                                          error:&writeError];
    if (!manifestData ||
        !AVX512WriteData(manifestData,
                         manifestURL,
                         &writeError)) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    NSData *receiptData =
        [NSJSONSerialization dataWithJSONObject:receipt
                                        options:NSJSONWritingPrettyPrinted |
                                                NSJSONWritingSortedKeys
                                          error:&writeError];
    if (!receiptData ||
        !AVX512WriteData(receiptData,
                         receiptURL,
                         &writeError)) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    if (!AVX512WriteString(AVX512BuildScript(),
                           buildScriptURL,
                           &writeError)) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    if (!AVX512WriteString(AVX512Workflow(),
                           workflowURL,
                           &writeError)) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    NSDictionary *attributes = @{
        NSFilePosixPermissions : @0755
    };
    if (![fm setAttributes:attributes
               ofItemAtPath:buildScriptURL.path
                      error:&writeError]) {
        if (error) {
            *error = writeError;
        }
        return nil;
    }
    return projectRoot;
}
@end
