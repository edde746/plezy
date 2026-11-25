import Foundation
import PlezyKit

/// How this launch starts: the product, or, in DEBUG builds only, a development session with the
/// development options every platform takes (`DevLaunch`; `parseDev`).
struct LaunchOptions: Equatable {
    #if DEBUG
    /// The development options (`--dev` and the options that need it), as the dev module's `DevLaunch.parse` reads them.
    var dev: DevLaunch?
    #endif
    /// `--dev-slow-start` in milliseconds; 0 without it.
    var devSlowStartMillis: Int64 = 0

    /// A launch argument can't be used; `message` says why.
    struct Failure: Error {
        let message: String
    }

    /// The options of this process.
    static func current() throws(Failure) -> LaunchOptions {
        try parse(Array(CommandLine.arguments.dropFirst()))
    }

    /// The options `arguments` give; a Release build reads none of them and keeps every default.
    static func parse(_ arguments: [String]) throws(Failure) -> LaunchOptions {
        var options = LaunchOptions()
        #if DEBUG
        try options.parseDev(arguments)
        #endif
        return options
    }
}
