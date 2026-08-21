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
      if enable {
        enableWakelock()
      } else {
        disableWakelock();
      }
      result(true)
    case "enabled":
      result(wakelockEnabled)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  func enableWakelock(reason: String = "Disabling display sleep") {
    if !wakelockEnabled {
      wakelockEnabled = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                                       IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                       reason as CFString,
                                       &assertionID) == kIOReturnSuccess
    }
  }
  
  func disableWakelock() {
    if wakelockEnabled {
      IOPMAssertionRelease(assertionID)
      wakelockEnabled = false
    }
  }
}
