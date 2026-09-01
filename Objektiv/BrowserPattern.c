#include <string.h>

#include "BrowserPattern.h"

static int ascii_tolower(unsigned char c)
{
    if (c >= 'A' && c <= 'Z') {
        return c - 'A' + 'a';
    }
    return c;
}

int BrowserPattern_matches(const char *identifier, const char *pattern)
{
    size_t pattern_length;
    const char *cursor;

    if (identifier == NULL || pattern == NULL || pattern[0] == '\0') {
        return 0;
    }

    pattern_length = strlen(pattern);
    for (cursor = identifier; *cursor != '\0'; cursor++) {
        size_t i = 0;
        while (i < pattern_length &&
               cursor[i] != '\0' &&
               ascii_tolower((unsigned char)cursor[i]) == ascii_tolower((unsigned char)pattern[i])) {
            i++;
        }
        if (i == pattern_length) {
            return 1;
        }
    }
    return 0;
}

int BrowserPattern_matchesAny(const char *identifier, const char *const *patterns, size_t count)
{
    size_t i;

    if (identifier == NULL || patterns == NULL) {
        return 0;
    }

    for (i = 0; i < count; i++) {
        if (BrowserPattern_matches(identifier, patterns[i])) {
            return 1;
        }
    }
    return 0;
}
