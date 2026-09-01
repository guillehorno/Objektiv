//
//  ImageUtils.m
//  Objektiv
//
//  Created by Ankit Solanki on 17/12/12.
//  Copyright (c) 2012 nth loop. All rights reserved.
//
// -------------------------------------------------
// This class uses a NSCache instance in order to cache icons
// of the installed browsers.
//

#import "ImageUtils.h"
#import "Constants.h"
#import <AppKit/AppKit.h>

@implementation ImageUtils
{
    NSCache *cache;
}

#pragma mark initialization

+ (ImageUtils *)sharedInstance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id)init
{
    self = [super init];
    if (self) {
        cache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark static methods

+ (NSImage *)statusBarIconForAppId:(NSString *)applicationIdentifier
{
    return [[self sharedInstance] menuIconForAppId:applicationIdentifier];
}

+ (NSImage *)menuIconForAppId:(NSString *)applicationIdentifier
{
    return [[self sharedInstance] menuIconForAppId:applicationIdentifier];
}

+ (NSImage *)fullSizeIconForAppId:(NSString *)applicationIdentifier
{
    return [[[self sharedInstance] iconForAppIdentifier:applicationIdentifier] copy];
}

+ (NSImage *)fullSizeIconForAppId:(NSString *)applicationIdentifier withSize:(NSSize)size
{
    NSImage *image = [self fullSizeIconForAppId:applicationIdentifier];
    image.size = size;
    return image;
}

+ (NSImage *)tintInputImage:(NSImage *)inputImage toColor:(NSColor *)outputColor
{
    CIColor *ciColor = [[CIColor alloc] initWithColor:outputColor];
    CIImage *ciColorImage = [CIImage imageWithColor:ciColor];
    CIImage *ciInputImage = [self ciImageFromNSImage:inputImage];
    if (!ciInputImage) {
        return inputImage;
    }

    CIFilter *filter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [filter setValue:ciColorImage forKey:@"inputImage"];
    [filter setValue:ciInputImage forKey:@"inputBackgroundImage"];

    CIImage *image = [filter valueForKey:@"outputImage"];
    return [self imageFromCIImage:image];
}

#pragma mark instance methods

- (NSImage *)statusBarIconForAppId:(NSString *)applicationIdentifier
{
    NSString *key = [@"status:" stringByAppendingString:applicationIdentifier ?: @""];
    NSImage *icon = [cache objectForKey:key];
    if (icon) {
        return icon;
    }

    icon = [ImageUtils resizeIcon:[ImageUtils desaturateIcon:[self iconForAppIdentifier:applicationIdentifier]]];
    if (icon) {
        [cache setObject:icon forKey:key];
    }
    return icon;
}

- (NSImage *)menuIconForAppId:(NSString *)applicationIdentifier
{
    NSString *key = [@"menu:" stringByAppendingString:applicationIdentifier ?: @""];
    NSImage *icon = [cache objectForKey:key];
    if (icon) {
        return icon;
    }

    icon = [ImageUtils resizeIcon:[self iconForAppIdentifier:applicationIdentifier]];
    if (icon) {
        [cache setObject:icon forKey:key];
    }
    return icon;
}

#pragma mark internal utility methods

+ (NSImage *)resizeIcon:(NSImage *)icon
{
    if (!icon) {
        return nil;
    }
    icon = [icon copy];
    icon.size = CGSizeMake(StatusBarIconSize, StatusBarIconSize);
    return icon;
}

- (NSImage *)iconForAppIdentifier:(NSString *)applicationIdentifier
{
    if (applicationIdentifier.length == 0) {
        return nil;
    }

    NSImage *icon = [cache objectForKey:applicationIdentifier];
    if (icon) {
        return icon;
    }

    NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:applicationIdentifier];
    if (!appURL) {
        return nil;
    }
    icon = [[[NSWorkspace sharedWorkspace] iconForFile:appURL.path] copy];
    if (icon) {
        [cache setObject:icon forKey:applicationIdentifier];
    }
    return icon;
}

+ (NSImage *)imageFromCIImage:(CIImage *)ciImage
{
    if (!ciImage) {
        return nil;
    }
    NSSize size = ciImage.extent.size;
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(size.width, size.height)];
    [image addRepresentation:[NSCIImageRep imageRepWithCIImage:ciImage]];
    return image;
}

+ (CIImage *)ciImageFromNSImage:(NSImage *)image
{
    if (!image) {
        return nil;
    }
    NSData *tiff = [image TIFFRepresentation];
    if (!tiff) {
        return nil;
    }
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:tiff];
    if (!rep) {
        return nil;
    }
    return [[CIImage alloc] initWithBitmapImageRep:rep];
}

+ (NSImage *)desaturateIcon:(NSImage *)original
{
    CIImage *image = [self ciImageFromNSImage:original];
    if (!image) {
        return original;
    }
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:image forKey:@"inputImage"];
    [filter setValue:@0 forKey:@"inputSaturation"];
    [filter setValue:@1 forKey:@"inputContrast"];
    return [self imageFromCIImage:[filter valueForKey:@"outputImage"]];
}

@end
