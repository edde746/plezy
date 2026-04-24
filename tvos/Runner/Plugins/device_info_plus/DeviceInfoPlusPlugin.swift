// Pure-Swift tvOS port of fluttercommunity.plus/device_info. Mirrors the
// Objective-C FPPDeviceInfoPlusPlugin on iOS so the Dart IosDeviceInfo
// parser finds all the keys it expects.

import Foundation
import UIKit

#if os(iOS) || os(tvOS)
  import Flutter

  public class DeviceInfoPlusPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(
        name: "dev.fluttercommunity.plus/device_info",
        binaryMessenger: registrar.messenger()
      )
      let instance = DeviceInfoPlusPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard call.method == "getDeviceInfo" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let device = UIDevice.current
      var uts = utsname()
      uname(&uts)

      let processInfo = ProcessInfo.processInfo
      let isSimulator: Bool = {
        #if targetEnvironment(simulator)
          return true
        #else
          return false
        #endif
      }()
      let isPhysicalDevice = !isSimulator

      let machine: String
      if isPhysicalDevice {
        machine = Self.utsnameString(&uts.machine)
      } else {
        machine = processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
      }

      let freeDisk: Int64
      let totalDisk: Int64
      if let attrs = try? FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory())
      {
        freeDisk = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? -1
        totalDisk = (attrs[.systemSize] as? NSNumber)?.int64Value ?? -1
      } else {
        freeDisk = -1
        totalDisk = -1
      }

      var isiOSAppOnMac = false
      if #available(iOS 14.0, tvOS 14.0, *) {
        isiOSAppOnMac = processInfo.isiOSAppOnMac
      }

      let physicalRam = Int64(processInfo.physicalMemory) / 1_048_576

      let info: [String: Any] = [
        "name": device.name,
        "systemName": device.systemName,
        "systemVersion": device.systemVersion,
        "model": device.model,
        "localizedModel": device.localizedModel,
        "modelName": machine,
        "identifierForVendor": device.identifierForVendor?.uuidString as Any,
        "freeDiskSize": freeDisk,
        "totalDiskSize": totalDisk,
        "isPhysicalDevice": isPhysicalDevice,
        "isiOSAppOnMac": isiOSAppOnMac,
        "physicalRamSize": physicalRam,
        "availableRamSize": Self.availableMemoryMB(),
        "utsname": [
          "sysname": Self.utsnameString(&uts.sysname),
          "nodename": Self.utsnameString(&uts.nodename),
          "release": Self.utsnameString(&uts.release),
          "version": Self.utsnameString(&uts.version),
          "machine": machine,
        ],
      ]

      result(info)
    }

    private static func utsnameString<T>(_ tupled: inout T) -> String {
      withUnsafePointer(to: &tupled) { ptr in
        ptr.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<T>.size) {
          String(cString: $0)
        }
      }
    }

    private static func availableMemoryMB() -> Int {
      var hostInfo = vm_statistics_data_t()
      var count = mach_msg_type_number_t(
        MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size)
      let host = mach_host_self()
      var pageSize: vm_size_t = 0
      host_page_size(host, &pageSize)

      let result: kern_return_t = withUnsafeMutablePointer(to: &hostInfo) { ptr in
        ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
          host_statistics(host, HOST_VM_INFO, reboundPtr, &count)
        }
      }
      guard result == KERN_SUCCESS else { return -1 }
      let memFree = UInt64(hostInfo.free_count) * UInt64(pageSize)
      return Int(memFree / 1_048_576)
    }
  }
#endif
