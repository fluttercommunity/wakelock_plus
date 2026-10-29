#!/usr/bin/env python3
"""Align beta-only Android CI with the selected Flutter SDK's Android templates.

Stable Flutter jobs keep the repository's checked-in Android configuration.
Flutter beta can move its minimum AGP/Gradle versions ahead of stable releases.
"""
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sdk_root = os.environ.get("FLUTTER_ROOT")
if not sdk_root:
    raise SystemExit("FLUTTER_ROOT is required after setting up Flutter beta")
defaults_path = Path(sdk_root) / "packages/flutter_tools/lib/src/android/gradle_utils.dart"
defaults = defaults_path.read_text(encoding="utf-8")


def sdk_version(constant: str) -> str:
    match = re.search(rf"^const {re.escape(constant)} = '([0-9.]+)';$", defaults, re.MULTILINE)
    if not match:
        raise RuntimeError(f"Cannot determine Flutter SDK {constant}")
    return match.group(1)


def rewrite_one(path: Path, pattern: str, replacement: str) -> None:
    source = path.read_text(encoding="utf-8")
    updated, changes = re.subn(pattern, replacement, source, count=1, flags=re.MULTILINE)
    if changes != 1:
        raise RuntimeError(f"Expected one match for {pattern!r} in {path}")
    path.write_text(updated, encoding="utf-8")


agp = sdk_version("templateAndroidGradlePluginVersion")
gradle = sdk_version("templateDefaultGradleVersion")
kotlin = sdk_version("templateKotlinGradlePluginVersion")
android_root = ROOT / "wakelock_plus/example/android"

rewrite_one(
    android_root / "settings.gradle",
    r'(id "com\.android\.application" version ")[^"]+(" apply false)',
    rf'\g<1>{agp}\g<2>',
)
rewrite_one(
    android_root / "settings.gradle",
    r'(id "org\.jetbrains\.kotlin\.android" version ")[^"]+(" apply false)',
    rf'\g<1>{kotlin}\g<2>',
)
rewrite_one(
    android_root / "gradle/wrapper/gradle-wrapper.properties",
    r'(distributionUrl=https\\://services\.gradle\.org/distributions/gradle-)[0-9.]+(-bin\.zip)',
    rf'\g<1>{gradle}\g<2>',
)
rewrite_one(
    android_root / "gradle.properties",
    r'^android\.builtInKotlin=false$',
    "android.builtInKotlin=true",
)
# Keep android.newDsl=false to preserve legacy example app DSL compatibility.
print(f"Flutter beta CI: AGP {agp}, Gradle {gradle}, Kotlin {kotlin}")
