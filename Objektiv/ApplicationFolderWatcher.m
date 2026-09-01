#import "ApplicationFolderWatcher.h"
#import <CoreServices/CoreServices.h>

@interface ApplicationFolderWatcher ()
- (void)noteChange;
@end

static void ApplicationFolderWatcherCallback(ConstFSEventStreamRef streamRef,
                                             void *clientCallBackInfo,
                                             size_t numEvents,
                                             void *eventPaths,
                                             const FSEventStreamEventFlags eventFlags[],
                                             const FSEventStreamEventId eventIds[])
{
    ApplicationFolderWatcher *watcher = (__bridge ApplicationFolderWatcher *)clientCallBackInfo;
    [watcher noteChange];
}

@implementation ApplicationFolderWatcher {
    FSEventStreamRef _stream;
    void (^_handler)(void);
}

- (instancetype)initWithDirectories:(NSArray<NSString *> *)paths handler:(void (^)(void))handler
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _handler = [handler copy];

    NSMutableArray<NSString *> *existingPaths = [NSMutableArray array];
    for (NSString *path in paths) {
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [existingPaths addObject:path];
        }
    }
    if (existingPaths.count == 0) {
        return self;
    }

    FSEventStreamContext context = {
        .version = 0,
        .info = (__bridge void *)self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };

    _stream = FSEventStreamCreate(kCFAllocatorDefault,
                                  &ApplicationFolderWatcherCallback,
                                  &context,
                                  (__bridge CFArrayRef)existingPaths,
                                  kFSEventStreamEventIdSinceNow,
                                  1.0,
                                  kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf);
    if (_stream) {
        FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        FSEventStreamStart(_stream);
    }
    return self;
}

- (void)noteChange
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireHandler) object:nil];
    [self performSelector:@selector(fireHandler) withObject:nil afterDelay:1.0];
}

- (void)fireHandler
{
    if (_handler) {
        _handler();
    }
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (_stream) {
        FSEventStreamStop(_stream);
        FSEventStreamInvalidate(_stream);
        FSEventStreamRelease(_stream);
        _stream = NULL;
    }
}

@end
