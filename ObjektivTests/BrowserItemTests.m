#import <XCTest/XCTest.h>
#import "BrowserItem.h"

@interface BrowserItemTests : XCTestCase
@end

@implementation BrowserItemTests

- (void)testInitializerStoresIdentity
{
    BrowserItem *item = [[BrowserItem alloc] initWithApplicationId:@"com.apple.Safari"
                                                             name:@"Safari"
                                                             path:@"/Applications/Safari.app"];
    XCTAssertEqualObjects(item.identifier, @"com.apple.Safari");
    XCTAssertEqualObjects(item.name, @"Safari");
    XCTAssertEqualObjects(item.path, @"/Applications/Safari.app");
    XCTAssertFalse(item.hidden);
    XCTAssertFalse(item.isDefault);
}

- (void)testDescriptionIncludesHiddenFlag
{
    BrowserItem *item = [[BrowserItem alloc] initWithApplicationId:@"com.google.Chrome"
                                                             name:@"Chrome"
                                                             path:@"/Applications/Google Chrome.app"];
    item.hidden = YES;
    item.isDefault = YES;
    NSString *description = item.description;
    XCTAssertTrue([description containsString:@"com.google.Chrome"]);
    XCTAssertTrue([description containsString:@"Chrome"]);
    XCTAssertTrue([description containsString:@"hidden:YES"]);
}

@end
