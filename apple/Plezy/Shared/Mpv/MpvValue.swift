import Foundation
import Libmpv

/// A C string from libmpv as Swift text. mpv does not promise UTF-8 (log lines, error strings, track titles from
/// legacy files), so bytes that are not valid UTF-8 are read as Latin-1 instead of being dropped or trapping.
func mpvString(_ cString: UnsafePointer<CChar>) -> String {
    if let string = String(validatingCString: cString) { return string }
    let bytes = UnsafeBufferPointer(start: UnsafeRawPointer(cString).assumingMemoryBound(to: UInt8.self), count: strlen(cString))
    return String(String.UnicodeScalarView(bytes.map { Unicode.Scalar($0) }))
}

/// One property value mpv reported (an observed change, a stats reply), copied out of libmpv's event memory (which is
/// only valid until the next `mpv_wait_event`). Node properties are read as strings, mpv's JSON of the node, which the
/// shared rules read (`MpvState`).
struct MpvValue {
    private(set) var double: Double?
    private(set) var int: Int64?
    private(set) var flag: Bool?
    private(set) var string: String?

    init(_ property: mpv_event_property) {
        guard let data = property.data else { return }
        switch property.format {
        case MPV_FORMAT_DOUBLE:
            let value = data.assumingMemoryBound(to: Double.self).pointee
            double = value.isFinite ? value : nil
        case MPV_FORMAT_INT64:
            int = data.assumingMemoryBound(to: Int64.self).pointee
        case MPV_FORMAT_FLAG:
            flag = data.assumingMemoryBound(to: Int32.self).pointee != 0
        case MPV_FORMAT_STRING:
            string = data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee.map(mpvString)
        default:
            break
        }
    }
}
