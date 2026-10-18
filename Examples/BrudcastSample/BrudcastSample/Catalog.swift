import Foundation

/// The products the sample's shop sells, so there is something to view and check out.
enum Catalog {
    /// A product.
    struct Product: Hashable, Identifiable {
        /// The id events carry as `product`.
        let id: String
        let name: String
        let description: String
        /// The price in US dollars.
        let price: Int

        var priceLabel: String { "$\(price).00" }
    }

    static let products = [
        Product(id: "sneakers", name: "Canvas sneakers", description: "Lightweight trainers for every day", price: 79),
        Product(id: "backpack", name: "Leather backpack", description: "Fits a 16-inch laptop", price: 129),
        Product(id: "beanie", name: "Wool beanie", description: "Merino wool, one size", price: 24),
    ]

    /// The product a `brudcast-sample://checkout` link checks out.
    static let featured = products[0]
}
