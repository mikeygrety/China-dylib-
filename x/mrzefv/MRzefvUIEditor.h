//
//  MRzefvUIEditor.h
//  AVX512
//
//  MRzefv UI Editor
//  AVX512 by DELvEK.NET
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MRzefvUIChangeType) {
    MRzefvUIChangeTypeText = 0,
    MRzefvUIChangeTypeHidden,
    MRzefvUIChangeTypeAlignment,
    MRzefvUIChangeTypeFrame,
    MRzefvUIChangeTypeAddText
};

@interface MRzefvUIChange : NSObject

@property (nonatomic) MRzefvUIChangeType type;

@property (nonatomic, copy, nullable) NSString *targetClass;
@property (nonatomic, copy, nullable) NSString *hierarchyPath;
@property (nonatomic, copy, nullable) NSString *propertyName;

@property (nonatomic, copy, nullable) NSString *originalValue;
@property (nonatomic, copy, nullable) NSString *replacementValue;

@property (nonatomic) CGRect frame;
@property (nonatomic) NSTextAlignment alignment;

@end

@interface MRzefvUIProfile : NSObject

@property (nonatomic, copy) NSString *format;
@property (nonatomic) NSUInteger version;

@property (nonatomic, copy) NSArray<MRzefvUIChange *> *changes;

- (void)addChange:(MRzefvUIChange *)change;
- (void)removeChange:(MRzefvUIChange *)change;
- (void)removeAllChanges;

- (NSDictionary *)dictionaryRepresentation;
- (nullable NSData *)JSONData;

@end

@interface MRzefvUIEditorController : UITableViewController

@property (nonatomic, strong, readonly) MRzefvUIProfile *profile;

@property (nonatomic, weak, nullable) UIView *selectedView;

- (void)beginPreview;
- (void)resetPreview;
- (void)saveCurrentProfile;

@end

NS_ASSUME_NONNULL_END