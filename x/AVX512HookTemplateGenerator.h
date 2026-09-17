//
//  AVX512HookTemplateGenerator.h
//  AVX512 by DELvEK.NET
//
//  Runtime explorer + diagnostic dylib generator.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVX512HookTemplateGenerator : UITableViewController

@end


@interface AVX512InspectorDataSource : NSObject
    <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithLines:(NSArray<NSString *> *)lines
                     className:(NSString *)className
              selectionHandler:(void (^)(void))selectionHandler;

- (void)selectClass;

@end

NS_ASSUME_NONNULL_END