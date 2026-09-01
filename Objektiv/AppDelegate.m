//
//  AppDelegate.m
//  Objektiv
//
//  Created by Ankit Solanki on 01/11/12.
//  Copyright (c) 2012 nth loop. All rights reserved.
//

#import "AppDelegate.h"
#import "Browsers.h"
#import "Constants.h"
#import "PrefsController.h"
#import "ImageUtils.h"
#import "BrowsersMenu.h"
#import "OverlayWindow.h"
#import "ZeroKitUtilities.h"
#import "ApplicationFolderWatcher.h"
#import <MASShortcut/Shortcut.h>
#import "PFMoveApplication.h"
#import <UserNotifications/UserNotifications.h>
#import <CoreServices/CoreServices.h>

@interface AppDelegate ()
{
    NSStatusItem *statusBarIcon;
    BrowsersMenu *browserMenu;
    NSUserDefaults *defaults;
    OverlayWindow *overlayWindow;
    ApplicationFolderWatcher *folderWatcher;
    NSString *_defaultBrowser;
}
@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self
            andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass
             andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    PFMoveToApplicationsFolderIfNecessary();

    NSLog(@"applicationDidFinishLaunching");

    self.prefsController = [[PrefsController alloc] initWithWindowNibName:@"PrefsController"];

    browserMenu = [[BrowsersMenu alloc] init];

    NSLog(@"Setting defaults");
    [ZeroKitUtilities registerDefaultsForBundle:[NSBundle mainBundle]];
    defaults = [NSUserDefaults standardUserDefaults];

    [self displayAreWeDefaultMsg];

    [defaults addObserver:self
               forKeyPath:PrefAutoHideIcon
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    [defaults addObserver:self
               forKeyPath:PrefStartAtLogin
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:PrefHotkey toAction:^{
        [self hotkeyTriggered];
    }];

    [[Browsers sharedInstance] findBrowsers];
    [self showAndHideIcon:nil];

    overlayWindow = [[OverlayWindow alloc] init];

    [self watchApplicationsFolder];

    NSLog(@"applicationDidFinishLaunching :: finish");
}

- (void)dealloc
{
    [defaults removeObserver:self forKeyPath:PrefAutoHideIcon];
    [defaults removeObserver:self forKeyPath:PrefStartAtLogin];
}

- (void)watchApplicationsFolder
{
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithObject:@"/Applications"];
    NSString *userApplications = [NSHomeDirectory() stringByAppendingPathComponent:@"Applications"];
    if (userApplications) {
        [paths addObject:userApplications];
    }

    folderWatcher = [[ApplicationFolderWatcher alloc] initWithDirectories:paths handler:^{
        [[Browsers sharedInstance] findBrowsersAsync];
    }];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)visibleWindows
{
    [self showAndHideIcon:nil];
    return YES;
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:PrefAutoHideIcon]) {
        [self showAndHideIcon:nil];
    }
    if ([keyPath isEqualToString:PrefStartAtLogin]) {
        [self toggleLoginItem];
    }
}

#pragma mark - "Business" Logic

- (NSArray *)browsers
{
    return [Browsers browsers];
}

- (void)selectABrowser:(id)sender
{
    NSString *newDefaultBrowser = [sender respondsToSelector:@selector(representedObject)]
        ? [sender representedObject]
        : sender;

    NSLog(@"Selecting a browser: %@", newDefaultBrowser);
    [Browsers sharedInstance].defaultBrowserIdentifier = newDefaultBrowser;
    [self performSelector:@selector(updateStatusBarIcon) withObject:nil afterDelay:0.1];

    if ([defaults boolForKey:PrefShowNotifications]) {
        [self showNotification:newDefaultBrowser];
    }
}

- (void)toggleLoginItem
{
    if ([defaults boolForKey:PrefStartAtLogin]) {
        [ZeroKitUtilities enableLoginItemForBundle:[NSBundle mainBundle]];
    } else {
        [ZeroKitUtilities disableLoginItemForBundle:[NSBundle mainBundle]];
    }
}

#pragma mark - UI

- (void)hotkeyTriggered
{
    NSLog(@"Hotkey triggered");
    if (overlayWindow.isVisible) {
        [overlayWindow close];
        return;
    }
    [overlayWindow makeKeyAndOrderFront:NSApp];
    [self showAndHideIcon:nil];
}

- (void)createStatusBarIcon
{
    NSLog(@"createStatusBarIcon");
    if (statusBarIcon != nil) {
        return;
    }
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

    statusBarIcon = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    statusBarIcon.button.toolTip = AppDescription;
    [self updateStatusBarIcon];
    statusBarIcon.menu = browserMenu;
}

- (void)updateStatusBarIcon
{
    NSString *identifier = [Browsers sharedInstance].defaultBrowserIdentifier;
    statusBarIcon.button.image = [ImageUtils statusBarIconForAppId:identifier];
    statusBarIcon.button.image.template = NO;

    if ([identifier isEqualToString:_defaultBrowser]) {
        return;
    }
    _defaultBrowser = identifier;
    [[Browsers sharedInstance] findBrowsersAsync];
}

- (void)destroyStatusBarIcon
{
    NSLog(@"destroyStatusBarIcon");
    if (![defaults boolForKey:PrefAutoHideIcon]) {
        return;
    }
    if (browserMenu.menuIsOpen) {
        [self performSelector:@selector(destroyStatusBarIcon) withObject:nil afterDelay:10];
    } else {
        [[statusBarIcon statusBar] removeStatusItem:statusBarIcon];
        statusBarIcon = nil;
    }
}

- (void)showAndHideIcon:(NSEvent *)hotKeyEvent
{
    NSLog(@"showAndHideIcon");
    [self createStatusBarIcon];
    if ([defaults boolForKey:PrefAutoHideIcon]) {
        [self performSelector:@selector(destroyStatusBarIcon) withObject:nil afterDelay:10];
    }
}

- (void)showAbout
{
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:nil];
}

- (void)doQuit
{
    [NSApp terminate:nil];
}

#pragma mark - Utilities

- (void)activateApp
{
    if (@available(macOS 14.0, *)) {
        [NSApp activate];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)showNotification:(NSString *)browserIdentifier
{
    NSURL *browserURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:browserIdentifier];
    NSString *browserName = browserURL ? [[NSFileManager defaultManager] displayNameAtPath:browserURL.path] : browserIdentifier;

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound;
    [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError *error) {
        if (!granted) {
            if (error) {
                NSLog(@"Notification authorization failed: %@", error);
            }
            return;
        }

        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = [NSString stringWithFormat:NotificationTitle, browserName];
        content.body = [NSString stringWithFormat:NotificationText, browserName, AppName];

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                              content:content
                                                                              trigger:nil];
        [center addNotificationRequest:request withCompletionHandler:^(NSError *addError) {
            if (addError) {
                NSLog(@"Failed to deliver notification: %@", addError);
            }
        }];
    }];
}

- (void)displayAreWeDefaultMsg
{
    if ([defaults boolForKey:PrefAreWeDefault]) {
        return;
    }
    if ([[[NSBundle mainBundle] bundleIdentifier] caseInsensitiveCompare:[[Browsers sharedInstance] systemDefaultBrowser]] == NSOrderedSame) {
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setShowsSuppressionButton:YES];
    [alert setMessageText:NSLocalizedString(@"Non Default Browser", @"Non Default Browser")];
    [alert setInformativeText:NSLocalizedString(@"No Default Browser Information", @"No Default Browser Information")];
    [alert addButtonWithTitle:NSLocalizedString(@"Set As Default", @"Set As Default")];
    NSButton *cancelButton = [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
    [cancelButton setKeyEquivalent:@"\e"];

    [self activateApp];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[Browsers sharedInstance] setOurselvesAsDefaultBrowser];
    }

    if (alert.suppressionButton.state == NSControlStateValueOn) {
        NSLog(@"Suppress");
        [defaults setBool:YES forKey:PrefAreWeDefault];
    }
}

#pragma mark - File Handlers

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [self openURL:[NSURL fileURLWithPath:filename]];
    return YES;
}

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls
{
    for (NSURL *url in urls) {
        [self openURL:url];
    }
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *location = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if (location.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:location];
    if (!url) {
        url = [NSURL fileURLWithPath:location];
    }
    [self openURL:url];
}

- (void)openURL:(NSURL *)url
{
    if (!url) {
        return;
    }

    NSString *identifier = [[Browsers sharedInstance] defaultBrowserIdentifier];
    NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:identifier];
    if (!appURL) {
        NSLog(@"Can't find selected browser %@. Falling back to Safari.", identifier);
        appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.apple.Safari"];
    }
    if (!appURL) {
        NSLog(@"Can't find a browser to open %@", url);
        return;
    }

    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    configuration.activates = YES;
    [[NSWorkspace sharedWorkspace] openURLs:@[url]
                       withApplicationAtURL:appURL
                              configuration:configuration
                          completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            NSLog(@"Failed to open %@ with %@: %@", url, identifier, error);
        }
    }];
}

@end
