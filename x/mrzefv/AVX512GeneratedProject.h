//
//  AVX512GeneratedProject.h
//  AVX512
//
//  Generated-project builder for AVX512 / MRzefv.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, AVX512GeneratedOperationType) {
    AVX512GeneratedOperationTypeMove = 0,
    AVX512GeneratedOperationTypeResize,
    AVX512GeneratedOperationTypeHide,
    AVX512GeneratedOperationTypeShow,
    AVX512GeneratedOperationTypeReplaceText,
    AVX512GeneratedOperationTypeAddText,
    AVX512GeneratedOperationTypeReplaceImage
};
@interface AVX512GeneratedOperation : NSObject
@property (nonatomic, assign) AVX512GeneratedOperationType type;
@property (nonatomic, copy, nullable) NSString *className;
@property (nonatomic, copy, nullable) NSString *viewPath;
@property (nonatomic, copy) NSDictionary<NSString *, id> *values;
+ (instancetype)operationWithType:(AVX512GeneratedOperationType)type
                         className:(nullable NSString *)className
                          viewPath:(nullable NSString *)viewPath
                            values:(nullable NSDictionary<NSString *, id> *)values;
@end
@interface AVX512GeneratedProject : NSObject
+ (nullable NSURL *)generateProjectWithTargetView:(UIView *)targetView
                                       operations:(NSArray *)operations
                                            error:(NSError **)error;
@end
NS_ASSUME_NONNULL_END
