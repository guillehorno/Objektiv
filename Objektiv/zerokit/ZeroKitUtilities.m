//
//  ZeroKitUtilities.m
//  Objektiv
//
//  Login items use SMAppService (macOS 13+) instead of the
//  deprecated session-login shared file list APIs.
//

#import "ZeroKitUtilities.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation ZeroKitUtilities

+ (void)registerDefaultsForBundle:(NSBundle *)bundle
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [bundle pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *applicationDefaults = [NSDictionary dictionaryWithContentsOfFile:path];
    if (applicationDefaults) {
        [defaults registerDefaults:applicationDefaults];
    }
}

+ (void)enableLoginItemForBundle:(NSBundle *)bundle
{
    (void)bundle;
    NSError *error = nil;
    if (![[SMAppService mainAppService] registerAndReturnError:&error]) {
        NSLog(@"Unable to register login item: %@", error);
    }
}

+ (void)disableLoginItemForBundle:(NSBundle *)bundle
{
    (void)bundle;
    NSError *error = nil;
    if (![[SMAppService mainAppService] unregisterAndReturnError:&error]) {
        NSLog(@"Unable to unregister login item: %@", error);
    }
}

+ (BOOL)loginItemEnabled
{
    return [SMAppService mainAppService].status == SMAppServiceStatusEnabled;
}

@end
