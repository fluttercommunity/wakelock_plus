# Wakelock Plus 
[![GitHub stars](https://img.shields.io/github/stars/fluttercommunity/wakelock_plus.svg)](https://github.com/fluttercommunity/wakelock_plus) [![Pub version](https://img.shields.io/pub/v/wakelock.svg)](https://pub.dev/packages/wakelock_plus)

A continuation of the original Flutter [plugin](https://github.com/creativecreatorormaybenot/wakelock) 
that allows you to keep the device screen awake, i.e. prevent the screen
from sleeping.

## Supported platforms

| Platform | `wakelock` support |
|:---------|:------------------:|
| Android  |         ✅          |
| iOS      |         ✅          |
| Web      |         ✅          |
| macOS    |         ✅          |
| Windows  |         ✅          |
| Linux    |         ✅          |

## Getting started

To learn more about the plugin and getting started, you can view the main package's 
[README](https://github.com/fluttercommunity/wakelock_plus/blob/main/wakelock/README.md).

### Plugin structure

This plugin plugin uses the [federated plugins approach](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#federated-plugins).  

Android, iOS, macOS (via Hybrid Implementation), and Web use Platform Channels in their implementations. 
Windows and Linux are handled through [Dart-only platform implementations](https://docs.flutter.dev/packages-and-plugins/developing-packages#dart-only-platform-implementations).  

The basic API is defined using [`pigeon`](https://pub.dev/packages/pigeon). The pigeon files can be found in the [`pigeons` directory](https://github.com/fluttercommunity/wakelock_plus/tree/main/wakelock/pigeons)
in the main package. The API is defined in Dart in the [`wakelock_plus_platform_interface` package](https://github.com/fluttercommunity/wakelock_plus/tree/main/wakelock_plus_platform_interface).

The packages in this repo are the following:

| Package                                                                                                                       | Implementations                                                                    |
|-------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| [`wakelock_plus`](https://github.com/fluttercommunity/wakelock_plus/tree/main/wakelock)                                       | Main plugin package + Android, iOS, macOS, Windows, Linux, and Web implementations |
| [`wakelock_plus_platform_interface`](https://github.com/fluttercommunity/wakelock_plus/tree/main/wakelock_platform_interface) | Basic API definition & message handling                                            |

## Contributing

If you want to contribute to this plugin, follow the [contributing guide](https://github.com/fluttercommunity/wakelock_plus/blob/main/.github/CONTRIBUTING.md).

## Origin

As stated before, this plugin is a continuation of the original [wakelock](https://pub.dev/packages/wakelock) plugin. 
That plugin was originally based on [`screen`](https://pub.dev/packages/screen).  

Specifically, the wakelock functionality was extracted into the `wakelock` plugin due to lack of 
maintenance by the author of the `screen` plugin.  

For this library, the functionality remains the 
same as the original plugin, but has been completely refreshed (using latest Flutter standards and
platform integration) with support for all six platforms currently supported by Flutter 
(Android, iOS, macOS, Windows, Linux, and Web).

## Migrating from the `wakelock` Plugin

Simply replace the import statement with the one below:

```dart
import 'package:wakelock_plus/wakelock_plus.dart';
```

As well as replacing all the calls to `Wakelock` with `WakelockPlus`:

```dart
WakelockPlus.enable();
//...
WakelockPlus.disable();
//...
WakelockPlus.toggle(enable: true);
```