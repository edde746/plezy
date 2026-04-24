import Foundation
import Network

public class PathMonitorConnectivityProvider: NSObject, ConnectivityProvider {

  // Use .utility, as it is intended for tasks that the user does not track actively.
  // See: https://developer.apple.com/documentation/dispatch/dispatchqos
  private let queue = DispatchQueue.global(qos: .utility)

  private var pathMonitor: NWPathMonitor?

  private func connectivityFrom(path: NWPath) -> [ConnectivityType] {
    var types: [ConnectivityType] = []
    
    // Check for connectivity and append to types array as necessary
    if path.status == .satisfied {
      if path.usesInterfaceType(.wifi) {
        types.append(.wifi)
      }
      if path.usesInterfaceType(.cellular) {
        types.append(.cellular)
      }
      if path.usesInterfaceType(.wiredEthernet) {
        types.append(.wiredEthernet)
      }
      if path.usesInterfaceType(.other) {
        types.append(.other)
      }
    }
    
    return types.isEmpty ? [.none] : types
  }

  public var currentConnectivityTypes: [ConnectivityType] {
    let path = ensurePathMonitor().currentPath
    return connectivityFrom(path: path)
  }

  public var connectivityUpdateHandler: ConnectivityUpdateHandler?

  override init() {
    super.init()
    _ = ensurePathMonitor()
  }

  public func start() {
    _ = ensurePathMonitor()
  }

  public func stop() {
    pathMonitor?.cancel()
    pathMonitor = nil
  }

  @discardableResult
  private func ensurePathMonitor() -> NWPathMonitor {
    if (pathMonitor == nil) {
      let pathMonitor = NWPathMonitor()
      pathMonitor.start(queue: queue)
      pathMonitor.pathUpdateHandler = pathUpdateHandler
      self.pathMonitor = pathMonitor
    }
    return self.pathMonitor!
  }

  private func pathUpdateHandler(path: NWPath) {
    connectivityUpdateHandler?(connectivityFrom(path: path))
  }
}
