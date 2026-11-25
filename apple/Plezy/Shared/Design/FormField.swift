import SwiftUI

extension View {
    /// A form row that is a text field: on tvOS the system's field fills the whole row, so the row's capsule and the
    /// field's are one shape and focus lifts and whitens that one (inset, the field read as a capsule drawn inside
    /// another, the focused one a white pill inside a dark one). Elsewhere the form's own row.
    func formFieldRow() -> some View {
        #if os(tvOS)
        listRowInsets(EdgeInsets())
        #else
        self
        #endif
    }
}
