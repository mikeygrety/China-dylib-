//
//  AVX512GlobalsViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXGlobalsViewController.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjcRuntimeViewController.h"
#import "FLEXKeychainViewController.h"
#import "FLEXAPNSViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXLiveObjectsController.h"
#import "FLEXFileBrowserController.h"
#import "FLEXCookiesViewController.h"
#import "FLEXGlobalsEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXSystemLogViewController.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXAddressExplorerCoordinator.h"
#import "FLEXGlobalsSection.h"
#import "UIBarButtonItem+FLEX.h"

// MRzefv
#import "x/mrzefv/MRzefvUIEditor.h"

@interface AVX512GlobalsViewController ()

// The visible sections displayed by the table view.
@property (nonatomic) NSArray<AVX512GlobalsSection *> *sections;

/// All sections, including sections which may currently have no visible rows.
@property (nonatomic, readonly) NSArray<AVX512GlobalsSection *> *allSections;

/// Whether the selected row needs to be manually deselected when appearing.
@property (nonatomic, readonly) BOOL manuallyDeselectOnAppear;

@end

@implementation AVX512GlobalsViewController

@dynamic sections, allSections;

#pragma mark - Section Titles

+ (NSString *)globalsTitleForSection:(AVX512GlobalsSectionKind)section {
    switch (section) {
        case AVX512GlobalsSectionProcessAndEvents:
            return @"Process & Events";

        case AVX512GlobalsSectionAppShortcuts:
            return @"App Shortcuts";

        case AVX512GlobalsSectionMisc:
            return @"Miscellaneous";

        case AVX512GlobalsSectionMRzefvTools:
            return @"MRzefv Tools";

        default:
            @throw NSInternalInconsistencyException;
    }
}

#pragma mark - Global Entries

+ (AVX512GlobalsEntry *)globalsEntryForRow:(AVX512GlobalsRow)row {
    switch (row) {

        case AVX512GlobalsRowAppKeychainItems:
            return [AVX512KeychainViewController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowPushNotifications:
            return [AVX512APNSViewController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowAddressInspector:
            return [AVX512AddressExplorerCoordinator avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowBrowseRuntime:
            return [AVX512ObjcRuntimeViewController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowLiveObjects:
            return [AVX512LiveObjectsController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowCookies:
            return [AVX512CookiesViewController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowBrowseBundle:
        case AVX512GlobalsRowBrowseContainer:
            return [AVX512FileBrowserController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowSystemLog:
            return [AVX512SystemLogViewController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowNetworkHistory:
            return [AVX512NetworkMITMViewController avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowKeyWindow:
        case AVX512GlobalsRowRootViewController:
        case AVX512GlobalsRowProcessInfo:
        case AVX512GlobalsRowAppDelegate:
        case AVX512GlobalsRowUserDefaults:
        case AVX512GlobalsRowMainBundle:
        case AVX512GlobalsRowApplication:
        case AVX512GlobalsRowMainScreen:
        case AVX512GlobalsRowCurrentDevice:
        case AVX512GlobalsRowPasteboard:
        case AVX512GlobalsRowURLSession:
        case AVX512GlobalsRowURLCache:
        case AVX512GlobalsRowNotificationCenter:
        case AVX512GlobalsRowMenuController:
        case AVX512GlobalsRowFileManager:
        case AVX512GlobalsRowTimeZone:
        case AVX512GlobalsRowLocale:
        case AVX512GlobalsRowCalendar:
        case AVX512GlobalsRowMainRunLoop:
        case AVX512GlobalsRowMainThread:
        case AVX512GlobalsRowOperationQueue:
            return [AVX512ObjectExplorerFactory avx512_concreteGlobalsEntry:row];

        case AVX512GlobalsRowCount:
        default:
            @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:@"Missing AVX512 globals row implementation."
                userInfo:nil
            ];
    }
}

#pragma mark - Default Sections

+ (NSArray<AVX512GlobalsSection *> *)defaultGlobalSections {
    static NSMutableArray<AVX512GlobalsSection *> *sections = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSDictionary<NSNumber *, NSArray<AVX512GlobalsEntry *> *> *rowsBySection = @{

            //
            // Process & Events
            //
            @(AVX512GlobalsSectionProcessAndEvents) : @[
                [self globalsEntryForRow:AVX512GlobalsRowNetworkHistory],
                [self globalsEntryForRow:AVX512GlobalsRowSystemLog],
                [self globalsEntryForRow:AVX512GlobalsRowProcessInfo],
                [self globalsEntryForRow:AVX512GlobalsRowLiveObjects],
                [self globalsEntryForRow:AVX512GlobalsRowAddressInspector],
                [self globalsEntryForRow:AVX512GlobalsRowBrowseRuntime],
            ],

            //
            // App Shortcuts
            //
            @(AVX512GlobalsSectionAppShortcuts) : @[
                [self globalsEntryForRow:AVX512GlobalsRowBrowseBundle],
                [self globalsEntryForRow:AVX512GlobalsRowBrowseContainer],
                [self globalsEntryForRow:AVX512GlobalsRowMainBundle],
                [self globalsEntryForRow:AVX512GlobalsRowUserDefaults],
                [self globalsEntryForRow:AVX512GlobalsRowAppKeychainItems],
                [self globalsEntryForRow:AVX512GlobalsRowPushNotifications],
                [self globalsEntryForRow:AVX512GlobalsRowApplication],
                [self globalsEntryForRow:AVX512GlobalsRowAppDelegate],
                [self globalsEntryForRow:AVX512GlobalsRowKeyWindow],
                [self globalsEntryForRow:AVX512GlobalsRowRootViewController],
                [self globalsEntryForRow:AVX512GlobalsRowCookies],
            ],

            //
            // Miscellaneous
            //
            @(AVX512GlobalsSectionMisc) : @[
                [self globalsEntryForRow:AVX512GlobalsRowPasteboard],
                [self globalsEntryForRow:AVX512GlobalsRowMainScreen],
                [self globalsEntryForRow:AVX512GlobalsRowCurrentDevice],
                [self globalsEntryForRow:AVX512GlobalsRowURLSession],
                [self globalsEntryForRow:AVX512GlobalsRowURLCache],
                [self globalsEntryForRow:AVX512GlobalsRowNotificationCenter],
                [self globalsEntryForRow:AVX512GlobalsRowMenuController],
                [self globalsEntryForRow:AVX512GlobalsRowFileManager],
                [self globalsEntryForRow:AVX512GlobalsRowTimeZone],
                [self globalsEntryForRow:AVX512GlobalsRowLocale],
                [self globalsEntryForRow:AVX512GlobalsRowCalendar],
                [self globalsEntryForRow:AVX512GlobalsRowMainRunLoop],
                [self globalsEntryForRow:AVX512GlobalsRowMainThread],
                [self globalsEntryForRow:AVX512GlobalsRowOperationQueue],
            ],

            //
            // MRzefv Tools
            //
            @(AVX512GlobalsSectionMRzefvTools) : @[
                [AVX512GlobalsEntry
                    entryWithNameFuture:^NSString * {
                        return @"UI Editor";
                    }
                    viewControllerFuture:^UIViewController * {
                        return [[MRzefvUIEditorController alloc] init];
                    }
                ],

                [AVX512GlobalsEntry
                    entryWithNameFuture:^NSString * {
                        return @"Dylib Generator";
                    }
                    action:^(__kindof UITableViewController *host) {
                        NSLog(@"[MRzefv] Dylib Generator selected.");
                    }
                ],

                [AVX512GlobalsEntry
                    entryWithNameFuture:^NSString * {
                        return @"Enhanced CFG";
                    }
                    action:^(__kindof UITableViewController *host) {
                        NSLog(@"[MRzefv] Enhanced CFG selected.");
                    }
                ],

                [AVX512GlobalsEntry
                    entryWithNameFuture:^NSString * {
                        return @"UI Profiles";
                    }
                    action:^(__kindof UITableViewController *host) {
                        NSLog(@"[MRzefv] UI Profiles selected.");
                    }
                ]
            ]
        };

        sections = [NSMutableArray array];

        for (AVX512GlobalsSectionKind i = AVX512GlobalsSectionProcessAndEvents;
             i < AVX512GlobalsSectionCount;
             ++i) {

            NSString *title = [self globalsTitleForSection:i];

            NSArray<AVX512GlobalsEntry *> *rows = rowsBySection[@(i)];

            [sections addObject:
                [AVX512GlobalsSection title:title rows:rows]
            ];
        }
    });

    return sections;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    //
    // Branded two-line title:
    // AVX512
    // signature.zh by DELvEK.NET
    //
    UILabel *titleLine = [[UILabel alloc] init];
    titleLine.text = @"AVX512";
    titleLine.font = [UIFont boldSystemFontOfSize:17];
    titleLine.textColor = UIColor.labelColor;
    titleLine.textAlignment = NSTextAlignmentCenter;

    UILabel *sigLine = [[UILabel alloc] init];
    sigLine.text = @"signature.zh by DELvEK.NET";
    sigLine.font = [UIFont systemFontOfSize:10
                                      weight:UIFontWeightSemibold];
    sigLine.textColor = UIColor.systemBlueColor;
    sigLine.textAlignment = NSTextAlignmentCenter;

    UIStackView *titleStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            titleLine,
            sigLine
        ]];

    titleStack.axis = UILayoutConstraintAxisVertical;
    titleStack.alignment = UIStackViewAlignmentCenter;
    titleStack.spacing = 0;

    self.navigationItem.titleView = titleStack;

    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kAVX512DebounceInstant;

    self.navigationItem.backBarButtonItem =
        [UIBarButtonItem avx512_backItemWithTitle:@"Back"];

    _manuallyDeselectOnAppear =
        NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self disableToolbar];

    if (self.manuallyDeselectOnAppear) {
        [self.tableView
            deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow
                         animated:YES];
    }
}

#pragma mark - Sections

- (NSArray<AVX512GlobalsSection *> *)makeSections {
    NSMutableArray<AVX512GlobalsSection *> *sections =
        [NSMutableArray array];

    [sections addObjectsFromArray:[self.class defaultGlobalSections]];

    return sections;
}

#pragma mark - Legacy Row Access

- (AVX512GlobalsEntry *)globalsEntryAtIndex:(NSInteger)index {
    AVX512GlobalsRow row = [self globalRowAtIndex:index];

    return [[self class] globalsEntryForRow:row];
}

- (AVX512GlobalsRow)globalRowAtIndex:(NSInteger)index {
    return (AVX512GlobalsRow)index;
}

@end