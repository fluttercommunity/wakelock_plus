## [1.5.0]
* [#122](https://github.com/fluttercommunity/wakelock_plus/pull/122): feat: bump win32 to 6.x and widen package_info_plus to 10.x. Thanks [dbebawy](https://github.com/dbebawy).
* [#123](https://github.com/fluttercommunity/wakelock_plus/pull/123): Flutter 3.41 upgrade. Thanks [diegotori](https://github.com/diegotori).
* [#124](https://github.com/fluttercommunity/wakelock_plus/pull/124): fix: replace unmaintained pana action with pub publish --dry-run. Thanks [dbebawy](https://github.com/dbebawy).
* **BREAKING CHANGES**:
  - Dart
    * Library now requires Dart version `3.11` or higher.
    * Library now requires Flutter version `3.41` or higher.

## [1.4.0]
* [#121](https://github.com/fluttercommunity/wakelock_plus/pull/121): Pigeon v26.2 upgrade. Thanks [diegotori](https://github.com/diegotori).
* **BREAKING CHANGES**:
  - Dart
    * Library now requires Dart version `3.10` or higher.
    * Library now requires Flutter version `3.38` or higher.
  - iOS
    * Library now supports at least iOS version `13.0` or higher.
  - Android
    * Library now supports at least Android API Level 24 (7.0 Nougat) or higher

## [1.3.0]
* [#107](https://github.com/fluttercommunity/wakelock_plus/pull/107): Flutter 3.35 upgrade. Thanks [diegotori](https://github.com/diegotori).
* **BREAKING CHANGES**:
  - Dart
    * Library now requires Dart version `3.4` or higher.
    * Library now requires Flutter version `3.22` or higher.
  - Android
    * Library now requires Android API 21 (Lollipop) or higher
    * Library now requires Java 17 or higher
    * Library now requires Android Gradle Plugin >=8.12.1
    * Library now requires Gradle wrapper >=8.13

## [1.2.3]
* [#95](https://github.com/fluttercommunity/wakelock_plus/pull/95): Fix SPM integration. Thanks [diegotori](https://github.com/diegotori).

## [1.2.2]
* [#82](https://github.com/fluttercommunity/wakelock_plus/pull/82): fix: resolve symbol conflicts in wakelock_plus by updating Pigeon prefix. Thanks [weitsai](https://github.com/weitsai).

## 1.2.1
* [#41](https://github.com/fluttercommunity/wakelock_plus/pull/41): Fix: dependency minimums adjustments. Thanks [diegotori](https://github.com/diegotori).

## 1.2.0

* **BREAKING CHANGES**:
    * Library now requires Dart version `3.3` or higher.
    * Library now requires Flutter version `3.19` or higher.

## 1.1.0

* [#2](https://github.com/fluttercommunity/wakelock_plus/pull/2): Downgraded minimum `meta` to version `1.3.0` in order to maintain compatibility with versions of Flutter below `3.10`. Thanks [diegotori](https://github.com/diegotori).
* **BREAKING CHANGE**: Increased the minimum supported Dart version to `2.18` in order to align it with `plugin_platform_interface`.

## 1.0.0

* Initial release.
