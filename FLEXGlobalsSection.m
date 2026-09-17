//
//  AVX512GlobalsSection.m
//  FLEX
//
//  Created by Tanner Bennett on 7/11/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXGlobalsSection.h"
#import "NSArray+FLEX.h"
#import "UIFont+FLEX.h"

@interface AVX512GlobalsSection ()

/// Filtered rows.
@property (nonatomic) NSArray<AVX512GlobalsEntry *> *rows;

/// Unfiltered rows.
@property (nonatomic) NSArray<AVX512GlobalsEntry *> *allRows;

@end

@implementation AVX512GlobalsSection

#pragma mark - Initialization

+ (instancetype)title:(NSString *)title rows:(NSArray<AVX512GlobalsEntry *> *)rows {
    AVX512GlobalsSection *section = [self new];
    section->_title = title;
    section.allRows = rows;

    return section;
}

- (void)setAllRows:(NSArray<AVX512GlobalsEntry *> *)allRows {
    _allRows = allRows.copy;
    [self reloadData];
}

#pragma mark - Overrides

- (NSInteger)numberOfRows {
    return self.rows.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    [self reloadData];
}

- (void)reloadData {
    NSString *filterText = self.filterText;

    if (filterText.length) {
        self.rows = [self.allRows avx512_filtered:^BOOL(AVX512GlobalsEntry *entry, NSUInteger idx) {
            NSString *name = entry.entryNameFuture ? entry.entryNameFuture() : @"";
            return [name localizedCaseInsensitiveContainsString:filterText];
        }];
    } else {
        self.rows = self.allRows;
    }
}

- (BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    return (id)self.rows[row].rowAction;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    AVX512GlobalsEntry *entry = self.rows[row];

    if (entry.viewControllerFuture) {
        return entry.viewControllerFuture();
    }

    return nil;
}

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = UIFont.avx512_defaultTableCellFont;

    AVX512GlobalsEntry *entry = self.rows[row];
    NSString *title = entry.entryNameFuture ? entry.entryNameFuture() : @"";

    cell.textLabel.text = title;

    //
    // One SF Symbol per globals entry.
    //
    // The symbols are keyed by the displayed title so the existing
    // AVX512GlobalsEntry implementations do not need to change.
    //
    static NSDictionary<NSString *, NSString *> *symbols = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        symbols = @{
            // Process & Events
            @"Network History":              @"antenna.radiowaves.left.and.right",
            @"System Log":                   @"doc.text.magnifyingglass",
            @"Process Info":                 @"cpu",
            @"Live Objects":                 @"cube.transparent",
            @"Address Explorer":             @"magnifyingglass",
            @"Runtime Browser":              @"books.vertical",

            // App Shortcuts
            @"App Delegate":                 @"app.badge",
            @"Key Window":                   @"macwindow",
            @"Root View Controller":         @"rectangle.stack",
            @"NSUserDefaults":               @"externaldrive",
            @"Main Bundle":                  @"shippingbox",
            @"UIApplication.shared":         @"app.dashed",
            @"Browse Bundle":                @"folder",
            @"Browse Container":             @"folder.badge.gearshape",
            @"Cookies":                      @"birthday.cake",
            @"Keychain":                     @"key",
            @"Push Notifications":           @"bell.badge",

            // Miscellaneous
            @"UIScreen.main":               @"display",
            @"UIDevice.current":             @"iphone",
            @"UIPasteboard.general":         @"doc.on.clipboard",
            @"NSURLSession.shared":          @"antenna.radiowaves.left.and.right",
            @"NSURLCache.shared":            @"hourglass",
            @"NSNotificationCenter.default": @"bell",
            @"UIMenuController.shared":      @"filemenu.and.selection",
            @"NSFileManager.default":        @"folder",
            @"NSTimeZone.system":            @"globe",
            @"NSLocale.current":             @"character.bubble",
            @"NSCalendar.current":           @"calendar",
            @"NSRunLoop.main":               @"arrow.triangle.2.circlepath",
            @"NSThread.main":                @"line.3.horizontal",
            @"NSOperationQueue.main":         @"square.stack.3d.up",

            // MRzefv Tools
            @"UI Editor":                    @"rectangle.and.pencil.and.ellipsis",
            @"Dylib Generator":              @"shippingbox",
            @"Enhanced CFG":                 @"point.3.connected.trianglepath.dotted",
            @"UI Profiles":                  @"doc.text"
        };
    });

    NSString *symbolName = symbols[title];

    if (symbolName.length) {
        cell.imageView.image = [UIImage systemImageNamed:symbolName];
        cell.imageView.tintColor = UIColor.systemBlueColor;
    } else {
        cell.imageView.image = nil;
    }
}

@end

@implementation AVX512GlobalsSection (Subscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.rows[idx];
}

@end