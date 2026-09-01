#import "BrowserPattern+ObjC.h"
#include "BrowserPattern.h"

@implementation BrowserPattern

+ (BOOL)identifier:(NSString *)identifier matchesPatterns:(NSArray<NSString *> *)patterns
{
    if (identifier.length == 0 || patterns.count == 0) {
        return NO;
    }

    const char *identifierUTF8 = identifier.UTF8String;
    if (!identifierUTF8) {
        return NO;
    }

    for (NSString *pattern in patterns) {
        if (![pattern isKindOfClass:[NSString class]] || pattern.length == 0) {
            continue;
        }
        const char *patternUTF8 = pattern.UTF8String;
        if (BrowserPattern_matches(identifierUTF8, patternUTF8)) {
            return YES;
        }
    }
    return NO;
}

@end
