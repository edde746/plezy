import Foundation
import os
import PlezyKit
import StoreKit
#if !os(macOS)
import UIKit
#endif

private let log = Logger(subsystem: "com.edde746.plezy", category: "supporter")

/// The Supporter perks on Apple platforms (`AppPlatform.supporter`): the build flavor's (`SupporterPlatform.of`: the App
/// Store's builds sell them, the Mac's DMG gives them, the GitHub IPA leaves them out), the App Store through StoreKit 2,
/// and the alternate icons on iPhone, iPad and Apple TV.
@MainActor
enum AppleSupporter {
    static func platform() -> SupporterPlatform {
        #if os(macOS)
        let icons: (any AppIconSwitch)? = nil
        #else
        let icons: (any AppIconSwitch)? = AppleAppIcons()
        #endif
        return SupporterPlatform.companion.of(
            flavor: ApplePlatform.flavor,
            platform: ApplePlatform.devicePlatform,
            packagedInstall: false,
            billing: AppleStoreBilling(),
            appIcons: icons
        )
    }
}

/// The App Store through StoreKit 2 (`AppStoreBilling`). The purchase stream is `Transaction.updates` (renewals,
/// refunds, Ask to Buy approvals, purchases made on other devices) and each `Product.purchase()`'s result; only verified
/// transactions count, and a transaction stays unfinished until the shared core completes it.
@MainActor
final class AppleStoreBilling: @preconcurrency AppStoreBilling {
    private var listener: (any StorePurchaseListener)?
    private var updates: Task<Void, Never>?
    private var products: [String: Product] = [:]
    /// Unfinished transactions by id, until `complete` finishes them.
    private var unfinished: [String: Transaction] = [:]

    /// StoreKit answers as long as the device may pay: Screen Time can turn purchases off.
    nonisolated func __isAvailable() async throws -> KotlinBoolean {
        KotlinBoolean(bool: AppStore.canMakePayments)
    }

    nonisolated func __queryProduct(productId: String) async throws -> StoreProduct {
        do {
            let found = try await Product.products(for: [productId]).first { $0.id == productId }
            guard let product = found else { return StoreProduct(price: nil, errorCode: nil) }
            await MainActor.run { self.products[productId] = product }
            return StoreProduct(price: product.displayPrice, errorCode: nil)
        } catch {
            return StoreProduct(price: nil, errorCode: String(describing: error))
        }
    }

    nonisolated func __buy(productId: String) async throws -> KotlinBoolean {
        guard let product = await MainActor.run(body: { self.products[productId] }) else { return KotlinBoolean(bool: false) }
        // The outcome goes out on the purchase stream; the flow itself opened when the call returned.
        Task { @MainActor in
            do {
                switch try await product.purchase() {
                case .success(let verification):
                    self.deliver(verification)
                case .pending:
                    self.listener?.onPurchases(purchases: [StorePurchase(productId: productId, status: .pending, revoked: false, pendingComplete: false, token: "", errorMessage: nil)])
                case .userCancelled:
                    self.listener?.onPurchases(purchases: [StorePurchase(productId: productId, status: .canceled, revoked: false, pendingComplete: false, token: "", errorMessage: nil)])
                @unknown default:
                    break
                }
            } catch {
                log.warning("The purchase failed: \(String(describing: error), privacy: .public)")
                self.listener?.onPurchases(purchases: [StorePurchase(productId: productId, status: .error, revoked: false, pendingComplete: false, token: "", errorMessage: String(describing: error))])
            }
        }
        return KotlinBoolean(bool: true)
    }

    nonisolated func __complete(purchase: StorePurchase) async throws {
        let token = purchase.token
        let transaction = await MainActor.run { self.unfinished.removeValue(forKey: token) }
        await transaction?.finish()
    }

    func listen(listener: any StorePurchaseListener) {
        self.listener = listener
        guard updates == nil else { return }
        // Unfinished transactions first (a purchase completed while the app was gone), then the updates as they come.
        updates = Task { @MainActor [weak self] in
            for await verification in Transaction.unfinished {
                self?.deliver(verification)
            }
            for await verification in Transaction.updates {
                self?.deliver(verification)
            }
        }
    }

    func stopListening() {
        listener = nil
        updates?.cancel()
        updates = nil
    }

    nonisolated func __transactions() async throws -> [StoreTransaction] {
        var transactions: [StoreTransaction] = []
        for await verification in Transaction.all {
            guard case .verified(let transaction) = verification else { continue }
            transactions.append(StoreTransaction(productId: transaction.productID, revoked: transaction.revocationDate != nil))
        }
        return transactions
    }

    nonisolated func __sync() async throws -> String? {
        do {
            try await AppStore.sync()
            return nil
        } catch StoreKitError.userCancelled {
            // AppStoreBilling.SYNC_CANCELLED: the user dismissed the sign-in.
            return "userCancelled"
        } catch {
            return String(describing: error)
        }
    }

    /// One verified transaction on the purchase stream: purchased, or revoked (a refund) with its revocation date.
    private func deliver(_ verification: VerificationResult<Transaction>) {
        guard case .verified(let transaction) = verification else {
            log.warning("Dropped a transaction StoreKit could not verify")
            return
        }
        let token = String(transaction.id)
        unfinished[token] = transaction
        listener?.onPurchases(purchases: [
            StorePurchase(
                productId: transaction.productID,
                status: .purchased,
                revoked: transaction.revocationDate != nil,
                pendingComplete: true,
                token: token,
                errorMessage: nil
            ),
        ])
    }
}

#if !os(macOS)
/// The home-screen icon on iPhone, iPad and Apple TV (`AppIconSwitch`): the alternates the Info.plist lists
/// (`CFBundleIcons[~ipad].CFBundleAlternateIcons`, a dictionary on iOS and an array on tvOS), set at once; the system
/// shows its alert.
@MainActor
final class AppleAppIcons: @preconcurrency AppIconSwitch {
    private static let prefix = "AppIcon-"

    /// The alternate icon names this build ships.
    private let names: Set<String> = {
        let info = Bundle.main.infoDictionary
        let icons = (info?["CFBundleIcons~ipad"] ?? info?["CFBundleIcons"]) as? [String: Any]
        switch icons?["CFBundleAlternateIcons"] {
        case let dictionary as [String: Any]: return Set(dictionary.keys)
        case let array as [String]: return Set(array)
        default: return []
        }
    }()

    nonisolated func __isSupported() async throws -> KotlinBoolean {
        let supported = await MainActor.run { UIApplication.shared.supportsAlternateIcons && !self.names.isEmpty }
        return KotlinBoolean(bool: supported)
    }

    nonisolated func __current() async throws -> String {
        await MainActor.run {
            guard let name = UIApplication.shared.alternateIconName, name.hasPrefix(Self.prefix) else { return "default" }
            return String(name.dropFirst(Self.prefix.count))
        }
    }

    /// What a pick asks of the system: nothing (shown already, or refused) or this alternate name (nil: the default).
    private enum Plan: Sendable {
        case done
        case unsupported
        case unknown
        case set(String?)
    }

    nonisolated func __setIcon(id: String) async throws -> AppIconError? {
        let plan: Plan = await MainActor.run {
            guard UIApplication.shared.supportsAlternateIcons, !self.names.isEmpty else { return .unsupported }
            let name: String? = id == "default" ? nil : Self.prefix + id
            if let name, !self.names.contains(name) { return .unknown }
            // Setting the icon shown already would show the system's alert for nothing.
            return UIApplication.shared.alternateIconName == name ? .done : .set(name)
        }
        switch plan {
        case .done: return nil
        case .unsupported: return .unsupported
        case .unknown: return .unknownIcon
        case .set(let name):
            do {
                try await Self.apply(name)
                return nil
            } catch {
                log.warning("Couldn't set the app icon \(id, privacy: .public): \(String(describing: error), privacy: .public)")
                return .failed
            }
        }
    }

    /// Sets the home-screen icon on the main actor, where UIKit takes it; the system shows its alert.
    @MainActor private static func apply(_ name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}
#endif
