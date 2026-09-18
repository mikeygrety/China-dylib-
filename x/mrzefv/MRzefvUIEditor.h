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

@property (nonatomic, strong, readonly)
    MRzefvUIProfile *profile;

/**
 * The exact UIView returned by FLEX's existing live
 * selection system.
 *
 * MRzefv does not perform its own hit-testing or install
 * another selection gesture recognizer.
 */
@property (nonatomic, weak, nullable)
    UIView *selectedView;

/**
 * Hands live selection to FLEX's existing Explorer.
 *
 * FLEX owns the selection gesture, hit-testing, and
 * selection overlay. When selection completes, FLEX
 * invokes its live-selection completion with either:
 *
 *   selectedView != nil
 *       Successful UIView selection.
 *
 *   selectedView == nil
 *       Selection cancelled.
 *
 * The MRzefv editor is then restored.
 */
- (void)beginViewSelection;

/**
 * Starts the live preview workflow for the current
 * selected view.
 */
- (void)beginPreview;

/**
 * Restores the current selected view and clears
 * the recorded profile changes.
 */
- (void)resetPreview;

/**
 * Serializes and saves the current MRzefv profile.
 */
- (void)saveCurrentProfile;

@end

NS_ASSUME_NONNULL_END