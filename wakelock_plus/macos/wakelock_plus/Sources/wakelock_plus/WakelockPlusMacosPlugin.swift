import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

public class WakelockPlusMacosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "wakelock_plus_macos", binaryMessenger: registrar.messenger)
    let instance = WakelockPlusMacosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  var assertionID: IOPMAssertionID = 0
  var wakelockEnabled = false

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "toggle":
      let args = call.arguments as? Dictionary<String, Any>
      let enable = args!["enable"] as! Bool
      let status = enable ? enableWakelock() : disableWakelock()
      if status == kIOReturnSuccess {
        result(true)
      } else {
        let operation = enable ? "enable" : "disable"
        let description = String(cString: mach_error_string(status))
        result(FlutterError(
          code: "wakelock-error",
          message: "Failed to \(operation) wakelock: \(description)",
          details: [
            "operation": operation,
            "status": Int(status),
            "description": description
          ]
        ))
      }
    case "enabled":
      result(wakelockEnabled)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  func enableWakelock(reason: String = "Disabling display sleep") -> IOReturn {
    guard !wakelockEnabled else { return kIOReturnSuccess }
    let status = IOPMAssertionCreateWithName(
      kIOPMAssertionTypeNoDisplaySleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason as CFString,
      &assertionID
    )
    wakelockEnabled = status == kIOReturnSuccess
    return status
  }
  
  func disableWakelock() -> IOReturn {
    guard wakelockEnabled else { return kIOReturnSuccess }
    let status = IOPMAssertionRelease(assertionID)
    if status == kIOReturnSuccess {
      wakelockEnabled = false
    }
    return status
  }
}
