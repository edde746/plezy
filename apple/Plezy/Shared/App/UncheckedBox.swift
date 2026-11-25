/// Carries a value the compiler can't prove `Sendable` (Kotlin objects, which are thread-safe to hand over) across an
/// isolation boundary.
struct UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}
