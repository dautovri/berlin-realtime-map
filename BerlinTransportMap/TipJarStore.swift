import Foundation
import Observation
import StoreKit

// MARK: - Tip Option
/// A hardcoded tip option that is always displayed, regardless of StoreKit availability.
struct TipOption: Identifiable, Sendable {
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
    let emoji: String
}

// MARK: - Tip Jar Store
@MainActor
@Observable
final class TipJarStore {
    enum TipJarStoreError: LocalizedError {
        case failedVerification
        case productUnavailable

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Could not verify the purchase transaction."
            case .productUnavailable:
                return "This tip is not available right now. Please try again later."
            }
        }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case purchasing(productID: String)
        case completed
        case cancelled
        case pending
        case failed(message: String)
    }

    /// Hardcoded tip options — these always appear in the UI.
    let tipOptions: [TipOption] = {
        let ids = StoreKitConfiguration.tipProductIDs
        return [
            TipOption(id: ids[0], displayName: "Buy Me a Coffee", description: "Support with the price of a coffee", displayPrice: "$4.99", emoji: "☕️"),
            TipOption(id: ids[1], displayName: "Buy Me Two Coffees", description: "A double shot of support", displayPrice: "$9.99", emoji: "☕️☕️"),
            TipOption(id: ids[2], displayName: "Buy Me a Treat", description: "Your generous support", displayPrice: "$19.99", emoji: "🎁"),
        ]
    }()

    /// Real StoreKit products, fetched in the background for accurate pricing.
    var products: [Product] = []
    var state: ViewState = .idle

    /// Returns the real `Product` matching the given option, if available.
    func product(for option: TipOption) -> Product? {
        products.first { $0.id == option.id }
    }

    /// Attempts to load real products from StoreKit for accurate, localized pricing.
    func loadProducts() async {
        state = .loading
        do {
            let ids = StoreKitConfiguration.tipProductIDs
            let fetched = try await Product.products(for: ids)
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            // Products couldn't be fetched — buttons still show with hardcoded prices
        }
        state = .loaded
    }

    /// Purchases a tip. Fetches the real product on-demand if not already cached.
    func purchaseTip(_ option: TipOption) async {
        // Use cached product if available
        if let cachedProduct = product(for: option) {
            await purchase(cachedProduct)
            return
        }

        // Try to fetch this specific product on-demand
        state = .purchasing(productID: option.id)
        do {
            let fetched = try await Product.products(for: [option.id])
            guard let realProduct = fetched.first else {
                state = .failed(message: TipJarStoreError.productUnavailable.localizedDescription)
                return
            }
            await purchase(realProduct)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func purchase(_ product: Product) async {
        state = .purchasing(productID: product.id)
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                state = .completed
            case .userCancelled:
                state = .cancelled
            case .pending:
                state = .pending
            @unknown default:
                state = .failed(message: "Unknown purchase result")
            }
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TipJarStoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
