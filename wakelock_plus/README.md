# wakelock_plus

[![Flutter Community: wakelock_plus](https://fluttercommunity.dev/_github/header/wakelock_plus)](https://github.com/fluttercommunity/community)

[![Pub version](https://img.shields.io/pub/v/wakelock_plus.svg)](https://pub.dev/packages/wakelock_plus) [![GitHub stars](https://img.shields.io/github/stars/fluttercommunity/wakelock_plus.svg)](https://github.com/fluttercommunity/wakelock_plus)  
A continuation of the original [wakelock](https://github.com/creativecreatorormaybenot/wakelock) Flutter Plugin written by [creativecreatorormaybenot](https://github.com/creativecreatorormaybenot) that allows you to keep the device screen awake, i.e. prevent the screen from sleeping.

---

You can enable and toggle the screen wakelock, which prevents the screen from turning off 
automatically.

## Supported Platforms

| Platform | `wakelock_plus` support |
|:---------|:-----------------------:|
| Android  |            ✅            |
| iOS      |            ✅            |
| Web      |            ✅            |
| macOS    |            ✅            |
| Windows  |            ✅            |
| Linux    |            ✅            |

## Usage

To use this plugin, follow the [installation guide](https://pub.dev/packages/wakelock_plus/install).

The `wakelock_plus` plugin **does not require any special _permissions_** on any platform :)  
This is because it only enables the _screen wakelock_ and not any partial 
(CPU) wakelocks that would keep the app alive in the background.

### Implementation

Everything in this plugin is controlled via the 
[`WakelockPlus` class](https://pub.dev/documentation/wakelock_plus/latest/wakelock_plus/WakelockPlus-class.html).  
If you want to enable the wakelock, i.e. keep the device awake, you can simply call 
[`WakelockPlus.enable`](https://pub.dev/documentation/wakelock_plus/latest/wakelock_plus/WakelockPlus/enable.html)
and to disable it again, you can use 
[`WakelockPlus.disable`](https://pub.dev/documentation/wakelock_plus/latest/wakelock_plus/WakelockPlus/disable.html):

```dart
import 'package:wakelock_plus/wakelock_plus.dart';
// ...

// The following line will enable the Android and iOS wakelock.
WakelockPlus.enable();

// The next line disables the wakelock again.
WakelockPlus.disable();
```

For more advanced usage, you can pass a `bool` to 
[`WakelockPlus.toggle`](https://pub.dev/documentation/wakelock_plus/latest/wakelock_plus/WakelockPlus/toggle.html)
to enable or disable the wakelock and also retrieve the current wakelock status using
[`WakelockPlus.isEnabled`](https://pub.dev/documentation/wakelock_plus/latest/wakelock_plus/WakelockPlus/isEnabled.html):

```dart
import 'package:wakelock_plus/wakelock_plus.dart';
// ...

// The following lines of code toggle the wakelock based on a bool value.
bool enable = true;
// The following statement enables the wakelock.
WakelockPlus.toggle(enable: enable);

enable = false;
// The following statement disables the wakelock.
WakelockPlus.toggle(enable: enable);

// If you want to retrieve the current wakelock status,
// you will have to be in an async scope
// to await the Future returned by `enabled`.
bool wakelockEnabled = await WakelockPlus.enabled;
```

If you want to wait for the wakelock toggle to complete (which takes an insignificant amount of
time), you can also `await` any of `WakelockPlus.enable`, `WakelockPlus.disable`, and 
`WakelockPlus.toggle`.

### Ensure the `WidgetsBinding` is initialized

If you want to call `WakelockPlus.enable()` or the other functions before `runApp()` 
(e.g. in `main()`), you will have to ensure that the `WidgetsBinding` is initialized first:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  runApp(..);
}
```

In general, it is advisable to make your wakelock dependent on certain components within your app
instead, e.g. by only enabling it (continually) when a certain widget is visible.
There is no negative impact in calling `WakelockPlus.enable()` more often.

### Calling `WakelockPlus.enable()` in `main()`

As touched on in the previous paragraph, calling `WakelockPlus.enable()` in your `main()` 
function is not the best approach for a number of reasons.

The most important factors are:

1. Users expect their screen to automatically turn off unless e.g. a video is playing.  
   It is unlikely that your whole app requires the screen to always stay on.
2. The wakelock can be released by external sources at any time (e.g. by the OS).  
   Only calling `WakelockPlus.enable()` once will most likely mean that the screen turns off 
   at one point or another anyway.

This is why you should instead prefer to enable the wakelock whenever components inside of your app
that require the screen to stay on are active. This can e.g. happen in the `build` method of your
widget.

## Learn more

If you want to learn more about how this plugin works, how to contribute, etc., you can read 
through the [main README on GitHub](https://github.com/fluttercommunity/wakelock_plus).
