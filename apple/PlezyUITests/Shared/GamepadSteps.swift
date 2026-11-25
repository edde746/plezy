import XCTest

extension PlezyUITestCase {
    /// A game controller's press, which the test machines can't make: the link `plezy://dev-gamepad?<query>` (`press=a`,
    /// `press=a&hold=900`, `stick=1,0`, `disconnect`) hands it to the app's controller bridge where the GameController
    /// handlers' presses go (DEBUG builds' `AppModel.followDevLink`); then the app has a moment to act.
    func gamepad(_ query: String) {
        guard let url = URL(string: "plezy://dev-gamepad?\(query)") else { return fail("no link for \(query)") }
        openFromOutside(url)
        // Paces the presses (a hold lasts its time); callers check what each one did.
        Thread.sleep(forTimeInterval: query.contains("hold=") ? 2 : 1)
    }
}
