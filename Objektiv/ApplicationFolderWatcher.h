#import <Foundation/Foundation.h>

@interface ApplicationFolderWatcher : NSObject

- (instancetype)initWithDirectories:(NSArray<NSString *> *)paths
                            handler:(void (^)(void))handler;

@end
