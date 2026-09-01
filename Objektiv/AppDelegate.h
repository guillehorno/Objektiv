//
//  AppDelegate.h
//  Objektiv
//
//  Created by Ankit Solanki on 01/11/12.
//  Copyright (c) 2012 nth loop. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (void)hotkeyTriggered;
- (void)selectABrowser:(id)sender;
- (void)updateStatusBarIcon;

@property (strong) PrefsController *prefsController;

@end
