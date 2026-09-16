//
//  AVX512HookTemplateGenerator.h
//  AVX512 by DELvEK.NET
//
//  Runtime recon -> class selection -> method inspection ->
//  project generation.
//
//  Generates a self-contained dylib project containing:
//
//      AVX512Hook.h
//      AVX512Hook.m
//      README.md
//      build.sh
//      OR
//      .github/workflows/build.yml
//
//  The generated implementation is a diagnostic/test harness.
//  Method metadata is discovered from the live Objective-C runtime.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVX512HookTemplateGenerator : UITableViewController
@end

NS_ASSUME_NONNULL_END
