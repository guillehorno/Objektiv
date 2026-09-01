#!/usr/bin/env bash
# Static + portable checks for the Apple Silicon / modern macOS port.
# Full app compilation requires Xcode on macOS; these gates run anywhere.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
failures=0

pass() { printf 'ok  %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "present $path"
  else
    fail "missing $path"
  fi
}

check_absent() {
  local path="$1"
  if [[ -e "$path" ]]; then
    fail "should be removed: $path"
  else
    pass "removed $path"
  fi
}

echo "== Portable unit tests =="
cc -std=c11 -Wall -Wextra -Werror -IObjektiv -c Objektiv/BrowserPattern.c -o /tmp/BrowserPattern.o
cc -std=c11 -Wall -Wextra -Werror -IObjektiv -o /tmp/test_browser_pattern tests/test_browser_pattern.c /tmp/BrowserPattern.o
/tmp/test_browser_pattern
pass "C browser-pattern tests"

echo "== Project layout =="
check_file Objektiv.xcodeproj/project.pbxproj
check_file Objektiv/Objektiv.entitlements
check_file Vendor/MASShortcut/Shortcut.h
check_file Vendor/MASShortcut/LICENSE
check_absent Sparkle.framework
check_absent Podfile
check_absent Objektiv/resources/dsa_pub.pem

echo "== Native architecture / deployment target =="
if grep -q 'ARCHS = arm64' Objektiv.xcodeproj/project.pbxproj; then
  pass "pbxproj builds arm64"
else
  fail "pbxproj does not set ARCHS = arm64"
fi
if grep -q 'MACOSX_DEPLOYMENT_TARGET = 13.0' Objektiv.xcodeproj/project.pbxproj; then
  pass "deployment target is macOS 13"
else
  fail "deployment target is not 13.0"
fi
if grep -q 'VALID_ARCHS' Objektiv.xcodeproj/project.pbxproj && grep -E 'VALID_ARCHS.*i386' Objektiv.xcodeproj/project.pbxproj; then
  fail "i386 still listed in VALID_ARCHS"
else
  pass "no i386 VALID_ARCHS"
fi

echo "== Intel-only and retired APIs =="
if grep -R --include='*.pbxproj' --include='*.m' --include='*.h' --include='*.plist' -n 'Sparkle' Objektiv Objektiv.xcodeproj Vendor >/dev/null 2>&1; then
  fail "Sparkle references remain"
else
  pass "Sparkle fully removed from app sources"
fi

if grep -R --include='*.m' --include='*.h' -E -n 'LSCopyAllHandlersForURLScheme|LSCopyDefaultHandlerForURLScheme|LSFindApplicationForInfo|LSSharedFileList|NSUserNotification([^C]|$)|SenTestingKit|CDEvents' Objektiv >/dev/null 2>&1; then
  fail "deprecated APIs still referenced in Objektiv sources"
else
  pass "retired Launch Services / notification / SenTest APIs gone"
fi

if grep -R --include='*.m' --include='*.h' --include='*.pbxproj' -E -n 'libPods-Objektiv|CocoaPods' Objektiv Objektiv.xcodeproj >/dev/null 2>&1; then
  fail "CocoaPods still wired into the project"
else
  pass "CocoaPods unplugged"
fi

echo "== Required modern APIs =="
for needle in \
  'URLsForApplicationsToOpenURL' \
  'setDefaultApplicationAtURL' \
  'SMAppService' \
  'UNUserNotificationCenter' \
  'URLForApplicationWithBundleIdentifier' \
  'NSWorkspaceOpenConfiguration'
do
  if grep -R --include='*.m' -n "$needle" Objektiv >/dev/null; then
    pass "uses $needle"
  else
    fail "missing $needle"
  fi
done

if grep -n 'com.apple.security.automation.apple-events' Objektiv/Objektiv.entitlements >/dev/null; then
  pass "Apple Events entitlement present"
else
  fail "missing Apple Events entitlement"
fi

echo "== Source files listed in Xcode project =="
missing_in_project=0
while IFS= read -r src; do
  base="$(basename "$src")"
  if ! grep -q "$base in Sources" Objektiv.xcodeproj/project.pbxproj; then
    echo "  not in pbxproj sources: $src"
    missing_in_project=$((missing_in_project + 1))
  fi
done < <(find Objektiv Vendor/MASShortcut \( -name '*.m' -o -name '*.c' \))
if [[ "$missing_in_project" -eq 0 ]]; then
  pass "all app sources are in the Xcode project"
else
  fail "$missing_in_project app source(s) missing from pbxproj"
fi

if [[ "$failures" -ne 0 ]]; then
  echo
  echo "$failures check(s) failed"
  exit 1
fi

echo
echo "All verification checks passed."
