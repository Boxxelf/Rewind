import Foundation
import Observation
import StoreKit

@Observable
final class EntitlementStore {
    static let monthlyID = "com.tinajiang.Rewind.premium.monthly"
    static let yearlyID = "com.tinajiang.Rewind.premium.yearly"

    var isPremium = false
    var monthly: Product?
    var yearly: Product?
    var isPurchasing = false
    var errorMessage: String?

    func refresh() async {
        await loadProducts()
        await listenForEntitlements()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
            monthly = products.first { $0.id == Self.monthlyID }
            yearly = products.first { $0.id == Self.yearlyID }
        } catch {
            errorMessage = "Products could not be loaded."
        }
    }

    func listenForEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.monthlyID || transaction.productID == Self.yearlyID {
                isPremium = true
                return
            }
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    isPremium = true
                }
            case .userCancelled:
                break
            default:
                errorMessage = "Purchase could not be completed."
            }
        } catch {
            errorMessage = "Purchase could not be completed."
        }
    }

    func markUnavailable() {
        errorMessage = "Product isn't available in this build."
    }

    func restore() async {
        try? await AppStore.sync()
        await listenForEntitlements()
    }
}
