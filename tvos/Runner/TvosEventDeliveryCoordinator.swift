import Foundation

/// Keeps tvOS launcher events single-shot without suppressing a deliberate
/// second tap forever. All access is confined to the main thread by the host.
final class TvosDeepLinkDeliveryCoordinator {
  struct Event: Equatable {
    let contentId: String
    let receivedAt: TimeInterval
    var flutterArguments: [String: String] { ["contentId": contentId] }
    fileprivate let sequence: UInt64
  }

  enum Receipt: Equatable {
    case retained
    case duplicate
    case deliver(Event)
  }

  private let deduplicationWindow: TimeInterval
  private let now: () -> TimeInterval
  private var sequence: UInt64 = 0
  private var liveDeliveryEnabled = false
  private var pending: Event?
  private var inFlight: Event?
  private var lastDelivered: Event?

  init(
    deduplicationWindow: TimeInterval = 2,
    now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
  ) {
    precondition(deduplicationWindow >= 0)
    self.deduplicationWindow = deduplicationWindow
    self.now = now
  }

  /// A replacement Flutter engine must perform its initial read before live
  /// delivery resumes. A launch event captured before registration is retained.
  func bindEngine() {
    liveDeliveryEnabled = false
    inFlight = nil
  }

  func receive(contentId: String) -> Receipt {
    let timestamp = now()

    if let inFlight, isDuplicate(contentId: contentId, at: timestamp, of: inFlight) {
      return .duplicate
    }
    if let pending, isDuplicate(contentId: contentId, at: timestamp, of: pending) {
      // A retained failed delivery is retryable when no send is active.
      return liveDeliveryEnabled && inFlight == nil ? beginDelivery(pending) : .duplicate
    }
    if let lastDelivered, isDuplicate(contentId: contentId, at: timestamp, of: lastDelivered) {
      return .duplicate
    }

    sequence &+= 1
    let event = Event(contentId: contentId, receivedAt: timestamp, sequence: sequence)
    pending = event
    guard liveDeliveryEnabled, inFlight == nil else { return .retained }
    return beginDelivery(event)
  }

  /// Atomically transitions an engine from retained launch delivery to live
  /// delivery and returns the one retained event, if any.
  func beginLiveDelivery() -> Event? {
    liveDeliveryEnabled = true
    guard inFlight == nil, let pending else { return nil }
    inFlight = pending
    return pending
  }

  /// Clears a retained event only after Flutter reports successful delivery.
  /// A newer retained event is returned so callers can deliver it next.
  func complete(_ event: Event, succeeded: Bool) -> Event? {
    guard inFlight == event else { return nil }
    inFlight = nil
    guard succeeded else { return nil }

    lastDelivered = event
    if pending == event {
      pending = nil
    }
    guard liveDeliveryEnabled, let pending else { return nil }
    return beginDelivery(pending).event
  }

  var retainedContentId: String? { pending?.contentId }

  private func beginDelivery(_ event: Event) -> Receipt {
    inFlight = event
    return .deliver(event)
  }

  private func isDuplicate(contentId: String, at timestamp: TimeInterval, of event: Event) -> Bool {
    contentId == event.contentId && timestamp - event.receivedAt <= deduplicationWindow
  }
}

private extension TvosDeepLinkDeliveryCoordinator.Receipt {
  var event: TvosDeepLinkDeliveryCoordinator.Event? {
    if case let .deliver(event) = self { return event }
    return nil
  }
}
