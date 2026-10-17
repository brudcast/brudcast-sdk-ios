import SwiftUI
import Brudcast

/// The products for sale.
struct ShopView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PageHeader(title: "Shop", description: "Pick a product to see it and check out.")
                ForEach(Catalog.products) { product in
                    NavigationLink(value: SampleRouter.ShopRoute.product(product)) {
                        HStack(spacing: 12) {
                            IconChip(systemName: "bag")
                            VStack(alignment: .leading, spacing: 0) {
                                Text(product.name).font(Typography.subheading)
                                Text(product.description).font(Typography.description).foregroundStyle(Palette.mutedForeground)
                            }
                            Spacer(minLength: 8)
                            Text(product.priceLabel).font(Typography.subheading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Rule()
                }
            }
        }
        .background(Palette.background)
        .trackScreen("Shop")
    }
}

/// A product page. Viewing it tracks `product_viewed`.
struct ProductView: View {
    let product: Catalog.Product

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name).font(Typography.pageTitle).tracking(-0.6)
                    Text(product.description).font(Typography.description).foregroundStyle(Palette.mutedForeground)
                    Text(product.priceLabel).font(Typography.metric).tracking(-0.6).padding(.top, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                Rule(strong: true)
                SectionBlock(title: "Delivery and returns") {
                    ForEach(["Free shipping", "Ships in 1 to 2 business days", "Free returns within 30 days"], id: \.self) {
                        Text($0).font(Typography.body)
                    }
                }
                Rule()
                NavigationLink("Buy now", value: SampleRouter.ShopRoute.checkout(product))
                    .buttonStyle(PrimaryButtonStyle(fullWidth: true))
                    .accessibilityIdentifier("buyButton")
                    .padding(20)
            }
        }
        .background(Palette.background)
        .trackScreen("Product", properties: ["product": .string(product.id)])
        .onAppear {
            Brudcast.track("product_viewed", properties: ["product": .string(product.id), "price": .number(Double(product.price))])
        }
    }
}

/// Checkout. Appearing tracks `checkout_started`, the event the README's example campaign is
/// triggered by, and placing the order tracks `order_completed`.
struct CheckoutView: View {
    let product: Catalog.Product
    @State private var placed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PageHeader(title: "Checkout", description: "This is a demo store. Nothing is charged or shipped.")
                SectionBlock(title: "Order summary") {
                    DetailRow(label: "Item", value: product.name)
                    DetailRow(label: "Quantity", value: "1")
                    DetailRow(label: "Shipping", value: "Free")
                    DetailRow(label: "Total", value: product.priceLabel)
                }
                Rule()
                VStack(spacing: 12) {
                    if placed {
                        Notice(text: "Order placed. order_completed was tracked.", background: Palette.success, foreground: Palette.successForeground)
                        Button("Continue shopping") { SampleRouter.shared.shopPath = [] }
                            .buttonStyle(OutlineButtonStyle(fullWidth: true))
                    } else {
                        Button("Place order") {
                            Brudcast.track("order_completed", properties: properties)
                            placed = true
                        }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: true))
                        .accessibilityIdentifier("placeOrderButton")
                    }
                }
                .padding(20)
            }
        }
        .background(Palette.background)
        .trackScreen("Checkout", properties: ["product": .string(product.id)])
        .onAppear { Brudcast.track("checkout_started", properties: properties) }
    }

    private var properties: BrudcastProperties {
        ["product": .string(product.id), "total": .number(Double(product.price))]
    }
}
