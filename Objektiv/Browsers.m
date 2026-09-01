//
//  Browsers.m
//  Objektiv
//
//  Created by Ankit Solanki on 19/01/13.
//  Copyright (c) 2013 nth loop. All rights reserved.
//

#import "Browsers.h"
#import "Constants.h"
#import "NSWorkspace+Utils.h"
#import "BrowserPattern+ObjC.h"

@implementation Browsers {
    NSArray *_browsers;
    NSArray *internalBlacklist;
}

#pragma mark - initialization

+ (Browsers *)sharedInstance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id)init
{
    self = [super init];

    internalBlacklist = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle]
                                                pathForResource:@"Blacklist"
                                                         ofType:@"plist"]];
    return self;
}

#pragma mark - static properties

+ (NSArray *)browsers
{
    return [[Browsers sharedInstance] browsers];
}

+ (NSArray *)validBrowsers
{
    return [[Browsers sharedInstance] validBrowsers];
}

#pragma mark - instance properties

- (NSArray *)browsers
{
    if (![_browsers count]) {
        [self findBrowsers];
    }
    return _browsers;
}

- (NSArray *)validBrowsers
{
    return [self.browsers filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        BrowserItem *item = evaluatedObject;
        return !item.hidden;
    }]];
}

- (NSString *)defaultBrowserIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *identifier = [defaults stringForKey:PrefSelectedBrowser];
    if (identifier.length == 0) {
        return @"com.apple.Safari";
    }
    return identifier;
}

- (NSString *)systemDefaultBrowser
{
    return [[NSWorkspace sharedWorkspace] defaultBrowserIdentifier];
}

- (void)setDefaultBrowserIdentifier:(NSString *)defaultBrowserIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:defaultBrowserIdentifier forKey:PrefSelectedBrowser];
}

- (void)setOurselvesAsDefaultBrowser
{
    [[NSWorkspace sharedWorkspace] setDefaultBrowserWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark - Public methods

- (void)findBrowsersAsync
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self findBrowsers];
    });
}

- (void)findBrowsers
{
    _browsers = [self collectBrowsers];
}

- (NSArray *)collectBrowsers
{
    NSLog(@"Find browsers");
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
    NSArray *identifiers = [sharedWorkspace installedBrowserIdentifiers];

    identifiers = [identifiers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id browserId, NSDictionary *bindings) {
        return ![BrowserPattern identifier:browserId matchesPatterns:self->internalBlacklist];
    }]];

    NSString *defaultBrowser = [self defaultBrowserIdentifier];
    NSMutableArray *allBrowsers = [[NSMutableArray alloc] initWithCapacity:identifiers.count];

    for (NSString *browser in identifiers) {
        if (![browser isKindOfClass:[NSString class]] || browser.length == 0) {
            NSLog(@"Invalid application identifier: %@", browser);
            continue;
        }

        NSURL *browserURL = [sharedWorkspace URLForApplicationWithBundleIdentifier:browser];
        NSString *browserPath = browserURL.path;
        if (!browserPath) {
            NSLog(@"Can't find path of browser: %@", browser);
            continue;
        }

        NSString *browserName = [defaultFileManager displayNameAtPath:browserPath];
        if (!browserName) {
            NSLog(@"Can't find name of browser: %@", browser);
            continue;
        }

        BrowserItem *item = [[BrowserItem alloc] initWithApplicationId:browser name:browserName path:browserPath];
        item.hidden = [self isHidden:browser];
        item.isDefault = [browser isEqualToString:defaultBrowser];
        [allBrowsers addObject:item];
    }

    return [allBrowsers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

- (BOOL)isHidden:(NSString *)browserIdentifier
{
    if (!browserIdentifier) {
        return NO;
    }

    NSArray *prefsHidden = [[NSUserDefaults standardUserDefaults] valueForKey:PrefBlacklist];
    return [BrowserPattern identifier:browserIdentifier matchesPatterns:prefsHidden];
}

- (void)hideABrowser:(id)sender
{
    NSString *identifier = [sender representedObject];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *prefsHidden = [[defaults valueForKey:PrefBlacklist] mutableCopy];
    if (!prefsHidden) {
        prefsHidden = [NSMutableArray array];
    }
    [prefsHidden addObject:identifier];
    [defaults setValue:prefsHidden forKey:PrefBlacklist];

    [self findBrowsersAsync];
}

- (void)unhideABrowser:(id)sender
{
    NSString *identifier = [sender representedObject];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *prefsHidden = [[defaults valueForKey:PrefBlacklist] mutableCopy];
    if (!prefsHidden) {
        return;
    }

    NSUInteger index = [prefsHidden indexOfObjectPassingTest:^BOOL(id hiddenIdentifer, NSUInteger idx, BOOL *stop) {
        return [identifier rangeOfString:hiddenIdentifer].location != NSNotFound;
    }];

    if (index == NSNotFound) {
        return;
    }

    [prefsHidden removeObjectAtIndex:index];
    [defaults setValue:prefsHidden forKey:PrefBlacklist];

    [self findBrowsersAsync];
}

@end
