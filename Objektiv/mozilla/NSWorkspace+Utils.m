/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NSWorkspace+Utils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation NSWorkspace (CaminoDefaultBrowserAdditions)

- (NSArray<NSString *> *)installedBrowserIdentifiers
{
    NSURL *httpsURL = [NSURL URLWithString:@"https://example.com"];
    NSArray<NSURL *> *appURLs = [self URLsForApplicationsToOpenURL:httpsURL];
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];

    for (NSURL *appURL in appURLs) {
        NSString *bundleID = [self identifierForBundle:appURL];
        if (bundleID.length == 0 || [seen containsObject:bundleID]) {
            continue;
        }
        [seen addObject:bundleID];
        [identifiers addObject:bundleID];
    }

    NSString *defaultHandler = [self defaultBrowserIdentifier];
    if (defaultHandler.length > 0 && ![seen containsObject:defaultHandler]) {
        [identifiers addObject:defaultHandler];
    }

    return identifiers;
}

- (NSString *)defaultBrowserIdentifier
{
    NSURL *httpsURL = [NSURL URLWithString:@"https://example.com"];
    NSURL *appURL = [self URLForApplicationToOpenURL:httpsURL];
    NSString *bundleID = [self identifierForBundle:appURL];
    if (bundleID.length == 0) {
        return @"com.apple.Safari";
    }
    return bundleID;
}

- (NSURL *)defaultBrowserURL
{
    NSString *defaultBundleId = [self defaultBrowserIdentifier];
    if (defaultBundleId) {
        return [self urlOfApplicationWithIdentifier:defaultBundleId];
    }
    return nil;
}

- (void)setDefaultBrowserWithIdentifier:(NSString *)bundleID
{
    NSURL *appURL = [self urlOfApplicationWithIdentifier:bundleID];
    if (!appURL) {
        NSLog(@"Can't locate application for bundle id %@", bundleID);
        return;
    }

    [self setDefaultApplicationAtURL:appURL
               toOpenURLsWithScheme:@"http"
                  completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to set default http handler: %@", error);
        }
    }];
    [self setDefaultApplicationAtURL:appURL
               toOpenURLsWithScheme:@"https"
                  completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to set default https handler: %@", error);
        }
    }];
    [self setDefaultApplicationAtURL:appURL
                  toOpenContentType:UTTypeHTML
                  completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to set default HTML handler: %@", error);
        }
    }];
}

- (NSURL *)urlOfApplicationWithIdentifier:(NSString *)bundleID
{
    if (bundleID.length == 0) {
        return nil;
    }
    return [self URLForApplicationWithBundleIdentifier:bundleID];
}

- (NSString *)identifierForBundle:(NSURL *)inBundleURL
{
    if (!inBundleURL) {
        return nil;
    }

    NSBundle *tmpBundle = [NSBundle bundleWithURL:inBundleURL];
    NSString *tmpBundleID = tmpBundle.bundleIdentifier;
    if (tmpBundleID.length > 0) {
        return tmpBundleID;
    }
    return nil;
}

@end
