//
//  MRzefvTools.h
//  AVX512HookTemplateGenerator
//
//  MRzefv Tools by DELvEK.NET
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MRzefvUIProfile;

@interface MRzefvToolsController : UITableViewController

/// Presents the MRzefv Tools menu.
+ (void)presentFromViewController:(UIViewController *)viewController;

/// Current UI profile being edited.
@property (nonatomic, strong, readonly) MRzefvUIProfile *profile;

@end

NS_ASSUME_NONNULL_END
