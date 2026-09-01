#import <XCTest/XCTest.h>
#include "BrowserPattern.h"
#import "BrowserPattern+ObjC.h"

@interface BrowserPatternTests : XCTestCase
@end

@implementation BrowserPatternTests

- (void)testExactBundleIdentifierMatch
{
    XCTAssertTrue(BrowserPattern_matches("com.nthloop.Objektiv", "com.nthloop.Objektiv"));
}

- (void)testBlacklistMatchIsCaseInsensitive
{
    XCTAssertTrue(BrowserPattern_matches("com.nthloop.Objektiv", "com.nthloop.objektiv"));
}

- (void)testPrefixPatternMatchesEvernoteStyleIdentifiers
{
    XCTAssertTrue(BrowserPattern_matches("com.evernote.Evernote", "com.evernote"));
}

- (void)testUnrelatedIdentifierDoesNotMatch
{
    XCTAssertFalse(BrowserPattern_matches("com.apple.Safari", "com.google.Chrome"));
}

- (void)testEmptyAndNullInputsDoNotMatch
{
    XCTAssertFalse(BrowserPattern_matches("com.apple.Safari", ""));
    XCTAssertFalse(BrowserPattern_matches(NULL, "com.apple.Safari"));
    XCTAssertFalse(BrowserPattern_matches("com.apple.Safari", NULL));
}

- (void)testMatchesAnyScansTheList
{
    const char *patterns[] = { "com.fluidapp", "com.nthloop.objektiv" };
    XCTAssertTrue(BrowserPattern_matchesAny("com.nthloop.objektiv", patterns, 2));
    XCTAssertFalse(BrowserPattern_matchesAny("com.apple.Safari", patterns, 2));
    XCTAssertFalse(BrowserPattern_matchesAny("com.apple.Safari", NULL, 0));
}

- (void)testObjCWrapperMatchesHistoricalBlacklistBehavior
{
    NSArray *blacklist = @[@"com.evernote", @"com.nthloop.objektiv"];
    XCTAssertTrue([BrowserPattern identifier:@"com.evernote.Evernote" matchesPatterns:blacklist]);
    XCTAssertTrue([BrowserPattern identifier:@"com.nthloop.objektiv" matchesPatterns:blacklist]);
    XCTAssertFalse([BrowserPattern identifier:@"com.apple.Safari" matchesPatterns:blacklist]);
    XCTAssertFalse([BrowserPattern identifier:@"com.apple.Safari" matchesPatterns:@[]]);
    XCTAssertFalse([BrowserPattern identifier:nil matchesPatterns:blacklist]);
}

@end
