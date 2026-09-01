#import <Foundation/Foundation.h>

@interface BrowserPattern : NSObject

+ (BOOL)identifier:(NSString *)identifier matchesPatterns:(NSArray<NSString *> *)patterns;

@end
