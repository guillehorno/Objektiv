#ifndef BrowserPattern_h
#define BrowserPattern_h

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Returns 1 when `identifier` contains `pattern`, matching Objektiv's historical
 * blacklist behavior (substring match so prefixes like "com.evernote" work). */
int BrowserPattern_matches(const char *identifier, const char *pattern);

int BrowserPattern_matchesAny(const char *identifier, const char *const *patterns, size_t count);

#ifdef __cplusplus
}
#endif

#endif /* BrowserPattern_h */
