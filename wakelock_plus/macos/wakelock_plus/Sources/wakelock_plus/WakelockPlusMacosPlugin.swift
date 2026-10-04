import Cocoa
import FlutterMacOS

public class WakelockPlusMacosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "wakelock_plus_macos", binaryMessenger: registrar.messenger)
    let instance = WakelockPlusMacosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private var activity: NSObjectProtocol?

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "toggle":
      let args = call.arguments as? Dictionary<String, Any>
      let enable = args!["enable"] as! Bool
      if enable {
        enableWakelock()
      } else {
        disableWakelock()
      }
      result(true)
    case "enabled":
      result(activity != nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func enableWakelock(reason: String = "Disabling display sleep") {
    if activity == nil {
      activity = ProcessInfo.processInfo.beginActivity(
        options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
        reason: reason
      )
    }
  }

  func disableWakelock() {
    if let activity = activity {
      ProcessInfo.processInfo.endActivity(activity)
      self.activity = nil
    }
  }
}
