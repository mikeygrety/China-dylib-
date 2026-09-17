//
//  AVX512HookTemplateGenerator.h
//  AVX512HookTemplateGenerator
//
//  AVX512 by DELvEK.NET
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVX512HookTemplateGenerator : UITableViewController
@interface AVX512InspectorDataSource : NSObject <UITableViewDataSource>

- (instancetype)initWithLines:(NSArray<NSString *> *)lines
                     className:(NSString *)className
              selectionHandler:(void (^)(void))selectionHandler;

- (void)selectClass;

@end

NS_ASSUME_NONNULL_END