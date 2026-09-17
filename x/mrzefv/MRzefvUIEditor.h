//
//  MRzefvUIEditor.h
//  AVX512HookTemplateGenerator
//
//  MRzefv UI Editor by DELvEK.NET
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MRzefvUIChangeType) {
    MRzefvUIChangeTypeText = 0,
    MRzefvUIChangeTypeHidden,
    MRzefvUIChangeTypeAlignment,
    MRzefvUIChangeTypeFrame,
    MRzefvUIChangeTypeAddText
};

@interface MRzefvUIChange : NSObject

@property (nonatomic, assign) MRzefvUIChangeType type;

@property (nonatomic, copy) NSString *targetClass;
@property (nonatomic, copy) NSString *hierarchyPath;

@property (nonatomic, copy, nullable) NSString *propertyName;

@property (nonatomic, copy, nullable) NSString *originalValue;
@property (nonatomic, copy, nullable) NSString *newValue;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSTextAlignment alignment;

@end

@interface MRzefvUIProfile : NSObject

@property (nonatomic, copy) NSString *format;
@property (nonatomic, assign) NSInteger version;

@property (nonatomic, strong) NSMutableArray<MRzefvUIChange *> *changes;

- (void)addChange:(MRzefvUIChange *)change;
- (void)removeChange:(MRzefvUIChange *)change;
- (void)removeAllChanges;

- (NSDictionary *)dictionaryRepresentation;
- (NSData *)JSONData:(NSError **)error;

@end

@interface MRzefvUIEditorController : UITableViewController

@property (nonatomic, strong) MRzefvUIProfile *profile;

/// The view currently being inspected/edited.
@property (nonatomic, weak, nullable) UIView *selectedView;

/// Begins a temporary live-preview session.
- (void)beginPreview;

/// Reverts all temporary preview changes.
- (void)resetPreview;

/// Saves the current changes into the UI profile.
- (void)saveCurrentProfile;

@end

NS_ASSUME_NONNULL_END
