#!/usr/bin/env python3
"""Generate a modern Xcode project for the Apple Silicon Objektiv port."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path("/workspace")
OUT = ROOT / "Objektiv.xcodeproj" / "project.pbxproj"


def uid(name: str) -> str:
    return hashlib.md5(name.encode("utf-8")).hexdigest()[:24].upper()


ARC_SOURCES = [
    "Objektiv/main.m",
    "Objektiv/AppDelegate.m",
    "Objektiv/BrowserItem.m",
    "Objektiv/Browsers.m",
    "Objektiv/ImageUtils.m",
    "Objektiv/BrowsersMenu.m",
    "Objektiv/PrefsController.m",
    "Objektiv/OverlayWindow.m",
    "Objektiv/OverlayWindowView.m",
    "Objektiv/BrowserPattern.c",
    "Objektiv/BrowserPattern+ObjC.m",
    "Objektiv/ApplicationFolderWatcher.m",
    "Objektiv/mozilla/NSWorkspace+Utils.m",
    "Objektiv/zerokit/ZeroKitUtilities.m",
    "Vendor/MASShortcut/MASShortcut.m",
    "Vendor/MASShortcut/MASShortcutValidator.m",
    "Vendor/MASShortcut/MASHotKey.m",
    "Vendor/MASShortcut/MASShortcutMonitor.m",
    "Vendor/MASShortcut/MASLocalization.m",
    "Vendor/MASShortcut/MASShortcutView+Bindings.m",
    "Vendor/MASShortcut/MASShortcutViewButtonCell.m",
    "Vendor/MASShortcut/MASShortcutView.m",
    "Vendor/MASShortcut/MASDictionaryTransformer.m",
    "Vendor/MASShortcut/MASShortcutBinder.m",
]

MRC_SOURCES = [
    "Objektiv/potionfactory/PFMoveApplication.m",
    "Objektiv/potionfactory/NSString+SymlinksAndAliases.m",
]

HEADERS = [
    "Objektiv/AppDelegate.h",
    "Objektiv/BrowserItem.h",
    "Objektiv/Browsers.h",
    "Objektiv/ImageUtils.h",
    "Objektiv/BrowsersMenu.h",
    "Objektiv/PrefsController.h",
    "Objektiv/OverlayWindow.h",
    "Objektiv/OverlayWindowView.h",
    "Objektiv/BrowserPattern.h",
    "Objektiv/BrowserPattern+ObjC.h",
    "Objektiv/ApplicationFolderWatcher.h",
    "Objektiv/Constants.h",
    "Objektiv/Objektiv-Prefix.pch",
    "Objektiv/mozilla/NSWorkspace+Utils.h",
    "Objektiv/zerokit/ZeroKitUtilities.h",
    "Objektiv/potionfactory/PFMoveApplication.h",
    "Objektiv/potionfactory/NSString+SymlinksAndAliases.h",
    "Vendor/MASShortcut/Shortcut.h",
    "Vendor/MASShortcut/MASKeyCodes.h",
    "Vendor/MASShortcut/MASShortcut.h",
    "Vendor/MASShortcut/MASShortcutValidator.h",
    "Vendor/MASShortcut/MASHotKey.h",
    "Vendor/MASShortcut/MASShortcutMonitor.h",
    "Vendor/MASShortcut/MASLocalization.h",
    "Vendor/MASShortcut/MASShortcutView+Bindings.h",
    "Vendor/MASShortcut/MASShortcutViewButtonCell.h",
    "Vendor/MASShortcut/MASShortcutView.h",
    "Vendor/MASShortcut/MASDictionaryTransformer.h",
    "Vendor/MASShortcut/MASShortcutBinder.h",
    "Vendor/MASShortcut/LICENSE",
]

RESOURCES = [
    ("Objektiv/PrefsController.xib", "file.xib"),
    ("Objektiv/MainMenu.nib", "wrapper.nib"),
    ("Objektiv/en.lproj/Defaults.plist", "text.plist.xml"),
    ("Objektiv/en.lproj/Blacklist.plist", "text.plist.xml"),
    ("Objektiv/en.lproj/Localizable.strings", "text.plist.strings"),
    ("Objektiv/en.lproj/InfoPlist.strings", "text.plist.strings"),
    ("Objektiv/en.lproj/Credits.rtf", "text.rtf"),
    ("Objektiv/en.lproj/MoveApplication.strings", "text.plist.strings"),
    ("Objektiv/en.lproj/objektiv-overlay.png", "image.png"),
    ("Objektiv/Objektiv.iconset", "folder.iconset"),
]

TEST_SOURCES = [
    "ObjektivTests/BrowserPatternTests.m",
    "ObjektivTests/BrowserItemTests.m",
    "Objektiv/BrowserPattern.c",
    "Objektiv/BrowserPattern+ObjC.m",
    "Objektiv/BrowserItem.m",
]

FRAMEWORKS = [
    "Cocoa",
    "QuartzCore",
    "Carbon",
    "Security",
    "ServiceManagement",
    "UserNotifications",
    "UniformTypeIdentifiers",
    "CoreServices",
]


def file_type_for_source(path: str) -> str:
    if path.endswith(".c"):
        return "sourcecode.c.c"
    return "sourcecode.c.objc"


def basename(path: str) -> str:
    return Path(path).name


lines: list[str] = []
build_files: dict[str, str] = {}
file_refs: dict[str, str] = {}

# IDs
project_id = uid("project")
app_target = uid("target:Objektiv")
test_target = uid("target:ObjektivTests")
app_product = uid("product:Objektiv.app")
test_product = uid("product:ObjektivTests.xctest")
main_group = uid("group:/")
products_group = uid("group:Products")
frameworks_group = uid("group:Frameworks")
app_group = uid("group:Objektiv")
vendor_group = uid("group:Vendor")
mass_group = uid("group:MASShortcut")
tests_group = uid("group:ObjektivTests")
supporting_group = uid("group:Supporting")
source_group = uid("group:source")
models_group = uid("group:models")
ui_group = uid("group:ui")
mozilla_group = uid("group:mozilla")
zerokit_group = uid("group:zerokit")
potion_group = uid("group:potionfactory")

app_sources_phase = uid("phase:app-sources")
app_frameworks_phase = uid("phase:app-frameworks")
app_resources_phase = uid("phase:app-resources")
test_sources_phase = uid("phase:test-sources")
test_frameworks_phase = uid("phase:test-frameworks")

project_cfg_list = uid("cfglist:project")
app_cfg_list = uid("cfglist:app")
test_cfg_list = uid("cfglist:test")
project_debug = uid("cfg:project-debug")
project_release = uid("cfg:project-release")
app_debug = uid("cfg:app-debug")
app_release = uid("cfg:app-release")
test_debug = uid("cfg:test-debug")
test_release = uid("cfg:test-release")

info_plist_ref = uid("ref:Objektiv-Info.plist")
entitlements_ref = uid("ref:Objektiv.entitlements")
file_refs["Objektiv/Objektiv-Info.plist"] = info_plist_ref
file_refs["Objektiv/Objektiv.entitlements"] = entitlements_ref

for path in ARC_SOURCES + MRC_SOURCES + HEADERS + TEST_SOURCES:
    file_refs[path] = uid(f"ref:{path}")

for path, _ in RESOURCES:
    file_refs[path] = uid(f"ref:{path}")

for name in FRAMEWORKS:
    file_refs[f"framework:{name}"] = uid(f"ref:framework:{name}")

for path in ARC_SOURCES + MRC_SOURCES:
    build_files[f"app:{path}"] = uid(f"bf:app:{path}")
for path, _ in RESOURCES:
    build_files[f"res:{path}"] = uid(f"bf:res:{path}")
for name in FRAMEWORKS:
    build_files[f"fw:{name}"] = uid(f"bf:fw:{name}")
for path in TEST_SOURCES:
    build_files[f"test:{path}"] = uid(f"bf:test:{path}")

# Cocoa is needed in the test bundle too for BrowserItem
build_files["test-fw:Cocoa"] = uid("bf:test-fw:Cocoa")

PBX = []
PBX.append("// !$*UTF8*$!")
PBX.append("{")
PBX.append("\tarchiveVersion = 1;")
PBX.append("\tclasses = {")
PBX.append("\t};")
PBX.append("\tobjectVersion = 56;")
PBX.append("\tobjects = {")
PBX.append("")
PBX.append("/* Begin PBXBuildFile section */")
for path in ARC_SOURCES + MRC_SOURCES:
    settings = ""
    if path in MRC_SOURCES:
        settings = " settings = {COMPILER_FLAGS = \"-fno-objc-arc\"; };"
    PBX.append(
        f"\t\t{build_files[f'app:{path}']} /* {basename(path)} in Sources */ = "
        f"{{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {basename(path)} */;{settings} }};"
    )
for path, _ in RESOURCES:
    PBX.append(
        f"\t\t{build_files[f'res:{path}']} /* {basename(path)} in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {basename(path)} */; }};"
    )
for name in FRAMEWORKS:
    PBX.append(
        f"\t\t{build_files[f'fw:{name}']} /* {name}.framework in Frameworks */ = "
        f"{{isa = PBXBuildFile; fileRef = {file_refs[f'framework:{name}']} /* {name}.framework */; }};"
    )
for path in TEST_SOURCES:
    PBX.append(
        f"\t\t{build_files[f'test:{path}']} /* {basename(path)} in Sources */ = "
        f"{{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {basename(path)} */; }};"
    )
PBX.append(
    f"\t\t{build_files['test-fw:Cocoa']} /* Cocoa.framework in Frameworks */ = "
    f"{{isa = PBXBuildFile; fileRef = {file_refs['framework:Cocoa']} /* Cocoa.framework */; }};"
)
PBX.append("/* End PBXBuildFile section */")
PBX.append("")
PBX.append("/* Begin PBXFileReference section */")
PBX.append(
    f"\t\t{app_product} /* Objektiv.app */ = "
    "{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Objektiv.app; sourceTree = BUILT_PRODUCTS_DIR; };"
)
PBX.append(
    f"\t\t{test_product} /* ObjektivTests.xctest */ = "
    "{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ObjektivTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };"
)
PBX.append(
    f"\t\t{info_plist_ref} /* Objektiv-Info.plist */ = "
    "{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"Objektiv-Info.plist\"; sourceTree = \"<group>\"; };"
)
PBX.append(
    f"\t\t{entitlements_ref} /* Objektiv.entitlements */ = "
    "{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Objektiv.entitlements; sourceTree = \"<group>\"; };"
)

seen_refs = {info_plist_ref, entitlements_ref}
for path in ARC_SOURCES + MRC_SOURCES + HEADERS + TEST_SOURCES:
    ref = file_refs[path]
    if ref in seen_refs:
        continue
    seen_refs.add(ref)
    ftype = file_type_for_source(path) if path.endswith((".m", ".c")) else (
        "text" if path.endswith("LICENSE") else "sourcecode.c.h"
    )
    if path.startswith("ObjektivTests/"):
        group_path = basename(path)
        PBX.append(
            f"\t\t{ref} /* {basename(path)} */ = "
            f"{{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{group_path}\"; sourceTree = \"<group>\"; }};"
        )
    elif path.startswith("Vendor/MASShortcut/"):
        PBX.append(
            f"\t\t{ref} /* {basename(path)} */ = "
            f"{{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{basename(path)}\"; sourceTree = \"<group>\"; }};"
        )
    else:
        # Keep relative path from Objektiv group when nested
        rel = path[len("Objektiv/") :] if path.startswith("Objektiv/") else basename(path)
        # Nested groups will use just the filename
        name = basename(path)
        PBX.append(
            f"\t\t{ref} /* {name} */ = "
            f"{{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{name}\"; sourceTree = \"<group>\"; }};"
        )

for path, ftype in RESOURCES:
    ref = file_refs[path]
    name = basename(path)
    PBX.append(
        f"\t\t{ref} /* {name} */ = "
        f"{{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{name}\"; sourceTree = \"<group>\"; }};"
    )

for name in FRAMEWORKS:
    PBX.append(
        f"\t\t{file_refs[f'framework:{name}']} /* {name}.framework */ = "
        f"{{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {name}.framework; "
        f"path = System/Library/Frameworks/{name}.framework; sourceTree = SDKROOT; }};"
    )
PBX.append("/* End PBXFileReference section */")
PBX.append("")

PBX.append("/* Begin PBXFrameworksBuildPhase section */")
PBX.append(f"\t\t{app_frameworks_phase} /* Frameworks */ = {{")
PBX.append("\t\t\tisa = PBXFrameworksBuildPhase;")
PBX.append("\t\t\tbuildActionMask = 2147483647;")
PBX.append("\t\t\tfiles = (")
for name in FRAMEWORKS:
    PBX.append(f"\t\t\t\t{build_files[f'fw:{name}']} /* {name}.framework in Frameworks */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
PBX.append("\t\t};")
PBX.append(f"\t\t{test_frameworks_phase} /* Frameworks */ = {{")
PBX.append("\t\t\tisa = PBXFrameworksBuildPhase;")
PBX.append("\t\t\tbuildActionMask = 2147483647;")
PBX.append("\t\t\tfiles = (")
PBX.append(f"\t\t\t\t{build_files['test-fw:Cocoa']} /* Cocoa.framework in Frameworks */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
PBX.append("\t\t};")
PBX.append("/* End PBXFrameworksBuildPhase section */")
PBX.append("")

# Groups
def refs_csv(paths):
    out = []
    for path in paths:
        out.append(f"\t\t\t\t{file_refs[path]} /* {basename(path)} */,")
    return "\n".join(out)

PBX.append("/* Begin PBXGroup section */")
PBX.append(f"\t\t{main_group} = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(f"\t\t\t\t{app_group} /* Objektiv */,")
PBX.append(f"\t\t\t\t{tests_group} /* ObjektivTests */,")
PBX.append(f"\t\t\t\t{vendor_group} /* Vendor */,")
PBX.append(f"\t\t\t\t{frameworks_group} /* Frameworks */,")
PBX.append(f"\t\t\t\t{products_group} /* Products */,")
PBX.append("\t\t\t);")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{products_group} /* Products */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(f"\t\t\t\t{app_product} /* Objektiv.app */,")
PBX.append(f"\t\t\t\t{test_product} /* ObjektivTests.xctest */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = Products;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{frameworks_group} /* Frameworks */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
for name in FRAMEWORKS:
    PBX.append(f"\t\t\t\t{file_refs[f'framework:{name}']} /* {name}.framework */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = Frameworks;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{app_group} /* Objektiv */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(f"\t\t\t\t{source_group} /* source */,")
PBX.append(f"\t\t\t\t{mozilla_group} /* mozilla */,")
PBX.append(f"\t\t\t\t{zerokit_group} /* zerokit */,")
PBX.append(f"\t\t\t\t{potion_group} /* potionfactory */,")
PBX.append(f"\t\t\t\t{supporting_group} /* Supporting Files */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tpath = Objektiv;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

source_files = [
    "Objektiv/main.m",
    "Objektiv/AppDelegate.h",
    "Objektiv/AppDelegate.m",
    "Objektiv/Constants.h",
    "Objektiv/BrowserPattern.h",
    "Objektiv/BrowserPattern.c",
    "Objektiv/BrowserPattern+ObjC.h",
    "Objektiv/BrowserPattern+ObjC.m",
    "Objektiv/ApplicationFolderWatcher.h",
    "Objektiv/ApplicationFolderWatcher.m",
    "Objektiv/BrowserItem.h",
    "Objektiv/BrowserItem.m",
    "Objektiv/Browsers.h",
    "Objektiv/Browsers.m",
    "Objektiv/ImageUtils.h",
    "Objektiv/ImageUtils.m",
    "Objektiv/BrowsersMenu.h",
    "Objektiv/BrowsersMenu.m",
    "Objektiv/PrefsController.h",
    "Objektiv/PrefsController.m",
    "Objektiv/PrefsController.xib",
    "Objektiv/OverlayWindow.h",
    "Objektiv/OverlayWindow.m",
    "Objektiv/OverlayWindowView.h",
    "Objektiv/OverlayWindowView.m",
]
# resources listed separately - PrefsController.xib is in source/ui originally
# I'll put xib in supporting

source_files = [p for p in source_files if not p.endswith(".xib")]

PBX.append(f"\t\t{source_group} /* source */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv(source_files))
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = source;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{mozilla_group} /* mozilla */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv(["Objektiv/mozilla/NSWorkspace+Utils.h", "Objektiv/mozilla/NSWorkspace+Utils.m"]))
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = mozilla;")
PBX.append("\t\t\tpath = mozilla;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{zerokit_group} /* zerokit */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv(["Objektiv/zerokit/ZeroKitUtilities.h", "Objektiv/zerokit/ZeroKitUtilities.m"]))
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = zerokit;")
PBX.append("\t\t\tpath = zerokit;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{potion_group} /* potionfactory */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv([
    "Objektiv/potionfactory/PFMoveApplication.h",
    "Objektiv/potionfactory/PFMoveApplication.m",
    "Objektiv/potionfactory/NSString+SymlinksAndAliases.h",
    "Objektiv/potionfactory/NSString+SymlinksAndAliases.m",
]))
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = potionfactory;")
PBX.append("\t\t\tpath = potionfactory;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

supporting = [
    "Objektiv/Objektiv-Info.plist",
    "Objektiv/Objektiv.entitlements",
    "Objektiv/Objektiv-Prefix.pch",
    "Objektiv/PrefsController.xib",
    "Objektiv/MainMenu.nib",
    "Objektiv/Objektiv.iconset",
    "Objektiv/en.lproj/Defaults.plist",
    "Objektiv/en.lproj/Blacklist.plist",
    "Objektiv/en.lproj/Localizable.strings",
    "Objektiv/en.lproj/InfoPlist.strings",
    "Objektiv/en.lproj/Credits.rtf",
    "Objektiv/en.lproj/MoveApplication.strings",
    "Objektiv/en.lproj/objektiv-overlay.png",
]
PBX.append(f"\t\t{supporting_group} /* Supporting Files */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv(supporting))
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = \"Supporting Files\";")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

# Localized resources live in en.lproj on disk but we referenced them by basename
# with sourceTree group. That only works if the group path includes en.lproj.
# Fix: set path on supporting files that are in en.lproj via file ref path.

# Actually file refs for resources used path = basename only, and supporting group
# has no path (it's inside Objektiv group which has path=Objektiv). So Xcode looks
# for Objektiv/Localizable.strings which is WRONG.

# Fix file refs for en.lproj files to path = en.lproj/Name

PBX.append(f"\t\t{vendor_group} /* Vendor */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(f"\t\t\t\t{mass_group} /* MASShortcut */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tpath = Vendor;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

mass_files = [p for p in ARC_SOURCES + HEADERS if p.startswith("Vendor/MASShortcut/")]
PBX.append(f"\t\t{mass_group} /* MASShortcut */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv(mass_files))
PBX.append("\t\t\t);")
PBX.append("\t\t\tpath = MASShortcut;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")

PBX.append(f"\t\t{tests_group} /* ObjektivTests */ = {{")
PBX.append("\t\t\tisa = PBXGroup;")
PBX.append("\t\t\tchildren = (")
PBX.append(refs_csv(["ObjektivTests/BrowserPatternTests.m", "ObjektivTests/BrowserItemTests.m"]))
PBX.append("\t\t\t);")
PBX.append("\t\t\tpath = ObjektivTests;")
PBX.append('\t\t\tsourceTree = "<group>";')
PBX.append("\t\t};")
PBX.append("/* End PBXGroup section */")
PBX.append("")

PBX.append("/* Begin PBXNativeTarget section */")
PBX.append(f"\t\t{app_target} /* Objektiv */ = {{")
PBX.append("\t\t\tisa = PBXNativeTarget;")
PBX.append(f"\t\t\tbuildConfigurationList = {app_cfg_list} /* Build configuration list for PBXNativeTarget \"Objektiv\" */;")
PBX.append("\t\t\tbuildPhases = (")
PBX.append(f"\t\t\t\t{app_sources_phase} /* Sources */,")
PBX.append(f"\t\t\t\t{app_frameworks_phase} /* Frameworks */,")
PBX.append(f"\t\t\t\t{app_resources_phase} /* Resources */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tbuildRules = (")
PBX.append("\t\t\t);")
PBX.append("\t\t\tdependencies = (")
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = Objektiv;")
PBX.append("\t\t\tproductName = Objektiv;")
PBX.append(f"\t\t\tproductReference = {app_product} /* Objektiv.app */;")
PBX.append('\t\t\tproductType = "com.apple.product-type.application";')
PBX.append("\t\t};")
PBX.append(f"\t\t{test_target} /* ObjektivTests */ = {{")
PBX.append("\t\t\tisa = PBXNativeTarget;")
PBX.append(f"\t\t\tbuildConfigurationList = {test_cfg_list} /* Build configuration list for PBXNativeTarget \"ObjektivTests\" */;")
PBX.append("\t\t\tbuildPhases = (")
PBX.append(f"\t\t\t\t{test_sources_phase} /* Sources */,")
PBX.append(f"\t\t\t\t{test_frameworks_phase} /* Frameworks */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tbuildRules = (")
PBX.append("\t\t\t);")
PBX.append("\t\t\tdependencies = (")
PBX.append("\t\t\t);")
PBX.append("\t\t\tname = ObjektivTests;")
PBX.append("\t\t\tproductName = ObjektivTests;")
PBX.append(f"\t\t\tproductReference = {test_product} /* ObjektivTests.xctest */;")
PBX.append('\t\t\tproductType = "com.apple.product-type.bundle.unit-test";')
PBX.append("\t\t};")
PBX.append("/* End PBXNativeTarget section */")
PBX.append("")

PBX.append("/* Begin PBXProject section */")
PBX.append(f"\t\t{project_id} /* Project object */ = {{")
PBX.append("\t\t\tisa = PBXProject;")
PBX.append("\t\t\tattributes = {")
PBX.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
PBX.append("\t\t\t\tLastUpgradeCheck = 1500;")
PBX.append('\t\t\t\tORGANIZATIONNAME = "nth loop";')
PBX.append("\t\t\t\tTargetAttributes = {")
PBX.append(f"\t\t\t\t\t{app_target} = {{")
PBX.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
PBX.append("\t\t\t\t\t};")
PBX.append(f"\t\t\t\t\t{test_target} = {{")
PBX.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
PBX.append("\t\t\t\t\t};")
PBX.append("\t\t\t\t};")
PBX.append("\t\t\t};")
PBX.append(f"\t\t\tbuildConfigurationList = {project_cfg_list} /* Build configuration list for PBXProject \"Objektiv\" */;")
PBX.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
PBX.append('\t\t\tdevelopmentRegion = en; /* pragma: allowlist secret */')  # pragma: allowlist secret
PBX.append("\t\t\thasScannedForEncodings = 0;")
PBX.append("\t\t\tknownRegions = (")
PBX.append("\t\t\t\ten,")
PBX.append("\t\t\t\tBase,")
PBX.append("\t\t\t);")
PBX.append(f"\t\t\tmainGroup = {main_group};")
PBX.append(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
PBX.append('\t\t\tprojectDirPath = "";')
PBX.append('\t\t\tprojectRoot = "";')
PBX.append("\t\t\ttargets = (")
PBX.append(f"\t\t\t\t{app_target} /* Objektiv */,")
PBX.append(f"\t\t\t\t{test_target} /* ObjektivTests */,")
PBX.append("\t\t\t);")
PBX.append("\t\t};")
PBX.append("/* End PBXProject section */")
PBX.append("")

PBX.append("/* Begin PBXResourcesBuildPhase section */")
PBX.append(f"\t\t{app_resources_phase} /* Resources */ = {{")
PBX.append("\t\t\tisa = PBXResourcesBuildPhase;")
PBX.append("\t\t\tbuildActionMask = 2147483647;")
PBX.append("\t\t\tfiles = (")
for path, _ in RESOURCES:
    PBX.append(f"\t\t\t\t{build_files[f'res:{path}']} /* {basename(path)} in Resources */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
PBX.append("\t\t};")
PBX.append("/* End PBXResourcesBuildPhase section */")
PBX.append("")

PBX.append("/* Begin PBXSourcesBuildPhase section */")
PBX.append(f"\t\t{app_sources_phase} /* Sources */ = {{")
PBX.append("\t\t\tisa = PBXSourcesBuildPhase;")
PBX.append("\t\t\tbuildActionMask = 2147483647;")
PBX.append("\t\t\tfiles = (")
for path in ARC_SOURCES + MRC_SOURCES:
    PBX.append(f"\t\t\t\t{build_files[f'app:{path}']} /* {basename(path)} in Sources */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
PBX.append("\t\t};")
PBX.append(f"\t\t{test_sources_phase} /* Sources */ = {{")
PBX.append("\t\t\tisa = PBXSourcesBuildPhase;")
PBX.append("\t\t\tbuildActionMask = 2147483647;")
PBX.append("\t\t\tfiles = (")
for path in TEST_SOURCES:
    PBX.append(f"\t\t\t\t{build_files[f'test:{path}']} /* {basename(path)} in Sources */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
PBX.append("\t\t};")
PBX.append("/* End PBXSourcesBuildPhase section */")
PBX.append("")

common_project_settings = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEAD_CODE_STRIPPING = YES;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				SDKROOT = macosx;
"""

PBX.append("/* Begin XCBuildConfiguration section */")
PBX.append(f"\t\t{project_debug} /* Debug */ = {{")
PBX.append("\t\t\tisa = XCBuildConfiguration;")
PBX.append("\t\t\tbuildSettings = {")
PBX.append(common_project_settings)
PBX.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
PBX.append("\t\t\t\tENABLE_TESTABILITY = YES;")
PBX.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
PBX.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
PBX.append("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
PBX.append('\t\t\t\t\t"DEBUG=1",')
PBX.append('\t\t\t\t\t"$(inherited)",')
PBX.append("\t\t\t\t);")
PBX.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
PBX.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
PBX.append("\t\t\t};")
PBX.append("\t\t\tname = Debug;")
PBX.append("\t\t};")
PBX.append(f"\t\t{project_release} /* Release */ = {{")
PBX.append("\t\t\tisa = XCBuildConfiguration;")
PBX.append("\t\t\tbuildSettings = {")
PBX.append(common_project_settings)
PBX.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
PBX.append("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
PBX.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
PBX.append("\t\t\t};")
PBX.append("\t\t\tname = Release;")
PBX.append("\t\t};")

app_settings = """
				ARCHS = arm64;
				ASSETCATALOG_COMPILER_APPICON_NAME = "";
				CODE_SIGN_ENTITLEMENTS = Objektiv/Objektiv.entitlements;
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 100;
				ENABLE_HARDENED_RUNTIME = YES;
				GCC_PREFIX_HEADER = "Objektiv/Objektiv-Prefix.pch";
				GCC_PRECOMPILE_PREFIX_HEADER = YES;
				GENERATE_INFOPLIST_FILE = NO;
				HEADER_SEARCH_PATHS = (
					"$(inherited)",
					"$(SRCROOT)/Vendor",
					"$(SRCROOT)/Vendor/MASShortcut",
				);
				INFOPLIST_FILE = "Objektiv/Objektiv-Info.plist";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nthloop.Objektiv;
				PRODUCT_NAME = Objektiv;
				SWIFT_EMIT_LOC_STRINGS = YES;
"""

PBX.append(f"\t\t{app_debug} /* Debug */ = {{")
PBX.append("\t\t\tisa = XCBuildConfiguration;")
PBX.append("\t\t\tbuildSettings = {")
PBX.append(app_settings)
PBX.append("\t\t\t};")
PBX.append("\t\t\tname = Debug;")
PBX.append("\t\t};")
PBX.append(f"\t\t{app_release} /* Release */ = {{")
PBX.append("\t\t\tisa = XCBuildConfiguration;")
PBX.append("\t\t\tbuildSettings = {")
PBX.append(app_settings)
PBX.append("\t\t\t};")
PBX.append("\t\t\tname = Release;")
PBX.append("\t\t};")

test_settings = """
				ARCHS = arm64;
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				GENERATE_INFOPLIST_FILE = YES;
				HEADER_SEARCH_PATHS = (
					"$(inherited)",
					"$(SRCROOT)/Objektiv",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nthloop.ObjektivTests;
				PRODUCT_NAME = ObjektivTests;
"""

PBX.append(f"\t\t{test_debug} /* Debug */ = {{")
PBX.append("\t\t\tisa = XCBuildConfiguration;")
PBX.append("\t\t\tbuildSettings = {")
PBX.append(test_settings)
PBX.append("\t\t\t};")
PBX.append("\t\t\tname = Debug;")
PBX.append("\t\t};")
PBX.append(f"\t\t{test_release} /* Release */ = {{")
PBX.append("\t\t\tisa = XCBuildConfiguration;")
PBX.append("\t\t\tbuildSettings = {")
PBX.append(test_settings)
PBX.append("\t\t\t};")
PBX.append("\t\t\tname = Release;")
PBX.append("\t\t};")
PBX.append("/* End XCBuildConfiguration section */")
PBX.append("")

PBX.append("/* Begin XCConfigurationList section */")
PBX.append(f"\t\t{project_cfg_list} /* Build configuration list for PBXProject \"Objektiv\" */ = {{")
PBX.append("\t\t\tisa = XCConfigurationList;")
PBX.append("\t\t\tbuildConfigurations = (")
PBX.append(f"\t\t\t\t{project_debug} /* Debug */,")
PBX.append(f"\t\t\t\t{project_release} /* Release */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tdefaultConfigurationIsVisible = 0;")
PBX.append("\t\t\tdefaultConfigurationName = Release;")
PBX.append("\t\t};")
PBX.append(f"\t\t{app_cfg_list} /* Build configuration list for PBXNativeTarget \"Objektiv\" */ = {{")
PBX.append("\t\t\tisa = XCConfigurationList;")
PBX.append("\t\t\tbuildConfigurations = (")
PBX.append(f"\t\t\t\t{app_debug} /* Debug */,")
PBX.append(f"\t\t\t\t{app_release} /* Release */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tdefaultConfigurationIsVisible = 0;")
PBX.append("\t\t\tdefaultConfigurationName = Release;")
PBX.append("\t\t};")
PBX.append(f"\t\t{test_cfg_list} /* Build configuration list for PBXNativeTarget \"ObjektivTests\" */ = {{")
PBX.append("\t\t\tisa = XCConfigurationList;")
PBX.append("\t\t\tbuildConfigurations = (")
PBX.append(f"\t\t\t\t{test_debug} /* Debug */,")
PBX.append(f"\t\t\t\t{test_release} /* Release */,")
PBX.append("\t\t\t);")
PBX.append("\t\t\tdefaultConfigurationIsVisible = 0;")
PBX.append("\t\t\tdefaultConfigurationName = Release;")
PBX.append("\t\t};")
PBX.append("/* End XCConfigurationList section */")
PBX.append("\t};")
PBX.append(f"\trootObject = {project_id} /* Project object */;")
PBX.append("}")

text = "\n".join(PBX) + "\n"

# Patch en.lproj resource file refs to include the subdirectory
for name in [
    "Defaults.plist",
    "Blacklist.plist",
    "Localizable.strings",
    "InfoPlist.strings",
    "Credits.rtf",
    "MoveApplication.strings",
    "objektiv-overlay.png",
]:
    old = f'path = "{name}"; sourceTree = "<group>"; }};'
    # only replace resource refs, not all. The file refs for these are unique by name
    # but Localizable might only appear once
    text = text.replace(
        f'/* {name} */ = {{isa = PBXFileReference; lastKnownFileType =',
        f'/* {name} */ = {{isa = PBXFileReference; name = "{name}"; lastKnownFileType =',
        1,
    )

# Better approach: rewrite those specific file refs with path = en.lproj/name
replacements = {
    "Defaults.plist": "text.plist.xml",
    "Blacklist.plist": "text.plist.xml",
    "Localizable.strings": "text.plist.strings",
    "InfoPlist.strings": "text.plist.strings",
    "Credits.rtf": "text.rtf",
    "MoveApplication.strings": "text.plist.strings",
    "objektiv-overlay.png": "image.png",
}
for name, ftype in replacements.items():
    needle = f'path = "{name}"; sourceTree = "<group>";'
    # This might match headers too? Defaults.plist is unique.
    text = text.replace(
        f'lastKnownFileType = {ftype}; path = "{name}"; sourceTree = "<group>";',
        f'lastKnownFileType = {ftype}; path = "en.lproj/{name}"; sourceTree = "<group>";',
    )

OUT.write_text(text)
print(f"Wrote {OUT} ({len(text)} bytes)")
