//
//  OverlayWindowView.m
//  Objektiv
//
//  Created by Ankit Solanki on 19/12/12.
//  Copyright (c) 2012 nth loop. All rights reserved.
//

#import "OverlayWindowView.h"
#import "BrowserItem.h"
#import "AppDelegate.h"
#import "ImageUtils.h"

@implementation OverlayWindowView {
    AppDelegate *appDelegate;
}

#pragma mark - constants

const NSUInteger ICON_SIZE = 84;
const NSUInteger TEXT_HEIGHT = 24;
const NSUInteger H_PADDING = 16;
const NSUInteger BOX_PADDING = 16;

#pragma mark - properties
@synthesize fillColor = _fillColor;
- (NSColor *)fillColor
{
    if (!_fillColor) {
        _fillColor = [[NSColor whiteColor] colorWithAlphaComponent:0.8];
    }
    return _fillColor;
}

@synthesize strokeColor = _strokeColor;
- (NSColor *)strokeColor
{
    if (!_strokeColor) {
        _strokeColor = [self colorWithRed:0 green:0x66 blue:0xBB alpha:1];
    }
    return _strokeColor;
}

#pragma mark - NSView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        appDelegate = [[NSApplication sharedApplication] delegate];
        self.title = @"";
        [self setBorderType:NSNoBorder];
        [self setContentViewMargins:NSMakeSize(0, 0)];
        [self setBoxType:NSBoxCustom];
        [self setBorderColor:[NSColor clearColor]];
        [self setFillColor:[NSColor clearColor]];
        [self setAutoresizesSubviews:NO];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    dirtyRect = CGRectInset(dirtyRect, 0.5, 0.5);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:16 yRadius:16];
    [self.fillColor set];
    [path fill];

    [path setLineWidth:2];
    [self.strokeColor set];
    [path stroke];
}

#pragma mark - Actions
- (void)buttonClicked:(id)sender
{
    NSButton *button = sender;

    [self.window orderOut:nil];
    [self.window close];

    [appDelegate selectABrowser:button.cell];
}

#pragma mark - Internals & Business Logic

- (NSSize)addBrowsers:(NSArray *)browsers
{
    NSRect itemRect = NSMakeRect(BOX_PADDING, BOX_PADDING, ICON_SIZE + H_PADDING, ICON_SIZE + TEXT_HEIGHT);
    NSRect buttonRect = CGRectInset(itemRect, H_PADDING / 2, 0);
    NSUInteger width = itemRect.size.width, height = itemRect.size.height;

    NSUInteger maxRow = browsers.count / 9, maxColumn = browsers.count > 9 ? 9 : browsers.count;
    if ((browsers.count % 9) == 0) {
        maxRow--;
    }
    NSUInteger row = maxRow, column = 0;
    for (NSUInteger i = 0; i < browsers.count; i++) {
        BrowserItem *browser = browsers[i];

        NSRect offset = CGRectOffset(buttonRect, width * column, height * row);

        NSButton *button = [self buttonForBrowser:browser
                                       atPosition:i
                                        withFrame:offset];
        [self addSubview:button];

        column++;
        if (column >= 9 && row > 0) {
            row--;
            column = 0;
        }
    }

    NSSize size = NSMakeSize(width * maxColumn + BOX_PADDING * 2, height * (maxRow + 1) + BOX_PADDING * 2);
    return size;
}

- (NSButton *)buttonForBrowser:(BrowserItem *)browser atPosition:(NSUInteger)position withFrame:(NSRect)frame
{
    NSButton *button = [[NSButton alloc] initWithFrame:frame];

    button.image = [self imageForBrowser:browser withBadge:position + 1];
    button.keyEquivalent = [NSString stringWithFormat:@"%ld", (long)(position + 1)];
    button.attributedTitle = [self titleForButton:browser.name inColor:self.strokeColor];
    button.target = self;
    button.action = @selector(buttonClicked:);

    NSButtonCell *cell = button.cell;
    cell.imagePosition = NSImageAbove;

    cell.focusRingType = NSFocusRingTypeNone;
    cell.backgroundColor = self.fillColor;
    [cell setBezeled:NO];
    [cell setBordered:NO];
    [cell setTransparent:NO];
    [cell setSelectable:NO];
    [cell setButtonType:NSButtonTypeMomentaryPushIn];
    cell.showsStateBy = NSPushInCellMask;
    cell.highlightsBy = NSContentsCellMask;
    cell.representedObject = browser.identifier;

    return button;
}

- (NSImage *)imageForBrowser:(BrowserItem *)browser withBadge:(NSUInteger)position
{
    NSImage *baseImage = [[ImageUtils fullSizeIconForAppId:browser.identifier
                                                 withSize:NSMakeSize(ICON_SIZE, ICON_SIZE)] copy];
    if (!baseImage) {
        return nil;
    }

    BOOL showBadge = !(position > 9 || browser.isDefault);
    NSImage *selectionImage = nil;
    if (browser.isDefault) {
        selectionImage = [NSImage imageNamed:NSImageNameMenuOnStateTemplate];
        selectionImage = [ImageUtils tintInputImage:selectionImage toColor:self.strokeColor];
    }

    NSColor *stroke = self.strokeColor;
    NSString *badge = showBadge ? [NSString stringWithFormat:@"%ld", (long)position] : nil;

    return [NSImage imageWithSize:baseImage.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [baseImage drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];

        if (selectionImage) {
            [selectionImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
        }

        if (badge) {
            NSRect rect = NSMakeRect(0, 0, 20, 20);
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4 yRadius:4];
            [stroke set];
            [path fill];
            [badge drawInRect:CGRectInset(rect, 7, 2)
               withAttributes:@{NSForegroundColorAttributeName : [NSColor whiteColor]}];
        }
        return YES;
    }];
}

- (NSAttributedString *)titleForButton:(NSString *)plainTitle inColor:(NSColor *)color
{
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:plainTitle ?: @""];

    NSRange range = NSMakeRange(0, title.length);
    NSFont *font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize] + 2];

    [title addAttribute:NSForegroundColorAttributeName
                  value:color
                  range:range];
    [title addAttribute:NSFontAttributeName
                  value:font
                  range:range];
    [title setAlignment:NSTextAlignmentCenter range:range];
    [title fixAttributesInRange:range];

    return [self truncateString:title toWidth:ICON_SIZE];
}

#pragma mark - Utilities

- (NSAttributedString *)truncateString:(NSAttributedString *)attributedString toWidth:(NSUInteger)width
{
    NSAttributedString *result = attributedString;
    if (result.size.width > width) {
        NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithAttributedString:result];
        while ([newString size].width > width && newString.length >= 2) {
            NSRange range = NSMakeRange(newString.length - 2, 2);
            [newString replaceCharactersInRange:range withString:@"…"];
        }
        result = newString;
    }
    return result;
}

- (NSColor *)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(CGFloat)alpha
{
    return [NSColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha];
}

@end
