//
//  AVX512HookTemplateGenerator.h
//  AVX512HookTemplateGenerator
//
//  AVX512 by DELvEK.NET
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Dylib Configuration

typedef NS_ENUM(NSInteger, AVX512DylibType) {
    AVX512DylibTypeDiagnostic = 0,
    AVX512DylibTypeTestHarness
};

typedef NS_ENUM(NSInteger, AVX512BuildStyle) {
    AVX512BuildStyleShell = 0,
    AVX512BuildStyleGitHubActions
};

#pragma mark - Method Information

@interface AVX512MethodInfo : NSObject

@property (nonatomic, copy) NSString *selectorName;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *returnType;

@property (nonatomic, assign) NSUInteger argumentCount;
@property (nonatomic, assign) BOOL inherited;

@property (nonatomic, assign) IMP implementation;
@property (nonatomic, copy, nullable) NSString *imageName;

@property (nonatomic, assign) uintptr_t implementationAddress;
@property (nonatomic, assign) uintptr_t imageOffset;

@end

#pragma mark - Class Information

@interface AVX512ClassInfo : NSObject

@property (nonatomic, assign) Class cls;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy, nullable) NSString *superclassName;

@property (nonatomic, strong) NSArray<AVX512MethodInfo *> *methods;

@end

#pragma mark - Assembly Information

@interface AVX512InstructionInfo : NSObject

@property (nonatomic, assign) uintptr_t address;
@property (nonatomic, assign) uint32_t instructionWord;

@property (nonatomic, copy) NSString *mnemonic;
@property (nonatomic, copy) NSString *operands;
@property (nonatomic, copy) NSString *bytes;

@property (nonatomic, copy) NSString *explanation;

@property (nonatomic, assign) BOOL isBranch;
@property (nonatomic, assign) BOOL isCall;
@property (nonatomic, assign) BOOL isReturn;

@property (nonatomic, assign) BOOL canNOP;

@end

#pragma mark - Test Patch

@interface AVX512PatchInfo : NSObject

@property (nonatomic, copy, nullable) NSString *imageName;

@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *selectorName;

@property (nonatomic, assign) uintptr_t address;

@property (nonatomic, copy) NSString *originalInstruction;
@property (nonatomic, copy) NSString *replacementInstruction;

@property (nonatomic, copy) NSString *originalBytes;
@property (nonatomic, copy) NSString *replacementBytes;

@property (nonatomic, assign) BOOL isNOP;

@end

#pragma mark - Generator

@interface AVX512HookTemplateGenerator : UITableViewController

@end

NS_ASSUME_NONNULL_END
