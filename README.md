Objektiv
========================================

![Objektiv Logo][logo] Objektiv is a menu-bar utility that lets you switch
your default browser instantly. You might find it useful if you are a web
designer or use multiple browsers in your workflow.

This fork is a **native Apple Silicon** port for current macOS. The last
Intel-only release depended on Rosetta 2 (and an Intel Sparkle framework).
Apple no longer supports that translation layer on the latest system, so this
tree builds `arm64` only, targets **macOS 13 Ventura and later**, and uses
current Launch Services, login-item, and notification APIs.

Requirements
----------------------------------------

- An Apple Silicon Mac
- macOS 13 or later
- Xcode 15 or later to build from source

Install
----------------------------------------

1. Open `Objektiv.xcodeproj` (or `Objektiv.xcworkspace`) in Xcode on a Mac.
2. Select the **Objektiv** scheme and an **Any Mac (Apple Silicon)** or your
   connected Mac destination.
3. Product → Build, then run or copy `Objektiv.app` to `/Applications`.
4. Set Objektiv as your default web browser in
   **System Settings → Desktop & Dock → Default web browser**.

Objektiv does not silently replace Safari/Chrome as the system default. It
*is* the default browser, then forwards each link to whichever real browser
you last selected in the menu bar or overlay.

The old Homebrew cask (`brew install --cask objektiv`) shipped the Intel
binary and is disabled. Use a local Xcode build from this repository instead.

Features
----------------------------------------

 - A status-bar icon for quick access
 - An optional global hotkey triggers an overlay window for even quicker
   switching
 - Pressing Option (⌥) in the status menu lets you hide browsers that
   are incorrectly detected

![Screenshot of the Objektiv overlay window](Objektiv/en.lproj/objektiv-overlay.png)

Building
----------------------------------------

CocoaPods is no longer required. MASShortcut is vendored under
`Vendor/MASShortcut`. Sparkle auto-update is removed (the original feed is
gone, and the bundled framework was Intel-only).

```bash
# Portable checks (Linux or macOS)
./scripts/verify.sh

# On macOS with Xcode
xcodebuild -scheme Objektiv -configuration Release -arch arm64 build
xcodebuild -scheme Objektiv -configuration Debug test
```

If Gatekeeper blocks a local build, ad-hoc signing is already enabled
(`CODE_SIGN_IDENTITY = "-"`). For distribution, sign with your Developer ID
and notarize.

Port notes
----------------------------------------

- Architecture: `arm64` only (no Rosetta)
- Deployment target: macOS 13 (needed for `SMAppService` login items)
- Browser discovery / default-handler APIs: `NSWorkspace` methods introduced
  in macOS 12+
- Notifications: UserNotifications
- Application-folder watching: FSEvents (replaces CDEvents)

Copyright & About
----------------------------------------

Objektiv was built by the former web development company *nth loop* to solve
a problem they were facing and to learn all about developing Mac Apps.
It might be ridiculously over-engineered for such a simple utility.

Copyright 2012, [nth loop][]. Objektiv is available under the MIT
License.

Contributors
----------------------------------------

* [Anks](https://github.com/Anks), original developer
* [xrivatsan](https://github.com/xrivatsan), original developer
* [Vorror](https://github.com/Vorror), major bugfixes and making the tool work with present-day macOS

Credits
----------------------------------------

  - [ZeroKit][] by eczarny (MIT Licensed, portions of source used)
  - [MASShortcut][] by Vadim Shpakovski (BSD Licensed)
  - [NSWorkspace+Utils][1] from Mozilla's Camino project (MPL)

  [logo]:        Objektiv/Objektiv.iconset/icon_128x128.png
  [nth loop]:    http://nthloop.com
  [ZeroKit]:     https://github.com/eczarny/zerokit
  [MASShortcut]: https://github.com/shpakovski/MASShortcut
  [1]:           http://hg.mozilla.org/camino/file/6d654a6d1cf4/src/extensions/NSWorkspace%2BUtils.h
