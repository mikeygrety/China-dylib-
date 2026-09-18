//
//  MRzefvUIEditor.h
//  AVX512
//
//  MRzefv UI Editor
//  AVX512 by DELvEK.NET
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MRzefv UI Change

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

#pragma mark - MRzefv UI Profile

@interface MRzefvUIProfile : NSObject

@property (nonatomic, copy) NSString *format;
@property (nonatomic) NSUInteger version;

@property (nonatomic, strong)
    NSMutableArray<MRzefvUIChange *> *changes;

- (void)addChange:(MRzefvUIChange *)change;
- (void)removeChange:(MRzefvUIChange *)change;
- (void)removeAllChanges;

- (NSDictionary *)dictionaryRepresentation;
- (nullable NSData *)JSONData;

@end

#pragma mark - MRzefv UI Editor

@interface MRzefvUIEditorController : UITableViewController

/**
 * The currently selected live UIView.
 *
 * Selection is performed by the existing AVX512/FLEX
 * Explorer. MRzefv does not create its own hit-testing
 * or selection gesture system.
 */
@property (nonatomic, weak, nullable) UIView *selectedView;

/**
 * The current MRzefv UI modification profile.
 *
 * The profile records changes made through the editor
 * and can be serialized with -JSONData.
 */
@property (nonatomic, strong, readonly)
    MRzefvUIProfile *profile;

/**
 * Hands live-view selection to the existing Explorer.
 *
 * The Explorer owns:
 *
 * - Live-view hit testing
 * - Selection gestures
 * - Selection highlighting
 * - Selected UIView resolution
 *
 * When selection finishes, the selected UIView is stored
 * in selectedView. A cancelled selection leaves
 * selectedView nil.
 */
- (void)beginViewSelection;

/**
 * Starts the live preview workflow for the current
 * selected view.
 */
- (void)beginPreview;

/**
 * Restores the selected view where possible and clears
 * the recorded profile changes.
 */
- (void)resetPreview;

/**
 * Serializes and saves the current MRzefv UI profile.
 */
- (void)saveCurrentProfile;

@end

NS_ASSUME_NONNULL_END