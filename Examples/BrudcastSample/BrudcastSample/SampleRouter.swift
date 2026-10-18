import Foundation

/// Turns the sample's `brudcast-sample:` links into screens, whether they come from an in-app
/// button, a notification tap or the system. A campaign button set to `brudcast-sample://checkout`
/// opens checkout.
final class SampleRouter: ObservableObject {
    enum Tab: Hashable {
        case home, shop, account
    }

    /// A screen pushed inside the shop tab.
    enum ShopRoute: Hashable {
        case product(Catalog.Product)
        case checkout(Catalog.Product)
    }

    static let shared = SampleRouter()

    @Published var tab: Tab = .home
    @Published var shopPath: [ShopRoute] = []

    /// Opens the screen a link names.
    ///
    /// - Parameter url: A `brudcast-sample:` link.
    /// - Returns: Whether the link names a screen.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard url.scheme == SampleConfig.deepLinkScheme else { return false }
        switch url.host {
        case "shop":
            show(tab: .shop, path: [])
        case "checkout":
            show(tab: .shop, path: [.checkout(Catalog.featured)])
        default:
            return false
        }
        return true
    }

    /// Returns to the first screen, for a fresh sign-in.
    func reset() {
        tab = .home
        shopPath = []
    }

    private func show(tab: Tab, path: [ShopRoute]) {
        DispatchQueue.main.async {
            self.tab = tab
            self.shopPath = path
        }
    }
}
