//
//  AVX512GeneratedProject.m
//  AVX512 / MRzefv
//
//  Converts recorded AVX512 edit operations into an isolated
//  MRzefvGenerated build project.
//
//  This file runs inside AVX512.
//  It is NOT compiled into MRzefvGenerated.dylib.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

#pragma mark - Generator Interface

@interface AVX512GeneratedProject : NSObject
@end

@interface AVX512GeneratedProject ()

* (NSURL *)projectDirectoryForSession:(NSString *)sessionID
    target:(NSString *)target
    error:(NSError **)error;
* (NSString *)headerSourceForTarget:(NSString *)target
    sessionID:(NSString *)sessionID;
* (NSString *)implementationSourceForTarget:(NSString *)target
    sessionID:(NSString *)sessionID
    className:(NSString *)className
    operations:(NSArray *)operations;
* (NSString *)manifestForTarget:(NSString *)target
    sessionID:(NSString *)sessionID
    className:(NSString *)className
    operations:(NSArray *)operations;
* (NSString *)buildScript;
* (NSString *)workflow;
* (BOOL)writeString:(NSString *)string
    toURL:(NSURL *)url
    error:(NSError **)error;
* (NSString *)sessionIdentifier;
* (NSString *)objcString:(NSString *)value;
* (id)operationValue:(id)operation
    key:(NSString *)key;
* (NSInteger)operationType:(id)operation;
* (NSString *)operationClassName:(id)operation
    fallback:(NSString *)fallback;
* (NSString *)operationViewPath:(id)operation;
* (NSDictionary *)operationValues:(id)operation;
* (id)fail:(NSError **)error
    code:(NSInteger)code
    reason:(NSString *)reason;

@end

#pragma mark - Implementation

@implementation AVX512GeneratedProject

#pragma mark - Public

* (NSURL *)generateProjectWithTargetView:(UIView *)targetView
    operations:(NSArray *)operations
    error:(NSError **)error
    {
    if (!targetView) {
    return [self fail:error
    code:1
    reason:@“No target view was supplied.”];
    }
    if (![operations isKindOfClass:[NSArray class]] ||
    operations.count == 0) {
    return [self fail:error
    code:2
    reason:@“No edit operations were recorded.”];
    }
    /*
    * ONE UUID PER GENERATION.
    * This exact value is reused by every generated artifact.
        */
        NSString *sessionID = [self sessionIdentifier];
    NSString *targetName = @“MRzefvGenerated”;
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
    [root URLByAppendingPathComponent:@“Sources”
    isDirectory:YES];
    NSURL *workflows =
    [root URLByAppendingPathComponent:@”.github/workflows”
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
    NSStringFromClass([targetView class]);
    if (className.length == 0) {
    className = @“UIView”;
    }
    NSLog(@”[AVX512] Generating MRzefv project”);
    NSLog(@”[AVX512] Session: %@”, sessionID);
    NSLog(@”[AVX512] Target: %@”, className);
    NSLog(@”[AVX512] Operations: %lu”,
    (unsigned long)operations.count);
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
    NSURL *headerURL =
    [sources URLByAppendingPathComponent:@“MRzefvGenerated.h”];
    NSURL *implementationURL =
    [sources URLByAppendingPathComponent:@“MRzefvGenerated.m”];
    NSURL *manifestURL =
    [root URLByAppendingPathComponent:@“manifest.json”];
    NSURL *buildURL =
    [root URLByAppendingPathComponent:@“build.sh”];
    NSURL *workflowURL =
    [workflows
    URLByAppendingPathComponent:@“build-mrzefv-generated.yml”];
    if (![self writeString:header
    toURL:headerURL
    error:error]) {
    return nil;
    }
    if (![self writeString:implementation
    toURL:implementationURL
    error:error]) {
    return nil;
    }
    if (![self writeString:manifest
    toURL:manifestURL
    error:error]) {
    return nil;
    }
    if (![self writeString:buildScript
    toURL:buildURL
    error:error]) {
    return nil;
    }
    if (![self writeString:workflow
    toURL:workflowURL
    error:error]) {
    return nil;
    }
    /*
    * Make build.sh executable.
        */
        [fm setAttributes:@{
        NSFilePosixPermissions : @0755
        }
        ofItemAtPath:buildURL.path
        error:nil];
    /*
    * Generation receipt.
    * IMPORTANT:
    * Same sessionID as manifest.json.
        */
        NSDictionary *receipt = @{
        @“generator” : @“AVX512/MRzefv”,
        @“target” : targetName,
        @“sessionID” : sessionID,
        @“className” : className,
        @“operationCount” : @(operations.count),
        @“status” : @“generated”
        };
    NSError *jsonError = nil;
    NSData *receiptData =
    [NSJSONSerialization
    dataWithJSONObject:receipt
    options:NSJSONWritingPrettyPrinted
    error:&jsonError];
    if (!receiptData) {
    if (error) {
    *error = jsonError;
    }

  return nil;

    }
    NSURL *receiptURL =
    [root
    URLByAppendingPathComponent:@“generation-receipt.json”];
    if (![receiptData writeToURL:receiptURL
    options:NSDataWritingAtomic
    error:error]) {
    return nil;
    }
    NSLog(@”[AVX512] Generated project:”);
    NSLog(@”%@”, root.path);
    return root;
    }

#pragma mark - Project Directory

* (NSURL *)projectDirectoryForSession:(NSString *)sessionID
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
    reason:@“Unable to locate Documents directory.”];
    }
    NSURL *buildRoot =
    [documents
    URLByAppendingPathComponent:@“AVX512/Generated”
    isDirectory:YES];
    NSURL *sessionRoot =
    [buildRoot
    URLByAppendingPathComponent:sessionID
    isDirectory:YES];
    NSURL *project =
    [sessionRoot
    URLByAppendingPathComponent:target
    isDirectory:YES];
    if (![fm createDirectoryAtURL:project
    withIntermediateDirectories:YES
    attributes:nil
    error:error]) {
    return nil;
    }
    return project;
    }

#pragma mark - Header Generation

* (NSString *)headerSourceForTarget:(NSString *)target
    sessionID:(NSString *)sessionID
    {
    NSMutableString *source =
    [NSMutableString string];
    [source appendString:
    @”//\n”
    @”// MRzefvGenerated.h\n”
    @”// Generated by AVX512 / MRzefv\n”
    @”//\n”
    @”\n”
    @”#ifndef MRzefvGenerated_h\n”
    @”#define MRzefvGenerated_h\n”
    @”\n”
    @”#import <Foundation/Foundation.h>\n”
    @”#import <UIKit/UIKit.h>\n”
    @”\n”];
    [source appendFormat:
    @”// Session: %@\n”
    @”// Target: %@\n”
    @”\n”,
    [self objcString:sessionID],
    [self objcString:target]];
    [source appendString:
    @“FOUNDATION_EXPORT NSString * const MRzefvGeneratedSessionID;\n”
    @“FOUNDATION_EXPORT NSString * const MRzefvGeneratedGenerator;\n”
    @“FOUNDATION_EXPORT NSString * const MRzefvGeneratedTarget;\n”
    @”\n”
    @“FOUNDATION_EXPORT void MRzefvGeneratedInitialize(void);\n”
    @“FOUNDATION_EXPORT NSString *MRzefvGeneratedBuildID(void);\n”
    @”\n”
    @”#endif\n”];
    return source;
    }

#pragma mark - Generated Objective-C

* (NSString *)implementationSourceForTarget:(NSString *)target
    sessionID:(NSString *)sessionID
    className:(NSString *)className
    operations:(NSArray *)operations
    {
    NSMutableString *source =
    [NSMutableString string];
    [source appendString:
    @”//\n”
    @”// MRzefvGenerated.m\n”
    @”// Generated by AVX512 / MRzefv\n”
    @”//\n”
    @”\n”
    @”#import "MRzefvGenerated.h"\n”
    @”#import <objc/runtime.h>\n”
    @”\n”];
    [source appendFormat:
    @“NSString * const MRzefvGeneratedSessionID = @"%@";\n”,
    [self objcString:sessionID]];
    [source appendString:
    @“NSString * const MRzefvGeneratedGenerator = @"AVX512/MRzefv";\n”
    @“NSString * const MRzefvGeneratedTarget = @"MRzefvGenerated";\n”
    @”\n”
    @“static BOOL MRzefvGeneratedDidInitialize = NO;\n”
    @”\n”
    @“static UIView *MRzefvFindViewInTree(UIView *root, Class targetClass);\n”
    @“static UIView *MRzefvFindTargetView(void);\n”
    @“static void MRzefvApplyOperations(UIView *view);\n”
    @”\n”];
    /*
    * Target class.
        */
        [source appendString:
        @“static UIView *MRzefvFindTargetView(void)\n”
        @”{\n”
        @”    Class targetClass = NSClassFromString(@"”];
    [source appendString:
    [self objcString:className]];
    [source appendString:
    @”");\n”
    @”\n”
    @”    if (!targetClass) {\n”
    @”        return nil;\n”
    @”    }\n”
    @”\n”
    @”    UIApplication *application = UIApplication.sharedApplication;\n”
    @”\n”
    @”    for (UIScene *scene in application.connectedScenes) {\n”
    @”        if (![scene isKindOfClass:[UIWindowScene class]]) {\n”
    @”            continue;\n”
    @”        }\n”
    @”\n”
    @”        UIWindowScene *windowScene = (UIWindowScene *)scene;\n”
    @”\n”
    @”        for (UIWindow *window in windowScene.windows) {\n”
    @”            UIView *found = MRzefvFindViewInTree(window, targetClass);\n”
    @”\n”
    @”            if (found) {\n”
    @”                return found;\n”
    @”            }\n”
    @”        }\n”
    @”    }\n”
    @”\n”
    @”    return nil;\n”
    @”}\n”
    @”\n”
    @“static UIView *MRzefvFindViewInTree(UIView *root, Class targetClass)\n”
    @”{\n”
    @”    if (!root || !targetClass) {\n”
    @”        return nil;\n”
    @”    }\n”
    @”\n”
    @”    if ([root isKindOfClass:targetClass]) {\n”
    @”        return root;\n”
    @”    }\n”
    @”\n”
    @”    for (UIView *child in root.subviews) {\n”
    @”        UIView *found = MRzefvFindViewInTree(child, targetClass);\n”
    @”\n”
    @”        if (found) {\n”
    @”            return found;\n”
    @”        }\n”
    @”    }\n”
    @”\n”
    @”    return nil;\n”
    @”}\n”
    @”\n”];
    /*
    * Apply recorded operations.
        */
        [source appendString:
        @“static void MRzefvApplyOperations(UIView *view)\n”
        @”{\n”
        @”    if (!view) {\n”
        @”        return;\n”
        @”    }\n”
        @”\n”];
    for (id operation in operations) {

  NSInteger type =
      [self operationType:operation];
  NSDictionary *values =
      [self operationValues:operation];
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
               @"        label.numberOfLines = 0;\n"
               @"        [view addSubview:label];\n"
               @"    }\n",
              [self objcString:text]];
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
      case AVX512GeneratedOperationReplaceImage: {
          NSString *resource =
              values[@"resource"];
          if (![resource isKindOfClass:[NSString class]]) {
              resource = @"";
          }
          [source appendFormat:
              @"    {\n"
               @"        UIImage *image = [UIImage imageNamed:@\"%@\"];\n"
               @"        if (image && [view respondsToSelector:@selector(setImage:)]) {\n"
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
    @”}\n”
    @”\n”
    @“void MRzefvGeneratedInitialize(void)\n”
    @”{\n”
    @”    if (MRzefvGeneratedDidInitialize) {\n”
    @”        return;\n”
    @”    }\n”
    @”\n”
    @”    MRzefvGeneratedDidInitialize = YES;\n”
    @”\n”
    @”    dispatch_async(dispatch_get_main_queue(), ^{\n”
    @”        UIView *target = MRzefvFindTargetView();\n”
    @”\n”
    @”        if (!target) {\n”
    @”            NSLog(@"[MRzefvGenerated] Target view not found");\n”
    @”            return;\n”
    @”        }\n”
    @”\n”
    @”        MRzefvApplyOperations(target);\n”
    @”    });\n”
    @”}\n”
    @”\n”
    @“NSString *MRzefvGeneratedBuildID(void)\n”
    @”{\n”
    @”    return MRzefvGeneratedSessionID;\n”
    @”}\n”
    @”\n”
    @”attribute((constructor))\n”
    @“static void MRzefvGeneratedConstructor(void)\n”
    @”{\n”
    @”    @autoreleasepool {\n”
    @”        MRzefvGeneratedInitialize();\n”
    @”    }\n”
    @”}\n”];
    return source;
    }

#pragma mark - Manifest

* (NSString *)manifestForTarget:(NSString *)target
    sessionID:(NSString *)sessionID
    className:(NSString *)className
    operations:(NSArray *)operations
    {
    NSMutableArray *manifestOperations =
    [NSMutableArray arrayWithCapacity:operations.count];
    for (id operation in operations) {

  NSDictionary *entry = @{
      @"type" :
          @([self operationType:operation]),
      @"className" :
          [self operationClassName:operation
                          fallback:className],
      @"viewPath" :
          [self operationViewPath:operation],
      @"values" :
          [self operationValues:operation]
  };
  [manifestOperations addObject:entry];

    }
    NSDictionary *manifest = @{
    @“formatVersion” : @1,

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
      ],
      @"minimumIOSVersion" : @"15.0"
  },
  @"target" : @{
      @"className" : className
  },
  @"operations" :
      manifestOperations,
  @"resources" : @[],
  @"integrity" : @{
      @"sourceHash" : @"__GENERATED_BY_BUILD__",
      @"manifestHash" : @"__GENERATED_BY_BUILD__"
  }

    };
    NSError *error = nil;
    NSData *data =
    [NSJSONSerialization
    dataWithJSONObject:manifest
    options:NSJSONWritingPrettyPrinted
    error:&error];
    if (!data) {
    NSLog(@”[AVX512] Manifest error: %@”, error);
    return @”{}”;
    }
    return
    [[NSString alloc]
    initWithData:data
    encoding:NSUTF8StringEncoding];
    }

#pragma mark - Build Script

* (NSString *)buildScript
    {
    return
    @”#!/usr/bin/env bash\n”
    @“set -euo pipefail\n”
    @”\n”
    @“ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\n”
    @“cd "$ROOT_DIR"\n”
    @”\n”
    @“TARGET_NAME="${OUT_NAME:-MRzefvGenerated}"\n”
    @“SOURCE_NAME="MRzefvGenerated"\n”
    @“MIN_IOS_VERSION="${MIN_IOS_VERSION:-15.0}"\n”
    @“BUILD_DIR="${BUILD_DIR:-build}"\n”
    @“PACKAGES_DIR="${PACKAGES_DIR:-packages}"\n”
    @“SOURCE_FILE="Sources/${SOURCE_NAME}.m"\n”
    @”\n”
    @“echo "========================================"\n”
    @“echo " MRzefv Generated Dylib Build"\n”
    @“echo "========================================"\n”
    @“echo "Target:       ${TARGET_NAME}"\n”
    @“echo "Session:      ${MRZEFV_SESSION_ID:-unknown}"\n”
    @“echo "Build ID:     ${MRZEFV_BUILD_ID:-unknown}"\n”
    @“echo\n”
    @”\n”
    @“command -v xcrun >/dev/null 2>&1 || exit 1\n”
    @“command -v lipo >/dev/null 2>&1 || exit 1\n”
    @“command -v otool >/dev/null 2>&1 || exit 1\n”
    @“command -v zip >/dev/null 2>&1 || exit 1\n”
    @”\n”
    @“CLANG="$(xcrun –sdk iphoneos -f clang)"\n”
    @“SDK="$(xcrun –sdk iphoneos –show-sdk-path)"\n”
    @“LDID="$(command -v ldid || true)"\n”
    @”\n”
    @“if [[ -z "$LDID" ]]; then\n”
    @”    echo "ERROR: ldid is not installed" >&2\n”
    @”    exit 1\n”
    @“fi\n”
    @”\n”
    @“if [[ -z "${MRZEFV_SESSION_ID:-}" ]]; then\n”
    @”    echo "ERROR: MRZEFV_SESSION_ID is not set" >&2\n”
    @”    exit 1\n”
    @“fi\n”
    @”\n”
    @“if [[ ! -f "$SOURCE_FILE" ]]; then\n”
    @”    echo "ERROR: $SOURCE_FILE not found" >&2\n”
    @”    exit 1\n”
    @“fi\n”
    @”\n”
    @“rm -rf "$BUILD_DIR" "$PACKAGES_DIR"\n”
    @“mkdir -p "$BUILD_DIR/arm64" "$BUILD_DIR/arm64e" "$PACKAGES_DIR"\n”
    @”\n”
    @“COMMON_CFLAGS=(\n”
    @”    -fobjc-arc\n”
    @”    -fblocks\n”
    @”    -fmodules\n”
    @”    -isysroot "$SDK"\n”
    @”    -miphoneos-version-min="$MIN_IOS_VERSION"\n”
    @”    -I"$ROOT_DIR/Sources"\n”
    @”    -Wall\n”
    @”    -Wextra\n”
    @”    -Wno-deprecated-declarations\n”
    @”    -Wno-nullability-completeness\n”
    @”)\n”
    @”\n”
    @“COMMON_LDFLAGS=(\n”
    @”    -dynamiclib\n”
    @”    -isysroot "$SDK"\n”
    @”    -miphoneos-version-min="$MIN_IOS_VERSION"\n”
    @”    -install_name "@rpath/${TARGET_NAME}.dylib"\n”
    @”    -Wl,-headerpad_max_install_names\n”
    @”    -Wl,-search_paths_first\n”
    @”    -framework Foundation\n”
    @”    -framework UIKit\n”
    @”)\n”
    @”\n”
    @“echo "[1/7] Compiling arm64"\n”
    @”"$CLANG" "${COMMON_CFLAGS[@]}" \\n”
    @”    -arch arm64 \\n”
    @”    -c "$SOURCE_FILE" \\n”
    @”    -o "$BUILD_DIR/arm64/${SOURCE_NAME}.o"\n”
    @”\n”
    @“echo "[2/7] Linking arm64"\n”
    @”"$CLANG" "${COMMON_LDFLAGS[@]}" \\n”
    @”    -arch arm64 \\n”
    @”    "$BUILD_DIR/arm64/${SOURCE_NAME}.o" \\n”
    @”    -o "$BUILD_DIR/arm64/${TARGET_NAME}.dylib"\n”
    @”\n”
    @“echo "[3/7] Compiling arm64e"\n”
    @”"$CLANG" "${COMMON_CFLAGS[@]}" \\n”
    @”    -arch arm64e \\n”
    @”    -c "$SOURCE_FILE" \\n”
    @”    -o "$BUILD_DIR/arm64e/${SOURCE_NAME}.o"\n”
    @”\n”
    @“echo "[4/7] Linking arm64e"\n”
    @”"$CLANG" "${COMMON_LDFLAGS[@]}" \\n”
    @”    -arch arm64e \\n”
    @”    "$BUILD_DIR/arm64e/${SOURCE_NAME}.o" \\n”
    @”    -o "$BUILD_DIR/arm64e/${TARGET_NAME}.dylib"\n”
    @”\n”
    @“echo "[5/7] Creating universal dylib"\n”
    @“lipo -create \\n”
    @”    "$BUILD_DIR/arm64/${TARGET_NAME}.dylib" \\n”
    @”    "$BUILD_DIR/arm64e/${TARGET_NAME}.dylib" \\n”
    @”    -output "$PACKAGES_DIR/${TARGET_NAME}.dylib"\n”
    @”\n”
    @“echo "[6/7] Signing"\n”
    @”"$LDID" -S "$PACKAGES_DIR/${TARGET_NAME}.dylib"\n”
    @”\n”
    @“echo "[7/7] Packaging"\n”
    @“cat > "$PACKAGES_DIR/build-info.json" <<EOF\n”
    @”{\n”
    @”  "target": "${TARGET_NAME}",\n”
    @”  "generator": "AVX512/MRzefv",\n”
    @”  "sessionID": "${MRZEFV_SESSION_ID}",\n”
    @”  "buildID": "${MRZEFV_BUILD_ID:-unknown}",\n”
    @”  "architectures": ["arm64", "arm64e"],\n”
    @”  "minimumIOSVersion": "${MIN_IOS_VERSION}",\n”
    @”  "sdk": "iphoneos",\n”
    @”  "compiler": "Apple Clang",\n”
    @”  "installName": "@rpath/${TARGET_NAME}.dylib",\n”
    @”  "signing": "ldid",\n”
    @”  "status": "built"\n”
    @”}\n”
    @“EOF\n”
    @”\n”
    @”(\n”
    @”    cd "$PACKAGES_DIR"\n”
    @”    zip -q "${TARGET_NAME}.zip" \\n”
    @”        "${TARGET_NAME}.dylib" \\n”
    @”        "build-info.json"\n”
    @”)\n”
    @”\n”
    @“echo "========================================"\n”
    @“echo " BUILD COMPLETE"\n”
    @“echo "========================================"\n”
    @“lipo -info "$PACKAGES_DIR/${TARGET_NAME}.dylib"\n”;
    return script;
    }

#pragma mark - GitHub Workflow

* (NSString )workflow
    {
    return
    @“name: Build MRzefv Generated Dylib\n”
    @”\n”
    @“on:\n”
    @”  workflow_dispatch:\n”
    @”    inputs:\n”
    @”      out_name:\n”
    @”        description: Output dylib name\n”
    @”        required: false\n”
    @”        default: MRzefvGenerated\n”
    @”  push:\n”
    @”    branches:\n”
    @”      - main\n”
    @”\n”
    @“permissions:\n”
    @”  contents: read\n”
    @”\n”
    @“jobs:\n”
    @”  build:\n”
    @”    name: Build Generated Dylib\n”
    @”    runs-on: macos-15\n”
    @”\n”
    @”    steps:\n”
    @”      - name: Checkout generated project\n”
    @”        uses: actions/checkout@v4\n”
    @”\n”
    @”      - name: Show Apple toolchain\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”          xcodebuild -version\n”
    @”          xcrun –sdk iphoneos –show-sdk-path\n”
    @”          xcrun –sdk iphoneos -f clang\n”
    @”\n”
    @”      - name: Install ldid\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”          if ! command -v ldid >/dev/null 2>&1; then\n”
    @”            brew update\n”
    @”            brew install ldid\n”
    @”          fi\n”
    @”          command -v ldid\n”
    @”          ldid –version || true\n”
    @”\n”
    @”      - name: Validate generated project\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”\n”
    @”          echo "========================================"\n”
    @”          echo "VALIDATING GENERATED PROJECT"\n”
    @”          echo "========================================"\n”
    @”\n”
    @”          required_files=(\n”
    @”            "build.sh"\n”
    @”            "manifest.json"\n”
    @”            "Sources/MRzefvGenerated.h"\n”
    @”            "Sources/MRzefvGenerated.m"\n”
    @”          )\n”
    @”\n”
    @”          for file in "${required_files[@]}"; do\n”
    @”            if [[ ! -f "$file" ]]; then\n”
    @”              echo "::error::Missing required file: $file"\n”
    @”              echo "Repository contents:"\n”
    @”              find . -maxdepth 5 -type f -print | sort\n”
    @”              exit 1\n”
    @”            fi\n”
    @”            echo "✓ $file"\n”
    @”          done\n”
    @”\n”
    @”          echo "✓ Validation passed"\n”
    @”\n”
    @”      - name: Read generated session ID\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”\n”
    @”          SESSION_ID="$(plutil -extract build.sessionID raw -o - manifest.json)"\n”
    @”\n”
    @”          if [[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]]; then\n”
    @”            echo "::error::manifest.json does not contain build.sessionID"\n”
    @”            exit 1\n”
    @”          fi\n”
    @”\n”
    @”          echo "MRZEFV_SESSION_ID=$SESSION_ID" >> "$GITHUB_ENV"\n”
    @”          echo "Session ID: $SESSION_ID"\n”
    @”\n”
    @”      - name: Verify generation receipt\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”\n”
    @”          if [[ -f "generation-receipt.json" ]]; then\n”
    @”            RECEIPT_SESSION="$(plutil -extract sessionID raw -o - generation-receipt.json)"\n”
    @”\n”
    @”            if [[ "$RECEIPT_SESSION" != "$MRZEFV_SESSION_ID" ]]; then\n”
    @”              echo "::error::Session ID mismatch"\n”
    @”              echo "Manifest: $MRZEFV_SESSION_ID"\n”
    @”              echo "Receipt:  $RECEIPT_SESSION"\n”
    @”              exit 1\n”
    @”            fi\n”
    @”\n”
    @”            echo "✓ Session IDs match"\n”
    @”          fi\n”
    @”\n”
    @”      - name: Set build identity\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”          BUILD_ID="MRZ-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"\n”
    @”          echo "MRZEFV_BUILD_ID=$BUILD_ID" >> "$GITHUB_ENV"\n”
    @”          echo "Build ID: $BUILD_ID"\n”
    @”\n”
    @”      - name: Build generated dylib\n”
    @”        shell: bash\n”
    @”        env:\n”
    @”          OUT_NAME: ${{ github.event.inputs.out_name || ‘MRzefvGenerated’ }}\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”          chmod +x build.sh\n”
    @”          ./build.sh\n”
    @”\n”
    @”      - name: Verify build output\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”\n”
    @”          [[ -d packages ]] || {\n”
    @”            echo "::error::packages/ was not produced"\n”
    @”            exit 1\n”
    @”          }\n”
    @”\n”
    @”          DYLIB="$(find packages -maxdepth 1 -name ".dylib" -type f | head -n 1)"\n”
    @”          ZIP="$(find packages -maxdepth 1 -name ".zip" -type f | head -n 1)"\n”
    @”\n”
    @”          [[ -n "$DYLIB" ]] || {\n”
    @”            echo "::error::No dylib produced"\n”
    @”            exit 1\n”
    @”          }\n”
    @”\n”
    @”          [[ -n "$ZIP" ]] || {\n”
    @”            echo "::error::No ZIP produced"\n”
    @”            exit 1\n”
    @”          }\n”
    @”\n”
    @”          echo "Dylib: $DYLIB"\n”
    @”          echo "ZIP:   $ZIP"\n”
    @”\n”
    @”      - name: Verify dylib\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”          DYLIB="$(find packages -maxdepth 1 -name ".dylib" -type f | head -n 1)"\n”
    @”          file "$DYLIB"\n”
    @”          lipo -info "$DYLIB"\n”
    @”          otool -D "$DYLIB"\n”
    @”          otool -L "$DYLIB" || true\n”
    @”\n”
    @”      - name: Verify build metadata\n”
    @”        shell: bash\n”
    @”        run: |\n”
    @”          set -euo pipefail\n”
    @”          BUILD_INFO="packages/build-info.json"\n”
    @”\n”
    @”          [[ -f "$BUILD_INFO" ]] || {\n”
    @”            echo "::error::Missing build-info.json"\n”
    @”            exit 1\n”
    @”          }\n”
    @”\n”
    @”          BUILD_SESSION="$(plutil -extract sessionID raw -o - "$BUILD_INFO")"\n”
    @”\n”
    @”          if [[ "$BUILD_SESSION" != "$MRZEFV_SESSION_ID" ]]; then\n”
    @”            echo "::error::Session ID mismatch in build-info.json"\n”
    @”            exit 1\n”
    @”          fi\n”
    @”\n”
    @”          cat "$BUILD_INFO"\n”
    @”          echo "✓ Build metadata verified"\n”
    @”\n”
    @”      - name: Upload dylib\n”
    @”        uses: actions/upload-artifact@v4\n”
    @”        with:\n”
    @”          name: MRzefvGenerated-dylib-${{ github.run_number }}\n”
    @”          path: packages/.dylib\n”
    @”          if-no-files-found: error\n”
    @”          retention-days: 30\n”
    @”\n”
    @”      - name: Upload generated ZIP\n”
    @”        uses: actions/upload-artifact@v4\n”
    @”        with:\n”
    @”          name: MRzefvGenerated-package-${{ github.run_number }}\n”
    @”          path: packages/.zip\n”
    @”          if-no-files-found: error\n”
    @”          retention-days: 30\n”
    @”\n”
    @”      - name: Upload build metadata\n”
    @”        if: always()\n”
    @”        uses: actions/upload-artifact@v4\n”
    @”        with:\n”
    @”          name: MRzefvGenerated-metadata-${{ github.run_number }}\n”
    @”          path: |\n”
    @”            manifest.json\n”
    @”            generation-receipt.json\n”
    @”            packages/build-info.json\n”
    @”          if-no-files-found: ignore\n”
    @”          retention-days: 30\n”;
    return workflow;
    }

#pragma mark - Operation Access

* (id)operationValue:(id)operation
    key:(NSString *)key
    {
    if (!operation || key.length == 0) {
    return nil;
    }
    /*
    * Support NSDictionary operations.
        */
        if ([operation isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)operation objectForKey:key];
        }
    /*
    * Support AVX512GeneratedOperation objects.
        */
        @try {
        return [operation valueForKey:key];
        }
        @catch (__unused NSException *exception) {
        return nil;
        }
        }
* (NSInteger)operationType:(id)operation
    {
    id value =
    [self operationValue:operation
    key:@“type”];
    if ([value respondsToSelector:@selector(integerValue)]) {
    return [value integerValue];
    }
    return -1;
    }
* (NSString *)operationClassName:(id)operation
    fallback:(NSString *)fallback
    {
    id value =
    [self operationValue:operation
    key:@“className”];
    if ([value isKindOfClass:[NSString class]] &&
    [(NSString *)value length] > 0) {
    return value;
    }
    return fallback ?: @“UIView”;
    }
* (NSString *)operationViewPath:(id)operation
    {
    id value =
    [self operationValue:operation
    key:@“viewPath”];
    if ([value isKindOfClass:[NSString class]]) {
    return value;
    }
    return @””;
    }
* (NSDictionary *)operationValues:(id)operation
    {
    id value =
    [self operationValue:operation
    key:@“values”];
    if ([value isKindOfClass:[NSDictionary class]]) {
    return value;
    }
    return @{};
    }

#pragma mark - File Writing

* (BOOL)writeString:(NSString *)string
    toURL:(NSURL *)url
    error:(NSError **)error
    {
    if (!string || !url) {
    if (error) {
    *error =
    [NSError
    errorWithDomain:@“AVX512GeneratedProject”
    code:20
    userInfo:@{
    NSLocalizedDescriptionKey :
    @“Unable to write generated file.”
    }];
    }

  return NO;

    }
    return
    [string writeToURL:url
    atomically:YES
    encoding:NSUTF8StringEncoding
    error:error];
    }

#pragma mark - Session

* (NSString *)sessionIdentifier
    {
    return
    [NSUUID UUID].UUIDString.lowercaseString;
    }

#pragma mark - Objective-C Escaping

* (NSString *)objcString:(NSString *)value
    {
    if (!value) {
    return @””;
    }
    NSString *escaped =
    [value stringByReplacingOccurrencesOfString:@”\”
    withString:@”\\”];
    escaped =
    [escaped stringByReplacingOccurrencesOfString:@”"”
    withString:@”\"”];
    escaped =
    [escaped stringByReplacingOccurrencesOfString:@”\n”
    withString:@”\n”];
    escaped =
    [escaped stringByReplacingOccurrencesOfString:@”\r”
    withString:@”\r”];
    escaped =
    [escaped stringByReplacingOccurrencesOfString:@”\t”
    withString:@”\t”];
    return escaped;
    }

#pragma mark - Errors

* (id)fail:(NSError **)error
    code:(NSInteger)code
    reason:(NSString *)reason
    {
    if (error) {
    *error =
    [NSError
    errorWithDomain:@“AVX512GeneratedProject”
    code:code
    userInfo:@{
    NSLocalizedDescriptionKey :
    reason ?: @“Unknown generator error.”
    }];
    }
    return nil;
    }

@end