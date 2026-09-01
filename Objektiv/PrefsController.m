//
//  PrefsController.m
//  Objektiv
//
//  Created by Ankit Solanki on 22/11/12.
//  Copyright (c) 2012 nth loop. All rights reserved.
//

#import "PrefsController.h"
#import "Constants.h"
#import <MASShortcut/Shortcut.h>

@interface PrefsController ()
{
    NSUserDefaults *defaults;
}
@end

@implementation PrefsController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        defaults = [NSUserDefaults standardUserDefaults];
    }

    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self initUI];
}

#pragma mark - UI methods

- (void)showPreferences
{
    [self.window makeKeyAndOrderFront:NSApp];
    if (@available(macOS 14.0, *)) {
        [NSApp activate];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)initUI
{
    self.autoHideIcon.state = [defaults boolForKey:PrefAutoHideIcon] ? NSControlStateValueOn : NSControlStateValueOff;
    self.startAtLogin.state = [defaults boolForKey:PrefStartAtLogin] ? NSControlStateValueOn : NSControlStateValueOff;
    self.showNotifications.state = [defaults boolForKey:PrefShowNotifications] ? NSControlStateValueOn : NSControlStateValueOff;
    self.hotkeyRecorder.associatedUserDefaultsKey = PrefHotkey;
}

#pragma mark - IBActions

- (IBAction)toggleLoginItem:(id)sender
{
    NSLog(@"PrefsController :: toggleLoginItem");
    [defaults setBool:(self.startAtLogin.state == NSControlStateValueOn) forKey:PrefStartAtLogin];
}

- (IBAction)toggleHideItem:(id)sender
{
    NSLog(@"PrefsController :: toggleHideItem");
    [defaults setBool:(self.autoHideIcon.state == NSControlStateValueOn) forKey:PrefAutoHideIcon];
}

- (IBAction)toggleShowNotifications:(id)sender
{
    NSLog(@"PrefsController :: showNotifications");
    [defaults setBool:(self.showNotifications.state == NSControlStateValueOn) forKey:PrefShowNotifications];
}

@end
