#include "BrowserPattern.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

static void test_exact_match(void)
{
    assert(BrowserPattern_matches("com.nthloop.Objektiv", "com.nthloop.Objektiv"));
}

static void test_prefix_blacklist(void)
{
    assert(BrowserPattern_matches("com.evernote.Evernote", "com.evernote"));
    assert(BrowserPattern_matches("com.parallels.winapp.ie", "com.parallels.winapp"));
}

static void test_self_blacklist(void)
{
    assert(BrowserPattern_matches("com.nthloop.objektiv", "com.nthloop.objektiv"));
    assert(BrowserPattern_matches("com.nthloop.Objektiv", "com.nthloop.objektiv"));
}

static void test_non_match(void)
{
    assert(!BrowserPattern_matches("com.apple.Safari", "com.google.Chrome"));
    assert(!BrowserPattern_matches("com.apple.Safari", "com.nthloop.objektiv"));
}

static void test_empty_and_null(void)
{
    assert(!BrowserPattern_matches(NULL, "x"));
    assert(!BrowserPattern_matches("x", NULL));
    assert(!BrowserPattern_matches("x", ""));
    assert(!BrowserPattern_matches("", "x"));
}

static void test_matches_any(void)
{
    const char *patterns[] = {
        "com.evernote",
        "com.parallels.winapp",
        "com.googlecode.iterm",
        "com.fluidapp",
        "com.nthloop.objektiv"
    };
    assert(BrowserPattern_matchesAny("com.fluidapp.FluidApp", patterns, 5));
    assert(BrowserPattern_matchesAny("com.nthloop.objektiv", patterns, 5));
    assert(!BrowserPattern_matchesAny("com.apple.Safari", patterns, 5));
    assert(!BrowserPattern_matchesAny("com.google.Chrome", patterns, 5));
    assert(!BrowserPattern_matchesAny(NULL, patterns, 5));
    assert(!BrowserPattern_matchesAny("com.apple.Safari", NULL, 5));
}

int main(void)
{
    test_exact_match();
    test_prefix_blacklist();
    test_self_blacklist();
    test_non_match();
    test_empty_and_null();
    test_matches_any();
    puts("browser_pattern_tests: ok");
    return 0;
}
